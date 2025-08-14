//
//  Encodable+Borsh.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation

extension Encodable {
  /// Encodes this value to binary data using Borsh encoding.
  ///
  /// - Returns: Binary data representation of this value.
  /// - Throws: An error if the value cannot be encoded.
  public func encodeBorsh() throws -> Data {
    let encoder = Solana.BorshEncoder()
    return try encoder.encode(self)
  }
  
  /// Encodes this value to binary data using Borsh encoding with custom user info.
  ///
  /// - Parameter userInfo: Custom user info for encoding.
  /// - Returns: Binary data representation of this value.
  /// - Throws: An error if the value cannot be encoded.
  public func encodeBorsh(userInfo: [CodingUserInfoKey: any Sendable]) throws -> Data {
    let encoder = Solana.BorshEncoder()
    encoder.userInfo = userInfo
    return try encoder.encode(self)
  }
}
