//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit_solana
import mew_wallet_ios_kit
import mew_wallet_ios_tweetnacl

extension Solana.Transaction {
  public enum SignError: Swift.Error {
    case noSigners
    case badSignatureLength
    case unknownSigner(PublicKey)
  }
  
  public mutating func sign(signers: [PrivateKey]) throws {
    guard !signers.isEmpty else {
      throw SignError.noSigners
    }
    
    var uniqueSigners: [PrivateKey] = []
    uniqueSigners.reserveCapacity(signers.count)
    
    for signer in signers {
      if try !uniqueSigners.contains(where: { try $0.publicKey() == signer.publicKey() }) {
        uniqueSigners.append(signer)
      }
    }
    
    self.signatures = try uniqueSigners.map({
      try Solana.SignaturePubkeyPair(signature: nil, publicKey: $0.publicKey())
    })
    
    let message = try self._compile()
    try self._partialSign(message: message, signers: uniqueSigners)
  }
  
  public mutating func sign(signers: PrivateKey...) throws {
    try self.sign(signers: signers)
  }
  
  private mutating func _partialSign(message: Solana.Message, signers: [PrivateKey]) throws {
    let encoder = Solana.ShortVecEncoder()
    let data = try encoder.encode(message)
    
    try signers.forEach { key in
      let signature = try TweetNacl.sign(message: data, secretKey: key.data())
      try self._addSignature(signature: signature, for: key.publicKey())
    }
  }
  
  private mutating func _compile() throws -> Solana.Message {
    let message = try self.compileMessage()
    let signedKeys = message.accountKeys.prefix(Int(message.header.numRequiredSignatures))
    
    if self.signatures.count == signedKeys.count,
       self.signatures.enumerated().allSatisfy({ signedKeys[$0.offset] == $0.element.publicKey }) {
      return message
    }
    
    self.signatures = signedKeys.map({
      .init(signature: nil, publicKey: $0)
    })
    
    return message
  }
  
  private mutating func _addSignature(signature: Data, for key: PublicKey) throws {
    guard signature.count == 64 else { throw SignError.badSignatureLength }
    guard let index = self.signatures.firstIndex(where: { $0.publicKey == key }) else {
      throw SignError.unknownSigner(key)
    }
    self.signatures[index].signature = signature
  }
}
