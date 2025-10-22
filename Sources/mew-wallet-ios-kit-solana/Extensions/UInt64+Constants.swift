//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/14/25.
//

import Foundation

extension UInt64 {
  /// The fixed byte length of a **Nonce Account** in Solana.
  ///
  /// Solana defines the serialized size of a nonce account as `80` bytes.
  /// This constant is used to verify account data size when decoding or validating
  /// a nonce account retrieved from on-chain storage.
  ///
  /// Structure breakdown (as per Solana runtime):
  /// ```
  /// NonceAccount {
  ///   version: u32,                // 4 bytes
  ///   state:   u32,                // 4 bytes
  ///   authorizedPubkey: [u8; 32],  // 32 bytes
  ///   nonce: [u8; 32],             // 32 bytes
  ///   feeCalculator: u64,          // 8 bytes
  /// }
  /// // Total = 80 bytes
  /// ```
  static let NONCE_ACCOUNT_LENGTH: Self = 80
}

