//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  /// List of instructions to be processed atomically
  public struct MessageV0: Equatable, Sendable {
    public let header: MessageHeader
    
    public let staticAccountKeys: [PublicKey]
    
    public let recentBlockhash: String
    
    public let compiledInstructions: [MessageCompiledInstruction]
    
    public let addressTableLookups: [MessageAddressTableLookup]
    
    public let version: Solana.Version = .v0
    
    public init(header: MessageHeader, staticAccountKeys: [PublicKey], recentBlockhash: String, compiledInstructions: [MessageCompiledInstruction], addressTableLookups: [MessageAddressTableLookup]) {
      self.header = header
      self.staticAccountKeys = staticAccountKeys
      self.recentBlockhash = recentBlockhash
      self.compiledInstructions = compiledInstructions
      self.addressTableLookups = addressTableLookups
    }
    
    public init(payerKey: PublicKey, instructions: [TransactionInstruction], recentBlockhash: String, addressLookupTableAccounts: [AddressLookupTableAccount]? = nil) throws {
      var compiledKeys = try Solana.CompiledKeys(instructions: instructions, payer: payerKey)
      
      var addressTableLookups: [MessageAddressTableLookup] = []
      var accountKeysFromLookups = AccountKeysFromLookups()
      
      if let lookupTables = addressLookupTableAccounts {
        for lookupTable in lookupTables {
          if let (addressTableLookup, extracted) = try compiledKeys.extractTableLookup(lookupTable) {
            addressTableLookups.append(addressTableLookup)
            accountKeysFromLookups.writable.append(contentsOf: extracted.writable)
            accountKeysFromLookups.readonly.append(contentsOf: extracted.readonly)
          }
        }
      }
      
      let (header, staticAccountKeys) = try compiledKeys.getMessageComponents()
      
      let accountKeys = MessageAccountKeys(
        staticAccountKeys: staticAccountKeys,
        accountKeysFromLookups: accountKeysFromLookups
      )
      let compiledInstructions = try accountKeys.compileInstructions(instructions)
      
      self.init(
        header: header,
        staticAccountKeys: staticAccountKeys,
        recentBlockhash: recentBlockhash,
        compiledInstructions: compiledInstructions,
        addressTableLookups: addressTableLookups
      )
    }
    
    func isAccountSigner(index: Int) -> Bool {
      fatalError()
    }
    
    func isAccountWritable(index: Int) -> Bool {
      fatalError()
    }
  }
}

extension Solana.MessageV0: Codable {
  public init(from decoder: any Decoder) throws {
    var container = try decoder.unkeyedContainer()
    
    // Skip version prefix
    _ = try container.decode(UInt8.self)

    // Header
    self.header = try container.decode(Solana.MessageHeader.self)
    
    // Account keys
    self.staticAccountKeys = try container.decode([PublicKey].self)
    
    // Recent blockhash
    let recentBlockhash = try container.decode(Data.self)
    self.recentBlockhash = try recentBlockhash.encodeBase58(.solana)
    
    // Instructions
    self.compiledInstructions = try container.decode([Solana.MessageCompiledInstruction].self)
    
    // AddressTableLookups
    self.addressTableLookups = try container.decode([Solana.MessageAddressTableLookup].self)
  }
  
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.unkeyedContainer()
    
    // Version
    try container.encode(self.version)
    
    // Header
    try container.encode(header)
    
    // Account keys
    try container.encode(staticAccountKeys)
    
    // Recent blockhash
    let blockhash = try recentBlockhash.decodeBase58(.solana)
    try container.encode(blockhash)
    
    // Instructions
    try container.encode(compiledInstructions)
    
    // AddressTableLookups
    try container.encode(addressTableLookups)
  }
}
