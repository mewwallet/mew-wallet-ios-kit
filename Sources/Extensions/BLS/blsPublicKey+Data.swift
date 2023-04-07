//
//  blsPublicKey+Data.swift
//  MEWwalletKit
//
//  Created by Mikhail Nikanorov on 12/7/20.
//  Copyright © 2020 MyEtherWallet Inc. All rights reserved.
//

#if os(iOS) || os(macOS)

import Foundation
import bls_framework

private let PUBLIC_KEY_LENGHT = 48

extension blsPublicKey {
  var serialized: Data {
    get throws {
      try BLSInterface.blsInit()
      
      var bytes = Data(count: PUBLIC_KEY_LENGHT).bytes
      var `self` = self
      blsPublicKeySerialize(&bytes, PUBLIC_KEY_LENGHT, &self)
      
      return Data(bytes)
    }
  }
}
#endif
