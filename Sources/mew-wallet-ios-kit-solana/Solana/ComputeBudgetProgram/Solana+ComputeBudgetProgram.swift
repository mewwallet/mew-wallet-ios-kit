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
  /// Factory for constructing instructions to the **Compute Budget** program.
  ///
  /// The Compute Budget program lets you:
  /// - request a larger per-program heap frame,
  /// - set a transaction-wide compute unit limit,
  /// - set a price (in micro-lamports per CU) for priority fees.
  ///
  /// All three instructions carry **no account metas** (`keys: []`) and only a small
  /// binary payload: `u8 opcode` followed by a little-endian integer.
  public struct ComputeBudgetProgram {
    /// Instruction discriminators (opcodes).
    ///
    /// Encoded as a single byte at the start of the instruction `data`.
    public enum Index: UInt8, EndianBytesEncodable, EndianBytesDecodable, Sendable {
      /// `RequestHeapFrame { bytes: u32 }`
      case requestHeapFrame         = 1
      /// `SetComputeUnitLimit { units: u32 }`
      case setComputeUnitLimit      = 2
      /// `SetComputeUnitPrice { microLamports: u64 }`
      case setComputeUnitPrice      = 3
    }
    
    /// Public key for the **Compute Budget** program.
    ///
    /// Mainnet address: `ComputeBudget111111111111111111111111111111`
    public static let programId: PublicKey = try! .init(base58: "ComputeBudget111111111111111111111111111111", network: .solana)
    
    /// Builds a `RequestHeapFrame` instruction.
    ///
    /// Layout:
    /// ```
    /// data = [ opcode: u8 = 1 ] || [ bytes: u32 LE ]
    /// ```
    /// - Parameter params: `bytes` must be a multiple of 1024.
    /// - Returns: `TransactionInstruction` with `keys: []`.
    public static func requestHeapFrame(params: Solana.ComputeBudgetProgram.RequestHeapFrameParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [],
        programId: self.programId,
        data: Index.requestHeapFrame, params.bytes
      )
    }
    
    /// Builds a `SetComputeUnitLimit` instruction.
    ///
    /// Layout:
    /// ```
    /// data = [ opcode: u8 = 2 ] || [ units: u32 LE ]
    /// ```
    /// - Parameter params: Desired compute unit limit for the transaction.
    /// - Returns: `TransactionInstruction` with `keys: []`.
    public static func setComputeUnitLimit(params: Solana.ComputeBudgetProgram.SetComputeUnitLimitParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [],
        programId: self.programId,
        data: Index.setComputeUnitLimit, params.units
      )
    }
    
    /// Builds a `SetComputeUnitPrice` instruction.
    ///
    /// Layout:
    /// ```
    /// data = [ opcode: u8 = 3 ] || [ microLamports: u64 LE ]
    /// ```
    /// - Parameter params: Price per compute unit (in **micro-lamports**).
    /// - Returns: `TransactionInstruction` with `keys: []`.
    public static func setComputeUnitPrice(params: Solana.ComputeBudgetProgram.SetComputeUnitPriceParams) -> TransactionInstruction {
      return TransactionInstruction(
        keys: [],
        programId: self.programId,
        data: Index.setComputeUnitPrice, params.microLamports
      )
    }
  }
}
