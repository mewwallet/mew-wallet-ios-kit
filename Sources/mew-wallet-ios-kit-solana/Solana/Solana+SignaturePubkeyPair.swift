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
    package var publicKey: PublicKey
    
    public init(signature: Data?, publicKey: PublicKey) {
      self.signature = signature
      self.publicKey = publicKey
    }
  }
}

extension Solana.SignaturePubkeyPair: Codable {
  public init(from decoder: any Decoder) throws {
    fatalError()
  }
  
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    if let signature {
      try container.encode(signature)
    } else {
      try container.encode(Data(repeating: 0x00, count: 64))
    }
  }
}
