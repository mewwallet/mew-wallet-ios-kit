//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/14/25.
//

import Foundation

extension Bitcoin {
  /// Represents a Bitcoin nSequence field used in transaction inputs.
  /// Supports special values like `0x00000000` (initial), `0xffffffff` (final), and any custom sequence number.
  public enum Sequence: RawRepresentable, Equatable, Sendable, Hashable {
    /// The default initial sequence (`0x00000000`) — used in unsigned or replaceable inputs.
    case initial

    /// A custom sequence number between 1 and `0xfffffffe`.
    case sequence(UInt32)

    /// The final sequence (`0xffffffff`) — used to disable locktime or finalize input.
    case final
    
    /// Initializes from a raw UInt32 value.
    /// Interprets `0x00000000` as `.initial` and `0xffffffff` as `.final`.
    /// All other values are wrapped in `.sequence(_)`.
    public init?(rawValue: UInt32) {
      switch rawValue {
      case 0x00000000:
        self = .initial
        case 0xffffffff:
        self = .final
      default:
        self = .sequence(rawValue)
      }
    }
    
    /// Returns the raw UInt32 value of the sequence case.
    public var rawValue: UInt32 {
      switch self {
      case .initial:                      return 0x00000000
      case .sequence(let value):          return value
      case .final:                        return 0xffffffff
      }
    }
  }
}

// MARK: - Bitcoin.Sequence + Codable

extension Bitcoin.Sequence: Codable {
  /// Decodes a sequence from a UInt32 value.
  /// Falls back to `.sequence(_)` if value is not `0x00` or `0xffffffff`.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let value = try container.decode(UInt32.self)
    self = .init(rawValue: value) ?? .sequence(value)
  }
  
  /// Encodes the sequence as a raw UInt32.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.rawValue)
  }
}
