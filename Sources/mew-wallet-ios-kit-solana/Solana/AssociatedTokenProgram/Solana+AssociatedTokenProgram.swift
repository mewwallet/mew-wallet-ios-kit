//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 10/10/25.
//

import Foundation
import mew_wallet_ios_kit
import mew_wallet_ios_kit_utils

extension Solana {
  /// Factory for constructing transaction instructions that interact with the
    /// **SPL Associated Token Account** program.
    ///
    /// This program creates deterministic token accounts (ATAs) derived from the
    /// wallet owner and token mint addresses, ensuring each owner–mint pair
    /// maps to exactly one account.
    ///
    /// Program spec: [https://spl.solana.com/associated-token-account](https://spl.solana.com/associated-token-account)
  public struct AssociatedTokenProgram {
    // MARK: - Program ID

    /// Public key that identifies the SPL **Associated Token Program**.
    ///
    /// Mainnet address: `ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL`
    public static let programId: PublicKey = try! .init(base58: "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL", network: .solana)
    
    // MARK: - Instruction builder
    
    /// Builds a transaction instruction to **create an associated token account** (ATA).
    ///
    /// The derived account address is calculated using:
    /// ```
    /// seeds = [
    ///   owner,
    ///   tokenProgramId,
    ///   mint
    /// ]
    /// pda = findProgramAddress(seeds, associatedTokenProgramId)
    /// ```
    ///
    /// ### Accounts
    /// | # | Account               | Writable | Signer | Description                   |
    /// |---|-----------------------|----------|--------|-------------------------------|
    /// | 0 | payer                 |    ✅    |   ✅   | Pays for account creation     |
    /// | 1 | associated token addr |    ✅    |   ❌   | ATA derived PDA               |
    /// | 2 | owner                 |    ❌    |   ❌   | Wallet or program authority   |
    /// | 3 | mint                  |    ❌    |   ❌   | SPL token mint                |
    /// | 4 | system program        |    ❌    |   ❌   | Required for account creation |
    /// | 5 | token program         |    ❌    |   ❌   | SPL Token Program             |
    ///
    /// - Parameter params: The ATA creation parameters.
    /// - Returns: A ready-to-send `TransactionInstruction`.
    ///
    /// - Note:
    ///   - This instruction **does not** require additional data; the `data` array is empty.
    ///   - The **sysvar rent** account has been deprecated since Solana v1.14 and is optional.
    public static func createAssociatedTokenAccount(params: Solana.AssociatedTokenProgram.CreateAssociatedTokenAccountParams) throws -> TransactionInstruction {
      return try TransactionInstruction(
        keys: [
          .init(pubkey: params.payer, isSigner: true, isWritable: true),
          .init(pubkey: params.owner.associatedTokenAddress(
            tokenMint: params.mint,
            tokenProgramId: params.programId
          ), isSigner: false, isWritable: true),
          .init(pubkey: params.owner, isSigner: false, isWritable: false),
          .init(pubkey: params.mint, isSigner: false, isWritable: false),
          .init(pubkey: SystemProgram.programId, isSigner: false, isWritable: false),
          .init(pubkey: params.programId, isSigner: false, isWritable: false)
        ],
        programId: Self.programId,
        data: []
      )
    }
  }
}
