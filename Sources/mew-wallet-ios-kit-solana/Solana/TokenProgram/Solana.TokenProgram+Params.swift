//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 10/10/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana.TokenProgram {
  /// Parameters for a `Transfer` instruction of the SPL Token program.
  ///
  /// Used to move fungible tokens between two associated token accounts.
  /// Can be signed by a single owner or by multiple signers when the
  /// source account is governed by a multisig.
  public struct TransferParams: Sendable, Equatable, Hashable {
    /// Source token account to debit.
    /// Must be owned by `owner` or a multisig that includes `owner`.
    public let source: PublicKey
    
    /// Destination token account to credit.
    /// Must hold the same mint as `source`.
    public let destination: PublicKey
    
    /// Public key of the account owner (or the multisig address).
    /// Must sign the transaction or be represented by `multiSigners`.
    public let owner: PublicKey
    
    /// Number of tokens to transfer, measured in the smallest unit
    /// (raw integer amount, not decimals).
    public let amount: UInt64
    
    /// Optional list of signer public keys when the `owner` is a multisig account.
    /// For single-owner transfers, this can be left empty.
    public let multiSigners: [PublicKey]
    
    /// SPL Token program identifier to use for the instruction.
    /// Defaults to `TokenProgram.programId`.
    public let programId: PublicKey
    
    /// Creates new SPL Token `Transfer` instruction parameters.
    ///
    /// - Parameters:
    ///   - source: Source token account to debit.
    ///   - destination: Destination token account to credit.
    ///   - owner: Account that owns the source token account.
    ///   - amount: Amount to transfer, in raw token units.
    ///   - multiSigners: Optional signer list for multisig.
    ///   - programId: Token program ID (default: standard SPL Token program).
    public init(source: PublicKey, destination: PublicKey, owner: PublicKey, amount: UInt64, multiSigners: [PublicKey] = [], programId: PublicKey = Solana.TokenProgram.programId) {
      self.source = source
      self.destination = destination
      self.owner = owner
      self.amount = amount
      self.multiSigners = multiSigners
      self.programId = programId
    }
  }
}
