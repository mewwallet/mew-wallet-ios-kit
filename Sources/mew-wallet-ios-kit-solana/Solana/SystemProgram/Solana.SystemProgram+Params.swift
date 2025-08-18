///
///  File.swift
///  mew-wallet-ios-kit
///
///  Created by Mikhail Nikanorov on 8/13/25.
///

import Foundation
import mew_wallet_ios_kit


extension Solana.SystemProgram {
  /// Create account system transaction params
  public struct CreateAccountParams: Sendable, Equatable, Hashable {
    /// The account that will transfer lamports to the created account
    public let fromPubkey: PublicKey
    
    /// Public key of the created account
    public let newAccountPubkey: PublicKey
    
    /// Amount of lamports to transfer to the created account
    public let lamports: UInt64
    
    /// Amount of space in bytes to allocate to the created account
    public let space: UInt64
    
    /// Public key of the program to assign as the owner of the created account
    public let programId: PublicKey
    
    public init(fromPubkey: PublicKey, newAccountPubkey: PublicKey, lamports: UInt64, space: UInt64, programId: PublicKey) {
      self.fromPubkey = fromPubkey
      self.newAccountPubkey = newAccountPubkey
      self.lamports = lamports
      self.space = space
      self.programId = programId
    }
  }
}

extension Solana.SystemProgram {
  /// Transfer system transaction params
  public struct TransferParams: Sendable, Equatable, Hashable {
    /// Account that will transfer lamports
    public let fromPubkey: PublicKey
    
    /// Account that will receive transferred lamports
    public let toPubkey: PublicKey
    
    /// Amount of lamports to transfer
    public let lamports: UInt64
    
    public init(fromPubkey: PublicKey, toPubkey: PublicKey, lamports: UInt64) {
      self.fromPubkey = fromPubkey
      self.toPubkey = toPubkey
      self.lamports = lamports
    }
  }
}

extension Solana.SystemProgram {
  /// Assign system transaction params
  public struct AssignParams: Sendable, Equatable, Hashable {
    /// Public key of the account which will be assigned a new owner
    public let accountPubkey: PublicKey
    
    /// Public key of the program to assign as the owner
    public let programId: PublicKey
    
    public init(accountPubkey: PublicKey, programId: PublicKey) {
      self.accountPubkey = accountPubkey
      self.programId = programId
    }
  }
}

extension Solana.SystemProgram {
  /// Create account with seed system transaction params
  public struct CreateAccountWithSeedParams: Sendable, Equatable, Hashable {
    /// The account that will transfer lamports to the created account
    public let fromPubkey: PublicKey
    
    /// Public key of the created account. Must be pre-calculated with PublicKey.createWithSeed()
    public let newAccountPubkey: PublicKey
    
    /// Base public key to use to derive the address of the created account. Must be the same as the base key used to create `newAccountPubkey`
    public let basePubkey: PublicKey
    
    /// Seed to use to derive the address of the created account. Must be the same as the seed used to create `newAccountPubkey`
    public let seed: String
    
    /// Amount of lamports to transfer to the created account
    public let lamports: UInt64
    
    /// Amount of space in bytes to allocate to the created account
    public let space: UInt64
    
    /// Public key of the program to assign as the owner of the created account
    public let programId: PublicKey
    
    public init(fromPubkey: PublicKey, newAccountPubkey: PublicKey, basePubkey: PublicKey, seed: String, lamports: UInt64, space: UInt64, programId: PublicKey) {
      self.fromPubkey = fromPubkey
      self.newAccountPubkey = newAccountPubkey
      self.basePubkey = basePubkey
      self.seed = seed
      self.lamports = lamports
      self.space = space
      self.programId = programId
    }
  }
}

extension Solana.SystemProgram {
  /// Create nonce account system transaction params
  public struct CreateNonceAccountParams: Sendable, Equatable, Hashable {
    /// The account that will transfer lamports to the created nonce account
    public let fromPubkey: PublicKey
    
    /// Public key of the created nonce account
    public let noncePubkey: PublicKey
    
    /// Public key to set as authority of the created nonce account
    public let authorizedPubkey: PublicKey
    
    /// Amount of lamports to transfer to the created nonce account
    public let lamports: UInt64
    
