//
//  PublicKey.swift
//  MEWwalletKit
//
//  Created by Mikhail Nikanorov on 12/04/20.
//  Copyright © 2020 MyEtherWallet Inc. All rights reserved.
//

import Foundation

protocol IPublicKey: IKey {
  init(publicKey: Data, compressed: Bool?, index: UInt32, network: Network) throws
}
