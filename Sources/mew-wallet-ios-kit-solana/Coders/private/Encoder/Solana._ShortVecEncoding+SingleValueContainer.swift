//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit_utils

extension Solana._ShortVecEncoding {
  /// A single-value encoding container for serializing raw values into Solana’s
  /// binary wire format.
  ///
  /// ### What this encodes
  /// - `Data`: appended to the output verbatim (no implicit length prefix).
  /// - `FixedWidthInteger`:
  ///   - **Unsigned** integers are encoded as **shortvec** (base-128 varint).
  ///   - **Signed** integers are supported only if **non-negative** and are encoded
  ///     via their unsigned magnitude as shortvec. Negative values are rejected.
  ///
  /// ### Not supported
  /// - `Float`, `Double`, `String`, `Bool`, `nil`.
  ///
  /// > Note:
  /// > Shortvec is used in Solana to encode **lengths/counts** (e.g., number of
  /// > signatures, number of keys, instruction data length). It is **not** a
  /// > general-purpose integer encoding for arbitrary signed values.
  struct SingleValueContainer: Swift.SingleValueEncodingContainer {
    
    /// The current coding path (diagnostics only).
    var codingPath: [CodingKey] { encoder.codingPath }
    
    /// Backing encoder and output buffer.
    private let encoder: Solana._ShortVecEncoding.Encoder
    
    /// Initializes a new single-value container.
    ///
    /// - Parameter encoder: The parent encoder instance.
    init(encoder: Solana._ShortVecEncoding.Encoder) {
      self.encoder = encoder
    }
    
    // MARK: - Generic Encodable
    
    /// Encodes a generic `Encodable` value.
    ///
    /// - If the value is `Data`, it is appended as-is.
    /// - Other `Encodable` types are **not supported** by this container.
    mutating func encode<T>(_ value: T) throws where T : Encodable {
      guard let data = value as? Data else {
        throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Non-Data values are not supported"))
      }
      
      // Directly encode raw data
      self.encoder.storage.append(data)
    }
    
    // MARK: - Fixed-width integers (shortvec lengths)
    
    // Unsigned — encode directly as shortvec (base-128 varint)
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
    
    /// Encodes an **unsigned** integer using Solana's shortvec (base-128 varint).
    ///
    /// - Parameter value: The non-negative integer to encode.
    /// - Important: This is **not** little-endian fixed-width encoding; it is a
    ///   variable-length, continuation-bit format used for lengths/counts.
    @inline(__always)
    mutating func encodeShortVecInteger<T>(_ value: T) throws where T: FixedWidthInteger {
      var value = value
      repeat {
        var byte = UInt8(truncatingIfNeeded: value & 0x7F)
        value >>= 7
        if value != 0 { byte |= 0x80 } // set continuation bit
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
