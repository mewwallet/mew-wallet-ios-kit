//
//  Wallet.swift
//  MEWwalletKitTests
//
//  Created by Mikhail Nikanorov on 4/17/19.
//  Copyright © 2019 MyEtherWallet Inc. All rights reserved.
//

import Foundation

public final class Wallet<PK: IPrivateKey> {
  // MARK: - Static methods
  
  public static func generate(bitsOfEntropy: Int = 256, language: BIP39Wordlist = .english, network: Network = .ethereum) throws -> (BIP39, Wallet) {
    let bip39 = try BIP39(bitsOfEntropy: bitsOfEntropy, language: language)
    do {
      let seed = try bip39.seed()
      let wallet = try Wallet(seed: seed, network: network)
      return (bip39, wallet)
    } catch {
      throw WalletError.emptySeed
    }
  }
  
  public static func restore(mnemonic: [String], language: BIP39Wordlist = .english, network: Network = .ethereum) throws -> (BIP39, Wallet) {
    let bip39 = BIP39(mnemonic: mnemonic, language: language)
    let wallet = try self.restore(bip39: bip39, network: network)
    return (bip39, wallet)
  }
  
  public static func restore(bip39: BIP39, network: Network = .ethereum) throws -> Wallet {
    do {
      let seed = try bip39.seed()
      let wallet = try Wallet(seed: seed, network: network)
      return wallet
    } catch {
      throw WalletError.emptySeed
    }
  }
  
  // MARK: - Properties
  
  public let privateKey: PK
  
  // MARK: - Lifecycle
  
  public init(seed: Data, network: Network = .ethereum) throws {
    self.privateKey = try PK(seed: seed, network: network)
  }
  
  public init(privateKey: PK) {
    self.privateKey = privateKey
  }
  
  // MARK: - BIP44
  
  public func derive(_ path: String, index: UInt32? = nil) throws -> Wallet {
    var derivationPath = try path.derivationPath(checkHardenedEdge: self.privateKey.hardenedEdge)
    if let index = index {
      derivationPath.append(.nonHardened(index))
    }
    
    let derivedPrivateKey = try self.privateKey.derived(nodes: derivationPath, network: nil)
    return Wallet(privateKey: derivedPrivateKey)
  }
  
  public func derive(_ network: Network? = nil, index: UInt32? = nil) throws -> Wallet {
    let network = network ?? self.privateKey.network
    let path = network.path(index: index)
    let derivationPath = try path.derivationPath(checkHardenedEdge: self.privateKey.hardenedEdge)
    let derivedPrivateKey = try self.privateKey.derived(nodes: derivationPath, network: network)
    return Wallet(privateKey: derivedPrivateKey)
  }
}

extension Wallet: Equatable where PK: Equatable {
  public static func == (lhs: Wallet<PK>, rhs: Wallet<PK>) -> Bool {
    lhs.privateKey == rhs.privateKey
  }
}

extension Wallet: Sendable where PK: Sendable { }
