//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  /// Discriminated wrapper over Solana message variants.
  ///
  /// - `.legacy` – Unversioned `Message` (no version prefix).
  /// - `.v0` – Versioned `MessageV0` with Address Lookup Tables.
  public enum VersionedMessage {
    /// A legacy (unversioned) message.
    case legacy(Solana.Message)
    /// A v0 message with address table lookups.
    case v0(Solana.MessageV0)
    
    /// The interpreted message version for this wrapper.
    public var version: Solana.Version {
      switch self {
      case .legacy(let message):   return message.version
      case .v0(let message):       return message.version
      }
    }
    
    /// The message header (signature counts and readonly flags).
    public var header: Solana.MessageHeader {
      switch self {
      case .legacy(let message):   return message.header
      case .v0(let message):       return message.header
      }
    }
    
    /// Static account keys present in the message (excludes lookup-loaded keys).
    public var staticAccountKeys: [PublicKey] {
      switch self {
      case .legacy(let message):   return message.accountKeys
      case .v0(let message):       return message.staticAccountKeys
      }
    }
    
    /// Message instructions compiled against message key indexes.
    public var compiledInstructions: [Solana.MessageCompiledInstruction] {
      switch self {
      case .legacy(let message):   return message.compiledInstructions
      case .v0(let message):       return message.compiledInstructions
      }
    }
    
    /// Recent blockhash used by the message.
    public var recentBlockhash: String {
      switch self {
      case .legacy(let message):   return message.recentBlockhash
      case .v0(let message):       return message.recentBlockhash
      }
    }
    
    /// Resolves a `MessageAccountKeys` view for this message.
    ///
    /// - For `.legacy`, lookups are ignored and static keys are returned.
    /// - For `.v0`, you may provide `accountKeysFromLookups` directly, or
    ///   `addressLookupTableAccounts` to resolve them on-the-fly.
    public func getAccountKeys(accountKeysFromLookups: AccountKeysFromLookups? = nil, addressLookupTableAccounts: [AddressLookupTableAccount]? = nil) throws -> MessageAccountKeys {
      switch self {
      case .legacy(let message):
        return message.getAccountKeys()
      case .v0(let message):
        if let accountKeysFromLookups {
          return try message.getAccountKeys(accountKeysFromLookups: accountKeysFromLookups)
        } else if let addressLookupTableAccounts {
          return try message.getAccountKeys(addressLookupTableAccounts: addressLookupTableAccounts)
        } else {
          return try message.getAccountKeys()
        }
      }
    }
  }
}

extension Solana.VersionedMessage: Codable {
  public init(from decoder: any Decoder) throws {
    let versionContainer = try decoder.singleValueContainer()
    
    // Decode the discriminator (does not advance for legacy in your custom decoder).
    let version = try versionContainer.decode(Solana.Version.self)
    
    switch version {
    case .legacy:
      let message = try Solana.Message(from: decoder)
      self = .legacy(message)
    case .v0:
      let v0Message = try Solana.MessageV0(from: decoder)
      self = .v0(v0Message)
    default:
      // Forward-compatibility: we don’t know how to decode other versions here.
      throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported version \(version)"))
    }
  }
  
  // Delegate to concrete message encoders.
  // `Message.encode` does *not* write a version byte (legacy),
  // `MessageV0.encode` writes the version prefix first.
  public func encode(to encoder: any Encoder) throws {
    switch self {
    case .legacy(let message):
      try message.encode(to: encoder)
    case .v0(let message):
      try message.encode(to: encoder)
    }
  }
}
