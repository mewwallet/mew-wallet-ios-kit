//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 10/10/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana.ComputeBudgetProgram {
  /// Parameters for the **RequestHeapFrame** instruction.
  ///
  /// This instruction requests an increased per-program heap size for all
  /// invoked programs within the transaction. It must be issued **before**
  /// any other instructions in the transaction to take effect.
  ///
  /// ### Notes
  /// - The requested size must be a multiple of 1024 bytes.
  /// - Default heap size is 32 KiB (32768 bytes).
  /// - Maximum is cluster-dependent (often 256 KiB or 512 KiB).
  ///
  /// ### Example
  /// ```swift
  /// let params = Solana.ComputeBudgetProgram.RequestHeapFrameParams(bytes: 128 * 1024)
  /// let ix = try Solana.ComputeBudgetProgram.requestHeapFrame(params: params)
  /// ```
  public struct RequestHeapFrameParams: Sendable, Equatable, Hashable {
    /// Requested transaction-wide program heap size in bytes.
    /// Must be a multiple of 1024.
    public let bytes: UInt32
    
    /// Creates a new request for a heap frame of the specified size.
    ///
    /// - Parameter bytes: Desired heap size (in bytes).
    public init(bytes: UInt32) {
      self.bytes = bytes
    }
  }
}

extension Solana.ComputeBudgetProgram {
  /// Parameters for the **SetComputeUnitLimit** instruction.
  ///
  /// Sets a transaction-wide upper bound on the number of compute units
  /// available for all instructions in the transaction.
  ///
  /// ### Notes
  /// - Default limit: 200,000 compute units.
  /// - Maximum allowed: 1,400,000 CU (cluster-dependent).
  ///
  /// ### Example
  /// ```swift
  /// let params = Solana.ComputeBudgetProgram.SetComputeUnitLimitParams(units: 1_000_000)
  /// let ix = try Solana.ComputeBudgetProgram.setComputeUnitLimit(params: params)
  /// ```
  public struct SetComputeUnitLimitParams: Sendable, Equatable, Hashable {
    /// Transaction-wide compute unit limit
    public let units: UInt32
    
    /// Creates a new compute unit limit configuration.
    ///
    /// - Parameter units: Maximum compute units for the transaction.
    public init(units: UInt32) {
      self.units = units
    }
  }
}

extension Solana.ComputeBudgetProgram {
  /// Parameters for the **SetComputeUnitPrice** instruction.
  ///
  /// Specifies the price (in micro-lamports per compute unit) to prioritize
  /// the transaction in fee markets. Higher prices give higher priority.
  ///
  /// ### Notes
  /// - 1 micro-lamport = 1 × 10⁻⁶ lamports per compute unit.
  /// - Used by block producers to determine priority fees.
  ///
  /// ### Example
  /// ```swift
  /// let params = Solana.ComputeBudgetProgram.SetComputeUnitPriceParams(microLamports: 5000)
  /// let ix = try Solana.ComputeBudgetProgram.setComputeUnitPrice(params: params)
  /// ```
  public struct SetComputeUnitPriceParams: Sendable, Equatable, Hashable {
    /// Transaction compute unit price used for prioritization fees
    public let microLamports: UInt64
    
    /// Creates a new compute unit price configuration.
    ///
    /// - Parameter microLamports: Price per compute unit (in micro-lamports).
    public init(microLamports: UInt64) {
      self.microLamports = microLamports
    }
  }
}
