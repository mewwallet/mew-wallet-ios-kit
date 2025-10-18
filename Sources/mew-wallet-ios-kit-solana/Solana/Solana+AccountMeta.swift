//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  /// Represents metadata about an account used in a Solana transaction instruction.
  ///
  /// Each Solana instruction references one or more accounts, specifying:
  /// - which accounts are **readable** or **writable**
  /// - which accounts must **sign** the transaction
  ///
  /// The `AccountMeta` structure encapsulates that information for serialization into
  /// a `TransactionInstruction`.
  ///
  /// ### Example
  /// ```swift
  /// let meta = Solana.AccountMeta(
  ///   pubkey: ownerPublicKey,
  ///   isSigner: true,
  ///   isWritable: false
  /// )
  /// ```
  ///
  /// This indicates that the account belongs to the signer but will not be modified.
  public struct AccountMeta: Equatable, Sendable {
    /// The public key identifying the account.
    ///
    /// This key references an on-chain account to be read or written during instruction execution.
    let pubkey: PublicKey
    
    /// Indicates whether this account must provide a **signature** for the transaction.
    ///
    /// - `true`: The transaction must be signed with this account’s private key.
    /// - `false`: The account is only referenced, not required to sign.
    ///
    /// Example:
    /// - The fee payer or token owner typically sets `isSigner = true`.
    /// - PDAs or system accounts (e.g., `SysvarRent`) are `isSigner = false`.
    var isSigner: Bool
    
    /// Indicates whether the account’s data or lamports may be **modified** during execution.
    ///
    /// - `true`: The account is writable and may have its balance or data updated.
    /// - `false`: The account is read-only.
    ///
    /// Example:
    /// - Token source and destination accounts are `isWritable = true`.
    /// - System program or rent sysvars are `isWritable = false`.
    var isWritable: Bool
    
    /// Creates a new `AccountMeta` entry for an instruction.
    ///
    /// - Parameters:
    ///   - pubkey: The public key of the referenced account.
    ///   - isSigner: Whether this account must sign the transaction.
    ///   - isWritable: Whether this account can be modified by the instruction.
    public init(pubkey: PublicKey, isSigner: Bool, isWritable: Bool) {
      self.pubkey = pubkey
      self.isSigner = isSigner
      self.isWritable = isWritable
    }
  }
}
