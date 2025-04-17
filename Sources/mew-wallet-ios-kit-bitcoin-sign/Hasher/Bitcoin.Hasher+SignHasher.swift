//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/18/25.
//

import Foundation
import mew_wallet_ios_kit_bitcoin

extension Bitcoin.Hasher {
  /// A unified interface for producing a signature hash (sighash) preimage.
  ///
  /// Concrete implementations (e.g. `BaseHasher`, `WitnessV0Hasher`, `TaprootHasher`) conform to this protocol
  /// and use injected contextual `Key` values to build the correct sighash digest.
  ///
  /// Typical usage:
  /// 1. Instantiate a `SignHasher` (e.g. via `Bitcoin.Hasher.hasher(for:)`).
  /// 2. Feed in all required `Key`s using `.combine(key:)`.
  /// 3. Call `.finalize()` to compute the signature hash.
  protocol SignHasher {
    /// Adds a contextual key (e.g., transaction, scriptCode, sighash type) needed to build the sighash.
    /// This method may be called multiple times with different keys.
    ///
    /// If a key with the same ID already exists, it will be replaced.
    ///
    /// - Parameter key: The key-value context required for hashing.
    func combine(key: Bitcoin.Hasher.Key)
    
    /// Computes the final signature hash using the injected keys.
    ///
    /// - Throws: `.missingKeys` if required keys are not provided.
    /// - Throws: `.encodingFailed` if transaction serialization fails.
    /// - Returns: A 32-byte sighash digest (to be signed by the private key).
    func finalize() throws(Bitcoin.Hasher.Error) -> Data
  }
}
