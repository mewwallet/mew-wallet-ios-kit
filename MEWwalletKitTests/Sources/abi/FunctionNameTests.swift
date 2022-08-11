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
    let customStructs: [String]
    let function: ABI.Element.Function?
  }
  
  private lazy var testVectors: [TestVector] = [
    .init(
      input: "override function transfer(address to, uint value) external returns (bool)",
      customStructs: [],
      function: .erc20transfer
    ),
    .init(
      input: "function accept(address to, uint value, Bid bid) external returns (bool)",
      customStructs: [
      """
      struct Bid {
      address bidOwner;
      uint amount;
      }
      """
      ],
      function: .init(
        name: "accept",
        inputs: [
          .init(name: "to", type: .address),
          .init(name: "value", type: .uint(bits: 256)),
          .init(name: "bid", type: .tuple(types: [.address, .uint(bits: 256)]))
        ],
        outputs: [
          .init(name: "", type: .bool)
        ],
        constant: false,
        payable: false
      )
    ),
    .init(
      input: "function getBid(address bidOwner) returns (Bid)",
      customStructs: [
      """
      struct Bid {
      address bidOwner;
      Amount amount;
      }
      """,
      """
      struct  Amount  { uint amount;
      }
      """
      ],
      function: .init(
        name: "getBid",
        inputs: [
          .init(name: "bidOwner", type: .address),
        ],
        outputs: [
          .init(name: "", type: .tuple(types: [.address, .tuple(types: [.uint(bits: 256)])]))
        ],
        constant: false,
        payable: false
      )
    )

  ]

  override func spec() {
    describe("general function name parsing") {
      it("should parse function declaration and extract function name") {
        for vector in self.testVectors {
          let function = ABI.Element.Function.parse(
            plainString: vector.input,
            structs: vector.customStructs
          )
          expect(function).to(equal(vector.function))
        }
      }
    }
  }
}
