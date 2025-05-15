//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/14/25.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

extension Bitcoin {
  /// Typealias for the default transaction decoder.
  public typealias TransactionDecoder = Bitcoin.Decoder
  
  /// A generic Bitcoin transaction decoder.
  ///
  /// This class allows decoding binary-encoded Bitcoin transactions (and related structures)
  /// using a custom decoding pipeline. It optionally supports input script validation.
  open class Decoder {
    // MARK: - Validation

    /// Validation options used during decoding to ensure correctness of certain fields.
    public struct Validation: OptionSet, Sendable {
      public let rawValue: UInt16
      
      public init(rawValue: UInt16) {
        self.rawValue = rawValue
      }
      
      /// Validates that `scriptSig` matches the expected script structure.
      public static let inputScriptSig = Validation(rawValue: 1 << 0)
      
      /// No validation (default).
      public static let disabled: Validation = []
      
      /// Enables all available validations.
      public static let all: Validation = [.inputScriptSig]
    }
    
    // MARK: - Properties

    /// Contextual information available during decoding.
    /// You may use this to pass auxiliary data to custom decoders.
    public var userInfo: [CodingUserInfoKey : any Sendable] = [:]
    
    /// Validation settings applied during decoding.
    /// Defaults to `.disabled` for performance.
    public var validation: Bitcoin.Decoder.Validation = .disabled
    
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
      let configuration = DataReaderConfiguration(validation: self.validation)
      let decoder = Bitcoin._Decoding.Decoder<_Reader.BitcoinTx>(
        data: [data],
        context: nil,
        map: nil,
        userInfo: userInfo,
        configuration: configuration
      )
      return try T(from: decoder)
    }
  }
}

#if canImport(Combine)
/// Support for Combine decoding streams.
extension Bitcoin.Decoder: TopLevelDecoder {}
#endif
