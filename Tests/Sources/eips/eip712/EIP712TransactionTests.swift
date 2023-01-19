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
      maxPriorityFeePerErg: BigInt(100_000_000),
      maxFeePerErg: BigInt(100_000_000),
      ergsLimit: BigInt(5_000_000),
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
    XCTAssertEqual(transaction.meta.customSignature?.toHexString(), "54761417b8b9ad2395901586b60139bd0cfcc2f99b182fee75a65551c9d7063c56d0369dd68c3150a87d31cdae42b9b00e18ac99e0c85318296e64b4a3cd3fbc1b")
    XCTAssertEqual(transaction.serialize()?.toHexString(), "71f891808405f5e1008405f5e100834c4b4094dc544d1aa88ff8bbd2f2aec754b1f1e99e1812fd85e8d4a5100080820118808082011894dc544d1aa88ff8bbd2f2aec754b1f1e99e1812fd83027100c0b84154761417b8b9ad2395901586b60139bd0cfcc2f99b182fee75a65551c9d7063c56d0369dd68c3150a87d31cdae42b9b00e18ac99e0c85318296e64b4a3cd3fbc1bc0")
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
}
