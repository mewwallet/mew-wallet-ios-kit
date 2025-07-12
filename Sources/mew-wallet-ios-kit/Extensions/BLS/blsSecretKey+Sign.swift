//
//  File.swift
//  
//
//  Created by Mikhail Nikanorov on 4/6/23.
//

import Foundation
import bls_framework
import CryptoSwift

extension blsSecretKey {
  public func sign(data toSign: Data) throws -> blsSignature {
    try BLSInterface.blsInit()
    
    var signature = blsSignature()
    let bytes = toSign.byteArray
    var `self` = self
    bls_framework.blsSign(&signature, &self, bytes, bytes.count)
    return signature
  }
}
