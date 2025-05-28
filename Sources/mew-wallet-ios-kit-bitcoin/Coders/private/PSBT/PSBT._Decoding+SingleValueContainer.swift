//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/15/25.
//

import Foundation

extension PSBT._Decoding {
  /// A `SingleValueDecodingContainer` implementation tailored for decoding single values
  /// from PSBT binary structures. It is used when decoding fields that contain one atomic
  /// value (e.g., `sighash`) or one nested structure (e.g., a single `tx` transaction).
  ///
  /// This decoder works with types conforming к `KeypathProvider` and `DataReader`, allowing
  /// value extraction through declarative mappings from binary PSBT data.
  ///
  /// - Supports: Fixed-width integers and contextually nested Decodable values.
  /// - Limitations:
  ///   - Floating-point, boolean, and string types are not supported and will throw.
  ///   - Only specific key contexts (e.g., `"tx"`) are allowed for nested decoding.
  ///   - Binary values are expected in little-endian format unless handled externally.
  internal struct SingleValueContainer<M: KeypathProvider & DataReader>: SingleValueDecodingContainer {
    /// The current decoding path (used for error reporting and nested decoding).
    var codingPath: [any CodingKey] { decoder.codingPath }
    
    /// Reference to the parent decoder.
    private let decoder: PSBT._Decoding.Decoder<M>
    
    /// Map responsible for extracting the actual value from raw PSBT binary data.
    private let map: M
    
    /// Initializes the single value container and parses the data into a map.
    ///
    /// - Parameters:
    ///   - decoder: The outer PSBT decoder.
    ///   - data: A binary slice containing the encoded value.
    ///   - context: Optional contextual info (e.g., index in inputs or outputs).
    ///
    /// - Throws: `DecodingError.dataCorrupted` if decoding fails.
    init(decoder: PSBT._Decoding.Decoder<M>, data: Data.SubSequence, context: DataReaderContext?) throws {
      self.decoder = decoder
      do {
        self.map = try M(data: data, context: context, configuration: DataReaderConfiguration(validation: .disabled))
      } catch {
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Corrupted data", underlyingError: error))
      }
    }
    
    /// Attempts to decode the value directly or via a nested decoder if needed.
    ///
    /// - Parameter type: The expected Decodable type.
    /// - Throws:
    ///   - `DecodingError.keyNotFound` if no decoder path is available for the current key.
    ///   - Any decoding error encountered during nested decoding.
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
        decoder = PSBT._Decoding.Decoder<M>(
          data: [self.map.raw],
          context: self.map.context != nil ? [self.map.context!] : nil,
          map: nil,
          codingPath: codingPath,
          userInfo: self.decoder.userInfo
        )
      default:
        throw DecodingError.keyNotFound(self.codingPath.last ?? AnyCodingKey(stringValue: ""), DecodingError.Context(codingPath: self.codingPath, debugDescription: "Not found or not supported yet"))
      }
      
      return try T(from: decoder)
    }
    
    // MARK: - Fixed-width Integer Decoding
    
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
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(type) is not supported"))
    }
    
    func decode(_ type: Double.Type) throws -> Double {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(type) is not supported"))
    }
    
    func decode(_ type: String.Type) throws -> String {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(type) is not supported"))
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(type) is not supported"))
    }
    
    /// Always returns `false`, since `nil` decoding is not supported.
    func decodeNil() -> Bool {
      return false
    }
  }
}
