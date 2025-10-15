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
  public struct ComputeBudgetInstruction {
    public enum Error: Swift.Error, Sendable, Equatable {
      case invalidInstruction(programId: PublicKey)
      case invalidKeysCount(expected: Int, actual: Int)
      case noDecodableData
      case badData
      case badDecodedData
      case badSeedData
      case invalidComputeBudgetProgramIndex(Solana.ComputeBudgetProgram.Index)
    }
    
    /**
     * Decode a compute budget instruction and retrieve the instruction type.
     */
    public static func decodeInstructionType(instruction: TransactionInstruction) throws -> Solana.ComputeBudgetProgram.Index {
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
    
    /**
     * Decode request heap frame compute budget instruction and retrieve the instruction params.
     */
    public static func decodeRequestHeapFrame(instruction: TransactionInstruction) throws -> Solana.ComputeBudgetProgram.RequestHeapFrameParams {
      guard instruction.programId == Solana.ComputeBudgetProgram.programId else {
        throw Error.invalidInstruction(programId: instruction.programId)
      }
      guard let bytes = instruction.data?.byteArray else {
        throw Error.noDecodableData
      }
      
      let contexts: [any DecodeContextProtocol] = [
        // 1 byte
        DecodeContext.littleEndian(size: 1, type: Solana.ComputeBudgetProgram.Index.self),
        // 4 bytes
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
    
        /**
         * Decode set compute unit limit compute budget instruction and retrieve the instruction params.
         */
    public static func decodeSetComputeUnitLimit(instruction: TransactionInstruction) throws -> Solana.ComputeBudgetProgram.SetComputeUnitLimitParams {
      guard instruction.programId == Solana.ComputeBudgetProgram.programId else {
        throw Error.invalidInstruction(programId: instruction.programId)
      }
      guard let bytes = instruction.data?.byteArray else {
        throw Error.noDecodableData
      }
      
      let contexts: [any DecodeContextProtocol] = [
        // 1 byte
        DecodeContext.littleEndian(size: 1, type: Solana.ComputeBudgetProgram.Index.self),
        // 4 bytes
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
    
        /**
         * Decode set compute unit price compute budget instruction and retrieve the instruction params.
         */
    public static func decodeSetComputeUnitPrice(instruction: TransactionInstruction) throws -> Solana.ComputeBudgetProgram.SetComputeUnitPriceParams {
      guard instruction.programId == Solana.ComputeBudgetProgram.programId else {
        throw Error.invalidInstruction(programId: instruction.programId)
      }
      guard let bytes = instruction.data?.byteArray else {
        throw Error.noDecodableData
      }
      
      let contexts: [any DecodeContextProtocol] = [
        // 1 byte
        DecodeContext.littleEndian(size: 1, type: Solana.ComputeBudgetProgram.Index.self),
        // 8 bytes
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
