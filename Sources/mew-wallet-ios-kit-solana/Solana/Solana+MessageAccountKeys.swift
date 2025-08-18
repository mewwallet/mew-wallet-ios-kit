//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  public struct MessageAccountKeys: Sendable, Equatable {
    public enum Error: Swift.Error, Equatable {
      case accountIndexOverflow
      case unknownInstructionAccountKey(PublicKey)
    }
    let staticAccountKeys: [PublicKey]
    let accountKeysFromLookups: AccountKeysFromLookups?
    
    public init(staticAccountKeys: [PublicKey], accountKeysFromLookups: AccountKeysFromLookups? = nil) {
      self.staticAccountKeys = staticAccountKeys
      self.accountKeysFromLookups = accountKeysFromLookups
    }
    
    public var keySegments: [[PublicKey]] {
      var segments: [[PublicKey]] = [staticAccountKeys]
      guard let accountKeysFromLookups else { return segments }
      if !accountKeysFromLookups.writable.isEmpty || !accountKeysFromLookups.readonly.isEmpty {
        segments.append(accountKeysFromLookups.writable)
        segments.append(accountKeysFromLookups.readonly)
      }
      return segments
    }
    
    var count: Int {
      self.keySegments.flatMap({ $0 }).count
    }
    
    public func get(keyAtIndex index: Int) -> PublicKey? {
      var index = index
      for segment in self.keySegments {
        guard index < segment.count else {
          index -= segment.count
          continue
        }
        return segment[index]
      }
      return nil
    }
    
    public func compileInstructions(_ instructions: [TransactionInstruction]) throws -> [MessageCompiledInstruction] {
      // Bail early if any account indexes would overflow a u8
      guard count <= 255 else {
        throw Error.accountIndexOverflow
      }
      
      let segments = self.keySegments.flatMap({ $0 })
      
      var keyIndexMap: [PublicKey: Int] = [:]
      keyIndexMap.reserveCapacity(segments.count)
      segments.enumerated()
        .forEach { element in
          keyIndexMap[element.element] = element.offset
        }
      
      let findKeyIndex: (PublicKey) throws -> UInt8 = { key in
        guard let index = keyIndexMap[key] else {
          throw Error.unknownInstructionAccountKey(key)
        }
        return UInt8(clamping: index)
      }
      
      return try instructions.map { instruction in
        return try .init(
            programIdIndex: findKeyIndex(instruction.programId),
            accountKeyIndexes: instruction.keys.map({ meta in
              try findKeyIndex(meta.pubkey)
            }),
            data: instruction.data
        )
      }
    }
  }
}
