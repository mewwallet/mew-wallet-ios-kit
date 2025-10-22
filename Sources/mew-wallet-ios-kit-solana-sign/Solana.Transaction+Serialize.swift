//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/9/25.
//

import Foundation
import mew_wallet_ios_kit
import mew_wallet_ios_kit_solana
import mew_wallet_ios_tweetnacl

extension Solana.Transaction {
  /// A container error that aggregates multiple signature issues discovered during validation.
  /// Thrown from `serialize(requireAllSignatures:verifySignatures:)` when any signature is
  /// missing (if required) or fails cryptographic verification.
  public struct ValidationErrors: Swift.Error, Equatable {
    /// The list of per-signer validation errors found.
    public let errors: [ValidationError]
  }
  
  /// Enumerates per-signer validation failures.
  public enum ValidationError: Swift.Error, Equatable {
    /// The provided signature bytes do not validate against `publicKey` and the signed message.
    case invalidSignature(PublicKey)
    /// The signature is missing (nil), but `requireAllSignatures == true`.
    case missingSignature(PublicKey)
  }
  
  // MARK: - Message serialization
  
  /// Returns the canonical message bytes that must be covered by Ed25519 signatures.
  ///
  /// This compiles the transaction into a `Message` (inserting a durable nonce
  /// instruction if `nonceInfo` is set, resolving fee payer position, etc.) and
  /// encodes it using the ShortVec-aware encoder to match Solana wire format.
  ///
  /// - Returns: The serialized message `Data` to sign/verify.
  /// - Throws: Any error raised by `_compile()` (message assembly) or the encoder.
  mutating func serializeMessage() throws -> Data {
    let message = try self._compile()
    let encoder = Solana.ShortVecEncoder()
    return try encoder.encode(message)
  }
  
  // MARK: - Full transaction serialization
  
  /// Serializes the transaction into Solana wire format (`wireTransaction`)
  ///
  /// - Parameters:
  ///   - requireAllSignatures: When `true` (default), all required signatures must be present
  ///     (non-`nil`). When `false`, missing signatures are allowed.
  ///   - verifySignatures: When `true` (default), each present signature is verified against
  ///     the compiled message using Ed25519.
  ///
  /// - Returns: A `Data` buffer of the entire transaction in the wire format.
  /// - Throws:
  ///   - `ValidationErrors` when any signature is missing (and required) or invalid,
  ///     if `verifySignatures == true`.
  ///   - Any error thrown by `serializeMessage()` or the encoder.
  ///
  /// - Note: Size constraints (e.g., Solana’s `PACKET_DATA_SIZE`) are not enforced here;
  ///   you may want to enforce them in a higher-level packing layer if needed.
  mutating public func serialize(requireAllSignatures: Bool = true, verifySignatures: Bool = true) throws -> Data {
    let signData = try self.serializeMessage()
    if verifySignatures {
      let errors = self._getValidationErrors(message: signData, requireAllSignatures: requireAllSignatures, verifySignatures: verifySignatures)
      guard errors.isEmpty else {
        throw ValidationErrors(errors: errors)
      }
    }
    let encoder = Solana.ShortVecEncoder()
    return try encoder.encode(self)
  }
  
  // MARK: - Signature verification
  
  /// Verifies the transaction’s signatures against the compiled message.
  ///
  /// - Parameter requireAllSignatures: When `true` (default), all required signatures must
  ///   be present; when `false`, missing signatures are ignored.
  /// - Returns: `true` if validation passes according to the chosen policy; otherwise `false`.
  /// - Throws: Any error thrown by `serializeMessage()` while building the message to verify.
  mutating public func verifySignatures(requireAllSignatures: Bool = true) throws -> Bool {
    let message = try self.serializeMessage()
    return self._getValidationErrors(message: message, requireAllSignatures: requireAllSignatures, verifySignatures: true).isEmpty
  }
  
  // MARK: - Internal helpers
  
  /// Collects per-signer validation errors for the provided message bytes.
  ///
  /// - Parameters:
  ///   - message: The compiled message to be verified.
  ///   - requireAllSignatures: Whether missing signatures constitute an error.
  ///   - verifySignatures: Whether to run cryptographic verification for present signatures.
  /// - Returns: An array of `ValidationError` (empty when validation passes).
  private func _getValidationErrors(message: Data, requireAllSignatures: Bool, verifySignatures: Bool) -> [Solana.Transaction.ValidationError] {
    var errors: [ValidationError] = []
    for signature in self.signatures {
      if let sig = signature.signature {
        if verifySignatures && !TweetNacl.verify(message: message, signature: sig, publicKey: signature.publicKey.data()) {
          errors.append(.invalidSignature(signature.publicKey))
        }
      } else if requireAllSignatures {
        errors.append(.missingSignature(signature.publicKey))
      }
    }
    return errors
  }
}
