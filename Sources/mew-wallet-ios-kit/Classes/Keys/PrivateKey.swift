//
//  PrivateKeyEth1.swift
//  MEWwalletKitTests
//
//  Created by Mikhail Nikanorov on 4/17/19.
//  Copyright © 2019 MyEtherWallet Inc. All rights reserved.
//

import Foundation
import CryptoSwift
import mew_wallet_ios_secp256k1
import BigInt

private let HMACKeyData: [UInt8] = [0x42, 0x69, 0x74, 0x63, 0x6F, 0x69, 0x6E, 0x20, 0x73, 0x65, 0x65, 0x64] // "Bitcoin seed"

@available(*, deprecated, renamed: "PrivateKey", message: "Please use PrivateKey instead")
public typealias PrivateKeyEth1 = PrivateKey

public struct PrivateKey: Equatable, Sendable {
  private let raw: Data
  private let chainCode: Data
  private let depth: UInt8
  private let fingerprint: Data
  private let index: UInt32
  public let network: Network
  
  private init(privateKey: Data, chainCode: Data, depth: UInt8, fingerprint: Data, index: UInt32, network: Network) {
    self.raw = privateKey
    self.chainCode = chainCode
    self.depth = depth
    self.fingerprint = fingerprint
    self.index = index
    self.network = network
  }
}

// MARK: - IPrivateKey

extension PrivateKey: IPrivateKey {
  public var hardenedEdge: Bool {
    return true
  }
  
  public init(seed: Data, network: Network) throws {
    let output = try Data(HMAC(key: HMACKeyData, variant: .sha2(.sha512)).authenticate(seed.bytes))
    guard output.count == 64 else {
      throw PrivateKeyError.invalidData
    }
    self.raw = output[0 ..< 32]
    self.chainCode = output[32 ..< 64]
    self.depth = 0
    self.fingerprint = Data([0x00, 0x00, 0x00, 0x00])
    self.index = 0
    self.network = network
  }
  
  public init(privateKey: Data, network: Network = .none) {
    self.raw = privateKey
    self.chainCode = Data()
    self.depth = 0
    self.fingerprint = Data([0x00, 0x00, 0x00, 0x00])
    self.index = 0
    self.network = network
  }
  
  public init?(wif: String, network: Network) {
    guard let alphabet = network.alphabet else { return nil }
    guard var data = wif.decodeBase58(alphabet: alphabet) else { return nil }
    
    let checksum = Data(data.suffix(4))
    data = data.dropLast(4)
    let verify = data.sha256().sha256()
    if data.count == 34, data.last == 0x01 {
      data = data.dropLast(1)
    }

    guard Data(verify.prefix(4)) == checksum else { return nil }
    
    self.raw = data.dropFirst(1)
    self.chainCode = Data()
    self.depth = 0
    self.fingerprint = Data([0x00, 0x00, 0x00, 0x00])
    self.index = 0
    self.network = network
  }
  
  public func publicKey(compressed: Bool? = nil) throws -> PublicKey {
    let compressed = compressed ?? self.network.publicKeyCompressed
    let publicKey = try PublicKey(
        privateKey: self.raw,
        compressed: compressed,
        chainCode: self.chainCode,
        depth: self.depth,
        fingerprint: self.fingerprint,
        index: self.index,
        network: self.network
    )
    return publicKey
  }
}

// MARK: - Key

extension PrivateKey: IKey {
  public func string(compressedPublicKey: Bool) -> String? {
    guard let wifPrefix = self.network.wifPrefix,
          let alphabet = self.network.alphabet else {
      return self.raw.toHexString()
    }
    var data = Data()
    data += Data([wifPrefix])
    data += self.raw
    if compressedPublicKey {
      data += Data([0x01])
    }
    data += data.sha256().sha256().prefix(4)
    return data.encodeBase58(alphabet: alphabet)
  }
  
  public func extended() -> String? {
    guard let alphabet = self.network.alphabet else {
      return nil
    }
    var extendedKey = Data()
    extendedKey += Data(self.network.privateKeyPrefix.littleEndian.bytes)
    extendedKey += Data(self.depth.bigEndian.bytes)
    extendedKey += self.fingerprint
    extendedKey += Data(self.index.bigEndian.bytes)
    extendedKey += self.chainCode
    extendedKey += Data([0x00])
    extendedKey += self.raw
    let checksum = extendedKey.sha256().sha256().prefix(4)
    extendedKey += checksum
    return extendedKey.encodeBase58(alphabet: alphabet)
  }
  
  public func data() -> Data {
    return self.raw
  }
  
  public func address() -> Address? {
    return try? self.publicKey().address()
  }
}

// MARK: - BIP32

extension PrivateKey: BIP32 {
  public func derived(nodes: [DerivationNode], network: Network? = nil) throws -> Self {
    let network = network ?? self.network
    if case .none = network { return self }
    guard nodes.count > 0 else { return self }
    guard let node = nodes.first else { return self }
    
    let derivingIndex: UInt32
    let derivedPrivateKeyData: Data
    let derivedChainCode: Data
    
    let publicKeyData = try self.publicKey(compressed: true).data()
    
    var data = Data()
    if case .hardened = node {
      data += Data([0x00])
      data += self.raw
    } else {
      data += publicKeyData
    }
    
    derivingIndex = CFSwapInt32BigToHost(node.index())
    data += Data(derivingIndex.bigEndian.bytes)
    
    let digest = try Data(HMAC(key: self.chainCode.bytes, variant: .sha2(.sha512)).authenticate(data.bytes))
    
    let factor = BigInt(data: Data(digest[0 ..< 32].bytes))
    guard let curveOrder = BigInt("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141", radix: 16) else {
      throw PrivateKeyError.invalidData
    }

    let rawKey = BigInt(data: self.raw)
        
    // swiftlint:disable:next identifier_name
    let bn = rawKey + factor
    let calculatedKey = (bn % curveOrder)
    
    var derivedPrivateKeyDataCandidate = calculatedKey.data
    derivedPrivateKeyDataCandidate.setLength(32, appendFromLeft: true)
    derivedPrivateKeyData = derivedPrivateKeyDataCandidate
    derivedChainCode = Data(digest[32 ..< 64])
    
    let fingerprint = Data(publicKeyData.ripemd160().prefix(4))
    let derivedPrivateKey = Self(
        privateKey: derivedPrivateKeyData,
        chainCode: derivedChainCode,
        depth: self.depth + 1,
        fingerprint: fingerprint,
        index: derivingIndex,
        network: network
    )
    if nodes.count > 1 {
      return try derivedPrivateKey.derived(nodes: Array(nodes[1 ..< nodes.count]), network: network)
    }
    
    return derivedPrivateKey
  }
  
  public func derive(_ network: Network? = nil, index: UInt32? = nil) throws -> Wallet<Self> {
    let network = network ?? self.network
    let path = network.path(index: index)
    let derivationPath = try path.derivationPath(checkHardenedEdge: self.hardenedEdge)
    let derivedPrivateKey = try self.derived(nodes: derivationPath, network: network)
    return Wallet(privateKey: derivedPrivateKey)
  }
}
