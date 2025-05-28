//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/11/25.
//

import Foundation

extension PSBT._Decoding {
  /// A custom `Decoder` for parsing PSBT (Partially Signed Bitcoin Transaction) data
  /// using a binary `DataReader` model and Bitcoin-specific decoding infrastructure.
  ///
  /// This decoder is responsible for constructing decoding containers for:
  /// - Keyed data (e.g., global map, input map, output map)
  /// - Unkeyed data (e.g., sequences of unknown elements or repeated keys)
  /// - Single values (e.g., raw payloads or script elements)
  ///
  /// This class is generic over a `DataReader` and `KeypathProvider` type that defines how
  /// binary data is mapped into semantic keys and types.
  internal final class Decoder<M: DataReader & KeypathProvider>: Swift.Decoder {
    /// Binary data fragments to be decoded, often VarInt-prefixed.
    let data: [Data.SubSequence]
    
    /// Optional contextual information (e.g. for indexing or witness context).
    let context: [DataReaderContext]?
    
    /// Optional decoded map objects, one per data chunk.
    let map: [M]?
    
    /// Current decoding path (for diagnostics and recursion).
    let codingPath: [any CodingKey]
    
    /// Arbitrary user info provided by the caller.
    let userInfo: [CodingUserInfoKey: Any]
    
    /// Constructs a new PSBT decoder for the given data payload.
    ///
    /// - Parameters:
    ///   - data: Raw binary chunks to decode.
    ///   - context: Optional context for decoding logic.
    ///   - map: Optional pre-parsed maps (e.g. structured PSBT fields).
    ///   - codingPath: Initial coding path (defaults to empty).
    ///   - userInfo: Custom user data (e.g. used by downstream tools).
    init(data: [Data.SubSequence], context: [DataReaderContext]?, map: [M]?, codingPath: [any CodingKey] = [], userInfo: [CodingUserInfoKey : Any]) {
      self.data = data
      self.map = map
      self.context = context
      self.codingPath = codingPath
      self.userInfo = userInfo
    }
    
    /// Creates a keyed container for decoding structured key-value pairs (e.g. PSBT maps).
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
      guard self.data.count == 1, let data = self.data.first else {
        throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Expecting array"))
      }
      let container = try PSBT._Decoding.KeyedContainer<Key, M>(
        decoder: self,
        data: data,
        context: nil
      )
      return KeyedDecodingContainer(container)
    }
    
    /// Creates an unkeyed container for decoding an ordered list of elements.
    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
      return try PSBT._Decoding.UnkeyedContainer<M>(
        decoder: self,
        data: data,
        context: context,
        maps: map
      )
    }
    
    /// Creates a single-value container for decoding a primitive value or wrapped structure.
    func singleValueContainer() throws -> any SingleValueDecodingContainer {
      guard self.data.count == 1, let data = self.data.first else {
        throw DecodingError.typeMismatch([UInt8].self, DecodingError.Context(codingPath: codingPath, debugDescription: "Expecting array"))
      }
      return try PSBT._Decoding.SingleValueContainer<M>(
        decoder: self,
        data: data,
        context: context?.first
      )
    }
  }
}
