//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  /// An atomically processed **legacy** (v0-disabled) Solana message.
  ///
  /// This structure mirrors the canonical `Message` layout used by legacy transactions:
  /// a compact header, a static list of account keys, a recent blockhash, and a list
  /// of compiled instructions that reference accounts by index.
  ///
  /// > Note:
  /// > - This type intentionally models **legacy** messages only. Versioned messages
  /// >   (with the `0x80` version prefix) must be handled by a separate `VersionedMessage`.
  /// > - See the decoding guard that rejects versioned payloads below.
  public struct Message: Equatable, Sendable {
    /// Compact header containing signer/read-only counts.
    public let header: MessageHeader
    
    /// Static account keys referenced by `instructions` via indices.
    /// The ordering must be:
    /// 1) writable signers,
    /// 2) read-only signers,
    /// 3) writable non-signers,
    /// 4) read-only non-signers.
    public let accountKeys: [PublicKey]
    
    /// Convenience alias for the static account keys (legacy messages have no dynamic lookups).
    public var staticAccountKeys: [PublicKey] { accountKeys }
    
    /// The recent blockhash (base58 string) that ties this message to a recent slot.
    public var recentBlockhash: String
    
    /// Compiled instructions that reference `accountKeys` by index and contain raw data payloads.
    public let instructions: [CompiledInstruction]
    
    /// A convenience projection into an alternative `MessageCompiledInstruction` model.
    /// (Keeps instruction fields but uses `accountKeyIndexes` naming to align with some SDKs.)
    var compiledInstructions: [MessageCompiledInstruction] {
      self.instructions.map {
        .init(
          programIdIndex: $0.programIdIndex,
          accountKeyIndexes: $0.accounts,
          data: $0.data
        )
      }
    }
    
    /// Explicitly marks this as a legacy message (no version prefix).
    public let version: Solana.Version = .legacy
    
    /// Legacy messages do not carry address lookup table references.
    public var addressTableLookups: [MessageAddressTableLookup] { [] }
    
    /// Designated initializer for a fully compiled legacy message.
    ///
    /// - Parameters:
    ///   - header: Message header counts.
    ///   - accountKeys: Static account keys (see ordering convention above).
    ///   - recentBlockhash: Base58-encoded recent blockhash (32 bytes when decoded).
    ///   - instructions: Compiled instructions that reference `accountKeys` by index.
    public init(header: MessageHeader, accountKeys: [PublicKey], recentBlockhash: String, instructions: [CompiledInstruction]) {
      self.header = header
      self.accountKeys = accountKeys
      self.recentBlockhash = recentBlockhash
      self.instructions = instructions
    }
    
    /// Convenience initializer that compiles `TransactionInstruction`s into a legacy `Message`.
    ///
    /// - Parameters:
    ///   - payerKey: Fee payer public key. Must be the **first writable signer**.
    ///   - recentBlockhash: Base58-encoded recent blockhash.
    ///   - instructions: High-level instructions with explicit `AccountMeta`s and `programId`s.
    ///
    /// - Throws: Propagates errors from key compilation and instruction compilation
    ///           (e.g., invalid keys, malformed ordering, or counts).
    public init(payerKey: PublicKey, recentBlockhash: String, instructions: [TransactionInstruction]) throws {
      let compiledKeys = try CompiledKeys(instructions: instructions, payer: payerKey)
      let (header, staticAccountKeys) = try compiledKeys.getMessageComponents()
      let accountKeys = MessageAccountKeys(staticAccountKeys: staticAccountKeys)
      let instructions = try accountKeys.compileInstructions(instructions).map { instruction in
        CompiledInstruction(
          programIdIndex: instruction.programIdIndex,
          accounts: instruction.accountKeyIndexes,
          data: instruction.data
        )
      }
      self.init(
        header: header,
        accountKeys: staticAccountKeys,
        recentBlockhash: recentBlockhash,
        instructions: instructions
      )
    }
    
    /// Returns `true` if the account at `index` is one of the `numRequiredSignatures`.
    /// (i.e., it is in the signer prefix of `accountKeys`.)
    func isAccountSigner(index: Int) -> Bool {
      return index < self.header.numRequiredSignatures
    }
    
    /// Returns `true` if the account at `index` is writable in this message.
    ///
    /// Writability is derived from header counts assuming canonical ordering:
    /// - Signers: first `numRequiredSignatures`, with the last
    ///   `numReadonlySignedAccounts` being read-only.
    /// - Non-signers: the remainder, with the last
    ///   `numReadonlyUnsignedAccounts` being read-only.
    func isAccountWritable(index: Int) -> Bool {
      let numSignedAccounts = Int(self.header.numRequiredSignatures)
      if (index >= self.header.numRequiredSignatures) {
        let unsignedAccountIndex = index - numSignedAccounts
        let numUnsignedAccounts = self.accountKeys.count - numSignedAccounts
        let numWritableUnsignedAccounts = numUnsignedAccounts - Int(self.header.numReadonlyUnsignedAccounts)
        return unsignedAccountIndex < numWritableUnsignedAccounts
      } else {
        let numWritableSignedAccounts = numSignedAccounts - Int(self.header.numReadonlySignedAccounts)
        return index < numWritableSignedAccounts
      }
    }
    
    /// Builds a `MessageAccountKeys` view over the static keys (legacy messages only).
    func getAccountKeys() -> MessageAccountKeys {
      return MessageAccountKeys(staticAccountKeys: self.staticAccountKeys)
    }
  }
}

extension Solana.Message: Codable {
  /// Decodes a **legacy** message from the shortvec-based binary format.
  ///
  /// Layout (conceptual):
  /// ```
  /// header
  /// accountKeys: shortvec<len> * 32-bytes
  /// recentBlockhash: 32 bytes
  /// instructions: shortvec<len> * compiled-instruction
  /// ```
  public init(from decoder: any Decoder) throws {
    var container = try decoder.unkeyedContainer()
    
    // Header (first byte must NOT contain version prefix)
    self.header = try container.decode(Solana.MessageHeader.self)
    
    // Reject versioned (v0+) messages: if the top bit is set in the first byte,
    // then `numRequiredSignatures` would differ from its 0x7F-masked value.
    if self.header.numRequiredSignatures != self.header.numRequiredSignatures & .VERSION_PREFIX_MASK {
      let context = DecodingError.Context(
        codingPath: decoder.codingPath,
        debugDescription: "Versioned messages must be deserialized to VersionedMessage.",
        underlyingError: nil
      )
      throw DecodingError.typeMismatch(Solana.Message.self, context)
    }
    
    // Static account keys
    self.accountKeys = try container.decode([PublicKey].self)
    
    // Recent blockhash (raw 32 bytes) → base58 string
    let recentBlockhash = try container.decode(Data.self)
    self.recentBlockhash = try recentBlockhash.encodeBase58(.solana)
    
    // Compiled instructions
    self.instructions = try container.decode([Solana.CompiledInstruction].self)
  }
  
  
  /// Encodes the legacy message into the shortvec-based binary format.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.unkeyedContainer()
    
    // Header
    try container.encode(header)
    
    // Static account keys
    try container.encode(accountKeys)
    
    // Recent blockhash: base58 string → raw 32 bytes
    let blockhash = try recentBlockhash.decodeBase58(.solana)
    try container.encode(blockhash)
    
    // Compiled instructions
    try container.encode(instructions)
  }
}
