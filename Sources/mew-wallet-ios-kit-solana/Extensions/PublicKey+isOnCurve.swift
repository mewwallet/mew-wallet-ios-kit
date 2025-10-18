//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 10/16/25.
//

import Foundation
import mew_wallet_ios_kit
import mew_wallet_ios_tweetnacl

extension PublicKey {
  /// Returns a Boolean value indicating whether this public key lies on the Ed25519 curve.
  ///
  /// This property uses the `TweetNacl.isOnCurve(publicKey:)` check to validate whether
  /// the public key corresponds to a point on the **Edwards25519** elliptic curve.
  ///
  /// ### Use cases
  /// - To verify that a given public key is a valid Ed25519 key (e.g., for signature verification).
  /// - To ensure that a Solana address is **not** a *program-derived address (PDA)*,
  ///   since PDAs are intentionally *off-curve*.
  ///
  /// ### Throws
  /// - Rethrows any underlying error from the TweetNaCl curve validation implementation.
  ///
  /// - SeeAlso: `TweetNacl.isOnCurve(publicKey:)`
  public var isOnCurve: Bool {
    get throws {
      try TweetNacl.isOnCurve(publicKey: self.data())
    }
  }
}
