//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation
import Testing
@testable import mew_wallet_ios_kit_solana
import CryptoSwift
import mew_wallet_ios_kit

@Suite("Message tests")
fileprivate struct SolanaMessageTests {
  private func createTestKeys(count: Int) -> [PublicKey] {
    var keys = [PublicKey]()
    keys.reserveCapacity(count)
    
    for _ in 0..<count {
      try! keys.append(PublicKey(hex: Data.randomBytes(length: 32)!.toHexString(), network: .solana))
    }
    return keys
  }
  
  @Test("compile")
  func compile() async throws {
    let keys = createTestKeys(count: 5)
    let recentBlockhash: String = try "test".data(using: .utf8)!.sha256().encodeBase58(.solana)
    let payerKey = keys[0]
    let instructions: [Solana.TransactionInstruction] = [
      .init(
        keys: [
          .init(pubkey: keys[1], isSigner: true, isWritable: true),
          .init(pubkey: keys[2], isSigner: false, isWritable: false),
          .init(pubkey: keys[3], isSigner: false, isWritable: false),
        ],
        programId: keys[4],
        data: Data(hex: "0x00")
      ),
      .init(
        keys: [
          .init(pubkey: keys[2], isSigner: true, isWritable: false),
          .init(pubkey: keys[3], isSigner: false, isWritable: true),
        ],
        programId: keys[1],
        data: Data(hex: "0x0000")
      )
    ]
    
    let message = try Solana.Message(
      payerKey: payerKey,
      recentBlockhash: recentBlockhash,
      instructions: instructions
    )
    #expect(message.accountKeys == [
      payerKey, // payer is first
      keys[1], // other writable signer
      keys[2], // sole readonly signer
      keys[3], // sole writable non-signer
      keys[4], // sole readonly non-signer
    ])
    #expect(message.header == .init(
      numRequiredSignatures: 3,
      numReadonlySignedAccounts: 1,
      numReadonlyUnsignedAccounts: 1
    ))
    #expect(message.addressTableLookups.isEmpty)
    #expect(message.instructions == [
      .init(
        programIdIndex: 4,
        accounts: [1, 2, 3],
        data: Data(hex: "0x00")
      ),
      .init(
        programIdIndex: 1,
        accounts: [2, 3],
        data: Data(hex: "0x0000")
      ),
    ])
    #expect(message.recentBlockhash == recentBlockhash)
  }
  
  @Test("compile without instructions")
  func compileWithoutInstructions() async throws {
    let payerKey = try PublicKey(hex: Data.randomBytes(length: 32)!.toHexString(), network: .solana)
    let recentBlockhash: String = try "test".data(using: .utf8)!.sha256().encodeBase58(.solana)
    let message = try Solana.Message(
      payerKey: payerKey,
      recentBlockhash: recentBlockhash,
      instructions: []
    )
    
    #expect(message.accountKeys == [payerKey])
    #expect(message.header == .init(
      numRequiredSignatures: 1,
      numReadonlySignedAccounts: 0,
      numReadonlyUnsignedAccounts: 0
    ))
    #expect(message.addressTableLookups.isEmpty)
    #expect(message.instructions.isEmpty)
    #expect(message.recentBlockhash == recentBlockhash)
  }
  
  @Test("isAccountWritable")
  func isAccountWritable() async throws {
    let accountKeys = self.createTestKeys(count: 4)
    let recentBlockhash: String = try "test".data(using: .utf8)!.sha256().encodeBase58(.solana)
    let message = Solana.Message(
      header: .init(
        numRequiredSignatures: 2,
        numReadonlySignedAccounts: 1,
        numReadonlyUnsignedAccounts: 1
      ),
      accountKeys: accountKeys,
      recentBlockhash: recentBlockhash,
      instructions: []
    )
    #expect(message.isAccountWritable(index: 0) == true)
    #expect(message.isAccountWritable(index: 1) == false)
    #expect(message.isAccountWritable(index: 2) == true)
    #expect(message.isAccountWritable(index: 3) == false)
  }
  
  @Test("isAccountSigner")
  func isAccountSigner() async throws {
    let accountKeys = self.createTestKeys(count: 4)
    let recentBlockhash: String = try "test".data(using: .utf8)!.sha256().encodeBase58(.solana)
    let message = Solana.Message(
      header: .init(
        numRequiredSignatures: 2,
        numReadonlySignedAccounts: 1,
        numReadonlyUnsignedAccounts: 1
      ),
      accountKeys: accountKeys,
      recentBlockhash: recentBlockhash,
      instructions: []
    )
    #expect(message.isAccountSigner(index: 0) == true)
    #expect(message.isAccountSigner(index: 1) == true)
    #expect(message.isAccountSigner(index: 2) == false)
    #expect(message.isAccountSigner(index: 3) == false)
  }
}
