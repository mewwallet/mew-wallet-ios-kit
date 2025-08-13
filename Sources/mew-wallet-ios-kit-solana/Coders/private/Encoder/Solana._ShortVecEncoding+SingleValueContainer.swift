//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit_utils

extension Solana._ShortVecEncoding {
  /// A custom single value encoding container used for serializing raw values
  /// into Bitcoin-compatible binary formats.
  ///
  /// This encoder is designed to support encoding of fixed-width integers and raw `Data`,
  /// optionally prefixing them with a `VarInt` size (depending on encoder configuration).
  ///
  /// ### Supported types:
  /// - `Data`: Directly encoded, with optional `VarInt` size prefix.
  /// - `FixedWidthInteger`: Encoded in little-endian format.
  /// - `Encodable`: Encoded recursively using a nested encoder.
  ///
  /// ### Limitations:
  /// - `Float`, `Double`, `String`, `Bool`, and `nil` values are **not supported**.
  ///
  /// This container is typically used for individual fields in Bitcoin transactions
  /// (e.g. script, locktime, version, witness elements).
  struct SingleValueContainer: Swift.SingleValueEncodingContainer {
    
    /// The current path of coding keys taken to get to this point in encoding.
    var codingPath: [CodingKey] { encoder.codingPath }
    
    /// The backing encoder.
    private let encoder: Solana._ShortVecEncoding.Encoder
    
    /// Initializes a new single value container.
    ///
    /// - Parameter encoder: The parent encoder instance.
    init(encoder: Solana._ShortVecEncoding.Encoder) {
      self.encoder = encoder
    }
    
    /// Encodes a generic `Encodable` value.
    ///
    /// - If the value is `Data`, it's directly encoded with an optional size prefix.
    /// - Otherwise, a nested encoder is used and the encoded result is prefixed with size.
    mutating func encode<T>(_ value: T) throws where T : Encodable {
      guard let data = value as? Data else {
        throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Non-Data values are not supported"))
      }
      
      // Directly encode raw data
      self.encoder.storage.append(data)
    }
    
    // MARK: - Fixed-width integer encodings
    
    mutating func encode(_ value: UInt64) throws { try self.encodeShortVecInteger(value) }
    mutating func encode(_ value: UInt32) throws { try self.encodeShortVecInteger(value) }
    mutating func encode(_ value: UInt16) throws { try self.encodeShortVecInteger(value) }
    mutating func encode(_ value: UInt8) throws { try self.encodeShortVecInteger(value) }
    mutating func encode(_ value: UInt) throws { try self.encodeShortVecInteger(value) }
    mutating func encode(_ value: Int64) throws { try self.encodeShortVecInteger(value) }
    mutating func encode(_ value: Int32) throws { try self.encodeShortVecInteger(value) }
    mutating func encode(_ value: Int16) throws { try self.encodeShortVecInteger(value) }
    mutating func encode(_ value: Int8) throws { try self.encodeShortVecInteger(value) }
    mutating func encode(_ value: Int) throws { try self.encodeShortVecInteger(value) }
    
    /// Encodes any fixed-width integer in little-endian format.
    ///
    /// - Parameter value: The integer to encode.
    @inline(__always)
    mutating func encodeShortVecInteger<T>(_ value: T) throws where T: FixedWidthInteger {
      var value = value
      repeat {
        var byte = UInt8(truncatingIfNeeded: value & 0x7F)
        value >>= 7
        if value != 0 { byte |= 0x80 }
        self.encoder.storage.append(byte)
      } while value != 0
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
      throw EncodingError.invalidValue(Any.self, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "nil values are not supported"))
    }
  }
}
