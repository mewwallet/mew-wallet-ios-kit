//
//  File.swift
//  
//
//  Created by Mikhail Nikanorov on 4/6/23.
//

import Foundation
import bls_framework

extension blsSignature {
  func verify(publicKey: blsPublicKey, data: Data) throws {
    try BLSInterface.blsInit()
    
    let bytes = data.bytes
    var publicKey = publicKey
    var `self` = self
    guard blsVerify(&self, &publicKey, bytes, bytes.count) == 1 else {
      throw EIP2333Error.badSignature
    }
  }
}