    public init(fromPubkey: PublicKey, noncePubkey: PublicKey, authorizedPubkey: PublicKey, lamports: UInt64) {
      self.fromPubkey = fromPubkey
      self.noncePubkey = noncePubkey
      self.authorizedPubkey = authorizedPubkey
      self.lamports = lamports
    }
  }
}


extension Solana.SystemProgram {
  /// Create nonce account with seed system transaction params
  public struct CreateNonceAccountWithSeedParams: Sendable, Equatable, Hashable {
    /// The account that will transfer lamports to the created nonce account
    public let fromPubkey: PublicKey
    
    /// Public key of the created nonce account
    public let noncePubkey: PublicKey
    
    /// Public key to set as authority of the created nonce account
    public let authorizedPubkey: PublicKey
    
    /// Amount of lamports to transfer to the created nonce account
    public let lamports: UInt64
    
    /// Base public key to use to derive the address of the nonce account
    public let basePubkey: PublicKey;
    
    /// Seed to use to derive the address of the nonce account
    public let seed: String
    
    public init(fromPubkey: PublicKey, noncePubkey: PublicKey, authorizedPubkey: PublicKey, lamports: UInt64, basePubkey: PublicKey, seed: String) {
      self.fromPubkey = fromPubkey
      self.noncePubkey = noncePubkey
      self.authorizedPubkey = authorizedPubkey
      self.lamports = lamports
      self.basePubkey = basePubkey
      self.seed = seed
    }
  }
}



extension Solana.SystemProgram {
  /// Initialize nonce account system instruction params
  public struct InitializeNonceParams: Sendable, Equatable, Hashable {
    /// Nonce account which will be initialized
    public let noncePubkey: PublicKey
    
    /// Public key to set as authority of the initialized nonce account
    public let authorizedPubkey: PublicKey
    
    public init(noncePubkey: PublicKey, authorizedPubkey: PublicKey) {
      self.noncePubkey = noncePubkey
      self.authorizedPubkey = authorizedPubkey
    }
  }
}

extension Solana.SystemProgram {
  /// Advance nonce account system instruction params
  public struct AdvanceNonceParams: Sendable, Equatable, Hashable {
    /// Nonce account
    public let noncePubkey: PublicKey;
    
    /// Public key of the nonce authority
    public let authorizedPubkey: PublicKey;
    
    public init(noncePubkey: PublicKey, authorizedPubkey: PublicKey) {
      self.noncePubkey = noncePubkey
      self.authorizedPubkey = authorizedPubkey
    }
  }
}

extension Solana.SystemProgram {
  /// Withdraw nonce account system transaction params
  public struct WithdrawNonceParams: Sendable, Equatable, Hashable {
    /// Nonce account
    public let noncePubkey: PublicKey
    
    /// Public key of the nonce authority
    public let authorizedPubkey: PublicKey
    
    /// Public key of the account which will receive the withdrawn nonce account balance
    public let toPubkey: PublicKey
    
    /// Amount of lamports to withdraw from the nonce account
    public let lamports: UInt64
    
    public init(noncePubkey: PublicKey, authorizedPubkey: PublicKey, toPubkey: PublicKey, lamports: UInt64) {
      self.noncePubkey = noncePubkey
      self.authorizedPubkey = authorizedPubkey
      self.toPubkey = toPubkey
      self.lamports = lamports
    }
  }
}

extension Solana.SystemProgram {
  /// Authorize nonce account system transaction params
  public struct AuthorizeNonceParams: Sendable, Equatable, Hashable {
    /// Nonce account
    public let noncePubkey: PublicKey
    
    /// Public key of the current nonce authority
    public let authorizedPubkey: PublicKey
    
    /// Public key to set as the new nonce authority
    public let newAuthorizedPubkey: PublicKey
    
    public init(noncePubkey: PublicKey, authorizedPubkey: PublicKey, newAuthorizedPubkey: PublicKey) {
      self.noncePubkey = noncePubkey
      self.authorizedPubkey = authorizedPubkey
      self.newAuthorizedPubkey = newAuthorizedPubkey
    }
  }
}

extension Solana.SystemProgram {
  /// Allocate account system transaction params
  public struct AllocateParams: Sendable, Equatable, Hashable {
    /// Account to allocate
    public let accountPubkey: PublicKey
    
    /// Amount of space in bytes to allocate
    public let space: UInt64
    
    public init(accountPubkey: PublicKey, space: UInt64) {
      self.accountPubkey = accountPubkey
      self.space = space
    }
  }
}

