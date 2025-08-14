//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/10/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana.StakeProgram {
  /**
   * Delegate stake instruction params
   */
  public struct DelegateStakeParams: Sendable, Equatable, Hashable {
    public let stakePubkey: PublicKey
    
    public let authorizedPubkey: PublicKey
    
    public let votePubkey: PublicKey
    
    public init(stakePubkey: PublicKey, authorizedPubkey: PublicKey, votePubkey: PublicKey) {
      self.stakePubkey = stakePubkey
      self.authorizedPubkey = authorizedPubkey
      self.votePubkey = votePubkey
    }
  }
}
