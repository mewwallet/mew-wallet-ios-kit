//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation

extension Solana._ShortVecEncoding {
  /// A custom unkeyed encoding container for serializing sequences in Bitcoin-specific binary format.
  ///
  /// This is used to encode arrays (e.g., inputs, outputs, witness data) in the Bitcoin transaction or PSBT format.
  /// It appends each element to the encoder’s binary `Storage`, optionally prepending length information using VarInt.
  ///
  /// ### Supported:
  /// - `Data`: Encoded with optional size prefix depending on encoder configuration.
  /// - `FixedWidthInteger`: Encoded in little-endian binary format.
  /// - `Encodable`: Recursively encoded via nested `Encoder`.
  ///
  /// ### Not supported:
  /// - `Float`, `Double`, `String`, `Bool`, `nil`
  ///
  /// ### Special cases:
  /// - If the container's `key` is `"script_witnesses"`, it prepends the count as a VarInt.
  struct UnkeyedContainer: Swift.UnkeyedEncodingContainer {
    /// The current path of coding keys taken to get to this container.
    var codingPath: [any CodingKey] { encoder.codingPath }
    
    /// The key that led to the creation of this unkeyed container (used to determine encoding rules).
    let key: (any CodingKey)?
    
    /// The number of elements encoded so far.
    var count: Int = 0
    
    /// The parent encoder.
    private let encoder: Solana._ShortVecEncoding.Encoder
    
    /// Initializes a new unkeyed container.
    ///
    /// - Parameters:
    ///   - encoder: The parent encoder instance.
    ///   - key: The coding key that created this container (optional).
    init(encoder: Solana._ShortVecEncoding.Encoder, key: (any CodingKey)?) {
      self.encoder = encoder
      self.key = key
    }
    
    /// Encodes a generic `Encodable` element into the container.
    ///
    /// - If it's `Data`, it's encoded directly with an optional size prefix.
    /// - Otherwise, it's recursively encoded using a nested encoder.
    /// - Special case: If the container is `"script_witnesses"`, writes a VarInt prefix for count.
    mutating func encode<T>(_ value: T) throws where T : Encodable {
      guard let data = value as? Data else {
        if let array = value as? [Any] {
          try self.encode(array.count)
        }
        // Encode using nested encoder
        let encoder = Solana._ShortVecEncoding.Encoder(
          codingPath: codingPath,
          userInfo: self.encoder.userInfo,
          storage: self.encoder.storage
        )
        try value.encode(to: encoder)
        return
      }
      
      // Directly encode raw data
      self.encoder.storage.append(data)
    }
    
    // MARK: - Fixed-width integer encoding
    
    mutating func encode(_ value: UInt64) throws { try self.encodeFixedWidthInteger(value) }
    mutating func encode(_ value: UInt32) throws { try self.encodeFixedWidthInteger(value) }
    mutating func encode(_ value: UInt16) throws { try self.encodeFixedWidthInteger(value) }
    mutating func encode(_ value: UInt8) throws { try self.encodeFixedWidthInteger(value) }
    mutating func encode(_ value: UInt) throws { try self.encodeFixedWidthInteger(value) }
    mutating func encode(_ value: Int64) throws { try self.encodeFixedWidthInteger(value) }
    mutating func encode(_ value: Int32) throws { try self.encodeFixedWidthInteger(value) }
    mutating func encode(_ value: Int16) throws { try self.encodeFixedWidthInteger(value) }
    mutating func encode(_ value: Int8) throws { try self.encodeFixedWidthInteger(value) }
    mutating func encode(_ value: Int) throws { try self.encodeFixedWidthInteger(value) }
    
    /// Encodes a fixed-width integer in little-endian format and increments `count`.
    @inline(__always)
    mutating func encodeFixedWidthInteger<T>(_ value: T) throws where T: FixedWidthInteger {
      var value = value
      repeat {
        var byte = UInt8(truncatingIfNeeded: value & 0x7F)
        value >>= 7
        if value != 0 { byte |= 0x80 }
        self.encoder.storage.append(byte)
      } while value != 0
      count += 1
    }
    
    // MARK: - Unsupported types
    
    mutating func encode(_ value: Float) throws {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Float values are not supported"))
    }
    
    mutating func encode(_ value: Double) throws {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Double values are not supported"))
    }
    
    mutating func encode(_ value: String) throws {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "String values are not supported"))
    }
    
    mutating func encode(_ value: Bool) throws {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Bool values are not supported"))
    }
    
    mutating func encodeNil() throws {
      throw EncodingError.invalidValue("", EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Nil values are not supported"))
    }
    
    // MARK: - Nested container support
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
      let container = KeyedContainer<NestedKey>(encoder: encoder)
      return KeyedEncodingContainer(container)
    }
    
    mutating func nestedUnkeyedContainer() -> Swift.UnkeyedEncodingContainer {
      return UnkeyedContainer(encoder: encoder, key: self.key)
    }
    
    mutating func superEncoder() -> Swift.Encoder {
      return encoder
    }
  }
}
