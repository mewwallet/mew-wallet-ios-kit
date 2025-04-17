//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/16/25.
//

import Foundation
import mew_wallet_ios_kit_bitcoin
import mew_wallet_ios_kit

extension PSBT.Transaction {
  /// Signs all applicable inputs in the PSBT (Partially Signed Bitcoin Transaction) using the provided private key.
  ///
  /// This method processes each input in the PSBT and attempts to sign it using the standard BIP143 or legacy signing rules,
  /// depending on the type of UTXO and script.
  ///
  /// Only non-multisig inputs using either Base (legacy P2PKH/P2SH) or WitnessV0 (P2WPKH/P2SH-P2WPKH) signature versions are supported.
  /// Multisignature, Taproot, and complex script inputs are not supported at this time.
  ///
  /// If an input is already finalized (i.e., contains a `finalScriptSig`), it will be skipped without error.
  ///
  /// ### Supported input formats:
  /// - `non_witness_utxo`: Full previous transaction. Used for legacy P2PKH or nested P2SH.
  /// - `witness_utxo`: Compact form containing just the UTXO output. Used for native SegWit (P2WPKH).
  /// - `redeem_script` / `witness_script`: Optional scripts for P2SH or P2WSH inputs, respectively.
  ///
  /// ### Unsupported scenarios:
  /// - Inputs without `non_witness_utxo`, `witness_utxo`, or `final_scriptSig`
  /// - Multisig or complex script inputs
  /// - Taproot (Witness v1) inputs
  ///
  /// - Parameter key: The private key to use for signing all valid inputs.
  /// - Returns: A fully signed `Bitcoin.Transaction`, serialized as raw `Data`.
  /// - Throws:
  ///   - `Bitcoin.SignError.outputsNotMatch` if input/output indices are invalid or mismatched.
  ///   - `Bitcoin.SignError.notSupported` for unsupported script types.
  ///   - `Bitcoin.SignError.signingError` if signature generation fails.
  ///   - `Bitcoin.SignError` if a specific signing error occurs.
  public func sign(key: PrivateKey) throws(Bitcoin.SignError) -> Data {
    guard self.inputs.count == self.tx.inputs.count else {
      throw Bitcoin.SignError.outputsNotMatch
    }
    
    do {
      var transaction = self.tx
      
      for (index, input) in self.inputs.enumerated() {
        let utxo: Bitcoin.Transaction.Output
        switch input.utxo {
        case .nonWitnessUTXO(let tx):
          // Validate index is within bounds
          guard Int(transaction.inputs[index].outpoint.vout) < tx.outputs.count else {
            throw Bitcoin.SignError.outputsNotMatch
          }
          // Use referenced output from the full previous transaction
          utxo = tx.outputs[Int(transaction.inputs[index].outpoint.vout)]
        case .witnessUTXO(let output):
          // Use the minimal witness output directly
          utxo = output
        case .finalScriptSig:
          // Input is already finalized, skip signing
          continue
        default:
          // Missing required UTXO information
          throw Bitcoin.SignError.notSupported
        }
        
        // Sign the input using the single-input sign function
        transaction = try transaction.sign(
          input: index,
          utxo: utxo,
          key: key,
          redeemScript: input.redeemScript,
          witnessScript: input.witnessScript,
          sigHash: input.sigHash ?? .all
        )
      }
      // Serialize the fully signed transaction
      return try Bitcoin.Encoder().encode(transaction)
    } catch let error as Bitcoin.SignError {
      throw error
    } catch {
      throw Bitcoin.SignError.signingError
    }
  }
}
