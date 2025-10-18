//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  /// Represents the **on-chain state** of a Solana Address Lookup Table (ALT).
  ///
  /// Address Lookup Tables store additional account addresses outside
  /// the transaction header, allowing v0 messages to include more than
  /// the 32-account limit of legacy transactions.
  ///
  /// ### Fields
  /// - `deactivationSlot`: The slot number after which the lookup table is no longer active.
  ///   - If equal to `UInt64.max`, the table is **active**.
  ///   - Otherwise, it was **deactivated** at or before this slot.
  ///
  /// - `lastExtendedSlot`: The slot when new addresses were last appended to the table.
  ///
  /// - `lastExtendedSlotStartIndex`: The index in `addresses` from which new entries
  ///   began at `lastExtendedSlot`. Used to efficiently resume extension.
  ///
  /// - `authority`: The optional address authorized to modify or close the lookup table.
  ///   - If `nil`, the table has no authority and cannot be modified.
  ///
  /// - `addresses`: The list of account public keys contained within this lookup table.
  ///
  /// ### Example
  /// ```swift
  /// let state = Solana.AddressLookupTableState(
  ///   deactivationSlot: UInt64.max,
  ///   lastExtendedSlot: 250000,
  ///   lastExtendedSlotStartIndex: 0,
  ///   authority: authorityPubkey,
  ///   addresses: cachedAddresses
  /// )
  /// ```
  public struct AddressLookupTableState: Sendable, Equatable {
    /// The slot number when the lookup table was deactivated.
    /// - `UInt64.max` means the table is still active.
    public let deactivationSlot: UInt64
    
    /// The slot number when new addresses were last appended to this table.
    public let lastExtendedSlot: UInt64
    
    /// Index within `addresses` where the most recent extension started.
    public let lastExtendedSlotStartIndex: UInt8
    
    /// The optional authority allowed to modify or close this table.
    /// - `nil` means the table has been finalized (no longer mutable).
    public let authority: PublicKey?
    
    /// The array of stored addresses referenced by recent v0 transactions.
    public let addresses: [PublicKey]
  }
  
  /// A wrapper that pairs a lookup table’s **account public key**
  /// with its decoded `AddressLookupTableState`.
  ///
  /// This structure simplifies higher-level API usage by bundling
  /// both metadata and the decoded state together.
  ///
  /// ### Computed Properties
  /// - `isActive`: Returns `true` if `deactivationSlot == UInt64.max`.
  ///
  /// ### Example
  /// ```swift
  /// if lookupTableAccount.isActive {
  ///   print("Lookup table \(lookupTableAccount.key) is active")
  /// }
  /// ```
  public struct AddressLookupTableAccount: Sendable, Equatable {
    /// The public key of the Address Lookup Table account.
    public let key: PublicKey
    
    /// The decoded `AddressLookupTableState` representing the account’s contents.
    public let state: AddressLookupTableState
    
    /// Indicates whether the lookup table is still active and usable.
    ///
    /// Returns `true` if `deactivationSlot` equals `UInt64.max`.
    var isActive: Bool {
      return self.state.deactivationSlot == UInt64.max
    }
    
    /// Initializes a new lookup table account representation.
    ///
    /// - Parameters:
    ///   - key: The account’s public key.
    ///   - state: The parsed state of the lookup table.
    public init(key: PublicKey, state: AddressLookupTableState) {
      self.key = key
      self.state = state
    }
  }
}
