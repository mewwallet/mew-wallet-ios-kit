//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  public struct TransactionMessage: Sendable, Equatable {
    public let payerKey: PublicKey
    public let instructions: [TransactionInstruction]
    public let recentBlockhash: String
    
    public init(payerKey: PublicKey,
         instructions: [TransactionInstruction],
         recentBlockhash: String) {
      self.payerKey = payerKey
      self.instructions = instructions
      self.recentBlockhash = recentBlockhash
    }
    
    static func decompile(_ message: VersionedMessage/*, args: DecompileArgs? = nil*/) throws -> TransactionMessage {
      fatalError()
    }
    
    public func compileToV0Message(addressLookupTableAccounts: [AddressLookupTableAccount]? = nil) throws -> VersionedMessage {
      let message = try MessageV0(
        payerKey: payerKey,
        instructions: instructions,
        recentBlockhash: recentBlockhash,
        addressLookupTableAccounts: addressLookupTableAccounts
      )
      return .v0(message)
    }
  }
}
