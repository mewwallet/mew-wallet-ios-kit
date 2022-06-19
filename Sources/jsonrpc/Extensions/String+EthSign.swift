//
//  String+EthSign.swift
//  MEWwalletKitTests
//
//  Created by Mikhail Nikanorov on 7/24/19.
//  Copyright © 2019 MyEtherWallet Inc. All rights reserved.
//

import Foundation

public extension String {
  func hashPersonalMessage() -> Data? {
    guard let personalMessage = self.data(using: .utf8) else {
      return nil
    }
    return personalMessage.hashPersonalMessage()
  }
  
  func signPersonalMessage(key: PrivateKeyEth1, leadingV: Bool) -> Data? {
    return self.hashPersonalMessage()?.unsafeSign(key: key.data(), leadingV: leadingV)
  }
  
  @available(swift, obsoleted: 1.0, renamed: "signPersonalMessage(key:leadingV:)")
  func hashPersonalMessageAndSign(key: PrivateKeyEth1, leadingV: Bool) -> Data? {
    return self.hashPersonalMessage()?.unsafeSign(key: key.data(), leadingV: leadingV)
  }
  
  @available(swift, obsoleted: 1.0, renamed: "signPersonalMessage(key:leadingV:)")
  func sign(key: PrivateKeyEth1, leadingV: Bool) -> Data? {
    guard let personalMessage = self.data(using: .utf8) else {
      return nil
    }
    return personalMessage.unsafeSign(key: key.data(), leadingV: leadingV)
  }
}
