//
//  File.swift
//  
//
//  Created by Mikhail Nikanorov on 1/18/23.
//

import BigInt
import Foundation
import XCTest
@testable import mew_wallet_ios_kit

final class EIP712TransactionTests: XCTestCase {
  func testSignature() {
    let privateKey = PrivateKeyEth1(privateKey: Data(hex: "0x58d23b55bc9cdce1f18c2500f40ff4ab7245df9a89505e9b1fa4851f623d241d"), network: .ethereum)
    
    let transaction = ZKSync.EIP712Transaction(
      nonce: BigInt(0),
      maxPriorityFeePerGas: BigInt(100_000_000),
      maxFeePerGas: BigInt(100_000_000),
      gasLimit: BigInt(5_000_000),
      from: privateKey.address(),
      to: privateKey.address(),
      value: BigInt(1_000_000_000_000),
      data: Data(),
      chainID: BigInt(Network.zkSyncAlphaTestnet.chainID))
    
    do {
      try transaction.sign(key: privateKey)
    } catch {
      XCTFail(error.localizedDescription)
    }
    XCTAssertNil(transaction.signature)
    XCTAssertNotNil(transaction.meta.customSignature)
    XCTAssertEqual(transaction.meta.customSignature?.toHexString(), "8ab421f3cfacd51e08054c79db85525d082cff45484c0cc4031d85b95b81377c16e4b6666077d456cad752acd3c0ebf403938012746517262f8e97591de3a2591c")
    XCTAssertEqual(transaction.serialize()?.toHexString(), "71f890808405f5e1008405f5e100834c4b4094dc544d1aa88ff8bbd2f2aec754b1f1e99e1812fd85e8d4a5100080820118808082011894dc544d1aa88ff8bbd2f2aec754b1f1e99e1812fd820320c0b8418ab421f3cfacd51e08054c79db85525d082cff45484c0cc4031d85b95b81377c16e4b6666077d456cad752acd3c0ebf403938012746517262f8e97591de3a2591cc0")
  }
  
  func testPaymasterInput() {
    let paymaster = ZKSync.EIP712Transaction.Meta.Paymaster.paymaster(with: .init(raw: "0x0265d9a5af8af5fe070933e5e549d8fef08e09f4"), type: .general(innerInput: Data(hex: "0xaabbcc")))
    XCTAssertEqual(paymaster.paymaster, Address(raw: "0x0265d9a5af8af5fe070933e5e549d8fef08e09f4"))
    XCTAssertEqual(paymaster.input?.toHexString(), "8c5a34450000000000000000000000000000000000000000000000000000000000000020aabbcc")
    
    let paymasterAllowance = ZKSync.EIP712Transaction.Meta.Paymaster.paymaster(with: .init(raw: "0x0265d9a5af8af5fe070933e5e549d8fef08e09f4"),
                                                                               type: .approvalBased(token: .init(raw: "0xaabbccddeeff00112233445566778899aabbccdd"),
                                                                                                    minimalAllowance: BigInt(500),
                                                                                                    innerInput: Data(hex: "0xaabbcc")))
    XCTAssertEqual(paymasterAllowance.paymaster, Address(raw: "0x0265d9a5af8af5fe070933e5e549d8fef08e09f4"))
    XCTAssertEqual(paymasterAllowance.input?.toHexString(), "949431dc000000000000000000000000aabbccddeeff00112233445566778899aabbccdd00000000000000000000000000000000000000000000000000000000000001f40000000000000000000000000000000000000000000000000000000000000060aabbcc")
  }
  
  func test2() {
    let function = ABI.Element.Function(name: "general",
                                        inputs: [
                                          .init(name: "input", type: .dynamicBytes)
                                        ],
                                        outputs: [], constant: false, payable: false)
    let parameters: [AnyObject] = [
      Data(hex: "0xaabbcc") as AnyObject
    ]
    
    let data = ABI.Element.function(function).encodeParameters(parameters)
    debugPrint(data?.toHexString())
  }
  
  func testSignatureWithPaymaster() {
    let privateKey = PrivateKeyEth1(privateKey: Data(hex: "0x58d23b55bc9cdce1f18c2500f40ff4ab7245df9a89505e9b1fa4851f623d241d"), network: .ethereum)
    
    let transaction = ZKSync.EIP712Transaction(
      nonce: BigInt(0),
      maxPriorityFeePerGas: BigInt(100_000_000),
      maxFeePerGas: BigInt(100_000_000),
      gasLimit: BigInt(5_000_000),
      from: privateKey.address(),
      to: privateKey.address(),
      value: BigInt(1_000_000_000_000),
      data: Data(),
      chainID: BigInt(Network.zkSyncAlphaTestnet.chainID))
    
    do {
      transaction.meta.paymaster = ZKSync.EIP712Transaction.Meta.Paymaster.paymaster(with: .init(raw: "0x0265d9a5af8af5fe070933e5e549d8fef08e09f4"), type: .general(innerInput: Data(hex: "0xaabbcc")))
      try transaction.sign(key: privateKey)
    } catch {
      XCTFail(error.localizedDescription)
    }
    XCTAssertNil(transaction.signature)
    XCTAssertNotNil(transaction.meta.customSignature)
    XCTAssertEqual(transaction.meta.customSignature?.toHexString(), "b882c515ee8a55a2ff6b8b970cf7eb4fdcd38895ff621416555f1d51eafe23cd47c14d498a32b73a9a73cfae2c64d4476987ca9bfea4096f2fbcd558927fe0a01b")
    XCTAssertEqual(transaction.serialize()?.toHexString(), "71f8ce808405f5e1008405f5e100834c4b4094dc544d1aa88ff8bbd2f2aec754b1f1e99e1812fd85e8d4a5100080820118808082011894dc544d1aa88ff8bbd2f2aec754b1f1e99e1812fd820320c0b841b882c515ee8a55a2ff6b8b970cf7eb4fdcd38895ff621416555f1d51eafe23cd47c14d498a32b73a9a73cfae2c64d4476987ca9bfea4096f2fbcd558927fe0a01bf83d940265d9a5af8af5fe070933e5e549d8fef08e09f4a78c5a34450000000000000000000000000000000000000000000000000000000000000020aabbcc")
  }
}
