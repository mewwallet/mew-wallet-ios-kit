//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  /// Alias for the set of addresses loaded via Address Lookup Tables (ALTs)
  /// and attached to a v0 message. Matches the naming used by Solana JS SDK.
  public typealias AccountKeysFromLookups = LoadedAddresses
  
  /// Addresses pulled from Address Lookup Tables (ALTs) and attached to a v0 message.
  ///
  /// The message format splits ALT-derived accounts into two ordered lists:
  /// - `writable`: ALT accounts that are writable in this message.
  /// - `readonly`: ALT accounts that are read-only in this message.
  ///
  /// ### Ordering
  /// The order of accounts inside each array **must** match the order implied by the
  /// shortvec indices encoded in `MessageAddressTableLookup` for the corresponding ALT.
  /// Your `extractTableLookup` implementation already preserves this by pushing keys
  /// in the order they’re discovered from the lookup table.
  ///
  /// ### Usage
  /// Used alongside the static account keys to fully reconstruct the account meta set
  /// when compiling or interpreting a versioned (v0) message.
  public struct LoadedAddresses: Sendable, Equatable {
    /// ALT-derived accounts that are **writable** in the message.
    /// The position of each entry corresponds to its shortvec index in the writable set.
    public var writable: [PublicKey] = []
    
    /// ALT-derived accounts that are **read-only** in the message.
    /// The position of each entry corresponds to its shortvec index in the read-only set.
    public var readonly: [PublicKey] = []
    
    /// Creates a new `LoadedAddresses` container.
    ///
    /// - Parameters:
    ///   - writable: Writable ALT accounts, ordered to match the lookup indices.
    ///   - readonly: Read-only ALT accounts, ordered to match the lookup indices.
    public init(writable: [PublicKey] = [], readonly: [PublicKey] = []) {
      self.writable = writable
      self.readonly = readonly
    }
  }
}
