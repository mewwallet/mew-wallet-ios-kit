//
//  Network.swift
//  MEWwalletKit
//
//  Created by Mikhail Nikanorov on 4/17/19.
//  Copyright © 2019 MyEtherWallet Inc. All rights reserved.
//

import Foundation

public enum NetworkPathProviderType: Equatable, Sendable {
  case prefix
  case suffix
}

open class NetworkPathProvider: Equatable, @unchecked Sendable {
  public static func == (lhs: NetworkPathProvider, rhs: NetworkPathProvider) -> Bool {
    return false
  }
  
  open func path(_ type: NetworkPathProviderType, _ index: UInt32?) -> String { return "" }
}

public enum Network: Equatable, Sendable {
  public enum Bitcoin: Equatable, Sendable {
    case legacy
    case legacyTestnet
    case segwit
    case segwitTestnet
  }
  public enum NetworkType: Equatable, Sendable {
    case evm
    case bitcoin
  }
  case bitcoin(_ format: Bitcoin)
  case litecoin
  case singularDTV
  case expanse
  case ledgerLiveEthereum
  case keepkeyEthereum
  case ledgerEthereum
  case ethereum
  case ledgerEthereumClassic
  case ledgerEthereumClassicVintage
  case ledgerLiveEthereumClassic
  case keepkeyEthereumClassic
  case ethereumClassic
  case mixBlockchain
  case ubiq
  case rskMainnet
  case ellaism
  case pirl
  case musicoin
  case callisto
  case tomoChain
  case thundercore
  case ethereumSocial
  case atheios
  case etherGem
  case eosClassic
  case goChain
  case etherSocialNetwork
  case rskTestnet
  case akroma
  case iolite
  case ether1
  case anonymizedId(_ Network: NetworkType)
  case kovan
  case goerli
  case eth2Withdrawal
  case zkSyncAlphaTestnet
  case zkSyncMainnet
  
  case none
  case custom(name: String, path: String, pathProvider: NetworkPathProvider?, chainID: UInt32)
  
  public init(path: String, pathProvider: NetworkPathProvider? = nil, chainID: UInt32 = 0) {
    switch path {
    case "m/0'/0'/0'":            self = .singularDTV
    case "m/44'/0'/0'/0":         self = .bitcoin(.legacy)
    case "m/84'/0'/0'/0":         self = .bitcoin(.segwit)
    case "m/44'/2'/0'/0":         self = .litecoin
    case "m/44'/40'/0'/0":        self = .expanse
    case "m/44'/60'":             self = .keepkeyEthereum
    case "m/44'/60'/0":           self = .ledgerEthereum
    case "m/44'/60'/0'/0":        self = .ethereum
    case "m/44'/60'/160720'/0":   self = .ledgerEthereumClassic
    case "m/44'/60'/160720'/0'":  self = .ledgerEthereumClassicVintage
    case "m/44'/61'":             self = .keepkeyEthereumClassic
    case "m/44'/61'/0'/0":        self = .ethereumClassic
    case "m/44'/76'/0'/0":        self = .mixBlockchain
    case "m/44'/108'/0'/0":       self = .ubiq
    case "m/44'/137'/0'/0":       self = .rskMainnet
    case "m/44'/163'/0'/0":       self = .ellaism
    case "m/44'/164'/0'/0":       self = .pirl
    case "m/44'/184'/0'/0":       self = .musicoin
    case "m/44'/820'/0'/0":       self = .callisto
    case "m/44'/889'/0'/0":       self = .tomoChain
    case "m/44'/1001'/0'/0":      self = .thundercore
    case "m/44'/1128'/0'/0":      self = .ethereumSocial
    case "m/44'/1620'/0'/0":      self = .atheios
    case "m/44'/1987'/0'/0":      self = .etherGem
    case "m/44'/2018'/0'/0":      self = .eosClassic
    case "m/44'/6060'/0'/0":      self = .goChain
    case "m/44'/31102'/0'/0":     self = .etherSocialNetwork
    case "m/44'/37310'/0'/0":     self = .rskTestnet
    case "m/44'/200625'/0'/0":    self = .akroma
    case "m/44'/1171337'/0'/0":   self = .iolite
    case "m/44'/1313114'/0'/0":   self = .ether1
    case "m/1000'/60'/0'/0":      self = .anonymizedId(.evm)
    case "m/1040'/60'/0'/0":      self = .anonymizedId(.bitcoin)
    case "m/44'/42'/0'/0":        self = .kovan
    case "m/44'/5'/0'/0":         self = .goerli
    case "m/12381/3600":          self = .eth2Withdrawal
    case "":                      self = .none
    default:                      self = .custom(name: path, path: path, pathProvider: pathProvider, chainID: chainID)
    }
  }
  
