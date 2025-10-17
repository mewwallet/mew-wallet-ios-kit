//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 10/16/25.
//

import Foundation

private enum Static {
  static let bitcoinQRCode = #"^(?:bitcoin:)?(?<\#(RawQRCodeGroups.target)>[13][a-km-zA-HJ-NP-Z1-9]{25,34}|bc1[a-zA-HJ-NP-Z0-9]{11,71})$"#
}

internal extension NSRegularExpression {
  static var bitcoinQRCode: NSRegularExpression? { return try? NSRegularExpression(pattern: Static.bitcoinQRCode, options: .dotMatchesLineSeparators) }
}
