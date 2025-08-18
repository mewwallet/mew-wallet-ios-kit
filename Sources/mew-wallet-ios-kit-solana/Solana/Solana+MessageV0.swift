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
    enum Error: Swift.Error, Equatable {
      case mismatchInNumberOfAccountKeysFromLookups
      case accountKeysAddressTableLookupsWereNotResolved
      case missingTableKey(PublicKey)
      case missingAddress(index: UInt8, key: PublicKey)
    }
    public let header: MessageHeader
    
    public let staticAccountKeys: [PublicKey]
    
    public let recentBlockhash: String
    
    public let compiledInstructions: [MessageCompiledInstruction]
    
    public var addressTableLookups: [MessageAddressTableLookup]
    
    public let version: Solana.Version = .v0
    
    var numAccountKeysFromLookups: Int {
      return addressTableLookups.reduce(into: 0) { partialResult, lookup in
        partialResult += lookup.readonlyIndexes.count + lookup.writableIndexes.count
      }
    }
    
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
      return index < self.header.numRequiredSignatures
    }
    
    func isAccountWritable(index: Int) -> Bool {
      let numSignedAccounts = header.numRequiredSignatures
      let numStaticAccountKeys = staticAccountKeys.count
      
      if index >= numStaticAccountKeys {
        let lookupAccountKeysIndex = index - numStaticAccountKeys
        let numWritableLookupAccountKeys = addressTableLookups.reduce(0) { count, lookup in
          count + lookup.writableIndexes.count
        }
        return lookupAccountKeysIndex < numWritableLookupAccountKeys
      } else if index >= numSignedAccounts {
        let unsignedAccountIndex = index - Int(numSignedAccounts)
        let numUnsignedAccounts = numStaticAccountKeys - Int(numSignedAccounts)
        let numWritableUnsignedAccounts = numUnsignedAccounts - Int(header.numReadonlyUnsignedAccounts)
        return unsignedAccountIndex < numWritableUnsignedAccounts
      } else {
        let numWritableSignedAccounts = numSignedAccounts - header.numReadonlySignedAccounts
        return index < numWritableSignedAccounts
      }
    }
    
    public func getAccountKeys(accountKeysFromLookups: AccountKeysFromLookups? = nil) throws -> MessageAccountKeys {
      return try self._getAccountKeys(accountKeysFromLookups: accountKeysFromLookups)
    }
    
    public func getAccountKeys(addressLookupTableAccounts: [AddressLookupTableAccount]) throws -> MessageAccountKeys {
      return try self._getAccountKeys(addressLookupTableAccounts: addressLookupTableAccounts)
    }
    
    public func resolveAddressTableLookups(addressLookupTableAccounts: [AddressLookupTableAccount]) throws -> AccountKeysFromLookups {
      var accountKeysFromLookups = AccountKeysFromLookups()
      
      for tableLookup in addressTableLookups {
        guard let tableAccount = addressLookupTableAccounts.first(where: { $0.key == tableLookup.accountKey }) else {
          throw Error.missingTableKey(tableLookup.accountKey)
        }
        
        let addresses = tableAccount.state.addresses
        
        for index in tableLookup.writableIndexes {
          guard index < addresses.count else {
            throw Error.missingAddress(index: index, key: tableLookup.accountKey)
          }
          accountKeysFromLookups.writable.append(addresses[Int(index)])
        }
        
        for index in tableLookup.readonlyIndexes {
          guard index < addresses.count else {
            throw Error.missingAddress(index: index, key: tableLookup.accountKey)
          }
          accountKeysFromLookups.readonly.append(addresses[Int(index)])
        }
      }
      
      return accountKeysFromLookups
    }
    
    private func _getAccountKeys(accountKeysFromLookups: AccountKeysFromLookups? = nil, addressLookupTableAccounts: [AddressLookupTableAccount]? = nil) throws -> MessageAccountKeys {
      let accountKeys: AccountKeysFromLookups?
      if let accountKeysFromLookups {
        guard self.numAccountKeysFromLookups == accountKeysFromLookups.writable.count + accountKeysFromLookups.readonly.count else {
          throw Error.mismatchInNumberOfAccountKeysFromLookups
        }
        accountKeys = accountKeysFromLookups
      } else if let addressLookupTableAccounts {
        accountKeys = try self.resolveAddressTableLookups(addressLookupTableAccounts: addressLookupTableAccounts)
      } else {
        guard self.addressTableLookups.isEmpty else {
          throw Error.accountKeysAddressTableLookupsWereNotResolved
        }
        accountKeys = nil
      }
      
      return MessageAccountKeys(
        staticAccountKeys: self.staticAccountKeys,
        accountKeysFromLookups: accountKeys
      )
    }
  }
}

extension Solana.MessageV0: Codable {
  public init(from decoder: any Decoder) throws {
    var container = try decoder.unkeyedContainer()
    
    // Skip version prefix
    let version = try container.decode(Solana.Version.self)
    switch version {
    case .legacy:
      throw DecodingError.typeMismatch(
        Solana.MessageV0.self,
        .init(codingPath: [], debugDescription: "Expected versioned message but received legacy message")
      )
    case .v0:
      // Consume version byte
      _ = try container.decode(UInt8.self)
    case .unknown(let uInt8):
      throw DecodingError.typeMismatch(
        Solana.MessageV0.self,
        .init(codingPath: [], debugDescription: "Expected versioned message with version 0 but found version \(uInt8)")
      )
    }

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
