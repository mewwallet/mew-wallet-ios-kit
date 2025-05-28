//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/14/25.
//

import Foundation

extension Bitcoin._Decoding {
  /// A generic implementation of `Decoder` for Bitcoin-specific binary structures.
  ///
  /// This decoder supports various decoding strategies based on the provided `DataReader`
  /// and optional `KeypathProvider` implementations. It can be customized for different
  /// parsing contexts (e.g., transactions, inputs, scripts).
  ///
  /// - Parameters:
  ///   - `M`: A type that conforms to both `DataReader` and `KeypathProvider`.
  internal final class Decoder<M: DataReader & KeypathProvider>: Swift.Decoder {
    /// The raw data slices to be decoded.
    let data: [Data.SubSequence]
    
    /// Optional parsing context information (e.g., versioning or flags).
    let context: [DataReaderContext]?
    
    /// Optional keypath maps describing expected key structures.
    let map: [M]?
    
    /// The current path of keys being decoded. Used for diagnostics and nested decoding.
    let codingPath: [any CodingKey]
    
    /// Arbitrary user-defined values available to decodable types during decoding.
    let userInfo: [CodingUserInfoKey : Any]
    
    /// Controls validation behavior and low-level decoding rules (e.g., script checks).
    let configuration: DataReaderConfiguration
    
    /// Initializes a new decoder with the specified state.
    ///
    /// - Parameters:
    ///   - data: An array of binary slices to decode.
    ///   - context: Optional decoding context (version flags, prior state, etc).
    ///   - map: map is a structure map for the binary layout, used for field-level key resolution if needed.
    ///   - codingPath: The initial coding path, empty by default.
    ///   - userInfo: Contextual values available to decode logic.
    ///   - configuration: Controls decoding rules, validation, and more.
    init(data: [Data.SubSequence], context: [DataReaderContext]?, map: [M]?, codingPath: [any CodingKey] = [], userInfo: [CodingUserInfoKey : Any], configuration: DataReaderConfiguration) {
      self.data = data
      self.context = context
      self.map = map
      self.codingPath = codingPath
      self.userInfo = userInfo
      self.configuration = configuration
    }
    
    /// Returns a keyed decoding container for the specified key type.
    ///
    /// - Throws: `DecodingError.typeMismatch` if data is not structured as expected.
    func container<Key>(keyedBy type: Key.Type) throws -> Swift.KeyedDecodingContainer<Key> where Key : CodingKey {
      guard self.data.count == 1, let data = self.data.first else {
        assertionFailure("Expected exactly one data segment, got \(self.data.count)")
        throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Expecting array"))
      }
      let container = try Bitcoin._Decoding.KeyedContainer<Key, M>(
        decoder: self,
        data: data,
        context: context?.first,
        map: map?.first
      )
      return Swift.KeyedDecodingContainer(container)
    }
    
    /// Returns an unkeyed decoding container.
    ///
    /// - Throws: `DecodingError` if the underlying data is not an array or valid sequence.
    func unkeyedContainer() throws -> any Swift.UnkeyedDecodingContainer {
      return try Bitcoin._Decoding.UnkeyedContainer<M>(
        decoder: self,
        data: data,
        context: context,
        maps: self.map
      )
    }
    
    /// Returns a single value container.
    ///
    /// - Throws: `DecodingError` if data is not singular or improperly structured.
    func singleValueContainer() throws -> any Swift.SingleValueDecodingContainer {
      guard self.data.count == 1, let data = self.data.first else {
        assertionFailure("Expected exactly one data segment, got \(self.data.count)")
        throw DecodingError.typeMismatch(Data.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Expecting array"))
      }
      return try Bitcoin._Decoding.SingleValueContainer<M>(
        decoder: self,
        data: data,
        context: context?.first,
        map: self.map?.first
      )
    }
  }
}
