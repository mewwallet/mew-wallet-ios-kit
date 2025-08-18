//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/10/25.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

extension Solana {
  open class ShortVecDecoder {
    public enum DecodingStyle {
      case transaction
      case message
      case messageV0
      case version
      case universal
      
      fileprivate var startSection: Solana._ShortVecDecoding.Decoder.Section {
        switch self {
        case .transaction:      return .transaction(.signatures)
        case .message:          return .message(.version)
        case .messageV0:        return .message(.version)
        case .version:          return .message(.version)
        case .universal:        return .universal
        }
      }
      
      fileprivate var isV0: Bool {
        switch self {
        case .messageV0, .version:
          return true
        default:
          return false
        }
      }
    }
  
    // MARK: - Properties

    /// Contextual information available during decoding.
    /// You may use this to pass auxiliary data to custom decoders.
    public var userInfo: [CodingUserInfoKey : any Sendable] = [:]
    
    public var decodingStyle: DecodingStyle = .transaction
    
    // MARK: - Init

    /// Creates a new `Bitcoin.Decoder` instance.
    public init() { }
    
    /// Decodes a type `T` conforming to `Decodable` from binary data.
    ///
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - data: The binary data representing a Bitcoin-encoded structure.
    /// - Returns: The decoded instance of `T`.
    /// - Throws: Any decoding error or format issue.
    open func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
      var startIndex = data.startIndex
      let decoder = Solana._ShortVecDecoding.Decoder(
        data: data,
        offset: &startIndex,
        section: self.decodingStyle.startSection,
        userInfo: userInfo
      )
      if self.decodingStyle.isV0 {
        decoder.version = .v0
      }
      return try T(from: decoder)
    }
  }
}

#if canImport(Combine)
/// Support for Combine decoding streams.
extension Solana.ShortVecDecoder: TopLevelDecoder {}
#endif
