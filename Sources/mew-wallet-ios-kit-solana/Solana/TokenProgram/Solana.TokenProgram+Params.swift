//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 10/10/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana.TokenProgram {
  public struct TransferParams: Sendable, Equatable, Hashable {
    public let source: PublicKey
    public let destination: PublicKey
    public let owner: PublicKey
    public let amount: UInt64
    public let multiSigners: [PublicKey]
    public let programId: PublicKey
    
    public init(source: PublicKey, destination: PublicKey, owner: PublicKey, amount: UInt64, multiSigners: [PublicKey] = [], programId: PublicKey = Solana.TokenProgram.programId) {
      self.source = source
      self.destination = destination
      self.owner = owner
      self.amount = amount
      self.multiSigners = multiSigners
      self.programId = programId
    }
  }
}
