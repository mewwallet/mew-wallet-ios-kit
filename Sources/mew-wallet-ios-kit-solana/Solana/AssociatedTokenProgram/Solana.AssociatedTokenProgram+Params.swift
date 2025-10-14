//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 10/10/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana.AssociatedTokenProgram {
  /// Create associated token account params
  public struct CreateAssociatedTokenAccountParams: Sendable, Equatable, Hashable {
    public let payer: PublicKey
    public let owner: PublicKey
    public let mint: PublicKey
    public let programId: PublicKey
    
    public init(payer: PublicKey, owner: PublicKey, mint: PublicKey, programId: PublicKey) {
      self.payer = payer
      self.owner = owner
      self.mint = mint
      self.programId = programId
    }
  }
}
