//
//  Data+Hash160.swift
//  MEWwalletKit
//
//  Created by Mikhail Nikanorov on 4/22/19.
//  Copyright © 2019 MyEtherWallet Inc. All rights reserved.
//

import Foundation
import CryptoSwift

extension Data {
  /// Computes the HASH160 of the data and returns it as a hexadecimal string.
  ///
  /// This is a convenience method for debugging or displaying addresses or identifiers.
  ///
  /// - Returns: A lowercase hexadecimal `String` representation of the HASH160.
  ///
  /// - Example:
  /// ```swift
  /// let pubkey = Data([/* bytes */])
  /// let hexHash = pubkey.hash160Hex()
  /// print(hexHash) // "1a2b3c..."
  /// ```
  package func hash160() -> String {
    return self.ripemd160().toHexString()
  }
  
  
  /// Computes the HASH160 of the data (SHA256 followed by RIPEMD160).
  ///
  /// This is commonly used in Bitcoin to derive P2PKH and P2WPKH addresses from a public key.
  ///
  /// - Returns: A `Data` object containing the 20-byte RIPEMD160(SHA256(data)) hash.
  ///
  /// - Example:
  /// ```swift
  /// let pubkey = Data([/* 33 or 65 bytes */])
  /// let hash160 = pubkey.hash160()
  /// ```
  package func hash160() -> Data {
    return self.ripemd160()
  }
}