  public var name: String {
    switch self {
    case .bitcoin(.legacy):                                     return "Bitcoin"
    case .bitcoin(.segwit):                                     return "Bitcoin SegWit"
    case .bitcoin(.legacyTestnet):                              return "Bitcoin testnet"
    case .bitcoin(.segwitTestnet):                              return "Bitcoin SegWit testnet"
    case .litecoin:                                                           return "Litecoin"
    case .singularDTV:                                                        return "SingularDTV"
    case .expanse:                                                            return "Expanse"
    case .ledgerLiveEthereum:                                                 return "Ethereum - Ledger Live"
    case .ethereum, .ledgerEthereum, .keepkeyEthereum:                        return "Ethereum"
    case .ledgerEthereumClassicVintage:                                       return "Ethereum Classic MEW Vintage"
    case .ledgerLiveEthereumClassic:                                          return "Ethereum Classic - Ledger Live"
    case .ethereumClassic, .ledgerEthereumClassic, .keepkeyEthereumClassic:   return "Ethereum Classic"
    case .mixBlockchain:                                                      return "Mix Blockchain"
    case .ubiq:                                                               return "Ubiq"
    case .rskMainnet:                                                         return "RSK Mainnet"
    case .ellaism:                                                            return "Ellaism"
    case .pirl:                                                               return "PIRL"
    case .musicoin:                                                           return "Musicoin"
    case .callisto:                                                           return "Callisto"
    case .tomoChain:                                                          return "TomoChain"
    case .thundercore:                                                        return "ThunderCore"
    case .ethereumSocial:                                                     return "Ethereum Social"
    case .atheios:                                                            return "Atheios"
    case .etherGem:                                                           return "EtherGem"
    case .eosClassic:                                                         return "EOS Classic"
    case .goChain:                                                            return "GoChain"
    case .etherSocialNetwork:                                                 return "EtherSocial Network"
    case .rskTestnet:                                                         return "RSK Testnet"
    case .akroma:                                                             return "Akroma"
    case .iolite:                                                             return "Iolite"
    case .ether1:                                                             return "Ether-1"
    case .anonymizedId:                                                       return "AnonymizedId"
    case .kovan:                                                              return "Kovan"
    case .goerli:                                                             return "Goerli"
    case .eth2Withdrawal:                                                     return "Eth 2.0"
    case .zkSyncAlphaTestnet:                                                 return "zkSync alpha testnet"
    case .zkSyncMainnet:                                                      return "zkSync"
    case .none:                                                               return ""
    case let .custom(name, _, _, _):                                          return name
    }
  }
  
  public func path(index: UInt32?) -> String {
    switch self {
    case let .custom(_, path, pathProvider, _):
      if let pathProvider = pathProvider {
        return pathProvider.path(.prefix, index) + pathProvider.path(.suffix, nil)
      } else if let index = index {
        return path.appending("/\(index)")
      } else {
        return path
      }
    case .eth2Withdrawal:
      if let index = index {
        return self.path.appending("/\(index)/0")
      } else {
        return self.path
      }
    default:
      if let index = index {
        return self.path.appending("/\(index)")
      } else {
        return self.path
      }
    }
  }
  
