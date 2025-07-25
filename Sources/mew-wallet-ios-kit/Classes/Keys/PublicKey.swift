//
//  PublicKeyEth1.swift
//  MEWwalletKitTests
//
//  Created by Mikhail Nikanorov on 4/17/19.
//  Copyright © 2019 MyEtherWallet Inc. All rights reserved.
//

import Foundation
import mew_wallet_ios_secp256k1

private struct PublicKeyConstants {
  static let compressedKeySize = 33
  static let decompressedKeySize = 65
  
  static let compressedFlags = UInt32(SECP256K1_EC_COMPRESSED)
  static let decompressedFlags = UInt32(SECP256K1_EC_UNCOMPRESSED)
}

private struct PublicKeyConfig {
  private let compressed: Bool
  
  var keySize: Int {
    return self.compressed ? PublicKeyConstants.compressedKeySize : PublicKeyConstants.decompressedKeySize
  }
  
  var keyFlags: UInt32 {
    return self.compressed ? PublicKeyConstants.compressedFlags : PublicKeyConstants.decompressedFlags
  }
  
  init(compressed: Bool) {
    self.compressed = compressed
  }
}

@available(*, deprecated, renamed: "PublicKey", message: "Please use PublicKey instead")
public typealias PublicKeyEth1 = PublicKey

public struct PublicKey: IPublicKey {
  private let raw: Data
  private let chainCode: Data
  private let depth: UInt8
  private let fingerprint: Data
  private let index: UInt32
  public let network: Network
  private let config: PublicKeyConfig
  
  init(privateKey: Data, compressed: Bool = false, chainCode: Data, depth: UInt8, fingerprint: Data, index: UInt32, network: Network) throws {
    self.config = PublicKeyConfig(compressed: compressed)
    guard let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN)) else {
      throw PublicKeyError.internalError
    }
    defer { secp256k1_context_destroy(context) }
    
    var pKey = try secp256k1_pubkey(privateKey: privateKey, context: context)
    
    guard let rawData = pKey.data(context: context, flags: self.config.keyFlags) else {
      throw PublicKeyError.internalError
    }
    self.raw = rawData
    self.chainCode = chainCode
    self.depth = depth
    self.fingerprint = fingerprint
    self.index = index
    self.network = network
  }
  
  init(publicKey: Data, compressed: Bool? = false, index: UInt32, network: Network) throws {
    guard let compressed = compressed else {
      throw PublicKeyError.invalidConfiguration
    }
    self.config = PublicKeyConfig(compressed: compressed)
    self.raw = publicKey
    self.chainCode = Data()
    self.depth = 0
    self.fingerprint = Data()
    self.index = index
    self.network = network
  }
}

extension PublicKey: IKey {
  public func string(compressedPublicKey: Bool) -> String? {
    return self.raw.toHexString()
  }
  
  public func extended() -> String? {
    guard let alphabet = self.network.alphabet else { return nil }
    var extendedKey = Data()
    
    extendedKey += Data(self.network.publicKeyPrefix.littleEndian.bytes)
    extendedKey += Data(self.depth.bigEndian.bytes)
    extendedKey += self.fingerprint
    extendedKey += Data(self.index.bigEndian.bytes)
    extendedKey += self.chainCode
    extendedKey += self.raw
    let checksum = extendedKey.sha256().sha256().prefix(4)
    extendedKey += checksum
    return extendedKey.encodeBase58(alphabet: alphabet)
  }
  
  public func data() -> Data {
    return self.raw
  }
  
  public func address() -> Address? {
    switch self.network {
    case .bitcoin(let format) where format == .segwit || format == .segwitTestnet:
      guard self.raw.count == PublicKeyConstants.compressedKeySize else { return nil }
      let publicKey = self.raw
      let bech = Bech32(encoding: .bech32)
      let payload = publicKey.ripemd160()
      guard var words: [UInt8] = try? bech.toWords(data: payload) else { return nil }
      words.insert(0x00, at: 0)
      guard let address = try? bech.encode(prefix: self.network.addressPrefix, words: words) else { return nil }
      return Address(raw: address)
      
    case .litecoin:
      guard self.raw.count == PublicKeyConstants.compressedKeySize else {
        return nil
      }
      guard let alphabet = self.network.alphabet else {
        return nil
      }
      let prefix = Data([self.network.publicKeyHash])
      let publicKey = self.raw
      let payload = publicKey.sha256().ripemd160()
      let checksum = (prefix + payload).sha256().sha256().prefix(4)
      let data = prefix + payload + checksum
      guard let stringAddress: String = data.encodeBase58(alphabet: alphabet) else {
        return nil
      }
      return Address(raw: stringAddress)
    case .bitcoin(let format) where format == .legacy || format == .legacyTestnet:
      guard self.raw.count == PublicKeyConstants.compressedKeySize else {
        return nil
      }
      guard let alphabet = self.network.alphabet else {
        return nil
      }
      let prefix = Data([self.network.publicKeyHash])
      let publicKey = self.raw
      let payload = publicKey.ripemd160()
      let checksum = (prefix + payload).sha256().sha256().prefix(4)
      let data = prefix + payload + checksum
      guard let stringAddress: String = data.encodeBase58(alphabet: alphabet) else {
        return nil
      }
      return Address(raw: stringAddress)
    default:
      guard self.raw.count == PublicKeyConstants.decompressedKeySize else {
        return nil
      }
      let publicKey = self.raw
      let formattedData = (Data(hex: self.network.addressPrefix) + publicKey).dropFirst()
      let addressData = formattedData.sha3(.keccak256).suffix(20)
      guard let eip55 = addressData.eip55() else {
        return nil
      }
      return Address(address: eip55, prefix: self.network.addressPrefix)
    }
  }
}
