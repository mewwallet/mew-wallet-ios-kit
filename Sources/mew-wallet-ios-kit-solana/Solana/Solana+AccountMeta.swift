//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  public struct AccountMeta: Equatable, Sendable {
    /// An account's public key
    let pubkey: PublicKey
    
    /// True if an instruction requires a transaction signature matching `pubkey`
    var isSigner: Bool
    
    /// True if the `pubkey` can be loaded as a read-write account.
    var isWritable: Bool
    
    public init(pubkey: PublicKey, isSigner: Bool, isWritable: Bool) {
      self.pubkey = pubkey
      self.isSigner = isSigner
      self.isWritable = isWritable
    }
  }
}
