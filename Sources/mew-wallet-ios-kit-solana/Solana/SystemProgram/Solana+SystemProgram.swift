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
    
    public static let programId: PublicKey = try! .init(base58: "11111111111111111111111111111111", network: .solana)
//    /**
//       * @internal
//       */
//      constructor() {}
//
//      /**
//       * Public key that identifies the System program
//       */
//      static programId: PublicKey = new PublicKey(
//        '11111111111111111111111111111111',
//      );
//
//      /**
//       * Generate a transaction instruction that creates a new account
//       */
//      static createAccount(params: CreateAccountParams): TransactionInstruction {
//        const type = SYSTEM_INSTRUCTION_LAYOUTS.Create;
//        const data = encodeData(type, {
//          lamports: params.lamports,
//          space: params.space,
//          programId: toBuffer(params.programId.toBuffer()),
//        });
//
//        return new TransactionInstruction({
//          keys: [
//            {pubkey: params.fromPubkey, isSigner: true, isWritable: true},
//            {pubkey: params.newAccountPubkey, isSigner: true, isWritable: true},
//          ],
//          programId: this.programId,
//          data,
//        });
//      }
//
    /**
     * Generate a transaction instruction that transfers lamports from one account to another
     */
    public static func transfer(params: TransferParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [
          .init(pubkey: params.fromPubkey, isSigner: true, isWritable: true),
          .init(pubkey: params.toPubkey, isSigner: false, isWritable: true),
        ],
        programId: SystemProgram.programId,
        data: Index.transfer, params.lamports
      )
    }
    
    public static func transfer(params: TransferWithSeedParams) -> TransactionInstruction {
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
    
//
//      /**
//       * Generate a transaction instruction that assigns an account to a program
//       */
//      static assign(
//        params: AssignParams | AssignWithSeedParams,
//      ): TransactionInstruction {
//        let data;
//        let keys;
//        if ('basePubkey' in params) {
//          const type = SYSTEM_INSTRUCTION_LAYOUTS.AssignWithSeed;
//          data = encodeData(type, {
//            base: toBuffer(params.basePubkey.toBuffer()),
//            seed: params.seed,
//            programId: toBuffer(params.programId.toBuffer()),
//          });
//          keys = [
//            {pubkey: params.accountPubkey, isSigner: false, isWritable: true},
//            {pubkey: params.basePubkey, isSigner: true, isWritable: false},
//          ];
//        } else {
//          const type = SYSTEM_INSTRUCTION_LAYOUTS.Assign;
//          data = encodeData(type, {
//            programId: toBuffer(params.programId.toBuffer()),
//          });
//          keys = [{pubkey: params.accountPubkey, isSigner: true, isWritable: true}];
//        }
//
//        return new TransactionInstruction({
//          keys,
//          programId: this.programId,
//          data,
//        });
//      }
//
//      /**
//       * Generate a transaction instruction that creates a new account at
//       *   an address generated with `from`, a seed, and programId
//       */
//      static createAccountWithSeed(
//        params: CreateAccountWithSeedParams,
//      ): TransactionInstruction {
//        const type = SYSTEM_INSTRUCTION_LAYOUTS.CreateWithSeed;
//        const data = encodeData(type, {
//          base: toBuffer(params.basePubkey.toBuffer()),
//          seed: params.seed,
//          lamports: params.lamports,
//          space: params.space,
//          programId: toBuffer(params.programId.toBuffer()),
//        });
//        let keys = [
//          {pubkey: params.fromPubkey, isSigner: true, isWritable: true},
//          {pubkey: params.newAccountPubkey, isSigner: false, isWritable: true},
//        ];
//        if (!params.basePubkey.equals(params.fromPubkey)) {
//          keys.push({
//            pubkey: params.basePubkey,
//            isSigner: true,
//            isWritable: false,
//          });
//        }
//
//        return new TransactionInstruction({
//          keys,
//          programId: this.programId,
//          data,
//        });
//      }
//
//      /**
//       * Generate a transaction that creates a new Nonce account
//       */
//      static createNonceAccount(
//        params: CreateNonceAccountParams | CreateNonceAccountWithSeedParams,
//      ): Transaction {
//        const transaction = new Transaction();
//        if ('basePubkey' in params && 'seed' in params) {
//          transaction.add(
//            SystemProgram.createAccountWithSeed({
//              fromPubkey: params.fromPubkey,
//              newAccountPubkey: params.noncePubkey,
//              basePubkey: params.basePubkey,
//              seed: params.seed,
//              lamports: params.lamports,
//              space: NONCE_ACCOUNT_LENGTH,
//              programId: this.programId,
//            }),
//          );
//        } else {
//          transaction.add(
//            SystemProgram.createAccount({
//              fromPubkey: params.fromPubkey,
//              newAccountPubkey: params.noncePubkey,
//              lamports: params.lamports,
//              space: NONCE_ACCOUNT_LENGTH,
//              programId: this.programId,
//            }),
//          );
//        }
//
//        const initParams = {
//          noncePubkey: params.noncePubkey,
//          authorizedPubkey: params.authorizedPubkey,
//        };
//
//        transaction.add(this.nonceInitialize(initParams));
//        return transaction;
//      }
//
//      /**
//       * Generate an instruction to initialize a Nonce account
//       */
//      static nonceInitialize(
//        params: InitializeNonceParams,
//      ): TransactionInstruction {
//        const type = SYSTEM_INSTRUCTION_LAYOUTS.InitializeNonceAccount;
//        const data = encodeData(type, {
//          authorized: toBuffer(params.authorizedPubkey.toBuffer()),
//        });
//        const instructionData = {
//          keys: [
//            {pubkey: params.noncePubkey, isSigner: false, isWritable: true},
//            {
//              pubkey: SYSVAR_RECENT_BLOCKHASHES_PUBKEY,
//              isSigner: false,
//              isWritable: false,
//            },
//            {pubkey: SYSVAR_RENT_PUBKEY, isSigner: false, isWritable: false},
//          ],
//          programId: this.programId,
//          data,
//        };
//        return new TransactionInstruction(instructionData);
//      }
//
      /**
       * Generate an instruction to advance the nonce in a Nonce account
       */
    public static func nonceAdvance(params: AdvanceNonceParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [
          .init(pubkey: params.noncePubkey, isSigner: false, isWritable: true),
          .init(pubkey: Solana.SystemProgram.SysVar.recentBlockhashes, isSigner: false, isWritable: false),
          .init(pubkey: params.authorizedPubkey, isSigner: true, isWritable: false),
        ],
        programId: SystemProgram.programId,
        data: Index.advanceNonceAccount
      )
    }
    
