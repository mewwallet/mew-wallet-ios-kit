//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 10/10/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana.ComputeBudgetProgram {
  /// Request heap frame instruction params
  public struct RequestHeapFrameParams: Sendable, Equatable, Hashable {
    /// Requested transaction-wide program heap size in bytes. Must be multiple of 1024. Applies to each program, including CPIs.
    public let bytes: UInt32
    
    public init(bytes: UInt32) {
      self.bytes = bytes
    }
  }
}

extension Solana.ComputeBudgetProgram {
  /// Set compute unit limit instruction params
  public struct SetComputeUnitLimitParams: Sendable, Equatable, Hashable {
    /// Transaction-wide compute unit limit
    public let units: UInt32
    
    public init(units: UInt32) {
      self.units = units
    }
  }
}

extension Solana.ComputeBudgetProgram {
  /// Set compute unit price instruction params
  public struct SetComputeUnitPriceParams: Sendable, Equatable, Hashable {
    /// Transaction compute unit price used for prioritization fees
    public let microLamports: UInt64
    
    public init(microLamports: UInt64) {
      self.microLamports = microLamports
    }
  }
}
