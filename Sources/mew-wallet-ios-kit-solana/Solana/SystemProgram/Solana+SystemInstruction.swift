//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/14/25.
//

import Foundation
import mew_wallet_ios_kit
import mew_wallet_ios_kit_utils

extension Solana {
  struct SystemInstruction {
    public enum Error: Swift.Error, Sendable, Equatable {
      case invalidInstruction(programId: PublicKey)
      case invalidKeysCount(expected: Int, actual: Int)
      case noDecodableData
      case badData
      case badDecodedData
      case badSeedData
      case invalidSystemProgramIndex(Solana.SystemProgram.Index)
    }
    
      /**
       * Decode a create account system instruction and retrieve the instruction params.
       */
    static func decodeCreateAccount(instruction: TransactionInstruction) throws -> Solana.SystemProgram.CreateAccountParams {
      guard instruction.programId == Solana.SystemProgram.programId else {
        throw Error.invalidInstruction(programId: instruction.programId)
      }
      guard instruction.keys.count >= 2 else {
        throw Error.invalidKeysCount(expected: 2, actual: instruction.keys.count)
      }
      guard let bytes = instruction.data?.byteArray else {
        throw Error.noDecodableData
      }
      
      let contexts: [any DecodeContextProtocol] = [
        // 4 bytes
        DecodeContext.littleEndian(size: 1, type: Solana.SystemProgram.Index.self),
        // 8 bytes
        DecodeContext.littleEndian(size: 1, type: UInt64.self),
        // 8 bytes
        DecodeContext.littleEndian(size: 1, type: UInt64.self),
        // 32 bytes
        DecodeContext.littleEndian(size: 32, type: Data.self)
      ]
      guard bytes.count >= 52,
            let decoded = bytes.decode(contexts: contexts),
            decoded.count == 4 else {
        throw Error.badData
      }
      
      guard let index = decoded[0] as? Solana.SystemProgram.Index,
            let lamports = decoded[1] as? UInt64,
            let space = decoded[2] as? UInt64,
            let programIdData = decoded[3] as? Data else {
        throw Error.badDecodedData
      }
      
      guard index == .create else {
        throw Error.invalidSystemProgramIndex(index)
      }
      
      return try Solana.SystemProgram.CreateAccountParams(
        fromPubkey: instruction.keys[0].pubkey,
        newAccountPubkey: instruction.keys[1].pubkey,
        lamports: lamports,
        space: space,
        programId: PublicKey(publicKey: programIdData, index: 0, network: .solana)
      )
    }

      /**
       * Decode a transfer system instruction and retrieve the instruction params.
       */
    static func decodeTransfer(instruction: TransactionInstruction) throws -> Solana.SystemProgram.TransferParams {
      guard instruction.programId == Solana.SystemProgram.programId else {
        throw Error.invalidInstruction(programId: instruction.programId)
      }
      guard instruction.keys.count >= 2 else {
        throw Error.invalidKeysCount(expected: 2, actual: instruction.keys.count)
      }
      guard let bytes = instruction.data?.byteArray else {
        throw Error.noDecodableData
      }
      
      let contexts: [any DecodeContextProtocol] = [
        // 4 bytes
        DecodeContext.littleEndian(size: 1, type: Solana.SystemProgram.Index.self),
        // 8 bytes
        DecodeContext.littleEndian(size: 1, type: UInt64.self),
      ]
      guard bytes.count >= 12,
            let decoded = bytes.decode(contexts: contexts),
            decoded.count == 2 else {
        throw Error.badData
      }
      
      guard let index = decoded[0] as? Solana.SystemProgram.Index,
            let lamports = decoded[1] as? UInt64 else {
        throw Error.badDecodedData
      }
      
      guard index == .transfer else {
        throw Error.invalidSystemProgramIndex(index)
      }
      
      return Solana.SystemProgram.TransferParams(
        fromPubkey: instruction.keys[0].pubkey,
        toPubkey: instruction.keys[1].pubkey,
        lamports: lamports
      )
    }

