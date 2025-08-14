//
//  Solana+BorshEncoder.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit_utils
#if canImport(Combine)
import Combine
#endif

extension Solana {
  public final class BorshEncoder: @unchecked Sendable {
    // MARK: - Properties
    public var userInfo: [CodingUserInfoKey : any Sendable] = [:]
    
    // MARK: - Init
    public init() { }
    
    // MARK: - Encoding
    public func encode<T>(_ value: T) throws -> Data where T : Encodable {
      let storage = BinaryStorage()
      let encoder = Solana._BorshEncoding.Encoder(codingPath: [], userInfo: self.userInfo, storage: storage)
      try value.encode(to: encoder)
      return storage.encodedData()
    }
  }
}

#if canImport(Combine)
/// Enables usage of `Solana.BorshEncoder` with Combine pipelines.
extension Solana.BorshEncoder: TopLevelEncoder {}
#endif
