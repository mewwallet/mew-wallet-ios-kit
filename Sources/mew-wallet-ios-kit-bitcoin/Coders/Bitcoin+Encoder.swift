//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/18/25.
//

import Foundation
import mew_wallet_ios_kit_utils
#if canImport(Combine)
import Combine
#endif

extension Bitcoin {
  /// A binary encoder for Bitcoin transactions and related structures.
  ///
  /// This encoder supports Bitcoin-specific binary serialization rules,
  /// including optional VarInt length prefixes for variable-sized arrays or scripts.
  /// It is intended for serializing structures like transactions, scripts,
  /// inputs, outputs, and other Bitcoin primitives.
  public final class Encoder: @unchecked Sendable {
    
    /// Specifies how variable-sized data should be length-prefixed.
    public enum SizeEncodingFormat: Sendable {
      /// Do not include size prefix.
      /// This is useful when size information is encoded separately or not required.
      case disabled
      
      /// Encode size using Bitcoin's VarInt format.
      /// This is the default and typically used for transaction lists and scripts.
      case varInt
    }
    
    // MARK: - Properties

    /// User-defined contextual information available during encoding.
    ///
    /// Use this to pass custom values to encoding implementations.
    public var userInfo: [CodingUserInfoKey : any Sendable] = [:]
    
    /// Defines how size prefixes should be encoded.
    /// Defaults to `.varInt`.
    public var sizeEncodingFormat: SizeEncodingFormat = .varInt
    
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
      let encoder = Bitcoin._Encoding.Encoder(codingPath: [], userInfo: self.userInfo, storage: storage, sizeEncodingFormat: self.sizeEncodingFormat)
      try value.encode(to: encoder)
      return storage.encodedData()
    }
  }
}

#if canImport(Combine)
/// Enables usage of `Bitcoin.Encoder` with Combine pipelines.
extension Bitcoin.Encoder: TopLevelEncoder {}
#endif
