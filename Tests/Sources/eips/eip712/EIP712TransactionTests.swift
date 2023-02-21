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
    XCTAssertEqual(transaction.meta.customSignature?.toHexString(), "8e67015a432c2990214401d35fa2b2b91e6857bb12bbc4f708a864a8dbe2e3195751e3d8f9b0d9a743351d5642f1c4d67457e1069822092a21068e672dd2f28a1c")
    XCTAssertEqual(transaction.serialize()?.toHexString(), "71f890808405f5e1008405f5e100834c4b4094dc544d1aa88ff8bbd2f2aec754b1f1e99e1812fd85e8d4a5100080820118808082011894dc544d1aa88ff8bbd2f2aec754b1f1e99e1812fd82c350c0b8418e67015a432c2990214401d35fa2b2b91e6857bb12bbc4f708a864a8dbe2e3195751e3d8f9b0d9a743351d5642f1c4d67457e1069822092a21068e672dd2f28a1cc0")
  }
  
  func testEmptyGeneralPaymasterInput() {
    let paymaster = ZKSync.EIP712Transaction.Meta.Paymaster.paymaster(with: .init(raw: "0x0265d9a5af8af5fe070933e5e549d8fef08e09f4"), type: .general(innerInput: Data()))
    XCTAssertEqual(paymaster.paymaster, Address(raw: "0x0265d9a5af8af5fe070933e5e549d8fef08e09f4"))
    XCTAssertEqual(paymaster.input?.toHexString(), "8c5a344500000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000")
  }
  
  func testPaymasterInput() {
    let paymaster = ZKSync.EIP712Transaction.Meta.Paymaster.paymaster(with: .init(raw: "0x0265d9a5af8af5fe070933e5e549d8fef08e09f4"), type: .general(innerInput: Data(hex: "0xaabbcc")))
    XCTAssertEqual(paymaster.paymaster, Address(raw: "0x0265d9a5af8af5fe070933e5e549d8fef08e09f4"))
    XCTAssertEqual(paymaster.input?.toHexString(), "8c5a344500000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003aabbcc0000000000000000000000000000000000000000000000000000000000")
    
    let paymasterAllowance = ZKSync.EIP712Transaction.Meta.Paymaster.paymaster(with: .init(raw: "0x0265d9a5af8af5fe070933e5e549d8fef08e09f4"),
                                                                               type: .approvalBased(token: .init(raw: "0xaabbccddeeff00112233445566778899aabbccdd"),
                                                                                                    minimalAllowance: BigInt(500),
                                                                                                    innerInput: Data(hex: "0xaabbcc")))
    XCTAssertEqual(paymasterAllowance.paymaster, Address(raw: "0x0265d9a5af8af5fe070933e5e549d8fef08e09f4"))
    XCTAssertEqual(paymasterAllowance.input?.toHexString(), "949431dc000000000000000000000000aabbccddeeff00112233445566778899aabbccdd00000000000000000000000000000000000000000000000000000000000001f400000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000003aabbcc0000000000000000000000000000000000000000000000000000000000")
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
    XCTAssertEqual(transaction.meta.paymaster?.input?.toHexString(), "8c5a344500000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003aabbcc0000000000000000000000000000000000000000000000000000000000")
    XCTAssertEqual(transaction.meta.customSignature?.toHexString(), "0d44b41225e470d984d77061101fdea43cc8d28c74be4d0bbe126d17535a4dc1690e629a5fc23f586d2d1fffa862b4a5e0e34fcbbb116a1e80e3a89711ddd4ff1c")
    XCTAssertEqual(transaction.serialize()?.toHexString(), "71f9010c808405f5e1008405f5e100834c4b4094dc544d1aa88ff8bbd2f2aec754b1f1e99e1812fd85e8d4a5100080820118808082011894dc544d1aa88ff8bbd2f2aec754b1f1e99e1812fd82c350c0b8410d44b41225e470d984d77061101fdea43cc8d28c74be4d0bbe126d17535a4dc1690e629a5fc23f586d2d1fffa862b4a5e0e34fcbbb116a1e80e3a89711ddd4ff1cf87b940265d9a5af8af5fe070933e5e549d8fef08e09f4b8648c5a344500000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003aabbcc0000000000000000000000000000000000000000000000000000000000")
  }
}
