//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation

extension Solana {
  public struct CompiledInstruction: Equatable, Sendable {
    /// Index into the transaction keys array indicating the program account that executes this instruction
    let programIdIndex: UInt8
    
    /// Ordered indices into the transaction keys array indicating which accounts to pass to the program
    let accounts: [UInt8]
    
    /// The program input data encoded as base 58
    let data: Data
  }
}

extension Solana.CompiledInstruction: Encodable {
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.unkeyedContainer()
    
    try container.encode(programIdIndex)
    
    try container.encode(accounts)
    
    try container.encode(data.count)
    try container.encode(data)
  }
}
