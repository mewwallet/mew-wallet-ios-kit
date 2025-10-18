//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  /// Per-account flags collected while compiling a message’s account key set.
  ///
  /// - `isSigner`: This account must sign the transaction (fee-payer, owner, multisig signers, etc.).
  /// - `isWritable`: The account may be modified (lamports or data) by any instruction in the message.
  /// - `isInvoked`: This account is a **program id** invoked by at least one instruction.
  ///   Program ids are read-only and never sign.
  public struct CompiledKeyMeta: Sendable, Equatable {
    /// `true` if this account must provide a signature for the transaction.
    var isSigner: Bool
    
    /// `true` if this account is writable in the message.
    var isWritable: Bool
    
    /// `true` if this account is the program id of any instruction in the message.
    var isInvoked: Bool
  }
  
  /// A working set used to build Solana message keys:
  /// - collects unique accounts across all instructions,
  /// - merges flags (signer/writable/invoked),
  /// - derives the canonical ordered key list for the message header,
  /// - optionally extracts Address Lookup Table (ALT) indices.
  public struct CompiledKeys: Sendable, Equatable {
    /// Entry in the “meta map” keyed by base58 address.
    ///
    /// - `address`: base58-encoded public key (used as a stable map key).
    /// - `key`: merged flags across all instructions referring to this account.
    public struct MapItem: Sendable, Equatable {
      let address: String
      var key: CompiledKeyMeta
    }
    
    /// Errors raised while building or extracting compiled keys.
    enum Error: Swift.Error, Equatable {
      case invalidPayer(PublicKey)
      case invalidPublickey(PublicKey)
      case invalidProgramId(PublicKey)
      case maxLookupTableIndexExceeded
      case maxStaticAccountKeysLengthExceeded
      case expectedAtLeastOneWritableSignerKey
      case expectedFirstWritableSignerKeyToBePayer
    }
    /// The declared fee payer. Must be a writable signer and appear **first** among writable signers.
    public let payer: PublicKey
    
    /// Working set of unique accounts discovered while scanning instructions.
    /// Order is insertion order (payer first, then program ids / accounts as discovered).
    public var keyMetaMap: [MapItem]
    
    /// Designated initializer used by call sites that pre-built `keyMetaMap`.
    public init(payer: PublicKey, keyMetaMap: [MapItem]) {
      self.payer = payer
      self.keyMetaMap = keyMetaMap
    }
    
    /// Scans all instructions and constructs the meta map:
    /// - Inserts the fee payer as writable signer.
    /// - Marks program ids as `isInvoked = true`.
    /// - OR-merges `isSigner`/`isWritable` for each account meta encountered.
    ///
    /// Validates:
    /// - `payer`, all account keys, and program ids have valid base58 string forms.
    public init(instructions: [Solana.TransactionInstruction], payer: PublicKey) throws {
      var keyMetaMap: [MapItem] = []
      
      /// Inserts a key if missing; returns its index + current meta.
      func getOrInsertDefault(_ pubkey: PublicKey) throws -> (Int, MapItem) {
        guard let address = pubkey.address()?.address else {
          throw Solana.CompiledKeys.Error.invalidPublickey(pubkey)
        }
        if let index = keyMetaMap.firstIndex(where: { $0.address == address }) {
          return (index, keyMetaMap[index])
        }
        
        keyMetaMap.append(
          .init(
            address: address,
            key: .init(
              isSigner: false,
              isWritable: false,
              isInvoked: false
            )
          )
        )
        return (keyMetaMap.count - 1, keyMetaMap.last!)
      }
      
      // Payer must be valid and will be the first inserted entry.
      guard payer.address()?.address != nil else {
        throw Solana.CompiledKeys.Error.invalidPayer(payer)
      }
      
      // Mark payer as writable signer.
      var (payerKeyMetaIndex, payerKeyMeta) = try getOrInsertDefault(payer)
      payerKeyMeta.key.isSigner = true
      payerKeyMeta.key.isWritable = true
      
      keyMetaMap[payerKeyMetaIndex] = payerKeyMeta
      
      // Walk instructions: mark program ids as invoked; merge metas for accounts.
      for ix in instructions {
        var (programKeyIndex, programKeyMeta) = try getOrInsertDefault(ix.programId)
        programKeyMeta.key.isInvoked = true
        guard ix.programId.address()?.address != nil else {
          throw Solana.CompiledKeys.Error.invalidProgramId(ix.programId)
        }
        keyMetaMap[programKeyIndex] = programKeyMeta
        
        for accountMeta in ix.keys {
          var (keyMetaIndex, keyMeta) = try getOrInsertDefault(accountMeta.pubkey)
          keyMeta.key.isSigner = keyMeta.key.isSigner || accountMeta.isSigner
          keyMeta.key.isWritable = keyMeta.key.isWritable || accountMeta.isWritable
          guard accountMeta.pubkey.address()?.address != nil else {
            throw Error.invalidPublickey(accountMeta.pubkey)
          }
          keyMetaMap[keyMetaIndex] = keyMeta
        }
      }
      
      self.payer = payer
      self.keyMetaMap = keyMetaMap
    }
    
    /// Attempts to extract a **MessageAddressTableLookup** from a given lookup table account.
    ///
    /// Rules (per v0 message spec):
    /// - Only **non-signers** and **non-invoked** (i.e., not program ids) can be placed in lookups.
    /// - We partition candidates by writability and produce two shortvecs of indices:
    ///   - `writableIndexes` for writable candidates,
    ///   - `readonlyIndexes` for read-only candidates.
    /// - Matching addresses are **drained** (removed) from `keyMetaMap` once offloaded to a lookup.
    ///
    /// - Returns: `nil` if no keys were offloaded; otherwise the table lookup + drained keys.
    public mutating func extractTableLookup(_ lookupTable: AddressLookupTableAccount) throws -> (tableLookup: MessageAddressTableLookup, extractedAddresses: AccountKeysFromLookups)? {
      let addresses = lookupTable.state.addresses
      
      // Writable: !signer && !invoked && writable
      let (writableIndexes, drainedWritable) = try drainKeysFoundInLookupTable(
        addresses,
        where: { meta in !meta.isSigner && !meta.isInvoked && meta.isWritable }
      )
      
      // Readonly: !signer && !invoked && !writable
      let (readonlyIndexes, drainedReadonly) = try drainKeysFoundInLookupTable(
        addresses,
        where: { meta in !meta.isSigner && !meta.isInvoked && !meta.isWritable }
      )
      
      // If no keys were found, do not extract lookup
      if writableIndexes.isEmpty && readonlyIndexes.isEmpty {
        return nil
      }
      
      let lut = MessageAddressTableLookup(
        accountKey: lookupTable.key,
        writableIndexes: writableIndexes,
        readonlyIndexes: readonlyIndexes
      )
      let drained = AccountKeysFromLookups(writable: drainedWritable, readonly: drainedReadonly)
      return (lut, drained)
    }
    
    /// Produces the message `header` and the **static** (non-lookup) account keys in canonical order:
    /// 1) writable signers, 2) read-only signers, 3) writable non-signers, 4) read-only non-signers.
    ///
    /// Validates:
    /// - There is at least one writable signer.
    /// - The **first writable signer** is the declared fee payer.
    /// - The number of **static** account keys does not exceed the u8 addressable range (**<= 256**).
    public func getMessageComponents() throws -> (MessageHeader, [PublicKey]) {
      let mapEntries = keyMetaMap
      
      // NOTE: legacy & v0 compiled instruction account indices are `u8` (0..=255)
      guard mapEntries.count <= 256 else {
        throw Error.maxStaticAccountKeysLengthExceeded
      }
      
      let writableSigners = mapEntries.filter { $0.key.isSigner && $0.key.isWritable }
      let readonlySigners = mapEntries.filter { $0.key.isSigner && !$0.key.isWritable }
      let writableNonSigners = mapEntries.filter { !$0.key.isSigner && $0.key.isWritable }
      let readonlyNonSigners = mapEntries.filter { !$0.key.isSigner && !$0.key.isWritable }
      
      guard !writableSigners.isEmpty else {
        throw Error.expectedAtLeastOneWritableSignerKey
      }
      
      // Preserve discovery order: payer is inserted first, so the first writable signer must be payer.
      guard writableSigners.first?.address == self.payer.address()?.address else {
        throw Error.expectedFirstWritableSignerKeyToBePayer
      }
      
      let header = MessageHeader(
        numRequiredSignatures: UInt8(clamping: writableSigners.count + readonlySigners.count),
        numReadonlySignedAccounts: UInt8(clamping: readonlySigners.count),
        numReadonlyUnsignedAccounts: UInt8(clamping: readonlyNonSigners.count)
      )
      var staticAccountKeys: [PublicKey] = []
      staticAccountKeys.reserveCapacity(writableSigners.count + readonlySigners.count + writableNonSigners.count + readonlyNonSigners.count)
      
      try staticAccountKeys.append(contentsOf: writableSigners.map({ try PublicKey(base58: $0.address, network: .solana) }))
      try staticAccountKeys.append(contentsOf: readonlySigners.map({ try PublicKey(base58: $0.address, network: .solana) }))
      try staticAccountKeys.append(contentsOf: writableNonSigners.map({ try PublicKey(base58: $0.address, network: .solana) }))
      try staticAccountKeys.append(contentsOf: readonlyNonSigners.map({ try PublicKey(base58: $0.address, network: .solana) }))
      
      return (header, staticAccountKeys)
    }
    
    /// Finds accounts present in a lookup table and drains them from the static key set.
    ///
    /// - Parameters:
    ///   - addresses: The ALT addresses in on-chain order.
    ///   - predicate: A filter over `CompiledKeyMeta` (e.g., “non-signer writable”).
    /// - Returns:
    ///   - The shortvec-ready list of **u8 indices** into the ALT,
    ///   - The concrete `PublicKey`s drained from the static list.
    ///
    /// - Throws:
    ///   - `maxLookupTableIndexExceeded` if a found address index does not fit in `UInt8`.
    mutating private func drainKeysFoundInLookupTable(_ addresses: [PublicKey], where predicate: (CompiledKeyMeta) -> Bool) throws -> ([UInt8], [PublicKey]) {
      var foundIndexes: [UInt8] = []
      var drainedKeys: [PublicKey] = []
      
      var i = 0
      while i < keyMetaMap.count {
        let item = keyMetaMap[i]
        if predicate(item.key) {
          let key = try PublicKey(base58: item.address, network: .solana)
          if let lutIndex = addresses.firstIndex(of: key) {
            guard let u8 = UInt8(exactly: lutIndex) else {
              throw CompiledKeys.Error.maxLookupTableIndexExceeded
            }
            foundIndexes.append(u8)
            drainedKeys.append(key)
            keyMetaMap.remove(at: i) // drain without advancing `i`
            continue
          }
        }
        i += 1
      }
      return (foundIndexes, drainedKeys)
    }
  }
}
