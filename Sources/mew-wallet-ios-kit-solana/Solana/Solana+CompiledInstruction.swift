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
    public let programIdIndex: UInt8
    
    /// Ordered indices into the transaction keys array indicating which accounts to pass to the program
    public let accounts: [UInt8]
    
    /// The program input data encoded as base 58
    public let data: Data
    
    public init(programIdIndex: UInt8, accounts: [UInt8], data: Data) {
      self.programIdIndex = programIdIndex
      self.accounts = accounts
      self.data = data
    }
  }
}

extension Solana.CompiledInstruction: Codable {
  public init(from decoder: any Decoder) throws {
    var container = try decoder.unkeyedContainer()
    
    self.programIdIndex = try container.decode(UInt8.self)
    
    self.accounts = try container.decode([UInt8].self)
    
    self.data = try container.decode(Data.self)
  }
  
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.unkeyedContainer()
    
    try container.encode(programIdIndex)
    
    try container.encode(accounts)
    
    // Size should be encoded manually
    try container.encode(data.count)
    try container.encode(data)
  }
}
