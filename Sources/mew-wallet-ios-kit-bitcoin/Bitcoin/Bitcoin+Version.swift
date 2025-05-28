//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/14/25.
//

import Foundation

extension Bitcoin {
  /// Represents the version of a Bitcoin transaction.
  ///
  /// - `version_1` and `version_2` are the most commonly used versions.
  /// - `unknown` captures all other versions that may be used in non-standard or future transactions.
  public enum Version: RawRepresentable, Equatable, Sendable, Hashable {
    /// Version 1 (default for legacy transactions).
    case version_1
    
    /// Version 2 (commonly used for RBF-enabled or modern transactions).
    case version_2
    
    /// Unknown or unsupported version, captured as a raw `UInt32`.
    case unknown(UInt32)
    
    /// Initializes a version from a raw `UInt32` value.
    /// Recognizes version 1 and 2; others are wrapped in `.unknown`.
    public init?(rawValue: UInt32) {
      switch rawValue {
      case 1:     self = .version_1
      case 2:     self = .version_2
      default:    self = .unknown(rawValue)
      }
    }
    
    /// The raw `UInt32` value of the transaction version.
    public var rawValue: UInt32 {
      switch self {
      case .version_1:                    return 1
      case .version_2:                    return 2
      case .unknown(let version):         return version
      }
    }
  }
}

extension Bitcoin.Version: Codable {
  /// Decodes a version from a single `UInt32` value.
  /// If the value is not 1 or 2, it will be wrapped in `.unknown`.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let value = try container.decode(UInt32.self)
    self = .init(rawValue: value) ?? .unknown(value)
  }
  
  /// Encodes the version as a single `UInt32` value.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.rawValue)
  }
}
