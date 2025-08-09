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
  
//  });
//  
//  @Test("uses the nonce as the recent blockhash when compiling nonce-based transactions")
//  func usesTheNonceAsTheRecentBlockhashWhenCompilingNonceBasedTransactions() async throws {
//    let payer = PrivateKey(privateKey: Data(hex: "8159abe20202e9aac131b34b41a8e9f9bc038fad865349382a175afee5133ae7"), network: .solana)
//    let recentBlockhash = "3pMGMtrafGShCntKUsQwnpbKVK2fV8FcvdfiBbQ8w7Tr"
//    let programId = try PublicKey(base58: "8zX1MGJwrh4BB3iAb9q5pyYon3MmmyiZ4R3z6z3XZX4h", network: .solana)
//    
//    var transaction = try Solana.Transaction(blockhash: recentBlockhash, lastValidBlockHeight: 9999)
//      .adding(instructions: [
//        .init(
//          keys: [
//            .init(pubkey: payer.publicKey(), isSigner: true, isWritable: false)
//          ],
//          programId: programId
//        )
//      ])
//    
//    try transaction.sign(signers: payer)
//    
//    let message = try transaction.compileMessage()
//    
//    #expect(try message.accountKeys[0] == payer.publicKey())
//    #expect(message.header.numRequiredSignatures == 1)
//    #expect(message.header.numReadonlySignedAccounts == 0)
//    #expect(message.header.numReadonlyUnsignedAccounts == 1)
//    
//  //  it('', () => {
//  //    const nonce = new PublicKey(1);
//  //    const nonceAuthority = new PublicKey(2);
//  //    const nonceInfo = {
//  //      nonce: nonce.toBase58(),
//  //      nonceInstruction: SystemProgram.nonceAdvance({
//  //        noncePubkey: nonce,
//  //        authorizedPubkey: nonceAuthority,
//  //      }),
//  //    };
//  //    const transaction = new Transaction({
//  //      feePayer: nonceAuthority,
//  //      nonceInfo,
//  //    });
//  //    const message = transaction.compileMessage();
//  //    expect(message.recentBlockhash).to.equal(nonce.toBase58());
//  //  });
//  }
}
