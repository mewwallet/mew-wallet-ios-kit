//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/14/25.
//

import Foundation

extension Solana {
  struct SystemInstruction {
    
//      /**
//       * Decode a system instruction and retrieve the instruction type.
//       */
//      static decodeInstructionType(
//        instruction: TransactionInstruction,
//      ): SystemInstructionType {
//        this.checkProgramId(instruction.programId);
//
//        const instructionTypeLayout = BufferLayout.u32('instruction');
//        const typeIndex = instructionTypeLayout.decode(instruction.data);
//
//        let type: SystemInstructionType | undefined;
//        for (const [ixType, layout] of Object.entries(SYSTEM_INSTRUCTION_LAYOUTS)) {
//          if (layout.index == typeIndex) {
//            type = ixType as SystemInstructionType;
//            break;
//          }
//        }
//
//        if (!type) {
//          throw new Error('Instruction type incorrect; not a SystemInstruction');
//        }
//
//        return type;
//      }
//
      /**
       * Decode a create account system instruction and retrieve the instruction params.
       */
//      static func decodeCreateAccount(instruction: TransactionInstruction) -> CreateAccountParams {
////        this.checkProgramId(instruction.programId);
////        this.checkKeyLength(instruction.keys, 2);
//      }
//
//      /**
//       * Decode a transfer system instruction and retrieve the instruction params.
//       */
//      static decodeTransfer(
//        instruction: TransactionInstruction,
//      ): DecodedTransferInstruction {
//        this.checkProgramId(instruction.programId);
//        this.checkKeyLength(instruction.keys, 2);
//
//        const {lamports} = decodeData(
//          SYSTEM_INSTRUCTION_LAYOUTS.Transfer,
//          instruction.data,
//        );
//
//        return {
//          fromPubkey: instruction.keys[0].pubkey,
//          toPubkey: instruction.keys[1].pubkey,
//          lamports,
//        };
//      }
//
//      /**
//       * Decode a transfer with seed system instruction and retrieve the instruction params.
//       */
//      static decodeTransferWithSeed(
//        instruction: TransactionInstruction,
//      ): DecodedTransferWithSeedInstruction {
//        this.checkProgramId(instruction.programId);
//        this.checkKeyLength(instruction.keys, 3);
//
//        const {lamports, seed, programId} = decodeData(
//          SYSTEM_INSTRUCTION_LAYOUTS.TransferWithSeed,
//          instruction.data,
//        );
//
//        return {
//          fromPubkey: instruction.keys[0].pubkey,
//          basePubkey: instruction.keys[1].pubkey,
//          toPubkey: instruction.keys[2].pubkey,
//          lamports,
//          seed,
//          programId: new PublicKey(programId),
//        };
//      }
//
//      /**
//       * Decode an allocate system instruction and retrieve the instruction params.
//       */
//      static decodeAllocate(instruction: TransactionInstruction): AllocateParams {
//        this.checkProgramId(instruction.programId);
//        this.checkKeyLength(instruction.keys, 1);
//
//        const {space} = decodeData(
//          SYSTEM_INSTRUCTION_LAYOUTS.Allocate,
//          instruction.data,
//        );
//
//        return {
//          accountPubkey: instruction.keys[0].pubkey,
//          space,
//        };
//      }
//
//      /**
//       * Decode an allocate with seed system instruction and retrieve the instruction params.
//       */
//      static decodeAllocateWithSeed(
//        instruction: TransactionInstruction,
//      ): AllocateWithSeedParams {
//        this.checkProgramId(instruction.programId);
//        this.checkKeyLength(instruction.keys, 1);
//
//        const {base, seed, space, programId} = decodeData(
//          SYSTEM_INSTRUCTION_LAYOUTS.AllocateWithSeed,
//          instruction.data,
//        );
//
//        return {
//          accountPubkey: instruction.keys[0].pubkey,
//          basePubkey: new PublicKey(base),
//          seed,
//          space,
//          programId: new PublicKey(programId),
//        };
//      }
//
//      /**
//       * Decode an assign system instruction and retrieve the instruction params.
//       */
//      static decodeAssign(instruction: TransactionInstruction): AssignParams {
//        this.checkProgramId(instruction.programId);
//        this.checkKeyLength(instruction.keys, 1);
//
//        const {programId} = decodeData(
//          SYSTEM_INSTRUCTION_LAYOUTS.Assign,
//          instruction.data,
//        );
//
//        return {
//          accountPubkey: instruction.keys[0].pubkey,
//          programId: new PublicKey(programId),
//        };
//      }
//
//      /**
//       * Decode an assign with seed system instruction and retrieve the instruction params.
//       */
//      static decodeAssignWithSeed(
//        instruction: TransactionInstruction,
//      ): AssignWithSeedParams {
//        this.checkProgramId(instruction.programId);
//        this.checkKeyLength(instruction.keys, 1);
//
//        const {base, seed, programId} = decodeData(
//          SYSTEM_INSTRUCTION_LAYOUTS.AssignWithSeed,
//          instruction.data,
//        );
//
//        return {
//          accountPubkey: instruction.keys[0].pubkey,
//          basePubkey: new PublicKey(base),
//          seed,
//          programId: new PublicKey(programId),
//        };
//      }
//
//      /**
//       * Decode a create account with seed system instruction and retrieve the instruction params.
//       */
//      static decodeCreateWithSeed(
//        instruction: TransactionInstruction,
//      ): CreateAccountWithSeedParams {
//        this.checkProgramId(instruction.programId);
//        this.checkKeyLength(instruction.keys, 2);
//
//        const {base, seed, lamports, space, programId} = decodeData(
//          SYSTEM_INSTRUCTION_LAYOUTS.CreateWithSeed,
//          instruction.data,
//        );
//
//        return {
//          fromPubkey: instruction.keys[0].pubkey,
//          newAccountPubkey: instruction.keys[1].pubkey,
//          basePubkey: new PublicKey(base),
//          seed,
//          lamports,
//          space,
//          programId: new PublicKey(programId),
//        };
//      }
//
//      /**
//       * Decode a nonce initialize system instruction and retrieve the instruction params.
//       */
//      static decodeNonceInitialize(
//        instruction: TransactionInstruction,
//      ): InitializeNonceParams {
//        this.checkProgramId(instruction.programId);
//        this.checkKeyLength(instruction.keys, 3);
//
//        const {authorized} = decodeData(
//          SYSTEM_INSTRUCTION_LAYOUTS.InitializeNonceAccount,
//          instruction.data,
//        );
//
//        return {
//          noncePubkey: instruction.keys[0].pubkey,
//          authorizedPubkey: new PublicKey(authorized),
//        };
//      }
//
//      /**
//       * Decode a nonce advance system instruction and retrieve the instruction params.
//       */
//      static decodeNonceAdvance(
//        instruction: TransactionInstruction,
//      ): AdvanceNonceParams {
//        this.checkProgramId(instruction.programId);
//        this.checkKeyLength(instruction.keys, 3);
//
//        decodeData(
//          SYSTEM_INSTRUCTION_LAYOUTS.AdvanceNonceAccount,
//          instruction.data,
//        );
//
//        return {
//          noncePubkey: instruction.keys[0].pubkey,
//          authorizedPubkey: instruction.keys[2].pubkey,
//        };
//      }
//
//      /**
//       * Decode a nonce withdraw system instruction and retrieve the instruction params.
//       */
//      static decodeNonceWithdraw(
//        instruction: TransactionInstruction,
//      ): WithdrawNonceParams {
//        this.checkProgramId(instruction.programId);
//        this.checkKeyLength(instruction.keys, 5);
//
//        const {lamports} = decodeData(
//          SYSTEM_INSTRUCTION_LAYOUTS.WithdrawNonceAccount,
//          instruction.data,
//        );
//
//        return {
//          noncePubkey: instruction.keys[0].pubkey,
//          toPubkey: instruction.keys[1].pubkey,
//          authorizedPubkey: instruction.keys[4].pubkey,
//          lamports,
//        };
//      }
//
//      /**
//       * Decode a nonce authorize system instruction and retrieve the instruction params.
//       */
//      static decodeNonceAuthorize(
//        instruction: TransactionInstruction,
//      ): AuthorizeNonceParams {
//        this.checkProgramId(instruction.programId);
//        this.checkKeyLength(instruction.keys, 2);
//
//        const {authorized} = decodeData(
//          SYSTEM_INSTRUCTION_LAYOUTS.AuthorizeNonceAccount,
//          instruction.data,
//        );
//
//        return {
//          noncePubkey: instruction.keys[0].pubkey,
//          authorizedPubkey: instruction.keys[1].pubkey,
//          newAuthorizedPubkey: new PublicKey(authorized),
//        };
//      }
//
//      /**
//       * @internal
//       */
//      static checkProgramId(programId: PublicKey) {
//        if (!programId.equals(SystemProgram.programId)) {
//          throw new Error('invalid instruction; programId is not SystemProgram');
//        }
//      }
//
//      /**
//       * @internal
//       */
//      static checkKeyLength(keys: Array<any>, expectedLength: number) {
//        if (keys.length < expectedLength) {
//          throw new Error(
//            `invalid instruction; found ${keys.length} keys, expected at least ${expectedLength}`,
//          );
//        }
//      }
//    }
  }
}
