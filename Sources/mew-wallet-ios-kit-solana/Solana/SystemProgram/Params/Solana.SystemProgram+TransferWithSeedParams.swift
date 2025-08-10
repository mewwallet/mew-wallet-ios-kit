//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/9/25.
//

import Foundation

import Foundation
import mew_wallet_ios_kit
import BigInt

extension Solana.SystemProgram {
  public struct TransferWithSeedParams: Sendable, Equatable, Hashable {
    /// Account that will transfer lamports
    public let fromPubkey: PublicKey
    
    /// Base public key to use to derive the funding account address
    public let basePubkey: PublicKey
    
    /// Account that will receive transferred lamports
    public let toPubkey: PublicKey
    
    /// Amount of lamports to transfer
    public let lamports: UInt64
    
    /// Seed to use to derive the funding account address
    public let seed: String
    
    /// Program id to use to derive the funding account address
    public let programId: PublicKey
    
    public init(fromPubkey: PublicKey, basePubkey: PublicKey, toPubkey: PublicKey, lamports: UInt64, seed: String, programId: PublicKey) {
      self.fromPubkey = fromPubkey
      self.basePubkey = basePubkey
      self.toPubkey = toPubkey
      self.lamports = lamports
      self.seed = seed
      self.programId = programId
    }
  }
}
