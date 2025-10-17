//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/9/25.
//

import Foundation
import mew_wallet_ios_kit_utils

extension Solana._ShortVecEncoding {
  /// A keyed encoding container that intentionally **does not support** keyed encoding
  /// for Solana’s positional wire formats.
  ///
  /// Solana transactions/messages are strictly positional (shortvec/varint + fixed fields),
  /// so keyed encoding is not used. This container exists to satisfy the `Encoder`
  /// protocol surface and will throw for all encode operations.
  ///
  /// If your type requires encoding, use the `UnkeyedContainer` (for ordered fields)
  /// or `SingleValueContainer` (for scalars/fixed-size blobs) instead.
  struct KeyedContainer<Key: CodingKey>: Swift.KeyedEncodingContainerProtocol {
    /// The current coding path (diagnostics only).
    var codingPath: [any CodingKey] { encoder.codingPath }
    
    /// The parent encoder used to access configuration and the binary output buffer.
    private let encoder: Solana._ShortVecEncoding.Encoder
    
    /// Initializes a new keyed encoding container.
    ///
    /// - Parameter encoder: The parent encoder.
    init(encoder: Solana._ShortVecEncoding.Encoder) {
      self.encoder = encoder
    }
    
    // MARK: - Generic Encodable
    
    /// Keyed encoding is not supported for Solana positional formats.
    mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "KeyedContainer is not supported"))
    }
    
    // MARK: - Fixed-Width Integer Support (unsupported in keyed form)
    
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
    
    /// Keyed fixed-width integer encoding is not supported; Solana wire format is positional.
    @inline(__always)
    mutating func encodeFixedWidthInteger<T>(_ value: T, for key: Key) throws where T: FixedWidthInteger {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "KeyedContainer is not supported"))
    }
    
    // MARK: - Unsupported Encodings (keyed)
    
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
    
    // MARK: - Nested Containers (explicitly unsupported to prevent misuse)
    
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
