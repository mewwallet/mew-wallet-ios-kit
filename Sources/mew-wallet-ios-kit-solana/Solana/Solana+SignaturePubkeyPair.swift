//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  ///  Pair of signature and corresponding public key
  public struct SignaturePubkeyPair: Equatable, Sendable {
    package var signature: Data?
    package let publicKey: PublicKey
    
    public init(signature: Data?, publicKey: PublicKey) {
      self.signature = signature
      self.publicKey = publicKey
    }
  }
}
