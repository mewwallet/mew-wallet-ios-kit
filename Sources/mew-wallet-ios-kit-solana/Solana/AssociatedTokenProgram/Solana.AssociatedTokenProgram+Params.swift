//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 10/10/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana.AssociatedTokenProgram {
  /// Parameters required to create an **Associated Token Account (ATA)**.
  ///
  /// This structure represents the inputs needed to build a
  /// `createAssociatedTokenAccount` instruction for the SPL Associated Token
  /// Account Program.
  ///
  /// ### Layout
  /// The resulting instruction will derive the ATA using:
  /// ```
  /// seeds = [
  ///   owner,           // wallet or program authority
  ///   tokenProgramId,  // SPL Token program id
  ///   mint             // SPL token mint
  /// ]
  /// address = findProgramAddress(seeds, associatedTokenProgramId)
  /// ```
  ///
  /// ### Parameters
  /// - `payer`: Account funding the creation of the ATA (must be a signer).
  /// - `owner`: Wallet or program that will own the new token account.
  /// - `mint`: The SPL token mint the ATA corresponds to.
  /// - `programId`: The program id for the **Associated Token Program** (usually `Solana.AssociatedTokenProgram.programId`).
  ///
  /// ### Notes
  /// - The payer and owner may be the same account.
  /// - This structure is only a parameter container; the actual instruction
  ///   builder is defined in `AssociatedTokenInstruction.createAssociatedTokenAccount(_:)`.
  ///
  /// Reference: [SPL Token Program — Associated Token Account specification](https://spl.solana.com/associated-token-account)
  public struct CreateAssociatedTokenAccountParams: Sendable, Equatable, Hashable {
    /// The account paying for the account creation (must sign the transaction).
    public let payer: PublicKey
    
    /// The owner of the resulting associated token account.
    public let owner: PublicKey
    
    /// The SPL token mint that this ATA corresponds to.
    public let mint: PublicKey
    
    /// The associated token program id used to derive the ATA.
    public let programId: PublicKey
    
    /// Creates a new parameter container for ATA creation.
    ///
    /// - Parameters:
    ///   - payer: The fee payer creating the account.
    ///   - owner: The owner of the ATA.
    ///   - mint: The SPL token mint.
    ///   - programId: The associated token program id.
    public init(payer: PublicKey, owner: PublicKey, mint: PublicKey, programId: PublicKey) {
      self.payer = payer
      self.owner = owner
      self.mint = mint
      self.programId = programId
    }
  }
}
