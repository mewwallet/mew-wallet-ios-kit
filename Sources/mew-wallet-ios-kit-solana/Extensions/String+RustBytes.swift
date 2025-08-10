//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/9/25.
//

import Foundation
import mew_wallet_ios_kit_utils

extension String {
  var rustBytes: Data {
    let utf8Bytes = Data(self.utf8)
    let length = UInt32(utf8Bytes.count).littleEndianBytes
    return length + utf8Bytes
  }
}
