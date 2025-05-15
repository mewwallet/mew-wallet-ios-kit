//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/14/25.
//

import Foundation

extension Bitcoin {
  /// Represents a Bitcoin locktime value, which can either be disabled or locked until a specific block height or Unix timestamp.
  ///
  /// Locktime determines the earliest point in time when a transaction can be added to a valid block.
  /// A locktime value of `0` means the transaction is not time-locked (`.disabled`).
  /// Otherwise, it's either:
  /// - A block height (if `value <= 499_999_999`)
  /// - A Unix timestamp in seconds (if `value >= 500_000_000`)
  ///
  /// This enum provides convenient accessors to interpret the value accordingly.
  public enum Locktime: RawRepresentable, Equatable, Sendable, Hashable {
    /// The highest value considered a block height (less than 500 million).
    private static let maxBlockHeight: UInt32 = 499_999_999
    
    /// Locktime is disabled (value = 0)
    case disabled
    
    /// Locktime is enabled with a raw `UInt32` value
    case locked(UInt32)
    
    /// Initializes a Locktime from its raw `UInt32` value.
    /// - Parameter rawValue: The raw locktime value.
    ///   - `0` → `.disabled`
    ///   - `> 0` → `.locked(value)`
    public init?(rawValue: UInt32) {
      if rawValue == 0 {
        self = .disabled
      } else {
        self = .locked(rawValue)
      }
    }
    
    /// The raw `UInt32` value of the locktime.
    public var rawValue: UInt32 {
      switch self {
      case .disabled:                     return 0
      case .locked(let value):            return value
      }
    }
    
    /// If the locktime is a block height (<= 499,999,999), returns its value. Otherwise, returns `nil`.
    public var blockHeight: UInt32? {
      guard case .locked(let value) = self else { return nil }
      guard value <= Self.maxBlockHeight else { return nil }
      return value
    }
    
    /// If the locktime is a Unix timestamp (>= 500,000,000), returns it as a `TimeInterval`. Otherwise, returns `nil`.
    public var unixTimestamp: TimeInterval? {
      guard case .locked(let value) = self else { return nil }
      guard value > Self.maxBlockHeight else { return nil }
      return TimeInterval(value)
    }
  }
}

// MARK: - Bitcoin.Locktime + Codable

extension Bitcoin.Locktime: Codable {
  /// Decodes the locktime from a `UInt32` value.
  /// - `0` is interpreted as `.disabled`
  /// - Any non-zero value is interpreted as `.locked(value)`
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let value = try container.decode(UInt32.self)
    if value > 0 {
      self = .locked(value)
    } else {
      self = .disabled
    }
  }
  
  /// Encodes the locktime as its raw `UInt32` representation.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.rawValue)
  }
}
