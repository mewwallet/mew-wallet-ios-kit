//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  /// List of instructions to be processed atomically
  public struct Message: Equatable, Sendable {
    package let header: MessageHeader
    
    package let accountKeys: [PublicKey]
    
    let recentBlockhash: String
    
    let instructions: [CompiledInstruction]
    
  }
}

extension Solana.Message: Encodable {
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.unkeyedContainer()
    
    // Header
    try container.encode(header)
    
    // Account keys
    try container.encode(accountKeys)
    
    // Recent blockhash
    let blockhash = try recentBlockhash.decodeBase58(.solana)
    try container.encode(blockhash)
    
    // Instructions
    try container.encode(instructions)
  }
}
