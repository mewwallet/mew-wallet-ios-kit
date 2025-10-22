//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/13/25.
//

import Foundation
import Testing
@testable import mew_wallet_ios_kit_solana
import CryptoSwift
import mew_wallet_ios_kit

@Suite("Solana.Version tests")
fileprivate struct SolanaTransactionCompileMessageTests {
  @Test("deserializeMessageVersion")
  func deserializeMessageVersion() async throws {
    let decoder = Solana.ShortVecDecoder()
    decoder.decodingStyle = .version
    
    var data = Data([0x01])
    var version = try decoder.decode(Solana.Version.self, from: data)
    #expect(version == .legacy)
    
    data = Data([(1 << 7) + 0])
    version = try decoder.decode(Solana.Version.self, from: data)
    #expect(version == .v0)
    
    data = Data([(1 << 7) + 1])
    version = try decoder.decode(Solana.Version.self, from: data)
    #expect(version == .unknown(1))
    
    data = Data([(1 << 7) + 127])
    version = try decoder.decode(Solana.Version.self, from: data)
    #expect(version == .unknown(127))
  }
  
  @Test("deserialize failure")
  func deserializeFailure() async throws {
    let decoder = Solana.ShortVecDecoder()
    decoder.decodingStyle = .version
    
    let data = Data([(1 << 7) + 1])
    #expect(throws: DecodingError.self, performing: {
      try decoder.decode(Solana.VersionedMessage.self, from: data)
    })
  }
}
