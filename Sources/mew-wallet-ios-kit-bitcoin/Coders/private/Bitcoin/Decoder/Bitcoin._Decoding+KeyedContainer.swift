//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/14/25.
//

import Foundation

extension Bitcoin._Decoding {
  /// A keyed decoding container used by the Bitcoin decoding system to extract
  /// values from binary or structured Bitcoin transaction formats, such as
  /// PSBT, witness data, or transaction fields.
  ///
  /// This container supports both single-value and many-value maps, providing
  /// context-aware access to transaction data using key paths. Keys are resolved
  /// based on static `KeypathProvider` definitions.
  ///
  /// Keys like `vin`, `vout`, `scriptSig`, `scriptPubKey`, and others are
  /// mapped to appropriate decoders (e.g. `Script`, `Output`, `Input`),
  /// ensuring structured decoding with support for nested decoding logic.
  ///
  /// - Note: Floating-point, string, and boolean decoding is unsupported and
  ///         will throw `DecodingError.typeMismatch`.
  /// - Note: Nested containers (keyed or unkeyed) and super decoders are not
  ///         currently supported.
  ///
  /// - Parameters:
  ///   - Key: The type of keys used to access values (must conform to `CodingKey`)
  ///   - M: The concrete map type implementing `KeypathProvider` & `DataReader`
  internal struct KeyedContainer<Key: CodingKey, M: KeypathProvider & DataReader>: Swift.KeyedDecodingContainerProtocol {
    let allKeys: [Key]
    
    /// The full path of the current decoding operation.
    var codingPath: [any CodingKey] { decoder.codingPath }
    
    /// Reference to the parent decoder context.
    private let decoder: Bitcoin._Decoding.Decoder<M>
    
    /// Parsed binary data structure that exposes typed access.
    private let map: M
    
    /// Creates a keyed decoding container for a Bitcoin decoding context.
    ///
    /// - Parameters:
    ///   - decoder: The parent decoder with context and configuration.
    ///   - data: The raw binary data slice for this container.
    ///   - context: Optional decoding context, such as witness data.
    ///   - map: An optional pre-parsed `DataReader` map; if nil, it will be initialized.
    /// - Throws: `DecodingError.dataCorrupted` if the data cannot be parsed.
    init(decoder: Bitcoin._Decoding.Decoder<M>, data: Data.SubSequence, context: DataReaderContext?, map: M?) throws {
      do {
        self.decoder = decoder
        self.allKeys = M.keyPathSingle.keys.compactMap(Key.init) + M.keyPathMany.keys.compactMap(Key.init)
        self.map = try map ?? M(data: data, context: context, configuration: decoder.configuration)
      } catch {
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Corrupted data", underlyingError: error))
      }
    }
    
    /// Decodes a value of the specified type for the given key.
    ///
    /// If the key maps to a binary value via `keyPathSingle`, the corresponding
    /// binary slice will be passed to the appropriate decoder. For array-based
    /// keys (`keyPathMany`), decoding will proceed as an array of records.
    ///
    /// - Throws:
    ///   - `DecodingError.keyNotFound` if no key path exists or value is missing.
    ///   - `DecodingError.typeMismatch` if the value cannot be decoded into `T`.
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
      if let keyPath = M.keyPathSingle[key.stringValue] {
        guard let value = map[keyPath: keyPath] else {
          throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "No value associated with key \(key.stringValue)"))
        }
        // If the value is already of the expected type, return it directly.
        if let typedValue = value as? T { return typedValue }
        
        // Otherwise, attempt to decode it as a nested Decodable type.
        // Create a new decoder with updated coding path.
        let decoder: any Swift.Decoder
        switch key.stringValue {
        case "version", "locktime", "sequence":
          decoder = Bitcoin._Decoding.Decoder<_Reader.Raw>(
            data: [value],
            context: nil,
            map: nil,
            codingPath: codingPath + [key],
            userInfo: self.decoder.userInfo,
            configuration: self.decoder.configuration
          )
        case "scriptPubKey", "scriptSig":
          decoder = Bitcoin._Decoding.Decoder<_Reader.Script>(
            data: [value],
            context: nil,
            map: nil,
            codingPath: codingPath + [key],
            userInfo: self.decoder.userInfo,
            configuration: self.decoder.configuration
          )
        case "outpoint":
          decoder = Bitcoin._Decoding.Decoder<_Reader.BitcoinTXInputOutpoint>(
            data: [value],
            context: nil,
            map: nil,
            codingPath: codingPath + [key],
            userInfo: self.decoder.userInfo,
            configuration: self.decoder.configuration
          )
        default:
          throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Key \(key.stringValue) not found or not supported yet"))
        }
        
