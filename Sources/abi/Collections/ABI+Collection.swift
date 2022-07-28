//
//  ABI+Collection.swift
//  MEWwalletKit
//
//  Created by Mikhail Nikanorov on 9/13/21.
//  Copyright © 2021 MyEtherWallet Inc. All rights reserved.
//

import Foundation

private enum Static {
  static let functionNamePattern = #"(?<\#(ABIFunctionGroup.functionName)>[a-zA-Z_{1}][a-zA-Z0-9_]+)(?=\()[^(]*\((?<\#(ABIFunctionGroup.parameters)>[^)]*)\)"#
  static let wordGroupsBySpacing = #"([^\s]+)"#
}

internal extension NSRegularExpression {
  static var abiFunctionName: NSRegularExpression? {
    return try? NSRegularExpression(pattern: Static.functionNamePattern, options: .dotMatchesLineSeparators)
  }
  
  static var wordsSeparatedByWhitespaces: NSRegularExpression? {
    return try? NSRegularExpression(pattern: Static.wordGroupsBySpacing, options: .dotMatchesLineSeparators)
  }
}

protocol Contract {
  var methods: [ABI.ContractCollection.MethodName: Method] { get }
}

struct Method {
  let name: ABI.ContractCollection.MethodName
  let `in`: [ABI.Element.InOut]
  let out: [ABI.Element.InOut]
}

extension ABI {
  internal struct ContractCollection {
    internal enum MethodName: String {
      case transfer
    }
    internal enum InParameters: ABI.Element.InOutName {
      case to
      case value
    }
    internal enum OutParameters: ABI.Element.InOutName {
      case success
    }
    
    // MARK: - Static
    
    static var erc20: Contract { return ERC20() }
  }
  
  // MARK: - Private
  
  // MARK: - ERC-20
  
  private struct ERC20: Contract {
    var methods: [ABI.ContractCollection.MethodName : Method] {
      return [
        .transfer: .init(name: .transfer,
                         in: [
                          .init(name: ABI.ContractCollection.InParameters.to.rawValue, type: .address),
                          .init(name: ABI.ContractCollection.InParameters.value.rawValue, type: .uint(bits: 256))
                         ], out: [
                          .init(name: ABI.ContractCollection.OutParameters.success.rawValue, type: .bool)
                         ])
      ]
    }
  }
}

extension ABI.Element.Function {
  public static var erc20transfer: ABI.Element.Function {
    guard let erc20transfer = ABI.ContractCollection.erc20.methods[.transfer] else {
      fatalError("Missed method")
    }
    return .init(
        name: erc20transfer.name.rawValue,
        inputs: erc20transfer.in,
        outputs: erc20transfer.out,
        constant: false,
        payable: false
    )
  }
}

enum ABIFunctionGroup: String {
  case functionName
  case parameters
}

internal extension NSTextCheckingResult {
  private var functionNameRange: NSRange? { range(named: .functionName) }
  private var parametersRange: NSRange?   { range(named: .parameters) }
  
  func abiFunctionName(in string: String) -> String? { value(of: .functionName, in: string) }
  func abiFunctionParameters(in string: String) -> String? { value(of: .parameters, in: string) }
  
  // MARK: - Private
  
  private func range(named: ABIFunctionGroup) -> NSRange? {
    let range = range(withName: named.rawValue)
    guard range.location != NSNotFound, range.length > 0 else { return nil }
    return range
  }
  
  private func value(of rangeName: ABIFunctionGroup, in string: String) -> String? {
    guard
      let nsrange = range(named: rangeName),
      let range = Range(nsrange, in: string)
    else {
      return nil
    }
    return String(string[range])
  }
}

extension ABI.Element.Function {
  public static func parse(plainString: String) -> ABI.Element.Function? {
    guard
      let encoding = plainString.removingPercentEncoding,
      let regex = NSRegularExpression.abiFunctionName
    else {
      return nil
    }
    let matches = regex.matches(in: encoding, range: encoding.fullNSRange)
    
    guard
      matches.count == 1,
      let match = matches.first,
      let methodName = match.abiFunctionName(in: encoding),
      let parameters = match.abiFunctionParameters(in: encoding)
    else {
      return nil
    }
    
    return .init(
      name: methodName,
      inputs: parse(parameters: parameters),
      outputs: [
        .init(name: ABI.ContractCollection.OutParameters.success.rawValue, type: .bool)
      ],
      constant: false,
      payable: false
    )
  }
  
  private static func parse(parameters: String) -> [ABI.Element.InOut] {
    let cmps = parameters.components(separatedBy: ",")
    guard
      let matcher = NSRegularExpression.wordsSeparatedByWhitespaces,
      !cmps.isEmpty
    else {
      return []
    }
    
    var inOuts = [ABI.Element.InOut?]()
    
    for cmp in cmps {
      let matches = matcher.matches(in: cmp, range: cmp.fullNSRange)
      guard
        let typeMatch = matches.first,
        let nameMatch = matches.last,
        let typeRange = Range(typeMatch.range, in: cmp),
        let nameRange = Range(nameMatch.range, in: cmp)
      else {
        continue
      }
      
      let type = String(cmp[typeRange])
      let name = String(cmp[nameRange])
      let inOut = ABI.Element.InOut.init(name: name, type: type)
      inOuts.append(inOut)
    }
    return inOuts.compactMap {
      $0
    }
  }
}


