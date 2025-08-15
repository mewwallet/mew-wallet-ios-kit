//
//  Solana+BorshDecoder.swift
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
  public final class BorshDecoder: @unchecked Sendable {
    public enum DecodingStyle {
      case universal

      internal var startSection: Solana._Borsh.Decoder.Section {
        switch self {
        case .universal:
          return .publicKey
        }
      }
    }
    
    // MARK: - Properties
    public var userInfo: [CodingUserInfoKey : any Sendable] = [:]
      public var decodingStyle: DecodingStyle = .universal

    // MARK: - Init
    public init() { }
    
    // MARK: - Decoding
    public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
      let decoder = Solana._Borsh.Decoder(
        codingPath: [], 
        userInfo: self.userInfo, 
        data: data, 
        section: self.decodingStyle.startSection
      )
      return try T(from: decoder)
    }
  }
}

#if canImport(Combine)
/// Enables usage of `Solana.BorshDecoder` with Combine pipelines.
extension Solana.BorshDecoder: TopLevelDecoder {}
#endif