      /**
       * Decode a transfer with seed system instruction and retrieve the instruction params.
       */
    static func decodeTransferWithSeed(instruction: TransactionInstruction) throws -> Solana.SystemProgram.TransferWithSeedParams {
      guard instruction.programId == Solana.SystemProgram.programId else {
        throw Error.invalidInstruction(programId: instruction.programId)
      }
      guard instruction.keys.count >= 3 else {
        throw Error.invalidKeysCount(expected: 3, actual: instruction.keys.count)
      }
      guard let data = instruction.data else {
        throw Error.noDecodableData
      }
      let bytes = data.byteArray
      
      var cursor: Int = 0
      // index - 4 bytes
      // lamports - 8 bytes
      // seedRustStringBytesCount - 4 bytes
      // seedrustString - value of seedRustStringBytesCount
      // programIdData - 32 bytes
      guard let index = Solana.SystemProgram.Index.decode(fromLittleEndian: bytes, cursor: &cursor),
            let lamports = UInt64.decode(fromLittleEndian: bytes, cursor: &cursor),
            let seedRustStringBytes = UInt32.decode(fromLittleEndian: bytes, cursor: &cursor) else {
        throw Error.badDecodedData
      }
      
      guard bytes.count >= 48 + Int(clamping: seedRustStringBytes) else {
        throw Error.badData
      }
      let seedData = try data.read(&cursor, offsetBy: Int(clamping: seedRustStringBytes))
      guard let seed = String(data: seedData, encoding: .utf8) else {
        throw Error.badSeedData
      }
      let programIdData = try data.read(&cursor, offsetBy: 32)
      
      guard index == .transferWithSeed else {
        throw Error.invalidSystemProgramIndex(index)
      }
      
      return try Solana.SystemProgram.TransferWithSeedParams(
        fromPubkey: instruction.keys[0].pubkey,
        basePubkey: instruction.keys[1].pubkey,
        toPubkey: instruction.keys[2].pubkey,
        lamports: lamports,
        seed: seed,
        programId: PublicKey(publicKey: programIdData, index: 0, network: .solana)
      )
    }
    

      /**
       * Decode an allocate system instruction and retrieve the instruction params.
       */
    static func decodeAllocate(instruction: TransactionInstruction) throws -> Solana.SystemProgram.AllocateParams {
      guard instruction.programId == Solana.SystemProgram.programId else {
        throw Error.invalidInstruction(programId: instruction.programId)
      }
      guard instruction.keys.count >= 1 else {
        throw Error.invalidKeysCount(expected: 1, actual: instruction.keys.count)
      }
      guard let bytes = instruction.data?.byteArray else {
        throw Error.noDecodableData
      }
      
      let contexts: [any DecodeContextProtocol] = [
        // 4 bytes
        DecodeContext.littleEndian(size: 1, type: Solana.SystemProgram.Index.self),
        // 8 bytes
        DecodeContext.littleEndian(size: 1, type: UInt64.self),
      ]
      guard bytes.count >= 12,
            let decoded = bytes.decode(contexts: contexts),
            decoded.count == 2 else {
        throw Error.badData
      }
      
      guard let index = decoded[0] as? Solana.SystemProgram.Index,
            let space = decoded[1] as? UInt64 else {
        throw Error.badDecodedData
      }
      
      guard index == .allocate else {
        throw Error.invalidSystemProgramIndex(index)
      }
      
      return Solana.SystemProgram.AllocateParams(
        accountPubkey: instruction.keys[0].pubkey,
        space: space
      )
    }
    
    static func decodeAllocateWithSeed(instruction: TransactionInstruction) throws -> Solana.SystemProgram.AllocateWithSeedParams {
      guard instruction.programId == Solana.SystemProgram.programId else {
        throw Error.invalidInstruction(programId: instruction.programId)
      }
      guard instruction.keys.count >= 1 else {
        throw Error.invalidKeysCount(expected: 1, actual: instruction.keys.count)
      }
      guard let data = instruction.data else {
        throw Error.noDecodableData
      }
      let bytes = data.byteArray
      
      var cursor: Int = 0
      guard let index = Solana.SystemProgram.Index.decode(fromLittleEndian: bytes, cursor: &cursor) else {
        throw Error.badDecodedData
      }
      let baseData = try data.read(&cursor, offsetBy: 32)
      guard let seedRustStringBytes = UInt32.decode(fromLittleEndian: bytes, cursor: &cursor) else {
        throw Error.badDecodedData
      }
      
      // index - 4 bytes
      // basePubKey - 32 bytes
      // seedRustStringBytesCount - 4 bytes
      // seedRustString - value of seedRustStringBytesCount
      // space - 8 bytes
      // programIdData - 32 bytes
      guard bytes.count >= 80 + Int(clamping: seedRustStringBytes) else {
        throw Error.badData
      }
      let seedData = try data.read(&cursor, offsetBy: Int(clamping: seedRustStringBytes))
      guard let seed = String(data: seedData, encoding: .utf8) else {
        throw Error.badSeedData
      }
      guard let space = UInt64.decode(fromLittleEndian: bytes, cursor: &cursor) else {
        throw Error.badDecodedData
      }
      let programIdData = try data.read(&cursor, offsetBy: 32)
      
      guard index == .allocateWithSeed else {
        throw Error.invalidSystemProgramIndex(index)
      }
      
      return try Solana.SystemProgram.AllocateWithSeedParams(
        accountPubkey: instruction.keys[0].pubkey,
        basePubkey: PublicKey(publicKey: baseData, index: 0, network: .solana),
        seed: seed,
        space: space,
        programId: PublicKey(publicKey: programIdData, index: 0, network: .solana)
      )
    }
    
