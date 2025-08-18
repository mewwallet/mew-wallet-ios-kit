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

@Suite("TransactionMessage tests")
fileprivate struct TransactionMessageTests {
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
  
  @Test("decompiles a legacy message")
  func decompilesALegacyMessage() async throws {
    let keys = createTestKeys(count: 7)
    let recentBlockhash: String = try "test".data(using: .utf8)!.sha256().encodeBase58(.solana)
    let payerKey = keys[0]
    let instructions: [Solana.TransactionInstruction] = [
      .init(
        keys: [
          .init(pubkey: keys[0], isSigner: true, isWritable: true),
          .init(pubkey: keys[6], isSigner: false, isWritable: false),
          .init(pubkey: keys[1], isSigner: false, isWritable: true),
          .init(pubkey: keys[3], isSigner: false, isWritable: false),
          .init(pubkey: keys[4], isSigner: false, isWritable: false),
          .init(pubkey: keys[2], isSigner: false, isWritable: false),
        ],
        programId: keys[5],
        data: Data(hex: "0x00")
      )
    ]
    let message = try Solana.Message(
      payerKey: payerKey,
      recentBlockhash: recentBlockhash,
      instructions: instructions
    )
    
    let decompiledMessage = try Solana.TransactionMessage(message: message)
    
    #expect(decompiledMessage.payerKey == payerKey)
    #expect(decompiledMessage.recentBlockhash == recentBlockhash)
    #expect(decompiledMessage.instructions == instructions)
  }
  
  @Test("decompiles a legacy message the same way as the old API")
  func decompilesALegacyMessageTheSameWayAsTheOldAPI() async throws {
    let accountKeys = createTestKeys(count: 7)
    let recentBlockhash: String = try "test".data(using: .utf8)!.sha256().encodeBase58(.solana)
    
    let legacyMessage = Solana.Message(
      header: .init(
        numRequiredSignatures: 1,
        numReadonlySignedAccounts: 0,
        numReadonlyUnsignedAccounts: 5
      ),
      accountKeys: accountKeys,
      recentBlockhash: recentBlockhash,
      instructions: [
        .init(
          programIdIndex: 5,
          accounts: [0, 6, 1, 3, 4, 2],
          data: Data()
        )
      ]
    )
    
    var transactionFromLegacyAPI = Solana.Transaction()
    transactionFromLegacyAPI.populate(signatures: [], message: legacyMessage)
    let transactionMessage = try Solana.TransactionMessage(message: legacyMessage)

    #expect(transactionMessage.payerKey == transactionFromLegacyAPI.feePayer)
    #expect(transactionMessage.instructions == transactionFromLegacyAPI.instructions)
    #expect(transactionMessage.recentBlockhash == transactionFromLegacyAPI.recentBlockhash)
  }
  
  @Test("decompiles a V0 message")
  func decompilesAV0Message() async throws {
    let keys = createTestKeys(count: 7)
    let recentBlockhash: String = try "test".data(using: .utf8)!.sha256().encodeBase58(.solana)
    let payerKey = keys[0]
    let instructions: [Solana.TransactionInstruction] = [
      .init(
        keys: [
          .init(pubkey: keys[1], isSigner: true, isWritable: true),
          .init(pubkey: keys[2], isSigner: true, isWritable: false),
          .init(pubkey: keys[3], isSigner: false, isWritable: true),
          .init(pubkey: keys[5], isSigner: false, isWritable: true),
          .init(pubkey: keys[6], isSigner: false, isWritable: false),
        ],
        programId: keys[4],
        data: Data(hex: "0x00")
      ),
      .init(
        keys: [],
        programId: keys[1],
        data: Data(hex: "0x0000")
      ),
      .init(
        keys: [],
        programId: keys[3],
        data: Data(hex: "0x000000")
      )
    ]
    let addressLookupTableAccounts = try [createTestLookupTable(addresses: keys)]
    let message = try Solana.MessageV0(
      payerKey: payerKey,
      instructions: instructions,
      recentBlockhash: recentBlockhash,
      addressLookupTableAccounts: addressLookupTableAccounts
    )
    #expect(throws: Solana.MessageV0.Error.accountKeysAddressTableLookupsWereNotResolved, performing: {
      try Solana.TransactionMessage(message: message)
    })
    
    let accountKeys = try message.getAccountKeys(addressLookupTableAccounts: addressLookupTableAccounts)
    let decompiledMessage = try Solana.TransactionMessage(message: message, addressLookupTableAccounts: addressLookupTableAccounts)
    
    #expect(decompiledMessage.payerKey == payerKey)
    #expect(decompiledMessage.recentBlockhash == recentBlockhash)
    #expect(decompiledMessage.instructions == instructions)

    let expectedMessage = try Solana.TransactionMessage(message: message, accountKeysFromLookups: accountKeys.accountKeysFromLookups)
    #expect(decompiledMessage == expectedMessage)
  }
}
