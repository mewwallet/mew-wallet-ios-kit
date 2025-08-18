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

@Suite("MessageAccountKeys tests")
fileprivate struct CompiledKeysTests {
  private func createTestKeys(count: Int) -> [PublicKey] {
    var keys = [PublicKey]()
    keys.reserveCapacity(count)
    
    for _ in 0..<count {
      try! keys.append(.unique())
    }
    return keys
  }
  
  @Test("keySegments")
  func keySegments() async throws {
    let keys = createTestKeys(count: 6)
    let staticAccountKeys = Array(keys[0..<3])
    let accountKeysFromLookup = Solana.AccountKeysFromLookups(
      writable: [keys[3], keys[4]],
      readonly: [keys[5]]
    )
    
    let accountKeys = Solana.MessageAccountKeys(
      staticAccountKeys: staticAccountKeys,
      accountKeysFromLookups: accountKeysFromLookup
    )
    let expectedSegments = [
      staticAccountKeys,
      accountKeysFromLookup.writable,
      accountKeysFromLookup.readonly
    ]
    
    #expect(expectedSegments == accountKeys.keySegments)
  }
  
  @Test("get")
  func get() async throws {
    let keys = createTestKeys(count: 3)
    
    let accountKeys = Solana.MessageAccountKeys(staticAccountKeys: keys)
    
    #expect(accountKeys.get(keyAtIndex: 0) == keys[0])
    #expect(accountKeys.get(keyAtIndex: 1) == keys[1])
    #expect(accountKeys.get(keyAtIndex: 2) == keys[2])
    #expect(accountKeys.get(keyAtIndex: 3) == nil)
  }
  
  @Test("get with loaded addresses")
  func getWithLoadedAddresses() async throws {
    let keys = createTestKeys(count: 6)
    let staticAccountKeys = Array(keys[0..<3])
    let accountKeysFromLookup = Solana.AccountKeysFromLookups(
      writable: [keys[3], keys[4]],
      readonly: [keys[5]]
    )
    let accountKeys = Solana.MessageAccountKeys(
      staticAccountKeys: staticAccountKeys,
      accountKeysFromLookups: accountKeysFromLookup
    )
    #expect(accountKeys.get(keyAtIndex: 0) == keys[0])
    #expect(accountKeys.get(keyAtIndex: 1) == keys[1])
    #expect(accountKeys.get(keyAtIndex: 2) == keys[2])
    #expect(accountKeys.get(keyAtIndex: 3) == keys[3])
    #expect(accountKeys.get(keyAtIndex: 4) == keys[4])
    #expect(accountKeys.get(keyAtIndex: 5) == keys[5])
  }
  
  @Test("length")
  func length() async throws {
    let keys = createTestKeys(count: 6)
    let accountKeys = Solana.MessageAccountKeys(staticAccountKeys: keys)
    #expect(accountKeys.count == 6)
  }
  
  @Test("length with loaded addresses")
  func lengthWithLoadedAddresses() async throws {
    let keys = createTestKeys(count: 6)
    let accountKeysFromLookup = Solana.AccountKeysFromLookups(
      writable: [],
      readonly: Array(keys[3..<6])
    )
    let accountKeys = Solana.MessageAccountKeys(
      staticAccountKeys: Array(keys[0..<3]),
      accountKeysFromLookups: accountKeysFromLookup
    )
    #expect(accountKeys.count == 6)
  }
  
  @Test("compileInstructions")
  func compileInstructions() async throws {
    let keys = createTestKeys(count: 3)
    let staticAccountKeys = [keys[0]]
    let accountKeysFromLookup = Solana.AccountKeysFromLookups(
      writable: [keys[1]],
      readonly: [keys[2]]
    )
    let accountKeys = Solana.MessageAccountKeys(
      staticAccountKeys: staticAccountKeys,
      accountKeysFromLookups: accountKeysFromLookup
    )
    let instructions = Solana.TransactionInstruction(
      keys: [
        .init(pubkey: keys[1], isSigner: true, isWritable: true),
        .init(pubkey: keys[2], isSigner: true, isWritable: true),
      ],
      programId: keys[0],
      data: Data()
    )
    
    let expectedInstructions: Solana.MessageCompiledInstruction = .init(
      programIdIndex: 0,
      accountKeyIndexes: [1, 2],
      data: Data()
    )
    
    try #expect(accountKeys.compileInstructions([instructions]) == [expectedInstructions])
  }
  
  @Test("compileInstructions with unknown key")
  func compileInstructionsWithUnknownKey() async throws {
    let keys = createTestKeys(count: 3)
    let staticAccountKeys = [keys[0]]
    let accountKeysFromLookup = Solana.AccountKeysFromLookups(
      writable: [keys[1]],
      readonly: [keys[2]]
    )
    let accountKeys = Solana.MessageAccountKeys(
      staticAccountKeys: staticAccountKeys,
      accountKeysFromLookups: accountKeysFromLookup
    )
    
    let unknownKey = try PublicKey.unique()
    
    let testInstructions: [Solana.TransactionInstruction] = [
      .init(keys: [], programId: unknownKey, data: Data()),
      .init(
        keys: [
          .init(pubkey: keys[1], isSigner: true, isWritable: true),
          .init(pubkey: unknownKey, isSigner: true, isWritable: true),
        ],
        programId: keys[0],
        data: Data()
      )
    ]
    for instruction in testInstructions {
      #expect(throws: Solana.MessageAccountKeys.Error.unknownInstructionAccountKey(unknownKey), performing: {
        try accountKeys.compileInstructions([instruction])
      })
    }
  }
  
  @Test("compileInstructions with too many account keys")
  func compileInstructionsWithTooManyAccountKeys() async throws {
    let keys = createTestKeys(count: 257)
    let staticAccountKeys = Array(keys[0..<257])
    let accountKeysFromLookup = Solana.AccountKeysFromLookups(
      writable: [keys[256]],
      readonly: []
    )
    let accountKeys = Solana.MessageAccountKeys(
      staticAccountKeys: staticAccountKeys,
      accountKeysFromLookups: accountKeysFromLookup
    )
    
    #expect(throws: Solana.MessageAccountKeys.Error.accountIndexOverflow, performing: {
      try accountKeys.compileInstructions([])
    })
  }
}
