//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  public struct CompiledKeyMeta: Sendable, Equatable {
    var isSigner: Bool
    var isWritable: Bool
    var isInvoked: Bool
  }
  
  public struct CompiledKeys: Sendable, Equatable {
    public struct MapItem: Sendable, Equatable {
      let address: String
      var key: CompiledKeyMeta
    }
    
    enum Error: Swift.Error, Equatable {
      case invalidPayer(PublicKey)
      case invalidPublickey(PublicKey)
      case invalidProgramId(PublicKey)
      case maxLookupTableIndexExceeded
      case maxStaticAccountKeysLengthExceeded
      case expectedAtLeastOneWritableSignerKey
      case expectedFirstWritableSignerKeyToBePayer
    }
    public let payer: PublicKey
    public var keyMetaMap: [MapItem]
    
    public init(payer: PublicKey, keyMetaMap: [MapItem]) {
      self.payer = payer
      self.keyMetaMap = keyMetaMap
    }
    
    public init(instructions: [Solana.TransactionInstruction], payer: PublicKey) throws {
      var keyMetaMap: [MapItem] = []
      
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
      
      guard payer.address()?.address != nil else {
        throw Solana.CompiledKeys.Error.invalidPayer(payer)
      }
      // payer
      var (payerKeyMetaIndex, payerKeyMeta) = try getOrInsertDefault(payer)
      payerKeyMeta.key.isSigner = true
      payerKeyMeta.key.isWritable = true
      
      keyMetaMap[payerKeyMetaIndex] = payerKeyMeta
      
      // instructions
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
    
    public func getMessageComponents() throws -> (MessageHeader, [PublicKey]) {
      let mapEntries = keyMetaMap
      
      guard mapEntries.count <= UInt8.max else {
        throw Error.maxStaticAccountKeysLengthExceeded
      }
      
      let writableSigners = mapEntries.filter { $0.key.isSigner && $0.key.isWritable }
      let readonlySigners = mapEntries.filter { $0.key.isSigner && !$0.key.isWritable }
      let writableNonSigners = mapEntries.filter { !$0.key.isSigner && $0.key.isWritable }
      let readonlyNonSigners = mapEntries.filter { !$0.key.isSigner && !$0.key.isWritable }
      
      guard !writableSigners.isEmpty else {
        throw Error.expectedAtLeastOneWritableSignerKey
      }
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
    
    mutating private func drainKeysFoundInLookupTable(
      _ addresses: [PublicKey],
      where predicate: (CompiledKeyMeta) -> Bool
    ) throws -> ([UInt8], [PublicKey]) {
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
            keyMetaMap.remove(at: i) // drain
            continue // don't advance i after removal
          }
        }
        i += 1
      }
      return (foundIndexes, drainedKeys)
    }
  }
}
