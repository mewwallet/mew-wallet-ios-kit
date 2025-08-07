//
//  Transaction+EIP155.swift
//  MEWwalletKit
//
//  Created by Mikhail Nikanorov on 4/25/19.
//  Copyright © 2019 MyEtherWallet Inc. All rights reserved.
//

import Foundation
import mew_wallet_ios_secp256k1
import BigInt

enum TransactionSignError: Error {
  case invalidChainId
  case invalidPublicKey
  case invalidPrivateKey
  case invalidSignature
  case emptyPublicKey
  case internalError
  case badTransaction
}

extension Transaction {
  public func sign(key: PrivateKey, extraEntropy: Bool = false) throws {
    if self.chainID == nil {
      self.chainID = BigInt(key.network.chainID)
    }
    switch self.eipType {
    case .eip712:
      guard let tx = self as? ZKSync.EIP712Transaction else {
        throw TransactionSignError.badTransaction
      }
      let message = try tx._eip712Message
      let payload = SignedMessagePayload(data: message, signature: nil)
      let signature = try signTypedMessage(privateKey: key, payload: payload, version: message.version)
      tx.meta.customSignature = Data(hex: signature)
    default:
      guard let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN|SECP256K1_CONTEXT_VERIFY)) else { throw TransactionSignError.internalError }
      defer { secp256k1_context_destroy(context) }
      guard let chainID = self.chainID else { throw TransactionSignError.invalidChainId }
      guard let publicKeyData = try? key.publicKey().data() else { throw TransactionSignError.invalidPublicKey }
      let signature = try self.eip155sign(privateKey: key, extraEntropy: extraEntropy, context: context)
      guard let serializedSignature = signature.serialized else { throw TransactionSignError.invalidSignature }
      let transactionSignature = try TransactionSignature(signature: serializedSignature, chainID: chainID)
      guard let recoveredPublicKey = transactionSignature.recoverPublicKey(transaction: self, context: context) else { throw TransactionSignError.emptyPublicKey }
      guard publicKeyData.secureCompare(recoveredPublicKey) else { throw TransactionSignError.invalidPublicKey }
      self.signature = transactionSignature
    }
  }
  
  private func eip155sign(privateKey: PrivateKey, extraEntropy: Bool = false, context: OpaquePointer/*secp256k1_context*/) throws -> (serialized: Data?, raw: Data?) {
    let privateKeyData = try privateKey.data()
    guard privateKeyData.secp256k1Verify(context: context) else { throw TransactionSignError.invalidPrivateKey }
    guard self.chainID != nil else { throw TransactionSignError.invalidChainId }
    self.signature = nil
    guard let publicKey = try? privateKey.publicKey(compressed: true).data() else { throw TransactionSignError.invalidPublicKey }
    guard let hash = self.hash(chainID: self.chainID, forSignature: true) else { throw TransactionSignError.internalError }
    for _ in 0 ..< 1024 {
      guard var signature = hash.secp256k1RecoverableSign(privateKey: privateKeyData, extraEntropy: extraEntropy, context: context) else { continue }
      guard let recoveredPublicKey = signature.recoverPublicKey(from: hash, compressed: true, context: context) else { continue }
      guard recoveredPublicKey.secureCompare(publicKey) else { continue }
      guard let serializedSignature = signature.serialized(context: context) else { continue }
      let rawSignature = signature.data()
      return (serializedSignature, rawSignature)
    }
    return (nil, nil)
  }
}
