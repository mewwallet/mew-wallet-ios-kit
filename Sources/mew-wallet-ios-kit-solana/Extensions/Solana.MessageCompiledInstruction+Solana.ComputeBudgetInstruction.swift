//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 10/14/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana.MessageCompiledInstruction {
  public enum Error: Swift.Error {
    case incompatibleInstruction
  }
  
  public func setComputeUnitLimitInstruction(keys: [PublicKey]) throws -> Solana.ComputeBudgetProgram.SetComputeUnitLimitParams {
    guard self.accountKeyIndexes.isEmpty,
          self.programIdIndex < keys.count else { throw Error.incompatibleInstruction }
    let instruction = Solana.TransactionInstruction(keys: [], programId: keys[Int(self.programIdIndex)], data: self.data)
    return try Solana.ComputeBudgetInstruction.decodeSetComputeUnitLimit(instruction: instruction)
  }
  
  public func setComputeUnitPriceInstruction(keys: [PublicKey]) throws -> Solana.ComputeBudgetProgram.SetComputeUnitPriceParams {
    guard self.accountKeyIndexes.isEmpty,
          self.programIdIndex < keys.count else { throw Error.incompatibleInstruction }
    let instruction = Solana.TransactionInstruction(keys: [], programId: keys[Int(self.programIdIndex)], data: self.data)
    return try Solana.ComputeBudgetInstruction.decodeSetComputeUnitPrice(instruction: instruction)
  }
}