extension Solana.SystemProgram {
  /// Allocate account with seed system transaction params
  public struct AllocateWithSeedParams: Sendable, Equatable, Hashable {
    /// Account to allocate
    public let accountPubkey: PublicKey
    
    /// Base public key to use to derive the address of the allocated account
    public let basePubkey: PublicKey
    
    /// Seed to use to derive the address of the allocated account
    public let seed: String
    
    /// Amount of space in bytes to allocate
    public let space: UInt64
    
    /// Public key of the program to assign as the owner of the allocated account
    public let programId: PublicKey
    
    public init(accountPubkey: PublicKey, basePubkey: PublicKey, seed: String, space: UInt64, programId: PublicKey) {
      self.accountPubkey = accountPubkey
      self.basePubkey = basePubkey
      self.seed = seed
      self.space = space
      self.programId = programId
    }
  }
}

extension Solana.SystemProgram {
  /// Assign account with seed system transaction params
  public struct AssignWithSeedParams: Sendable, Equatable, Hashable {
    /// Public key of the account which will be assigned a new owner
    public let accountPubkey: PublicKey
    
    /// Base public key to use to derive the address of the assigned account
    public let basePubkey: PublicKey
    
    /// Seed to use to derive the address of the assigned account
    public let seed: String
    
    /// Public key of the program to assign as the owner
    public let programId: PublicKey
    
    public init(accountPubkey: PublicKey, basePubkey: PublicKey, seed: String, programId: PublicKey) {
      self.accountPubkey = accountPubkey
      self.basePubkey = basePubkey
      self.seed = seed
      self.programId = programId
    }
  }
}

extension Solana.SystemProgram {
  /// Transfer with seed system transaction params
  public struct TransferWithSeedParams: Sendable, Equatable, Hashable {
    /// Account that will transfer lamports
    public let fromPubkey: PublicKey
    
    /// Base public key to use to derive the funding account address
    public let basePubkey: PublicKey
    
    /// Account that will receive transferred lamports
    public let toPubkey: PublicKey
    
    /// Amount of lamports to transfer
    public let lamports: UInt64
    
    /// Seed to use to derive the funding account address
    public let seed: String
    
    /// Program id to use to derive the funding account address
    public let programId: PublicKey
    
    public init(fromPubkey: PublicKey, basePubkey: PublicKey, toPubkey: PublicKey, lamports: UInt64, seed: String, programId: PublicKey) {
      self.fromPubkey = fromPubkey
      self.basePubkey = basePubkey
      self.toPubkey = toPubkey
      self.lamports = lamports
      self.seed = seed
      self.programId = programId
    }
  }
}

extension Solana.SystemProgram {
  /// Decoded transfer system transaction instruction
  public struct DecodedTransferInstruction: Sendable, Equatable, Hashable {
    /// Account that will transfer lamports
    public let fromPubkey: PublicKey
    
    /// Account that will receive transferred lamports
    public let toPubkey: PublicKey
    
    /// Amount of lamports to transfer
    public let lamports: UInt64
    
    public init(fromPubkey: PublicKey, toPubkey: PublicKey, lamports: UInt64) {
      self.fromPubkey = fromPubkey
      self.toPubkey = toPubkey
      self.lamports = lamports
    }
  }
}

extension Solana.SystemProgram {
  /// Decoded transferWithSeed system transaction instruction
  public struct DecodedTransferWithSeedInstruction: Sendable, Equatable, Hashable {
    /// Account that will transfer lamports
    public let fromPubkey: PublicKey
    
    /// Base public key to use to derive the funding account address
    public let basePubkey: PublicKey
    
    /// Account that will receive transferred lamports
    public let toPubkey: PublicKey
    
    /// Amount of lamports to transfer
    public let lamports: UInt64
    
    /// Seed to use to derive the funding account address
    public let seed: String
    
    /// Program id to use to derive the funding account address
    public let programId: PublicKey
    
    public init(fromPubkey: PublicKey, basePubkey: PublicKey, toPubkey: PublicKey, lamports: UInt64, seed: String, programId: PublicKey) {
      self.fromPubkey = fromPubkey
      self.basePubkey = basePubkey
      self.toPubkey = toPubkey
      self.lamports = lamports
      self.seed = seed
      self.programId = programId
    }
  }
}
