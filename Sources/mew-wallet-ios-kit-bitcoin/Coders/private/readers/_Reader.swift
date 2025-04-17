//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/14/25.
//

import Foundation

internal enum _Reader {
  /// Enumerates the distinct PSBT map sections defined in BIP-174.
  /// Each map is encoded sequentially: global → input(s) → output(s).
  enum GlobalMap: UInt8 {
    /// Global key-value pairs (e.g., unsigned tx, xpubs, version).
    case global_map = 0
    
    /// Input maps (multiple, one per transaction input).
    case input_map  = 1
    
    /// Output maps (multiple, one per transaction output).
    case output_map = 2
    
    /// Returns the next logical map section, if any.
    var next: GlobalMap? {
      switch self {
      case .global_map:
        return .input_map
      case .input_map:
        return .output_map
      case .output_map:
        return nil
      }
    }
  }
  
  /// Represents a decoded PSBT key with an optional sub-key payload.
  ///
  /// For known (standard) types, an enum key is used.
  /// For unknown (proprietary or future) types, a raw byte is preserved.
  ///
  /// - Parameters:
  ///   - K: Known PSBT key type (e.g. `PSBT.InputType`)
  ///   - U: Unknown/raw key type (usually `UInt8`)
  enum KeyType<K, U> {
    /// A known key with optional additional payload (`keydata`).
    case known(K, Data.SubSequence?)
    
    /// An unknown or proprietary key, retaining the original key ID.
    case unknown(U, Data.SubSequence?)
    
    /// An empty key (0-length key).
    case empty
  }
  
  /// Represents a parsed PSBT key for global, input, or output maps.
  enum MapKey {
    /// Global key (e.g., unsigned tx, xpub, version).
    case globalMap(KeyType<mew_wallet_ios_kit_bitcoin.PSBT.GlobalType, UInt8>)
    
    /// Input-specific key (e.g., UTXOs, partial sigs, scripts).
    case inputMap(KeyType<mew_wallet_ios_kit_bitcoin.PSBT.InputType, UInt8>)
    
    /// Output-specific key (e.g., redeem/witness scripts).
    case outputMap(KeyType<mew_wallet_ios_kit_bitcoin.PSBT.OutputType, UInt8>)
    
    /// Indicates whether the key is explicitly empty.
    var isEmpty: Bool {
      switch self {
      case .globalMap(.empty),
          .inputMap(.empty),
          .outputMap(.empty):
        return true
      default:
        return false
      }
    }
    
    /// Initializes a typed PSBT map key based on map section and raw key bytes.
    ///
    /// - Parameters:
    ///   - map: The current map section (`global`, `input`, or `output`).
    ///   - data: The raw key data to decode.
    init(map: GlobalMap, data: Data.SubSequence) {
      guard let byte = data.first else {
        switch map {
        case .global_map:
          self = .globalMap(.empty)
        case .input_map:
          self = .inputMap(.empty)
        case .output_map:
          self = .outputMap(.empty)
        }
        return
      }
      let keydata = data.dropFirst()
      switch map {
      case .global_map:
        if let type = mew_wallet_ios_kit_bitcoin.PSBT.GlobalType(rawValue: byte) {
          self = .globalMap(.known(type, keydata))
        } else {
          self = .globalMap(.unknown(byte, keydata))
        }
      case .input_map:
        if let type = mew_wallet_ios_kit_bitcoin.PSBT.InputType(rawValue: byte) {
          self = .inputMap(.known(type, keydata))
        } else {
          self = .inputMap(.unknown(byte, keydata))
        }
      case .output_map:
        if let type = mew_wallet_ios_kit_bitcoin.PSBT.OutputType(rawValue: byte) {
          self = .outputMap(.known(type, keydata))
        } else {
          self = .outputMap(.unknown(byte, keydata))
        }
      }
    }
  }
}
