//
//  File.swift
//  
//
//  Created by Mikhail Nikanorov on 4/6/23.
//

import Foundation
import bls_framework
import CryptoSwift

extension blsSignature {
  public func verify(publicKey: blsPublicKey, data: Data) throws {
    try BLSInterface.blsInit()
    
    let bytes = data.byteArray
    var publicKey = publicKey
    var `self` = self
    guard blsVerify(&self, &publicKey, bytes, bytes.count) == 1 else {
      throw EIP2333Error.badSignature
    }
  }
}
