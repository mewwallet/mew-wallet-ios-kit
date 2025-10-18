///
///  File.swift
///  mew-wallet-ios-kit
///
///  Created by Mikhail Nikanorov on 8/13/25.
///

import Foundation
import mew_wallet_ios_kit

extension Solana.SystemProgram {
  /// Parameters for **SystemProgram::CreateAccount**.
  ///
  /// Creates a brand new account owned by `programId`, funded by `fromPubkey`.
  /// The account's data space is allocated to `space` bytes and funded with `lamports`.
  ///
  /// Signers: `fromPubkey` **and** `newAccountPubkey`.
  public struct CreateAccountParams: Sendable, Equatable, Hashable {
    /// Payer that transfers lamports into the new account (signer).
    public let fromPubkey: PublicKey
    
    /// Newly created account public key (signer).
    public let newAccountPubkey: PublicKey
    
    /// Lamports to fund the new account (usually at least rent-exempt).
    public let lamports: UInt64
    
    /// Number of bytes of account data to allocate.
    public let space: UInt64
    
    /// Program that will own the new account.
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
  /// Parameters for the **Transfer** system instruction.
  public struct TransferParams: Sendable, Equatable, Hashable {
    /// Account that will transfer lamports (signer).
    public let fromPubkey: PublicKey
    
    /// Account that will receive transferred lamports.
    public let toPubkey: PublicKey
    
    /// Amount of lamports to transfer.
    public let lamports: UInt64
    
    /// Creates a parameter container for `SystemProgram.transfer`.
    public init(fromPubkey: PublicKey, toPubkey: PublicKey, lamports: UInt64) {
      self.fromPubkey = fromPubkey
      self.toPubkey = toPubkey
      self.lamports = lamports
    }
  }
}

extension Solana.SystemProgram {
  /// Parameters for the **Assign** system instruction.
  public struct AssignParams: Sendable, Equatable, Hashable {
    /// Account which will be assigned a new owner.
    public let accountPubkey: PublicKey
    
    /// Program to assign as the new owner.
    public let programId: PublicKey
    
    /// Creates a parameter container for `SystemProgram.assign`.
    public init(accountPubkey: PublicKey, programId: PublicKey) {
      self.accountPubkey = accountPubkey
      self.programId = programId
    }
  }
}

extension Solana.SystemProgram {
  /// Parameters for the **CreateAccountWithSeed** system instruction.
  public struct CreateAccountWithSeedParams: Sendable, Equatable, Hashable {
    /// The account that will transfer lamports to the created account (fee payer & signer).
    public let fromPubkey: PublicKey
    
    /// Public key of the created account.
    public let newAccountPubkey: PublicKey
    
    /// Base key used to derive `newAccountPubkey`.
    public let basePubkey: PublicKey
    
    /// Seed used to derive `newAccountPubkey`.
    public let seed: String
    
    /// Amount of lamports to transfer to the created account.
    public let lamports: UInt64
    
    /// Amount of space (in bytes) to allocate to the created account.
    public let space: UInt64
    
    /// Program to assign as the owner of the created account.
    public let programId: PublicKey
    
    /// Creates a parameter container for `SystemProgram.createAccountWithSeed`.
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
  /// Parameters for composing a **Create Nonce Account** sequence (System + Nonce init).
  public struct CreateNonceAccountParams: Sendable, Equatable, Hashable {
    /// The account that will transfer lamports to the created nonce account (fee payer & signer).
    public let fromPubkey: PublicKey
    
    /// Public key of the nonce account to create.
    public let noncePubkey: PublicKey
    
    /// Authority that will control the nonce account.
    public let authorizedPubkey: PublicKey
    
    /// Amount of lamports to transfer to the created nonce account.
    public let lamports: UInt64
    
