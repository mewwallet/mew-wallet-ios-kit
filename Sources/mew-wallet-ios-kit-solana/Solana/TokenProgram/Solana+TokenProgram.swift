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
  /// Factory for building transaction instructions targeting the **SPL Token** program
  /// (`Tokenkeg...`). This module currently implements the minimal `Transfer`
  /// instruction needed for fungible token movement.
  public struct TokenProgram {
    /// SPL Token instruction discriminators for the legacy Token program.
    /// Matches the on-chain program's enum indices.
    public enum Index: UInt8, EndianBytesEncodable, EndianBytesDecodable, Sendable {
      case transfer                 = 3
    }
    
    /// Public key that identifies the **legacy SPL Token program**.
    /// > Note: This is **not** Token-2022. If you plan to support Token-2022 features
    /// (transfer hooks, metadata pointers, etc.), you'll need a different `programId`
    /// and different account sizing rules.
    public static let programId: PublicKey = try! .init(base58: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA", network: .solana)
    
    /// Canonical buffer layout for **legacy** token accounts (no extensions).
    ///
    /// Byte sizes (165 bytes total):
    /// ```
    /// struct Account {
    /// mint:                 Pubkey   // 32
    /// owner:                Pubkey   // 32
    /// amount:               u64      //  8
    /// delegateOption:       u32      //  4
    /// delegate:             Pubkey   // 32
    /// state:                u8       //  1
    /// isNativeOption:       u32      //  4
    /// isNative:             u64      //  8
    /// delegatedAmount:      u64      //  8
    /// closeAuthorityOption: u32      //  4
    /// closeAuthority:       Pubkey   // 32
    /// } // = 165 bytes
    /// ```
    ///
    /// - For **Token-2022**, the account may include **extensions** and be larger than 165 bytes.
    ///   This constant is only correct for legacy, extension-less accounts.
    public static let accountSize: Int = 165
    
    /// Build a **Transfer** instruction for the legacy SPL Token program.
    ///
    /// Keys (order and flags must match on-chain expectations):
    /// 0. `[writable]` source token account (`source`)
    /// 1. `[writable]` destination token account (`destination`)
    /// 2. `[signer?]`  owner OR multisig address (`owner`)
    /// 3+. `[signer]`  each multisig signer (if `owner` is a multisig)
    ///
    /// Data layout (little-endian where applicable):
    /// - `u8`  index  = `Index.transfer` (3)
    /// - `u64` amount = raw token units (not adjusted for decimals)
    ///
    /// Semantics:
    /// - **Single owner:** `multiSigners` is empty; `owner` must sign the transaction.
    /// - **Multisig owner:** `owner` is the multisig **account address** (PDA-like, not an EO key),
    ///   and `multiSigners` must include the required M-of-N signer keys. In this case
    ///   `owner` is **not** a signer key; the provided signer keys authorize on its behalf.
    ///
    /// - Parameters:
    ///   - `params.source`: Source token account (must match the mint of `destination`).
    ///   - `params.destination`: Destination token account.
    ///   - `params.owner`: Owner of `source` (single owner **or** multisig address).
    ///   - `params.amount`: Transfer amount in the smallest unit.
    ///   - `params.multiSigners`: Optional signer list when `owner` is a multisig.
    ///   - `params.programId`: SPL Token program id (defaults to `TokenProgram.programId`).
    public static func transfer(params: Solana.TokenProgram.TransferParams) -> TransactionInstruction {
      var keys: [Solana.AccountMeta] = []
      keys.reserveCapacity(3 + params.multiSigners.count)
      keys.append(.init(pubkey: params.source, isSigner: false, isWritable: true))
      keys.append(.init(pubkey: params.destination, isSigner: false, isWritable: true))
      keys.append(.init(pubkey: params.owner, isSigner: params.multiSigners.isEmpty, isWritable: false))
      keys.append(contentsOf: params.multiSigners.map({
        .init(pubkey: $0, isSigner: true, isWritable: false)
      }))
      
      return TransactionInstruction(
        keys: keys,
        programId: params.programId,
        data: Index.transfer, params.amount
      )
    }
  }
}
