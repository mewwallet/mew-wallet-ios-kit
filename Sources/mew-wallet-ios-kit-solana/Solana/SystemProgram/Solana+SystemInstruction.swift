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
  /// Low-level decoders for **System Program** instructions.
  ///
  /// Each decoder:
  /// - validates the `programId`,
  /// - validates expected account metas presence/order,
  /// - parses the binary payload into strongly-typed params,
  /// - verifies the instruction **index/opcode**.
  struct SystemInstruction {
    
    // MARK: - Errors
    
    /// Errors that may occur while decoding System Program instructions.
    public enum Error: Swift.Error, Sendable, Equatable {
      /// The instruction targets a different program id than `SystemProgram.programId`.
      case invalidInstruction(programId: PublicKey)
      /// The number of account metas on the instruction was not as expected.
      case invalidKeysCount(expected: Int, actual: Int)
      /// The instruction has no `data` payload to decode.
      case noDecodableData
      /// The raw payload length or layout is not valid for the instruction.
      case badData
      /// The payload could be read but did not produce expected typed values.
      case badDecodedData
      /// Seed payload could not be interpreted as UTF-8.
      case badSeedData
      /// The decoded opcode does not match the expected `SystemProgram.Index`.
      case invalidSystemProgramIndex(Solana.SystemProgram.Index)
    }
    
    // MARK: - CreateAccount
    
    /// Decode a **CreateAccount** system instruction into `CreateAccountParams`.
    ///
    /// Accounts:
    /// 0. `[signer, writable]` from (payer)
    /// 1. `[writable]`        new account
    ///
    /// Data layout (`solana-web3.js` parity):
    /// ```
    /// [0..3]   u32  index = SystemProgram.Index.create
    /// [4..11]  u64  lamports
    /// [12..19] u64  space
    /// [20..51] 32B  owner program id
    /// ```
    public static func decodeCreateAccount(instruction: TransactionInstruction) throws -> Solana.SystemProgram.CreateAccountParams {
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
        // 4 bytes (u32)
        DecodeContext.littleEndian(size: 1, type: Solana.SystemProgram.Index.self),
        // 8 bytes (lamports)
        DecodeContext.littleEndian(size: 1, type: UInt64.self),
        // 8 bytes (space)
        DecodeContext.littleEndian(size: 1, type: UInt64.self),
        // 32 bytes (owner)
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
    
    // MARK: - Transfer
    
    /// Decode a **Transfer** system instruction into `TransferParams`.
    ///
    /// Accounts:
    /// 0. `[signer, writable]` from
    /// 1. `[writable]`        to
    ///
    /// Data layout:
    /// ```
    /// [0..3]   u32  index = SystemProgram.Index.transfer
    /// [4..11]  u64  lamports
    /// ```
    public static func decodeTransfer(instruction: TransactionInstruction) throws -> Solana.SystemProgram.TransferParams {
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
        // 4 bytes (u32)
        DecodeContext.littleEndian(size: 1, type: Solana.SystemProgram.Index.self),
        // 8 bytes (lamports)
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
    
    // MARK: - TransferWithSeed
    
    /// Decode a **TransferWithSeed** system instruction into `TransferWithSeedParams`.
    ///
    /// Accounts:
    /// 0. `[writable]` from (derived address)
    /// 1. `[]`         base
    /// 2. `[writable]` to
    ///
    /// Data layout:
    /// ```
    /// [0..3]    u32   index = SystemProgram.Index.transferWithSeed
    /// [4..11]   u64   lamports
    /// [12..15]  u32   seed_len
    /// [16..X]   u8[]  seed (UTF-8, length = seed_len)
    /// [..+32]   32B   program_id (derivation)
    /// ```
    public static func decodeTransferWithSeed(instruction: TransactionInstruction) throws -> Solana.SystemProgram.TransferWithSeedParams {
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
    
    // MARK: - Allocate
    
    /// Decode an **Allocate** system instruction into `AllocateParams`.
    ///
    /// Accounts:
    /// 0. `[writable]` account to allocate
    ///
    /// Data layout:
    /// ```
    /// [0..3]   u32  index = SystemProgram.Index.allocate
    /// [4..11]  u64  space
    /// ```
    public static func decodeAllocate(instruction: TransactionInstruction) throws -> Solana.SystemProgram.AllocateParams {
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
        // 4 bytes (u32)
        DecodeContext.littleEndian(size: 1, type: Solana.SystemProgram.Index.self),
        // 8 bytes (space)
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
    
    // MARK: - AllocateWithSeed
    
    /// Decode an **AllocateWithSeed** system instruction into `AllocateWithSeedParams`.
    ///
    /// Accounts:
    /// 0. `[writable]` derived account (to allocate)
    ///
    /// Data layout:
    /// ```
    /// [0..3]    u32   index = SystemProgram.Index.allocateWithSeed
    /// [4..35]   32B   base_pubkey
    /// [36..39]  u32   seed_len
    /// [40..X]   u8[]  seed (UTF-8, length = seed_len)
    /// [..+8]    u64   space
    /// [..+32]   32B   program_id
    /// ```
    public static func decodeAllocateWithSeed(instruction: TransactionInstruction) throws -> Solana.SystemProgram.AllocateWithSeedParams {
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
    
    // MARK: - Assign
    
    /// Decode an **Assign** system instruction into `AssignParams`.
    ///
    /// Accounts:
    /// 0. `[writable]` account to assign
    ///
    /// Data layout:
    /// ```
    /// [0..3]   u32  index = SystemProgram.Index.assign
    /// [4..35]  32B  program_id
    /// ```
    public static func decodeAssign(instruction: TransactionInstruction) throws -> Solana.SystemProgram.AssignParams {
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
        // 4 bytes (u32)
        DecodeContext.littleEndian(size: 1, type: Solana.SystemProgram.Index.self),
        // 32 bytes (pubkey)
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
    
    // MARK: - AssignWithSeed
    
    /// Decode an **AssignWithSeed** system instruction into `AssignWithSeedParams`.
    ///
    /// Accounts:
    /// 0. `[writable]` derived account to reassign
    ///
    /// Data layout:
    /// ```
    /// [0..3]    u32   index = SystemProgram.Index.assignWithSeed
    /// [4..35]   32B   base_pubkey
    /// [36..39]  u32   seed_len
    /// [40..X]   u8[]  seed (UTF-8, length = seed_len)
    /// [..+32]   32B   program_id
    /// ```
    public static func decodeAssignWithSeed(instruction: TransactionInstruction) throws -> Solana.SystemProgram.AssignWithSeedParams {
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
    
    // MARK: - CreateAccountWithSeed
    
    /// Decode a **CreateAccountWithSeed** system instruction into `CreateAccountWithSeedParams`.
    ///
    /// Accounts:
    /// 0. `[signer, writable]` from (payer)
    /// 1. `[writable]`        new derived account
    ///
    /// Data layout:
    /// ```
    /// [0..3]     u32   index = SystemProgram.Index.createWithSeed
    /// [4..35]    32B   base_pubkey
    /// [36..39]   u32   seed_len
    /// [40..X]    u8[]  seed (UTF-8, length = seed_len)
    /// [..+8]     u64   lamports
    /// [..+8]     u64   space
    /// [..+32]    32B   owner program id
    /// ```
    public static func decodeCreateAccountWithSeed(instruction: TransactionInstruction) throws -> Solana.SystemProgram.CreateAccountWithSeedParams {
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
    
    // MARK: - Nonce Initialize
    
    /// Decode a **Nonce Initialize** system instruction into `InitializeNonceParams`.
    ///
    /// Accounts:
    /// 0. `[writable]` nonce account
    /// 1. `[]`         sysvar recent blockhashes (deprecated in modern runtimes; may be empty in web3.js)
    /// 2. `[]`         sysvar rent (also deprecated in modern runtimes)
    ///
    /// Data layout:
    /// ```
    /// [0..3]   u32  index = SystemProgram.Index.initializeNonceAccount
    /// [4..35]  32B  authorized_pubkey
    /// ```
    public static func decodeNonceInitialize(instruction: TransactionInstruction) throws -> Solana.SystemProgram.InitializeNonceParams {
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
        // 4 bytes (u32)
        DecodeContext.littleEndian(size: 1, type: Solana.SystemProgram.Index.self),
        // 32 bytes (pubkey)
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
    
    // MARK: - Nonce Advance
    
    /// Decode a **Nonce Advance** system instruction into `AdvanceNonceParams`.
    ///
    /// Accounts:
    /// 0. `[writable]` nonce account
    /// 1. `[]`         sysvar recent blockhashes
    /// 2. `[signer]`   nonce authority
    ///
    /// Data layout:
    /// ```
    /// [0..3]   u32  index = SystemProgram.Index.advanceNonceAccount
    /// ```
    public static func decodeNonceAdvance(instruction: TransactionInstruction) throws -> Solana.SystemProgram.AdvanceNonceParams {
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
        // 4 bytes (u32)
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
    
    // MARK: - Nonce Withdraw
    
    /// Decode a **Nonce Withdraw** system instruction into `WithdrawNonceParams`.
    ///
    /// Accounts:
    /// 0. `[writable]` nonce account
    /// 1. `[writable]` destination
    /// 2. `[]`         sysvar recent blockhashes
    /// 3. `[]`         sysvar rent
    /// 4. `[signer]`   nonce authority
    ///
    /// Data layout:
    /// ```
    /// [0..3]   u32  index = SystemProgram.Index.withdrawNonceAccount
    /// [4..11]  u64  lamports
    /// ```
    public static func decodeNonceWithdraw(instruction: TransactionInstruction) throws -> Solana.SystemProgram.WithdrawNonceParams {
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
        // 4 bytes (u32)
        DecodeContext.littleEndian(size: 1, type: Solana.SystemProgram.Index.self),
        // 8 bytes (lamports)
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
    
    // MARK: - Nonce Authorize
    
    /// Decode a **Nonce Authorize** system instruction into `AuthorizeNonceParams`.
    ///
    /// Accounts:
    /// 0. `[writable]` nonce account
    /// 1. `[signer]`   current authority
    ///
    /// Data layout:
    /// ```
    /// [0..3]   u32  index = SystemProgram.Index.authorizeNonceAccount
    /// [4..35]  32B  new_authority
    /// ```
    public static func decodeNonceAuthorize(instruction: TransactionInstruction) throws -> Solana.SystemProgram.AuthorizeNonceParams {
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
        // 4 bytes (u32)
        DecodeContext.littleEndian(size: 1, type: Solana.SystemProgram.Index.self),
        // 32 bytes (pubkey)
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
  }
}
