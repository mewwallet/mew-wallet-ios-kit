//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/18/25.
//

import Foundation

extension Bitcoin._Encoding {
  /// A custom implementation of `Swift.Encoder` used to encode Bitcoin-specific structures
  /// (e.g. transactions, scripts, PSBTs) into binary format with fine control over size encoding.
  ///
  /// This encoder works with `KeyedContainer`, `UnkeyedContainer`, and `SingleValueContainer`
  /// tailored to the Bitcoin serialization format. It supports `varInt` or disabled size prefixes.
  ///
  /// This class is not intended for general-purpose encoding; it assumes low-level control over
  /// output structure and is tightly coupled to Bitcoin's serialization rules.
  ///
  /// - Important: Use only in conjunction with `Bitcoin.Encoder`.
  internal final class Encoder: Swift.Encoder {
    /// The current coding path for nested container resolution.
    let codingPath: [any CodingKey]
    
    /// Any user-provided metadata or configuration during encoding.
    let userInfo: [CodingUserInfoKey : Any]
    
    /// The backing storage where encoded bytes are collected.
    let storage: Bitcoin._Encoding.Storage
    
    /// Encoding strategy for collection sizes (e.g., varInt or none).
    let sizeEncodingFormat: Bitcoin.Encoder.SizeEncodingFormat
    
    /// Initializes a new encoder instance.
    ///
    /// - Parameters:
    ///   - codingPath: The initial coding path for nested containers.
    ///   - userInfo: Any contextual information for encoding.
    ///   - storage: The output data storage buffer.
    ///   - sizeEncodingFormat: The strategy used for encoding size prefixes (e.g. `.varInt`).
    init(codingPath: [any CodingKey], userInfo: [CodingUserInfoKey : Any], storage: Bitcoin._Encoding.Storage, sizeEncodingFormat: Bitcoin.Encoder.SizeEncodingFormat) {
      self.codingPath = codingPath
      self.userInfo = userInfo
      self.storage = storage
      self.sizeEncodingFormat = sizeEncodingFormat
    }
    
    /// Creates a keyed encoding container.
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
      let container = Bitcoin._Encoding.KeyedContainer<Key>(encoder: self)
      return KeyedEncodingContainer(container)
    }
    
    /// Creates an unkeyed encoding container.
    func unkeyedContainer() -> any UnkeyedEncodingContainer {
      return Bitcoin._Encoding.UnkeyedContainer(encoder: self, key: self.codingPath.last)
    }
    
    /// Creates a single-value encoding container.
    func singleValueContainer() -> any SingleValueEncodingContainer {
      return Bitcoin._Encoding.SingleValueContainer(encoder: self)
    }
  }
}
