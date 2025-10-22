//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  /// A client-side representation of a Solana transaction.
  ///
  /// This type holds instructions, fee payer, and recent blockhash (or durable nonce),
  /// and can compile itself into a canonical `Message` ready to be signed.
  /// It also provides helpers to add instructions and to populate itself back
  /// from a decoded wire `Message` + signature list.
  public struct Transaction: Equatable, Sendable {
    // MARK: Errors
    public enum Error: Swift.Error, Equatable {
      /// No instructions supplied where at least one instruction is required.
      case noInstructions
      /// Transaction requires a recent blockhash/nonce but it is missing.
      case recentBlockhashRequired
      /// Transaction requires a fee payer but it is missing.
      case feePayerRequired
      /// An instruction references a programId that could not be resolved.
      case undefinedProgramId(index: Int)
      /// A signature was provided for an account that does not appear in the key set.
      case unknownSigner(PublicKey)
      /// No signers were provided where at least one signer is required.
      case noSigners
    }
    
    // MARK: Mutable state (invalidation of compiled message)
    
    /// The signature list aligned with the first `header.numRequiredSignatures`
    /// message account keys during encoding. Setting this invalidates the cached `_message`.
    public var signatures: [SignaturePubkeyPair] {
      didSet { self._message = nil }
    }
    
    /// Optional explicit fee payer. If unset, the first signature’s public key is used.
    /// Setting this invalidates the cached `_message`.
    public var feePayer: PublicKey? {
      didSet { self._message = nil }
    }
    
    /// The instructions to execute atomically. Setting this invalidates the cached `_message`.
    public var instructions: [TransactionInstruction] {
      didSet { self._message = nil }
    }
    
    /// A recent blockhash (base58 string) or a durable nonce value (if `nonceInfo` is set).
    /// Setting this invalidates the cached `_message`.
    public var recentBlockhash: String? {
      didSet { self._message = nil }
    }
    
    // MARK: Optional execution constraints
    
    /// The last block height at/after which the transaction is considered expired.
    /// Not serialized in the message; used for lifecycle/confirmation logic.
    let lastValidBlockHeight: UInt64?
    
    /// Durable nonce information. If present, the transaction will use `nonceInfo.nonce`
    /// as its blockhash and will (if needed) prepend the `AdvanceNonceAccount` instruction.
    let nonceInfo: NonceInformation?
    
    /// For durable nonce flows, the minimum slot context used to validate that
    /// the nonce has not advanced erroneously during confirmation.
    let minNonceContextSlot: UInt64?
    
    /// Cached compiled message (invalidated when inputs change). Package-internal.
    package var _message: Message?
    
    // MARK: Init
    
    /// Creates a new transaction container.
    ///
    /// - Parameters:
    ///   - signatures: Optional signature/public-key pairs (usually set after signing).
    ///   - feePayer: Optional explicit fee payer. If nil, first signature’s public key is used.
    ///   - instructions: Instruction list to execute atomically.
    ///   - blockhash: Recent blockhash in base58; ignored if `nonceInfo` is present.
    ///   - lastValidBlockHeight: Optional expiry constraint by block height.
    ///   - nonceInfo: Optional durable nonce information.
    ///   - minNonceContextSlot: Optional slot context guard for nonce confirmations.
    public init(
      signatures: [SignaturePubkeyPair] = [],
      feePayer: PublicKey? = nil,
      instructions: [TransactionInstruction] = [],
      blockhash: String? = nil,
      lastValidBlockHeight: UInt64? = nil,
      nonceInfo: NonceInformation? = nil,
      minNonceContextSlot: UInt64? = nil) {
        self.signatures = signatures
        self.feePayer = feePayer
        self.instructions = instructions
        self.recentBlockhash = blockhash
        self.lastValidBlockHeight = lastValidBlockHeight
        self.nonceInfo = nonceInfo
        self.minNonceContextSlot = minNonceContextSlot
        self._message = nil
      }
    
    // MARK: - Add (mutating)
    
    /// Appends one or more instructions to this transaction.
    /// - Parameter instructions: Instructions to append (must be non-empty).
    mutating public func add(instructions: [TransactionInstruction]) throws {
      guard !instructions.isEmpty else {
        throw Error.noInstructions
      }
      self.instructions.append(contentsOf: instructions)
      self._message = nil
    }
    
    /// Variadic convenience for `add(instructions:)`.
    mutating public func add(instructions: TransactionInstruction...) throws {
      try self.add(instructions: instructions)
    }
    
    /// Appends all instructions from another transaction.
    mutating public func add(transaction: Self) throws {
      try self.add(instructions: transaction.instructions)
    }
    
    // MARK: - Add (non-mutating, returns a copy)
    
    /// Returns a copy with additional instructions appended.
    public func adding(instructions: [TransactionInstruction]) throws -> Self {
      guard !instructions.isEmpty else {
        throw Error.noInstructions
      }
      var newInstructions = self.instructions
      newInstructions.append(contentsOf: instructions)
      
      return Self.init(
        signatures: signatures,
        feePayer: feePayer,
        instructions: newInstructions,
        blockhash: recentBlockhash,
        lastValidBlockHeight: lastValidBlockHeight,
        nonceInfo: nonceInfo,
        minNonceContextSlot: minNonceContextSlot
      )
    }
    
    /// Variadic convenience for `adding(instructions:)`.
    public func adding(instructions: TransactionInstruction...) throws -> Self {
      return try self.adding(instructions: instructions)
    }
    
    /// Returns a copy with all instructions from another transaction appended.
    public func adding(transaction: Transaction) throws -> Self {
      return try self.adding(instructions: transaction.instructions)
    }
    
    // MARK: - Signer helpers (package)
    
    /// Replaces the signature list with unique public keys (signatures set to `nil`),
    /// preserving first-seen order. At least one signer is required.
    mutating package func setSigners(signers: [PublicKey]) throws {
      guard !signers.isEmpty else {
        throw Error.noSigners
      }
      var seen: Set<PublicKey> = .init()
      self.signatures = signers
        .compactMap({
          guard !seen.contains($0) else { return nil }
          seen.insert($0)
          return .init(signature: nil, publicKey: $0)
        })
    }
    
    /// Variadic convenience for `setSigners(signers:)`.
    mutating package func setSigners(signers: PublicKey...) throws {
      try self.setSigners(signers: signers)
    }
    
    // MARK: - Compile
    
    /// Compiles the current transaction fields into a canonical `Message`.
    ///
    /// - Returns: A `Message` with header, ordered account keys, recent blockhash,
    ///            and compiled (indexed) instructions.
    /// - Throws: `recentBlockhashRequired`, `feePayerRequired`, `unknownSigner`.
    public func compileMessage() throws(Error) -> Message {
      // Use cached message if still valid.
      if let cached = _message { return cached }
      
      // Resolve blockhash (durable nonce has priority).
      let recentBlockhash: String?
      let instructions: [TransactionInstruction]
      
      if let nonceInfo {
        recentBlockhash = nonceInfo.nonce
        if self.instructions.first != nonceInfo.nonceInstruction {
          instructions = [nonceInfo.nonceInstruction] + self.instructions
        } else {
          instructions = self.instructions
        }
      } else {
        recentBlockhash = self.recentBlockhash
        instructions = self.instructions
      }
      
      guard !(recentBlockhash?.isEmpty ?? true) else {
        throw Error.recentBlockhashRequired
      }
      
      // Resolve fee payer (explicit > implicit from first signature pk).
      let feePayer: PublicKey
      if self.feePayer != nil {
        feePayer = self.feePayer!
      } else if let payer = self.signatures.first?.publicKey {
        feePayer = payer
      } else {
        throw Error.feePayerRequired
      }
      
      // Collect metas for all keys referenced by instructions + program IDs.
      var programIds: [PublicKey] = []
      var metas: [AccountMeta] = []
      for instruction in instructions {
        metas.append(contentsOf: instruction.keys)
        let pid = instruction.programId
        if !programIds.contains(pid) { programIds.append(pid) }
      }
      
      // Add program IDs as readonly, non-signers (as Solana requires)
      metas.append(contentsOf: programIds.map({ pid in
          .init(pubkey: pid, isSigner: false, isWritable: false)
      }))
      
      // Merge duplicates (OR flags).
      var uniqueMetas = [AccountMeta]()
      uniqueMetas.reserveCapacity(metas.count)
      
      uniqueMetas = metas.reduce(into: uniqueMetas) { partialResult, meta in
        if let idx = partialResult.firstIndex(where: { $0.pubkey == meta.pubkey }) {
          partialResult[idx] = .init(
            pubkey: partialResult[idx].pubkey,
            isSigner: partialResult[idx].isSigner || meta.isSigner,
            isWritable: partialResult[idx].isWritable || meta.isWritable
          )
        } else {
          partialResult.append(meta)
        }
      }
      
      // Sort by (isSigner desc, isWritable desc, base58(pubkey) asc).
      // Base58 strings are ASCII; simple lexicographic compare is stable.
      let locale = Locale(identifier: "en")
      // Sort: signers first, then writables, then by pubkey (base58 lexicographic)
      uniqueMetas.sort { lhs, rhs in
        if lhs.isSigner != rhs.isSigner { return lhs.isSigner && !rhs.isSigner }
        if lhs.isWritable != rhs.isWritable { return lhs.isWritable && !rhs.isWritable }
        // Lexicographic by base58
        
        let lhsA = lhs.pubkey.address()?.address ?? ""
        let rhsA = rhs.pubkey.address()?.address ?? ""
        
        let primary = lhsA.compare(rhsA, options: [], range: nil, locale: locale)
        if primary != .orderedSame {
          return primary == .orderedAscending
        }
        
        // Tie-breaker to emulate caseFirst: 'lower'
        // If strings are equal under primary compare but differ by case,
        // prefer the one that is all-lowercase at the first differing scalar.
        // (Simple heuristic: whole-string check, good for Base58.)
        let lhsAIsLower = lhsA == lhsA.lowercased(with: locale)
        let rhsAIsLower = rhsA == rhsA.lowercased(with: locale)
        if lhsAIsLower != rhsAIsLower { return lhsAIsLower } // lower comes first
        
        // Final fallback: Unicode scalar order (stable and deterministic)
        return lhsA < rhsA
      }
      
      // Ensure fee payer is first and marked as (signer, writable).
      if let idx = uniqueMetas.firstIndex(where: { $0.pubkey == feePayer }) {
        var payerMeta = uniqueMetas.remove(at: idx)
        payerMeta.isSigner = true
        payerMeta.isWritable = true
        uniqueMetas.insert(payerMeta, at: 0)
      } else {
        uniqueMetas.insert(.init(pubkey: feePayer, isSigner: true, isWritable: true), at: 0)
      }
      
      // All provided signers must be present among metas.
      for sig in signatures {
        guard let idx = uniqueMetas.firstIndex(where: { $0.pubkey == sig.publicKey }) else {
          throw Error.unknownSigner(sig.publicKey)
        }
        if !uniqueMetas[idx].isSigner {
          uniqueMetas[idx] = .init(pubkey: uniqueMetas[idx].pubkey, isSigner: true, isWritable: uniqueMetas[idx].isWritable)
        }
      }
      
      // Build header and final account key order.
      var numRequiredSignatures: UInt8 = 0
      var numReadonlySignedAccounts: UInt8 = 0
      var numReadonlyUnsignedAccounts: UInt8 = 0
      var signedKeys = [PublicKey]()
      var unsignedKeys = [PublicKey]()
      signedKeys.reserveCapacity(uniqueMetas.count)
      unsignedKeys.reserveCapacity(uniqueMetas.count)
      
      for meta in uniqueMetas {
        if meta.isSigner {
          signedKeys.append(meta.pubkey)
          numRequiredSignatures &+= 1
          if !meta.isWritable { numReadonlySignedAccounts &+= 1 }
        } else {
          unsignedKeys.append(meta.pubkey)
          if !meta.isWritable { numReadonlyUnsignedAccounts &+= 1 }
        }
      }
      
      let accountKeys = signedKeys + unsignedKeys
      
      // Compile instructions (program + account indices into `accountKeys`).
      let compiled: [CompiledInstruction] = instructions.map { instruction in
        let programIndex = accountKeys.firstIndex(of: instruction.programId)!
        
        let accountIndices: [UInt8] = instruction.keys.compactMap { meta in
          guard let idx = accountKeys.firstIndex(of: meta.pubkey) else { return nil }
          return UInt8(idx)
        }
        // All indices must exist
        precondition(accountIndices.count == instruction.keys.count, "Account metas missing from key set")
        
        return CompiledInstruction(
          programIdIndex: UInt8(programIndex),
          accounts: accountIndices,
          data: instruction.data ?? Data()
        )
      }
      
      let header = MessageHeader(
        numRequiredSignatures: numRequiredSignatures,
        numReadonlySignedAccounts: numReadonlySignedAccounts,
        numReadonlyUnsignedAccounts: numReadonlyUnsignedAccounts
      )
      
      return Message(
        header: header,
        accountKeys: accountKeys,
        recentBlockhash: recentBlockhash!,
        instructions: compiled
      )
    }
    
    // MARK: - Populate from decoded wire parts
    
    /// Populates this transaction from already-decoded wire parts.
    ///
    /// - Parameters:
    ///   - rawSigs: Signatures in message order. A 64-byte zero array means "no signature".
    ///   - message: The decoded canonical message (accounts, header, compiled instructions).
    public mutating func populate(signatures rawSigs: [Data], message: Solana.Message) {
      let feePayer: PublicKey? = message.header.numRequiredSignatures > 0 ? message.accountKeys.first : nil
      
      // Default signature (64 zero bytes) = "no signature"
      let defaultSignature = Data(repeating: 0, count: 64)
      
      // Pair the first N signatures with the first N account keys.
      let signatures = rawSigs.enumerated().map { (idx, sig) in
        Solana.SignaturePubkeyPair(
          signature: (sig == defaultSignature) ? nil : sig,
          publicKey: message.accountKeys[idx]
        )
      }
      
      // Expand compiled instructions using header-derived signer/writable flags.
      let instructions = message.instructions.map { ix in
        let keys: [Solana.AccountMeta] = ix.accounts.map { accountIndex in
          let index = Int(accountIndex)
          let pk = message.accountKeys[index]
          let isSigner = signatures.contains(where: { $0.publicKey == pk }) || message.isAccountSigner(index: index)
          let isWritable = message.isAccountWritable(index: index)
          
          return Solana.AccountMeta(pubkey: pk, isSigner: isSigner, isWritable: isWritable)
        }
        
        let programId = message.accountKeys[Int(ix.programIdIndex)]
        
        // Assuming `ix.data` is already `Data` (adjust if your `Message` uses base58 `String`)
        return Solana.TransactionInstruction(keys: keys, programId: programId, data: ix.data)
      }
      
      self.signatures = signatures
      self.feePayer = feePayer
      self.instructions = instructions
      self.recentBlockhash = message.recentBlockhash
      self._message = message
    }
  }
}

// MARK: - Codable

extension Solana.Transaction: Codable {
  /// Decodes a transaction from the canonical wire tuple `[signatures, message]`.
  /// The `signatures` portion is an array of 64-byte blobs (zeroed means "missing").
  public init(from decoder: any Decoder) throws {
    var container = try decoder.unkeyedContainer()
    
    let rawSignatures = try container.decode([Data].self)
    let message = try container.decode(Solana.Message.self)
    
    self.init()
    self.populate(signatures: rawSignatures, message: message)
  }
  
  /// Encodes a transaction as the canonical wire tuple `[signatures, message]`.
  /// Signatures are encoded as 64-byte blobs (or zeroed if missing).
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.unkeyedContainer()
    
    try container.encode(self.signatures)
    let message = try self.compileMessage()
    try container.encode(message)
  }
}
