//
//  File.swift
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
  public final class ShortVecEncoder: @unchecked Sendable {
    // MARK: - Properties

    /// User-defined contextual information available during encoding.
    ///
    /// Use this to pass custom values to encoding implementations.
    public var userInfo: [CodingUserInfoKey : any Sendable] = [:]
        
    // MARK: - Init

    /// Creates a new instance of the encoder.
    public init() { }
    
    // MARK: - Encoding

    /// Encodes a given value to binary `Data` using Bitcoin encoding rules.
    ///
    /// - Parameter value: The encodable value to encode.
    /// - Returns: A `Data` object containing the binary representation.
    /// - Throws: An error if the value cannot be encoded.
    public func encode<T>(_ value: T) throws -> Data where T : Encodable {
      let storage = BinaryStorage()
      let encoder = Solana._ShortVecEncoding.Encoder(codingPath: [], userInfo: self.userInfo, storage: storage)
      try value.encode(to: encoder)
      return storage.encodedData()
    }
  }
}

#if canImport(Combine)
/// Enables usage of `Solana.Encoder` with Combine pipelines.
extension Solana.ShortVecEncoder: TopLevelEncoder {}
#endif
