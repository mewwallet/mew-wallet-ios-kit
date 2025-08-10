//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/9/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana.SystemProgram {
  public enum SysVar {
    static let clock                = try! PublicKey(base58: "SysvarC1ock11111111111111111111111111111111", network: .solana)
    static let epochSchedule        = try! PublicKey(base58: "SysvarEpochSchedu1e111111111111111111111111", network: .solana)
    static let instructions         = try! PublicKey(base58: "Sysvar1nstructions1111111111111111111111111", network: .solana)
    static let recentBlockhashes    = try! PublicKey(base58: "SysvarRecentB1ockHashes11111111111111111111", network: .solana)
    static let rent                 = try! PublicKey(base58: "SysvarRent111111111111111111111111111111111", network: .solana)
    static let rewards              = try! PublicKey(base58: "SysvarRewards111111111111111111111111111111", network: .solana)
    static let slotHashes           = try! PublicKey(base58: "SysvarS1otHashes111111111111111111111111111", network: .solana)
    static let slotHistory          = try! PublicKey(base58: "SysvarS1otHistory11111111111111111111111111", network: .solana)
    static let stakeHistory         = try! PublicKey(base58: "SysvarStakeHistory1111111111111111111111111", network: .solana)
  }
}
