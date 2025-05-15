//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/17/25.
//

import Foundation
import mew_wallet_ios_kit_bitcoin

//https://en.bitcoin.it/wiki/OP_CHECKSIG
extension Bitcoin.Hasher {
  /// Computes a signature hash preimage for legacy Base (non-witness) inputs, as used by OP_CHECKSIG.
  /// This implementation handles all SIGHASH modes, including ANYONECANPAY.
  ///
  /// Required keys:
  /// - `.transaction`: the unsigned transaction
  /// - `.inputIndex`: the input being signed
  /// - `.scriptCode`: the unlocking script for the UTXO being spent
  /// - `.sigHash`: the SIGHASH mode (default: .all)
  final class BaseHasher: Bitcoin.Hasher.SignHasher {
    /// Internal key store for required hashing components.
    /// Defaults to `.sigHash(.all)` if not explicitly set.
    private var keys: [Bitcoin.Hasher.Key.ID: Bitcoin.Hasher.Key] = [
      .sigHash: .sigHash(.all)
    ]
    
    init() { }
    
    /// Sets or overrides a specific key in the hash context.
    /// All required keys must be present before calling `finalize()`.
    func combine(key: Bitcoin.Hasher.Key) {
      self.keys[key.id] = key
    }
    
    /// Finalizes the hasher by producing a sighash digest according to legacy base rules.
    /// The produced preimage is serialized and hashed using double SHA256 (hash256).
    ///
    /// Required keys:
    /// - `.transaction`: The unsigned Bitcoin transaction.
    /// - `.inputIndex`: The index of the input being signed.
    /// - `.scriptCode`: The script to place in the input being signed.
    /// - `.sigHash`: The desired sighash mode (e.g. .all, .single, .none).
    ///
    /// - Throws: `.missingKeys` if any required key is missing.
    /// - Throws: `.encodingFailed` if transaction serialization fails.
    /// - Returns: 32-byte sighash digest as `Data`.
    func finalize() throws(Bitcoin.Hasher.Error) -> Data {
      guard case .transaction(let tx) = self.keys[.transaction],
            case .inputIndex(let index) = self.keys[.inputIndex],
            case .scriptCode(let script) = self.keys[.scriptCode],
            case .sigHash(let sigHash) = self.keys[.sigHash] else {
        var requiredKeys: Set<Bitcoin.Hasher.Key.ID> = [
          .transaction,
          .inputIndex,
          .scriptCode,
          .sigHash
        ]
        self.keys.keys.forEach { requiredKeys.remove($0) }
        throw .missingKeys(keys: requiredKeys)
      }
      
      // BIP-143: If using SIGHASH_SINGLE and index >= outputs.count, return 0x000..01
      if sigHash.isSingle, index >= tx.outputs.count {
        return Data(repeating: 0x00, count: 31) + Data([0x01])
      }
      
      // Handle inputs based on ANYONECANPAY
      let inputs: [Bitcoin.Transaction.Input]
      if sigHash.contains(.anyoneCanPay) {
        inputs = [
          .init(
            outpoint: tx.inputs[index].outpoint,
            sequence: tx.inputs[index].sequence,
            scriptSig: script,
            txinwitness: nil
          )
        ]
      } else {
        let sigHashSequence = !sigHash.isNone && !sigHash.isSingle
        inputs = try tx.inputs.enumerated().map { (i, txin) throws(Bitcoin.Hasher.Error) -> Bitcoin.Transaction.Input in
          return .init(
            outpoint: txin.outpoint,
            sequence: i == index || sigHashSequence ? txin.sequence : .initial,
            scriptSig: i == index ? script : .empty,
            txinwitness: nil
          )
        }
      }
      
      // Handle outputs based on sighash type
      let outputs: [Bitcoin.Transaction.Output]
      if sigHash.isSingle {
        outputs = tx.outputs.enumerated().compactMap({ i, txout in
          guard i <= index else { return nil }
          
          if i == index {
            return txout
          } else {
            return .init(value: .max, n: nil, script: .empty) // .max == 0xffffffffffffffff
          }
        })
      } else if sigHash.isNone {
        outputs = []
      } else {
        outputs = tx.outputs
      }
      
      // Construct the transaction to be hashed
      let preimage = Self.Preimage(
        transaction: Bitcoin.Transaction(
          version: tx.version,
          inputs: inputs,
          outputs: outputs,
          locktime: tx.locktime
        ),
        sighash: sigHash
      )
      
      do {
        let encoder = Bitcoin.Encoder()
        let data = try encoder.encode(preimage)
        return data.hash256()
      } catch {
        throw .encodingFailed
      }
    }
  }
}
