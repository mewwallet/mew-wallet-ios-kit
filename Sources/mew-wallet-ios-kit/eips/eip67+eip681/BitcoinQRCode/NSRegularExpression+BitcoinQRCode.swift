//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 10/16/25.
//

import Foundation

enum BitcoinQRCodeGroups: String {
  case target
}

internal extension NSTextCheckingResult {
  private var targetRange: NSRange?       { range(named: .target) }
  
  func bitcoinQRCodeTarget(in string: String) -> String?      { value(of: .target, in: string) }
  
  // MARK: - Private
  
  private func range(named: BitcoinQRCodeGroups) -> NSRange? {
    let range = range(withName: named.rawValue)
    guard range.location != NSNotFound, range.length > 0 else { return nil }
    return range
  }
  
  private func value(of rangeName: BitcoinQRCodeGroups, in string: String) -> String? {
    guard let nsrange = range(named: rangeName),
          let range = Range(nsrange, in: string) else { return nil }
    return String(string[range])
  }
}
