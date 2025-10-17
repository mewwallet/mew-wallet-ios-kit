//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 10/16/25.
//

import Foundation
import mew_wallet_ios_kit
import mew_wallet_ios_tweetnacl

extension PublicKey {
  public var isOnCurve: Bool {
    get throws {
      try TweetNacl.isOnCurve(publicKey: self.data())
    }
  }
}