    /// Creates a parameter container for creating and initializing a nonce account.
    public init(fromPubkey: PublicKey, noncePubkey: PublicKey, authorizedPubkey: PublicKey, lamports: UInt64) {
      self.fromPubkey = fromPubkey
      self.noncePubkey = noncePubkey
      self.authorizedPubkey = authorizedPubkey
      self.lamports = lamports
    }
  }
}


extension Solana.SystemProgram {
  /// Parameters for **Create Nonce Account With Seed** sequence.
  public struct CreateNonceAccountWithSeedParams: Sendable, Equatable, Hashable {
    /// The account that will transfer lamports to the created nonce account (fee payer & signer).
    public let fromPubkey: PublicKey
    
    /// Public key of the nonce account to create (derived with base+seed).
    public let noncePubkey: PublicKey
    
    /// Authority that will control the nonce account.
    public let authorizedPubkey: PublicKey
    
    /// Amount of lamports to transfer to the created nonce account.
    public let lamports: UInt64
    
    /// Base key used to derive the nonce account address.
    public let basePubkey: PublicKey;
    
    /// Seed used to derive the nonce account address.
    public let seed: String
    
    /// Creates a parameter container for creating and initializing a seeded nonce account.
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
  /// Parameters for the **Initialize Nonce Account** instruction.
  public struct InitializeNonceParams: Sendable, Equatable, Hashable {
    /// Nonce account to initialize.
    public let noncePubkey: PublicKey
    
    /// Authority that will control the initialized nonce account.
    public let authorizedPubkey: PublicKey
    
    /// Creates a parameter container for `SystemProgram.nonceInitialize`.
    public init(noncePubkey: PublicKey, authorizedPubkey: PublicKey) {
      self.noncePubkey = noncePubkey
      self.authorizedPubkey = authorizedPubkey
    }
  }
}

extension Solana.SystemProgram {
  /// Parameters for the **Advance Nonce** instruction.
  public struct AdvanceNonceParams: Sendable, Equatable, Hashable {
    /// Nonce account whose nonce will be advanced.
    public let noncePubkey: PublicKey;
    
    /// Current nonce authority (must sign).
    public let authorizedPubkey: PublicKey;
    
    /// Creates a parameter container for `SystemProgram.nonceAdvance`.
    public init(noncePubkey: PublicKey, authorizedPubkey: PublicKey) {
      self.noncePubkey = noncePubkey
      self.authorizedPubkey = authorizedPubkey
    }
  }
}

extension Solana.SystemProgram {
  /// Parameters for the **Withdraw Nonce** instruction.
  public struct WithdrawNonceParams: Sendable, Equatable, Hashable {
    /// Nonce account to withdraw from.
    public let noncePubkey: PublicKey
    
    /// Current nonce authority (must sign).
    public let authorizedPubkey: PublicKey
    
    /// Recipient of withdrawn lamports.
    public let toPubkey: PublicKey
    
    /// Amount of lamports to withdraw from the nonce account.
    public let lamports: UInt64
    
    /// Creates a parameter container for `SystemProgram.nonceWithdraw`.
    public init(noncePubkey: PublicKey, authorizedPubkey: PublicKey, toPubkey: PublicKey, lamports: UInt64) {
      self.noncePubkey = noncePubkey
      self.authorizedPubkey = authorizedPubkey
      self.toPubkey = toPubkey
      self.lamports = lamports
    }
  }
}

extension Solana.SystemProgram {
  /// Parameters for the **Authorize Nonce** instruction.
  public struct AuthorizeNonceParams: Sendable, Equatable, Hashable {
    /// Nonce account to update.
    public let noncePubkey: PublicKey
    
    /// Current nonce authority (must sign).
    public let authorizedPubkey: PublicKey
    
    /// New authority to set on the nonce account.
    public let newAuthorizedPubkey: PublicKey
    
    /// Creates a parameter container for `SystemProgram.nonceAuthorize`.
    public init(noncePubkey: PublicKey, authorizedPubkey: PublicKey, newAuthorizedPubkey: PublicKey) {
      self.noncePubkey = noncePubkey
      self.authorizedPubkey = authorizedPubkey
      self.newAuthorizedPubkey = newAuthorizedPubkey
    }
  }
}

extension Solana.SystemProgram {
  /// Parameters for the **Allocate** system instruction.
  public struct AllocateParams: Sendable, Equatable, Hashable {
    /// Account to allocate additional space for.
    public let accountPubkey: PublicKey
    
