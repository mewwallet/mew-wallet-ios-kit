//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation

extension Solana {
  /// Represents the version of a Solana message.
  ///
  /// Solana transaction messages may be:
  /// - **Legacy** (unversioned): used before versioned transactions were introduced.
  /// - **v0**: the current versioned message format with support for Address Lookup Tables (ALTs).
  /// - **unknown(_:)**: a fallback case for forward-compatibility, capturing any unrecognized version byte.
  public enum Version: Sendable, Equatable, Hashable {
    /// Legacy (unversioned) message.
    case legacy
    /// Version 0 (supports Address Lookup Tables).
    case v0
    /// Unknown or future version, carrying the raw version number.
    case unknown(UInt8)
  }
}

extension Solana.Version: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let prefix = try container.decode(UInt8.self)
    
    // If the highest bit of the prefix is *not* set, this is an unversioned (legacy) message.
    let maskedPrefix = prefix & .VERSION_PREFIX_MASK
    
    guard maskedPrefix != prefix else {
      self = .legacy
      return
    }
    
    // Lower 7 bits represent the version.
    switch maskedPrefix {
    case 0:
      self = .v0
    default:
      self = .unknown(maskedPrefix)
    }
  }
  
  public func encode(to encoder: any Encoder) throws {
    switch self {
    case .legacy:
      // Legacy messages have no prefix byte at all.
      break
    case .v0:
      var container = encoder.singleValueContainer()
      try container.encode(Data([.VERSION_PREFIX]))
    case .unknown(let version):
      var container = encoder.singleValueContainer()
      try container.encode(Data([.VERSION_PREFIX | (version & .VERSION_PREFIX_MASK)]))
    }
  }
}
