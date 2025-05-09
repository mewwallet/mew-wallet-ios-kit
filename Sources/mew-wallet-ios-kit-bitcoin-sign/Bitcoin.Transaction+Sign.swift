//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/19/25.
//

import Foundation
import mew_wallet_ios_kit_bitcoin
import mew_wallet_ios_kit

extension Bitcoin.Transaction {
  /// Signs a specific input of the transaction using the provided private key and UTXO metadata.
  ///
  /// This method generates a valid unlocking script (`scriptSig` or `witness`) for the input at the given index,
  /// by producing a deterministic signature according to BIP143 (for SegWit) or legacy rules (for non-SegWit).
  ///
  /// ### Supported Types:
  /// - **P2PKH** (legacy, base signature hash)
  /// - **P2WPKH** (SegWit v0 witness signature hash)
  ///
  /// ### Unsupported:
  /// - Multisig scripts
  /// - Taproot scripts (P2TR)
  /// - Script types not recognized or explicitly disabled
  ///
  /// ### Usage:
  /// You must provide the original `utxo` being spent (scriptPubKey + value) for the input,
  /// as well as the appropriate optional scripts if the UTXO uses P2SH or P2WSH.
  ///
  /// - Parameters:
  ///   - index: The index of the input within the transaction to be signed.
  ///   - utxo: The previous output (UTXO) being spent — must contain a `script` and `value`.
  ///   - key: The private key used for signing the transaction input.
  ///   - redeemScript: The redeem script (if applicable) for P2SH inputs. Optional.
  ///   - witnessScript: The witness script (if applicable) for P2WSH inputs. Optional.
  ///   - sigHash: The signature hash type (e.g. `.all`, `.single`, `.none`, `.anyoneCanPay`). Defaults to `.all`.
  ///
  /// - Returns: A new `Bitcoin.Transaction` instance with the specified input signed.
  ///
  /// - Throws:
  ///   - `Bitcoin.SignError.outputsNotMatch`: If the index is out of bounds of the transaction's inputs.
  ///   - `Bitcoin.SignError.notSupported`: If the script type is unsupported (e.g., multisig or taproot).
  ///   - `Bitcoin.SignError.badDerSignature`: If the public key does not match the expected output script.
  ///   - `Bitcoin.SignError.signingError`: If any unexpected error occurs during signing or serialization.
  public func sign(
    input index: Int,
    utxo: Bitcoin.Transaction.Output,
    key: PrivateKey,
    redeemScript: Bitcoin.Script? = nil,
    witnessScript: Bitcoin.Script? = nil,
    sigHash: Bitcoin.SigHash = .all
  ) throws -> Bitcoin.Transaction {
    
    // Ensure the input index is valid
    guard index < self.inputs.count else {
      throw Bitcoin.SignError.outputsNotMatch
    }
    
    let input = self.inputs[index]
    let publicKey = try key.publicKey()
    
    // Detect script type and signing configuration
    let config = try Bitcoin.Hasher.configuration(
      for: utxo.script,
      witnessScript: witnessScript,
      redeemScript: redeemScript
    )
    
    // Multisig not supported in this implementation
    guard !config.multisig else {
      throw Bitcoin.SignError.notSupported
    }
    
    // Select appropriate hasher based on script type
    let hasher = try Bitcoin.Hasher.hasher(for: config)
    hasher.combine(key: .transaction(self)) // Full transaction
    hasher.combine(key: .inputIndex(index)) // Index of input being signed
    hasher.combine(key: .sigHash(sigHash))  // Sighash flags
    
    // Provide required data for each signing variant
    switch config.sigVersion {
    case .base:
      // Check that scriptPubKey matches expected pubkeyhash form
      guard utxo.script == .bip143ScriptCode(key: publicKey) else {
        throw Bitcoin.SignError.badDerSignature
      }
      
      hasher.combine(key: .scriptCode(.bip143ScriptCode(key: publicKey)))
      
    case .witness_v0:
      // SegWit v0: same pubkeyhash check, but script code is serialized separately
      guard utxo.script == .witness_v0_keyhash(key: publicKey) else {
        throw Bitcoin.SignError.badDerSignature
      }
      
      hasher.combine(key: .scriptCode(.bip143ScriptCode(key: publicKey)))
      hasher.combine(key: .amount(utxo.value)) // Required for BIP143
      
    default:
      throw Bitcoin.SignError.notSupported
    }
    
    // Finalize preimage hash and sign with private key
    let hash = try hasher.finalize()
    let signature = try hash.signDER(key: key, sigHash: sigHash)
    
    // Assemble unlocking script (scriptSig or witness)
    let scriptSig: Bitcoin.Script
    var witness: [Data]? = nil
    
    switch config.sigVersion {
    case .base:
      // Legacy input: use scriptSig with signature + public key
      scriptSig = Bitcoin.Script(asm: [
        .OP_PUSHBYTES(signature),
        .OP_PUSHBYTES(publicKey.data())
      ])
      
    case .witness_v0:
      // SegWit input: scriptSig is empty, data goes into witness field
      scriptSig = .empty
      witness = [
        signature,
        publicKey.data()
      ]
      
    default:
      throw Bitcoin.SignError.notSupported
    }
    
    // Replace the signed input in the transaction
    var newInputs = self.inputs
    newInputs[index] = Bitcoin.Transaction.Input(
      outpoint: input.outpoint,
      sequence: input.sequence,
      scriptSig: scriptSig,
      txinwitness: witness
    )
    
    // Return a new transaction with the signed input
    return Bitcoin.Transaction(
      version: self.version,
      inputs: newInputs,
      outputs: self.outputs,
      locktime: self.locktime
    )
  }
}