    static func decodeAssign(instruction: TransactionInstruction) throws -> Solana.SystemProgram.AssignParams {
      guard instruction.programId == Solana.SystemProgram.programId else {
        throw Error.invalidInstruction(programId: instruction.programId)
      }
      guard instruction.keys.count >= 1 else {
        throw Error.invalidKeysCount(expected: 1, actual: instruction.keys.count)
      }
      guard let bytes = instruction.data?.byteArray else {
        throw Error.noDecodableData
      }
      
      let contexts: [any DecodeContextProtocol] = [
        // 4 bytes
        DecodeContext.littleEndian(size: 1, type: Solana.SystemProgram.Index.self),
        // 32 bytes
        DecodeContext.littleEndian(size: 32, type: Data.self),
      ]
      guard bytes.count >= 36,
            let decoded = bytes.decode(contexts: contexts),
            decoded.count == 2 else {
        throw Error.badData
      }
      
      guard let index = decoded[0] as? Solana.SystemProgram.Index,
            let programIdData = decoded[1] as? Data else {
        throw Error.badDecodedData
      }
      
      guard index == .assign else {
        throw Error.invalidSystemProgramIndex(index)
      }
      
      return try Solana.SystemProgram.AssignParams(
        accountPubkey: instruction.keys[0].pubkey,
        programId: PublicKey(publicKey: programIdData, index: 0, network: .solana)
      )
    }
    
    /**
     * Decode an assign with seed system instruction and retrieve the instruction params.
     */
    
    static func decodeAssignWithSeed(instruction: TransactionInstruction) throws -> Solana.SystemProgram.AssignWithSeedParams {
      guard instruction.programId == Solana.SystemProgram.programId else {
        throw Error.invalidInstruction(programId: instruction.programId)
      }
      guard instruction.keys.count >= 1 else {
        throw Error.invalidKeysCount(expected: 1, actual: instruction.keys.count)
      }
      guard let data = instruction.data else {
        throw Error.noDecodableData
      }
      let bytes = data.byteArray
      
      var cursor: Int = 0
      guard let index = Solana.SystemProgram.Index.decode(fromLittleEndian: bytes, cursor: &cursor) else {
        throw Error.badDecodedData
      }
      let baseData = try data.read(&cursor, offsetBy: 32)
      guard let seedRustStringBytes = UInt32.decode(fromLittleEndian: bytes, cursor: &cursor) else {
        throw Error.badDecodedData
      }
      
      // index - 4 bytes
      // basePubKey - 32 bytes
      // seedRustStringBytesCount - 4 bytes
      // seedRustString - value of seedRustStringBytesCount
      // programIdData - 32 bytes
      guard bytes.count >= 72 + Int(clamping: seedRustStringBytes) else {
        throw Error.badData
      }
      let seedData = try data.read(&cursor, offsetBy: Int(clamping: seedRustStringBytes))
      guard let seed = String(data: seedData, encoding: .utf8) else {
        throw Error.badSeedData
      }
      let programIdData = try data.read(&cursor, offsetBy: 32)
      
      guard index == .assignWithSeed else {
        throw Error.invalidSystemProgramIndex(index)
      }
      
      return try Solana.SystemProgram.AssignWithSeedParams(
        accountPubkey: instruction.keys[0].pubkey,
        basePubkey: PublicKey(publicKey: baseData, index: 0, network: .solana),
        seed: seed,
        programId: PublicKey(publicKey: programIdData, index: 0, network: .solana)
      )
    }
    
