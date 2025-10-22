//
//  PrivateKey.swift
//  MEWwalletKit
//
//  Created by Mikhail Nikanorov on 12/04/20.
//  Copyright © 2020 MyEtherWallet Inc. All rights reserved.
//

import Foundation

public protocol IPrivateKey: IKey, BIP32 where BIPPK == Self {
  // swiftlint:disable:next type_name
  associatedtype PK
 
  init(seed: Data, network: Network) throws
  init(privateKey: Data, network: Network) throws
  init?(wif: String, network: Network) throws
  func publicKey(compressed: Bool?) throws -> PK
  func data() throws -> Data
  var hardenedEdge: Bool { get }
}
