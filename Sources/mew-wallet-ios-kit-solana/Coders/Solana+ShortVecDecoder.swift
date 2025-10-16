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
  /// A top-level binary decoder for Solana’s **shortvec/varint-based** wire formats.
  ///
  /// `ShortVecDecoder` drives decoding for different Solana payloads (legacy `Transaction`,
  /// `Message`, and versioned `MessageV0`). It sets the initial decoding **section**
  /// and toggles versioning so nested decoders know how to interpret varints,
  /// account key lists, and instruction layouts.
  ///
  /// Use `decodingStyle` to select the correct entry point for the buffer you’re decoding.
  open class ShortVecDecoder {
    // MARK: Decoding Style

    /// Selects the entry section and versioning mode for the input buffer.
    ///
    /// - `.transaction` — Start at the top of a legacy **Transaction** (`signatures` shortvec, then message bytes).
    /// - `.message` — Start at the top of a legacy **Message** (header/version marker).
    /// - `.messageV0` — Start at the top of a **MessageV0** (versioned message with address tables).
    /// - `.version` — Reads a versioned message envelope (sets `version = .v0` for downstream decoding).
    /// - `.universal` — Allows a downstream decoder to auto-detect based on the buffer (advanced).
    public enum DecodingStyle {
      case transaction
      case message
      case messageV0
      case version
      case universal
      
      /// Internal: maps a style to the initial decoding **section** of the low-level decoder.
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

    /// Arbitrary, user-supplied context passed down to nested decoders.
    ///
    /// Use this to provide auxiliary information (e.g., cluster config, program id hints)
    /// to custom `Decodable` implementations encountered during decoding.
    public var userInfo: [CodingUserInfoKey : any Sendable] = [:]
    
    public var decodingStyle: DecodingStyle = .transaction
    
    // MARK: - Init

    /// Creates a new `Solana.ShortVecDecoder`.
    public init() { }
    
    // MARK: - Top-level decode

    /// Decodes a value of the given type from Solana shortvec-encoded binary data.
    ///
    /// Sets up the low-level decoder with:
    /// - a moving offset into `data`,
    /// - an initial `section` (derived from `decodingStyle`),
    /// - optional `userInfo`,
    /// - and `version = .v0` when required for versioned messages.
    ///
    /// - Parameters:
    ///   - type: The `Decodable` type to decode.
    ///   - data: The binary buffer to decode from.
    /// - Returns: A decoded value of type `T`.
    /// - Throws: Low-level decoding errors (malformed shortvec, OOB reads, unexpected section/version).
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
/// Enables use with Combine’s `decode(type:decoder:)` operator.
extension Solana.ShortVecDecoder: TopLevelDecoder {}
#endif
