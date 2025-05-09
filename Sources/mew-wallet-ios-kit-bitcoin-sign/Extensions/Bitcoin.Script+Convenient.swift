//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/17/25.
//

import Foundation
import mew_wallet_ios_kit
import mew_wallet_ios_kit_bitcoin

extension Bitcoin.Script {
  /// Constructs the `scriptCode` used in BIP143 signature hashing for P2WPKH (Pay-to-Witness-Public-Key-Hash) inputs.
  ///
  /// Although the witness program for P2WPKH is a simple `0 <20-byte-pubKeyHash>`,
  /// the signature hash algorithm (BIP143) requires the `scriptCode` to be the
  /// standard legacy P2PKH locking script:
  ///
  ///     OP_DUP OP_HASH160 <PubKeyHash> OP_EQUALVERIFY OP_CHECKSIG
  ///
  /// This `scriptCode` is serialized and included in the signature preimage when signing witness v0 inputs,
  /// even though it's not directly part of the scriptPubKey or witness data.
  ///
  /// - Important: This method is used specifically for SegWit version 0 inputs (e.g., P2WPKH or P2SH-P2WPKH),
  ///   and is required to produce the correct sighash as per [BIP143](https://github.com/bitcoin/bips/blob/master/bip-0143.mediawiki).
  ///
  /// - Parameter key: The public key whose HASH160 will be used in the script.
  /// - Returns: A `Script` representing the `scriptCode` expected in BIP143 sighash computation.
  public static func bip143ScriptCode(key: PublicKey) -> Self {
    let hash: Data = key.data().hash160()
    
    return Self(asm: [
      .OP_DUP,
      .OP_HASH160,
      .OP_PUSHBYTES(hash),
      .OP_EQUALVERIFY,
      .OP_CHECKSIG
    ])
  }
  
  /// Constructs a standard P2WPKH (Pay-to-Witness-Public-Key-Hash) scriptPubKey.
  ///
  /// Format: `OP_0 <PubKeyHash>`
  ///
  /// - Parameter key: The public key used to derive the hash160.
  /// - Returns: A `Script` representing a witness version 0 keyhash (P2WPKH) output.
  public static func witness_v0_keyhash(key: PublicKey) -> Self {
    let hash: Data = key.data().hash160()
    
    return Self(asm: [
      .OP_0,
      .OP_PUSHBYTES(hash)
    ])
  }
  
  /// Constructs an unlocking script (scriptSig or witness) with a signature and public key.
  ///
  /// Format: `<signature> <pubkey>`
  ///
  /// - Parameters:
  ///   - signature: A DER-encoded ECDSA signature (with sighash byte appended).
  ///   - key: The public key corresponding to the private key that signed the transaction.
  /// - Returns: A `Script` representing the unlocking script.
  public static func signature(_ signature: Data, key: PublicKey) -> Self {
    return Self(asm: [
      .OP_PUSHBYTES(signature),
      .OP_PUSHBYTES(key.data())
    ])
  }
}
