//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation

extension Solana {
  /// The header determines how to interpret the *ordering* of `accountKeys`:
  ///
  /// - The first `numRequiredSignatures` accounts are **signers**.
  ///   - Of these signers, the **last** `numReadonlySignedAccounts` are read-only.
  ///   - Therefore, the first `numRequiredSignatures - numReadonlySignedAccounts` signers are writable.
  /// - The remaining accounts are **non-signers**.
  ///   - Of these non-signers, the **last** `numReadonlyUnsignedAccounts` are read-only.
  ///   - Therefore, the first `(accountKeys.count - numRequiredSignatures) - numReadonlyUnsignedAccounts`
  ///     non-signers are writable.
  ///
  /// This is exactly how writability is derived in `Message.isAccountWritable(index:)`.
  public struct MessageHeader: Equatable, Sendable {
    /// The number of signatures required for this message to be considered valid.
    /// The signatures must match the first `numRequiredSignatures` entries of `accountKeys`.
    package let numRequiredSignatures: UInt8
    
    /// Among the *signed* keys (the first `numRequiredSignatures`), the **last**
    /// `numReadonlySignedAccounts` are read-only accounts.
    package let numReadonlySignedAccounts: UInt8
    
    /// Among the *unsigned* keys (the remainder after the first `numRequiredSignatures`),
    /// the **last** `numReadonlyUnsignedAccounts` are read-only accounts.
    package let numReadonlyUnsignedAccounts: UInt8
  }
}

extension Solana.MessageHeader: Codable {
  public init(from decoder: any Decoder) throws {
    var container = try decoder.unkeyedContainer()
    
    self.numRequiredSignatures = try container.decode(UInt8.self)
    self.numReadonlySignedAccounts = try container.decode(UInt8.self)
    self.numReadonlyUnsignedAccounts = try container.decode(UInt8.self)
  }
  
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.unkeyedContainer()
    
    try container.encode(numRequiredSignatures)
    try container.encode(numReadonlySignedAccounts)
    try container.encode(numReadonlyUnsignedAccounts)
  }
}
