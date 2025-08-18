//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/10/25.
//

import Foundation
import mew_wallet_ios_kit_utils

extension Solana._ShortVecDecoding {
  internal final class Decoder: Swift.Decoder {
    enum Version {
      case legacy
      case v0
      case unknown(UInt8)
    }
    
    enum Section {
      case universal
      
      enum Transaction {
        case signatures
        case message
      }
      case transaction(Transaction)
      enum Message {
        case version
        case header
        
        enum AccountKeys {
          case array(count: Int)
          case publicKey(count: Int)
        }
        case accountKeys(AccountKeys)
        case recentBlockhash
        
        enum Instructions {
          case array(count: Int)
          case instruction(count: Int)
        }
        
        case instructions(Instructions)
        
        enum AddressTableLookups {
          case array(count: Int)
          
          enum AddressTableLookup {
            case addressTableLookup(count: Int)
            case publicKey(count: Int)
            case fields(count: Int)
          }
          case addressTableLookups(AddressTableLookup)
        }
        case addressTableLookups(AddressTableLookups)
      }
      case message(Message)
    }
    /// Binary data fragments to be decoded, often VarInt-prefixed.
    let data: Data.SubSequence
    var offset: Data.SubSequence.Index
    var section: Section
    var version: Version = .legacy
    
    /// Current decoding path (for diagnostics and recursion).
    let codingPath: [any CodingKey]
    
    /// Arbitrary user info provided by the caller.
    let userInfo: [CodingUserInfoKey: Any]
    
    /// Constructs a new PSBT decoder for the given data payload.
    ///
    /// - Parameters:
    ///   - data: Raw binary chunks to decode.
    ///   - context: Optional context for decoding logic.
    ///   - map: Optional pre-parsed maps (e.g. structured PSBT fields).
    ///   - codingPath: Initial coding path (defaults to empty).
    ///   - userInfo: Custom user data (e.g. used by downstream tools).
    init(data: Data.SubSequence, offset: inout Data.SubSequence.Index, section: Decoder.Section, codingPath: [any CodingKey] = [], userInfo: [CodingUserInfoKey : Any]) {
      self.data = data
      self.offset = offset
      self.section = section
      self.codingPath = codingPath
      self.userInfo = userInfo
    }
    
    /// Creates a keyed container for decoding structured key-value pairs (e.g. PSBT maps).
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
      throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: codingPath, debugDescription: "KeyedContainer is not supported"))
    }
    
    /// Creates an unkeyed container for decoding an ordered list of elements.
    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
      return UnkeyedContainer(decoder: self)
    }
    
    /// Creates a single-value container for decoding a primitive value or wrapped structure.
    func singleValueContainer() throws -> any SingleValueDecodingContainer {
      return SingleValueContainer(decoder: self)
    }
  }
}
