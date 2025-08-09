//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation

extension Solana {
  public struct MessageHeader: Equatable, Sendable {
    /// The number of signatures required for this message to be considered valid. The
    /// signatures must match the first `numRequiredSignatures` of `accountKeys`.
    package let numRequiredSignatures: UInt8
    
    /// The last `numReadonlySignedAccounts` of the signed keys are read-only accounts
    package let numReadonlySignedAccounts: UInt8
    
    /// The last `numReadonlySignedAccounts` of the unsigned keys are read-only accounts
    package let numReadonlyUnsignedAccounts: UInt8
  }
}

extension Solana.MessageHeader: Encodable {
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.unkeyedContainer()
    
    try container.encode(numRequiredSignatures)
    try container.encode(numReadonlySignedAccounts)
    try container.encode(numReadonlyUnsignedAccounts)
  }
}
