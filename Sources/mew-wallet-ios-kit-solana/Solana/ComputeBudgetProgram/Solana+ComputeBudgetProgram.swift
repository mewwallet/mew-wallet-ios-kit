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
  /// Factory class for transaction instructions to interact with the Compute Budget program
  public struct ComputeBudgetProgram {
    public enum Index: UInt8, EndianBytesEncodable, EndianBytesDecodable, Sendable {
      case requestHeapFrame         = 1
      case setComputeUnitLimit      = 2
      case setComputeUnitPrice      = 3
    }
    
    /// Public key that identifies the Compute Budget program
    public static let programId: PublicKey = try! .init(base58: "ComputeBudget111111111111111111111111111111", network: .solana)
    
    public static func requestHeapFrame(params: Solana.ComputeBudgetProgram.RequestHeapFrameParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [],
        programId: self.programId,
        data: Index.requestHeapFrame, params.bytes
      )
    }
    
    public static func setComputeUnitLimit(params: Solana.ComputeBudgetProgram.SetComputeUnitLimitParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [],
        programId: self.programId,
        data: Index.setComputeUnitLimit, params.units
      )
    }
    
    public static func setComputeUnitPrice(params: Solana.ComputeBudgetProgram.SetComputeUnitPriceParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [],
        programId: self.programId,
        data: Index.setComputeUnitPrice, params.microLamports
      )
    }
  }
}
