//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 10/16/25.
//

import Foundation
import BigInt

public struct BitcoinQRCode: EIPQRCode & Equatable {
  
  // MARK: - Properties
  
  public var targetAddress: Address
  public var recipientAddress: Address?
  public var chainID: BigInt? { return nil }
  public var type: EIPQRCodeType { return .pay }
  public var functionName: String? { return nil }
  public var gasLimit: BigUInt? { return nil }
  public var value: BigUInt? { return nil }
  public var tokenValue: BigUInt? { return nil }
  public var function: ABI.Element.Function? { return nil }
  public var parameters: [EIPQRCodeParameter] = []
  public var data: Data? { return nil }
  public var equatable: EquatableEIPQRCode { .bitcoin(self) }
  
  public init(_ targetAddress: Address) {
    self.targetAddress = targetAddress
  }
  
  public init?(_ data: Data) {
    guard let val = BitcoinQRCodeParser.parse(data) else { return nil }
    self = val
  }
  
  public init?(_ string: String) {
    guard let val = BitcoinQRCodeParser.parse(string) else { return nil }
    self = val
  }
}

// MARK: - Parser

private struct BitcoinQRCodeParser {
  static func parse(_ data: Data) -> BitcoinQRCode? {
    guard let string = String(data: data, encoding: .utf8) else { return nil }
    return parse(string)
  }

  static func parse(_ string: String) -> BitcoinQRCode? {
    guard let encoding = string.removingPercentEncoding,
          let matcher: NSRegularExpression = .bitcoinQRCode else { return nil }
    
    let matches = matcher.matches(in: encoding, options: .anchored, range: encoding.fullNSRange)
    
    guard matches.count == 1,
          let match = matches.first else { return nil }
    
    guard let target = match.bitcoinQRCodeTarget(in: encoding),
          let targetAddress = Address(bitcoinAddress: target) else { return nil }
    
    return BitcoinQRCode(targetAddress)
  }
}
