//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  public enum VersionedMessage {
    case legacy(Solana.Message)
    case v0(Solana.MessageV0)
    
    public var version: Solana.Version {
      switch self {
      case .legacy(let message):   return message.version
      case .v0(let message):       return message.version
      }
    }
    
    public var header: Solana.MessageHeader {
      switch self {
      case .legacy(let message):   return message.header
      case .v0(let message):       return message.header
      }
    }
    
    public var staticAccountKeys: [PublicKey] {
      switch self {
      case .legacy(let message):   return message.accountKeys
      case .v0(let message):       return message.staticAccountKeys
      }
    }
    
    public var compiledInstructions: [Solana.MessageCompiledInstruction] {
      switch self {
      case .legacy(let message):   return message.compiledInstructions
      case .v0(let message):       return message.compiledInstructions
      }
    }
    
    public var recentBlockhash: String {
      switch self {
      case .legacy(let message):   return message.recentBlockhash
      case .v0(let message):       return message.recentBlockhash
      }
    }
    
    func getAccountKeys(accountKeysFromLookups: AccountKeysFromLookups? = nil, addressLookupTableAccounts: [AddressLookupTableAccount]? = nil) throws -> MessageAccountKeys {
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
    let verion = try versionContainer.decode(Solana.Version.self)
    
    switch verion {
    case .legacy:
      let message = try Solana.Message(from: decoder)
      self = .legacy(message)
    case .v0:
      let v0Message = try Solana.MessageV0(from: decoder)
      self = .v0(v0Message)
    default:
      throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported version \(verion)"))
    }
  }
  
  public func encode(to encoder: any Encoder) throws {
    switch self {
    case .legacy(let message):
      try message.encode(to: encoder)
    case .v0(let message):
      try message.encode(to: encoder)
    }
  }
}
