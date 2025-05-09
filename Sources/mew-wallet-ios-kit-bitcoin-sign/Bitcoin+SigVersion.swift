//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/17/25.
//

import Foundation
import mew_wallet_ios_kit_bitcoin

extension Bitcoin {
  enum SigVersion {
    /// Bare scripts and BIP16 P2SH-wrapped redeemscripts
    case base
    /// Witness v0 (P2WPKH and P2WSH); see BIP 141
    case witness_v0
    /// Witness v1 with 32-byte program, not BIP16 P2SH-wrapped, key path spending; see BIP 341
    case taproot
    /// Witness v1 with 32-byte program, not BIP16 P2SH-wrapped, script path spending, leaf version 0xc0; see BIP 342
    case tapscript
  }
}
