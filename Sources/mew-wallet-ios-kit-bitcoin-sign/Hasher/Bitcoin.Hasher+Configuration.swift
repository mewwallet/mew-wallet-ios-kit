//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/18/25.
//

import Foundation
import mew_wallet_ios_kit_bitcoin

/// A factory and configuration utility for selecting the appropriate sighash computation logic.
/// Supports mapping between script types and sighash versions, and producing correct hashers.

extension Bitcoin.Hasher {
  /// Describes how a transaction input should be signed:
  /// - `sigVersion`: Determines the hashing strategy (Base, WitnessV0, Taproot, etc).
  /// - `multisig`: Indicates whether this input uses a multisig redeem/witness script.
  struct Configuration {
    /// The version of the sighash algorithm to use, based on script type (base, witness_v0, taproot, etc).
    let sigVersion: Bitcoin.SigVersion
    
    /// Indicates whether the script being signed is a multisig script.
    /// This is used to prevent unsupported cases (e.g., base multisig).
    let multisig: Bool
  }
  
  /// Returns an appropriate sighash hasher implementation based on the given `sigVersion`.
  ///
  /// - Parameter sigVersion: The script version to use for hashing.
  /// - Throws: `.notSupported` if the version is not yet implemented.
  /// - Returns: A type-erased `SignHasher` implementation.
  static func hasher(for sigVersion: Bitcoin.SigVersion) throws(Bitcoin.Hasher.Error) -> any Bitcoin.Hasher.SignHasher {
    switch sigVersion {
    case .base:
      return Bitcoin.Hasher.BaseHasher()
    case .witness_v0:
      return Bitcoin.Hasher.WitnessV0Hasher()
    default:
      throw .notSupported
    }
  }
  
  /// Returns a sighash hasher based on full configuration (version + multisig info).
  ///
  /// - Throws: `.notSupported` if multisig is currently unsupported or version is not implemented.
  static func hasher(for configuration: Bitcoin.Hasher.Configuration) throws(Bitcoin.Hasher.Error) -> any Bitcoin.Hasher.SignHasher {
    guard !configuration.multisig else {
      throw Bitcoin.Hasher.Error.notSupported
    }
    switch configuration.sigVersion {
    case .base:
      return Bitcoin.Hasher.BaseHasher()
    case .witness_v0:
      return Bitcoin.Hasher.WitnessV0Hasher()
    default:
      throw .notSupported
    }
  }
  
  /// Determines the appropriate `Hasher.Configuration` for a given locking script,
  /// optionally using `redeemScript` and `witnessScript` for nested or wrapped scripts.
  ///
  /// This maps script types (e.g., P2PKH, P2SH-P2WPKH, P2WSH) to SigVersion and multisig flags.
  ///
  /// - Parameters:
  ///   - script: The scriptPubKey or UTXO locking script.
  ///   - witnessScript: Optional witness script if applicable.
  ///   - redeemScript: Optional redeem script if applicable.
  ///   - isTapscript: Indicates whether the spending path is via script-path in Taproot.
  ///
  /// - Throws: `.notSupported` if the script type is unknown or unsupported.
  /// - Returns: A `Hasher.Configuration` with derived version and multisig flag.
  static func configuration(for script: Bitcoin.Script, witnessScript: Bitcoin.Script?, redeemScript: Bitcoin.Script?, isTapscript: Bool = false) throws(Bitcoin.Hasher.Error) -> Bitcoin.Hasher.Configuration {
    switch script.type {
    case .nonstandard, .nulldata, .witness_unknown, .anchor:
      throw .notSupported
      
    case .witness_v1_taproot:
      throw .notSupported
      // TODO
//        return .init(sigVersion: isTapscript ? .tapscript : .taproot, multisig: false)
      
    case .witness_v0_keyhash:
      return .init(sigVersion: .witness_v0, multisig: false)
      
    case .witness_v0_scripthash:
      return .init(sigVersion: .witness_v0, multisig: witnessScript?.type == .multisig)
      
    case .scripthash:
      switch redeemScript?.type {
      case .nonstandard, .nulldata, .witness_v1_taproot, .witness_unknown, .anchor:
        throw .notSupported
        
      case .witness_v0_keyhash:
        return .init(sigVersion: .witness_v0, multisig: false)
        
      case .witness_v0_scripthash:
        return .init(sigVersion: .witness_v0, multisig: witnessScript?.type == .multisig)
        
      case .multisig:
        return .init(sigVersion: .base, multisig: true)
        
      default:
        return .init(sigVersion: .base, multisig: redeemScript?.type == .multisig)
      }
      
    default:
      return .init(sigVersion: .base, multisig: script.type == .multisig)
    }
  }
}
