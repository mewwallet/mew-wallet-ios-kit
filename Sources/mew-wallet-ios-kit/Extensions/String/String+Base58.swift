//
//  String+Base58.swift
//  MEWwalletKit
//
//  Created by Mikhail Nikanorov on 4/19/19.
//  Copyright © 2019 MyEtherWallet Inc. All rights reserved.
//

import Foundation
import BigInt
import CryptoSwift

extension String {
  package enum Base58Error: Error {
    case invalidCharacter
  }
  
  package func decodeBase58(alphabet: String) throws -> Data {
    let alphabetBytes = alphabet.bytes
    
    var result = BigInt(0)
    
    var j = BigInt(1)
    let radix = BigInt(alphabetBytes.count)
    
    let byteString = self.bytes
    let byteStringReversed = byteString.reversed()
    
    for char in byteStringReversed {
      guard let index = alphabetBytes.firstIndex(of: char) else {
        throw Base58Error.invalidCharacter
      }
      result += j * BigInt(index)
      j *= radix
    }
    
    let bytes = result.data.byteArray
    var prefixData = Data()
    
    for _ in 0 ..< byteString.prefix(while: { i in i == alphabetBytes[0] }).count {
      prefixData += [0x00]
    }
    return prefixData + Data(bytes)
  }
  
  package func decodeBase58(_ network: Network) throws -> Data {
    precondition(network.alphabet != nil)
    return try decodeBase58(alphabet: network.alphabet!)
  }
}
