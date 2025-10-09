//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 10/8/25.
//

import Foundation
import mew_wallet_ios_kit
import mew_wallet_ios_kit_solana
import mew_wallet_ios_tweetnacl

extension Solana.VersionedTransaction {
  mutating public func sign(signer: PrivateKey) throws {
    try self.sign(signers: [signer])
  }
  
  mutating public func sign(signers: [PrivateKey]) throws {
    let encoder = Solana.ShortVecEncoder()
    let messageData = try encoder.encode(self.message)
    for signer in signers {
      let signature = try TweetNacl.sign(message: messageData, secretKey: signer.ed25519())
      try self.addSignature(publicKey: signer.publicKey(), signature: signature)
    }
  }
 
  mutating public func addSignature(publicKey: PublicKey, signature: Data) throws {
    guard signature.count == 64 else {
      throw Error.invalidSignature
    }
    let signerPubkeys = message.staticAccountKeys[0..<Int(message.header.numRequiredSignatures)]
    guard let signerIndex = signerPubkeys.firstIndex(of: publicKey) else {
      throw Error.signerIsNotRequired(publicKey)
    }
    self.signatures[signerIndex] = signature
  }
}
