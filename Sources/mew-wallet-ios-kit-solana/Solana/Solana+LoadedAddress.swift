//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  public typealias AccountKeysFromLookups = LoadedAddresses
  
  public struct LoadedAddresses: Sendable, Equatable {
    var writable: [PublicKey] = []
    var readonly: [PublicKey] = []
    
    public init(writable: [PublicKey] = [], readonly: [PublicKey] = []) {
      self.writable = writable
      self.readonly = readonly
    }
  }
}
