//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/13/25.
//

import Foundation
import mew_wallet_ios_kit

extension PublicKey {
  static func unique() throws -> Self {
    try PublicKey(hex: Data.randomBytes(length: 32)!.toHexString(), network: .solana)
  }
}
