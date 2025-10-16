//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/10/25.
//

import Foundation
import mew_wallet_ios_kit_utils

extension Solana._ShortVecDecoding {
  /// A low-level binary decoder that conforms to Swift's `Decoder` protocol and
  /// understands Solana's shortvec/varint-oriented wire formats (e.g., Transaction,
  /// Message, and MessageV0).
  ///
  /// This decoder maintains:
  /// - an `offset` into a `Data.SubSequence` that advances as bytes are consumed,
  /// - a decoding `section` (a lightweight state machine indicating which part
  ///   of the wire format is expected next),
  /// - a `version` flag for legacy vs. versioned message semantics,
  /// - and standard `codingPath`/`userInfo` for diagnostics and customization.
  ///
  /// Containers:
  /// - `unkeyedContainer()` — for ordered sequences (arrays, instruction lists, etc.)
  /// - `singleValueContainer()` — for scalars and fixed-layout records
  /// - keyed containers are **not supported** because the wire format is positional
  internal final class Decoder: Swift.Decoder {
    /// Message format version recognized by this decoder.
    /// - `.legacy` — legacy `Message` (no version prefix; header starts immediately)
    /// - `.v0` — versioned `MessageV0` (prefixed with a version discriminator)
    /// - `.unknown(n)` — reserved for forward-compatibility with future versions
    enum Version {
      case legacy
      case v0
      case unknown(UInt8)
    }
    
    /// High-level decoding state. Represents entry points and sub-states the
    /// decoder expects to parse next. This acts as a minimal state machine
    /// guiding how shortvec lengths and fixed fields are interpreted.
    enum Section {
      /// Let downstream logic infer the entry point from initial bytes (auto-detect).
      case universal
      
      enum Transaction {
        case signatures                             // shortvec count + N signatures (64 bytes each)
        case message                                // the serialized Message bytes
      }
      case transaction(Transaction)
      
      enum Message {
        case version                                // optional version discriminator (for v0)
        case header                                 // MessageHeader: 3 bytes (u8, u8, u8)
        
        enum AccountKeys {
          case array(count: Int)                    // shortvec count has been read; expect N keys
          case publicKey(count: Int)                // ingest one 32-byte pubkey; decrement remaining
        }
        case accountKeys(AccountKeys)
        
        case recentBlockhash                        // 32 bytes (base58-decoded hash)
        
        enum Instructions {
          case array(count: Int)                    // shortvec count; expect N instructions
          case instruction(count: Int)              // parse one instruction; decrement remaining
        }
        case instructions(Instructions)
        
        enum AddressTableLookups {
          case array(count: Int)                    // shortvec count; expect N lookups
          
          enum AddressTableLookup {
            case addressTableLookup(count: Int)     // parse one lookup; decrement remaining
            case publicKey(count: Int)              // next 32 bytes are a table address
            case fields(count: Int)                 // parse `readable/writable` indices (shortvecs)
          }
          case addressTableLookups(AddressTableLookup)
        }
        case addressTableLookups(AddressTableLookups)
      }
      case message(Message)
    }
    /// Underlying binary slice to be decoded (often contains shortvec-prefixed segments).
    let data: Data.SubSequence
    
    /// Current read offset into `data`. Advanced as bytes are consumed.
    var offset: Data.SubSequence.Index
    
    /// Current decoding section (state).
    var section: Section
    
    /// Message version mode (legacy, v0, or unknown for forward-compat).
    var version: Version = .legacy
    
    /// Current coding path (useful for diagnostics).
    let codingPath: [any CodingKey]
    
    /// Arbitrary user information for downstream consumers.
    let userInfo: [CodingUserInfoKey: Any]

    /// Initializes a new shortvec-aware decoder positioned at `offset` within `data`,
    /// with an initial `section` state and optional diagnostics context.
    ///
    /// - Parameters:
    ///   - data: The raw binary slice being decoded.
    ///   - offset: The starting index into `data` from which decoding begins.
    ///   - section: The initial state guiding how to interpret subsequent bytes.
    ///   - codingPath: An optional coding path for diagnostic context (defaults to empty).
    ///   - userInfo: Arbitrary user info for customization (defaults to empty).
    init(data: Data.SubSequence, offset: inout Data.SubSequence.Index, section: Decoder.Section, codingPath: [any CodingKey] = [], userInfo: [CodingUserInfoKey : Any]) {
      self.data = data
      self.offset = offset
      self.section = section
      self.codingPath = codingPath
      self.userInfo = userInfo
    }
    
    /// Keyed containers are not supported because Solana's wire format is positional.
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
      throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: codingPath, debugDescription: "KeyedContainer is not supported"))
    }
    
    /// Returns an unkeyed container for decoding ordered sequences (arrays).
    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
      return UnkeyedContainer(decoder: self)
    }
    
    /// Returns a single-value container for decoding scalars and fixed-layout records.
    func singleValueContainer() throws -> any SingleValueDecodingContainer {
      return SingleValueContainer(decoder: self)
    }
  }
}
