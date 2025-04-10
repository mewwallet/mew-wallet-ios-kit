//
//  EIPQRCode.swift
//  MEWwalletKit
//
//  Created by Mikhail Nikanorov on 9/13/21.
//  Copyright © 2021 MyEtherWallet Inc. All rights reserved.
//

import Foundation
import BigInt

public protocol EIPQRCode {
  var chainID: BigInt? { get }
  var targetAddress: Address { get }
  var recipientAddress: Address? { get }
  var value: BigUInt? { get }
  var tokenValue: BigUInt? { get }
  var gasLimit: BigUInt? { get }
  var data: Data? { get }
  var functionName: String? { get }
  var function: ABI.Element.Function? { get }
  var parameters: [EIPQRCodeParameter] { get }
  var equitable: EquatableEIPQRCode { get }
}

extension EIPQRCode where Self: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.equitable == rhs.equitable
  }
}

public enum EquatableEIPQRCode {
  case eip681(EIP681Code)
  case eip67(EIP67Code)
  case raw(RawQRCode)
  
  public var qr: EIPQRCode {
    switch self {
    case .eip681(let eip681Code):   return eip681Code
    case .eip67(let eip67Code):     return eip67Code
    case .raw(let rawQRCode):       return rawQRCode
    }
  }
  
  public init?(string: String) {
    if let eip681 = EIP681Code(string) {
      self = .eip681(eip681)
      return
    } else if let eip67 = EIP67Code(string) {
      self = .eip67(eip67)
      return
    } else if let raw = RawQRCode(string) {
      self = .raw(raw)
      return
    }
    return nil
  }
}

extension EquatableEIPQRCode: Equatable {
  public static func == (lhs: EquatableEIPQRCode, rhs: EquatableEIPQRCode) -> Bool {
    switch (lhs, rhs) {
    case (.eip681(let lhs), .eip681(let rhs)):
      return lhs == rhs
    case (.eip67(let lhs), .eip67(let rhs)):
      return lhs == rhs
    case (.raw(let lhs), .raw(let rhs)):
      return lhs == rhs
    default:
      return false
    }
  }
}
