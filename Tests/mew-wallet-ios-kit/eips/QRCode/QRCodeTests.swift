//
//  RawQRCodeTests.swift
//  MEWwalletKitTests
//
//  Created by Mikhail Nikanorov on 10/18/21.
//  Copyright © 2021 MyEtherWallet Inc. All rights reserved.
//

import Foundation
import Testing
import BigInt
@testable import mew_wallet_ios_kit

fileprivate struct TestVector: @unchecked Sendable {
  let raw: String
  let chainID: BigInt?
  let targetAddress: Address?
  let recipientAddress: Address?
  let value: BigUInt?
  let tokenValue: BigUInt?
  let gasLimit: BigUInt?
  let data: Data?
  let functionName: String?
  let function: ABI.Element.Function?
  let parameters: [EIPQRCodeParameter]
  
  init(raw: String) {
    self.raw = raw
    self.chainID = nil
    self.targetAddress = nil
    self.recipientAddress = nil
    self.value = nil
    self.tokenValue = nil
    self.gasLimit = nil
    self.data = nil
    self.functionName = nil
    self.function = nil
    self.parameters = []
  }
  
  init(raw: String,
       chainID: BigInt?,
       targetAddress: Address?,
       recipientAddress: Address?,
       value: BigUInt?,
       tokenValue: BigUInt?,
       gasLimit: BigUInt?,
       data: Data?,
       functionName: String?,
       function: ABI.Element.Function?,
       parameters: [EIPQRCodeParameter]) {
    self.raw = raw
    self.chainID = chainID
    self.targetAddress = targetAddress
    self.recipientAddress = recipientAddress
    self.value = value
    self.tokenValue = tokenValue
    self.gasLimit = gasLimit
    self.data = data
    self.functionName = functionName
    self.function = function
    self.parameters = parameters
  }
  
  fileprivate static let validRaw: [TestVector] = [
    .init(raw: "0xcccc00000000000000000000000000000000cccc", chainID: nil, targetAddress: Address(raw: "0xcccc00000000000000000000000000000000cccc"), recipientAddress: nil, value: nil, tokenValue: nil, gasLimit: nil, data: nil, functionName: nil, function: nil, parameters: []),
  ]
  fileprivate static let validBTC: [TestVector] = [
    .init(raw: "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4", chainID: nil, targetAddress: Address(raw: "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"), recipientAddress: nil, value: nil, tokenValue: nil, gasLimit: nil, data: nil, functionName: nil, function: nil, parameters: [])
  ]
  fileprivate static let validSOL: [TestVector] = [
    .init(raw: "2ipZdgc1uLgFWd8UznBA9V2urrgHf41FoqdW8v3hCCeb", chainID: nil, targetAddress: Address(raw: "2ipZdgc1uLgFWd8UznBA9V2urrgHf41FoqdW8v3hCCeb"), recipientAddress: nil, value: nil, tokenValue: nil, gasLimit: nil, data: nil, functionName: nil, function: nil, parameters: []),
  ]

  fileprivate static let invalid: [TestVector] = [
    .init(raw: "cccc00000000000000000000000000000000cccc"),
    .init(raw: "0xeeee00000000000000000000000000000000eee"),
    .init(raw: "0xcccc00000000000000000000000000000000cccQ"),
    .init(raw: "0xdeadbeef")
  ]
}

@Suite("QRCode Tests")
fileprivate struct RawQRCodeTests {
  @Test("Test raw valid cases", arguments: TestVector.validRaw)
  func validRaw(vector: TestVector) async throws {
    let code = try #require(RawQRCode(vector.raw))
    
    #expect(code.chainID == vector.chainID)
    #expect(code.targetAddress == vector.targetAddress)
    #expect(code.recipientAddress == vector.recipientAddress)
    #expect(code.value == vector.value)
    #expect(code.tokenValue == vector.tokenValue)
    #expect(code.gasLimit == vector.gasLimit)
    #expect(code.data == vector.data)
    #expect(code.functionName == vector.functionName)
    #expect(code.function == vector.function)
    #expect(code.parameters == vector.parameters)
  }
  
  @Test("Test BTC valid cases", arguments: TestVector.validBTC)
  func validBTC(vector: TestVector) async throws {
    let code = try #require(BitcoinQRCode(vector.raw))
    
    #expect(code.chainID == vector.chainID)
    #expect(code.targetAddress == vector.targetAddress)
    #expect(code.recipientAddress == vector.recipientAddress)
    #expect(code.value == vector.value)
    #expect(code.tokenValue == vector.tokenValue)
    #expect(code.gasLimit == vector.gasLimit)
    #expect(code.data == vector.data)
    #expect(code.functionName == vector.functionName)
    #expect(code.function == vector.function)
    #expect(code.parameters == vector.parameters)
  }
  
  @Test("Test SOL valid cases", arguments: TestVector.validSOL)
  func validSOL(vector: TestVector) async throws {
    let code = try #require(SolanaQRCode(vector.raw))
    
    #expect(code.chainID == vector.chainID)
    #expect(code.targetAddress == vector.targetAddress)
    #expect(code.recipientAddress == vector.recipientAddress)
    #expect(code.value == vector.value)
    #expect(code.tokenValue == vector.tokenValue)
    #expect(code.gasLimit == vector.gasLimit)
    #expect(code.data == vector.data)
    #expect(code.functionName == vector.functionName)
    #expect(code.function == vector.function)
    #expect(code.parameters == vector.parameters)
  }
  
  @Test("Test invalid invalid cases", arguments: TestVector.invalid)
  func invalid(vector: TestVector) async throws {
    let code = RawQRCode(vector.raw)
    #expect(code == nil)
  }
}