  public func pathPrefix() -> String {
    switch self {
    case let .custom(_, path, pathProvider, _):
      if let pathProvider = pathProvider {
        return pathProvider.path(.prefix, nil)
      } else {
        return path
      }
    default:
      return self.path
    }
  }
  
  public func pathSuffix() -> String {
    switch self {
    case let .custom(_, _, pathProvider, _):
      if let pathProvider = pathProvider {
        return pathProvider.path(.suffix, nil)
      } else {
        return ""
      }
    case .eth2Withdrawal:
      return "/0"
    default:
      return ""
    }
  }
  
  public var path: String {
    switch self {
    case .singularDTV:                                          return "m/0'/0'/0'"
    case .bitcoin(.legacy):                                     return "m/44'/0'/0'/0"
    case .bitcoin(.segwit):                                     return "m/84'/0'/0'/0"
    case .bitcoin(.legacyTestnet):                              return "m/44'/1'/0'/0"
    case .bitcoin(.segwitTestnet):                              return "m/84'/0'/0'/0"
    case .litecoin:                                             return "m/44'/2'/0'/0"
    case .expanse:                                              return "m/44'/40'/0'/0"
    case .ledgerLiveEthereum, .keepkeyEthereum:                 return "m/44'/60'"
    case .ledgerEthereum:                                       return "m/44'/60'/0"
    case .ethereum, .zkSyncMainnet, .zkSyncAlphaTestnet:        return "m/44'/60'/0'/0"
    case .ledgerEthereumClassic:                                return "m/44'/60'/160720'/0"
    case .ledgerEthereumClassicVintage:                         return "m/44'/60'/160720'/0'"
    case .ledgerLiveEthereumClassic, .keepkeyEthereumClassic:   return "m/44'/61'"
    case .ethereumClassic:                                      return "m/44'/61'/0'/0"
    case .mixBlockchain:                                        return "m/44'/76'/0'/0"
    case .ubiq:                                                 return "m/44'/108'/0'/0"
    case .rskMainnet:                                           return "m/44'/137'/0'/0"
    case .ellaism:                                              return "m/44'/163'/0'/0"
    case .pirl:                                                 return "m/44'/164'/0'/0"
    case .musicoin:                                             return "m/44'/184'/0'/0"
    case .callisto:                                             return "m/44'/820'/0'/0"
    case .tomoChain:                                            return "m/44'/889'/0'/0"
    case .thundercore:                                          return "m/44'/1001'/0'/0"
    case .ethereumSocial:                                       return "m/44'/1128'/0'/0"
    case .atheios:                                              return "m/44'/1620'/0'/0"
    case .etherGem:                                             return "m/44'/1987'/0'/0"
    case .eosClassic:                                           return "m/44'/2018'/0'/0"
    case .goChain:                                              return "m/44'/6060'/0'/0"
    case .etherSocialNetwork:                                   return "m/44'/31102'/0'/0"
    case .rskTestnet:                                           return "m/44'/37310'/0'/0"
    case .akroma:                                               return "m/44'/200625'/0'/0"
    case .iolite:                                               return "m/44'/1171337'/0'/0"
    case .ether1:                                               return "m/44'/1313114'/0'/0"
    case .anonymizedId(let network):
      switch network {
      case .evm:                                                return "m/1000'/60'/0'/0"
      case .bitcoin:                                            return "m/1040'/60'/0'/0"
      }
    case .kovan:                                                return "m/44'/42'/0'/0"
    case .goerli:                                               return "m/44'/5'/0'/0"
    case .eth2Withdrawal:                                       return "m/12381/3600"
    case .none:                                                 return ""
    case let .custom(_, path, _, _):                            return path
    }
  }
  
