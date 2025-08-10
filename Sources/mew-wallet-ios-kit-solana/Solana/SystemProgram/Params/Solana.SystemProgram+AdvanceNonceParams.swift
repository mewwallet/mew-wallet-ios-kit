//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/9/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana.SystemProgram {
  public struct AdvanceNonceParams: Sendable, Equatable, Hashable {
    /// Nonce account
    public let noncePubkey: PublicKey;
    /// Public key of the nonce authority
    public let authorizedPubkey: PublicKey;
    
    public init(noncePubkey: PublicKey, authorizedPubkey: PublicKey) {
      self.noncePubkey = noncePubkey
      self.authorizedPubkey = authorizedPubkey
    }
  }
}
