//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  /// A view over all accounts that can be referenced by compiled instructions:
  /// - the **static** account keys embedded in the legacy/v0 message, and
  /// - the optional **lookup-derived** keys (writable + read-only) for v0.
  ///
  /// This type provides:
  /// - a canonical segmentation of keys in message order,
  /// - O(1) index lookup for instruction compilation,
  /// - helpers to fetch a key by global index.
  public struct MessageAccountKeys: Sendable, Equatable {
    /// Errors that can occur while compiling instructions against the key set.
    public enum Error: Swift.Error, Equatable {
      /// The combined number of addressable keys exceeds the `u8` index space.
      case accountIndexOverflow
      /// An instruction references a key that is not present in the message’s key set.
      case unknownInstructionAccountKey(PublicKey)
    }
    
    /// The static account keys present directly in the message.
    /// For legacy messages, this is the entire key set.
    /// For v0 messages, these are the “static” (non-ALT) keys.
    let staticAccountKeys: [PublicKey]
    
    /// Optional keys loaded via Address Lookup Tables (v0 only), split
    /// into writable and read-only lists in on-chain order.
    let accountKeysFromLookups: AccountKeysFromLookups?
    
    /// Creates a new `MessageAccountKeys` view.
    ///
    /// - Parameters:
    ///   - staticAccountKeys: The static keys embedded in the message.
    ///   - accountKeysFromLookups: Optional v0 loaded keys (writable + read-only).
    public init(staticAccountKeys: [PublicKey], accountKeysFromLookups: AccountKeysFromLookups? = nil) {
      self.staticAccountKeys = staticAccountKeys
      self.accountKeysFromLookups = accountKeysFromLookups
    }
    
    /// The message key set split into ordered segments:
    /// 1) static account keys,
    /// 2) (optional) writable lookup keys,
    /// 3) (optional) read-only lookup keys.
    ///
    /// Empty lookup segments are omitted, which preserves correct global indexing.
    public var keySegments: [[PublicKey]] {
      var segments: [[PublicKey]] = [staticAccountKeys]
      guard let accountKeysFromLookups else { return segments }
      if !accountKeysFromLookups.writable.isEmpty || !accountKeysFromLookups.readonly.isEmpty {
        segments.append(accountKeysFromLookups.writable)
        segments.append(accountKeysFromLookups.readonly)
      }
      return segments
    }
    

    /// Total number of addressable keys across all segments.
    public var count: Int {
      self.keySegments.flatMap({ $0 }).count
    }
    
    /// Returns the `PublicKey` at a global `index` across all segments, or `nil` if out of range.
    ///
    /// - Parameter index: Global key index as used by compiled instructions (`u8`-sized).
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
    
    /// Compiles high-level `TransactionInstruction`s into `MessageCompiledInstruction`s
    /// by translating each referenced `PublicKey` into its global index within the message’s
    /// key set (static + optional lookup keys).
    ///
    /// - Throws:
    ///   - `accountIndexOverflow` if total keys exceed the `u8` index space (0…255).
    ///   - `unknownInstructionAccountKey` if an instruction references a key not in the set.
    public func compileInstructions(_ instructions: [TransactionInstruction]) throws -> [MessageCompiledInstruction] {
      // The u8 index space is 0…255 → total addressable keys **≤ 256** (exactly 256 is OK).
      guard count <= 256 else {
        throw Error.accountIndexOverflow
      }
      
      // Flatten segments to a single array for index mapping.
      let segments = self.keySegments.flatMap({ $0 })
      
      // Build a dictionary mapping each PublicKey to its global index.
      var keyIndexMap: [PublicKey: Int] = [:]
      keyIndexMap.reserveCapacity(segments.count)
      segments.enumerated()
        .forEach { element in
          keyIndexMap[element.element] = element.offset
        }
      
      // Helper to find a u8 index for a given key.
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
