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
  public struct SystemProgram {
    public enum Index: UInt32, EndianBytesEncodable {
      case create                   = 0
      case assign                   = 1
      case transfer                 = 2
      case createWithSeed           = 3
      case advanceNonceAccount      = 4
      case withdrawNonceAccount     = 5
      case initializeNonceAccount   = 6
      case authorizeNonceAccount    = 7
      case allocate                 = 8
      case allocateWithSeed         = 9
      case assignWithSeed           = 10
      case transferWithSeed         = 11
      case upgradeNonceAccount      = 12
      
      
      
      //      Create: {
      //          index: 0,
      //          layout: BufferLayout.struct<SystemInstructionInputData['Create']>([
      //            BufferLayout.u32('instruction'),
      //            BufferLayout.ns64('lamports'),
      //            BufferLayout.ns64('space'),
      //            Layout.publicKey('programId'),
      //          ]),
      //        },
      //        Assign: {
      //          index: 1,
      //          layout: BufferLayout.struct<SystemInstructionInputData['Assign']>([
      //            BufferLayout.u32('instruction'),
      //            Layout.publicKey('programId'),
      //          ]),
      //        },
      //        Transfer: {
      //          index: 2,
      //          layout: BufferLayout.struct<SystemInstructionInputData['Transfer']>([
      //            BufferLayout.u32('instruction'),
      //            u64('lamports'),
      //          ]),
      //        },
      //        CreateWithSeed: {
      //          index: 3,
      //          layout: BufferLayout.struct<SystemInstructionInputData['CreateWithSeed']>([
      //            BufferLayout.u32('instruction'),
      //            Layout.publicKey('base'),
      //            Layout.rustString('seed'),
      //            BufferLayout.ns64('lamports'),
      //            BufferLayout.ns64('space'),
      //            Layout.publicKey('programId'),
      //          ]),
      //        },
      //        AdvanceNonceAccount: {
      //          index: 4,
      //          layout: BufferLayout.struct<
      //            SystemInstructionInputData['AdvanceNonceAccount']
      //          >([BufferLayout.u32('instruction')]),
      //        },
      //        WithdrawNonceAccount: {
      //          index: 5,
      //          layout: BufferLayout.struct<
      //            SystemInstructionInputData['WithdrawNonceAccount']
      //          >([BufferLayout.u32('instruction'), BufferLayout.ns64('lamports')]),
      //        },
      //        InitializeNonceAccount: {
      //          index: 6,
      //          layout: BufferLayout.struct<
      //            SystemInstructionInputData['InitializeNonceAccount']
      //          >([BufferLayout.u32('instruction'), Layout.publicKey('authorized')]),
      //        },
      //        AuthorizeNonceAccount: {
      //          index: 7,
      //          layout: BufferLayout.struct<
      //            SystemInstructionInputData['AuthorizeNonceAccount']
      //          >([BufferLayout.u32('instruction'), Layout.publicKey('authorized')]),
      //        },
      //        Allocate: {
      //          index: 8,
      //          layout: BufferLayout.struct<SystemInstructionInputData['Allocate']>([
      //            BufferLayout.u32('instruction'),
      //            BufferLayout.ns64('space'),
      //          ]),
      //        },
      //        AllocateWithSeed: {
      //          index: 9,
      //          layout: BufferLayout.struct<SystemInstructionInputData['AllocateWithSeed']>(
      //            [
      //              BufferLayout.u32('instruction'),
      //              Layout.publicKey('base'),
      //              Layout.rustString('seed'),
      //              BufferLayout.ns64('space'),
      //              Layout.publicKey('programId'),
      //            ],
      //          ),
      //        },
      //        AssignWithSeed: {
      //          index: 10,
      //          layout: BufferLayout.struct<SystemInstructionInputData['AssignWithSeed']>([
      //            BufferLayout.u32('instruction'),
      //            Layout.publicKey('base'),
      //            Layout.rustString('seed'),
      //            Layout.publicKey('programId'),
      //          ]),
      //        },
      //        TransferWithSeed: {
      //          index: 11,
      //          layout: BufferLayout.struct<SystemInstructionInputData['TransferWithSeed']>(
      //            [
      //              BufferLayout.u32('instruction'),
      //              u64('lamports'),
      //              Layout.rustString('seed'),
      //              Layout.publicKey('programId'),
      //            ],
      //          ),
      //        },
      //        UpgradeNonceAccount: {
      //          index: 12,
      //          layout: BufferLayout.struct<
      //            SystemInstructionInputData['UpgradeNonceAccount']
      //          >([BufferLayout.u32('instruction')]),
      //        },
    }
    
    /// Public key that identifies the System program
    public static let programId: PublicKey = try! .init(base58: "11111111111111111111111111111111", network: .solana)
    
    /**
     * Generate a transaction instruction that creates a new account
     */
    public static func createAccount(params: Solana.SystemProgram.CreateAccountParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [
          .init(pubkey: params.fromPubkey, isSigner: true, isWritable: true),
          .init(pubkey: params.newAccountPubkey, isSigner: true, isWritable: true),
        ],
        programId: SystemProgram.programId,
        data: Index.create, params.lamports, params.space, params.programId.data()
      )
    }
    
    /**
     * Generate a transaction instruction that transfers lamports from one account to another
     */
    public static func transfer(params: Solana.SystemProgram.TransferParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [
          .init(pubkey: params.fromPubkey, isSigner: true, isWritable: true),
          .init(pubkey: params.toPubkey, isSigner: false, isWritable: true),
        ],
        programId: SystemProgram.programId,
        data: Index.transfer, params.lamports
      )
    }
    
    public static func transfer(params: Solana.SystemProgram.TransferWithSeedParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [
          .init(pubkey: params.fromPubkey, isSigner: false, isWritable: true),
          .init(pubkey: params.basePubkey, isSigner: true, isWritable: false),
          .init(pubkey: params.toPubkey, isSigner: true, isWritable: true),
        ],
        programId: SystemProgram.programId,
        data: Index.transferWithSeed, params.lamports, params.seed.rustBytes, params.programId.data()
      )
    }
    
    
    /**
     * Generate a transaction instruction that assigns an account to a program
     */
    static func assign(params: Solana.SystemProgram.AssignParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [
          .init(pubkey: params.accountPubkey, isSigner: true, isWritable: true)
        ],
        programId: self.programId,
        data: Index.assign, params.programId.data()
      )
    }
    
    /**
     * Generate a transaction instruction that assigns an account to a program
     */
    static func assign(params: Solana.SystemProgram.AssignWithSeedParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [
          .init(pubkey: params.accountPubkey, isSigner: false, isWritable: true),
          .init(pubkey: params.basePubkey, isSigner: true, isWritable: false),
        ],
        programId: self.programId,
        data: Index.assign, params.basePubkey.data(), params.seed.rustBytes
      )
    }
    
    /**
     * Generate a transaction instruction that creates a new account at
     *   an address generated with `from`, a seed, and programId
     */
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
    
    /**
     * Generate a transaction that creates a new Nonce account
     */
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
    
    /**
     * Generate a transaction that creates a new Nonce account
     */
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
    
    /**
     * Generate an instruction to initialize a Nonce account
     */
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
    
    /**
     * Generate an instruction to advance the nonce in a Nonce account
     */
    public static func nonceAdvance(params: Solana.SystemProgram.AdvanceNonceParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [
          .init(pubkey: params.noncePubkey, isSigner: false, isWritable: true),
          .init(pubkey: Solana.SysVar.recentBlockhashes, isSigner: false, isWritable: false),
          .init(pubkey: params.authorizedPubkey, isSigner: true, isWritable: false),
        ],
        programId: SystemProgram.programId,
        data: Index.advanceNonceAccount
      )
    }
    
    
    /**
     * Generate a transaction instruction that withdraws lamports from a Nonce account
     */
    static func nonceWithdraw(params: Solana.SystemProgram.WithdrawNonceParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [
          .init(pubkey: params.noncePubkey, isSigner: false, isWritable: true),
          .init(pubkey: params.toPubkey, isSigner: false, isWritable: true),
          .init(pubkey: Solana.SysVar.recentBlockhashes, isSigner: false, isWritable: false),
          .init(pubkey: Solana.SysVar.rent, isSigner: false, isWritable: false),
          .init(pubkey: params.authorizedPubkey, isSigner: true, isWritable: false)
        ],
        programId: SystemProgram.programId,
        data: Index.withdrawNonceAccount, params.lamports
      )
    }
    
    /**
     * Generate a transaction instruction that authorizes a new PublicKey as the authority
     * on a Nonce account.
     */
    static func nonceAuthorize(params: Solana.SystemProgram.AuthorizeNonceParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [
          .init(pubkey: params.noncePubkey, isSigner: false, isWritable: true),
          .init(pubkey: params.authorizedPubkey, isSigner: true, isWritable: false),
        ],
        programId: SystemProgram.programId,
        data: Index.authorizeNonceAccount, params.newAuthorizedPubkey.data()
      )
    }
    
    /**
     * Generate a transaction instruction that allocates space in an account without funding
     */
    static func allocate(params: Solana.SystemProgram.AllocateParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [
          .init(pubkey: params.accountPubkey, isSigner: true, isWritable: true)
        ],
        programId: SystemProgram.programId,
        data: Index.allocateWithSeed, params.space
      )
    }
    
    /**
     * Generate a transaction instruction that allocates space in an account without funding
     */
    static func allocate(params: Solana.SystemProgram.AllocateWithSeedParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [
          .init(pubkey: params.accountPubkey, isSigner: false, isWritable: true),
          .init(pubkey: params.basePubkey, isSigner: true, isWritable: false)
        ],
        programId: SystemProgram.programId,
        data: Index.allocateWithSeed, params.basePubkey.data(), params.seed.rustBytes, params.space, params.programId.data()
      )
    } 
  }
}
