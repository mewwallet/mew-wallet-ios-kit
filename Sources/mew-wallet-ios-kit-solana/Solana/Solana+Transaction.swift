//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  public struct Transaction: Equatable, Sendable {
    public enum Error: Swift.Error, Equatable {
      case noInstructions
      case invalidNetwork
      case recentBlockhashRequired
      case feePayerRequired
      case undefinedProgramId(index: Int)
      case unknownSigner(Address?)
      case noSigners
    }
    
    /// Signatures for the transaction.  Typically created by invoking the `sign()` method
    public var signatures: [SignaturePubkeyPair]
    
    /// The transaction fee payer
    public var feePayer: PublicKey? {
      didSet {
        self._message = nil
      }
    }
    
    /// The instructions to atomically execute
    var instructions: [TransactionInstruction]
    
    /// A recent transaction id. Must be populated by the caller
    public var recentBlockhash: String?
    
    /// the last block chain can advance to before tx is declared expired
    let lastValidBlockHeight: UInt64?
    
    /// Optional Nonce information. If populated, transaction will use a durable
    /// Nonce hash instead of a recentBlockhash. Must be populated by the caller
    let nonceInfo: NonceInformation?
    
    /// If this is a nonce transaction this represents the minimum slot from which
    /// to evaluate if the nonce has advanced when attempting to confirm the
    /// transaction. This protects against a case where the transaction confirmation
    /// logic loads the nonce account from an old slot and assumes the mismatch in
    /// nonce value implies that the nonce has been advanced.
    let minNonceContextSlot: UInt64?
    
    package var _message: Message?
    
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
    
    // MARK: - Add
    
    /// Add one or more instructions to this Transaction
    /// - Parameter instructions: Instructions to be added
    mutating func add(instructions: [TransactionInstruction]) throws {
      guard !instructions.isEmpty else {
        throw Error.noInstructions
      }
      self.instructions.append(contentsOf: instructions)
      self._message = nil
    }
    
    /// Add one or more instructions to this Transaction
    /// - Parameter instructions: Instructions to be added
    mutating func add(instructions: TransactionInstruction...) throws {
      try self.add(instructions: instructions)
    }
    
    mutating func add(transaction: Self) throws {
      try self.add(instructions: transaction.instructions)
    }
    
    /// Add one or more instructions to this Transaction
    /// - Parameter instructions: Instructions to be added
    /// - Returns: `Transaction` with all instructions
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
    
    /// Add one or more instructions to this Transaction
    /// - Parameter instructions: Instructions to be added
    /// - Returns: `Transaction` with all instructions
    public func adding(instructions: TransactionInstruction...) throws -> Self {
      return try self.adding(instructions: instructions)
    }
    
    /// Add one or more instructions to this Transaction
    /// - Parameter instructions: Instructions to be added
    /// - Returns: `Transaction` with all instructions
    public func adding(transaction: Transaction) throws -> Self {
      return try self.adding(instructions: transaction.instructions)
    }
    
    // MARK: - Set
    
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
    
    mutating package func setSigners(signers: PublicKey...) throws {
      try self.setSigners(signers: signers)
    }
    
    // MARK: - Compile
    
    /// Compile transaction data into a `Message`
    public func compileMessage() throws(Error) -> Message {
      // Reuse cached message if structure hasn't changed
      if let cached = _message { return cached }
      
      // Resolve blockhash & instruction list (nonce or recentBlockhash)
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
      
      // Resolve fee payer
      let feePayer: PublicKey
      if self.feePayer != nil {
        feePayer = self.feePayer!
      } else if let payer = self.signatures.first?.publicKey {
        feePayer = payer
      } else {
        throw Error.feePayerRequired
      }
      
      // Validate programIds presence
      for (index, instruction) in instructions.enumerated() {
        guard instruction.programId != nil else {
          throw Error.undefinedProgramId(index: index)
        }
      }
      
      // Collect metas & programIds
      var programIds: [PublicKey] = []
      var metas: [AccountMeta] = []
      for instruction in instructions {
        metas.append(contentsOf: instruction.keys)
        let pid = instruction.programId! // Safe, programId was validated
        if !programIds.contains(pid) { programIds.append(pid) }
      }
      
      // Append programId metas (readonly, nonsigner)
      metas.append(contentsOf: programIds.map({ pid in
          .init(pubkey: pid, isSigner: false, isWritable: false)
      }))
      
      // Deduplicate metas, merging flags
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
      
      // Ensure fee payer is first and marked signer+writable
      if let idx = uniqueMetas.firstIndex(where: { $0.pubkey == feePayer }) {
        var payerMeta = uniqueMetas.remove(at: idx)
        payerMeta.isSigner = true
        payerMeta.isWritable = true
        uniqueMetas.insert(payerMeta, at: 0)
      } else {
        uniqueMetas.insert(.init(pubkey: feePayer, isSigner: true, isWritable: true), at: 0)
      }
      
      // Disallow unknown signers
      for sig in signatures {
        guard let idx = uniqueMetas.firstIndex(where: { $0.pubkey == sig.publicKey }) else {
          throw Error.unknownSigner(sig.publicKey.address())
        }
        if !uniqueMetas[idx].isSigner {
          uniqueMetas[idx] = .init(pubkey: uniqueMetas[idx].pubkey, isSigner: true, isWritable: uniqueMetas[idx].isWritable)
        }
      }
      
      // Header counts & account key ordering
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
      
      // Compile instructions with indexed accounts
      let compiled: [CompiledInstruction] = instructions.map { instruction in
        let programIndex = accountKeys.firstIndex(of: instruction.programId!)!
        
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
  }
}

extension Solana.Transaction: Encodable {
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.unkeyedContainer()
    
    let message = try self.compileMessage()
    
    try container.encode(self.signatures.count)
    try self.signatures.forEach {
      if let signature = $0.signature {
        try container.encode(signature)
      } else {
        try container.encode(Data(repeating: 0x00, count: 64))
      }
    }
    try container.encode(message)
  }
}
