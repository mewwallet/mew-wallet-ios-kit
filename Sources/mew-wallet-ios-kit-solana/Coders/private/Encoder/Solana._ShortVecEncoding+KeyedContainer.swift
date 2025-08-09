//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/9/25.
//

import Foundation
import mew_wallet_ios_kit_utils

extension Solana._ShortVecEncoding {
  struct KeyedContainer<Key: CodingKey>: Swift.KeyedEncodingContainerProtocol {
    var codingPath: [any CodingKey] { encoder.codingPath }
    
    /// The parent encoder used to access configuration and binary output buffer.
    private let encoder: Solana._ShortVecEncoding.Encoder
    
    /// Initializes a new keyed encoding container.
    ///
    /// - Parameter encoder: The parent encoder.
    init(encoder: Solana._ShortVecEncoding.Encoder) {
      self.encoder = encoder
    }
    
    mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "KeyedContainer is not supported"))
    }
    
    // MARK: - Fixed-Width Integer Support
    
    mutating func encode(_ value: UInt64, forKey key: Key) throws { try encodeFixedWidthInteger(value, for: key) }
    mutating func encode(_ value: UInt32, forKey key: Key) throws { try encodeFixedWidthInteger(value, for: key) }
    mutating func encode(_ value: UInt16, forKey key: Key) throws { try encodeFixedWidthInteger(value, for: key) }
    mutating func encode(_ value: UInt8, forKey key: Key) throws { try encodeFixedWidthInteger(value, for: key) }
    mutating func encode(_ value: UInt, forKey key: Key) throws { try encodeFixedWidthInteger(value, for: key) }
    mutating func encode(_ value: Int64, forKey key: Key) throws { try encodeFixedWidthInteger(value, for: key) }
    mutating func encode(_ value: Int32, forKey key: Key) throws { try encodeFixedWidthInteger(value, for: key) }
    mutating func encode(_ value: Int16, forKey key: Key) throws { try encodeFixedWidthInteger(value, for: key) }
    mutating func encode(_ value: Int8, forKey key: Key) throws { try encodeFixedWidthInteger(value, for: key) }
    mutating func encode(_ value: Int, forKey key: Key) throws { try encodeFixedWidthInteger(value, for: key) }
    
    /// Encodes a fixed-width integer unless the key is `"n"` (which is ignored).
    @inline(__always)
    mutating func encodeFixedWidthInteger<T>(_ value: T, for key: Key) throws where T: FixedWidthInteger {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "KeyedContainer is not supported"))
    }
    
    // MARK: - Unsupported Encodings
    
    mutating func encode(_ value: Float, forKey key: Key) throws {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "KeyedContainer is not supported"))
    }
    
    mutating func encode(_ value: Double, forKey key: Key) throws {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "KeyedContainer is not supported"))
    }
    
    mutating func encode(_ value: String, forKey key: Key) throws {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "KeyedContainer is not supported"))
    }
    
    mutating func encode(_ value: Bool, forKey key: Key) throws {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "KeyedContainer is not supported"))
    }
    
    mutating func encodeNil(forKey key: Key) throws {
      throw EncodingError.invalidValue("", EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "KeyedContainer is not supported"))
    }
    
    // MARK: - Nested Containers
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
      return KeyedEncodingContainer(KeyedContainer<NestedKey>(encoder: encoder))
    }
    
    mutating func nestedUnkeyedContainer(forKey key: Key) -> Swift.UnkeyedEncodingContainer {
      return UnkeyedContainer(encoder: self.encoder, key: key)
    }
    
    mutating func superEncoder() -> Swift.Encoder {
      encoder
    }
    
    mutating func superEncoder(forKey key: Key) -> Swift.Encoder {
      encoder
    }
  }
}
