//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation

extension Solana {
  public enum Version: Sendable, Equatable, Hashable {
    case legacy
    case v0
    case unknown(UInt8)
  }
}

extension Solana.Version: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let prefix = try container.decode(UInt8.self)
    
    // if the highest bit of the prefix is not set, the message is not versioned
    let maskedPrefix = prefix & .VERSION_PREFIX_MASK
    
    guard maskedPrefix != prefix else {
      self = .legacy
      return
    }
    
    // the lower 7 bits of the prefix indicate the message version
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
