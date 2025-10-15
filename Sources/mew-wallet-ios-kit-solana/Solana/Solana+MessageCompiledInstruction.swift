//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation

extension Solana {
  public struct MessageCompiledInstruction: Equatable, Sendable {
    /// Index into the transaction keys array indicating the program account that executes this instruction
    public let programIdIndex: UInt8
    
    /// Ordered indices into the transaction keys array indicating which accounts to pass to the program
    public let accountKeyIndexes: [UInt8]
    
    /// The program input data
    public let data: Data
    
    public init(programIdIndex: UInt8, accountKeyIndexes: [UInt8], data: Data?) {
      self.programIdIndex = programIdIndex
      self.accountKeyIndexes = accountKeyIndexes
      self.data = data ?? Data()
    }
  }
}

extension Solana.MessageCompiledInstruction: Codable {
  public init(from decoder: any Decoder) throws {
    var container = try decoder.unkeyedContainer()
    
    self.programIdIndex = try container.decode(UInt8.self)
    
    self.accountKeyIndexes = try container.decode([UInt8].self)
    
    self.data = try container.decode(Data.self)
  }
  
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.unkeyedContainer()
    
    try container.encode(programIdIndex)
    
    try container.encode(accountKeyIndexes)
    
    // Size should be encoded manually
    try container.encode(data.count)
    try container.encode(data)
  }
}
