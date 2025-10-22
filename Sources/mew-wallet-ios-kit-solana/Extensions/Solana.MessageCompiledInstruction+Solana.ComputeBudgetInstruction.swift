//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 10/14/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana.MessageCompiledInstruction {
  /// Errors that may occur while converting a compiled compute-budget instruction
  /// into high-level parameter structs.
  public enum Error: Swift.Error {
    /// The compiled instruction does not match the expected shape for a compute-budget instruction
    /// (e.g., non-empty account list, out-of-range program index, or wrong program id).
    case incompatibleInstruction
  }
  
  /// Decodes a **Compute Budget: SetComputeUnitLimit** instruction from a compiled instruction.
  ///
  /// This helper reconstructs a `TransactionInstruction` using:
  /// - `programId = keys[programIdIndex]`
  /// - `keys = []` (Compute Budget instructions do not carry account metas)
  /// - `data = self.data` (raw instruction payload)
  ///
  /// and forwards it to `ComputeBudgetInstruction.decodeSetComputeUnitLimit`.
  ///
  /// - Parameters:
  ///   - keys: The `Message.accountKeys` array corresponding to this compiled instruction.
  /// - Returns: Decoded `SetComputeUnitLimitParams`.
  /// - Throws: `Error.incompatibleInstruction` if:
  ///   - `accountKeyIndexes` is not empty,
  ///   - or `programIdIndex` is out of bounds,
  ///   - or (optionally) the program id does not equal `ComputeBudgetProgram.programId`.
  public func setComputeUnitLimitInstruction(keys: [PublicKey]) throws -> Solana.ComputeBudgetProgram.SetComputeUnitLimitParams {
    guard self.accountKeyIndexes.isEmpty,
          self.programIdIndex < keys.count else { throw Error.incompatibleInstruction }
    let instruction = Solana.TransactionInstruction(keys: [], programId: keys[Int(self.programIdIndex)], data: self.data)
    return try Solana.ComputeBudgetInstruction.decodeSetComputeUnitLimit(instruction: instruction)
  }
  
  /// Decodes a **Compute Budget: SetComputeUnitPrice** instruction from a compiled instruction.
  ///
  /// This helper reconstructs a `TransactionInstruction` using:
  /// - `programId = keys[programIdIndex]`
  /// - `keys = []` (Compute Budget instructions do not carry account metas)
  /// - `data = self.data` (raw instruction payload)
  ///
  /// and forwards it to `ComputeBudgetInstruction.decodeSetComputeUnitPrice`.
  ///
  /// - Parameters:
  ///   - keys: The `Message.accountKeys` array corresponding to this compiled instruction.
  /// - Returns: Decoded `SetComputeUnitPriceParams`.
  /// - Throws: `Error.incompatibleInstruction` if:
  ///   - `accountKeyIndexes` is not empty,
  ///   - or `programIdIndex` is out of bounds,
  ///   - or (optionally) the program id does not equal `ComputeBudgetProgram.programId`.
  public func setComputeUnitPriceInstruction(keys: [PublicKey]) throws -> Solana.ComputeBudgetProgram.SetComputeUnitPriceParams {
    guard self.accountKeyIndexes.isEmpty,
          self.programIdIndex < keys.count else { throw Error.incompatibleInstruction }
    let instruction = Solana.TransactionInstruction(keys: [], programId: keys[Int(self.programIdIndex)], data: self.data)
    return try Solana.ComputeBudgetInstruction.decodeSetComputeUnitPrice(instruction: instruction)
  }
}
