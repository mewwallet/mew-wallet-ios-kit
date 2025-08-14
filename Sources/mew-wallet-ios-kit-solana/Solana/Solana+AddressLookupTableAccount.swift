//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  public struct AddressLookupTableState: Sendable, Equatable {
    public let deactivationSlot: UInt64
    public let lastExtendedSlot: UInt64
    public let lastExtendedSlotStartIndex: UInt8
    public let authority: PublicKey?
    public let addresses: [PublicKey]
  }
  
  public struct AddressLookupTableAccount: Sendable, Equatable {
    public let key: PublicKey
    public let state: AddressLookupTableState
    
    var isActive: Bool {
      return self.state.deactivationSlot == UInt64.max
    }
    
    public init(key: PublicKey, state: AddressLookupTableState) {
      self.key = key
      self.state = state
    }
  }
}
