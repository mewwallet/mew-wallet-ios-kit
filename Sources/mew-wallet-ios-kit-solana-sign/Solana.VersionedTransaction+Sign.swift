//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 10/8/25.
//

import Foundation
import mew_wallet_ios_kit
import mew_wallet_ios_kit_solana
import mew_wallet_ios_tweetnacl

extension Solana.VersionedTransaction {
  /// Signs the versioned transaction with a single private key.
  ///
  /// This is a convenience overload of `sign(signers:)`.
  /// Internally, it encodes the current `message` using the ShortVec encoder,
  /// produces an Ed25519 detached signature over those bytes, and places the
  /// signature into `signatures` at the signer’s index (0..<numRequiredSignatures).
  ///
  /// - Parameter signer: The private key used to sign.
  /// - Throws:
  ///   - Any error thrown by the encoder while serializing the message.
  ///   - Any error thrown by `TweetNacl.sign`.
  ///   - `Error.signerIsNotRequired` if the provided key is not among the
  ///     first `numRequiredSignatures` static account keys.
  ///   - `Error.invalidSignature` if the produced signature is not 64 bytes
  ///     (should not happen for a valid Ed25519 signature).
  mutating public func sign(signer: PrivateKey) throws {
    try self.sign(signers: [signer])
  }
  
  /// Signs the versioned transaction with multiple private keys.
  ///
  /// For each signer:
  /// 1. The current `message` is encoded using `ShortVecEncoder`.
  /// 2. An Ed25519 detached signature is produced with `TweetNacl.sign`.
  /// 3. The signature is added at the correct index using `addSignature(publicKey:signature:)`.
  ///
  /// Existing signatures in `self.signatures` are preserved for other signers; only
  /// indices corresponding to the provided signers are updated.
  ///
  /// - Parameter signers: Private keys to sign the transaction.
  /// - Throws:
  ///   - Any error thrown by the encoder while serializing the message.
  ///   - Any error thrown by `TweetNacl.sign`.
  ///   - `Error.signerIsNotRequired` if any provided key is not among the
  ///     first `numRequiredSignatures` static account keys.
  ///   - `Error.invalidSignature` if any produced signature is not 64 bytes.
  mutating public func sign(signers: [PrivateKey]) throws {
    let encoder = Solana.ShortVecEncoder()
    let messageData = try encoder.encode(self.message)
    for signer in signers {
      let signature = try TweetNacl.sign(message: messageData, secretKey: signer.ed25519())
      try self.addSignature(publicKey: signer.publicKey(), signature: signature)
    }
  }
  
  /// Inserts an externally-created Ed25519 signature for a specific signer.
  ///
  /// The `publicKey` must be one of the first `numRequiredSignatures` entries
  /// in `message.staticAccountKeys` (the required signers). The method replaces
  /// the signature at that signer’s index.
  ///
  /// - Parameters:
  ///   - publicKey: The public key of the signer whose slot will be updated.
  ///   - signature: A 64-byte Ed25519 detached signature over the encoded message.
  /// - Throws:
  ///   - `Error.invalidSignature` if `signature.count != 64`.
  ///   - `Error.signerIsNotRequired(publicKey)` if `publicKey` is not among the
  ///     required signers for this message.
  mutating public func addSignature(publicKey: PublicKey, signature: Data) throws {
    guard signature.count == 64 else {
      throw Error.invalidSignature
    }
    let signerPubkeys = message.staticAccountKeys[0..<Int(message.header.numRequiredSignatures)]
    guard let signerIndex = signerPubkeys.firstIndex(of: publicKey) else {
      throw Error.signerIsNotRequired(publicKey)
    }
    self.signatures[signerIndex] = signature
  }
}
