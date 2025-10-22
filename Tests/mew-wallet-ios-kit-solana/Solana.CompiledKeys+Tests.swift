//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/13/25.
//

import Foundation
import Testing
@testable import mew_wallet_ios_kit_solana
import CryptoSwift
import mew_wallet_ios_kit

@Suite("CompiledKeys tests")
fileprivate struct CompiledKeysTests {
  private func createTestKeys(count: Int) -> [PublicKey] {
    var keys = [PublicKey]()
    keys.reserveCapacity(count)
    
    for _ in 0..<count {
      try! keys.append(.unique())
    }
    return keys
  }
  
  
  private func createTestLookupTable(addresses: [PublicKey]) throws -> Solana.AddressLookupTableAccount {
    return try Solana.AddressLookupTableAccount(
      key: .unique(),
      state: .init(
        deactivationSlot: .max,
        lastExtendedSlot: 0,
        lastExtendedSlotStartIndex: 0,
        authority: .unique(),
        addresses: addresses
      )
    )
  }
  
  @Test("compile")
  func compile() async throws {
    let payer = try PublicKey.unique()
    let keys = createTestKeys(count: 4)
    let programIds = createTestKeys(count: 4)
    let compiledKeys = try Solana.CompiledKeys(
      instructions: [
        .init(
          keys: [
            .init(pubkey: keys[0], isSigner: false, isWritable: false),
            .init(pubkey: keys[1], isSigner: true, isWritable: false),
            .init(pubkey: keys[2], isSigner: false, isWritable: true),
            .init(pubkey: keys[3], isSigner: true, isWritable: true),
            // duplicate the account metas
            .init(pubkey: keys[0], isSigner: false, isWritable: false),
            .init(pubkey: keys[1], isSigner: true, isWritable: false),
            .init(pubkey: keys[2], isSigner: false, isWritable: true),
            .init(pubkey: keys[3], isSigner: true, isWritable: true),
            // reference program ids
            .init(pubkey: programIds[0], isSigner: false, isWritable: false),
            .init(pubkey: programIds[1], isSigner: true, isWritable: false),
            .init(pubkey: programIds[2], isSigner: false, isWritable: true),
            .init(pubkey: programIds[3], isSigner: true, isWritable: true),
          ],
          programId: programIds[0]
        ),
        .init(keys: [], programId: programIds[1]),
        .init(keys: [], programId: programIds[2]),
        .init(keys: [], programId: programIds[3]),
      ],
      payer: payer
    )
    
    #expect(compiledKeys.keyMetaMap == [
      .init(address: payer.address()!.address, key: .init(isSigner: true, isWritable: true, isInvoked: false)),
      .init(address: programIds[0].address()!.address, key: .init(isSigner: false, isWritable: false, isInvoked: true)),
      .init(address: keys[0].address()!.address, key: .init(isSigner: false, isWritable: false, isInvoked: false)),
      .init(address: keys[1].address()!.address, key: .init(isSigner: true, isWritable: false, isInvoked: false)),
      .init(address: keys[2].address()!.address, key: .init(isSigner: false, isWritable: true, isInvoked: false)),
      .init(address: keys[3].address()!.address, key: .init(isSigner: true, isWritable: true, isInvoked: false)),
      .init(address: programIds[1].address()!.address, key: .init(isSigner: true, isWritable: false, isInvoked: true)),
      .init(address: programIds[2].address()!.address, key: .init(isSigner: false, isWritable: true, isInvoked: true)),
      .init(address: programIds[3].address()!.address, key: .init(isSigner: true, isWritable: true, isInvoked: true)),
    ])
    #expect(compiledKeys.payer == payer)
  }
  
  @Test("compile with dup payer")
  func compileWithDupPayer() async throws {
    let payer = try PublicKey.unique()
    let programId = try PublicKey.unique()
    let compiledKeys = try Solana.CompiledKeys(
      instructions: [
        .init(
          keys: [
            .init(pubkey: payer, isSigner: false, isWritable: false)
          ],
          programId: programId
        )
      ],
      payer: payer
    )
    
    #expect(compiledKeys.keyMetaMap == [
      .init(address: payer.address()!.address, key: .init(isSigner: true, isWritable: true, isInvoked: false)),
      .init(address: programId.address()!.address, key: .init(isSigner: false, isWritable: false, isInvoked: true))
    ])
    #expect(compiledKeys.payer == payer)
  }
  
  @Test("compile with dup key")
  func compileWithDupKey() async throws {
    let payer = try PublicKey.unique()
    let key = try PublicKey.unique()
    let programId = try PublicKey.unique()
    
    let compiledKeys = try Solana.CompiledKeys(
      instructions: [
        .init(
          keys: [
            .init(pubkey: key, isSigner: false, isWritable: false),
            .init(pubkey: key, isSigner: true, isWritable: true)
          ],
          programId: programId
        )
      ],
      payer: payer
    )
    
    #expect(compiledKeys.keyMetaMap == [
      .init(address: payer.address()!.address, key: .init(isSigner: true, isWritable: true, isInvoked: false)),
      .init(address: programId.address()!.address, key: .init(isSigner: false, isWritable: false, isInvoked: true)),
      .init(address: key.address()!.address, key: .init(isSigner: true, isWritable: true, isInvoked: false)),
    ])
    #expect(compiledKeys.payer == payer)
  }
  
  @Test("getMessageComponents")
  func getMessageComponents() async throws {
    let keys = createTestKeys(count: 4)
    let payer = keys[0]
    
    let map: [Solana.CompiledKeys.MapItem] = [
      .init(address: payer.address()!.address, key: .init(isSigner: true, isWritable: true, isInvoked: false)),
      .init(address: keys[1].address()!.address, key: .init(isSigner: true, isWritable: false, isInvoked: false)),
      .init(address: keys[2].address()!.address, key: .init(isSigner: false, isWritable: true, isInvoked: false)),
      .init(address: keys[3].address()!.address, key: .init(isSigner: false, isWritable: false, isInvoked: false)),
    ]
    
    let compiledKeys = Solana.CompiledKeys(payer: payer, keyMetaMap: map)
    let (header, staticAccountKeys) = try compiledKeys.getMessageComponents()
    #expect(staticAccountKeys == keys)
    #expect(header == .init(
      numRequiredSignatures: 2,
      numReadonlySignedAccounts: 1,
      numReadonlyUnsignedAccounts: 1
    ))
  }
  
  @Test("getMessageComponents with overflow")
  func getMessageComponentsWithOverflow() async throws {
    let keys = createTestKeys(count: 257)
    
    let map: [Solana.CompiledKeys.MapItem] = keys.map { key in
      return .init(address: key.address()!.address, key: .init(isSigner: true, isWritable: true, isInvoked: false))
    }
    let compiledKeys = Solana.CompiledKeys(payer: keys[0], keyMetaMap: map)
    
    #expect(throws: Solana.CompiledKeys.Error.maxStaticAccountKeysLengthExceeded, performing: {
      try compiledKeys.getMessageComponents()
    })
  }
  
  @Test("extractTableLookup")
  func extractTableLookup() async throws {
    let keys = createTestKeys(count: 6)
    
    let map: [Solana.CompiledKeys.MapItem] = [
      .init(address: keys[0].address()!.address, key: .init(isSigner: true, isWritable: true, isInvoked: false)),
      .init(address: keys[1].address()!.address, key: .init(isSigner: true, isWritable: false, isInvoked: false)),
      .init(address: keys[2].address()!.address, key: .init(isSigner: false, isWritable: true, isInvoked: false)),
      .init(address: keys[3].address()!.address, key: .init(isSigner: false, isWritable: false, isInvoked: false)),
      .init(address: keys[4].address()!.address, key: .init(isSigner: true, isWritable: false, isInvoked: true)),
      .init(address: keys[5].address()!.address, key: .init(isSigner: false, isWritable: false, isInvoked: true)),
    ]
    let lookupTable = try createTestLookupTable(addresses: keys)
    var compiledKeys = Solana.CompiledKeys(payer: keys[0], keyMetaMap: map)
    let extractResult = try compiledKeys.extractTableLookup(lookupTable)
    #expect(extractResult != nil)
    
    #expect(extractResult?.tableLookup == .init(
      accountKey: lookupTable.key,
      writableIndexes: [2],
      readonlyIndexes: [3]
    ))
    #expect(extractResult?.extractedAddresses == .init(
      writable: [keys[2]],
      readonly: [keys[3]]
    ))
  }
  
  @Test("extractTableLookup no extractable keys found")
  func extractTableLookupNoExtractableKeysFound() async throws {
    let keys = createTestKeys(count: 6)
    
    let map: [Solana.CompiledKeys.MapItem] = [
      .init(address: keys[0].address()!.address, key: .init(isSigner: true, isWritable: true, isInvoked: false)),
      .init(address: keys[1].address()!.address, key: .init(isSigner: true, isWritable: false, isInvoked: false)),
      .init(address: keys[2].address()!.address, key: .init(isSigner: true, isWritable: true, isInvoked: true)),
      .init(address: keys[3].address()!.address, key: .init(isSigner: true, isWritable: false, isInvoked: true)),
      .init(address: keys[4].address()!.address, key: .init(isSigner: false, isWritable: true, isInvoked: true)),
      .init(address: keys[5].address()!.address, key: .init(isSigner: false, isWritable: false, isInvoked: true)),
    ]
    let lookupTable = try createTestLookupTable(addresses: keys)
    var compiledKeys = Solana.CompiledKeys(payer: keys[0], keyMetaMap: map)
    let extractResult = try compiledKeys.extractTableLookup(lookupTable)
    #expect(extractResult == nil)
  }
  
  @Test("extractTableLookup with empty lookup table")
  func extractTableLookupWithEmptyLookupTable() async throws {
    let keys = createTestKeys(count: 2)
    
    let map: [Solana.CompiledKeys.MapItem] = [
      .init(address: keys[0].address()!.address, key: .init(isSigner: true, isWritable: true, isInvoked: false)),
      .init(address: keys[1].address()!.address, key: .init(isSigner: false, isWritable: false, isInvoked: false)),
    ]
    let lookupTable = try createTestLookupTable(addresses: [])
    var compiledKeys = Solana.CompiledKeys(payer: keys[0], keyMetaMap: map)
    let extractResult = try compiledKeys.extractTableLookup(lookupTable)
    #expect(extractResult == nil)
  }
  
  @Test("extractTableLookup with invalid lookup table")
  func extractTableLookupWithEmptyLookupTable2() async throws {
    let keys = createTestKeys(count: 257)
    
    let map: [Solana.CompiledKeys.MapItem] = [
      .init(address: keys[0].address()!.address, key: .init(isSigner: true, isWritable: true, isInvoked: false)),
      .init(address: keys[256].address()!.address, key: .init(isSigner: false, isWritable: false, isInvoked: false)),
    ]
    let lookupTable = try createTestLookupTable(addresses: keys)
    var compiledKeys = Solana.CompiledKeys(payer: keys[0], keyMetaMap: map)
    #expect(throws: Solana.CompiledKeys.Error.maxLookupTableIndexExceeded, performing: {
      try compiledKeys.extractTableLookup(lookupTable)
    })
  }
}
