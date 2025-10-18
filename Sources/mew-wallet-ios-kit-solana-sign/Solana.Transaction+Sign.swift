//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit_solana
import mew_wallet_ios_kit
import mew_wallet_ios_tweetnacl

extension Solana.Transaction {
  /// Errors thrown during signing or when attaching signatures.
  public enum SignError: Swift.Error, Equatable {
    /// No signers were provided.
    case noSigners
    /// Signature length is not 64 bytes (Ed25519 detached signature length).
    case badSignatureLength
    /// A signature was provided for a public key that is not expected to sign this transaction.
    case unknownSigner(PublicKey)
  }
  
  /// Signs the transaction with the provided private keys, replacing any existing signatures.
  ///
  /// This method:
  /// 1. Deduplicates signers by their public key.
  /// 2. Seeds the transaction’s `signatures` array with those public keys.
  /// 3. Compiles the transaction to a canonical `Message`.
  /// 4. Produces Ed25519 signatures over the compiled message and attaches them.
  ///
  /// - Parameter signers: The private keys that will sign the transaction.
  /// - Throws:
  ///   - `SignError.noSigners` if `signers` is empty.
  ///   - Any error thrown by `_compile()` (e.g. missing fee payer/recent blockhash).
  ///   - Any error thrown by `TweetNacl.sign` or key conversion (`ed25519()` / `publicKey()`).
  public mutating func sign(signers: [PrivateKey]) throws {
    guard !signers.isEmpty else {
      throw SignError.noSigners
    }
    
    var uniqueSigners: [PrivateKey] = []
    uniqueSigners.reserveCapacity(signers.count)
    
    for signer in signers {
      if try !uniqueSigners.contains(where: { try $0.publicKey() == signer.publicKey() }) {
        uniqueSigners.append(signer)
      }
    }
    
    self.signatures = try uniqueSigners.map({
      try Solana.SignaturePubkeyPair(signature: nil, publicKey: $0.publicKey())
    })
    
    let message = try self._compile()
    try self._partialSign(message: message, signers: uniqueSigners)
  }
  
  /// Variadic convenience overload for `sign(signers:)`.
  ///
  /// - Parameter signers: One or more private keys to sign the transaction.
  /// - Throws: See `sign(signers:)`.
  public mutating func sign(signers: PrivateKey...) throws {
    try self.sign(signers: signers)
  }
  
  /// Partially signs the transaction with the specified private keys.
  ///
  /// Existing signatures are preserved; only the provided signers will be (re)applied.
  /// Each signer’s public key must correspond to either:
  /// - the fee payer, or
  /// - a signer account in the transaction instructions.
  ///
  /// - Parameter signers: The private keys that will partially sign the transaction.
  /// - Throws:
  ///   - `SignError.noSigners` if `signers` is empty.
  ///   - Any error thrown by `_compile()` or the signing primitives.
  public mutating func partialSign(signers: [PrivateKey]) throws {
    guard !signers.isEmpty else {
      throw SignError.noSigners
    }
    
    var uniqueSigners: [PrivateKey] = []
    uniqueSigners.reserveCapacity(signers.count)
    
    for signer in signers {
      if try !uniqueSigners.contains(where: { try $0.publicKey() == signer.publicKey() }) {
        uniqueSigners.append(signer)
      }
    }
    
    let message = try self._compile()
    try self._partialSign(message: message, signers: uniqueSigners)
  }
  
  /// Variadic convenience overload for `partialSign(signers:)`.
  ///
  /// - Parameter signers: One or more private keys to partially sign the transaction.
  /// - Throws: See `partialSign(signers:)`.
  public mutating func partialSign(signers: PrivateKey...) throws {
    try self.partialSign(signers: signers)
  }
  
  /// Adds an externally-produced Ed25519 signature to the transaction.
  ///
  /// The `pubkey` must appear among the transaction’s required signers
  /// (fee payer or any signer account referenced by the instructions).
  /// The transaction is compiled (if needed) to ensure the `signatures`
  /// array is populated and aligned with the message header.
  ///
  /// - Parameters:
  ///   - pubkey: The public key corresponding to the provided signature.
  ///   - signature: A 64-byte detached Ed25519 signature over the compiled message.
  /// - Throws:
  ///   - `SignError.badSignatureLength` if `signature.count != 64`.
  ///   - `SignError.unknownSigner` if `pubkey` is not one of the required signers.
  ///   - Any error thrown by `_compile()`.
  mutating func addSignature(pubkey: PublicKey, signature: Data) throws {
    _ = try self._compile() // Ensure signatures array is populated
    try self._addSignature(signature: signature, for: pubkey)
  }
  
  /// Signs the compiled message with each provided private key and attaches the signatures.
  ///
  /// - Parameters:
  ///   - message: The compiled transaction message to sign.
  ///   - signers: Private keys used to produce signatures.
  /// - Throws: Any error thrown by the encoder, `TweetNacl.sign`, or `_addSignature`.
  private mutating func _partialSign(message: Solana.Message, signers: [PrivateKey]) throws {
    let encoder = Solana.ShortVecEncoder()
    let data = try encoder.encode(message)
    
    try signers.forEach { key in
      let signature = try TweetNacl.sign(message: data, secretKey: key.ed25519())
      try self._addSignature(signature: signature, for: key.publicKey())
    }
  }
  
  /// Compiles the transaction to a canonical `Message` and ensures the `signatures`
  /// array matches the header’s required signers (by order and count).
  ///
  /// If `signatures` already matches the first `numRequiredSignatures` account keys
  /// (all public keys aligned), it is reused unchanged; otherwise, it is rebuilt
  /// with `nil` signatures for each required signer public key.
  ///
  /// - Returns: The compiled `Message`.
  /// - Throws: Any error thrown during `compileMessage()`.
  package mutating func _compile() throws -> Solana.Message {
    let message = try self.compileMessage()
    let signedKeys = message.accountKeys.prefix(Int(message.header.numRequiredSignatures))
    
    if self.signatures.count == signedKeys.count,
       self.signatures.enumerated().allSatisfy({ signedKeys[$0.offset] == $0.element.publicKey }) {
      return message
    }
    
    self.signatures = signedKeys.map({
      .init(signature: nil, publicKey: $0)
    })
    
    return message
  }
  
  /// Attaches a detached Ed25519 signature to the entry corresponding to `key`.
  ///
  /// - Parameters:
  ///   - signature: A 64-byte signature.
  ///   - key: The signer’s public key that must already be present in `signatures`.
  /// - Throws:
  ///   - `SignError.badSignatureLength` if the signature is not 64 bytes.
  ///   - `SignError.unknownSigner` if `key` is not in `signatures`.
  private mutating func _addSignature(signature: Data, for key: PublicKey) throws {
    guard signature.count == 64 else { throw SignError.badSignatureLength }
    guard let index = self.signatures.firstIndex(where: { $0.publicKey == key }) else {
      throw SignError.unknownSigner(key)
    }
    self.signatures[index].signature = signature
  }
}
