//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/10/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana.StakeProgram {
  /// Parameters for the **DelegateStake** instruction.
  ///
  /// This instruction authorizes a validator to begin earning staking rewards
  /// on behalf of a previously created stake account.
  ///
  /// ### Layout
  /// The underlying Solana instruction expects three public keys:
  /// 1. `stakePubkey` – The stake account to be delegated.
  /// 2. `votePubkey` – The validator vote account to which the stake is delegated.
  /// 3. `authorizedPubkey` – The account that must sign to authorize delegation.
  ///
  /// ### Example
  /// ```swift
  /// let params = Solana.StakeProgram.DelegateStakeParams(
  ///   stakePubkey: stakeAccount,
  ///   authorizedPubkey: walletOwner,
  ///   votePubkey: validatorVoteAccount
  /// )
  /// let ix = try Solana.StakeProgram.delegateStake(params: params)
  /// ```
  ///
  /// ### Notes
  /// - The stake account must be initialized and have available balance.
  /// - The authorized staker must sign the transaction.
  /// - After delegation, the stake will begin to activate toward the chosen validator.
  /*public */package struct DelegateStakeParams: Sendable, Equatable, Hashable {
    /// The stake account being delegated.
    public let stakePubkey: PublicKey
    
    /// The authorized staker's public key (must sign).
    public let authorizedPubkey: PublicKey
    
    /// The validator vote account to which the stake will be delegated.
    public let votePubkey: PublicKey
    
    /// Creates new `DelegateStakeParams` with all required public keys.
    ///
    /// - Parameters:
    ///   - stakePubkey: The stake account being delegated.
    ///   - authorizedPubkey: The authorized staker public key (signer).
    ///   - votePubkey: The validator vote account to delegate to.
    public init(stakePubkey: PublicKey, authorizedPubkey: PublicKey, votePubkey: PublicKey) {
      self.stakePubkey = stakePubkey
      self.authorizedPubkey = authorizedPubkey
      self.votePubkey = votePubkey
    }
  }
}