    /// Amount of space (in bytes) to allocate.
    public let space: UInt64
    
    /// Creates a parameter container for `SystemProgram.allocate`.
    public init(accountPubkey: PublicKey, space: UInt64) {
      self.accountPubkey = accountPubkey
      self.space = space
    }
  }
}

extension Solana.SystemProgram {
  /// Parameters for the **AllocateWithSeed** system instruction.
  public struct AllocateWithSeedParams: Sendable, Equatable, Hashable {
    /// Account to allocate (derived account).
    public let accountPubkey: PublicKey
    
    /// Base key used to derive the account address.
    public let basePubkey: PublicKey
    
    /// Seed used to derive the account address.
    public let seed: String
    
    /// Amount of space (in bytes) to allocate.
    public let space: UInt64
    
    /// Program to assign as the owner of the allocated account.
    public let programId: PublicKey
    
    /// Creates a parameter container for `SystemProgram.allocateWithSeed`.
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
  /// Parameters for the **AssignWithSeed** system instruction.
  public struct AssignWithSeedParams: Sendable, Equatable, Hashable {
    /// Account which will be assigned a new owner (derived account).
    public let accountPubkey: PublicKey
    
    /// Base key used to derive the account address.
    public let basePubkey: PublicKey
    
    /// Seed used to derive the account address.
    public let seed: String
    
    /// Program to assign as the owner.
    public let programId: PublicKey
    
    /// Creates a parameter container for `SystemProgram.assignWithSeed`.
    public init(accountPubkey: PublicKey, basePubkey: PublicKey, seed: String, programId: PublicKey) {
      self.accountPubkey = accountPubkey
      self.basePubkey = basePubkey
      self.seed = seed
      self.programId = programId
    }
  }
}

extension Solana.SystemProgram {
  /// Parameters for the **TransferWithSeed** system instruction.
  public struct TransferWithSeedParams: Sendable, Equatable, Hashable {
    /// Funding account (derived) that will transfer lamports.
    public let fromPubkey: PublicKey
    
    /// Base key used to derive the funding account address.
    public let basePubkey: PublicKey
    
    /// Recipient of transferred lamports.
    public let toPubkey: PublicKey
    
    /// Amount of lamports to transfer.
    public let lamports: UInt64
    
    /// Seed used to derive the funding account address.
    public let seed: String
    
    /// Program id used to derive the funding account address.
    public let programId: PublicKey
    
    /// Creates a parameter container for `SystemProgram.transferWithSeed`.
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
  /// Decoded payload for a **Transfer** instruction.
  public struct DecodedTransferInstruction: Sendable, Equatable, Hashable {
    /// Account that transferred lamports.
    public let fromPubkey: PublicKey
    
    /// Account that received lamports.
    public let toPubkey: PublicKey
    
    /// Amount of lamports transferred.
    public let lamports: UInt64
    
    /// Creates a decoded model for `SystemProgram.transfer`.
    public init(fromPubkey: PublicKey, toPubkey: PublicKey, lamports: UInt64) {
      self.fromPubkey = fromPubkey
      self.toPubkey = toPubkey
      self.lamports = lamports
    }
  }
}

extension Solana.SystemProgram {
  /// Decoded payload for a **TransferWithSeed** instruction.
  public struct DecodedTransferWithSeedInstruction: Sendable, Equatable, Hashable {
    /// Funding account (derived) that transferred lamports.
    public let fromPubkey: PublicKey
    
    /// Base key used to derive the funding account address.
    public let basePubkey: PublicKey
    
    /// Recipient account.
    public let toPubkey: PublicKey
    
    /// Amount of lamports transferred.
    public let lamports: UInt64
    
    /// Seed used to derive the funding account address.
    public let seed: String
    
    /// Program id used to derive the funding account address.
    public let programId: PublicKey
    
    /// Creates a decoded model for `SystemProgram.transferWithSeed`.
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
