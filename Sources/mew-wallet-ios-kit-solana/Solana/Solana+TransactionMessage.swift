//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  public struct TransactionMessage: Sendable, Equatable {
    public enum Error: Swift.Error, Equatable {
      case invalidMessageHeader
      case noAccountKeys
      case noKeyForAccount(Int)
      case noProgramId(Int)
    }
    
    public let payerKey: PublicKey
    public let instructions: [TransactionInstruction]
    public let recentBlockhash: String
    
    public init(payerKey: PublicKey,
         instructions: [TransactionInstruction],
         recentBlockhash: String) {
      self.payerKey = payerKey
      self.instructions = instructions
      self.recentBlockhash = recentBlockhash
    }
    
    public init(message: Solana.Message, accountKeysFromLookups: AccountKeysFromLookups? = nil, addressLookupTableAccounts: [AddressLookupTableAccount]? = nil) throws {
      try self.init(message: .legacy(message), accountKeysFromLookups: accountKeysFromLookups, addressLookupTableAccounts: addressLookupTableAccounts)
    }
    
    public init(message: Solana.MessageV0, accountKeysFromLookups: AccountKeysFromLookups? = nil, addressLookupTableAccounts: [AddressLookupTableAccount]? = nil) throws {
      try self.init(message: .v0(message), accountKeysFromLookups: accountKeysFromLookups, addressLookupTableAccounts: addressLookupTableAccounts)
    }
    
    public init(message: VersionedMessage, accountKeysFromLookups: AccountKeysFromLookups? = nil, addressLookupTableAccounts: [AddressLookupTableAccount]? = nil) throws {
      let header = message.header
      let compiledInstructions = message.compiledInstructions
      let recentBlockhash = message.recentBlockhash
      
      let numRequiredSignatures = Int(header.numRequiredSignatures)
      let numReadonlySignedAccounts = Int(header.numReadonlySignedAccounts)
      let numReadonlyUnsignedAccounts = Int(header.numReadonlyUnsignedAccounts)
      
      let numWritableSignedAccounts = numRequiredSignatures - numReadonlySignedAccounts
      guard numWritableSignedAccounts > 0 else {
        throw Error.invalidMessageHeader
      }
      
      let numWritableUnsignedAccounts = message.staticAccountKeys.count - numRequiredSignatures - numReadonlyUnsignedAccounts
      guard numWritableUnsignedAccounts >= 0 else {
        throw Error.invalidMessageHeader
      }
      
      let accountKeys = try message.getAccountKeys(accountKeysFromLookups: accountKeysFromLookups, addressLookupTableAccounts: addressLookupTableAccounts)
      
      
      guard let payerKey = accountKeys.get(keyAtIndex: 0) else {
        throw Error.noAccountKeys
      }
      
      let instructions: [TransactionInstruction] = try compiledInstructions.map { compiledIx in
        let keys: [Solana.AccountMeta] = try compiledIx.accountKeyIndexes
          .map { Int($0) }
          .map { keyIndex in
            guard let pubkey = accountKeys.get(keyAtIndex: keyIndex) else {
              throw Error.noKeyForAccount(Int(keyIndex))
            }
            let isSigner = keyIndex < numRequiredSignatures
            let isWritable: Bool
            if isSigner {
              isWritable = keyIndex < numWritableSignedAccounts
            } else if keyIndex < accountKeys.staticAccountKeys.count {
              isWritable = (keyIndex - numRequiredSignatures) < numWritableUnsignedAccounts
            } else {
              isWritable = (keyIndex - accountKeys.staticAccountKeys.count) < (accountKeys.accountKeysFromLookups?.writable.count ?? 0)
            }
            return .init(
              pubkey: pubkey,
              isSigner: isSigner,
              isWritable: isWritable
            )
          }
        
        guard let programId = accountKeys.get(keyAtIndex: Int(compiledIx.programIdIndex)) else {
          throw Error.noProgramId(Int(compiledIx.programIdIndex))
        }
        return .init(
          keys: keys,
          programId: programId,
          data: compiledIx.data
        )
      }
      
      self.init(
        payerKey: payerKey,
        instructions: instructions,
        recentBlockhash: recentBlockhash
      )
    }
    
    static func decompile(_ message: VersionedMessage/*, args: DecompileArgs? = nil*/) throws -> TransactionMessage {
      fatalError()
    }
    
    public func compileToV0Message(addressLookupTableAccounts: [AddressLookupTableAccount]? = nil) throws -> VersionedMessage {
      let message = try MessageV0(
        payerKey: payerKey,
        instructions: instructions,
        recentBlockhash: recentBlockhash,
        addressLookupTableAccounts: addressLookupTableAccounts
      )
      return .v0(message)
    }
  }
}
