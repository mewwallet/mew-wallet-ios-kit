//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  /// Nonce information to be used to build an offline Transaction.
  public struct NonceInformation: Equatable, Sendable {
    public enum Error: Swift.Error {
      case badPublicKey
    }
    
    /// The current blockhash stored in the nonce
    let nonce: String
    
    /// AdvanceNonceAccount Instruction
    let nonceInstruction: TransactionInstruction
    
    public init(nonce: String, nonceInstruction: TransactionInstruction) {
      self.nonce = nonce
      self.nonceInstruction = nonceInstruction
    }
    
    public init(nonce: PublicKey, nonceInstruction: TransactionInstruction) throws {
      guard let nonce = nonce.address()?.address else {
        throw Error.badPublicKey
      }
      self.init(nonce: nonce, nonceInstruction: nonceInstruction)
    }
  }
}
