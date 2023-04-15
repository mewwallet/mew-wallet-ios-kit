//
//  blsSecretKey+PublicKey.swift
//  MEWwalletKit
//
//  Created by Mikhail Nikanorov on 12/7/20.
//  Copyright © 2020 MyEtherWallet Inc. All rights reserved.
//

#if os(iOS) || os(macOS)

import Foundation
import bls_framework

extension blsSecretKey {
  public var blsPublicKey: blsPublicKey {
    get throws {
      try BLSInterface.blsInit()
      
      var publicKey = bls_framework.blsPublicKey.init()
      var `self` = self
      blsGetPublicKey(&publicKey, &self)
      return publicKey
    }
  }
}

#endif
