//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import Testing
import mew_wallet_ios_kit_solana
@testable import mew_wallet_ios_kit_solana_sign
import CryptoSwift
import mew_wallet_ios_kit
import mew_wallet_ios_tweetnacl

@Suite("Solana.Transaction compileMessage tests")
fileprivate struct SolanaTransactionCompileMessageTests {
  @Test("payer is first account meta")
  func payerIsFirstAccountMeta() async throws {
    let payer = PrivateKey(privateKey: Data(hex: "8159abe20202e9aac131b34b41a8e9f9bc038fad865349382a175afee5133ae7"), network: .solana)
    let other = PrivateKey(privateKey: Data(hex: "2e070ce3a9f6b2626aaf797beefef58948bf172ea91557d0cf5164f2d5cba59a"), network: .solana)
    
    let recentBlockhash = "3pMGMtrafGShCntKUsQwnpbKVK2fV8FcvdfiBbQ8w7Tr"
    let programId = try PublicKey(base58: "8zX1MGJwrh4BB3iAb9q5pyYon3MmmyiZ4R3z6z3XZX4h", network: .solana)
    var transaction = try Solana.Transaction(blockhash: recentBlockhash, lastValidBlockHeight: 9999)
      .adding(instructions: [
        .init(
          keys: [
            .init(pubkey: other.publicKey(), isSigner: true, isWritable: true),
            .init(pubkey: payer.publicKey(), isSigner: true, isWritable: true)
          ],
          programId: programId
        )
      ])
    
    try transaction.sign(signers: payer, other)
    
    let message = try transaction.compileMessage()
    #expect(try message.accountKeys[0] == payer.publicKey())
    #expect(try message.accountKeys[1] == other.publicKey())
    #expect(message.header.numRequiredSignatures == 2)
    #expect(message.header.numReadonlySignedAccounts == 0)
    #expect(message.header.numReadonlyUnsignedAccounts == 1)
    #expect(transaction.signatures[0].signature == Data(hex: "a1719b74c496fe6b962cdc6eae7f635e8d5ec4b354397ad6bb9e639791b560c517c58d5efcf7d8f5f032c58151f5f53c6c06f7a3922367e1f8d75444186d4d04"))
    #expect(try transaction.signatures[0].publicKey == payer.publicKey())
    #expect(transaction.signatures[1].signature == Data(hex: "f64157c75a44c6b8361a66721bef61060ef243e29cf999c3e3a38fa48c81dc055931777c0518b142d1faced4c0d229cf387de22ed9708530df3bdf90dba01b06"))
    #expect(try transaction.signatures[1].publicKey == other.publicKey())
  }
  
  @Test("payer is writable")
  func payerIsWritable() async throws {
    let payer = PrivateKey(privateKey: Data(hex: "8159abe20202e9aac131b34b41a8e9f9bc038fad865349382a175afee5133ae7"), network: .solana)
    let recentBlockhash = "3pMGMtrafGShCntKUsQwnpbKVK2fV8FcvdfiBbQ8w7Tr"
    let programId = try PublicKey(base58: "8zX1MGJwrh4BB3iAb9q5pyYon3MmmyiZ4R3z6z3XZX4h", network: .solana)
    
    var transaction = try Solana.Transaction(blockhash: recentBlockhash, lastValidBlockHeight: 9999)
      .adding(instructions: [
        .init(
          keys: [
            .init(pubkey: payer.publicKey(), isSigner: true, isWritable: false)
          ],
          programId: programId
        )
      ])
    
    try transaction.sign(signers: payer)
    
    let message = try transaction.compileMessage()
    
    #expect(try message.accountKeys[0] == payer.publicKey())
    #expect(message.header.numRequiredSignatures == 1)
    #expect(message.header.numReadonlySignedAccounts == 0)
    #expect(message.header.numReadonlyUnsignedAccounts == 1)
  }
  
  @Test("validation")
  func validation() async throws {
    let payer = PrivateKey(privateKey: Data(hex: "8159abe20202e9aac131b34b41a8e9f9bc038fad865349382a175afee5133ae7"), network: .solana)
    let other = PrivateKey(privateKey: Data(hex: "2e070ce3a9f6b2626aaf797beefef58948bf172ea91557d0cf5164f2d5cba59a"), network: .solana)
    let recentBlockhash = "3pMGMtrafGShCntKUsQwnpbKVK2fV8FcvdfiBbQ8w7Tr"
    
    var transaction = Solana.Transaction()
    #expect(throws: Solana.Transaction.Error.recentBlockhashRequired, performing: {
      try transaction.compileMessage()
    })
    transaction.recentBlockhash = recentBlockhash
    
    #expect(throws: Solana.Transaction.Error.feePayerRequired, performing: {
      try transaction.compileMessage()
    })
    
    try transaction.setSigners(signers: [payer.publicKey(), other.publicKey()])
    try #expect(throws: Solana.Transaction.Error.unknownSigner(other.publicKey()), performing: {
      try transaction.compileMessage()
    })
    
    // Expect compile to succeed with implicit fee payer from signers
    try transaction.setSigners(signers: [payer.publicKey()])
    #expect(throws: Never.self, performing: {
      try transaction.compileMessage()
    })
    
    // Expect compile to succeed with fee payer and no signers
    transaction.signatures = []
    transaction.feePayer = try payer.publicKey()
    #expect(throws: Never.self, performing: {
      try transaction.compileMessage()
    })
  }
  
  @Test("uses the nonce as the recent blockhash when compiling nonce-based transactions")
  func usesTheNonceAsTheRecentBlockhashWhenCompilingNonceBasedTransactions() async throws {
    let nonce = try PublicKey(hex: "0x01", network: .solana)
    let nonceAuthority = try PublicKey(hex: "0x02", network: .solana)
    let nonceInfo = try Solana.NonceInformation(
      nonce: nonce,
      nonceInstruction: Solana.SystemProgram.nonceAdvance(
        params: .init(noncePubkey: nonce, authorizedPubkey: nonceAuthority)
      )
    )
    let transaction = Solana.Transaction(feePayer: nonceAuthority, nonceInfo: nonceInfo)
    let message = try transaction.compileMessage()
    #expect(message.recentBlockhash == nonce.address()?.address)
  }
  
  @Test("partialSign")
  func partialSign() async throws {
    let account1 = PrivateKey(privateKey: Data(hex: "59a1aceb689ed3fe7adc1b44d78be38d0f1f0ec99263ce6199fbb369722a773c"), network: .solana)
    let account2 = PrivateKey(privateKey: Data(hex: "d4db5154833691176b4172b6dce524d40a035698738400ca6d131e8f6decc764"), network: .solana)
    let recentBlockhash = "9U2wM3MUToUCRiBsR6zAcnqJw43kcXSxp27QxsKEJSBf"
    
    let transfer = try Solana.SystemProgram.transfer(
      params: .init(
        fromPubkey: account1.publicKey(),
        toPubkey: account2.publicKey(),
        lamports: 123
      )
    )
    
    var transaction = try Solana.Transaction(blockhash: recentBlockhash, lastValidBlockHeight: 9999)
      .adding(instructions: transfer)
    
    try transaction.sign(signers: account1, account2)
    let serialized = try transaction.serialize()
    #expect(serialized == Data(hex: "02c11bb529ce91cd1325556573862ea67ffd1c941f5acbff6246909e517768681375a214db732d6a5b8140f8c9fd21b173872571c5ae8c1703ba36e499ffcdf603b09d91d092a237fe97cfde7b62fe4c7450dbdf27e72d9b2e80e8240cfe7d50386030c289f57661e44d55f4b0786ca64f2fa8edec6ba27e56e24003c521b27204020001037dca5e0f34700786cefd219b3a1310e5b52913b7404c89d31fad7ee632dcefa61ed68ea990632c02ef770046016e3b1c88ce995a656a74463a7eca61db0448cd00000000000000000000000000000000000000000000000000000000000000007dca5e0f34700786cefd219b3a1310e5b52913b7404c89d31fad7ee632dcefa601020200010c020000007b00000000000000"))
    
    var partialTransaction = try Solana.Transaction(blockhash: recentBlockhash, lastValidBlockHeight: 9999)
      .adding(instructions: transfer)
    
    try partialTransaction.setSigners(signers: account1.publicKey(), account2.publicKey())
    #expect(partialTransaction.signatures[0].signature == nil)
    #expect(partialTransaction.signatures[1].signature == nil)
    
    try partialTransaction.partialSign(signers: account1)
    #expect(partialTransaction.signatures[0].signature != nil)
    #expect(partialTransaction.signatures[1].signature == nil)
    
    #expect(throws: Solana.Transaction.ValidationErrors.self, performing: {
      try partialTransaction.serialize()
    })
    #expect(throws: Never.self, performing: {
      try partialTransaction.serialize(requireAllSignatures: false)
    })
    try partialTransaction.partialSign(signers: account2)
    #expect(partialTransaction.signatures[0].signature != nil)
    #expect(partialTransaction.signatures[1].signature != nil)
    #expect(throws: Never.self, performing: {
      try partialTransaction.serialize()
    })
    #expect(partialTransaction == transaction)
    partialTransaction.signatures[0].signature = Data(repeating: 1, count: 64)
    #expect(throws: Solana.Transaction.ValidationErrors.self, performing: {
      try partialTransaction.serialize(requireAllSignatures: false)
    })
    #expect(throws: Never.self, performing: {
      try partialTransaction.serialize(requireAllSignatures: false, verifySignatures: false)
    })
  }
}

