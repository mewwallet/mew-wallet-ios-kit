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
  /// A top-level binary encoder for Solana’s **shortvec/varint-based** wire formats.
  ///
  /// `ShortVecEncoder` produces deterministic, allocation-efficient binary output compatible
  /// with Solana message/transaction encoding conventions:
  /// - **ShortVec (base-128 varint)** for lengths of dynamic arrays/byte buffers.
  /// - **Little-endian** for fixed-width integers where applicable in instruction payloads.
  /// - **32-byte raw buffers** for public keys.
  ///
  /// The actual field layout is defined by the `Encodable` types you pass in, which are
  /// expected to cooperate with the internal `_ShortVecEncoding.Encoder` (e.g., by writing
  /// shortvec lengths for arrays and fixed-width numeric fields in LE as needed).
  ///
  /// > Note:
  /// > This encoder is **not** JSON; it writes raw bytes in the exact order your types request.
  public final class ShortVecEncoder: @unchecked Sendable {
    // MARK: - Properties
    
    /// User-provided contextual information available to nested encoders during encoding.
    ///
    /// You can use this to pass auxiliary values (e.g., cluster hints, feature flags) that
    /// custom `Encodable` implementations may consult when deciding how to encode themselves.
    public var userInfo: [CodingUserInfoKey : any Sendable] = [:]
    
    // MARK: - Init
    
    /// Creates a new `ShortVecEncoder`.
    public init() { }
    
    // MARK: - Encoding
    
    /// Encodes an `Encodable` value into Solana **shortvec-compatible** binary `Data`.
    ///
    /// - Parameter value: The value to encode.
    /// - Returns: A `Data` buffer containing the binary representation.
    /// - Throws: Any error raised by the value’s `encode(to:)` implementation or the
    ///           underlying storage/encoding primitives (e.g., range checks).
    ///
    /// - Important:
    ///   This encoder assumes your `Encodable` types follow Solana’s binary conventions
    ///   (shortvec for lengths, fixed-width little-endian where required, and raw 32-byte
    ///   public keys). Mismatched conventions will yield data that on-chain programs and
    ///   other SDKs cannot parse.
    public func encode<T>(_ value: T) throws -> Data where T : Encodable {
      let storage = BinaryStorage()
      let encoder = Solana._ShortVecEncoding.Encoder(codingPath: [], userInfo: self.userInfo, storage: storage)
      try value.encode(to: encoder)
      return storage.encodedData()
    }
  }
}

#if canImport(Combine)
/// Enables use of `Solana.ShortVecEncoder` with Combine’s `encode`/`map` pipelines.
extension Solana.ShortVecEncoder: TopLevelEncoder {}
#endif
