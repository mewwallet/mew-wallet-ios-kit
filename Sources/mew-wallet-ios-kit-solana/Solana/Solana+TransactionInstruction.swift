//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  public struct TransactionInstruction: Equatable, Sendable {
    /// Public keys to include in this transaction
    /// Boolean represents whether this pubkey needs to sign the transaction
    let keys: [AccountMeta]
    
    /// Program Id to execute
    let programId: PublicKey?
    
    /// Program input
    let data: Data?
    
    public init(keys: [AccountMeta], programId: PublicKey?, data: Data? = nil) {
      self.keys = keys
      self.programId = programId
      self.data = data
    }
  }
}
