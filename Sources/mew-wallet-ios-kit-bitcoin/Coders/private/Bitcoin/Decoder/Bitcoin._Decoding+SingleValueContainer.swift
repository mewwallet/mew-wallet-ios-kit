//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/14/25.
//

import Foundation

extension Bitcoin._Decoding {
  /// A `SingleValueDecodingContainer` implementation used in the Bitcoin decoding pipeline.
  ///
  /// This container is specialized for decoding binary-encoded, single-value fields from
  /// Bitcoin-related data structures such as transactions, inputs, outputs, and scripts.
  ///
  /// ### Features:
  /// - Decodes little-endian fixed-width integers (e.g., `UInt32`, `Int64`, etc.)
  /// - Supports decoding nested types if the context is known (e.g., `tx`)
  /// - Strictly rejects unsupported types such as `String`, `Float`, `Bool`
  ///
  /// ### Limitations:
  /// - Only supports nested decoding for known keys (currently `tx`)
  /// - No support for dynamic or string-based type resolution
  /// - Decoding logic assumes low-level Bitcoin binary layout (non-JSON)
  ///
  /// - Note: All numeric types are decoded using little-endian byte order.
  /// - Warning: If the context (`map`) is malformed or unknown, decoding will fail.
  internal struct SingleValueContainer<M: KeypathProvider & DataReader>: Swift.SingleValueDecodingContainer {
    /// The full path of the current decoding operation.
    var codingPath: [any CodingKey] { self.decoder.codingPath }
    
    /// Reference to the parent decoder context.
    private let decoder: Bitcoin._Decoding.Decoder<M>
    
    /// Parsed binary data structure that exposes typed access.
    private let map: M
    
    /// Initializes a single-value container using a decoder and raw binary input.
    ///
    /// - Parameters:
    ///   - decoder: The parent decoder managing the decoding process.
    ///   - data: A slice of the raw binary input.
    ///   - context: Optional additional context (e.g., witness metadata).
    ///   - map: Optional pre-parsed map; a new one is created if nil.
    ///
    /// - Throws: `DecodingError.dataCorrupted` if the data cannot be interpreted.
    init(decoder: Bitcoin._Decoding.Decoder<M>, data: Data.SubSequence, context: DataReaderContext?, map: M?) throws {
      do {
        self.decoder = decoder
        self.map = try map ?? M(data: data, context: context, configuration: decoder.configuration)
      } catch {
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Corrupted data", underlyingError: error))
      }
    }
    
    /// Attempts to decode a generic `Decodable` value.
    ///
    /// - If the raw value (`map.raw`) already matches the requested type, it is returned directly.
    /// - If nested decoding is needed (e.g., `tx`), a new internal decoder is created.
    /// - All other cases result in a `keyNotFound` error.
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
      // If the value is already of the expected type, return it directly.
      if let typedValue = self.map.raw as? T {
        return typedValue
      }
      
      // Otherwise, attempt to decode it as a nested Decodable type.
      // Create a new decoder with updated coding path.
      
      let decoder: any Swift.Decoder
      switch self.codingPath.last?.stringValue {
      case "tx":
        decoder = Bitcoin._Decoding.Decoder<M>(
          data: [self.map.raw],
          context: self.map.context != nil ? [self.map.context!] : nil,
          map: [self.map],
          codingPath: codingPath,
          userInfo: self.decoder.userInfo,
          configuration: self.decoder.configuration
        )
      default:
        throw DecodingError.keyNotFound(self.codingPath.last ?? AnyCodingKey(stringValue: ""), DecodingError.Context(codingPath: self.codingPath, debugDescription: "Not found or not supported yet"))
      }
      
      return try T(from: decoder)
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 { try self.decodeFixedWidthInteger(type) }
    func decode(_ type: UInt32.Type) throws -> UInt32 { try self.decodeFixedWidthInteger(type) }
    func decode(_ type: UInt16.Type) throws -> UInt16 { try self.decodeFixedWidthInteger(type) }
    func decode(_ type: UInt8.Type) throws -> UInt8 { try self.decodeFixedWidthInteger(type) }
    func decode(_ type: UInt.Type) throws -> UInt { try self.decodeFixedWidthInteger(type) }
    func decode(_ type: Int64.Type) throws -> Int64 { try self.decodeFixedWidthInteger(type) }
    func decode(_ type: Int32.Type) throws -> Int32 { try self.decodeFixedWidthInteger(type) }
    func decode(_ type: Int16.Type) throws -> Int16 { try self.decodeFixedWidthInteger(type) }
    func decode(_ type: Int8.Type) throws -> Int8 { try self.decodeFixedWidthInteger(type) }
    func decode(_ type: Int.Type) throws -> Int { try self.decodeFixedWidthInteger(type) }
    
    /// Reads a fixed-width integer using little-endian format.
    ///
    /// - Throws: `DecodingError.typeMismatch` if decoding fails or types mismatch.
    @inline(__always)
    func decodeFixedWidthInteger<T>(_ type: T.Type) throws -> T where T: FixedWidthInteger {
      do {
        return try self.map.raw.readLE()
      } catch {
        throw DecodingError.typeMismatch(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Incorrect value", underlyingError: error))
      }
    }
    
    // MARK: - Unsupported Decoding
    
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
    
    /// Binary Bitcoin fields are never `nil`.
    func decodeNil() -> Bool {
      return false
    }
  }
}
