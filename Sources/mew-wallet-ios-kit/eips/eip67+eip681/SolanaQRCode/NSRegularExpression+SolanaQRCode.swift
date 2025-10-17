//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 10/16/25.
//

import Foundation

private enum Static {
  static let solanaQRCode = #"^(?:solana:)?(?<\#(SolanaQRCodeGroups.target)>[a-km-zA-HJ-NP-Z1-9]{32,44})$"#
}

internal extension NSRegularExpression {
  static var solanaQRCode: NSRegularExpression? { return try? NSRegularExpression(pattern: Static.solanaQRCode, options: .dotMatchesLineSeparators) }
}
