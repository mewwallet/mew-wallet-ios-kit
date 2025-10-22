//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  /// Durable Nonce information used to build an **offline** Solana `Transaction`.
  ///
  /// When a transaction uses a durable nonce instead of a recent blockhash, the
  /// message must:
  /// - use `nonce` (the current blockhash stored in the nonce account) in place of
  ///   the normal recent blockhash, and
  /// - include an `AdvanceNonceAccount` instruction that advances the nonce account
  ///   (JS SDK expects this to be the **first** instruction in the transaction).
  ///
  /// This struct bundles those two pieces together.
  public struct NonceInformation: Equatable, Sendable {
    public enum Error: Swift.Error {
      /// Provided `PublicKey` could not be represented as a Base58 address string.
      case badPublicKey
    }
    
    /// The Base58-encoded blockhash currently stored in the nonce account.
    ///
    /// This value must be copied into the transaction’s `recentBlockhash` field when
    /// compiling a nonce-based transaction.
    public let nonce: String
    
    /// The `AdvanceNonceAccount` instruction that must be included
    /// (typically as the **first** instruction) to advance the nonce.
    ///
    /// In the classic JS flow, `compileMessage()` ensures that if `nonceInfo` is
    /// provided, the `nonceInstruction` is prepended when it’s not already the first
    /// instruction.
    public let nonceInstruction: TransactionInstruction
    
    /// Creates a durable-nonce descriptor from raw components.
    ///
    /// - Parameters:
    ///   - nonce: Base58-encoded blockhash loaded from the nonce account.
    ///   - nonceInstruction: The `AdvanceNonceAccount` instruction for the same nonce account.
    public init(nonce: String, nonceInstruction: TransactionInstruction) {
      self.nonce = nonce
      self.nonceInstruction = nonceInstruction
    }
    
    /// Convenience initializer that derives `nonce` from a `PublicKey`.
    ///
    /// - Parameters:
    ///   - nonce: Public key of the nonce account; must be convertible to a Base58 address.
    ///   - nonceInstruction: The `AdvanceNonceAccount` instruction for the same nonce account.
    /// - Throws:
    ///   - `Error.badPublicKey` if the public key cannot be rendered as Base58.
    public init(nonce: PublicKey, nonceInstruction: TransactionInstruction) throws {
      guard let nonce = nonce.address()?.address else {
        throw Error.badPublicKey
      }
      self.init(nonce: nonce, nonceInstruction: nonceInstruction)
    }
  }
}
