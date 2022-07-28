//
//  File.swift
//  
//
//  Created by Nail Galiaskarov on 7/21/22.
//

import Foundation
import Quick
import Nimble
import MEWwalletKit

// Transfer function
// {
//    "constant": false,
//    "inputs": [
//        {
//        "name": "_to",
//        "type": "address"
//        },
//        {
//        "name": "_value",
//        "type": "uint256"
//        }
//    ],
//    "name": "transfer",
//    "outputs": [
//        {
//        "name": "",
//        "type": "bool"
//        }
//    ],
//    "payable": false,
//    "stateMutability": "nonpayable",
//    "type": "function"
//}

// Approve
//{
//    "constant": false,
//    "inputs": [
//        {
//        "name": "_spender",
//        "type": "address"
//        },
//        {
//        "name": "_value",
//        "type": "uint256"
//        }
//    ],
//    "name": "approve",
//    "outputs": [
//        {
//        "name": "",
//        "type": "bool"
//        }
//    ],
//    "payable": false,
//    "stateMutability": "nonpayable",
//    "type": "function"
//}

final class FunctionNameTests: QuickSpec {
  private struct TestVector {
    let input: String
    let function: ABI.Element.Function?
  }
  
  private lazy var testVectors: [TestVector] = [
    .init(
      input: "function transfer(address to, uint value) external returns (bool)",
      function: .erc20transfer
    )
  ]

  override func spec() {
    describe("general function name parsing") {
      it("should parse function declaration and extract function name") {
        for vector in self.testVectors {
          let function = ABI.Element.Function.parse(plainString: vector.input)
          expect(function).to(equal(vector.function))
        }
      }
    }
  }
}
