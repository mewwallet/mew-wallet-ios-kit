//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/20/25.
//

import Foundation
import mew_wallet_ios_kit_bitcoin

extension Bitcoin.Hasher {
  /// Implements the BIP143 signature hashing algorithm for SegWit v0 inputs (P2WPKH, P2WSH).
  ///
  /// This hasher produces the digest to be signed for witness-based inputs using the structure and rules defined in [BIP-0143](https://github.com/bitcoin/bips/blob/master/bip-0143.mediawiki).
  /// It supports the following sighash types: `SIGHASH_ALL`, `SIGHASH_SINGLE`, `SIGHASH_NONE`, and the `SIGHASH_ANYONECANPAY` flag.
  ///
  /// Usage:
  /// 1. Create a new instance.
  /// 2. Call `combine(key:)` for all required data (transaction, input index, sighash type, etc).
  /// 3. Call `finalize()` to produce the hash for signing.
  final class WitnessV0Hasher: Bitcoin.Hasher.SignHasher {
    /// Internal key store for all components required to compute the sighash.
    /// Default includes `.sigHash(.all)` if not explicitly provided.
    private var keys: [Bitcoin.Hasher.Key.ID: Bitcoin.Hasher.Key] = [
      .sigHash: .sigHash(.all)
    ]
    
    init() { }
    
    /// Inserts or overrides a hashing component (`Bitcoin.Hasher.Key`) into the context.
    /// - Parameter key: The hasher key to combine (e.g., `.transaction`, `.amount`, etc.).
    func combine(key: Bitcoin.Hasher.Key) {
      self.keys[key.id] = key
    }
    
    /// Finalizes the sighash computation and returns the 32-byte digest.
    ///
    /// - Returns: The `hash256`-encoded preimage that should be signed with the private key.
    /// - Throws: `Bitcoin.Hasher.Error` if required keys are missing or encoding fails.
    func finalize() throws(Bitcoin.Hasher.Error) -> Data {
      // Ensure all required keys are present
      guard case .transaction(let tx) = keys[.transaction],
            case .inputIndex(let index) = keys[.inputIndex],
            case .scriptCode(let scriptCode) = keys[.scriptCode],
            case .amount(let amount) = keys[.amount],
            case .sigHash(let sigHash) = keys[.sigHash] else {
        throw .missingKeys(keys: [.transaction, .inputIndex, .scriptCode, .amount, .sigHash])
      }
      
      let encoder = Bitcoin.Encoder()
      
      let input = tx.inputs[index]
      
      // MARK: hashPrevouts
      // If ANYONECANPAY is set, skip hashing all input outpoints (use 0x00 * 32)
      // Otherwise, hash all input outpoints
      let hashPrevouts: Data
      if sigHash.contains(.anyoneCanPay) {
        hashPrevouts = Data(repeating: 0x00, count: 32)
      } else {
        do {
          let data = try encoder.encode(tx.inputs.map { $0.outpoint })
          hashPrevouts = data.hash256()
        } catch {
          throw .encodingFailed
        }
      }
      
      // MARK: hashSequence
      // Needed unless ANYONECANPAY or SINGLE/NONE are set
      let hashSequence: Data
      if sigHash.contains(.anyoneCanPay) || sigHash.isSingle || sigHash.isNone {
        hashSequence = Data(repeating: 0x00, count: 32)
      } else {
        do {
          let data = try encoder.encode(tx.inputs.map { $0.sequence })
          hashSequence = data.hash256()
        } catch {
          throw .encodingFailed
        }
      }
      
      // MARK: hashOutputs
      // Depends on sighash type
      let hashOutputs: Data
      if sigHash.isSingle {
        // If index is within bounds, hash only the matching output
        if index < tx.outputs.count {
          do {
            let data = try encoder.encode(tx.outputs[index])
            hashOutputs = data.hash256()
          } catch {
            throw .encodingFailed
          }
        } else {
          // BIP143 edge case: index >= outputs.count returns hash of 0x00 * 32
          hashOutputs = Data(repeating: 0x00, count: 32)
        }
      } else if sigHash.isNone {
        hashOutputs = Data(repeating: 0x00, count: 32)
      } else {
        // SIGHASH_ALL — hash all outputs
        do {
          let data = try encoder.encode(tx.outputs)
          hashOutputs = data.hash256()
        } catch {
          throw .encodingFailed
        }
      }
      
      // MARK: Build preimage for final digest
      let preimage = Self.Preimage(
        version: tx.version,
        hashPrevouts: hashPrevouts,
        hashSequence: hashSequence,
        outpoint: input.outpoint,
        script: scriptCode,
        value: amount,
        sequence: input.sequence,
        hashOutputs: hashOutputs,
        locktime: tx.locktime,
        sighash: sigHash
      )
      
      do {
        encoder.sizeEncodingFormat = .disabled // No varint sizes for preimage
        let data = try encoder.encode(preimage)
        return data.hash256()
      } catch {
        throw .encodingFailed
      }
    }
  }
}
