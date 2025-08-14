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
  struct ValidationErrors: Swift.Error {
    public let errors: [ValidationError]
  }
  
  public enum ValidationError: Swift.Error {
    case invalidSignature(PublicKey)
    case missingSignature(PublicKey)
  }
  /**
   * Get a buffer of the Transaction data that need to be covered by signatures
   */
  mutating func serializeMessage() throws -> Data {
    let message = try self._compile()
    let encoder = Solana.ShortVecEncoder()
    return try encoder.encode(message)
  }
  
  //  /**
  //     * Serialize the Transaction in the wire format.
  //     *
  //     * @param {Buffer} [config] Config of transaction.
  //     *
  //     * @returns {Buffer} Signature of transaction in wire format.
  //     */
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
  
  private func _getValidationErrors(message: Data, requireAllSignatures: Bool, verifySignatures: Bool) -> [Solana.Transaction.ValidationError] {
    var errors: [ValidationError] = []
    for signature in self.signatures {
      if let sig = signature.signature {
//        if verifySignatures && !TweetNacl.verify(message: message, signature: sig, publicKey: signature.publicKey.data()) {
//          errors.append(.invalidSignature(signature.publicKey))
//        }
      } else if requireAllSignatures {
        errors.append(.missingSignature(signature.publicKey))
      }
    }
    return errors
  }
}
