//
//  Address.swift
//  MEWwalletKit
//
//  Created by Mikhail Nikanorov on 4/25/19.
//  Copyright © 2019 MyEtherWallet Inc. All rights reserved.
//

import Foundation
import CryptoSwift

public struct Address: CustomDebugStringConvertible, Sendable {
  public struct Ethereum {
    static let length = 42
  }
  
  private var _address: String
  public var address: String {
    return self._address
  }
    
    public var data: Data {
        return Data(hex: address)
    }
  
  public init?(data: Data, prefix: String? = nil) {
    self.init(address: data.toHexString(), prefix: prefix)
  }
  
  public init(raw: String) {
    self._address = raw
  }
  
  public init?(address: String, prefix: String? = nil) {
    var address = address
    if let prefix = prefix, !address.hasPrefix(prefix) {
      address.insert(contentsOf: prefix, at: address.startIndex)
    }
    if address.stringAddHexPrefix().count == Address.Ethereum.length, prefix == nil, address.isHex(), let eip55address = address.stringAddHexPrefix().eip55() {
      self._address = eip55address
    } else {
      self._address = address
    }
  }
  
  public init?(ethereumAddress: String) {
    let value = ethereumAddress.stringAddHexPrefix()
    guard value.count == Address.Ethereum.length, value.isHex(), let address = value.eip55() else { return nil } // 42 = 0x + 20bytes
    self._address = address
  }
  
  public init?(bitcoinAddress: String) {
    let alphabet = Network.bitcoin(.legacy).alphabet
    
    // Try Base58Check decode
    if let alphabet, let decoded = bitcoinAddress.decodeBase58(alphabet: alphabet), decoded.count == 25 {
      let payload = decoded.prefix(21)
      let checksum = decoded.suffix(4)
      let calculated: Data = payload.hash256().prefix(4)
      
      if checksum == calculated {
        self._address = bitcoinAddress
        return
      }
    }
    
    // Bech32 / Bech32m (SegWit)
    for encoding in [Bech32.Encoding.bech32, .bech32m] {
      let bech32 = Bech32(encoding: encoding)
      do {
        let (hrp, words) = try bech32.decode(bitcoinAddress)
        guard (hrp == "bc" || hrp == "tb" || hrp == "bcrt"), let witnessVersion = words.first else { continue }
        
        let witnessProgram = try bech32.fromWords(words: Array(words.dropFirst()))
        
        switch encoding {
        case .bech32:
          guard witnessVersion == 0 else { continue } // BIP173
        case .bech32m:
          guard witnessVersion > 0 else { continue } // BIP350
        }
        
        guard witnessProgram.count == 20 || witnessProgram.count == 32 else { continue }
        
        self._address = bitcoinAddress
        return
      } catch {}
    }
    
    return nil
  }
  
  public var debugDescription: String {
    return self._address
  }
}

extension Address: Equatable {
  public static func == (lhs: Address, rhs: Address) -> Bool {
    return lhs._address.lowercased() == rhs._address.lowercased()
  }
}
