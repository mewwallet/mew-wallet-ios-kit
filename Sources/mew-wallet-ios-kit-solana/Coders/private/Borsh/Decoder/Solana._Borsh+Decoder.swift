//
//  Solana._BorshEncoding+Decoder.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit_utils

extension Solana._Borsh {
  /// A decoder for Borsh deserialization with sections for structured data.
  internal final class Decoder: Swift.Decoder {

    /// The current coding path for nested container resolution.
    let codingPath: [any CodingKey]
    
    /// Any user-provided metadata or configuration during decoding.
    let userInfo: [CodingUserInfoKey : Any]
    
    /// The input data to decode from.
    let data: Data
    
    /// Current position in the data.
    internal var currentIndex: Int = 0
    
    /// Current section being decoded
    var section: Section
    
    /// Sections for structured decoding
    enum Section {
      case universal
      case publicKey
    }
    
    /// Initializes a new decoder instance.
      init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any], data: Data, section: Section = .universal) {
      self.codingPath = codingPath
      self.userInfo = userInfo
      self.data = data
      self.currentIndex = 0
      self.section = section
    }
    
    /// Creates a keyed decoding container (not supported in Borsh).
    func container<Key>(keyedBy type: Key.Type) throws -> Swift.KeyedDecodingContainer<Key> where Key : CodingKey {
      throw DecodingError.dataCorrupted(DecodingError.Context(
        codingPath: codingPath,
        debugDescription: "Keyed containers are not supported in Borsh decoding"
      ))
    }
    
    /// Creates an unkeyed decoding container.
    func unkeyedContainer() throws -> Swift.UnkeyedDecodingContainer {
      let container = Solana._Borsh.UnkeyedDecodingContainer(decoder: self)
      return container
    }
    
    /// Creates a single-value decoding container.
    func singleValueContainer() throws -> Swift.SingleValueDecodingContainer {
      let container = Solana._Borsh.SingleValueDecodingContainer(decoder: self)
      return container
    }
  }
}
