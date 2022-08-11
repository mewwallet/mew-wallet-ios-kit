//
//  ABI+Collection.swift
//  MEWwalletKit
//
//  Created by Mikhail Nikanorov on 9/13/21.
//  Copyright © 2021 MyEtherWallet Inc. All rights reserved.
//

import Foundation

private enum Static {
  static let functionNamePattern = #"function[ ]+(?<\#(ABIFunctionGroup.functionName)>[a-zA-Z_{1}][a-zA-Z0-9_]*)[ ]*[(]{1}(?<\#(ABIFunctionGroup.parameters)>[^)]*)[)]{1}[^(]*[(]{1}(?<\#(ABIFunctionGroup.returnType)>[^)]*)"#
  static let structNamePattern = #"struct[ ]+(?<\#(ABIStructGroup.structName)>[a-zA-Z_{1}][a-zA-Z0-9_]*)[ ]*[{]{1}(?<\#(ABIStructGroup.properties)>[^}]*)"#
  static let wordGroupsBySpacing = #"([^\s]+)"#
}

internal extension NSRegularExpression {
  static var abiFunctionName: NSRegularExpression? {
    return try? NSRegularExpression(pattern: Static.functionNamePattern, options: .dotMatchesLineSeparators)
  }
  
  static var wordsSeparatedByWhitespaces: NSRegularExpression? {
    return try? NSRegularExpression(pattern: Static.wordGroupsBySpacing, options: .dotMatchesLineSeparators)
  }
  
  static var abiStructName: NSRegularExpression? {
    return try? NSRegularExpression(pattern: Static.structNamePattern, options: .dotMatchesLineSeparators)
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
                          .init(name: "", type: .bool)
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
  case returnType
}

enum ABIStructGroup: String {
  case structName
  case properties
}

struct ABITuple {
  let name: String
  let properties: [(name: String, type: String)]
}

internal extension NSTextCheckingResult {
  //function
  private var functionNameRange: NSRange? { range(named: ABIFunctionGroup.functionName) }
  private var parametersRange: NSRange?   { range(named: ABIFunctionGroup.parameters) }
  private var returnTypeRange: NSRange?   { range(named: ABIFunctionGroup.returnType) }
  
  func abiFunctionName(in string: String) -> String? { value(of: ABIFunctionGroup.functionName, in: string) }
  func abiFunctionParameters(in string: String) -> String? { value(of: ABIFunctionGroup.parameters, in: string) }
  func abiFunctionReturnType(in string: String) -> String? { value(of: ABIFunctionGroup.returnType, in: string) }

  // struct
  private var structNameRange: NSRange? { range(named: ABIStructGroup.structName) }
  private var structProperties: NSRange? { range(named: ABIStructGroup.properties) }

  func abiStructName(in string: String) -> String? { value(of: ABIStructGroup.structName, in: string) }
  func abiStructProperties(in string: String) -> String? { value(of: ABIStructGroup.properties, in: string) }

  // MARK: - Private
  
  private func range<T: RawRepresentable>(named: T) -> NSRange? where T.RawValue == String {
    let range = range(withName: named.rawValue)
    guard range.location != NSNotFound, range.length > 0 else { return nil }
    return range
  }
  
  private func value<T: RawRepresentable>(of rangeName: T, in string: String) -> String? where T.RawValue == String {
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
  public static func parse(plainString: String, structs: [String] = []) -> ABI.Element.Function? {
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
      let methodName = match.abiFunctionName(in: encoding)
    else {
      return nil
    }
    
    let tuples = parse(structs: structs)
    
    let parameters = match.abiFunctionParameters(in: encoding).flatMap {
      parse(parameters:$0, tuples: tuples)
    }
    let returnType = match.abiFunctionReturnType(in: encoding).flatMap {
      parse(returnType: $0, tuples: tuples)
    }
    
    return .init(
      name: methodName,
      inputs: parameters ?? [],
      outputs: returnType ?? [],
      constant: false,
      payable: false
    )
  }
  
  private static func parse(parameters: String, tuples: [String: ABITuple]) -> [ABI.Element.InOut] {
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
      let inOut = parse(propertyType: type, tuples: tuples).flatMap {
        ABI.Element.InOut(name: name, type: $0)
      }
      inOuts.append(inOut)
    }
    return inOuts.compactMap {
      $0
    }
  }
  
  
  
  private static func parse(structs: [String]) -> [String: ABITuple] {
    var result = [String: ABITuple]()
    
    for element in structs {
      guard let tuple = parse(struct: element) else {
        continue
      }
      result[tuple.name] = tuple
    }
    
    return result
  }
  
  private static func parse(`struct`: String) -> ABITuple? {
    guard
      let matcher = NSRegularExpression.abiStructName
    else {
      return nil
    }

    let matches = matcher.matches(in: `struct`, range: `struct`.fullNSRange)
    
    guard
      matches.count == 1,
      let match = matches.first,
      let structName = match.abiStructName(in: `struct`),
      let properties = match.abiStructProperties(in: `struct`)
    else {
      return nil
    }
    
    let cmps = properties.components(separatedBy: ";")
    
    guard
      let matcher = NSRegularExpression.wordsSeparatedByWhitespaces,
      !cmps.isEmpty
    else {
      return nil
    }
    
    var tupleProperties = [(name: String, type: String)]()
    
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
      
      tupleProperties.append((name, type))
    }
    
    return .init(name: structName, properties: tupleProperties)
  }
  
  private static func parse(returnType: String, tuples: [String: ABITuple]) -> [ABI.Element.InOut] {
    return [
      parse(propertyType: returnType, tuples: tuples).flatMap {
        .init(name: "", type: $0)
      }
    ].compactMap {
      $0
    }
  }
  
  private static func parse(propertyType: String, tuples: [String: ABITuple]) -> ABI.Element.ParameterType? {
    guard let tuple = tuples[propertyType] else {
      return ABI.Element.ParameterType(from: propertyType)
    }
    
    var types = [ABI.Element.ParameterType]()
    for property in tuple.properties {
      guard let parameterType = parse(propertyType: property.type, tuples: tuples) else {
        continue
      }
      types.append(parameterType)
    }
    return .tuple(types: types)
  }
}