      /**
       * Decode a create account with seed system instruction and retrieve the instruction params.
       */
    
    static func decodeCreateAccountWithSeed(instruction: TransactionInstruction) throws -> Solana.SystemProgram.CreateAccountWithSeedParams {
      guard instruction.programId == Solana.SystemProgram.programId else {
        throw Error.invalidInstruction(programId: instruction.programId)
      }
      guard instruction.keys.count >= 2 else {
        throw Error.invalidKeysCount(expected: 2, actual: instruction.keys.count)
      }
      guard let data = instruction.data else {
        throw Error.noDecodableData
      }
      let bytes = data.byteArray
      
      var cursor: Int = 0
      guard let index = Solana.SystemProgram.Index.decode(fromLittleEndian: bytes, cursor: &cursor) else {
        throw Error.badDecodedData
      }
      let baseData = try data.read(&cursor, offsetBy: 32)
      guard let seedRustStringBytes = UInt32.decode(fromLittleEndian: bytes, cursor: &cursor) else {
        throw Error.badDecodedData
      }
      
      // index - 4 bytes
      // basePubKey - 32 bytes
      // seedRustStringBytesCount - 4 bytes
      // seedRustString - value of seedRustStringBytesCount
      // lamports - 8 bytes
      // space - 8 bytes
      // programIdData - 32 bytes
      guard bytes.count >= 88 + Int(clamping: seedRustStringBytes) else {
        throw Error.badData
      }
      let seedData = try data.read(&cursor, offsetBy: Int(clamping: seedRustStringBytes))
      guard let seed = String(data: seedData, encoding: .utf8) else {
        throw Error.badSeedData
      }
      guard let lamports = UInt64.decode(fromLittleEndian: bytes, cursor: &cursor),
            let space = UInt64.decode(fromLittleEndian: bytes, cursor: &cursor) else {
        throw Error.badDecodedData
      }
      let programIdData = try data.read(&cursor, offsetBy: 32)
      
      guard index == .createWithSeed else {
        throw Error.invalidSystemProgramIndex(index)
      }
      
      return try Solana.SystemProgram.CreateAccountWithSeedParams(
        fromPubkey: instruction.keys[0].pubkey,
        newAccountPubkey: instruction.keys[1].pubkey,
        basePubkey: PublicKey(publicKey: baseData, index: 0, network: .solana),
        seed: seed,
        lamports: lamports,
        space: space,
        programId: PublicKey(publicKey: programIdData, index: 0, network: .solana)
      )
    }
    

      /**
       * Decode a nonce initialize system instruction and retrieve the instruction params.
       */
    static func decodeNonceInitialize(instruction: TransactionInstruction) throws -> Solana.SystemProgram.InitializeNonceParams {
      guard instruction.programId == Solana.SystemProgram.programId else {
        throw Error.invalidInstruction(programId: instruction.programId)
      }
      guard instruction.keys.count >= 3 else {
        throw Error.invalidKeysCount(expected: 3, actual: instruction.keys.count)
      }
      guard let bytes = instruction.data?.byteArray else {
        throw Error.noDecodableData
      }
      
      let contexts: [any DecodeContextProtocol] = [
        // 4 bytes
        DecodeContext.littleEndian(size: 1, type: Solana.SystemProgram.Index.self),
        // 32 bytes
        DecodeContext.littleEndian(size: 32, type: Data.self),
      ]
      guard bytes.count >= 36,
            let decoded = bytes.decode(contexts: contexts),
            decoded.count == 2 else {
        throw Error.badData
      }
      
      guard let index = decoded[0] as? Solana.SystemProgram.Index,
            let authorizedData = decoded[1] as? Data else {
        throw Error.badDecodedData
      }
      
      guard index == .initializeNonceAccount else {
        throw Error.invalidSystemProgramIndex(index)
      }
      
      return try Solana.SystemProgram.InitializeNonceParams(
        noncePubkey: instruction.keys[0].pubkey,
        authorizedPubkey: PublicKey(publicKey: authorizedData, index: 0, network: .solana)
      )
    }


