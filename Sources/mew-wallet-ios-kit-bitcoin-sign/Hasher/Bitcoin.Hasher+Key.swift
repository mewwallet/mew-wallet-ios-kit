//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/18/25.
//

import Foundation
import mew_wallet_ios_kit_bitcoin

extension Bitcoin.Hasher {
  /// Represents a piece of contextual information required for constructing a signature preimage.
  /// Used in all sighash implementations to inject transaction details, scripts, and flags.
  enum Key: Sendable, Hashable {
    /// The unsigned transaction being signed.
    case transaction(Bitcoin.Transaction)
    
    /// Index of the input being signed.
    case inputIndex(Int)
    
    /// The script code used for hashing (e.g. the UTXO's scriptPubKey or derived redeem/witness script).
    case scriptCode(Bitcoin.Script)
    
    /// The amount being spent by the input (required for SegWit and Taproot signing).
    case amount(UInt64)
    
    /// The sighash mode used (SIGHASH_ALL, SINGLE, NONE, with optional ANYONECANPAY).
    case sigHash(Bitcoin.SigHash)
    
    /// Used in SIGHASH_SINGLE and SIGHASH_NONE when only selected outputs should be signed.
    case outputs([Bitcoin.Transaction.Output])
    
    /// For Taproot script-path spending: the script being evaluated (leaf script).
    case tapScript(Bitcoin.Script)
    
    /// Taproot leaf version (usually 0xC0 for script-path, per BIP342).
    case leafVersion(UInt8)
    
    /// Taproot control block proving script inclusion in internal key tree.
    case controlBlock(Data)
    
    /// Taproot annex (optional commitment area, see BIP342).
    case annex(Data)
  }
}

extension Bitcoin.Hasher.Key: Identifiable {
  /// Unique key identifiers for all supported key types.
  enum KeyID: UInt8 {
    case transaction
    case inputIndex
    case scriptCode
    case amount
    case sigHash
    case outputs
    case tapScript
    case leafVersion
    case controlBlock
    case annex
  }
  
  /// Maps each `Key` case to its corresponding `KeyID` for identification and lookup.
  var id: KeyID {
    switch self {
    case .transaction:    return .transaction
    case .inputIndex:     return .inputIndex
    case .scriptCode:     return .scriptCode
    case .amount:         return .amount
    case .sigHash:        return .sigHash
    case .outputs:        return .outputs
    case .tapScript:      return .tapScript
    case .leafVersion:    return .leafVersion
    case .controlBlock:   return .controlBlock
    case .annex:          return .annex
    }
  }
}