        return try T(from: decoder)
      } else if let keyPath = M.keyPathMany[key.stringValue] {
        guard let value = map[keyPath: keyPath] else {
          throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "No value associated with key \(key.stringValue)"))
        }
        // If the value is already of the expected type, return it directly.
        if let typedValue = value as? T { return typedValue }
        
        // Otherwise, attempt to decode it as a nested Decodable type.
        // Create a new decoder with updated coding path.
        let decoder: any Swift.Decoder
        switch key.stringValue {
        case "version", "locktime", "sequence":
          decoder = Bitcoin._Decoding.Decoder<_Reader.Raw>(
            data: value,
            context: nil,
            map: nil,
            codingPath: codingPath + [key],
            userInfo: self.decoder.userInfo,
            configuration: self.decoder.configuration
          )
        case "vin", "inputs":
          let contexts: [DataReaderContext]?
          if let keypath = M.keyPathMany["vin_witness"],
             let witnesses = map[keyPath: keypath] {
            contexts = witnesses.map({ DataReaderContext(payload: $0) })
          } else {
            contexts = nil
          }
          decoder = Bitcoin._Decoding.Decoder<_Reader.BitcoinTXInput>(
            data: value,
            context: contexts,
            map: nil,
            codingPath: codingPath + [key],
            userInfo: self.decoder.userInfo,
            configuration: self.decoder.configuration
          )
        case "witness", "txinwitness":
          decoder = Bitcoin._Decoding.Decoder<_Reader.Raw>(
            data: value,
            context: nil,
            map: nil,
            codingPath: codingPath + [key],
            userInfo: self.decoder.userInfo,
            configuration: self.decoder.configuration
          )
        case "vout", "outputs":
          decoder = Bitcoin._Decoding.Decoder<_Reader.BitcoinTXOutput>(
            data: value,
            context: nil,
            map: nil,
            codingPath: codingPath + [key],
            userInfo: self.decoder.userInfo,
            configuration: self.decoder.configuration
          )
        case "asm", "script":
          decoder = Bitcoin._Decoding.Decoder<_Reader.Op>(
            data: value,
            context: nil,
            map: nil,
            codingPath: codingPath + [key],
            userInfo: self.decoder.userInfo,
            configuration: self.decoder.configuration
          )
        default:
          throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Key \(key.stringValue) not found or not supported yet"))
        }
        
        return try T(from: decoder)
      }
      throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Key \(key.stringValue) not found or not supported yet"))
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { try self.decodeFixedWidthInteger(for: key) }
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { try self.decodeFixedWidthInteger(for: key) }
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { try self.decodeFixedWidthInteger(for: key) }
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 { try self.decodeFixedWidthInteger(for: key) }
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt { try self.decodeFixedWidthInteger(for: key) }
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 { try self.decodeFixedWidthInteger(for: key) }
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 { try self.decodeFixedWidthInteger(for: key) }
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 { try self.decodeFixedWidthInteger(for: key) }
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 { try self.decodeFixedWidthInteger(for: key) }
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int { try self.decodeFixedWidthInteger(for: key) }
    
    /// Decodes a fixed-width integer value for the given key.
    ///
    /// Reads the value from raw little-endian bytes using the associated key path.
    /// - Throws:
    ///   - `DecodingError.keyNotFound` if the field is missing.
    ///   - `DecodingError.typeMismatch` if the value is invalid.
    @inline(__always)
    func decodeFixedWidthInteger<T>(for key: Key) throws -> T where T: FixedWidthInteger {
      guard let keyPath = M.keyPathSingle[key.stringValue],
            let value = map[keyPath: keyPath] else {
        throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "No value associated with key \(key.stringValue)"))
      }
      do {
        return try value.readLE()
      } catch {
        throw DecodingError.typeMismatch(T.self, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "Incorrect type", underlyingError: error))
      }
    }
    
    /// Decoding for types such as `Float`, `Double`, `String`, and `Bool` is
    /// not supported in Bitcoin transaction formats and will always throw.
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath + [key], debugDescription: "Float values are not supported"))
    }
    
    /// Decoding for types such as `Float`, `Double`, `String`, and `Bool` is
    /// not supported in Bitcoin transaction formats and will always throw.
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath + [key], debugDescription: "Double values are not supported"))
    }
    
    /// Decoding for types such as `Float`, `Double`, `String`, and `Bool` is
    /// not supported in Bitcoin transaction formats and will always throw.
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath + [key], debugDescription: "String values are not supported"))
    }
    
    /// Decoding for types such as `Float`, `Double`, `String`, and `Bool` is
    /// not supported in Bitcoin transaction formats and will always throw.
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath + [key], debugDescription: "Bool values are not supported"))
    }
    
    /// Returns whether a key is known to this container.
    ///
    /// This checks `allKeys` and doesn't validate value presence.
    func contains(_ key: Key) -> Bool {
      return self.allKeys.contains(where: {
        $0.stringValue == key.stringValue
      })
    }
    
    /// Returns true if no value is associated with the given key path.
    ///
    /// - Note: This only checks for presence in the map and does not decode literal `null`.
    func decodeNil(forKey key: Key) throws -> Bool {
      if let keyPath = M.keyPathSingle[key.stringValue], map[keyPath: keyPath] != nil { return false }
      if let keyPath = M.keyPathMany[key.stringValue], map[keyPath: keyPath] != nil { return false }
      return true
    }
    
    /// Nested containers (`nestedContainer`, `nestedUnkeyedContainer`, `superDecoder`)
    /// are not supported and will throw if used.
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> Swift.KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Nested keyed containers are not supported"))
    }
    
    /// Nested containers (`nestedContainer`, `nestedUnkeyedContainer`, `superDecoder`)
    /// are not supported and will throw if used.
    func nestedUnkeyedContainer(forKey key: Key) throws -> any Swift.UnkeyedDecodingContainer {
      throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Nested unkeyed containers are not supported"))
    }
    
    /// Nested containers (`nestedContainer`, `nestedUnkeyedContainer`, `superDecoder`)
    /// are not supported and will throw if used.
    func superDecoder() throws -> any Swift.Decoder {
      throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Super decoder is not supported"))
    }
    
    /// Nested containers (`nestedContainer`, `nestedUnkeyedContainer`, `superDecoder`)
    /// are not supported and will throw if used.
    func superDecoder(forKey key: Key) throws -> any Swift.Decoder {
      throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Super decoder is not supported"))
    }
  }
}
