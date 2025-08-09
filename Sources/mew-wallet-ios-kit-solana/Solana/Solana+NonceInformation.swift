//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation

extension Solana {
  /// Nonce information to be used to build an offline Transaction.
  public struct NonceInformation: Equatable, Sendable {
    /// The current blockhash stored in the nonce
    let nonce: String
    
    /// AdvanceNonceAccount Instruction
    let nonceInstruction: TransactionInstruction
  }
}
