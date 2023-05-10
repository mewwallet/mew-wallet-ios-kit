//
//  EIP681.swift
//  MEWwalletKit
//
//  Created by Mikhail Nikanorov on 9/10/21.
//  Copyright © 2021 MyEtherWallet Inc. All rights reserved.
//

import Foundation
import BigInt

public struct EIP681Code: EIPQRCode & Equatable {

  // MARK: - Properties
  
  public var targetAddress: Address
  public var recipientAddress: Address?
  public var chainID: BigInt?
  public var type: EIPQRCodeType = .pay
  public var functionName: String?
  public var gasLimit: BigUInt?
  public var value: BigUInt?
  public var tokenValue: BigUInt?
  public var function: ABI.Element.Function?
  public var parameters: [EIPQRCodeParameter] = []
  public var data: Data? { return nil }
  public var equitable: EquatableEIPQRCode { .eip681(self) }
  
  public init(_ targetAddress: Address) {
    self.targetAddress = targetAddress
  }
  
  public init?(_ data: Data) {
    guard let val = EIP681CodeParser.parse(data) else { return nil }
    self = val
  }
  
  public init?(_ string: String) {
    guard let val = EIP681CodeParser.parse(string) else { return nil }
    self = val
  }
}

// MARK: - Parser

private struct EIP681CodeParser {
  static func parse(_ data: Data) -> EIP681Code? {
    guard let string = String(data: data, encoding: .utf8) else { return nil }
    return parse(string)
  }
  
  static func parse(_ string: String) -> EIP681Code? {
    guard let encoding = string.removingPercentEncoding,
          let matcher: NSRegularExpression = .eip681 else { return nil }
    
    let matches = matcher.matches(in: encoding, options: .anchored, range: encoding.fullNSRange)
    
    guard matches.count == 1,
          let match = matches.first else { return nil }
    
    guard let target = match.eip681Target(in: encoding),
          let targetAddress = Address(ethereumAddress: target) else { return nil }
    
    var code = EIP681Code(targetAddress)
    
    if let value = match.eip681Type(in: encoding) {
      guard let type = EIP681QRCodeType(rawValue: value.lowercased()) else {
        return nil
      }
      code.type = type
    }
    
    if let chainId = match.eip681ChainID(in: encoding) {
      code.chainID = BigInt(chainId)
    }
    
    code.functionName = match.eip681FunctionName(in: encoding)
    
    var inputs: [ABI.Element.InOut] = []
    
    guard var parameters = match.eip681Parameters(in: encoding) else {
      code.function = _buildFunction(code: code, inputs: inputs)
      return code
    }
    parameters = "?" + parameters
    guard let components = URLComponents(string: parameters) else {
      code.function = _buildFunction(code: code, inputs: inputs)
      return code
    }
    
    guard let queryItems = components.queryItems else {
      code.function = _buildFunction(code: code, inputs: inputs)
      return code
    }
    var inputNumber: Int = 0
    
    for comp in queryItems {
      if let inputType = try? ABITypeParser.parseTypeString(comp.name) {
        guard let value = comp.value else { continue }
        var nativeValue: AnyObject? = nil
        
        switch inputType {
        case .address:
          if let val = Address(ethereumAddress: value) {
            nativeValue = val as AnyObject
          }
          
        case .uint(bits: _):
          if value.isHexWithPrefix(), let val = BigUInt(value.stringRemoveHexPrefix(), radix: 16) {
            nativeValue = val as AnyObject
          } else if let val = BigUInt(scienceNotation: value) {
            nativeValue = val as AnyObject
          }
        case .int(bits: _):
          if value.isHexWithPrefix(), let val = BigInt(value.stringRemoveHexPrefix(), radix: 16) {
            nativeValue = val as AnyObject
          } else if let val = BigInt(scienceNotation: value) {
            nativeValue = val as AnyObject
          }
          
        case .string:
          nativeValue = value as AnyObject
          
        case .dynamicBytes:
          if value.isHex() {
            let val = Data(hex: value)
            nativeValue = val as AnyObject
          } else if let val = value.data(using: .utf8) {
            nativeValue = val as AnyObject
          }
          
        case .bytes(length: _):
          if value.isHex() {
            let val = Data(hex: value)
            nativeValue = val as AnyObject
          } else if let val = value.data(using: .utf8) {
            nativeValue = val as AnyObject
          }
          
        case .bool:
          switch value.lowercased() {
          case "true", "1":
            nativeValue = true as AnyObject
          case "false", "0":
            nativeValue = false as AnyObject
          default:
            nativeValue = true as AnyObject
          }
          
        case .function, .array, .tuple: // Not supported
          continue
        }
        guard let nativeValue = nativeValue else { return nil }
        
        inputs.append(.init(name: String(inputNumber), type: inputType))
        code.parameters.append(.init(type: inputType, value: nativeValue))
        inputNumber += 1
      } else {
        switch comp.name {
        case "value":
          guard let value = comp.value,
                let val = BigUInt(scienceNotation: value) else { return nil }
          code.value = val

        case "gas", "gasLimit":
          guard let value = comp.value,
                let val = BigUInt(scienceNotation: value) else { return nil }
          code.gasLimit = val
          
        case "gasPrice":
          break
        default:
          continue
        }
      }
    }
    
    code.function = _buildFunction(code: code, inputs: inputs)
    _checkForTransfer(code: &code)
    return code
  }
  
  private static func _buildFunction(code: EIP681Code, inputs: [ABI.Element.InOut]) -> ABI.Element.Function? {
    guard let functionName = code.functionName else { return nil }
    return ABI.Element.Function(name: functionName,
                                inputs: inputs,
                                outputs: [],
                                constant: false,
                                payable: code.value != nil)
  }
  
  private static func _checkForTransfer(code: inout EIP681Code) {
    if code.function?.name == ABI.Element.Function.erc20transfer.name {
      for parameter in code.parameters {
        switch (parameter.type, parameter.value) {
        case (.address, let address as Address):
          code.recipientAddress = address
        case (.uint(256), let amount as BigUInt):
          code.tokenValue = amount
        default:
          break
        }
      }
    }
  }
}
