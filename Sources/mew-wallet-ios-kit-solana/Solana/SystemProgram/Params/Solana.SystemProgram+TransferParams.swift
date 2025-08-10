//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/9/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana.SystemProgram {
  public struct TransferParams: Sendable, Equatable, Hashable {
    /// Account that will transfer lamports
    public let fromPubkey: PublicKey
    
    /// Account that will receive transferred lamports
    public let toPubkey: PublicKey
    
    /// Amount of lamports to transfer
    public let lamports: UInt64
    
    public init(fromPubkey: PublicKey, toPubkey: PublicKey, lamports: UInt64) {
      self.fromPubkey = fromPubkey
      self.toPubkey = toPubkey
      self.lamports = lamports
    }
  }
}
