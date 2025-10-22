//
//  Key.swift
//  MEWwalletKit
//
//  Created by Mikhail Nikanorov on 4/19/19.
//  Copyright © 2019 MyEtherWallet Inc. All rights reserved.
//

import Foundation

public protocol IKey {
  var network: Network { get }
  func string(compressedPublicKey: Bool) -> String?
  func extended() -> String?
  func address() -> Address?
}

public extension IKey {
  func string() -> String? {
    return self.string(compressedPublicKey: true)
  }
}
