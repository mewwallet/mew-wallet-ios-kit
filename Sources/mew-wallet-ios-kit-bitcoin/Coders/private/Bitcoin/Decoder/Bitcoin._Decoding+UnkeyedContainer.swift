//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/14/25.
//

import Foundation

extension Bitcoin._Decoding {
  /// An internal implementation of `UnkeyedDecodingContainer` used for decoding
  /// ordered binary sequences in Bitcoin data structures such as transaction inputs,
  /// outputs, or witness arrays.
  ///
  /// This container iterates over an array of binary elements and decodes them into
  /// values of a specific type, leveraging the Bitcoin-specific `DataReader` infrastructure.
  ///
  /// ### Capabilities:
  /// - Supports decoding of fixed-width integers in little-endian format.
  /// - Allows decoding nested `Decodable` objects from raw or mapped values.
  ///
  /// ### Limitations:
  /// - No support for `String`, `Bool`, `Float`, or `Double` decoding.
  /// - Nil values and nested containers are explicitly not supported.
  /// - Only supports linear, sequential access to elements.
  ///
  /// This container is designed to support both structured maps and raw binary decoding.
  internal struct UnkeyedContainer<M: KeypathProvider & DataReader>: Swift.UnkeyedDecodingContainer {
    /// Current coding path, inherited from the parent decoder.
    var codingPath: [any CodingKey] { decoder.codingPath }
    
    /// The total number of decodable elements, if known.
    var count: Int? { self.maps.count }
    
    /// Boolean indicating if all elements have been decoded.
    var isAtEnd: Bool {
      currentIndex >= self.maps.count
    }
    
    /// The current index into the sequence of elements.
    var currentIndex: Int = 0
    
    /// Parent decoder used to propagate configuration and context.
    private let decoder: Bitcoin._Decoding.Decoder<M>
    
    /// Parsed map instances (either pre-provided or dynamically parsed from raw).
    private let maps: [M]
    
    /// Initializes an unkeyed decoding container.
    ///
    /// - Parameters:
    ///   - decoder: The parent decoder instance.
    ///   - data: An array of `Data.SubSequence` chunks to be decoded.
    ///   - context: Optional array of contextual information for each chunk.
    ///   - maps: Optional pre-parsed maps for each element.
    ///
    /// - Throws: `DecodingError.dataCorrupted` if any element fails to decode into a valid map.
    init(decoder: Bitcoin._Decoding.Decoder<M>, data: [Data.SubSequence], context: [DataReaderContext]?, maps: [M]?) throws {
      do {
        self.decoder = decoder
        if let maps {
          self.maps = maps
        } else {
          var maps: [M] = []
          maps.reserveCapacity(data.count)
          var n: UInt32 = 0
          for data in data {
            var context = context?[Int(n)] ?? DataReaderContext(payload: nil)
            context.n = n
            let map = try M(data: data, context: context, configuration: decoder.configuration)
            maps.append(map)
            n += 1
          }
          self.maps = maps
        }
      } catch {
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Corrupted data", underlyingError: error))
      }
    }
    
    /// Decodes the next value in the array to a `Decodable` object.
    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
      guard !isAtEnd else {
        throw DecodingError.valueNotFound(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Unkeyed container is at end."))
      }
      
      let value: [Data.SubSequence]
      let map: M
      
      if let keypath = M.keyPathMany["raw"] {
        map = maps[currentIndex]
        guard let mapValue = map[keyPath: keypath] else {
          throw DecodingError.valueNotFound(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Bad mapping"))
        }
        value = mapValue
        
        let key = AnyCodingKey(intValue: currentIndex)
        currentIndex += 1
        
        let decoder = Bitcoin._Decoding.Decoder<_Reader.Raw>(
          data: value,
          context: nil,
          map: nil,
          codingPath: codingPath + [key],
          userInfo: self.decoder.userInfo,
          configuration: self.decoder.configuration
        )
        return try T(from: decoder)
      } else {
        let dataValue = self.maps[currentIndex].raw
        map = self.maps[currentIndex]
        
        let key = AnyCodingKey(intValue: currentIndex)
        currentIndex += 1
        
        if let result = dataValue as? T {
          return result
        }
        value = [dataValue]
        
        let decoder = Bitcoin._Decoding.Decoder<M>(
          data: value,
          context: nil,
          map: [map],
          codingPath: codingPath + [key],
          userInfo: self.decoder.userInfo,
          configuration: self.decoder.configuration
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
    
    // MARK: - Unsupported
    
    func decode(_ type: Float.Type) throws -> Float {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Float values are not supported"))
    }
    
    func decode(_ type: Double.Type) throws -> Double {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Double values are not supported"))
    }
    
    func decode(_ type: String.Type) throws -> String {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "String values are not supported"))
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Bool values are not supported"))
    }
    
    func decodeNil() throws -> Bool {
      throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Nil values are not supported"))
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> Swift.KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Nested keyed containers are not supported"))
    }
    
    func nestedUnkeyedContainer() throws -> any Swift.UnkeyedDecodingContainer {
      throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Nested unkeyed containers are not supported"))
    }
    
    func superDecoder() throws -> any Swift.Decoder {
      throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Super decoder is not supported"))
    }
  }
}
