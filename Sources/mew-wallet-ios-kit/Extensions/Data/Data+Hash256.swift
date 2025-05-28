//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/18/25.
//

import Foundation
import CryptoSwift

extension Data {
  /// Computes the double SHA256 hash (i.e., SHA256(SHA256(data))) and returns it as a hex string.
  ///
  /// - Returns: A lowercase hexadecimal `String` of the resulting hash.
  ///
  /// - Example:
  /// ```swift
  /// let header = Data([/* block header */])
  /// let hashString = header.hash256Hex()
  /// print(hashString) // "00000000abcd..."
  /// ```
  package func hash256() -> String {
    return self.sha256().sha256().toHexString()
  }
  
  /// Computes the double SHA256 hash (i.e., SHA256(SHA256(data))).
  ///
  /// This is used in Bitcoin for transaction IDs, block hashes, and sighash preimage signing.
  ///
  /// - Returns: A `Data` value representing the double SHA256 hash.
  ///
  /// - Example:
  /// ```swift
  /// let txBytes = Data([/* transaction bytes */])
  /// let txid = txBytes.hash256()
  /// ```
  package func hash256() -> Data {
    return self.sha256().sha256()
  }
}
