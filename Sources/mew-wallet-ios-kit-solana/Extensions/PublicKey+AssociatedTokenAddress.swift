//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 10/10/25.
//

import Foundation
import mew_wallet_ios_kit
import mew_wallet_ios_tweetnacl

extension PublicKey {
  // MARK: - Errors
  
  /// Errors thrown while deriving associated token accounts or PDAs.
  public enum AssociatedTokenError: Swift.Error {
    case ownerOffCurve                // Owner must be on-curve when `allowOwnerOffCurve == false`
    case noAddress                    // Unable to find a valid PDA for any bump (255…0)
    case maxSeedLengthExceeded        // A single seed exceeded 32 bytes
    case internalError                // Internal/format error constructing the public key
    case invalidSeed                  // Derived point is on-curve (invalid for PDA)
    case underlying(any Swift.Error)  // Wrapped dependency error
  }
  
  // MARK: - Associated Token Address (ATA)
  
  /// Computes the **Associated Token Account** (ATA) for this owner and the given mint.
  ///
  /// Derivation follows the SPL Associated Token Account program:
  /// ```
  /// seeds = [
  ///   owner,                // 32 bytes
  ///   tokenProgramId,       // 32 bytes (SPL Token program id)
  ///   tokenMint             // 32 bytes
  /// ]
  /// PDA = find_program_address(seeds, associatedTokenProgramId)
  /// ```
  ///
  /// - Parameters:
  ///   - tokenMint: The SPL token mint public key.
  ///   - allowOwnerOffCurve: If `false` (default), the owner must be an on-curve ed25519 key.
  ///                         If the owner is a PDA (off-curve), set this to `true`.
  ///   - tokenProgramId: SPL Token program id (defaults to the classic token program).
  ///   - associatedTokenProgramId: SPL Associated Token Account program id.
  /// - Returns: The derived ATA public key.
  /// - Throws: `AssociatedTokenError` if validation fails or PDA cannot be found.
  public func associatedTokenAddress(
    tokenMint: PublicKey,
    allowOwnerOffCurve: Bool = false,
    tokenProgramId: PublicKey = Solana.TokenProgram.programId,
    associatedTokenProgramId: PublicKey = Solana.AssociatedTokenProgram.programId) throws(AssociatedTokenError) -> PublicKey {
      if !allowOwnerOffCurve {
        do {
          guard try TweetNacl.isOnCurve(publicKey: self.data()) else { throw AssociatedTokenError.ownerOffCurve }
        } catch let error as AssociatedTokenError {
          throw error
        } catch {
          throw .underlying(error)
        }
      }
      let seeds = [
        self.data(),
        tokenProgramId.data(),
        tokenMint.data(),
      ]
      return try Self.findProgramAddress(data: seeds, programId: associatedTokenProgramId).0
    }
  
  // MARK: - PDA helpers
  
  /// Finds a **Program Derived Address (PDA)** by searching bump seeds from 255 down to 0.
  ///
  /// `findProgramAddress` computes `createProgramAddress(seeds + [bump], programId)` and returns
  /// the first address that is **off-curve** (valid PDA).
  ///
  /// - Parameters:
  ///   - data: Seed array; each item must be ≤ 32 bytes.
  ///   - programId: Program id that owns the PDA.
  /// - Returns: `(pda, bump)` where `bump` is the successful 0…255 bump seed.
  /// - Throws: `.noAddress` if no valid PDA could be derived for all bumps.
  static func findProgramAddress(data: [Data], programId: Self) throws(AssociatedTokenError) -> (Self, UInt8) {
    var nonce: UInt8 = .max // 255
    while nonce > 0 {
      if let address = try? createProgramAddress(seeds: data + [Data([nonce])], programId: programId) {
        return (address, nonce)
      }
      if nonce == 0 { break }
      nonce &-= 1
    }
    throw .noAddress
  }
  
  /// Creates a **Program Derived Address (PDA)** for the given seeds and program id.
  ///
  /// Layout:
  /// ```
  /// hash = sha256( concat(seeds...) || programId || "ProgramDerivedAddress" )
  /// pda  = Pubkey( hash[0..31] )     // 32 raw bytes from the digest
  /// require !isOnCurve(pda)          // PDA must be off-curve
  /// ```
  ///
  /// - Parameters:
  ///   - seeds: Seed array; each must be ≤ 32 bytes (Solana constraint).
  ///   - programId: Program id that owns the PDA.
  /// - Returns: The derived PDA as a `PublicKey`.
  /// - Throws:
  ///   - `.maxSeedLengthExceeded` if any seed > 32 bytes.
  ///   - `.invalidSeed` if the derived 32-byte value lies **on** the ed25519 curve.
  ///   - `.internalError` for unexpected formatting failures.
  static func createProgramAddress(seeds: [Data], programId: PublicKey) throws(AssociatedTokenError) -> PublicKey {
    var data = Data()
    for seed in seeds {
      guard seed.count <= 32 else { throw .maxSeedLengthExceeded }
      data.append(seed)
    }
    data.append(programId.data())
    data.append("ProgramDerivedAddress".data(using: .utf8)!)
    
    // SHA-256 digest is already 32 bytes. Use the raw bytes directly.
    let hash = data.sha256() // Data, 32 bytes
    guard hash.count == 32 else { throw .internalError }
    
    do {
      // PDA **must** be off-curve.
      guard try TweetNacl.isOnCurve(publicKey: hash) == false else {
        throw AssociatedTokenError.invalidSeed
      }
      // Construct PublicKey directly from the 32-byte digest.
      return try PublicKey(publicKey: hash, index: 0, network: .solana)
    } catch let error as AssociatedTokenError {
      throw error
    } catch {
      throw .underlying(error)
    }
  }
}
