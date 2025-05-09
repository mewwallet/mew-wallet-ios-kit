//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/18/25.
//

import Foundation
import mew_wallet_ios_kit_bitcoin

/// Represents the data structure used to compute the legacy signature hash (sighash) preimage.
/// This structure is serialized and double-SHA256 hashed to produce the final digest for signing.
///
/// Used exclusively by BaseHasher (SigVersion::Base) with legacy inputs.
///
/// The serialized form consists of:
/// - The full transaction (with adjusted scripts and sequences depending on sighash flags)
/// - The sighash type (as a trailing 4-byte value, per legacy rules)
extension Bitcoin.Hasher.BaseHasher {
  struct Preimage: Codable {
    
    /// The modified transaction containing the selected inputs, outputs, and locktime.
    /// Scripts and sequences are adjusted according to sighash semantics.
    let transaction: Bitcoin.Transaction
    
    /// The sighash mode (e.g., SIGHASH_ALL, SINGLE, NONE, ANYONECANPAY).
    /// This is appended to the serialized transaction as a 4-byte little-endian field.
    let sighash: Bitcoin.SigHash
  }
}
