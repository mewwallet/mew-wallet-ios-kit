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
    public let header: MessageHeader
    
    public let accountKeys: [PublicKey]
    public var staticAccountKeys: [PublicKey] { accountKeys }
    
    public let recentBlockhash: String
    
    public let instructions: [CompiledInstruction]
    var compiledInstructions: [MessageCompiledInstruction] {
      self.instructions.map {
        .init(
          programIdIndex: $0.programIdIndex,
          accountKeyIndexes: $0.accounts,
          data: $0.data
        )
      }
    }
    
    public let version: Solana.Version = .legacy
    
    public var addressTableLookups: [MessageAddressTableLookup] { [] }
    
    public init(header: MessageHeader, accountKeys: [PublicKey], recentBlockhash: String, instructions: [CompiledInstruction]) {
      self.header = header
      self.accountKeys = accountKeys
      self.recentBlockhash = recentBlockhash
      self.instructions = instructions
    }
    
    public init(payerKey: PublicKey, recentBlockhash: String, instructions: [TransactionInstruction]) throws {
      let compiledKeys = try CompiledKeys(instructions: instructions, payer: payerKey)
      let (header, staticAccountKeys) = try compiledKeys.getMessageComponents()
      let accountKeys = MessageAccountKeys(staticAccountKeys: staticAccountKeys)
      let instructions = try accountKeys.compileInstructions(instructions).map { instruction in
        CompiledInstruction(
          programIdIndex: instruction.programIdIndex,
          accounts: instruction.accountKeyIndexes,
          data: instruction.data
        )
      }
      self.init(
        header: header,
        accountKeys: staticAccountKeys,
        recentBlockhash: recentBlockhash,
        instructions: instructions
      )
    }
    
    func isAccountSigner(index: Int) -> Bool {
      return index < self.header.numRequiredSignatures
    }
    
    func isAccountWritable(index: Int) -> Bool {
      let numSignedAccounts = Int(self.header.numRequiredSignatures)
      if (index >= self.header.numRequiredSignatures) {
        let unsignedAccountIndex = index - numSignedAccounts
        let numUnsignedAccounts = self.accountKeys.count - numSignedAccounts
        let numWritableUnsignedAccounts = numUnsignedAccounts - Int(self.header.numReadonlyUnsignedAccounts)
        return unsignedAccountIndex < numWritableUnsignedAccounts
      } else {
        let numWritableSignedAccounts = numSignedAccounts - Int(self.header.numReadonlySignedAccounts)
        return index < numWritableSignedAccounts
      }
    }
    
    func getAccountKeys() -> MessageAccountKeys {
      return MessageAccountKeys(staticAccountKeys: self.staticAccountKeys)
    }
  }
}

extension Solana.Message: Codable {
  public init(from decoder: any Decoder) throws {
    var container = try decoder.unkeyedContainer()
    
    // Header
    self.header = try container.decode(Solana.MessageHeader.self)
    
    if self.header.numRequiredSignatures != self.header.numRequiredSignatures & .VERSION_PREFIX_MASK {
      let context = DecodingError.Context(
        codingPath: decoder.codingPath,
        debugDescription: "Versioned messages must be deserialized to VersionedMessage.",
        underlyingError: nil
      )
      throw DecodingError.typeMismatch(Solana.Message.self, context)
    }
    
    // Account keys
    self.accountKeys = try container.decode([PublicKey].self)
    
    // Recent blockhash
    let recentBlockhash = try container.decode(Data.self)
    self.recentBlockhash = try recentBlockhash.encodeBase58(.solana)
    
    // Instructions
    self.instructions = try container.decode([Solana.CompiledInstruction].self)
  }
  
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
