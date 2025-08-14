//
//  Data+Base58.swift
//  MEWwalletKit
//
//  Created by Mikhail Nikanorov on 4/19/19.
//  Copyright © 2019 MyEtherWallet Inc. All rights reserved.
//

import Foundation
import BigInt
import CryptoSwift

extension Data {
  public enum Base58Error: Error {
    case invalidData
  }
  
  package func encodeBase58(alphabet: String) -> Data {
    let alphabetBytes = alphabet.bytes
    var value = BigInt(data: Data(self))
    let radix = BigInt(alphabet.count.bytes)
        
    var result: [UInt8] = []
    result.reserveCapacity(byteArray.count)
    
    while value > 0 {
      let (quotient, modulus) = value.quotientAndRemainder(dividingBy: radix)
      result += [alphabetBytes[Int(modulus)]]
      value = quotient
    }
    
    let prefix = Array(byteArray.prefix(while: {$0 == 0}).map { _ in alphabetBytes[0] })
    result.append(contentsOf: prefix)
    result.reverse()
    
    return Data(result)
  }
  
  package func encodeBase58(alphabet: String) throws -> String {
    let data: Data = self.encodeBase58(alphabet: alphabet)
    guard let string = String(data: data, encoding: .utf8) else {
      throw Base58Error.invalidData
    }
    return string
  }
  
  package func encodeBase58(_ network: Network) throws -> Data {
    precondition(network.alphabet != nil)
    return encodeBase58(alphabet: network.alphabet!)
  }
  
  package func encodeBase58(_ network: Network) throws -> String {
    precondition(network.alphabet != nil)
    return try encodeBase58(alphabet: network.alphabet!)
  }
}
