//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation

extension UInt8 {
  /// Version prefix constants used in **versioned Solana messages**.
  ///
  /// These constants define how the message version byte is interpreted:
  ///
  /// - `VERSION_PREFIX (0x80)` — Marks that the message is **versioned**.
  ///   Solana sets the high bit (bit 7) to indicate a versioned message.
  ///
  /// Example:
  /// ```
  /// let prefix: UInt8 = 0x80 | 0x00  // Versioned message (v0)
  /// let version = prefix & UInt8.VERSION_PREFIX_MASK  // → 0
  /// ```
  static let VERSION_PREFIX: Self = 0x80
  
  /// Version prefix constants used in **versioned Solana messages**.
  ///
  /// These constants define how the message version byte is interpreted:
  ///
  /// - `VERSION_PREFIX_MASK (0x7F)` — Used to **extract the version number**
  ///   by masking out the prefix bit (`byte & VERSION_PREFIX_MASK`).
  ///
  /// Example:
  /// ```
  /// let prefix: UInt8 = 0x80 | 0x00  // Versioned message (v0)
  /// let version = prefix & UInt8.VERSION_PREFIX_MASK  // → 0
  /// ```
  static let VERSION_PREFIX_MASK: Self = 0x7F
}
