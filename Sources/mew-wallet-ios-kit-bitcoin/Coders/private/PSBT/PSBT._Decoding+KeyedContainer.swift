//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/15/25.
//

import Foundation

extension PSBT._Decoding {
  /// A custom implementation of `KeyedDecodingContainerProtocol` for decoding key-value pairs
  /// in PSBT (Partially Signed Bitcoin Transaction) binary data.
  ///
  /// This container supports both single-value and multi-value fields, and provides decoding
  /// logic for various PSBT keys such as `non_witness_utxo`, `witness_utxo`, `inputs`, `outputs`,
  /// `redeem_script`, and more.
  ///
  /// Generic over:
  /// - `Key`: The coding key type (e.g., `CodingKeys`)
  /// - `M`: A type that conforms to both `KeypathProvider` and `DataReader` and knows how
  ///        to extract binary data for given semantic keys.
  internal struct KeyedContainer<Key: CodingKey, M: KeypathProvider & DataReader>: KeyedDecodingContainerProtocol {
    /// All keys known by this container, derived from the key path mappings in `M`.
    let allKeys: [Key]
    
    /// The current decoding path.
    var codingPath: [any CodingKey] { decoder.codingPath }
    
    /// Reference to the parent decoder context.
    private let decoder: PSBT._Decoding.Decoder<M>
    
    /// Parsed binary data structure that exposes typed access.
    private let map: M
    
    /// Initializes the container with raw data and parses it using the provided map type `M`.
    ///
    /// - Parameters:
    ///   - decoder: The outer PSBT decoder instance.
    ///   - data: The raw binary data for the container.
    ///   - context: Optional reader context (e.g. input index or witness info).
    ///
    /// - Throws: `DecodingError.dataCorrupted` if parsing fails.
    init(decoder: PSBT._Decoding.Decoder<M>, data: Data.SubSequence, context: DataReaderContext?) throws {
      self.decoder = decoder
      self.allKeys = M.keyPathSingle.keys.compactMap(Key.init) + M.keyPathMany.keys.compactMap(Key.init)
      do {
        self.map = try M(data: data, context: context, configuration: DataReaderConfiguration(validation: .all))
      } catch {
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Corrupted data", underlyingError: error))
      }
    }
        
    /// Attempts to decode a value of type `T` for the given key by dispatching to the appropriate decoder.
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
      let decoder: any Swift.Decoder
      let value: [Data.SubSequence]
      if let keyPath = M.keyPathSingle[key.stringValue] {
        guard let mapValue = map[keyPath: keyPath] else {
          throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "No value associated with key \(key.stringValue)"))
        }
        // If the value is already of the expected type, return it directly.
        if let typedValue = mapValue as? T {
          return typedValue
        }
        value = [mapValue]
      } else if let keyPath = M.keyPathMany[key.stringValue] {
        guard let mapValue = map[keyPath: keyPath] else {
          throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "No value associated with key \(key.stringValue)"))
        }
        
        // If the value is already of the expected type, return it directly.
        if let typedValue = mapValue as? T {
          return typedValue
        }
        value = mapValue
      } else {
        throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "No value associated with key \(key.stringValue)"))
      }
      
      let codingPath = codingPath + [key]
      
      // Dispatch decoding to appropriate type based on known PSBT key names.
      switch key.stringValue {
      case "non_witness_utxo", "nonWitnessUTXO":
        decoder = Bitcoin._Decoding.Decoder<_Reader.BitcoinTx>(
          data: value,
          context: nil,
          map: nil,
          codingPath: codingPath,
          userInfo: self.decoder.userInfo,
          configuration: DataReaderConfiguration(validation: .disabled)
        )
      case "tx":
        decoder = Bitcoin._Decoding.Decoder<_Reader.BitcoinTx>(
          data: value,
          context: nil,
          map: nil,
          codingPath: codingPath,
          userInfo: self.decoder.userInfo,
          configuration: DataReaderConfiguration(validation: .all)
        )
      case "inputs":
        decoder = PSBT._Decoding.Decoder<_Reader.PSBTInput>(
          data: value,
          context: nil,
          map: nil,
          codingPath: codingPath,
          userInfo: self.decoder.userInfo
        )
      case "outputs":
        decoder = PSBT._Decoding.Decoder<_Reader.PSBTOutput>(
          data: value,
          context: nil,
          map: nil,
          codingPath: codingPath,
          userInfo: self.decoder.userInfo
        )
      case "witness_script", "witnessScript":
        decoder = Bitcoin._Decoding.Decoder<_Reader.Script>(
          data: value,
          context: nil,
          map: nil,
          codingPath: codingPath,
          userInfo: self.decoder.userInfo,
          configuration: DataReaderConfiguration(validation: .disabled)
        )
      case "redeem_script", "redeemScript":
        decoder = Bitcoin._Decoding.Decoder<_Reader.Script>(
          data: value,
          context: nil,
          map: nil,
          codingPath: codingPath,
          userInfo: self.decoder.userInfo,
          configuration: DataReaderConfiguration(validation: .disabled)
        )
      case "final_scriptSig", "finalScriptSig":
        decoder = Bitcoin._Decoding.Decoder<_Reader.Script>(
          data: value,
          context: nil,
          map: nil,
          codingPath: codingPath,
          userInfo: self.decoder.userInfo,
          configuration: DataReaderConfiguration(validation: .disabled)
        )
      case "witness_utxo", "witnessUTXO":
        decoder = Bitcoin._Decoding.Decoder<_Reader.BitcoinTXOutput>(
          data: value,
          context: nil,
          map: nil,
          codingPath: codingPath,
          userInfo: self.decoder.userInfo,
          configuration: DataReaderConfiguration(validation: .disabled)
        )
      case "sighash", "sigHash":
        decoder = Bitcoin._Decoding.Decoder<_Reader.Raw>(
          data: value,
          context: nil,
          map: nil,
          codingPath: codingPath,
          userInfo: self.decoder.userInfo,
          configuration: DataReaderConfiguration(validation: .disabled)
        )
      default:
        throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Key \(key.stringValue) not found or not supported yet"))
      }
      
      return try T(from: decoder)
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
    
    // MARK: - Optional / nested
    
    func contains(_ key: Key) -> Bool {
      return self.allKeys.contains(where: {
        $0.stringValue == key.stringValue
      })
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
      if let keyPath = M.keyPathSingle[key.stringValue], map[keyPath: keyPath] != nil { return false }
      if let keyPath = M.keyPathMany[key.stringValue], map[keyPath: keyPath] != nil { return false }
      return true
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Nested keyed containers are not supported"))
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer {
      throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Nested unkeyed containers are not supported"))
    }
    
    func superDecoder() throws -> any Swift.Decoder {
      throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Super decoder is not supported"))
    }
    
    func superDecoder(forKey key: Key) throws -> any Swift.Decoder {
      throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Super decoder is not supported"))
    }
  }
}
