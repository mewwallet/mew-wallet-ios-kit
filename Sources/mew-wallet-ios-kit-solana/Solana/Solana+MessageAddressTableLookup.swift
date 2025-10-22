//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  /// Describes a single Address Lookup Table (ALT) entry referenced by a v0 message.
  ///
  /// The lookup tells the runtime which on-chain ALT account to read, and which
  /// *indices* (shortvec-encoded) within that ALT’s address array to load as
  /// additional writable / read-only accounts for this message.
  public struct MessageAddressTableLookup: Equatable, Sendable {
    /// The public key of the ALT account to read from.
    public let accountKey: PublicKey
    
    /// Shortvec-encoded list of **u8 indices** into the ALT’s address array for
    /// accounts that must be loaded as **writable**.
    public let writableIndexes: [UInt8]
    
    /// Shortvec-encoded list of **u8 indices** into the ALT’s address array for
    /// accounts that must be loaded as **read-only**.
    public let readonlyIndexes: [UInt8]
    
    public init(accountKey: PublicKey, writableIndexes: [UInt8], readonlyIndexes: [UInt8]) {
      precondition(writableIndexes.count <= 255 && readonlyIndexes.count <= 255)
      self.accountKey = accountKey
      self.writableIndexes = writableIndexes
      self.readonlyIndexes = readonlyIndexes
    }
  }
}

extension Solana.MessageAddressTableLookup: Codable {
  /// Decodes according to Solana v0 message layout:
  /// `accountKey` (32 bytes) +
  /// shortvec(`writableIndexes.count`) + raw `writableIndexes` bytes +
  /// shortvec(`readonlyIndexes.count`) + raw `readonlyIndexes` bytes.
  ///
  /// Your custom ShortVec decoder drives the state machine so that
  /// `[UInt8].self` in the “fields” section reads a shortvec length followed by
  /// exactly that many raw bytes.
  public init(from decoder: any Decoder) throws {
    var container = try decoder.unkeyedContainer()
    
    self.accountKey = try container.decode(PublicKey.self)
    self.writableIndexes = try container.decode([UInt8].self)
    self.readonlyIndexes = try container.decode([UInt8].self)
  }
  
  /// Encodes with the same layout the decoder expects:
  /// - `accountKey`
  /// - shortvec(length) + raw bytes for `writableIndexes`
  /// - shortvec(length) + raw bytes for `readonlyIndexes`
  ///
  /// Note: We **don’t** call `encode([UInt8])` directly because your encoder
  /// would emit each `UInt8` as a varint. We need *raw* bytes, so we:
  ///   1) write the shortvec length manually,
  ///   2) append the raw byte array as `Data`.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.unkeyedContainer()
    
    try container.encode(accountKey)
    try container.encode(writableIndexes.count)
    try container.encode(Data(writableIndexes))
    try container.encode(readonlyIndexes.count)
    try container.encode(Data(readonlyIndexes))
  }
}
