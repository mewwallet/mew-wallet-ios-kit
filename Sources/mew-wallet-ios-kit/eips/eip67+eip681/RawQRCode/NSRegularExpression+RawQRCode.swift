//
//  NSRegularExpression+RawQRCode.swift
//  MEWwalletKitTests
//
//  Created by Mikhail Nikanorov on 10/18/21.
//  Copyright © 2021 MyEtherWallet Inc. All rights reserved.
//

import Foundation

private enum Static {
  static let rawQRCode = #"^(?<\#(RawQRCodeGroups.target)>0x[0-9a-fA-F]{40}|[13][a-km-zA-HJ-NP-Z1-9]{25,34}|[bB][cC]1[pPqQ][a-zA-Z0-9]{38,58})$"#
}

internal extension NSRegularExpression {
  static var rawQRCode: NSRegularExpression? { return try? NSRegularExpression(pattern: Static.rawQRCode, options: .dotMatchesLineSeparators) }
}
