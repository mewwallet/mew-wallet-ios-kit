//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation
import mew_wallet_ios_kit
import mew_wallet_ios_tweetnacl

/**
 * Versioned transaction class
 */
extension Solana {
  public struct VersionedTransaction {
    public enum Error: Swift.Error, Equatable {
      case invalidSignature
      case invalidSignaturesCount
      case signerIsNotRequired(PublicKey)
    }
    public var signatures: [Data]
    public private(set) var message: VersionedMessage
    
    public var version: Solana.Version {
      return message.version
    }
    
    public var recentBlockhash: String {
      get {
        switch message {
        case .legacy(let message):    return message.recentBlockhash
        case .v0(let message):        return message.recentBlockhash
        }
      }
      set {
        switch message {
        case .legacy(var message):
          message.recentBlockhash = newValue
          self.message = .legacy(message)
        case .v0(var message):
          message.recentBlockhash = newValue
          self.message = .v0(message)
        }
      }
    }
    
    public init(message: VersionedMessage, signatures: [Data]? = nil) throws {
      if let signatures {
        guard signatures.count == message.header.numRequiredSignatures else {
          throw Error.invalidSignaturesCount
        }
        self.signatures = signatures
      } else {
        self.signatures = [Data](repeating: Data(repeating: 0x00, count: 64), count: Int(message.header.numRequiredSignatures))
      }
      self.message = message
    }
    
    mutating public func sign(signer: PrivateKey) throws {
      try self.sign(signers: [signer])
    }
    
    mutating public func sign(signers: [PrivateKey]) throws {
      let encoder = Solana.ShortVecEncoder()
      let messageData = try encoder.encode(self.message)
      for signer in signers {
        let signature = try TweetNacl.sign(message: messageData, secretKey: signer.data())
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
}

extension Solana.VersionedTransaction: Codable {
  public init(from decoder: any Decoder) throws {
    var container = try decoder.unkeyedContainer()

    let rawSignatures = try container.decode([Data].self)
    let message = try container.decode(Solana.VersionedMessage.self)

    guard rawSignatures.count == message.header.numRequiredSignatures else {
      throw Error.invalidSignaturesCount
    }

    self.signatures = rawSignatures
    self.message = message
  }
  
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.unkeyedContainer()
    
    try container.encode(self.signatures)
    
    try container.encode(self.message)
  }
}