      /**
       * Decode a nonce advance system instruction and retrieve the instruction params.
       */
    static func decodeNonceAdvance(instruction: TransactionInstruction) throws -> Solana.SystemProgram.AdvanceNonceParams {
      guard instruction.programId == Solana.SystemProgram.programId else {
        throw Error.invalidInstruction(programId: instruction.programId)
      }
      guard instruction.keys.count >= 3 else {
        throw Error.invalidKeysCount(expected: 3, actual: instruction.keys.count)
      }
      guard let bytes = instruction.data?.byteArray else {
        throw Error.noDecodableData
      }
      
      let contexts: [any DecodeContextProtocol] = [
        // 4 bytes
        DecodeContext.littleEndian(size: 1, type: Solana.SystemProgram.Index.self),
      ]
      guard bytes.count >= 4,
            let decoded = bytes.decode(contexts: contexts),
            decoded.count == 1 else {
        throw Error.badData
      }
      
      guard let index = decoded[0] as? Solana.SystemProgram.Index else {
        throw Error.badDecodedData
      }
      
      guard index == .advanceNonceAccount else {
        throw Error.invalidSystemProgramIndex(index)
      }
      
      return Solana.SystemProgram.AdvanceNonceParams(
        noncePubkey: instruction.keys[0].pubkey,
        authorizedPubkey: instruction.keys[2].pubkey
      )
    }
    

      /**
       * Decode a nonce withdraw system instruction and retrieve the instruction params.
       */
    static func decodeNonceWithdraw(instruction: TransactionInstruction) throws -> Solana.SystemProgram.WithdrawNonceParams {
      guard instruction.programId == Solana.SystemProgram.programId else {
        throw Error.invalidInstruction(programId: instruction.programId)
      }
      guard instruction.keys.count >= 5 else {
        throw Error.invalidKeysCount(expected: 5, actual: instruction.keys.count)
      }
      guard let bytes = instruction.data?.byteArray else {
        throw Error.noDecodableData
      }
      
      let contexts: [any DecodeContextProtocol] = [
        // 4 bytes
        DecodeContext.littleEndian(size: 1, type: Solana.SystemProgram.Index.self),
        // 8 bytes
        DecodeContext.littleEndian(size: 1, type: UInt64.self),
      ]
      guard bytes.count >= 12,
            let decoded = bytes.decode(contexts: contexts),
            decoded.count == 2 else {
        throw Error.badData
      }
      
      guard let index = decoded[0] as? Solana.SystemProgram.Index,
            let lamports = decoded[1] as? UInt64 else {
        throw Error.badDecodedData
      }
      
      guard index == .withdrawNonceAccount else {
        throw Error.invalidSystemProgramIndex(index)
      }
      
      return Solana.SystemProgram.WithdrawNonceParams(
        noncePubkey: instruction.keys[0].pubkey,
        authorizedPubkey: instruction.keys[4].pubkey,
        toPubkey: instruction.keys[1].pubkey,
        lamports: lamports
      )
    }

    /**
       * Decode a nonce authorize system instruction and retrieve the instruction params.
       */
    
 static func decodeNonceAuthorize(instruction: TransactionInstruction) throws -> Solana.SystemProgram.AuthorizeNonceParams {
   guard instruction.programId == Solana.SystemProgram.programId else {
     throw Error.invalidInstruction(programId: instruction.programId)
   }
   guard instruction.keys.count >= 2 else {
     throw Error.invalidKeysCount(expected: 2, actual: instruction.keys.count)
   }
   guard let bytes = instruction.data?.byteArray else {
     throw Error.noDecodableData
   }
   
   let contexts: [any DecodeContextProtocol] = [
     // 4 bytes
     DecodeContext.littleEndian(size: 1, type: Solana.SystemProgram.Index.self),
     // 32 bytes
     DecodeContext.littleEndian(size: 32, type: Data.self),
   ]
   guard bytes.count >= 36,
         let decoded = bytes.decode(contexts: contexts),
         decoded.count == 2 else {
     throw Error.badData
   }
   
   guard let index = decoded[0] as? Solana.SystemProgram.Index,
         let newAuthorizedKeyData = decoded[1] as? Data else {
     throw Error.badDecodedData
   }
   
   guard index == .authorizeNonceAccount else {
     throw Error.invalidSystemProgramIndex(index)
   }
   
   return try Solana.SystemProgram.AuthorizeNonceParams(
    noncePubkey: instruction.keys[0].pubkey,
    authorizedPubkey: instruction.keys[1].pubkey,
    newAuthorizedPubkey: PublicKey(publicKey: newAuthorizedKeyData, index: 0, network: .solana)
   )
 }
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
