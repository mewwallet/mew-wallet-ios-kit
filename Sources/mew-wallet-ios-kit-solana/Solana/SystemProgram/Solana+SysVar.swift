//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/9/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  /// Canonical **Sysvar** account public keys on Solana.
  ///
  /// These well-known accounts are maintained by the runtime and provide
  /// read-only system data (clock, rent, stake history, etc.) to programs.
  /// Keys match the official on-chain IDs (with the same “1” digit substitutions).
  public enum SysVar {
    /// Sysvar account that exposes cluster time-related data:
    /// slot, epoch, epoch start timestamp, leader schedule epoch, etc.
    /// Commonly read by programs to gate time/epoch-dependent logic.
    static let clock                = try! PublicKey(base58: "SysvarC1ock11111111111111111111111111111111", network: .solana)
    
    /// Sysvar with epoch configuration parameters such as slots per epoch and
    /// warmup/cooldown schedule. Used by staking and scheduling logic.
    static let epochSchedule        = try! PublicKey(base58: "SysvarEpochSchedu1e111111111111111111111111", network: .solana)
    
    /// Sysvar that records the **current transaction’s** instruction stack and
    /// allows CPI’d programs to introspect parent/peer instructions.
    /// Useful for security checks and meta-transaction flows.
    static let instructions         = try! PublicKey(base58: "Sysvar1nstructions1111111111111111111111111", network: .solana)
    
    /// **Deprecated** sysvar that used to expose a rolling window of recent
    /// blockhashes. Kept here for legacy program compatibility; modern flows
    /// should not rely on it.
    static let recentBlockhashes    = try! PublicKey(base58: "SysvarRecentB1ockHashes11111111111111111111", network: .solana)
    
    /// Sysvar that exposes rent parameters (e.g., rent exemption threshold).
    /// Programs read this to enforce rent-exempt minimums for accounts.
    static let rent                 = try! PublicKey(base58: "SysvarRent111111111111111111111111111111111", network: .solana)
    
    /// Sysvar with validator rewards-related information used by staking logic.
    static let rewards              = try! PublicKey(base58: "SysvarRewards111111111111111111111111111111", network: .solana)
    
    /// Sysvar that contains a recent history of `(slot, hash)` pairs.
    /// Often used by programs that need lightweight chain-history checks.
    static let slotHashes           = try! PublicKey(base58: "SysvarS1otHashes111111111111111111111111111", network: .solana)
    
    
    /// Sysvar that stores a bitmap-like history of processed slots for quick
    /// liveness/progress verification by programs.
    static let slotHistory          = try! PublicKey(base58: "SysvarS1otHistory11111111111111111111111111", network: .solana)
    
    
    /// Sysvar providing historical stake/activation information used by the
    /// stake program (e.g., warmup/cooldown and effective stake over time).
    static let stakeHistory         = try! PublicKey(base58: "SysvarStakeHistory1111111111111111111111111", network: .solana)
  }
}