//      static nonceAdvance(params: AdvanceNonceParams): TransactionInstruction {
//        const type = SYSTEM_INSTRUCTION_LAYOUTS.AdvanceNonceAccount;
//        const data = encodeData(type);
//        const instructionData = {
//          keys: [
//            {pubkey: params.noncePubkey, isSigner: false, isWritable: true},
//            {
//              pubkey: SYSVAR_RECENT_BLOCKHASHES_PUBKEY,
//              isSigner: false,
//              isWritable: false,
//            },
//            {pubkey: params.authorizedPubkey, isSigner: true, isWritable: false},
//          ],
//          programId: this.programId,
//          data,
//        };
//        return new TransactionInstruction(instructionData);
//      }
//
//      /**
//       * Generate a transaction instruction that withdraws lamports from a Nonce account
//       */
//      static nonceWithdraw(params: WithdrawNonceParams): TransactionInstruction {
//        const type = SYSTEM_INSTRUCTION_LAYOUTS.WithdrawNonceAccount;
//        const data = encodeData(type, {lamports: params.lamports});
//
//        return new TransactionInstruction({
//          keys: [
//            {pubkey: params.noncePubkey, isSigner: false, isWritable: true},
//            {pubkey: params.toPubkey, isSigner: false, isWritable: true},
//            {
//              pubkey: SYSVAR_RECENT_BLOCKHASHES_PUBKEY,
//              isSigner: false,
//              isWritable: false,
//            },
//            {
//              pubkey: SYSVAR_RENT_PUBKEY,
//              isSigner: false,
//              isWritable: false,
//            },
//            {pubkey: params.authorizedPubkey, isSigner: true, isWritable: false},
//          ],
//          programId: this.programId,
//          data,
//        });
//      }
//
//      /**
//       * Generate a transaction instruction that authorizes a new PublicKey as the authority
//       * on a Nonce account.
//       */
//      static nonceAuthorize(params: AuthorizeNonceParams): TransactionInstruction {
//        const type = SYSTEM_INSTRUCTION_LAYOUTS.AuthorizeNonceAccount;
//        const data = encodeData(type, {
//          authorized: toBuffer(params.newAuthorizedPubkey.toBuffer()),
//        });
//
//        return new TransactionInstruction({
//          keys: [
//            {pubkey: params.noncePubkey, isSigner: false, isWritable: true},
//            {pubkey: params.authorizedPubkey, isSigner: true, isWritable: false},
//          ],
//          programId: this.programId,
//          data,
//        });
//      }
//
//      /**
//       * Generate a transaction instruction that allocates space in an account without funding
//       */
//      static allocate(
//        params: AllocateParams | AllocateWithSeedParams,
//      ): TransactionInstruction {
//        let data;
//        let keys;
//        if ('basePubkey' in params) {
//          const type = SYSTEM_INSTRUCTION_LAYOUTS.AllocateWithSeed;
//          data = encodeData(type, {
//            base: toBuffer(params.basePubkey.toBuffer()),
//            seed: params.seed,
//            space: params.space,
//            programId: toBuffer(params.programId.toBuffer()),
//          });
//          keys = [
//            {pubkey: params.accountPubkey, isSigner: false, isWritable: true},
//            {pubkey: params.basePubkey, isSigner: true, isWritable: false},
//          ];
//        } else {
//          const type = SYSTEM_INSTRUCTION_LAYOUTS.Allocate;
//          data = encodeData(type, {
//            space: params.space,
//          });
//          keys = [{pubkey: params.accountPubkey, isSigner: true, isWritable: true}];
//        }
//
//        return new TransactionInstruction({
//          keys,
//          programId: this.programId,
//          data,
//        });
//      }
  }
}
