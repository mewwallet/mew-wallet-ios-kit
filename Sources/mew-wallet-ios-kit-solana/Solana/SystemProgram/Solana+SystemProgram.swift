//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/9/25.
//

import Foundation
import mew_wallet_ios_kit
import mew_wallet_ios_kit_utils

extension Solana {
  /// System Program instruction builders (owner: `11111111111111111111111111111111`).
  public struct SystemProgram {
    
    /// System instruction discriminators (`u32`), matching on-chain System Program API.
    public enum Index: UInt32, EndianBytesEncodable, EndianBytesDecodable, Sendable {
      /// `CreateAccount { lamports: u64, space: u64, owner: Pubkey }`
      case create                   = 0
      /// `Assign { owner: Pubkey }`
      case assign                   = 1
      /// `Transfer { lamports: u64 }`
      case transfer                 = 2
      /// `CreateAccountWithSeed { base: Pubkey, seed: String, lamports: u64, space: u64, owner: Pubkey }`
      case createWithSeed           = 3
      /// `AdvanceNonceAccount`
      case advanceNonceAccount      = 4
      /// `WithdrawNonceAccount { lamports: u64 }`
      case withdrawNonceAccount     = 5
      /// `InitializeNonceAccount { authorized: Pubkey }`
      case initializeNonceAccount   = 6
      /// `AuthorizeNonceAccount { new_authority: Pubkey }`
      case authorizeNonceAccount    = 7
      /// `Allocate { space: u64 }`
      case allocate                 = 8
      /// `AllocateWithSeed { base: Pubkey, seed: String, space: u64, owner: Pubkey }`
      case allocateWithSeed         = 9
      /// `AssignWithSeed { base: Pubkey, seed: String, owner: Pubkey }`
      case assignWithSeed           = 10
      /// `TransferWithSeed { lamports: u64, seed: String, owner: Pubkey }`
      case transferWithSeed         = 11
      /// `UpgradeNonceAccount` (reserved op)
      case upgradeNonceAccount      = 12
    }
    
    /// Public key that identifies the System Program.
    public static let programId: PublicKey = try! .init(base58: "11111111111111111111111111111111", network: .solana)
    
    // MARK: - CreateAccount
    
    /// Build `CreateAccount` instruction.
    ///
    /// Keys (order matters):
    /// 0. `[signer, writable]` payer (`fromPubkey`)
    /// 1. `[signer, writable]` new account (`newAccountPubkey`)
    ///
    /// Data layout:
    /// - `u32` index = `.create`
    /// - `u64` lamports
    /// - `u64` space
    /// - `32B` owner program id
    public static func createAccount(params: Solana.SystemProgram.CreateAccountParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [
          .init(pubkey: params.fromPubkey, isSigner: true, isWritable: true),
          .init(pubkey: params.newAccountPubkey, isSigner: true, isWritable: true),
        ],
        programId: self.programId,
        data: Index.create, params.lamports, params.space, params.programId.data()
      )
    }
    
    // MARK: - Transfer
    
