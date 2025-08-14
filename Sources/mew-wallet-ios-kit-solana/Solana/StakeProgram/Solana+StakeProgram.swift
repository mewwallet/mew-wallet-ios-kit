//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/10/25.
//

import Foundation
import mew_wallet_ios_kit
import mew_wallet_ios_kit_utils

extension Solana {
  public struct StakeProgram {
    public enum Index: UInt32, EndianBytesEncodable {
      case initialize               = 0
      case authorize                = 1
      case delegate                 = 2
      case split                    = 3
      case withdraw                 = 4
      case deactivate               = 5
      case merge                    = 7
      case authorizeWithSeed        = 8
      

//      /**
//       * An enumeration of valid stake InstructionType's
//       * @internal
//       */
//      export const STAKE_INSTRUCTION_LAYOUTS = Object.freeze<{
//        [Instruction in StakeInstructionType]: InstructionType<
//          StakeInstructionInputData[Instruction]
//        >;
//      }>({
//        Initialize: {
//          index: 0,
//          layout: BufferLayout.struct<StakeInstructionInputData['Initialize']>([
//            BufferLayout.u32('instruction'),
//            Layout.authorized(),
//            Layout.lockup(),
//          ]),
//        },
//        Authorize: {
//          index: 1,
//          layout: BufferLayout.struct<StakeInstructionInputData['Authorize']>([
//            BufferLayout.u32('instruction'),
//            Layout.publicKey('newAuthorized'),
//            BufferLayout.u32('stakeAuthorizationType'),
//          ]),
//        },
//        Delegate: {
//          index: 2,
//          layout: BufferLayout.struct<StakeInstructionInputData['Delegate']>([
//            BufferLayout.u32('instruction'),
//          ]),
//        },
//        Split: {
//          index: 3,
//          layout: BufferLayout.struct<StakeInstructionInputData['Split']>([
//            BufferLayout.u32('instruction'),
//            BufferLayout.ns64('lamports'),
//          ]),
//        },
//        Withdraw: {
//          index: 4,
//          layout: BufferLayout.struct<StakeInstructionInputData['Withdraw']>([
//            BufferLayout.u32('instruction'),
//            BufferLayout.ns64('lamports'),
//          ]),
//        },
//        Deactivate: {
//          index: 5,
//          layout: BufferLayout.struct<StakeInstructionInputData['Deactivate']>([
//            BufferLayout.u32('instruction'),
//          ]),
//        },
//        Merge: {
//          index: 7,
//          layout: BufferLayout.struct<StakeInstructionInputData['Merge']>([
//            BufferLayout.u32('instruction'),
//          ]),
//        },
//        AuthorizeWithSeed: {
//          index: 8,
//          layout: BufferLayout.struct<StakeInstructionInputData['AuthorizeWithSeed']>(
//            [
//              BufferLayout.u32('instruction'),
//              Layout.publicKey('newAuthorized'),
//              BufferLayout.u32('stakeAuthorizationType'),
//              Layout.rustString('authoritySeed'),
//              Layout.publicKey('authorityOwner'),
//            ],
//          ),
//        },
//      });
    }
    
    public static let programId: PublicKey = try! .init(base58: "Stake11111111111111111111111111111111111111", network: .solana)
    
    /**
     * Address of the stake config account which configures the rate
     * of stake warmup and cooldown as well as the slashing penalty.
     */
    public static let stakeConfigID: PublicKey = try! .init(base58: "StakeConfig11111111111111111111111111111111", network: .solana)
    
    /**
     * Max space of a Stake account
     *
     * This is generated from the solana-stake-program StakeState struct as
     * `StakeStateV2::size_of()`:
     * https://docs.rs/solana-stake-program/latest/solana_stake_program/stake_state/enum.StakeStateV2.html
     */
    public static let space = 200

