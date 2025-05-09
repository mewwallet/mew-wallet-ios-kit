//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/16/25.
//

import Foundation

extension PSBT {
  /// Represents a single input in a PSBT (Partially Signed Bitcoin Transaction).
  ///
  /// This struct aggregates input-related metadata such as the UTXO being spent,
  /// the scripts used to unlock it, and optional signature hashing details.
  public struct Input: Equatable, Sendable {
    /// Enumeration of UTXO representations in a PSBT input.
    /// These mutually exclusive fields specify how the input is resolved or finalized.
    public enum UTXO: Equatable, Sendable {
      /// Witness-style UTXO (`scriptPubKey`, `value`) used for SegWit inputs.
      case witnessUTXO(Bitcoin.Transaction.Output)
      
      /// Full transaction data used for legacy (non-witness) inputs.
      case nonWitnessUTXO(Bitcoin.Transaction)
      
      /// Finalized `scriptSig`, indicating that the input is fully signed.
      case finalScriptSig(Bitcoin.Script)
    }
    
    /// The unspent output being consumed by this input.
    public let utxo: UTXO?
    
    /// The witness script used for P2WSH or nested witness inputs.
    public let witnessScript: Bitcoin.Script?
    
    /// The redeem script used for P2SH-based inputs.
    public let redeemScript: Bitcoin.Script?
    
    /// The custom SIGHASH type applied to this input, if set.
    public let sigHash: Bitcoin.SigHash?
  }
}

// MARK: - PSBT.Input + Codable

extension PSBT.Input: Codable {
  enum CodingKeys: CodingKey {
    case non_witness_utxo
    case witness_utxo
    case final_scriptSig
    case witness_script
    case redeem_script
    case sig_hash_type
  }
  
  /// Initializes a `PSBT.Input` by decoding available keys.
  ///
  /// It attempts to decode mutually exclusive fields for the UTXO in order:
  /// `non_witness_utxo`, `witness_utxo`, `final_scriptSig`.
  public init(from decoder: any Swift.Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if let nonWitnessUTXO = try container.decodeIfPresent(Bitcoin.Transaction.self, forKey: .non_witness_utxo) {
      self.utxo = .nonWitnessUTXO(nonWitnessUTXO)
    } else if let witnessUTXO = try container.decodeIfPresent(Bitcoin.Transaction.Output.self, forKey: .witness_utxo) {
      self.utxo = .witnessUTXO(witnessUTXO)
    } else if let finalScriptSig = try container.decodeIfPresent(Bitcoin.Script.self, forKey: .final_scriptSig) {
      self.utxo = .finalScriptSig(finalScriptSig)
    } else {
      self.utxo = nil
    }
    self.witnessScript = try container.decodeIfPresent(Bitcoin.Script.self, forKey: .witness_script)
    self.redeemScript = try container.decodeIfPresent(Bitcoin.Script.self, forKey: .redeem_script)
    self.sigHash = try container.decodeIfPresent(Bitcoin.SigHash.self, forKey: .sig_hash_type)
  }
  
  /// Encodes the `PSBT.Input` to a keyed container, writing only present fields.
  public func encode(to encoder: any Swift.Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self.utxo {
      case .witnessUTXO(let witnessUTXO):
      try container.encode(witnessUTXO, forKey: .witness_utxo)
    case .nonWitnessUTXO(let nonWitnessUTXO):
      try container.encode(nonWitnessUTXO, forKey: .non_witness_utxo)
    case .finalScriptSig(let script):
      try container.encode(script, forKey: .final_scriptSig)
    default:
      break
    }
    try container.encodeIfPresent(witnessScript, forKey: .witness_script)
    try container.encodeIfPresent(redeemScript, forKey: .redeem_script)
    try container.encodeIfPresent(sigHash, forKey: .sig_hash_type)
  }
}