    /// Build `Transfer` instruction.
    ///
    /// Keys:
    /// 0. `[signer, writable]` source (`fromPubkey`)
    /// 1. `[writable]`        destination (`toPubkey`)
    ///
    /// Data:
    /// - `u32` index = `.transfer`
    /// - `u64` lamports
    public static func transfer(params: Solana.SystemProgram.TransferParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [
          .init(pubkey: params.fromPubkey, isSigner: true, isWritable: true),
          .init(pubkey: params.toPubkey, isSigner: false, isWritable: true),
        ],
        programId: self.programId,
        data: Index.transfer, params.lamports
      )
    }
    
    /// Build `TransferWithSeed` instruction (derived funding address).
    ///
    /// Keys:
    /// 0. `[writable]` derived funding account (`fromPubkey`)
    /// 1. `[signer]`   base used in derivation (`basePubkey`)
    /// 2. `[writable]` destination (`toPubkey`)
    ///
    /// Data:
    /// - `u32` index = `.transferWithSeed`
    /// - `u64` lamports
    /// - `rust string` seed (u32 len + bytes)
    /// - `32B` owner program id (used in derivation)
    public static func transfer(params: Solana.SystemProgram.TransferWithSeedParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [
          .init(pubkey: params.fromPubkey, isSigner: false, isWritable: true),
          .init(pubkey: params.basePubkey, isSigner: true, isWritable: false),
          .init(pubkey: params.toPubkey, isSigner: false, isWritable: true),
        ],
        programId: self.programId,
        data: Index.transferWithSeed, params.lamports, params.seed.rustBytes, params.programId.data()
      )
    }
    
    // MARK: - Assign
    
    /// Build `Assign` instruction (change owner).
    ///
    /// Keys:
    /// 0. `[signer, writable]` target account (`accountPubkey`)
    ///
    /// Data:
    /// - `u32` index = `.assign`
    /// - `32B` new owner program id
    static func assign(params: Solana.SystemProgram.AssignParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [
          .init(pubkey: params.accountPubkey, isSigner: true, isWritable: true)
        ],
        programId: self.programId,
        data: Index.assign, params.programId.data()
      )
    }
    
    /// Build `AssignWithSeed` instruction.
    ///
    /// Keys:
    /// 0. `[writable]` derived account (`accountPubkey`)
    /// 1. `[signer]`   base used in derivation (`basePubkey`)
    ///
    /// Data:
    /// - `u32` index = `.assignWithSeed`
    /// - `32B` base pubkey
    /// - `rust string` seed
    /// - `32B` new owner program id
    static func assign(params: Solana.SystemProgram.AssignWithSeedParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [
          .init(pubkey: params.accountPubkey, isSigner: false, isWritable: true),
          .init(pubkey: params.basePubkey, isSigner: true, isWritable: false),
        ],
        programId: self.programId,
        data: Index.assignWithSeed, params.basePubkey.data(), params.seed.rustBytes, params.programId.data()
      )
    }
    
    // MARK: - CreateAccountWithSeed
    
    /// Build `CreateAccountWithSeed` instruction.
    ///
    /// Keys:
    /// 0. `[signer, writable]` payer (`fromPubkey`)
    /// 1. `[writable]`        new derived account (`newAccountPubkey`)
    /// 2. `[signer]`          base (`basePubkey`) — **only if** `base != from`
    ///
    /// Data:
    /// - `u32` index = `.createWithSeed`
    /// - `32B` base pubkey
    /// - `rust string` seed
    /// - `u64` lamports
    /// - `u64` space
    /// - `32B` owner program id
    static func createAccountWithSeed(params: Solana.SystemProgram.CreateAccountWithSeedParams) -> TransactionInstruction {
      var keys: [Solana.AccountMeta] = [
        .init(pubkey: params.fromPubkey, isSigner: true, isWritable: true),
        .init(pubkey: params.newAccountPubkey, isSigner: false, isWritable: true),
      ]
      if params.basePubkey != params.fromPubkey {
        keys.append(
          .init(pubkey: params.basePubkey, isSigner: true, isWritable: false)
        )
      }
      return TransactionInstruction(
        keys: keys,
        programId: self.programId,
        data: Index.createWithSeed, params.basePubkey.data(), params.seed.rustBytes, params.lamports, params.space, params.programId.data()
      )
    }
    
    // MARK: - Nonce helpers (compose multiple instructions)
    
    /// Build a transaction that **creates** and then **initializes** a Nonce account.
    static func createNonceAccount(params: Solana.SystemProgram.CreateNonceAccountParams) throws -> Transaction {
      return try Transaction()
        .adding(instructions: Self.createAccount(
          params: .init(
            fromPubkey: params.fromPubkey,
            newAccountPubkey: params.noncePubkey,
            lamports: params.lamports,
            space: .NONCE_ACCOUNT_LENGTH,
            programId: self.programId
          )
        ))
        .adding(instructions: Self.nonceInitialize(
          params: .init(
            noncePubkey: params.noncePubkey,
            authorizedPubkey: params.authorizedPubkey
          )
        ))
    }
    
    /// Build a transaction that **creates with seed** and then **initializes** a Nonce account.
    static func createNonceAccount(params: CreateNonceAccountWithSeedParams) throws -> Transaction {
      return try Transaction()
        .adding(instructions: Self.createAccountWithSeed(
          params: .init(
            fromPubkey: params.fromPubkey,
            newAccountPubkey: params.noncePubkey,
            basePubkey: params.basePubkey,
            seed: params.seed,
            lamports: params.lamports,
            space: .NONCE_ACCOUNT_LENGTH,
            programId: self.programId
          )
        ))
        .adding(instructions: Self.nonceInitialize(
          params: .init(
            noncePubkey: params.noncePubkey,
            authorizedPubkey: params.authorizedPubkey
          )
        ))
    }
    
    // MARK: - Nonce instructions
    
    /// Build `InitializeNonceAccount` instruction.
    ///
    /// Keys:
    /// 0. `[writable]` nonce account
    /// 1. `[]`         sysvar recent blockhashes
    /// 2. `[]`         sysvar rent
    ///
    /// Data:
    /// - `u32` index = `.initializeNonceAccount`
    /// - `32B` authorized pubkey
    static func nonceInitialize(params: Solana.SystemProgram.InitializeNonceParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [
          .init(pubkey: params.noncePubkey, isSigner: false, isWritable: true),
          .init(pubkey: Solana.SysVar.recentBlockhashes, isSigner: false, isWritable: false),
          .init(pubkey: Solana.SysVar.rent, isSigner: false, isWritable: false)
        ],
        programId: self.programId,
        data: Index.initializeNonceAccount, params.authorizedPubkey.data()
      )
    }
    
    /// Build `AdvanceNonceAccount` instruction.
    ///
    /// Keys:
    /// 0. `[writable]` nonce account
    /// 1. `[]`         sysvar recent blockhashes
    /// 2. `[signer]`   nonce authority
    public static func nonceAdvance(params: Solana.SystemProgram.AdvanceNonceParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [
          .init(pubkey: params.noncePubkey, isSigner: false, isWritable: true),
          .init(pubkey: Solana.SysVar.recentBlockhashes, isSigner: false, isWritable: false),
          .init(pubkey: params.authorizedPubkey, isSigner: true, isWritable: false),
        ],
        programId: self.programId,
        data: Index.advanceNonceAccount
      )
    }
    
    /// Build `WithdrawNonceAccount` instruction.
    ///
    /// Keys:
    /// 0. `[writable]` nonce account
    /// 1. `[writable]` destination
    /// 2. `[]`         sysvar recent blockhashes
    /// 3. `[]`         sysvar rent
    /// 4. `[signer]`   nonce authority
    ///
    /// Data:
    /// - `u32` index = `.withdrawNonceAccount`
    /// - `u64` lamports
    static func nonceWithdraw(params: Solana.SystemProgram.WithdrawNonceParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [
          .init(pubkey: params.noncePubkey, isSigner: false, isWritable: true),
          .init(pubkey: params.toPubkey, isSigner: false, isWritable: true),
          .init(pubkey: Solana.SysVar.recentBlockhashes, isSigner: false, isWritable: false),
          .init(pubkey: Solana.SysVar.rent, isSigner: false, isWritable: false),
          .init(pubkey: params.authorizedPubkey, isSigner: true, isWritable: false)
        ],
        programId: self.programId,
        data: Index.withdrawNonceAccount, params.lamports
      )
    }
    
    /// Build `AuthorizeNonceAccount` instruction.
    ///
    /// Keys:
    /// 0. `[writable]` nonce account
    /// 1. `[signer]`   current authority
    ///
    /// Data:
    /// - `u32` index = `.authorizeNonceAccount`
    /// - `32B` new authority pubkey
    static func nonceAuthorize(params: Solana.SystemProgram.AuthorizeNonceParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [
          .init(pubkey: params.noncePubkey, isSigner: false, isWritable: true),
          .init(pubkey: params.authorizedPubkey, isSigner: true, isWritable: false),
        ],
        programId: self.programId,
        data: Index.authorizeNonceAccount, params.newAuthorizedPubkey.data()
      )
    }
    
    // MARK: - Allocate
    
    /// Build `Allocate` instruction (reserve space without funding).
    ///
    /// Keys:
    /// 0. `[signer, writable]` target account
    static func allocate(params: Solana.SystemProgram.AllocateParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [
          .init(pubkey: params.accountPubkey, isSigner: true, isWritable: true)
        ],
        programId: self.programId,
        data: Index.allocate, params.space
      )
    }
    
    /// Build `AllocateWithSeed` instruction.
    ///
    /// Keys:
    /// 0. `[writable]` derived account
    /// 1. `[signer]`   base used in derivation
    static func allocate(params: Solana.SystemProgram.AllocateWithSeedParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [
          .init(pubkey: params.accountPubkey, isSigner: false, isWritable: true),
          .init(pubkey: params.basePubkey, isSigner: true, isWritable: false)
        ],
        programId: self.programId,
        data: Index.allocateWithSeed, params.basePubkey.data(), params.seed.rustBytes, params.space, params.programId.data()
      )
    }
  }
}
