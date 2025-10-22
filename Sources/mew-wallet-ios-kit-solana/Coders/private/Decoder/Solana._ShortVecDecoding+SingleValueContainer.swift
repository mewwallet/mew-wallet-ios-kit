//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/10/25.
//

import Foundation

extension Solana._ShortVecDecoding {
  /// A single-value decoding container that reads primitive scalars or fixed-size
  /// byte slices directly from the parent shortvec-aware decoder.
  ///
  /// This container:
  /// - Advances the shared `decoder.offset` as bytes are consumed.
  /// - Handles Solana-specific cases (e.g., 32-byte public keys; version byte).
  /// - Decodes shortvec (base-128 varint) integers for all fixed-width integer types.
  internal struct SingleValueContainer: Swift.SingleValueDecodingContainer {
    /// The full coding path for diagnostics.
    var codingPath: [any CodingKey] { self.decoder.codingPath }
    
    /// Reference to the parent decoder (class reference; offset is shared & mutable).
    private let decoder: Solana._ShortVecDecoding.Decoder
    
    /// The decoding section/state captured at container creation.
    let section: Solana._ShortVecDecoding.Decoder.Section
    
    /// Creates a container bound to a specific decoder/state snapshot.
    init(decoder: Solana._ShortVecDecoding.Decoder) {
      self.decoder = decoder
      self.section = decoder.section
    }
    
    // MARK: - Generic Decodable entry point
    
    /// Dispatches to specialized implementations for Solana wire cases or falls back to type-driven decoding.
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
      switch self.section {
      case .message(.accountKeys) where type == Data.self:
        // Read a 32-byte slice (e.g., a public key) and return as `Data`.
        return try self.decoder.data.read(&self.decoder.offset, offsetBy: 32) as! T
        
      case .message(.addressTableLookups) where type == Data.self:
        // Read a 32-byte slice (e.g., a public key) and return as `Data`.
        return try self.decoder.data.read(&self.decoder.offset, offsetBy: 32) as! T
        
      case .message(.version):
        // Defer to the type's decoding; callers typically decode a single version byte first.
        return try T(from: self.decoder)
        
      default:
        throw DecodingError.dataCorruptedError(in: self, debugDescription: "Unknown field")
      }
    }
    
    // MARK: - FixedWidthInteger (shortvec varint) decoders
    
    func decode(_ type: UInt64.Type) throws -> UInt64 { try self.decodeShortVecInteger(type) }
    func decode(_ type: UInt32.Type) throws -> UInt32 { try self.decodeShortVecInteger(type) }
    func decode(_ type: UInt16.Type) throws -> UInt16 { try self.decodeShortVecInteger(type) }
    
    /// Decodes a single byte. Special-case the version field to ensure we **advance the offset**.
    func decode(_ type: UInt8.Type) throws -> UInt8 {
      switch self.decoder.section {
      case .message(.version):
        return self.decoder.data[self.decoder.offset]
      default:
        return try self.decoder.data.readLE(&self.decoder.offset)
      }
    }
    func decode(_ type: UInt.Type) throws -> UInt { try self.decodeShortVecInteger(type) }
    func decode(_ type: Int64.Type) throws -> Int64 { try self.decodeShortVecInteger(type) }
    func decode(_ type: Int32.Type) throws -> Int32 { try self.decodeShortVecInteger(type) }
    func decode(_ type: Int16.Type) throws -> Int16 { try self.decodeShortVecInteger(type) }
    func decode(_ type: Int8.Type) throws -> Int8 {
      let uint8: UInt8 = try self.decode(UInt8.self)
      return Int8(bitPattern: uint8)
    }
    func decode(_ type: Int.Type) throws -> Int { try self.decodeShortVecInteger(type) }
    
    // MARK: - Shortvec (base-128 varint) core
    
    /// Decodes a shortvec (base-128 varint) integer and returns it as `T`.
    ///
    /// The value is accumulated in `UInt64` to avoid overflow on small integer targets
    /// (e.g., `UInt8`) and converted exactly at the end. Throws if conversion cannot be exact.
    @inline(__always)
    func decodeShortVecInteger<T>(_ type: T.Type = T.self) throws -> T where T: FixedWidthInteger {
      var result: T = 0
      var shift: Int = 0
      
      while true {
        // Read the next continuation byte; advances shared offset.
        let byte: UInt8 = try decoder.data.readLE(&decoder.offset)
        
        // add 7 low bits
        let low7 = T(byte & 0x7F)
        
        // Pre-append overflow guard.
        if shift >= T.bitWidth || (low7 != 0 && shift > T.bitWidth - 7) {
          throw DecodingError.dataCorrupted(.init(codingPath: self.codingPath, debugDescription: "ShortVec overflow"))
        }
        
        result |= (low7 &<< T(shift))
        
        // If MSB not set, we're done.
        if (byte & 0x80) == 0 { break }
        
        shift &+= 7
        if shift >= T.bitWidth {
          throw DecodingError.dataCorrupted(.init(codingPath: self.codingPath, debugDescription: "ShortVec overflow"))
        }
      }
      
      return result
    }
    
    // MARK: - Unsupported types
    
    func decode(_ type: Float.Type) throws -> Float {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(type) not supported"))
    }
    
    func decode(_ type: Double.Type) throws -> Double {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(type) not supported"))
    }
    
    func decode(_ type: String.Type) throws -> String {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(type) not supported"))
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(type) not supported"))
    }
    
    func decodeNil() -> Bool {
      return false
    }
  }
}
