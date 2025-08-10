//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import Testing
@testable import mew_wallet_ios_kit_solana
import CryptoSwift
import mew_wallet_ios_kit

@Suite("Solana.Transaction compileMessage tests")
fileprivate struct SolanaTransactionCompileMessageTests {
  @Test("accountKeys are ordered")
  func accountKeysAreOrdered() async throws {
    // These pubkeys are chosen specially to be in sort order.
    let payer = try PublicKey(base58: "3qMLYYyNvaxNZP7nW8u5abHMoJthYqQehRLbFVPNNcvQ", network: .solana)
    let accountWritableSigner2 = try PublicKey(base58: "3XLtLo5Z4DG8b6PteJidF6kFPNDfxWjxv4vTLrjaHTvd", network: .solana)
    let accountWritableSigner3 = try PublicKey(base58: "4rvqGPb4sXgyUKQcvmPxnWEZTTiTqNUZ2jjnw7atKVxa", network: .solana)
    let accountSigner4 = try PublicKey(base58: "5oGjWjyoKDoXGpboGBfqm9a5ZscyAjRi3xuGYYu1ayQg", network: .solana)
    let accountSigner5 = try PublicKey(base58: "65Rkc3VmDEV6zTRGtgdwkTcQUxDJnJszj2s4WoXazYpC", network: .solana)
    let accountWritable6 = try PublicKey(base58: "72BxBZ9eD9Ue6zoJ9bzfit7MuaDAnq1qhirgAoFUXz9q", network: .solana)
    let accountWritable7 = try PublicKey(base58: "BtYrPUeVphVgRHJkf2bKz8DLRxJdQmZyANrTM12xFqZL", network: .solana)
    let accountRegular8 = try PublicKey(base58: "Di1MbqFwpodKzNrkjGaUHhXC4TJ1SHUAxo9agPZphNH1", network: .solana)
    let accountRegular9 = try PublicKey(base58: "DYzzsfHTgaNhCgn7wMaciAYuwYsGqtVNg9PeFZhH93Pc", network: .solana)
    let programId = try PublicKey(base58: "Fx9svCTdxnACvmEmx672v2kP1or4G1zC73tH7XsXbKkP", network: .solana)
    
    let recentBlockhash = "5V686myXsj1iXtj3NZUs3W9wTEcdugQW9w1ykARBchk3"
    
    var transaction = try Solana.Transaction(blockhash: recentBlockhash, lastValidBlockHeight: 9999)
      .adding(instructions: [
        .init(
          keys: [
            // Regular accounts
            .init(pubkey: accountRegular9, isSigner: false, isWritable: false),
            .init(pubkey: accountRegular8, isSigner: false, isWritable: false),
            // Writable accounts
            .init(pubkey: accountWritable7, isSigner: false, isWritable: true),
            .init(pubkey: accountWritable6, isSigner: false, isWritable: true),
            // Signers
            .init(pubkey: accountSigner5, isSigner: true, isWritable: false),
            .init(pubkey: accountSigner4, isSigner: true, isWritable: false),
            // Writable Signers
            .init(pubkey: accountWritableSigner3, isSigner: true, isWritable: true),
            .init(pubkey: accountWritableSigner2, isSigner: true, isWritable: true),
            // Payer.
            .init(pubkey: payer, isSigner: true, isWritable: true),
          ],
          programId: programId
        )
      ])
    transaction.feePayer = payer
    
    let message = try transaction.compileMessage()
    
    // Payer comes first.
    #expect(message.accountKeys[0] == payer)
    // Writable signers come next, in pubkey order.
    #expect(message.accountKeys[1] == accountWritableSigner2)
    #expect(message.accountKeys[2] == accountWritableSigner3)
    // Signers come next, in pubkey order.
    #expect(message.accountKeys[3] == accountSigner4)
    #expect(message.accountKeys[4] == accountSigner5)
    // Writable accounts come next, in pubkey order.
    #expect(message.accountKeys[5] == accountWritable6)
    #expect(message.accountKeys[6] == accountWritable7)
    // Everything else afterward, in pubkey order.
    #expect(message.accountKeys[7] == accountRegular8)
    #expect(message.accountKeys[8] == accountRegular9)
    #expect(message.accountKeys[9] == programId)
  }
  
  @Test("accountKeys collapses signedness and writability of duplicate accounts")
  func accountKeysCollapsesSignednessAndWritabilityOfDuplicateAccounts() async throws {
    // These pubkeys are chosen specially to be in sort order.
    let payer = try PublicKey(base58: "2eBgaMN8dCnCjx8B8Wrwk974v5WHwA6Vvj4N2mW9KDyt", network: .solana)
    let account2 = try PublicKey(base58: "DL8FErokCN7rerLdmJ7tQvsL1FsqDu1sTKLLooWmChiW", network: .solana)
    let account3 = try PublicKey(base58: "EdPiTYbXFxNrn1vqD7ZdDyauRKG4hMR6wY54RU1YFP2e", network: .solana)
    let account4 = try PublicKey(base58: "FThXbyKK4kYJBngSSuvo9e6kc7mwPHEgw4V8qdmz1h3k", network: .solana)
    let programId = try PublicKey(base58: "Gcatgv533efD1z2knsH9UKtkrjRWCZGi12f8MjNaDzmN", network: .solana)
    let account5 = try PublicKey(base58: "rBtwG4bx85Exjr9cgoupvP1c7VTe7u5B36rzCg1HYgi", network: .solana)
    
    let recentBlockhash = "5V686myXsj1iXtj3NZUs3W9wTEcdugQW9w1ykARBchk3"
    var transaction = try Solana.Transaction(blockhash: recentBlockhash, lastValidBlockHeight: 9999)
      .adding(instructions: [
        .init(
          keys: [
            // Should sort last.
            .init(pubkey: account5, isSigner: false, isWritable: false),
            .init(pubkey: account5, isSigner: false, isWritable: false),
            // Should be considered writeable.
            .init(pubkey: account4, isSigner: false, isWritable: false),
            .init(pubkey: account4, isSigner: false, isWritable: true),
            // Should be considered a signer.
            .init(pubkey: account3, isSigner: false, isWritable: false),
            .init(pubkey: account3, isSigner: true, isWritable: false),
            // Should be considered a writable signer.
            .init(pubkey: account2, isSigner: false, isWritable: true),
            .init(pubkey: account2, isSigner: true, isWritable: false),
            // Payer.
            .init(pubkey: payer, isSigner: true, isWritable: true),
          ],
          programId: programId
        )
      ])
    transaction.feePayer = payer

    let message = try transaction.compileMessage()
    // Payer comes first.
    #expect(message.accountKeys[0] == payer)
    // Writable signer comes first.
    #expect(message.accountKeys[1] == account2)
    // Signer comes next.
    #expect(message.accountKeys[2] == account3)
    // Writable account comes next.
    #expect(message.accountKeys[3] == account4)
    // Regular accounts come last.
    #expect(message.accountKeys[4] == programId)
    #expect(message.accountKeys[5] == account5)
  }
  
  @Test("prepends the nonce advance instruction when compiling nonce-based transactions")
  func prependsTheNonceAdvanceInstructionWhenCompilingNonceBasedTransactions() async throws {
    let nonce = try PublicKey(hex: "0x01", network: .solana)
    let nonceAuthority = try PublicKey(hex: "0x02", network: .solana)
    let nonceInfo = try Solana.NonceInformation(
      nonce: nonce,
      nonceInstruction: Solana.SystemProgram.nonceAdvance(
        params: .init(
          noncePubkey: nonce,
          authorizedPubkey: nonceAuthority
        )
      )
    )
    let transaction = try Solana.Transaction(
      feePayer: nonceAuthority,
      nonceInfo: nonceInfo
    ).adding(
      instructions: Solana.SystemProgram.transfer(
        params: .init(
          fromPubkey: nonceAuthority,
          toPubkey: PublicKey(hex: "0x03", network: .solana),
          lamports: 1
        )
      )
    )
    
    let message = try transaction.compileMessage()
    let programIdIndex: Int = {
      var found = -1
      for (i, key) in message.accountKeys.enumerated() {
        if key == Solana.SystemProgram.programId {
          found = i
          break
        }
      }
      return found
    }()
    #expect(message.instructions.count == 2)
    #expect(message.instructions[0].accounts == [1, 4, 0])
    #expect(message.instructions[0].data == Data(UInt32(4).littleEndianBytes))
    #expect(message.instructions[0].programIdIndex == programIdIndex)
  }
  
  @Test("does not prepend the nonce advance instruction when compiling nonce-based transactions if it is already there")
  func doesNotPrependTheNonceAdvanceInstructionWhenCompilingNonceBasedTransactionsIfItIsAlreadyThere() async throws {
    let nonce = try PublicKey(hex: "0x01", network: .solana)
    let nonceAuthority = try PublicKey(hex: "0x02", network: .solana)
    let nonceInfo = try Solana.NonceInformation(
      nonce: nonce,
      nonceInstruction: Solana.SystemProgram.nonceAdvance(
        params: .init(
          noncePubkey: nonce,
          authorizedPubkey: nonceAuthority
        )
      )
    )
    let transaction = try Solana.Transaction(feePayer: nonceAuthority, nonceInfo: nonceInfo)
      .adding(instructions: nonceInfo.nonceInstruction)
      .adding(
        instructions: Solana.SystemProgram.transfer(
          params: .init(
            fromPubkey: nonceAuthority,
            toPubkey: PublicKey(hex: "0x03", network: .solana),
            lamports: 1
          )
        )
      )
    
    let message = try transaction.compileMessage()
    let programIdIndex: Int = {
      var found = -1
      for (i, key) in message.accountKeys.enumerated() {
        if key == Solana.SystemProgram.programId {
          found = i
          break
        }
      }
      return found
    }()
    #expect(message.instructions.count == 2)
    #expect(message.instructions[0].accounts == [1, 4, 0])
    #expect(message.instructions[0].data == Data(UInt32(4).littleEndianBytes))
    #expect(message.instructions[0].programIdIndex == programIdIndex)
  }
}
