//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/9/25.
//

import Foundation
import mew_wallet_ios_kit_utils

extension String {
  /// Converts the string into a **Rust-compatible byte buffer** used by Solana
  /// and other Rust-based systems that serialize `String` values as:
  ///
  /// ```
  /// <length: u32 little-endian> <UTF-8 bytes>
  /// ```
  ///
  /// Example:
  /// ```
  /// "SOL".rustBytes
  /// // -> [0x03, 0x00, 0x00, 0x00, 0x53, 0x4F, 0x4C]
  /// ```
  ///
  /// - Returns: A `Data` buffer where the first 4 bytes represent the UTF-8
  ///   byte count as a little-endian `UInt32`, followed by the UTF-8 bytes of
  ///   the string itself.
  var rustBytes: Data {
    let utf8Bytes = Data(self.utf8)
    let length = UInt32(utf8Bytes.count).littleEndianBytes
    return length + utf8Bytes
  }
}
