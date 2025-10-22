//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation

extension Solana {
  /// Represents a **compiled transaction instruction** in Solana’s message format.
  ///
  /// A compiled instruction references accounts by index rather than full public keys,
  /// providing a compact, efficient encoding for on-chain execution.
  ///
  /// This type is used inside `Message` or `MessageV0` structures once all account
  /// references have been collected and deduplicated.
  ///
  /// ### Structure
  /// - `programIdIndex`: Index into the message’s account key array pointing to
  ///   the program account that executes this instruction.
  /// - `accounts`: Indices into the message’s account key array specifying the
  ///   ordered list of accounts to be passed to the program.
  /// - `data`: Raw instruction data bytes (program-specific payload).
  ///
  /// ### Example
  /// ```swift
  /// let instruction = Solana.CompiledInstruction(
  ///   programIdIndex: 2,
  ///   accounts: [0, 1],
  ///   data: [1, 0, 0, 0]
  /// )
  /// ```
  ///
  /// This represents an instruction where:
  /// - The program is at index `2` in the transaction’s key list.
  /// - Two accounts (`0` and `1`) are passed as inputs.
  /// - Instruction data contains the program’s binary payload.
  public struct CompiledInstruction: Equatable, Sendable {
    /// Index into the transaction’s account key array
    /// identifying the program that executes this instruction.
    public let programIdIndex: UInt8
    
    /// Ordered indices into the transaction’s account key array
    /// for the accounts passed to the program.
    public let accounts: [UInt8]
    
    /// Raw instruction data bytes.
    ///
    /// > Note: This field contains **binary data** (not base58).
    ///   Base58 is only used for human-readable representations.
    public let data: Data
    
    /// Initializes a new compiled instruction.
    ///
    /// - Parameters:
    ///   - programIdIndex: Index into the message’s key array for the program account.
    ///   - accounts: Ordered list of account indices used by the instruction.
    ///   - data: Raw instruction data bytes.
    public init(programIdIndex: UInt8, accounts: [UInt8], data: Data) {
      self.programIdIndex = programIdIndex
      self.accounts = accounts
      self.data = data
    }
  }
}

extension Solana.CompiledInstruction: Codable {
  /// Decodes a compiled instruction from Solana’s binary message format.
  ///
  /// Expected format:
  /// ```
  /// [programIdIndex] [accounts length + accounts[]] [data length + data[]]
  /// ```
  public init(from decoder: any Decoder) throws {
    var container = try decoder.unkeyedContainer()
    
    self.programIdIndex = try container.decode(UInt8.self)
    
    self.accounts = try container.decode([UInt8].self)
    
    self.data = try container.decode(Data.self)
  }
  
  /// Encodes this compiled instruction into Solana’s binary message format.
  ///
  /// The encoder includes the data length explicitly before the raw data bytes.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.unkeyedContainer()
    
    try container.encode(programIdIndex)
    
    try container.encode(accounts)
    
    // Size should be encoded manually
    try container.encode(data.count)
    try container.encode(data)
  }
}
