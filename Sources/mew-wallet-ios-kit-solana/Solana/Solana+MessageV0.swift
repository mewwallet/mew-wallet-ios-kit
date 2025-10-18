//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  /// Versioned (v0) message: an atomic list of instructions with static keys
  /// plus Address Lookup Table (ALT) lookups.
  ///
  /// Layout on the wire (v0):
  /// - 1 byte: version prefix (0x80 | 0)
  /// - `MessageHeader`
  /// - shortvec<`PublicKey`> static account keys
  /// - `recentBlockhash` (32 bytes)
  /// - shortvec<`MessageCompiledInstruction`> instructions
  /// - shortvec<`MessageAddressTableLookup`> address table lookups
  public struct MessageV0: Equatable, Sendable {
    // MARK: Errors
    enum Error: Swift.Error, Equatable {
      /// The supplied `AccountKeysFromLookups` didn’t match the total indices
      /// referenced by `addressTableLookups`.
      case mismatchInNumberOfAccountKeysFromLookups
      /// Caller requested keys but didn’t provide lookups nor tables, while
      /// `addressTableLookups` isn’t empty.
      case accountKeysAddressTableLookupsWereNotResolved
      /// A lookup referenced a table that wasn’t provided.
      case missingTableKey(PublicKey)
      /// A lookup referenced an index outside the table’s address array.
      case missingAddress(index: UInt8, key: PublicKey)
    }
    
    // MARK: Header & keys
    
    /// Compact counts describing signer/read-only segments for **static** keys.
    public let header: MessageHeader
    
    /// The “static” account keys carried inline in the message.
    /// (These include all signers; ALT-derived keys are never signers.)
    public let staticAccountKeys: [PublicKey]
    
    /// The recent blockhash (base58), used for freshness/expiry.
    public var recentBlockhash: String
    
    /// Program-invocation list, already compiled to index form.
    public let compiledInstructions: [MessageCompiledInstruction]
    
    /// Lookups to load extra accounts from Address Lookup Tables (ALTs).
    /// The loaded keys get appended after `staticAccountKeys` in this order:
    /// first all writable lookup keys, then all read-only lookup keys.
    public var addressTableLookups: [MessageAddressTableLookup]
    
    /// Version discriminator for this message (always `.v0` here).
    public let version: Solana.Version = .v0
    
    // MARK: Derived counts
    
    /// Total number of ALT-derived keys referenced by all lookups.
    var numAccountKeysFromLookups: Int {
      return addressTableLookups.reduce(into: 0) { partialResult, lookup in
        partialResult += lookup.readonlyIndexes.count + lookup.writableIndexes.count
      }
    }
    
    // MARK: Init
    
    public init(header: MessageHeader, staticAccountKeys: [PublicKey], recentBlockhash: String, compiledInstructions: [MessageCompiledInstruction], addressTableLookups: [MessageAddressTableLookup]) {
      self.header = header
      self.staticAccountKeys = staticAccountKeys
      self.recentBlockhash = recentBlockhash
      self.compiledInstructions = compiledInstructions
      self.addressTableLookups = addressTableLookups
    }
    
    /// Convenience initializer that compiles instructions and optionally extracts
    /// ALT lookups from provided tables.
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
    
    // MARK: Accessors
    
    /// True if the account at `index` is a signer.
    /// (All signers live in the static segment.)
    func isAccountSigner(index: Int) -> Bool {
      return index < self.header.numRequiredSignatures
    }
    
    /// True if the account at `index` is writable.
    ///
    /// For static keys, the header splits signed/unsigned into writable and
    /// read-only tails. For ALT-derived keys, writable lookups are placed first,
    /// followed by read-only lookups.
    func isAccountWritable(index: Int) -> Bool {
      let numSignedAccounts = header.numRequiredSignatures
      let numStaticAccountKeys = staticAccountKeys.count
      
      if index >= numStaticAccountKeys {
        // In the lookup region: writable block first, then read-only block.
        let lookupAccountKeysIndex = index - numStaticAccountKeys
        let numWritableLookupAccountKeys = addressTableLookups.reduce(0) { count, lookup in
          count + lookup.writableIndexes.count
        }
        return lookupAccountKeysIndex < numWritableLookupAccountKeys
      } else if index >= numSignedAccounts {
        // Unsigned static keys: compute writable prefix length.
        let unsignedAccountIndex = index - Int(numSignedAccounts)
        let numUnsignedAccounts = numStaticAccountKeys - Int(numSignedAccounts)
        let numWritableUnsignedAccounts = numUnsignedAccounts - Int(header.numReadonlyUnsignedAccounts)
        return unsignedAccountIndex < numWritableUnsignedAccounts
      } else {
        // Signed static keys: writable prefix length.
        let numWritableSignedAccounts = numSignedAccounts - header.numReadonlySignedAccounts
        return index < numWritableSignedAccounts
      }
    }
    
    /// Returns a `MessageAccountKeys` view, resolving ALT keys either from an
    /// explicit set of loaded keys or by resolving from the provided tables.
    public func getAccountKeys(accountKeysFromLookups: AccountKeysFromLookups? = nil) throws -> MessageAccountKeys {
      return try self._getAccountKeys(accountKeysFromLookups: accountKeysFromLookups)
    }
    
    /// Same as above but resolves ALT indices against the provided tables.
    public func getAccountKeys(addressLookupTableAccounts: [AddressLookupTableAccount]) throws -> MessageAccountKeys {
      return try self._getAccountKeys(addressLookupTableAccounts: addressLookupTableAccounts)
    }
    
    /// Resolves `addressTableLookups` using the given table accounts, returning
    /// the concatenated writable then read-only address lists.
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
    
    // MARK: Internals
    
    private func _getAccountKeys(accountKeysFromLookups: AccountKeysFromLookups? = nil, addressLookupTableAccounts: [AddressLookupTableAccount]? = nil) throws -> MessageAccountKeys {
      let accountKeys: AccountKeysFromLookups?
      if let accountKeysFromLookups {
        // Must match the total indices referenced by the lookups.
        guard self.numAccountKeysFromLookups == accountKeysFromLookups.writable.count + accountKeysFromLookups.readonly.count else {
          throw Error.mismatchInNumberOfAccountKeysFromLookups
        }
        accountKeys = accountKeysFromLookups
      } else if let addressLookupTableAccounts {
        accountKeys = try self.resolveAddressTableLookups(addressLookupTableAccounts: addressLookupTableAccounts)
      } else {
        // If we have lookups but the caller didn’t resolve or provide them, fail.
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
    
    // Version byte (0x80 | 0) is *peeked* by your custom decoder when decoding `Solana.Version`.
    let version = try container.decode(Solana.Version.self)
    switch version {
    case .legacy:
      throw DecodingError.typeMismatch(
        Solana.MessageV0.self,
        .init(codingPath: [], debugDescription: "Expected versioned message but received legacy message")
      )
    case .v0:
      // Now actually consume the version byte (your decoder's .version path peeks).
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
