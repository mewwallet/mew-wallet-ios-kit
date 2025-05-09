//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/20/25.
//

import Foundation
import mew_wallet_ios_kit_bitcoin

extension Bitcoin.Hasher.WitnessV0Hasher {
  /// Represents the preimage structure used to generate a signature hash (sighash) for
  /// SegWit v0 inputs, as defined by [BIP-0143](https://github.com/bitcoin/bips/blob/master/bip-0143.mediawiki).
  ///
  /// This structure is serialized and double-SHA256 hashed to produce the digest that is
  /// signed with the corresponding private key.
  struct Preimage {
    /// A wrapper to encode the `scriptCode` using Bitcoin's custom encoder rules.
    struct ScriptBox: Encodable {
      let script: Bitcoin.Script
    }
    
    /// Transaction version.
    let version: Bitcoin.Version
    
    /// Hash of all input outpoints in the transaction (or 0x00 * 32 if `ANYONECANPAY` is set).
    let hashPrevouts: Data
    
    /// Hash of all input sequences in the transaction (or 0x00 * 32 depending on sighash flags).
    let hashSequence: Data
    
    /// The specific outpoint (txid + vout) being signed.
    let outpoint: Bitcoin.Transaction.Input.Outpoint
    
    /// The script code used in signature verification.
    /// For P2WPKH, this is a P2PKH-style script (legacy scriptPubKey).
    let script: ScriptBox
    
    /// The amount (in satoshis) being spent by the input.
    let value: UInt64
    
    /// The sequence number of the input being signed.
    let sequence: Bitcoin.Sequence
    
    /// Hash of transaction outputs depending on sighash type.
    /// May include all outputs, only the matching output, or be blank (0x00 * 32).
    let hashOutputs: Data
    
    /// Locktime value of the transaction.
    let locktime: Bitcoin.Locktime
    
    /// Sighash flags (e.g., `SIGHASH_ALL`, `SIGHASH_SINGLE`, `SIGHASH_ANYONECANPAY`).
    /// Serialized as a 4-byte little-endian value at the end of the preimage.
    let sighash: Bitcoin.SigHash
    
    /// Initializes a new preimage with the specified components.
    init(version: Bitcoin.Version, hashPrevouts: Data, hashSequence: Data, outpoint: Bitcoin.Transaction.Input.Outpoint, script: Bitcoin.Script, value: UInt64, sequence: Bitcoin.Sequence, hashOutputs: Data, locktime: Bitcoin.Locktime, sighash: Bitcoin.SigHash) {
      self.version = version
      self.hashPrevouts = hashPrevouts
      self.hashSequence = hashSequence
      self.outpoint = outpoint
      self.script = .init(script: script)
      self.value = value
      self.sequence = sequence
      self.hashOutputs = hashOutputs
      self.locktime = locktime
      self.sighash = sighash
    }
  }
}

extension Bitcoin.Hasher.WitnessV0Hasher.Preimage: Encodable {
  enum CodingKeys: CodingKey {
    case version
    case hashPrevouts
    case hashSequence
    case outpoint
    case script
    case value
    case sequence
    case hashOutputs
    case locktime
    case sighash
  }
  
  /// Encodes the preimage using the custom Bitcoin encoder.
  ///
  /// `script` is encoded using `Bitcoin.Encoder` as a raw script (with length prefix etc.).
  /// All other fields are encoded with standard encoder semantics.
  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: Bitcoin.Hasher.WitnessV0Hasher.Preimage.CodingKeys.self)
    try container.encode(self.version, forKey: .version)
    try container.encode(self.hashPrevouts, forKey: .hashPrevouts)
    try container.encode(self.hashSequence, forKey: .hashSequence)
    try container.encode(self.outpoint, forKey: .outpoint)
    
    let encoder = Bitcoin.Encoder()
    let data = try encoder.encode(self.script)
    try container.encode(data, forKey: .script)
    
    try container.encode(self.value, forKey: .value)
    try container.encode(self.sequence, forKey: .sequence)
    try container.encode(self.hashOutputs, forKey: .hashOutputs)
    try container.encode(self.locktime, forKey: .locktime)
    try container.encode(self.sighash, forKey: .sighash)
  }
}