@Suite("Solana.Transaction dedup tests")
fileprivate struct SolanaTransactionDedupTests {
  let payer: PrivateKey = PrivateKey(privateKey: Data(hex: "59a1aceb689ed3fe7adc1b44d78be38d0f1f0ec99263ce6199fbb369722a773c"), network: .solana)
  var duplicate1: PrivateKey { payer }
  var duplicate2: PrivateKey { payer }
  let recentBlockhash = "9U2wM3MUToUCRiBsR6zAcnqJw43kcXSxp27QxsKEJSBf"
  let programId = try! PublicKey(base58: "3pMGMtrafGShCntKUsQwnpbKVK2fV8FcvdfiBbQ8w7Tr", network: .solana)
  
  @Test("setSigners")
  func setSigners() async throws {
    var transaction = try Solana.Transaction(blockhash: recentBlockhash, lastValidBlockHeight: 9999)
      .adding(instructions: [
        .init(
          keys: [
            .init(pubkey: duplicate1.publicKey(), isSigner: true, isWritable: true),
            .init(pubkey: payer.publicKey(), isSigner: false, isWritable: true),
            .init(pubkey: duplicate2.publicKey(), isSigner: true, isWritable: false)
          ],
          programId: programId
        )
      ])
    
    try transaction.setSigners(signers: payer.publicKey(), duplicate1.publicKey(), duplicate2.publicKey())
    
    #expect(transaction.signatures.count == 1)
    #expect(try transaction.signatures[0].publicKey == payer.publicKey())
    
    let message = try transaction.compileMessage()
    #expect(try message.accountKeys[0] == payer.publicKey())
    #expect(message.header.numRequiredSignatures == 1)
    #expect(message.header.numReadonlySignedAccounts == 0)
    #expect(message.header.numReadonlyUnsignedAccounts == 1)
  }
  
  @Test("sign")
  func sign() async throws {
    var transaction = try Solana.Transaction(blockhash: recentBlockhash, lastValidBlockHeight: 9999)
      .adding(instructions: [
        .init(
          keys: [
            .init(pubkey: duplicate1.publicKey(), isSigner: true, isWritable: true),
            .init(pubkey: payer.publicKey(), isSigner: false, isWritable: true),
            .init(pubkey: duplicate2.publicKey(), isSigner: true, isWritable: false)
          ],
          programId: programId
        )
      ])
    
    try transaction.sign(signers: payer, duplicate1, duplicate2)
    
    #expect(transaction.signatures.count == 1)
    #expect(try transaction.signatures[0].publicKey == payer.publicKey())
    
    let message = try transaction.compileMessage()
    #expect(try message.accountKeys[0] == payer.publicKey())
    #expect(message.header.numRequiredSignatures == 1)
    #expect(message.header.numReadonlySignedAccounts == 0)
    #expect(message.header.numReadonlyUnsignedAccounts == 1)
  }
}

