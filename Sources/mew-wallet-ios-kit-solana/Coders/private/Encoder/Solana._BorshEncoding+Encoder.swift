//
//  Solana._BorshEncoding+Encoder.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit_utils

extension Solana._BorshEncoding {
  /// A simple encoder for Borsh serialization that handles basic types.
  internal final class Encoder: Swift.Encoder {
    /// The current coding path for nested container resolution.
    let codingPath: [any CodingKey]
    
    /// Any user-provided metadata or configuration during encoding.
    let userInfo: [CodingUserInfoKey : Any]
    
    /// The storage for accumulated encoded data.
    let storage: BinaryStorage
    
    /// Initializes a new encoder instance.
    init(codingPath: [any CodingKey], userInfo: [CodingUserInfoKey : Any], storage: BinaryStorage) {
      self.codingPath = codingPath
      self.userInfo = userInfo
      self.storage = storage
    }
    
    /// Creates a keyed encoding container.
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
      let container = Solana._BorshEncoding.KeyedContainer<Key>(encoder: self)
      return KeyedEncodingContainer(container)
    }
    
    /// Creates an unkeyed encoding container.
    func unkeyedContainer() -> any UnkeyedEncodingContainer {
      let container = Solana._BorshEncoding.UnkeyedContainer(encoder: self)
      return container
    }
    
    /// Creates a single-value encoding container.
    func singleValueContainer() -> any SingleValueEncodingContainer {
      let container = Solana._BorshEncoding.SingleValueContainer(encoder: self)
      return container
    }
  }
}
