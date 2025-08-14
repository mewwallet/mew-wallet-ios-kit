//
//  Data+Borsh.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation

extension Data {
  /// Decodes a value of the specified type from this data using Borsh decoding.
  ///
  /// - Parameter type: The type of the value to decode.
  /// - Returns: A value of the specified type.
  /// - Throws: An error if the value cannot be decoded.
  public func decodeBorsh<T>(_ type: T.Type) throws -> T where T : Decodable {
    let decoder = Solana.BorshDecoder()
    return try decoder.decode(type, from: self)
  }
  
  /// Decodes a value of the specified type from this data using Borsh decoding with custom user info.
  ///
  /// - Parameters:
  ///   - type: The type of the value to decode.
  ///   - userInfo: Custom user info for decoding.
  /// - Returns: A value of the specified type.
  /// - Throws: An error if the value cannot be decoded.
  public func decodeBorsh<T>(_ type: T.Type, userInfo: [CodingUserInfoKey: any Sendable]) throws -> T where T : Decodable {
    let decoder = Solana.BorshDecoder()
    decoder.userInfo = userInfo
    return try decoder.decode(type, from: self)
  }
}
