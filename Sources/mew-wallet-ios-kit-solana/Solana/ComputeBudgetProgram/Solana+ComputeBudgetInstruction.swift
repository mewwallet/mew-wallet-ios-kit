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
  /// Utilities for decoding **Compute Budget Program** instructions into
  /// strongly-typed parameter structures.
  ///
  /// Supported variants:
  /// - `RequestHeapFrame`      (opcode = 1, payload: `u32` bytes)
  /// - `SetComputeUnitLimit`   (opcode = 2, payload: `u32` units)
  /// - `SetComputeUnitPrice`   (opcode = 3, payload: `u64` microLamports)
  public struct ComputeBudgetInstruction {
    /// Errors that may arise during decoding.
    public enum Error: Swift.Error, Sendable, Equatable {
      /// Instruction targets the wrong program id.
      case invalidInstruction(programId: PublicKey)
      /// Keys array length did not match the expected value for this instruction.
      case invalidKeysCount(expected: Int, actual: Int)
      /// No instruction `data` available for decoding.
      case noDecodableData
      /// The raw `data` buffer length or layout is not as expected.
      case badData
      /// The buffer could be parsed but did not produce expected types.
      case badDecodedData
      /// The opcode is not the expected variant for this decode function.
      case invalidComputeBudgetProgramIndex(Solana.ComputeBudgetProgram.Index)
    }
    
    // MARK: Decode: type only
    
    /// Decodes a Compute Budget instruction and returns only its **type** (opcode).
    ///
    /// - Parameter instruction: A `TransactionInstruction` whose `programId` must be `ComputeBudgetProgram.programId`.
    /// - Returns: The decoded `ComputeBudgetProgram.Index` (opcode).
    /// - Throws:
    ///   - `invalidInstruction` if `programId` is not `ComputeBudgetProgram.programId`
    ///   - `noDecodableData` if `data` is `nil`
    ///   - `badData` / `badDecodedData` on layout/type mismatch
    public static func decodeInstructionType(instruction: TransactionInstruction) throws(Solana.ComputeBudgetInstruction.Error) -> Solana.ComputeBudgetProgram.Index {
      guard instruction.programId == Solana.ComputeBudgetProgram.programId else {
        throw Error.invalidInstruction(programId: instruction.programId)
      }
      guard let bytes = instruction.data?.byteArray else {
        throw Error.noDecodableData
      }
      
      let contexts: [any DecodeContextProtocol] = [
        // 1 byte
        DecodeContext.littleEndian(size: 1, type: Solana.ComputeBudgetProgram.Index.self)
      ]
      guard bytes.count >= 1,
            let decoded = bytes.decode(contexts: contexts),
            decoded.count == 1 else {
        throw Error.badData
      }
      
      guard let index = decoded[0] as? Solana.ComputeBudgetProgram.Index else {
        throw Error.badDecodedData
      }
      return index
    }
    
    // MARK: Decode: RequestHeapFrame
    
    /// Decodes a **RequestHeapFrame** compute budget instruction into parameters.
    ///
    /// Layout:
    /// ```
    /// [0] u8   opcode = 1  (RequestHeapFrame)
    /// [1..4] u32 bytes     (heap size, must be multiple of 1024)
    /// ```
    /// - Parameter instruction: The instruction to decode.
    /// - Returns: `RequestHeapFrameParams`.
    /// - Throws: `invalidInstruction`, `noDecodableData`, `badData`, `badDecodedData`,
    ///   or `invalidComputeBudgetProgramIndex(.requestHeapFrame)` if opcode mismatches.
    public static func decodeRequestHeapFrame(instruction: TransactionInstruction) throws(Solana.ComputeBudgetInstruction.Error) -> Solana.ComputeBudgetProgram.RequestHeapFrameParams {
      guard instruction.programId == Solana.ComputeBudgetProgram.programId else {
        throw Error.invalidInstruction(programId: instruction.programId)
      }
      guard let bytes = instruction.data?.byteArray else {
        throw Error.noDecodableData
      }
      
      let contexts: [any DecodeContextProtocol] = [
        // 1 byte
        DecodeContext.littleEndian(size: 1, type: Solana.ComputeBudgetProgram.Index.self),
        // 4 bytes payload (u32)
        DecodeContext.littleEndian(size: 1, type: UInt32.self),
      ]
      guard bytes.count == 5,
            let decoded = bytes.decode(contexts: contexts),
            decoded.count == 2 else {
        throw Error.badData
      }
      
      guard let index = decoded[0] as? Solana.ComputeBudgetProgram.Index,
            let bytes = decoded[1] as? UInt32 else {
        throw Error.badDecodedData
      }
      
      guard index == .requestHeapFrame else {
        throw Error.invalidComputeBudgetProgramIndex(index)
      }
      
      return Solana.ComputeBudgetProgram.RequestHeapFrameParams(
        bytes: bytes
      )
    }
    
    // MARK: Decode: SetComputeUnitLimit
    
    /// Decodes a **SetComputeUnitLimit** compute budget instruction into parameters.
    ///
    /// Layout:
    /// ```
    /// [0] u8   opcode = 2  (SetComputeUnitLimit)
    /// [1..4] u32 units
    /// ```
    /// - Parameter instruction: The instruction to decode.
    /// - Returns: `SetComputeUnitLimitParams`.
    /// - Throws: `invalidInstruction`, `noDecodableData`, `badData`, `badDecodedData`,
    ///   or `invalidComputeBudgetProgramIndex(.setComputeUnitLimit)` if opcode mismatches.
    public static func decodeSetComputeUnitLimit(instruction: TransactionInstruction) throws(Solana.ComputeBudgetInstruction.Error) -> Solana.ComputeBudgetProgram.SetComputeUnitLimitParams {
      guard instruction.programId == Solana.ComputeBudgetProgram.programId else {
        throw Error.invalidInstruction(programId: instruction.programId)
      }
      guard let bytes = instruction.data?.byteArray else {
        throw Error.noDecodableData
      }
      
      let contexts: [any DecodeContextProtocol] = [
        // 1 byte
        DecodeContext.littleEndian(size: 1, type: Solana.ComputeBudgetProgram.Index.self),
        // 4 bytes payload (u32)
        DecodeContext.littleEndian(size: 1, type: UInt32.self),
      ]
      guard bytes.count == 5,
            let decoded = bytes.decode(contexts: contexts),
            decoded.count == 2 else {
        throw Error.badData
      }
      
      guard let index = decoded[0] as? Solana.ComputeBudgetProgram.Index,
            let units = decoded[1] as? UInt32 else {
        throw Error.badDecodedData
      }
      
      guard index == .setComputeUnitLimit else {
        throw Error.invalidComputeBudgetProgramIndex(index)
      }
      
      return Solana.ComputeBudgetProgram.SetComputeUnitLimitParams(
        units: units
      )
    }
    
    // MARK: Decode: SetComputeUnitPrice
    
    /// Decodes a **SetComputeUnitPrice** compute budget instruction into parameters.
    ///
    /// Layout:
    /// ```
    /// [0] u8      opcode = 3  (SetComputeUnitPrice)
    /// [1..8] u64  microLamports
    /// ```
    /// - Parameter instruction: The instruction to decode.
    /// - Returns: `SetComputeUnitPriceParams`.
    /// - Throws: `invalidInstruction`, `noDecodableData`, `badData`, `badDecodedData`,
    ///   or `invalidComputeBudgetProgramIndex(.setComputeUnitPrice)` if opcode mismatches.
    public static func decodeSetComputeUnitPrice(instruction: TransactionInstruction) throws(Solana.ComputeBudgetInstruction.Error) -> Solana.ComputeBudgetProgram.SetComputeUnitPriceParams {
      guard instruction.programId == Solana.ComputeBudgetProgram.programId else {
        throw Error.invalidInstruction(programId: instruction.programId)
      }
      guard let bytes = instruction.data?.byteArray else {
        throw Error.noDecodableData
      }
      
      let contexts: [any DecodeContextProtocol] = [
        // 1 byte
        DecodeContext.littleEndian(size: 1, type: Solana.ComputeBudgetProgram.Index.self),
        // 8 bytes payload (u64)
        DecodeContext.littleEndian(size: 1, type: UInt64.self),
      ]
      guard bytes.count == 9,
            let decoded = bytes.decode(contexts: contexts),
            decoded.count == 2 else {
        throw Error.badData
      }
      
      guard let index = decoded[0] as? Solana.ComputeBudgetProgram.Index,
            let microLamports = decoded[1] as? UInt64 else {
        throw Error.badDecodedData
      }
      
      guard index == .setComputeUnitPrice else {
        throw Error.invalidComputeBudgetProgramIndex(index)
      }
      
      return Solana.ComputeBudgetProgram.SetComputeUnitPriceParams(
        microLamports: microLamports
      )
    }
  }
}
