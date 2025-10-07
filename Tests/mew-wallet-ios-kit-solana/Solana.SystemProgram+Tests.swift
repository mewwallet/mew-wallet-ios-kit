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

@Suite("SystemProgram tests")
fileprivate struct SystemProgramTests {
  //  private func createTestKeys(count: Int) -> [PublicKey] {
  //    var keys = [PublicKey]()
  //    keys.reserveCapacity(count)
  //
  //    for _ in 0..<count {
  //      try! keys.append(.unique())
  //    }
  //    return keys
  //  }
  //
  //
  //  private func createTestLookupTable(addresses: [PublicKey]) throws -> Solana.AddressLookupTableAccount {
  //    return try Solana.AddressLookupTableAccount(
  //      key: .unique(),
  //      state: .init(
  //        deactivationSlot: .max,
  //        lastExtendedSlot: 0,
  //        lastExtendedSlotStartIndex: 0,
  //        authority: .unique(),
  //        addresses: addresses
  //      )
  //    )
  //  }
  //
  @Test("createAccount")
  func createAccount() async throws {
    let params = try Solana.SystemProgram.CreateAccountParams(
      fromPubkey: .unique(),
      newAccountPubkey: .unique(),
      lamports: 123,
      space: 0,
      programId: Solana.SystemProgram.programId
    )
    let transaction = try Solana.Transaction().adding(
      instructions: Solana.SystemProgram.createAccount(params: params)
    )
    #expect(transaction.instructions.count == 1)
    let decoded = try Solana.SystemInstruction.decodeCreateAccount(instruction: transaction.instructions[0])
    #expect(params == decoded)
  }
  
  @Test("transfer")
  func transfer() async throws {
    let params = try Solana.SystemProgram.TransferParams(
      fromPubkey: .unique(),
      toPubkey: .unique(),
      lamports: 123
    )
    let transaction = try Solana.Transaction().adding(
      instructions: Solana.SystemProgram.transfer(params: params)
    )
    #expect(transaction.instructions.count == 1)
    let decoded = try Solana.SystemInstruction.decodeTransfer(instruction: transaction.instructions[0])
    #expect(params == decoded)
  }
  
  @Test("transferWithSeed")
  func transferWithSeed() async throws {
    let params = try Solana.SystemProgram.TransferWithSeedParams(
      fromPubkey: .unique(),
      basePubkey: .unique(),
      toPubkey: .unique(),
      lamports: 123,
      seed: "你好",
      programId: .unique()
    )
    let transaction = try Solana.Transaction().adding(
      instructions: Solana.SystemProgram.transfer(params: params)
    )
    #expect(transaction.instructions.count == 1)
    let decoded = try Solana.SystemInstruction.decodeTransferWithSeed(instruction: transaction.instructions[0])
    #expect(params == decoded)
  }
  
  @Test("allocate")
  func allocate() async throws {
    let params = try Solana.SystemProgram.AllocateParams(
      accountPubkey: .unique(),
      space: 42
    )
    let transaction = try Solana.Transaction().adding(
      instructions: Solana.SystemProgram.allocate(params: params)
    )
    #expect(transaction.instructions.count == 1)
    let decoded = try Solana.SystemInstruction.decodeAllocate(instruction: transaction.instructions[0])
    #expect(params == decoded)
  }
  
  @Test("allocateWithSeed")
  func allocateWithSeed() async throws {
    let params = try Solana.SystemProgram.AllocateWithSeedParams(
      accountPubkey: .unique(),
      basePubkey: .unique(),
      seed: "你好",
      space: 42,
      programId: .unique()
    )
    let transaction = try Solana.Transaction().adding(
      instructions: Solana.SystemProgram.allocate(params: params)
    )
    #expect(transaction.instructions.count == 1)
    let decoded = try Solana.SystemInstruction.decodeAllocateWithSeed(instruction: transaction.instructions[0])
    #expect(params == decoded)
  }
  
  @Test("assign")
  func assign() async throws {
    let params = try Solana.SystemProgram.AssignParams(
      accountPubkey: .unique(),
      programId: .unique()
    )
    let transaction = try Solana.Transaction().adding(
      instructions: Solana.SystemProgram.assign(params: params)
    )
    #expect(transaction.instructions.count == 1)
    let decoded = try Solana.SystemInstruction.decodeAssign(instruction: transaction.instructions[0])
    #expect(params == decoded)
  }
  
  @Test("assignWithSeed")
  func assignWithSeed() async throws {
    let params = try Solana.SystemProgram.AssignWithSeedParams(
      accountPubkey: .unique(),
      basePubkey: .unique(),
      seed: "你好",
      programId: .unique()
    )
    let transaction = try Solana.Transaction().adding(
      instructions: Solana.SystemProgram.assign(params: params)
    )
    #expect(transaction.instructions.count == 1)
    let decoded = try Solana.SystemInstruction.decodeAssignWithSeed(instruction: transaction.instructions[0])
    #expect(params == decoded)
  }
  
  @Test("createAccountWithSeed")
  func createAccountWithSeed() async throws {
    let fromPubKey: PublicKey = try .unique()
    let params = try Solana.SystemProgram.CreateAccountWithSeedParams(
      fromPubkey: fromPubKey,
      newAccountPubkey: .unique(),
      basePubkey: fromPubKey,
      seed: "hi there",
      lamports: 123,
      space: 0,
      programId: Solana.SystemProgram.programId
    )
    let transaction = try Solana.Transaction().adding(
      instructions: Solana.SystemProgram.createAccountWithSeed(params: params)
    )
    #expect(transaction.instructions.count == 1)
    let decoded = try Solana.SystemInstruction.decodeCreateAccountWithSeed(instruction: transaction.instructions[0])
    #expect(params == decoded)
  }
  
  @Test("createNonceAccount")
  func createNonceAccount() async throws {
    let fromPubKey: PublicKey = try .unique()
    let params = try Solana.SystemProgram.CreateNonceAccountParams(
      fromPubkey: fromPubKey,
      noncePubkey: .unique(),
      authorizedPubkey: fromPubKey,
      lamports: 123
    )
    let transaction = try Solana.Transaction().adding(
      transaction: Solana.SystemProgram.createNonceAccount(params: params)
    )
    #expect(transaction.instructions.count == 2)
    let createInstruction = transaction.instructions[0]
    let initInstruction = transaction.instructions[1]
    
    let createParams = Solana.SystemProgram.CreateAccountParams(
      fromPubkey: params.fromPubkey,
      newAccountPubkey: params.noncePubkey,
      lamports: params.lamports,
      space: .NONCE_ACCOUNT_LENGTH,
      programId: Solana.SystemProgram.programId
    )
    let decodedCreateParams = try Solana.SystemInstruction.decodeCreateAccount(instruction: createInstruction)
    #expect(createParams == decodedCreateParams)
    
    let initParams = Solana.SystemProgram.InitializeNonceParams(
      noncePubkey: params.noncePubkey,
      authorizedPubkey: fromPubKey
    )
    let decodedInitParams = try Solana.SystemInstruction.decodeNonceInitialize(instruction: initInstruction)
    #expect(initParams == decodedInitParams)
  }
  
  @Test("createNonceAccount with seed")
  func createNonceAccountWithSeed() async throws {
    let fromPubKey: PublicKey = try .unique()
    let params = try Solana.SystemProgram.CreateNonceAccountWithSeedParams(
      fromPubkey: fromPubKey,
      noncePubkey: .unique(),
      authorizedPubkey: fromPubKey,
      lamports: 123,
      basePubkey: fromPubKey,
      seed: "hi there"
    )
    let transaction = try Solana.Transaction().adding(
      transaction: Solana.SystemProgram.createNonceAccount(params: params)
    )
    #expect(transaction.instructions.count == 2)
    let createInstruction = transaction.instructions[0]
    let initInstruction = transaction.instructions[1]
    
    let createParams = Solana.SystemProgram.CreateAccountWithSeedParams(
      fromPubkey: params.fromPubkey,
      newAccountPubkey: params.noncePubkey,
      basePubkey: fromPubKey,
      seed: "hi there",
      lamports: params.lamports,
      space: .NONCE_ACCOUNT_LENGTH,
      programId: Solana.SystemProgram.programId
    )
    let decodedCreateParams = try Solana.SystemInstruction.decodeCreateAccountWithSeed(instruction: createInstruction)
    #expect(createParams == decodedCreateParams)
    
    let initParams = Solana.SystemProgram.InitializeNonceParams(
      noncePubkey: params.noncePubkey,
      authorizedPubkey: fromPubKey
    )
    let decodedInitParams = try Solana.SystemInstruction.decodeNonceInitialize(instruction: initInstruction)
    #expect(initParams == decodedInitParams)
  }
  
  @Test("nonceAdvance")
  func nonceAdvance() async throws {
    let params = try Solana.SystemProgram.AdvanceNonceParams(
      noncePubkey: .unique(),
      authorizedPubkey: .unique()
    )
    let instruction = Solana.SystemProgram.nonceAdvance(params: params)
    let decoded = try Solana.SystemInstruction.decodeNonceAdvance(instruction: instruction)
    #expect(params == decoded)
  }
  
  @Test("nonceWithdraw")
  func nonceWithdraw() async throws {
    let params = try Solana.SystemProgram.WithdrawNonceParams(
      noncePubkey: .unique(),
      authorizedPubkey: .unique(),
      toPubkey: .unique(),
      lamports: 123
    )
    let transaction = try Solana.Transaction().adding(
      instructions: Solana.SystemProgram.nonceWithdraw(params: params)
    )
    #expect(transaction.instructions.count == 1)
    let decoded = try Solana.SystemInstruction.decodeNonceWithdraw(instruction: transaction.instructions[0])
    #expect(params == decoded)
  }
  
  @Test("nonceAuthorize")
  func nonceAuthorize() async throws {
    let params = try Solana.SystemProgram.AuthorizeNonceParams(
      noncePubkey: .unique(),
      authorizedPubkey: .unique(),
      newAuthorizedPubkey: .unique()
    )
    let transaction = try Solana.Transaction().adding(
      instructions: Solana.SystemProgram.nonceAuthorize(params: params)
    )
    #expect(transaction.instructions.count == 1)
    let decoded = try Solana.SystemInstruction.decodeNonceAuthorize(instruction: transaction.instructions[0])
    #expect(params == decoded)
  }
}