@Suite("Solana.Transaction other tests")
fileprivate struct SolanaTransactionOtherTests {
  @Test("transfer signatures")
  func transferSignatures() async throws {
    let account1 = PrivateKey(privateKey: Data(hex: "59a1aceb689ed3fe7adc1b44d78be38d0f1f0ec99263ce6199fbb369722a773c"), network: .solana)
    let account2 = PrivateKey(privateKey: Data(hex: "d4db5154833691176b4172b6dce524d40a035698738400ca6d131e8f6decc764"), network: .solana)
    let recentBlockhash = "9U2wM3MUToUCRiBsR6zAcnqJw43kcXSxp27QxsKEJSBf"
    
    let transfer1 = try Solana.SystemProgram.transfer(
      params: .init(
        fromPubkey: account1.publicKey(),
        toPubkey: account2.publicKey(),
        lamports: 123
      )
    )
    let transfer2 = try Solana.SystemProgram.transfer(
      params: .init(
        fromPubkey: account2.publicKey(),
        toPubkey: account1.publicKey(),
        lamports: 123
      )
    )
    var orgTransaction = try Solana.Transaction(blockhash: recentBlockhash, lastValidBlockHeight: 9999)
      .adding(instructions: transfer1, transfer2)
    try orgTransaction.sign(signers: account1, account2)
    
    let newTransaction = try Solana.Transaction(signatures: orgTransaction.signatures, blockhash: recentBlockhash, lastValidBlockHeight: 9999)
      .adding(instructions: transfer1, transfer2)
    
    #expect(newTransaction == orgTransaction)
  }
  
  @Test("use nonce")
  func useNonce() async throws {
    let account1 = PrivateKey(privateKey: Data(hex: "59a1aceb689ed3fe7adc1b44d78be38d0f1f0ec99263ce6199fbb369722a773c"), network: .solana)
    let account2 = PrivateKey(privateKey: Data(hex: "d4db5154833691176b4172b6dce524d40a035698738400ca6d131e8f6decc764"), network: .solana)
    let nonceAccount = PrivateKey(privateKey: Data(hex: "8159abe20202e9aac131b34b41a8e9f9bc038fad865349382a175afee5133ae7"), network: .solana)
    let nonce = try account2.publicKey().address()!.address
    
    let nonceInfo = try Solana.NonceInformation(
      nonce: nonce,
      nonceInstruction: Solana.SystemProgram.nonceAdvance(
        params: .init(
          noncePubkey: nonceAccount.publicKey(),
          authorizedPubkey: account1.publicKey()
        )
      )
    )
    
    var transferTransaction = try Solana.Transaction(nonceInfo: nonceInfo)
      .adding(
        instructions: Solana.SystemProgram.transfer(
          params: .init(
            fromPubkey: account1.publicKey(),
            toPubkey: account2.publicKey(),
            lamports: 123
          )
        )
      )
    
    try transferTransaction.sign(signers: account1)
    #expect(transferTransaction.instructions.count == 1)
    #expect(transferTransaction.recentBlockhash == nil)
    
    let stakeAccount = PrivateKey(privateKey: Data(hex: "2e070ce3a9f6b2626aaf797beefef58948bf172ea91557d0cf5164f2d5cba59a"), network: .solana)
    let voteAccount = PrivateKey(privateKey: Data(hex: "cebf7a0b3d439f9b8798504208e4dc397419a02fa8381f5e7afccec838891765"), network: .solana)
    var stakeTransaction = try Solana.Transaction(nonceInfo: nonceInfo)
      .adding(
        transaction: Solana.StakeProgram.delegate(
          params: .init(
            stakePubkey: stakeAccount.publicKey(),
            authorizedPubkey: account1.publicKey(),
            votePubkey: voteAccount.publicKey()
          )
        )
      )
    
    try stakeTransaction.sign(signers: account1)
    #expect(stakeTransaction.instructions.count == 1)
    #expect(stakeTransaction.recentBlockhash == nil)
  }
  
  @Test("parse wire format and serialize")
  func parseWireFormatAndSerialize() async throws {
    let sender = PrivateKey(privateKey: Data(repeating: 0x08, count: 32), network: .solana) // Arbitrary known account
    try #expect(sender.publicKey().data() == Data(hex: "1398f62c6d1a457c51ba6a4b5f3dbd2f69fca93216218dc8997e416bd17d93ca"))
    let recentBlockhash = "EETubP5AKHgjPAhzPAFcb8BAY1hMH639CWCFTqi3hq1k" // Arbitrary known recentBlockhash
    let recipient = try PublicKey(base58: "J3dxNj7nDRRqRRXuEMynDG57DkZK4jYRuv3Garmb1i99", network: .solana) // Arbitrary known public key
    let transfer = try Solana.SystemProgram.transfer(
      params: .init(
        fromPubkey: sender.publicKey(),
        toPubkey: recipient,
        lamports: 49
      )
    )
    
    var expectedTransaction = try Solana.Transaction(
      feePayer: sender.publicKey(),
      blockhash: recentBlockhash,
      lastValidBlockHeight: 9999
    ).adding(instructions: transfer)
    try expectedTransaction.sign(signers: sender)
    
    let expecedSerializedTransaction = try expectedTransaction.serialize()
    
    let serializedTransaction = Data(base64Encoded: "AVuErQHaXv0SG0/PchunfxHKt8wMRfMZzqV0tkC5qO6owYxWU2v871AoWywGoFQr4z+q/7mE8lIufNl/kxj+nQ0BAAEDE5j2LG0aRXxRumpLXz29L2n8qTIWIY3ImX5Ba9F9k8r9Q5/Mtmcn8onFxt47xKj+XdXXd3C8j/FcPu7csUrz/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAxJrndgN4IFTxep3s6kO0ROug7bEsbx0xxuDkqEvwUusBAgIAAQwCAAAAMQAAAAAAAAA=")!
    
    let decoder = Solana.ShortVecDecoder()
    var deserializedTransaction = try decoder.decode(Solana.Transaction.self, from: serializedTransaction)
    
    let deserializedSerializedTransaction = try deserializedTransaction.serialize()
    
    #expect(expecedSerializedTransaction == serializedTransaction)
    #expect(deserializedSerializedTransaction == serializedTransaction)
  }
  
  @Test("serialize unsigned transaction")
  func serializeUnsignedTransaction() async throws {
    let sender = PrivateKey(privateKey: Data(repeating: 0x08, count: 32), network: .solana) // Arbitrary known account
    try #expect(sender.publicKey().data() == Data(hex: "1398f62c6d1a457c51ba6a4b5f3dbd2f69fca93216218dc8997e416bd17d93ca"))
    let recentBlockhash = "EETubP5AKHgjPAhzPAFcb8BAY1hMH639CWCFTqi3hq1k" // Arbitrary known recentBlockhash
    let recipient = try PublicKey(base58: "J3dxNj7nDRRqRRXuEMynDG57DkZK4jYRuv3Garmb1i99", network: .solana) // Arbitrary known public key
    let transfer = try Solana.SystemProgram.transfer(
      params: .init(
        fromPubkey: sender.publicKey(),
        toPubkey: recipient,
        lamports: 49
      )
    )
    
    var expectedTransaction = try Solana.Transaction(
      blockhash: recentBlockhash,
      lastValidBlockHeight: 9999
    ).adding(instructions: transfer)
    
    // Empty signature array fails.
    #expect(expectedTransaction.signatures.isEmpty)
    #expect(throws: Solana.Transaction.Error.feePayerRequired, performing: {
      try expectedTransaction.serialize()
    })
    #expect(throws: Solana.Transaction.Error.feePayerRequired, performing: {
      try expectedTransaction.serialize(verifySignatures: false)
    })
    #expect(throws: Solana.Transaction.Error.feePayerRequired, performing: {
      try expectedTransaction.serializeMessage()
    })
    expectedTransaction.feePayer = try sender.publicKey()
    
    // Serializing without signatures is allowed if sigverify disabled.
    #expect(throws: Never.self, performing: {
      try expectedTransaction.serialize(verifySignatures: false)
    })
    
    // Serializing the message is allowed when signature array has null signatures
    #expect(throws: Never.self, performing: {
      try expectedTransaction.serializeMessage()
    })
    
    let expectedSerializationWithNoSignatures = Data(base64Encoded: "AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAEDE5j2LG0aRXxRumpLXz29L2n8qTIWIY3ImX5Ba9F9k8r9Q5/Mtmcn8onFxt47xKj+XdXXd3C8j/FcPu7csUrz/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAxJrndgN4IFTxep3s6kO0ROug7bEsbx0xxuDkqEvwUusBAgIAAQwCAAAAMQAAAAAAAAA=")
    try #expect(expectedTransaction.serialize(verifySignatures: false) == expectedSerializationWithNoSignatures)
    
    // Properly signed transaction succeeds
    try expectedTransaction.partialSign(signers: sender)
    #expect(expectedTransaction.signatures.count == 1)
    
    let expectedSerialization = Data(base64Encoded: "AVuErQHaXv0SG0/PchunfxHKt8wMRfMZzqV0tkC5qO6owYxWU2v871AoWywGoFQr4z+q/7mE8lIufNl/kxj+nQ0BAAEDE5j2LG0aRXxRumpLXz29L2n8qTIWIY3ImX5Ba9F9k8r9Q5/Mtmcn8onFxt47xKj+XdXXd3C8j/FcPu7csUrz/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAxJrndgN4IFTxep3s6kO0ROug7bEsbx0xxuDkqEvwUusBAgIAAQwCAAAAMQAAAAAAAAA=")
    try #expect(expectedTransaction.serialize() == expectedSerialization)
    #expect(expectedTransaction.signatures.count == 1)
  }
  
  @Test("throws for invalid signatures")
  func throwsForInvalidSignatures() async throws {
    let sender = PrivateKey(privateKey: Data(repeating: 0x08, count: 32), network: .solana) // Arbitrary known account
    let senderPublicKey = try sender.publicKey()
    try #expect(sender.publicKey().data() == Data(hex: "1398f62c6d1a457c51ba6a4b5f3dbd2f69fca93216218dc8997e416bd17d93ca"))
    let recentBlockhash = "EETubP5AKHgjPAhzPAFcb8BAY1hMH639CWCFTqi3hq1k" // Arbitrary known recentBlockhash
    let recipient = try PublicKey(base58: "J3dxNj7nDRRqRRXuEMynDG57DkZK4jYRuv3Garmb1i99", network: .solana) // Arbitrary known public key
    let transfer = try Solana.SystemProgram.transfer(
      params: .init(
        fromPubkey: sender.publicKey(),
        toPubkey: recipient,
        lamports: 49
      )
    )
    
    var sampleTransaction = try Solana.Transaction(
      blockhash: recentBlockhash,
      lastValidBlockHeight: 9999
    ).adding(instructions: transfer)
    sampleTransaction.feePayer = try sender.publicKey()
    
    // Transactions with missing signatures will fail sigverify.
    #expect(throws: Solana.Transaction.ValidationErrors.init(errors: [
      Solana.Transaction.ValidationError.missingSignature(senderPublicKey)
    ]), performing: {
      try sampleTransaction.serialize()
    })
    
    // Serializing without signatures is allowed if sigverify disabled.
    #expect(throws: Never.self, performing: {
      try sampleTransaction.serialize(verifySignatures: false)
    })
    
    // Serializing the message is allowed when signature array has null signatures
    #expect(throws: Never.self, performing: {
      try sampleTransaction.serializeMessage()
    })
    sampleTransaction.feePayer = nil
    try sampleTransaction.setSigners(signers: senderPublicKey)
    #expect(sampleTransaction.signatures.count == 1)
    sampleTransaction.signatures[0].signature = Data(repeating: 0x00, count: 64)

    // Transactions with invalid signature will fail sigverify.
    #expect(throws: Solana.Transaction.ValidationErrors.init(errors: [
      Solana.Transaction.ValidationError.invalidSignature(senderPublicKey)
    ]), performing: {
      try sampleTransaction.serialize()
    })
    
    let tempKey = PrivateKey(privateKey: Data(hex: "2e070ce3a9f6b2626aaf797beefef58948bf172ea91557d0cf5164f2d5cba59a"), network: .solana)
    sampleTransaction.feePayer = try tempKey.publicKey()
    sampleTransaction.signatures = try [
      .init(signature: nil, publicKey: tempKey.publicKey()),
      .init(signature: Data(repeating: 64, count: 0x2A), publicKey: senderPublicKey),
    ]
    
    // Transactions with invalid signature and missing signature will fail sigverify and throw both.
    try #expect(throws: Solana.Transaction.ValidationErrors.init(errors: [
      Solana.Transaction.ValidationError.missingSignature(tempKey.publicKey()),
      Solana.Transaction.ValidationError.invalidSignature(senderPublicKey),
    ]), performing: {
      try sampleTransaction.serialize()
    })
  }
  
  
  @Suite("partially signed transaction signature verification tests")
  fileprivate struct PartiallySignedTransactionSignatureVerificationTests {
    let sender = PrivateKey(privateKey: Data(repeating: 0x08, count: 32), network: .solana) // Arbitrary known account
    let feePayer = PrivateKey(privateKey: Data(repeating: 0x09, count: 32), network: .solana) // Arbitrary known account
    let fakeKey = PrivateKey(privateKey: Data(repeating: 0x0A, count: 32), network: .solana) // Arbitrary known account
    let recentBlockhash = "EETubP5AKHgjPAhzPAFcb8BAY1hMH639CWCFTqi3hq1k" // Arbitrary known recentBlockhash
    let recipient = try! PublicKey(base58: "J3dxNj7nDRRqRRXuEMynDG57DkZK4jYRuv3Garmb1i99", network: .solana) // Arbitrary known public key
    
    let transfer: Solana.TransactionInstruction
    var expectedTransaction: Solana.Transaction
    
    init() throws {
      self.transfer = try Solana.SystemProgram.transfer(
        params: .init(
          fromPubkey: self.sender.publicKey(),
          toPubkey: self.recipient,
          lamports: 49
        )
      )
      self.expectedTransaction = try Solana.Transaction(
        blockhash: self.recentBlockhash, lastValidBlockHeight: 9999
      ).adding(instructions: transfer)
      
      // To have 2 required signers we add a feepayer
      self.expectedTransaction.feePayer = try feePayer.publicKey()
    }
    
    @Test("verifies for no sigs")
    mutating func verifiesForNoSigs() async throws {
      #expect(expectedTransaction.signatures.isEmpty)
      
      // No extra param should require all sigs, should be false for no sigs
      try #expect(expectedTransaction.verifySignatures() == false)
      
      // True should require all sigs, should be false for no sigs
      try #expect(expectedTransaction.verifySignatures(requireAllSignatures: true) == false)
      
      // False should verify only the available sigs, should be true for no sigs
      try #expect(expectedTransaction.verifySignatures(requireAllSignatures: false) == true)
    }
    
    @Test("verifies for one sig")
    mutating func verifiesForOneSig() async throws {
      // Add one required sig
      try expectedTransaction.partialSign(signers: self.sender)

      #expect(expectedTransaction.signatures.filter({ $0.signature != nil }).count == 1)

      // No extra param should require all sigs, should be false for one missing sig
      try #expect(expectedTransaction.verifySignatures() == false)

      // True should require all sigs, should be false one missing sigs
      try #expect(expectedTransaction.verifySignatures(requireAllSignatures: true) == false)

      // False should verify only the available sigs, should be true one valid sig
      try #expect(expectedTransaction.verifySignatures(requireAllSignatures: false) == true)
    }
    
    @Test("verifies for all sigs")
    mutating func verifiesForAllSigs() async throws {
      // Add all required sigs
      try expectedTransaction.partialSign(signers: sender)
      try expectedTransaction.partialSign(signers: feePayer)

      #expect(expectedTransaction.signatures.filter({ $0.signature != nil }).count == 2)

      // No extra param should require all sigs, should be true for no missing sig
      try #expect(expectedTransaction.verifySignatures() == true)

      // True should require all sigs, should be true for no missing sig
      try #expect(expectedTransaction.verifySignatures(requireAllSignatures: true) == true)

      // False should verify only the available sigs, should be true for no missing sig
      try #expect(expectedTransaction.verifySignatures(requireAllSignatures: false) == true)
    }
    
    @Test("throws for wrong sig with only one sig present")
    mutating func throwsForWrongSigWithOnlyOneSigPresent() async throws {
      // Add one required sigs
      try expectedTransaction.partialSign(signers: feePayer)

      // Add a wrong signature
      let fakePublicKey = try fakeKey.publicKey()
      expectedTransaction.signatures[0].publicKey = fakePublicKey
      #expect(expectedTransaction.signatures[0].publicKey == fakePublicKey)

      // No extra param should require all sigs, should throw for wrong sig
      #expect(throws: Solana.Transaction.Error.unknownSigner(fakePublicKey), performing: {
        try expectedTransaction.verifySignatures()
      })

      // True should require all sigs, should throw for wrong sig
      #expect(throws: Solana.Transaction.Error.unknownSigner(fakePublicKey), performing: {
        try expectedTransaction.verifySignatures(requireAllSignatures: true)
      })
      
      // False should verify only the available sigs, should throw for wrong sig
      #expect(throws: Solana.Transaction.Error.unknownSigner(fakePublicKey), performing: {
        try expectedTransaction.verifySignatures(requireAllSignatures: false)
      })
    }
    
    @Test("throws for wrong sig with all sigs present")
    mutating func throwsForWrongSigWithAllSigsPresent() async throws {
      // Add all required sigs
      try expectedTransaction.partialSign(signers: sender)
      try expectedTransaction.partialSign(signers: feePayer)

      // Add a wrong signature
      let fakePublicKey = try fakeKey.publicKey()
      expectedTransaction.signatures[0].publicKey = fakePublicKey
      #expect(expectedTransaction.signatures[0].publicKey == fakePublicKey)

      // No extra param should require all sigs, should throw for wrong sig
      #expect(throws: Solana.Transaction.Error.unknownSigner(fakePublicKey), performing: {
        try expectedTransaction.verifySignatures()
      })

      // True should require all sigs, should throw for wrong sig
      #expect(throws: Solana.Transaction.Error.unknownSigner(fakePublicKey), performing: {
        try expectedTransaction.verifySignatures(requireAllSignatures: true)
      })
      
      // False should verify only the available sigs, should throw for wrong sig
      #expect(throws: Solana.Transaction.Error.unknownSigner(fakePublicKey), performing: {
        try expectedTransaction.verifySignatures(requireAllSignatures: false)
      })
    }
  }
  
  @Test("deprecated - externally signed stake delegate")
  func deprecatedExternallySignedStakeDelegate() async throws {
    let authority = PrivateKey(privateKey: Data(repeating: 0x01, count: 32), network: .solana)
    let stake = try PublicKey(hex: "0x02", network: .solana)
    let recentBlockhash = try PublicKey(hex: "0x03", network: .solana).address()!.address
    let vote = try PublicKey(hex: "0x04", network: .solana)
    
    var tx = try Solana.StakeProgram.delegate(
      params: .init(
        stakePubkey: stake,
        authorizedPubkey: authority.publicKey(),
        votePubkey: vote
      )
    )
    let from = authority
    tx.recentBlockhash = recentBlockhash
    try tx.setSigners(signers: from.publicKey())
    let txBytes = try tx.serializeMessage()
    
    let signature = try TweetNacl.sign(message: txBytes, secretKey: from.ed25519())
    try tx.addSignature(pubkey: from.publicKey(), signature: signature)
    try #expect(tx.verifySignatures() == true)
  }
  
  @Test("externally signed stake delegate")
  func externallySignedStakeDelegate() async throws {
    let authority = PrivateKey(privateKey: Data(repeating: 0x01, count: 32), network: .solana)
    let stake = try PublicKey(hex: "0x02", network: .solana)
    let recentBlockhash = try PublicKey(hex: "0x03", network: .solana).address()!.address
    let vote = try PublicKey(hex: "0x04", network: .solana)
    
    var tx = try Solana.StakeProgram.delegate(
      params: .init(
        stakePubkey: stake,
        authorizedPubkey: authority.publicKey(),
        votePubkey: vote
      )
    )
    let from = authority
    tx.recentBlockhash = recentBlockhash
    tx.feePayer = try from.publicKey()
    
    let txBytes = try tx.serializeMessage()
    let signature = try TweetNacl.sign(message: txBytes, secretKey: from.ed25519())
    try tx.addSignature(pubkey: from.publicKey(), signature: signature)
    try #expect(tx.verifySignatures() == true)
  }
  
  @Test("can serialize, deserialize, and reserialize with a partial signer")
  func canSerializeDeserializeAndReserializeWithAPartialSigner() async throws {
    let signer = PrivateKey(privateKey: Data(hex: "8159abe20202e9aac131b34b41a8e9f9bc038fad865349382a175afee5133ae7"), network: .solana)
    let acc0Writable = PrivateKey(privateKey: Data(hex: "2e070ce3a9f6b2626aaf797beefef58948bf172ea91557d0cf5164f2d5cba59a"), network: .solana)
    let acc1Writable = PrivateKey(privateKey: Data(hex: "59a1aceb689ed3fe7adc1b44d78be38d0f1f0ec99263ce6199fbb369722a773c"), network: .solana)
    let acc2Writable = PrivateKey(privateKey: Data(hex: "d4db5154833691176b4172b6dce524d40a035698738400ca6d131e8f6decc764"), network: .solana)
    
    var t0 = try Solana.Transaction(
      feePayer: signer.publicKey(),
      blockhash: "HZaTsZuhN1aaz9WuuimCFMyH7wJ5xiyMUHFCnZSMyguH",
      lastValidBlockHeight: 9999
    )
    try t0.add(
      instructions: Solana.TransactionInstruction(
        keys: [
          .init(pubkey: signer.publicKey(), isSigner: true, isWritable: true),
          .init(pubkey: acc0Writable.publicKey(), isSigner: false, isWritable: true),
        ],
        programId: PublicKey(base58: "J3dxNj7nDRRqRRXuEMynDG57DkZK4jYRuv3Garmb1i99", network: .solana)
      )
    )
    try t0.add(
      instructions: Solana.TransactionInstruction(
        keys: [
          .init(pubkey: acc1Writable.publicKey(), isSigner: false, isWritable: false),
        ],
        programId: PublicKey(base58: "EETubP5AKHgjPAhzPAFcb8BAY1hMH639CWCFTqi3hq1k", network: .solana)
      )
    )
    try t0.add(
      instructions: Solana.TransactionInstruction(
        keys: [
          .init(pubkey: acc2Writable.publicKey(), isSigner: false, isWritable: true),
        ],
        programId: PublicKey(base58: "9U2wM3MUToUCRiBsR6zAcnqJw43kcXSxp27QxsKEJSBf", network: .solana)
      )
    )
    try t0.add(
      instructions: Solana.TransactionInstruction(
        keys: [
          .init(pubkey: signer.publicKey(), isSigner: true, isWritable: true),
          .init(pubkey: acc0Writable.publicKey(), isSigner: false, isWritable: false),
          .init(pubkey: acc2Writable.publicKey(), isSigner: false, isWritable: false),
          .init(pubkey: acc1Writable.publicKey(), isSigner: false, isWritable: true),
        ],
        programId: PublicKey(base58: "3pMGMtrafGShCntKUsQwnpbKVK2fV8FcvdfiBbQ8w7Tr", network: .solana)
      )
    )
    
    let t0Data = try t0.serialize(requireAllSignatures: false)
    let decoder = Solana.ShortVecDecoder()
    var t1 = try decoder.decode(Solana.Transaction.self, from: t0Data)
    
    #expect(throws: Never.self, performing: {
      try t1.partialSign(signers: signer)
      _ = try t1.serialize()
    })
  }
  
  @Suite("VersionedTransaction tests")
  fileprivate struct VersionedTransactionTests {
    @Test("deserializes versioned transactions")
    mutating func verifiesForNoSigs() async throws {
      let serializedVersionedTx = Data(base64Encoded: "AdTIDASR42TgVuXKkd7mJKk373J3LPVp85eyKMVcrboo9KTY8/vm6N/Cv0NiHqk2I8iYw6VX5ZaBKG8z9l1XjwiAAQACA+6qNbqfjaIENwt9GzEK/ENiB/ijGwluzBUmQ9xlTAMcCaS0ctnyxTcXXlJr7u2qtnaMgIAO2/c7RBD0ipHWUcEDBkZv5SEXMv/srbpyw5vnvIzlu8X3EmssQ5s6QAAAAJbI7VNs6MzREUlnzRaJpBKP8QQoDn2dWQvD0KIgHFDiAwIACQAgoQcAAAAAAAIABQEAAAQAATYPBwAKBDIBAyQWIw0oCxIdCA4iJzQRKwUZHxceHCohMBUJJiwpMxAaGC0TLhQxGyAMBiU2NS8VDgAAAADuAgAAAAAAAAIAAAAAAAAAAdGCTQiq5yw3+3m1sPoRNj0GtUNNs0FIMocxzt3zuoSZHQABAwQFBwgLDA8RFBcYGhwdHh8iIyUnKiwtLi8yFwIGCQoNDhASExUWGRsgISQmKCkrMDEz")!
      let decoder = Solana.ShortVecDecoder()
      
      #expect(throws: DecodingError.self, performing: {
        _ = try decoder.decode(Solana.Transaction.self, from: serializedVersionedTx)
      })
      
      // decode versioned
      let versionedTx = try decoder.decode(Solana.VersionedTransaction.self, from: serializedVersionedTx)
      #expect(versionedTx.message.version == .v0)
    }
    
    @Suite("addSignature")
    fileprivate struct VersionedTransactionTests {
      let signer1 = PrivateKey(privateKey: Data(hex: "5c9ed52cdc1f195ba68ccddf8da9c058cf96cba74d325fc6414a179c3fa7bc37"), network: .solana)
      let signer2 = PrivateKey(privateKey: Data(hex: "49b5622ca5f5e72ade9b0fd0778b51e0dc43007516d7887002adb5cd6e79e304"), network: .solana)
      let signer3 = PrivateKey(privateKey: Data(hex: "304618984e147eb511527cbc4dbabcc4e351d85046a71304a8350962705e1de1"), network: .solana)
      let recentBlockhash = try! PublicKey(hex: "0x03", network: .solana).address()!.address
      let message: Solana.TransactionMessage
      var transaction: Solana.VersionedTransaction
      
      init() throws {
        self.message = try Solana.TransactionMessage(
          payerKey: signer1.publicKey(),
          instructions: [
            Solana.TransactionInstruction(
              keys: [
                .init(pubkey: signer1.publicKey(), isSigner: true, isWritable: true),
                .init(pubkey: signer2.publicKey(), isSigner: true, isWritable: true),
                .init(pubkey: signer3.publicKey(), isSigner: false, isWritable: false),
              ],
              programId: PublicKey(base58: "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr", network: .solana),
              data: "Hello!".data(using: .utf8)!
            )
          ],
          recentBlockhash: self.recentBlockhash
        )
        self.transaction = try Solana.VersionedTransaction(message: self.message.compileToV0Message())
      }
      
      @Test("appends externally generated signatures at correct indexes")
      mutating func appendsExternallyGeneratedSignaturesAtCorrectIndexes() async throws {
        let encoder = Solana.ShortVecEncoder()
        let messageData = try encoder.encode(transaction.message)
        let signature1 = try TweetNacl.sign(
          message: messageData,
          secretKey: signer1.ed25519()
        )
        let signature2 = try TweetNacl.sign(
          message: messageData,
          secretKey: signer2.ed25519()
        )
        try transaction.addSignature(publicKey: signer2.publicKey(), signature: signature2)
        try transaction.addSignature(publicKey: signer1.publicKey(), signature: signature1)
        
        #expect(transaction.signatures.count == 2)
        #expect(transaction.signatures[0] == signature1)
        #expect(transaction.signatures[1] == signature2)
      }
      
      @Test("fatals when the signature is the wrong length")
      mutating func fatalsWhenTheSignatureIsTheWrongLength() async throws {
        #expect(throws: Solana.VersionedTransaction.Error.invalidSignature, performing: {
          try transaction.addSignature(publicKey: signer1.publicKey(), signature: Data(repeating: 0x00, count: 32))
        })
      }
      
      @Test("fatals when adding a signature for a public key that has not been marked as a signer")
      mutating func fatalsWhenAddingASignatureForAPublicKeyThatHasNotBeenMarkedAsASigner() async throws {
        try #expect(throws: Solana.VersionedTransaction.Error.signerIsNotRequired(signer3.publicKey()), performing: {
          try transaction.addSignature(publicKey: signer3.publicKey(), signature: Data(repeating: 0x00, count: 64))
        })
      }
    }
  }
}
