//
//  SecretKeyEth2.swift
//  MEWwalletKitTests
//
//  Created by Mikhail Nikanorov on 12/4/20.
//  Copyright © 2020 MyEtherWallet Inc. All rights reserved.
//

import Foundation

#if os(iOS) || os(macOS)

import bls_framework

private let SECRET_KEY_LENGHT = 32

@available(*, deprecated, renamed: "BLSSecretKey", message: "Please use BLSSecretKey instead")
public typealias SecretKeyEth2 = BLSSecretKey

public struct BLSSecretKey {
  private let raw: Data
  private let index: UInt32
  public let network: Network
  
  public init(privateKey: Data, index: UInt32, network: Network) {
    self.raw = privateKey
    self.index = index
    self.network = network
  }
}

// MARK: - PrivateKey

extension BLSSecretKey: IPrivateKey {
  public var hardenedEdge: Bool {
    return false
  }
  
  public init(seed: Data, network: Network) throws {
    self.raw = try seed.deriveRootSK()
    self.index = 0
    self.network = network
  }
  
  public init(privateKey: Data, network: Network = .none) throws {
    guard privateKey.count == SECRET_KEY_LENGHT else {
      throw PrivateKeyError.invalidData
    }
    self.raw = privateKey
    self.index = 0
    self.network = network
  }
  
  public init?(wif: String, network: Network) throws {
    return nil
  }
  
  public func publicKey(compressed: Bool? = nil) -> BLSPublicKey? {
    let raw = self.raw
    guard let blsPublicKey = try? raw.blsPublicKey(),
          let data = try? blsPublicKey.serialized else {
      return nil
    }
    
    return try? BLSPublicKey(publicKey: data, compressed: compressed, index: self.index, network: self.network)
  }
}

// MARK: - Key

extension BLSSecretKey: IKey {
  public func string(compressedPublicKey: Bool) -> String? {
    return self.raw.toHexString()
  }
  
  public func extended() -> String? {
    return nil
  }
  
  public func data() -> Data {
    return self.raw
  }
  
  public func address() -> Address? {
    return self.publicKey()?.address()
  }
}

// MARK: - BIP32

extension BLSSecretKey: BIP32 {
  public func derived(nodes: [DerivationNode], network: Network?) throws -> BLSSecretKey {
    if case .none = self.network {
      return self
    }
    var nodes = nodes
    guard nodes.count > 0 else {
      return self
    }
    let node = nodes.removeFirst()
    
    let derivedSKRaw = try self.raw.deriveChildSK(index: node.index())
    let derivedSK = BLSSecretKey(privateKey: derivedSKRaw,
                                 index: node.index(),
                                 network: self.network)
    if nodes.count > 0 {
      return try derivedSK.derived(nodes: nodes, network: network ?? self.network)
    }
    return derivedSK
  }
}

#endif
