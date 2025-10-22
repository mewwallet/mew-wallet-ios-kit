//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit_utils

extension Solana._ShortVecEncoding {
  /// A low-level binary encoder that conforms to `Swift.Encoder` and targets
  /// Solana's shortvec/varint-oriented wire format (e.g., Transaction, Message,
  /// MessageV0, and instruction payloads).
  ///
  /// This encoder provides:
  /// - `KeyedContainer` — for structured, field-addressable records (rare in Solana wire paths).
  /// - `UnkeyedContainer` — for ordered sequences (arrays, instruction lists, indices).
  /// - `SingleValueContainer` — for scalars and fixed-size byte slices.
  ///
  /// It is *not* a general-purpose encoder; it assumes tight control over the
  /// binary layout (little-endian where applicable) and Solana’s **shortvec**
  /// (base-128 varint) length encoding for collections.
  ///
  /// - Important: Use this in conjunction with Solana-specific containers
  ///   in `Solana._ShortVecEncoding` and `BinaryStorage` to ensure deterministic layout.
  internal final class Encoder: Swift.Encoder {
    /// Current coding path used for diagnostics and nested container resolution.
    let codingPath: [any CodingKey]
    
    /// Arbitrary user information passed through the encoding process.
    let userInfo: [CodingUserInfoKey : Any]
    
    /// Backing storage collecting encoded bytes (appended in-order).
    let storage: BinaryStorage
    
    /// Initializes a new shortvec-aware encoder.
    ///
    /// - Parameters:
    ///   - codingPath: Initial coding path (usually empty).
    ///   - userInfo: Arbitrary user info for downstream customization.
    ///   - storage: The output byte buffer where encoded data is appended.
    init(codingPath: [any CodingKey], userInfo: [CodingUserInfoKey : Any], storage: BinaryStorage) {
      self.codingPath = codingPath
      self.userInfo = userInfo
      self.storage = storage
    }
    
    /// Returns a keyed encoding container for encoding field-addressable records.
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
      let container = Solana._ShortVecEncoding.KeyedContainer<Key>(encoder: self)
      return KeyedEncodingContainer(container)
    }
    
    /// Returns an unkeyed encoding container for encoding ordered sequences.
    func unkeyedContainer() -> any UnkeyedEncodingContainer {
      return Solana._ShortVecEncoding.UnkeyedContainer(encoder: self, key: self.codingPath.last)
    }
    
    /// Returns a single-value encoding container for encoding scalars or fixed-size blobs.
    func singleValueContainer() -> any SingleValueEncodingContainer {
      return Solana._ShortVecEncoding.SingleValueContainer(encoder: self)
    }
  }
}
