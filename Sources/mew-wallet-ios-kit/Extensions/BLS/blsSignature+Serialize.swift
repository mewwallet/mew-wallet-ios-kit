//
//  File.swift
//  
//
//  Created by Mikhail Nikanorov on 4/6/23.
//

import Foundation
import bls_framework

extension blsSignature {
  public var serialized: Data {
    get throws {
      try BLSInterface.blsInit()
      
      let size = 1024
      var buffer: [UInt8] = [UInt8](repeating: 0, count: size)
      var `self` = self
      let result = blsSignatureSerialize(&buffer, size, &self)
      guard result > 0 else { throw EIP2333Error.internal }
      return Data(buffer[0..<result])
    }
  }
}