    /**
     * Generate an Initialize instruction to add to a Stake Create transaction
     */
//    static initialize(params: InitializeStakeParams): TransactionInstruction {
//      const {stakePubkey, authorized, lockup: maybeLockup} = params;
//      const lockup: Lockup = maybeLockup || Lockup.default;
//      const type = STAKE_INSTRUCTION_LAYOUTS.Initialize;
//      const data = encodeData(type, {
//        authorized: {
//          staker: toBuffer(authorized.staker.toBuffer()),
//          withdrawer: toBuffer(authorized.withdrawer.toBuffer()),
//        },
//        lockup: {
//          unixTimestamp: lockup.unixTimestamp,
//          epoch: lockup.epoch,
//          custodian: toBuffer(lockup.custodian.toBuffer()),
//        },
//      });
//      const instructionData = {
//        keys: [
//          {pubkey: stakePubkey, isSigner: false, isWritable: true},
//          {pubkey: SYSVAR_RENT_PUBKEY, isSigner: false, isWritable: false},
//        ],
//        programId: this.programId,
//        data,
//      };
//      return new TransactionInstruction(instructionData);
//    }
//
//    /**
//     * Generate a Transaction that creates a new Stake account at
//     *   an address generated with `from`, a seed, and the Stake programId
//     */
//    static createAccountWithSeed(
//      params: CreateStakeAccountWithSeedParams,
//    ): Transaction {
//      const transaction = new Transaction();
//      transaction.add(
//        SystemProgram.createAccountWithSeed({
//          fromPubkey: params.fromPubkey,
//          newAccountPubkey: params.stakePubkey,
//          basePubkey: params.basePubkey,
//          seed: params.seed,
//          lamports: params.lamports,
//          space: this.space,
//          programId: this.programId,
//        }),
//      );
//
//      const {stakePubkey, authorized, lockup} = params;
//      return transaction.add(this.initialize({stakePubkey, authorized, lockup}));
//    }
//
//    /**
//     * Generate a Transaction that creates a new Stake account
//     */
//    static createAccount(params: CreateStakeAccountParams): Transaction {
//      const transaction = new Transaction();
//      transaction.add(
//        SystemProgram.createAccount({
//          fromPubkey: params.fromPubkey,
//          newAccountPubkey: params.stakePubkey,
//          lamports: params.lamports,
//          space: this.space,
//          programId: this.programId,
//        }),
//      );
//
//      const {stakePubkey, authorized, lockup} = params;
//      return transaction.add(this.initialize({stakePubkey, authorized, lockup}));
//    }
//
//    /**
//     * Generate a Transaction that delegates Stake tokens to a validator
//     * Vote PublicKey. This transaction can also be used to redelegate Stake
//     * to a new validator Vote PublicKey.
//     */
    public static func delegate(params: DelegateStakeParams) throws -> Transaction {
      return Transaction(
        instructions: [
          .init(
            keys: [
              .init(pubkey: params.stakePubkey, isSigner: false, isWritable: true),
              .init(pubkey: params.votePubkey, isSigner: false, isWritable: false),
              .init(pubkey: Solana.SysVar.clock, isSigner: false, isWritable: false),
              .init(pubkey: Solana.SysVar.stakeHistory, isSigner: false, isWritable: false),
              .init(pubkey: Self.stakeConfigID, isSigner: false, isWritable: false),
              .init(pubkey: params.authorizedPubkey, isSigner: true, isWritable: false),
            ],
            programId: Self.programId,
            data: Index.delegate
          )
        ]
      )
    }
    
//    static delegate(params: DelegateStakeParams): Transaction {
//      const {stakePubkey, authorizedPubkey, votePubkey} = params;
//
//      const type = STAKE_INSTRUCTION_LAYOUTS.Delegate;
//      const data = encodeData(type);
//
//      return new Transaction().add({
//        keys: [
//          {pubkey: stakePubkey, isSigner: false, isWritable: true},
//          {pubkey: votePubkey, isSigner: false, isWritable: false},
//          {pubkey: SYSVAR_CLOCK_PUBKEY, isSigner: false, isWritable: false},
//          {
//            pubkey: SYSVAR_STAKE_HISTORY_PUBKEY,
//            isSigner: false,
//            isWritable: false,
//          },
//          {pubkey: STAKE_CONFIG_ID, isSigner: false, isWritable: false},
//          {pubkey: authorizedPubkey, isSigner: true, isWritable: false},
//        ],
//        programId: this.programId,
//        data,
//      });
//    }
//
//    /**
//     * Generate a Transaction that authorizes a new PublicKey as Staker
//     * or Withdrawer on the Stake account.
//     */
//    static authorize(params: AuthorizeStakeParams): Transaction {
//      const {
//        stakePubkey,
//        authorizedPubkey,
//        newAuthorizedPubkey,
//        stakeAuthorizationType,
//        custodianPubkey,
//      } = params;
//
//      const type = STAKE_INSTRUCTION_LAYOUTS.Authorize;
//      const data = encodeData(type, {
//        newAuthorized: toBuffer(newAuthorizedPubkey.toBuffer()),
//        stakeAuthorizationType: stakeAuthorizationType.index,
//      });
//
//      const keys = [
//        {pubkey: stakePubkey, isSigner: false, isWritable: true},
//        {pubkey: SYSVAR_CLOCK_PUBKEY, isSigner: false, isWritable: true},
//        {pubkey: authorizedPubkey, isSigner: true, isWritable: false},
//      ];
//      if (custodianPubkey) {
//        keys.push({
//          pubkey: custodianPubkey,
//          isSigner: true,
//          isWritable: false,
//        });
//      }
//      return new Transaction().add({
//        keys,
//        programId: this.programId,
//        data,
//      });
//    }
//
//    /**
//     * Generate a Transaction that authorizes a new PublicKey as Staker
//     * or Withdrawer on the Stake account.
//     */
//    static authorizeWithSeed(params: AuthorizeWithSeedStakeParams): Transaction {
//      const {
//        stakePubkey,
//        authorityBase,
//        authoritySeed,
//        authorityOwner,
//        newAuthorizedPubkey,
//        stakeAuthorizationType,
//        custodianPubkey,
//      } = params;
//
//      const type = STAKE_INSTRUCTION_LAYOUTS.AuthorizeWithSeed;
//      const data = encodeData(type, {
//        newAuthorized: toBuffer(newAuthorizedPubkey.toBuffer()),
//        stakeAuthorizationType: stakeAuthorizationType.index,
//        authoritySeed: authoritySeed,
//        authorityOwner: toBuffer(authorityOwner.toBuffer()),
//      });
//
//      const keys = [
//        {pubkey: stakePubkey, isSigner: false, isWritable: true},
//        {pubkey: authorityBase, isSigner: true, isWritable: false},
//        {pubkey: SYSVAR_CLOCK_PUBKEY, isSigner: false, isWritable: false},
//      ];
//      if (custodianPubkey) {
//        keys.push({
//          pubkey: custodianPubkey,
//          isSigner: true,
//          isWritable: false,
//        });
//      }
//      return new Transaction().add({
//        keys,
//        programId: this.programId,
//        data,
//      });
//    }
//
//    /**
//     * @internal
//     */
//    static splitInstruction(params: SplitStakeParams): TransactionInstruction {
//      const {stakePubkey, authorizedPubkey, splitStakePubkey, lamports} = params;
//      const type = STAKE_INSTRUCTION_LAYOUTS.Split;
//      const data = encodeData(type, {lamports});
//      return new TransactionInstruction({
//        keys: [
//          {pubkey: stakePubkey, isSigner: false, isWritable: true},
//          {pubkey: splitStakePubkey, isSigner: false, isWritable: true},
//          {pubkey: authorizedPubkey, isSigner: true, isWritable: false},
//        ],
//        programId: this.programId,
//        data,
//      });
//    }
//
//    /**
//     * Generate a Transaction that splits Stake tokens into another stake account
//     */
//    static split(
//      params: SplitStakeParams,
//      // Compute the cost of allocating the new stake account in lamports
//      rentExemptReserve: number,
//    ): Transaction {
//      const transaction = new Transaction();
//      transaction.add(
//        SystemProgram.createAccount({
//          fromPubkey: params.authorizedPubkey,
//          newAccountPubkey: params.splitStakePubkey,
//          lamports: rentExemptReserve,
//          space: this.space,
//          programId: this.programId,
//        }),
//      );
//      return transaction.add(this.splitInstruction(params));
//    }
//
//    /**
//     * Generate a Transaction that splits Stake tokens into another account
//     * derived from a base public key and seed
//     */
//    static splitWithSeed(
//      params: SplitStakeWithSeedParams,
//      // If this stake account is new, compute the cost of allocating it in lamports
//      rentExemptReserve?: number,
//    ): Transaction {
//      const {
//        stakePubkey,
//        authorizedPubkey,
//        splitStakePubkey,
//        basePubkey,
//        seed,
//        lamports,
//      } = params;
//      const transaction = new Transaction();
//      transaction.add(
//        SystemProgram.allocate({
//          accountPubkey: splitStakePubkey,
//          basePubkey,
//          seed,
//          space: this.space,
//          programId: this.programId,
//        }),
//      );
//      if (rentExemptReserve && rentExemptReserve > 0) {
//        transaction.add(
//          SystemProgram.transfer({
//            fromPubkey: params.authorizedPubkey,
//            toPubkey: splitStakePubkey,
//            lamports: rentExemptReserve,
//          }),
//        );
//      }
//      return transaction.add(
//        this.splitInstruction({
//          stakePubkey,
//          authorizedPubkey,
//          splitStakePubkey,
//          lamports,
//        }),
//      );
//    }
//
//    /**
//     * Generate a Transaction that merges Stake accounts.
//     */
//    static merge(params: MergeStakeParams): Transaction {
//      const {stakePubkey, sourceStakePubKey, authorizedPubkey} = params;
//      const type = STAKE_INSTRUCTION_LAYOUTS.Merge;
//      const data = encodeData(type);
//
//      return new Transaction().add({
//        keys: [
//          {pubkey: stakePubkey, isSigner: false, isWritable: true},
//          {pubkey: sourceStakePubKey, isSigner: false, isWritable: true},
//          {pubkey: SYSVAR_CLOCK_PUBKEY, isSigner: false, isWritable: false},
//          {
//            pubkey: SYSVAR_STAKE_HISTORY_PUBKEY,
//            isSigner: false,
//            isWritable: false,
//          },
//          {pubkey: authorizedPubkey, isSigner: true, isWritable: false},
//        ],
//        programId: this.programId,
//        data,
//      });
//    }
//
//    /**
//     * Generate a Transaction that withdraws deactivated Stake tokens.
//     */
//    static withdraw(params: WithdrawStakeParams): Transaction {
//      const {stakePubkey, authorizedPubkey, toPubkey, lamports, custodianPubkey} =
//        params;
//      const type = STAKE_INSTRUCTION_LAYOUTS.Withdraw;
//      const data = encodeData(type, {lamports});
//
//      const keys = [
//        {pubkey: stakePubkey, isSigner: false, isWritable: true},
//        {pubkey: toPubkey, isSigner: false, isWritable: true},
//        {pubkey: SYSVAR_CLOCK_PUBKEY, isSigner: false, isWritable: false},
//        {
//          pubkey: SYSVAR_STAKE_HISTORY_PUBKEY,
//          isSigner: false,
//          isWritable: false,
//        },
//        {pubkey: authorizedPubkey, isSigner: true, isWritable: false},
//      ];
//      if (custodianPubkey) {
//        keys.push({
//          pubkey: custodianPubkey,
//          isSigner: true,
//          isWritable: false,
//        });
//      }
//      return new Transaction().add({
//        keys,
//        programId: this.programId,
//        data,
//      });
//    }
//
//    /**
//     * Generate a Transaction that deactivates Stake tokens.
//     */
//    static deactivate(params: DeactivateStakeParams): Transaction {
//      const {stakePubkey, authorizedPubkey} = params;
//      const type = STAKE_INSTRUCTION_LAYOUTS.Deactivate;
//      const data = encodeData(type);
//
//      return new Transaction().add({
//        keys: [
//          {pubkey: stakePubkey, isSigner: false, isWritable: true},
//          {pubkey: SYSVAR_CLOCK_PUBKEY, isSigner: false, isWritable: false},
//          {pubkey: authorizedPubkey, isSigner: true, isWritable: false},
//        ],
//        programId: this.programId,
//        data,
//      });
//    }
  }
}
