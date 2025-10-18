//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation

extension Solana {
  /// A single compiled instruction as carried inside a Solana message.
  ///
  /// The instruction references accounts by **index** into the message’s
  /// account key array (static keys plus, for v0, any ALT-derived keys).
  public struct MessageCompiledInstruction: Equatable, Sendable {
    /// Index into the message’s account keys that identifies the **program**
    /// which will execute this instruction.
    public let programIdIndex: UInt8
    
    /// Ordered indices into the message’s account keys for all accounts
    /// passed to the program (signers/writable/read-only as required).
    public let accountKeyIndexes: [UInt8]
    
    /// Opaque program input bytes (already assembled/encoded for the target program).
    public let data: Data
    
    /// Creates a compiled instruction.
    ///
    /// - Parameters:
    ///   - programIdIndex: Index of the program in the message’s account key list.
    ///   - accountKeyIndexes: Indices of all accounts the program needs.
    ///   - data: Program input bytes (nil becomes empty).
    public init(programIdIndex: UInt8, accountKeyIndexes: [UInt8], data: Data?) {
      self.programIdIndex = programIdIndex
      self.accountKeyIndexes = accountKeyIndexes
      self.data = data ?? Data()
    }
  }
}

extension Solana.MessageCompiledInstruction: Codable {
  /// Decodes using the message’s shortvec-aware decoding:
  /// ```
  /// programIdIndex: u8
  /// accountKeyIndexes: shortvec<u8>  (length + raw u8 bytes)
  /// data: shortvec<u8>               (length + raw bytes)
  /// ```
  public init(from decoder: any Decoder) throws {
    var container = try decoder.unkeyedContainer()
    
    self.programIdIndex = try container.decode(UInt8.self)
    
    self.accountKeyIndexes = try container.decode([UInt8].self)
    
    self.data = try container.decode(Data.self)
  }
  
  /// Encodes with the same layout expected by the Solana wire format:
  /// - `programIdIndex` as a single u8
  /// - `accountKeyIndexes` as shortvec length + **raw** u8 bytes
  /// - `data` as shortvec length + raw bytes
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.unkeyedContainer()
    
    try container.encode(programIdIndex)
    
    // accountKeyIndexes: shortvec(len) + raw bytes
#warning("hm?")
    try container.encode(accountKeyIndexes.count)
    try container.encode(Data(accountKeyIndexes))
    
    // data: shortvec(len) + raw bytes
    try container.encode(data.count)
    try container.encode(data)
  }
}
