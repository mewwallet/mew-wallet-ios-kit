//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/17/25.
//

import Foundation

extension Bitcoin {
  /// Represents a Bitcoin signature hash type (SIGHASH) used during transaction signing.
  /// Supports standard SIGHASH modes, the ANYONECANPAY flag, and combinations thereof.
  /// See BIP-143, BIP-341 for usage in legacy and SegWit/Taproot contexts.
  public struct SigHash: OptionSet, Sendable, Equatable, Hashable {
    /// The raw UInt32 representation of the SigHash flags.
    public let rawValue: UInt32
    
    public init(rawValue: UInt32) {
      self.rawValue = rawValue
    }
    
    /// SIGHASH_DEFAULT (0x00): Taproot only; equivalent to SIGHASH_ALL, implied when missing.
    public static let `default`                = Self([])                  // 0b0000_0000

    /// SIGHASH_ALL (0x01): Signs all inputs and all outputs.
    public static let all                      = Self(rawValue: 0x01)      // 0b0000_0001

    /// SIGHASH_NONE (0x02): Signs all inputs but no outputs.
    public static let none                     = Self(rawValue: 0x02)      // 0b0000_0010

    /// SIGHASH_SINGLE (0x03): Signs all inputs and one corresponding output.
    public static let single                   = Self(rawValue: 0x03)      // 0b0000_0011

    /// SIGHASH_ANYONECANPAY (0x80): Signs only the current input (bitwise flag).
    public static let anyoneCanPay             = Self(rawValue: 0x80)      // 0b1000_0000
    
    /// Bitmask for the output selection portion of the sighash flag.
    public static let outputMask               = Self(rawValue: 0x03)      // 0b0000_0011

    /// Bitmask for the input selection portion (just ANYONECANPAY).
    public static let inputMask                = Self(rawValue: 0x80)      // 0b1000_0000
    
    /// Bitmask used in BIP-143 to strip sighash to known values. https://en.bitcoin.it/wiki/BIP_0143
    public static let maskAnyCanPay            = Self(rawValue: 0x1f)      // 0b0001_1111
    
    /// SIGHASH_ALL | ANYONECANPAY
    public static let allAnyoneCanPay: Self    = [.all, .anyoneCanPay]     // 0b1000_0001
    
    /// SIGHASH_NONE | ANYONECANPAY
    public static let noneAnyoneCanPay: Self   = [.none, .anyoneCanPay]    // 0b1000_0010

    /// SIGHASH_SINGLE | ANYONECANPAY
    public static let singleAnyoneCanPay: Self = [.single, .anyoneCanPay]  // 0b1000_0011
    
    /// Returns the lowest byte of the rawValue (as written in serialized transactions).
    public var `type`: UInt8 {
      return UInt8(truncatingIfNeeded: self.rawValue)
    }

    /// Returns true if sighash type is SINGLE (ignoring ANYONECANPAY flag).
    public var isSingle: Bool {
      return self.intersection(.maskAnyCanPay) == .single
    }

    /// Returns true if sighash type is NONE (ignoring ANYONECANPAY flag).
    public var isNone: Bool {
      return self.intersection(.maskAnyCanPay) == .none
    }
  }
}

// MARK: - Bitcoin.SigHash + Codable

extension Bitcoin.SigHash: Codable {
  /// Decodes a SigHash from a UInt32 (as stored in PSBT or raw tx encoding).
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.rawValue = try container.decode(UInt32.self)
  }

  /// Encodes SigHash as its UInt32 representation.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.rawValue)
  }
}