  public var chainID: UInt32 {
    switch self {
    case .singularDTV:                                          return 0
    case .bitcoin:                                              return 0
    case .litecoin:                                             return 2
    case .expanse:                                              return 2
    case .ledgerLiveEthereum, .keepkeyEthereum:                 return 1
    case .ledgerEthereum:                                       return 1
    case .ethereum:                                             return 1
    case .ledgerEthereumClassic:                                return 1
    case .ledgerEthereumClassicVintage:                         return 1
    case .ledgerLiveEthereumClassic, .keepkeyEthereumClassic:   return 44
    case .ethereumClassic:                                      return 61
    case .mixBlockchain:                                        return 76
    case .ubiq:                                                 return 8
    case .rskMainnet:                                           return 30
    case .ellaism:                                              return 64
    case .pirl:                                                 return 3125659152
    case .musicoin:                                             return 7762959
    case .callisto:                                             return 820
    case .tomoChain:                                            return 88
    case .thundercore:                                          return 108
    case .ethereumSocial:                                       return 1128
    case .atheios:                                              return 1620
    case .etherGem:                                             return 1987
    case .eosClassic:                                           return 2018
    case .goChain:                                              return 60
    case .etherSocialNetwork:                                   return 31102
    case .rskTestnet:                                           return 31
    case .akroma:                                               return 200625
    case .iolite:                                               return 18289463
    case .ether1:                                               return 1313114
    case .anonymizedId:                                         return 1
    case .kovan:                                                return 42
    case .goerli:                                               return 5
    case .eth2Withdrawal:                                       return 3660
    case .zkSyncAlphaTestnet:                                   return 280
    case .zkSyncMainnet:                                        return 324
    case .none:                                                 return 0
    case let .custom(_, _, _, chainID):                         return chainID
    }
  }
  
  var wifPrefix: UInt8? {
    switch self {
    case .bitcoin(.legacy):         return 0x80
    case .bitcoin(.segwit):         return 0x80
    case .bitcoin(.legacyTestnet):  return 0xEF
    case .bitcoin(.segwitTestnet):  return 0xEF
    case .litecoin:                 return 0xB0
    default:                        return nil
    }
  }
  
  var publicKeyHash: UInt8 {
    switch self {
    case .bitcoin(.legacy):         return 0x00
    case .bitcoin(.segwit):         return 0x00
    case .bitcoin(.legacyTestnet):  return 0x6F
    case .bitcoin(.segwitTestnet):  return 0x6F
    case .litecoin:                 return 0x30
    default:                        return 0x00
    }
  }
  
  var addressPrefix: String {
    switch self {
    case .bitcoin(let format):
      switch format {
        case .legacy:                                         return ""
        case .legacyTestnet:                                  return ""
        case .segwit:                                         return "bc"
        case .segwitTestnet:                                  return "tb"
      }
    case .ethereum, .anonymizedId, .kovan, .goerli,
        .zkSyncAlphaTestnet, .zkSyncMainnet:                  return "0x"
    case .none:                                               return ""
    default:                                                  return "0x"
    }
  }
  
  var alphabet: String? {
    switch self {
    case .bitcoin:          return "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    default:                return nil
    }
  }
  
  var privateKeyPrefix: UInt32 {
    switch self {
    case .bitcoin(.legacy):         return 0x0488ADE4
    case .bitcoin(.segwit):         return 0x04B2430C
    case .bitcoin(.legacyTestnet):  return 0x04358394
    case .bitcoin(.segwitTestnet):  return 0x04B2430C
    default:                return 0
    }
  }
  
  var publicKeyPrefix: UInt32 {
    switch self {
    case .bitcoin(.legacy):         return 0x0488b21E
    case .bitcoin(.segwit):         return 0x04B24746
    case .bitcoin(.legacyTestnet):  return 0x043587CF
    case .bitcoin(.segwitTestnet):  return 0x04B24746
    default:                return 0
    }
  }
  
  var publicKeyCompressed: Bool {
    switch self {
    case .bitcoin, .litecoin:                                 return true
    case .ethereum, .anonymizedId, .kovan, .goerli,
        .zkSyncMainnet, .zkSyncAlphaTestnet:                  return false
    default:                                                  return false
    }
  }
  
  public var symbol: String {
    switch self {
    case .bitcoin:  return "btc"
    case .ethereum: return "eth"
    case .kovan:    return "kov"
    case .goerli:   return "goe"
    default:        return ""
    }
  }
}
