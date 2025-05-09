//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/15/25.
//

import Foundation

extension PSBT._Decoding {
  /// A custom implementation of `UnkeyedDecodingContainer` for parsing arrays of values
  /// from PSBT binary structures. Supports decoding of fixed-width integers and Decodable
  /// elements from binary slices.
  ///
  /// This is typically used to decode PSBT fields that are represented as arrays, such as
  /// `PSBT.inputs`, `PSBT.outputs`, or `PSBT.txinwitness`.
  ///
  /// - Note: Binary values are expected to be little-endian unless handled explicitly.
  /// - Warning: Nested containers and unsupported types (Float, String, Bool, etc.) will throw.
  internal struct UnkeyedContainer<M: KeypathProvider & DataReader>: UnkeyedDecodingContainer {
    /// Path to the current position in the decoding hierarchy.
    var codingPath: [any CodingKey] { decoder.codingPath }
    
    /// Total number of elements (if determinable from context).
    var count: Int? { maps.count }
    
    /// Indicates if the container has reached the end of the available data.
    var isAtEnd: Bool { currentIndex >= maps.count }
    
    /// Index of the current element being decoded.
    var currentIndex: Int = 0
    
    /// Reference to the parent decoder.
    private let decoder: PSBT._Decoding.Decoder<M>
    
    /// Map responsible for extracting the actual value from raw PSBT binary data.
    private let maps: [M]
    
    /// Initializes an unkeyed container with optional pre-parsed maps or raw binary data.
    ///
    /// - Parameters:
    ///   - decoder: The outer PSBT decoder instance.
    ///   - data: A list of binary blobs representing the elements.
    ///   - context: Optional per-element context such as index or payload metadata.
    ///   - maps: Pre-parsed data readers; if not provided, they'll be parsed from `data`.
    init(decoder: PSBT._Decoding.Decoder<M>, data: [Data.SubSequence], context: [DataReaderContext]?, maps: [M]?) throws {
      self.decoder = decoder
      do {
        if let maps {
          self.maps = maps
        } else {
          var maps: [M] = []
          maps.reserveCapacity(data.count)
          var n: UInt32 = 0
          for data in data {
            var context = context?[Int(n)] ?? DataReaderContext(payload: nil)
            context.n = n
            let map = try M(data: data, context: context, configuration: DataReaderConfiguration(validation: .disabled))
            maps.append(map)
            n += 1
          }
          self.maps = maps
        }
      } catch {
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Corrupted data", underlyingError: error))
      }
    }
    
    /// Decodes the next value of type `T` in the array.
    /// Uses either `.raw` field or nested decoder based on keypath availability.
    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
      guard !isAtEnd else {
        throw DecodingError.valueNotFound(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Unkeyed container is at end."))
      }
      
      let value: [Data.SubSequence]
      let map: M
      
      // If `raw` is mapped for multiple values, decode through Raw reader
      if let keypath = M.keyPathMany["raw"] {
        map = maps[currentIndex]
        guard let mapValue = map[keyPath: keypath] else {
          throw DecodingError.valueNotFound(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Bad mapping"))
        }
        value = mapValue
        
        let key = AnyCodingKey(intValue: currentIndex)
        currentIndex += 1
        
        let decoder = PSBT._Decoding.Decoder<_Reader.Raw>(
          data: value,
          context: nil,
          map: nil,
          codingPath: codingPath + [key],
          userInfo: [:]
        )
        return try T(from: decoder)
      } else {
        let dataValue = self.decoder.data[currentIndex]
        map = self.maps[currentIndex]
        
        let key = AnyCodingKey(intValue: currentIndex)
        currentIndex += 1
        
        // Fallback to decoding using the actual data segment and map
        if let result = dataValue as? T {
          return result
        }
        value = [dataValue]
        
        let decoder = PSBT._Decoding.Decoder<M>(
          data: value,
          context: nil,
          map: [map],
          codingPath: codingPath + [key],
          userInfo: [:]
        )
        return try T(from: decoder)
      }
    }
    
    // MARK: - Fixed-width integers
    
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 { try decodeFixedWidthInteger() }
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 { try decodeFixedWidthInteger() }
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 { try decodeFixedWidthInteger() }
    mutating func decode(_ type: UInt8.Type) throws -> UInt8 { try decodeFixedWidthInteger() }
    mutating func decode(_ type: UInt.Type) throws -> UInt { try decodeFixedWidthInteger() }
    mutating func decode(_ type: Int64.Type) throws -> Int64 { try decodeFixedWidthInteger() }
    mutating func decode(_ type: Int32.Type) throws -> Int32 { try decodeFixedWidthInteger() }
    mutating func decode(_ type: Int16.Type) throws -> Int16 { try decodeFixedWidthInteger() }
    mutating func decode(_ type: Int8.Type) throws -> Int8 { try decodeFixedWidthInteger() }
    mutating func decode(_ type: Int.Type) throws -> Int { try decodeFixedWidthInteger() }
    
    @inline(__always)
    mutating func decodeFixedWidthInteger<T>() throws -> T where T: FixedWidthInteger {
      guard !isAtEnd else {
        throw DecodingError.valueNotFound(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Unkeyed container is at end."))
      }
      
      // Retrieve the value at the current index.
      let value = self.maps[currentIndex].raw
      // Create a coding key for this index to update the codingPath.
      let key = AnyCodingKey(intValue: currentIndex)
      currentIndex += 1
      
      do {
        return try value.readLE()
      } catch {
        throw DecodingError.typeMismatch(T.self, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "Incorrect type"))
      }
    }
    
    // MARK: - Unsupported decoding types
    
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
    
    func decodeNil() throws -> Bool {
      throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: codingPath, debugDescription: "decodeNil() is not supported"))
    }
    
    // MARK: - Unsupported container types
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Nested keyed containers are not supported"))
    }
    
    func nestedUnkeyedContainer() throws -> any UnkeyedDecodingContainer {
      throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Nested unkeyed containers are not supported"))
    }
    
    func superDecoder() throws -> any Swift.Decoder {
      throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Super decoder is not supported"))
    }
  }
}
