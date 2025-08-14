//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  /**
   * An address table lookup used to load additional accounts
   */
  public struct MessageAddressTableLookup: Equatable, Sendable {
    let accountKey: PublicKey
    
    let writableIndexes: [UInt8]
    
    let readonlyIndexes: [UInt8]
  }
}

extension Solana.MessageAddressTableLookup: Codable {
  public init(from decoder: any Decoder) throws {
    var container = try decoder.unkeyedContainer()
    
    self.accountKey = try container.decode(PublicKey.self)
    self.writableIndexes = try container.decode([UInt8].self)
    self.readonlyIndexes = try container.decode([UInt8].self)
  }
  
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.unkeyedContainer()
    
    try container.encode(accountKey)
    try container.encode(writableIndexes)
    try container.encode(readonlyIndexes)
  }
}
