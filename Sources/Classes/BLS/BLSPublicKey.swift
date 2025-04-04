//
//  PublicKeyEth1.swift
//  MEWwalletKitTests
//
//  Created by Mikhail Nikanorov on 12/4/20.
//  Copyright © 2020 MyEtherWallet Inc. All rights reserved.
//

#if os(iOS) || os(macOS)

import Foundation

@available(*, deprecated, renamed: "BLSPublicKey", message: "Please use BLSPublicKey instead")
public typealias PublicKeyEth2 = BLSPublicKey

public struct BLSPublicKey: IPublicKey {
  private let raw: Data
  private let index: UInt32
  public let network: Network

  init(publicKey: Data, compressed: Bool?, index: UInt32, network: Network) throws {
    self.raw = publicKey
    self.index = index
    self.network = network
  }
}

extension BLSPublicKey: IKey {
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
    return nil
  }
}

#endif
