//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  /// A high-level, program-agnostic representation of a Solana transaction message.
  ///
  /// `TransactionMessage` is a convenience wrapper that:
  /// - reconstructs `TransactionInstruction`s from an already-compiled `Message`/`MessageV0` by
  ///   resolving account indices into `AccountMeta`s (including signer/writable flags inferred from
  ///   the header and account ordering),
  /// - exposes the `payerKey` and `recentBlockhash` alongside the instruction list,
  /// - and can recompile itself into a versioned message (currently `MessageV0`) using optional
  ///   Address Lookup Tables (ALTs).
  ///
  /// This type is useful when you need to:
  /// - deserialize a `Message`/`MessageV0` and regain instruction-level semantics,
  /// - inspect or transform instructions without working directly with index-based forms, and
  /// - recompile a v0 message using the static+lookup accounts resolution flow.
  public struct TransactionMessage: Sendable, Equatable {
    public enum Error: Swift.Error, Equatable {
      /// The header fields imply no writable signer, which is invalid (payer must be writable signer).
      case invalidMessageHeader
      /// The message contained no account keys.
      case noAccountKeys
      /// An instruction referenced an account index that could not be resolved.
      case noKeyForAccount(Int)
      /// The program ID index could not be resolved for an instruction.
      case noProgramId(Int)
    }
    
    /// The fee-payer account key.
    ///
    /// By protocol, the payer is the **first** account key and must be a **writable signer**.
    public let payerKey: PublicKey
    
    /// Fully materialized, program-agnostic instructions for this message.
    ///
    /// Each instruction contains ordered `AccountMeta`s with `isSigner` and `isWritable` flags
    /// inferred from the header and account ordering rules, plus the decoded `programId` and
    /// the program `data` payload.
    public let instructions: [TransactionInstruction]
    
    /// The recent blockhash (or durable nonce value if this message is derived from a nonce flow).
    public let recentBlockhash: String
    
    /// Creates a message wrapper from raw parts.
    ///
    /// - Parameters:
    ///   - payerKey: The fee-payer public key (must be the first writable signer if compiled).
    ///   - instructions: Fully materialized transaction instructions.
    ///   - recentBlockhash: Recent blockhash/nonce used for transaction freshness.
    public init(payerKey: PublicKey,
                instructions: [TransactionInstruction],
                recentBlockhash: String) {
      self.payerKey = payerKey
      self.instructions = instructions
      self.recentBlockhash = recentBlockhash
    }
    
    /// Initializes from a legacy `Message`. Optionally provide ALTs or pre-resolved lookup keys.
    public init(message: Solana.Message, accountKeysFromLookups: AccountKeysFromLookups? = nil, addressLookupTableAccounts: [AddressLookupTableAccount]? = nil) throws {
      try self.init(message: .legacy(message), accountKeysFromLookups: accountKeysFromLookups, addressLookupTableAccounts: addressLookupTableAccounts)
    }
    
    /// Initializes from a `MessageV0`. Optionally provide ALTs or pre-resolved lookup keys.
    public init(message: Solana.MessageV0, accountKeysFromLookups: AccountKeysFromLookups? = nil, addressLookupTableAccounts: [AddressLookupTableAccount]? = nil) throws {
      try self.init(message: .v0(message), accountKeysFromLookups: accountKeysFromLookups, addressLookupTableAccounts: addressLookupTableAccounts)
    }
    
    /// Initializes from a `VersionedMessage` by reconstructing instruction metas and flags.
    ///
    /// The initializer:
    /// 1. Validates the header (`numRequiredSignatures`, `numReadonlySignedAccounts`,
    ///    `numReadonlyUnsignedAccounts`) to ensure at least one writable signer exists.
    /// 2. Resolves account keys (static + from lookups if provided or resolvable via ALTs).
    /// 3. Converts each compiled instruction (program index + account indices + bytes) into a
    ///    `TransactionInstruction` with concrete `AccountMeta`s and the correct signer/writable flags
    ///    based on the message header rules:
    ///       - Signed segment (indices `0..<numRequiredSignatures`):
    ///           * first `numRequiredSignatures - numReadonlySignedAccounts` are writable signers,
    ///             the rest are readonly signers.
    ///       - Unsigned *static* segment (next `staticCount - numRequiredSignatures`):
    ///           * first `numUnsigned - numReadonlyUnsignedAccounts` are writable,
    ///             the rest are readonly.
    ///       - Unsigned *lookup* segment (remaining `lookupCount`):
    ///           * first `sum(writableIndexes)` are writable, rest are readonly.
    ///
    /// - Parameters:
    ///   - message: A versioned message (`legacy` or `v0`).
    ///   - accountKeysFromLookups: Optional pre-resolved lookup keys (writable/readonly segments).
    ///   - addressLookupTableAccounts: Optional ALT accounts to resolve `MessageV0` lookups.
    public init(message: VersionedMessage, accountKeysFromLookups: AccountKeysFromLookups? = nil, addressLookupTableAccounts: [AddressLookupTableAccount]? = nil) throws {
      let header = message.header
      let compiledInstructions = message.compiledInstructions
      let recentBlockhash = message.recentBlockhash
      
      let numRequiredSignatures = Int(header.numRequiredSignatures)
      let numReadonlySignedAccounts = Int(header.numReadonlySignedAccounts)
      let numReadonlyUnsignedAccounts = Int(header.numReadonlyUnsignedAccounts)
      
      // Writable signers must be > 0 (payer must be a writable signer).
      let numWritableSignedAccounts = numRequiredSignatures - numReadonlySignedAccounts
      guard numWritableSignedAccounts > 0 else {
        throw Error.invalidMessageHeader
      }
      
      // Validate unsigned static segment math.
      let numWritableUnsignedAccounts = message.staticAccountKeys.count - numRequiredSignatures - numReadonlyUnsignedAccounts
      guard numWritableUnsignedAccounts >= 0 else {
        throw Error.invalidMessageHeader
      }
      
      // Resolve account keys (static + lookups).
      let accountKeys = try message.getAccountKeys(accountKeysFromLookups: accountKeysFromLookups, addressLookupTableAccounts: addressLookupTableAccounts)
      
      // Payer must be first account.
      guard let payerKey = accountKeys.get(keyAtIndex: 0) else {
        throw Error.noAccountKeys
      }
      
      // Expand compiled instructions into fully described metas.
      let instructions: [TransactionInstruction] = try compiledInstructions.map { compiledIx in
        // Resolve account metas per index, then derive flags from header/segments
        let keys: [Solana.AccountMeta] = try compiledIx.accountKeyIndexes
          .map { Int($0) }
          .map { keyIndex in
            guard let pubkey = accountKeys.get(keyAtIndex: keyIndex) else {
              throw Error.noKeyForAccount(Int(keyIndex))
            }
            
            // Signer set = first numRequiredSignatures indices
            let isSigner = keyIndex < numRequiredSignatures
            
            // Writable derivation per segment
            let isWritable: Bool
            if isSigner {
              isWritable = keyIndex < numWritableSignedAccounts
            } else if keyIndex < accountKeys.staticAccountKeys.count {
              // unsigned static segment
              isWritable = (keyIndex - numRequiredSignatures) < numWritableUnsignedAccounts
            } else {
              // lookup segment: first N are writable, where N = total writable lookups
              let lookupWritableCount = accountKeys.accountKeysFromLookups?.writable.count ?? 0
              isWritable = (keyIndex - accountKeys.staticAccountKeys.count) < lookupWritableCount
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
    
    /// Compiles this wrapper back into a `VersionedMessage` (v0).
    ///
    /// - Parameter addressLookupTableAccounts: Optional ALTs to extract and reference
    ///   additional accounts in the v0 message to minimize static keys.
    /// - Returns: A `.v0` `VersionedMessage` assembled from the provided parts.
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
