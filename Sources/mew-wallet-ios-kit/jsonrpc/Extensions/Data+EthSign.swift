//
//  Data+EthSign.swift
//  MEWwalletKit
//
//  Created by Mikhail Nikanorov on 7/24/19.
//  Copyright © 2019 MyEtherWallet Inc. All rights reserved.
//

import Foundation
import mew_wallet_ios_secp256k1

private let ethSignPrefix = "\u{19}Ethereum Signed Message:\n"

public extension Data {
  func hashPersonalMessage() -> Data? {
    var prefix = ethSignPrefix
    prefix += String(self.count)
    guard let prefixData = prefix.data(using: .ascii) else {
      return nil
    }
    let data = prefixData + self
    let hash = data.sha3(.keccak256)
    return hash
  }
  
  func sign(key: PrivateKey, leadingV: Bool) -> Data? {
    self.hashPersonalMessage()?.unsafeSign(key: key.data(), leadingV: leadingV)
  }
    
  /// Recovers address from a hashed message (self) with provided signature.
  ///
  /// Caller must compare returned Ethereum address with the sender's address and
  /// confirm the hash provided by the sender is equal to the hash of the original message
  /// - Parameter with signature: signature
  /// - Returns: Ethereum address that signed the message, nil if address could not be recovered
  func recover(with signature: Data) -> Address? {
    guard let rawPublicKey = self.recoverPublicKey(with: signature),
          let publicKey = try? PublicKey(publicKey: rawPublicKey, index: 0, network: .ethereum) else { return nil }
    
    return publicKey.address()
  }
  
  /// Recovers `publicKey` from a hashed message (`self`) with provided signature.
  ///
  /// - Parameter with signature: signature
  /// - Returns: Ethereum address that signed the message, nil if address could not be recovered
  func recoverPublicKey(with signature: Data) -> Data? {
    // Normalize V part of signature
    var signature = signature
    if signature[64] > 3 {
      signature[64] = signature[64] - 0x1b
    }
      
    let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_VERIFY))!
    // Recover public key from signature and hash
    guard let publicKeyRecovered = signature.secp256k1RecoverPublicKey(hash: self, context: context) else {
      return nil
    }
    return publicKeyRecovered
  }
}

public extension Data {
  
  @available(*, deprecated, renamed: "unsafeSign(key:leadingV:)")
  func sign(key: Data, leadingV: Bool) -> Data? {
    return self.unsafeSign(key: key, leadingV: leadingV)
  }
  
  /// Signs data with provided key
  /// Please pay attention when using this method. It's possible to accidently sign phishing data, f.e. transaction that will drain tokens.
  /// In case if you need to sign personal message or transaction - use other methods
  /// - Parameters:
  ///   - key: PrivateKey to sign data
  ///   - leadingV: controls order of signature: VRS or RSV
  /// - Returns: result signature
  func unsafeSign(key: Data, leadingV: Bool) -> Data? {
    guard let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN)) else {
      return nil
    }
    defer { secp256k1_context_destroy(context) }
    guard var recoverableSignature = self.secp256k1RecoverableSign(privateKey: key, context: context) else {
      return nil
    }
    guard let serializedRecoverableSignature = recoverableSignature.serialized(context: context) else {
      return nil
    }
    do {
      let signature = try TransactionSignature(signature: serializedRecoverableSignature, normalized: true)
      var signed = Data()
      if leadingV {
        signed.append(signature.v.data)
      }
      signed.append(signature.r.data)
      signed.append(signature.s.data)
      if !leadingV {
        signed.append(signature.v.data)
      }
      
      return signed
    } catch {
      return nil
    }
  }
}
