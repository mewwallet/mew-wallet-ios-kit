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
    #expect(throws: Solana.Transaction.Error.unknownSigner(other.address()), performing: {
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
  
//  it('use nonce', () => {
//      const account1 = Keypair.generate();
//      const account2 = Keypair.generate();
//      const nonceAccount = Keypair.generate();
//      const nonce = account2.publicKey.toBase58(); // Fake Nonce hash
//
//      const nonceInfo = {
//        nonce,
//        nonceInstruction: SystemProgram.nonceAdvance({
//          noncePubkey: nonceAccount.publicKey,
//          authorizedPubkey: account1.publicKey,
//        }),
//      };
//
//      const transferTransaction = new Transaction({nonceInfo}).add(
//        SystemProgram.transfer({
//          fromPubkey: account1.publicKey,
//          toPubkey: account2.publicKey,
//          lamports: 123,
//        }),
//      );
//      transferTransaction.sign(account1);
//
//      expect(transferTransaction.instructions).to.have.length(1);
//      expect(transferTransaction.recentBlockhash).to.be.undefined;
//
//      const stakeAccount = Keypair.generate();
//      const voteAccount = Keypair.generate();
//      const stakeTransaction = new Transaction({nonceInfo}).add(
//        StakeProgram.delegate({
//          stakePubkey: stakeAccount.publicKey,
//          authorizedPubkey: account1.publicKey,
//          votePubkey: voteAccount.publicKey,
//        }),
//      );
//      stakeTransaction.sign(account1);
//
//      expect(stakeTransaction.instructions).to.have.length(1);
//      expect(stakeTransaction.recentBlockhash).to.be.undefined;
//    });
}
