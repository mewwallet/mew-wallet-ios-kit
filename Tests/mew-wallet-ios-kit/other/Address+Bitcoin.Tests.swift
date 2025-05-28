//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 5/4/25.
//

import Foundation
import Testing
@testable import mew_wallet_ios_kit

fileprivate struct TestVector {
  let raw: String
  let address: Address?
  
  init(raw: String, address: Address?) {
    self.raw = raw
    self.address = address
  }
  
  fileprivate static let valid: [TestVector] = [
    .init(raw: "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa", address: Address(raw: "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa")),
    .init(raw: "1BoatSLRHtKNngkdXEeobR76b53LETtpyT", address: Address(raw: "1BoatSLRHtKNngkdXEeobR76b53LETtpyT")),
    .init(raw: "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy", address: Address(raw: "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy")),
    .init(raw: "3CMNFxN1oHBc4R1EpboAL5yzHGgE611Xou", address: Address(raw: "3CMNFxN1oHBc4R1EpboAL5yzHGgE611Xou")),
    .init(raw: "tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3q0sl5k7", address: Address(raw: "tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3q0sl5k7")),
    .init(raw: "bc1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vqzk5jj0", address: Address(raw: "bc1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vqzk5jj0")),
    .init(raw: "bc1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3qccfmv3", address: Address(raw: "bc1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3qccfmv3")),
    .init(raw: "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4", address: Address(raw: "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4")),
    .init(raw: "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx", address: Address(raw: "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx")),
    .init(raw: "mzBc4XEFSdzCDcTxAgf6EZXgsZWpztRhef", address: Address(raw: "mzBc4XEFSdzCDcTxAgf6EZXgsZWpztRhef"))
  ]

  fileprivate static let invalid: [TestVector] = [
    .init(raw: "1BoatSLRHtKNngkdXEeobR76b53LETtpyt", address: nil), // Bad checksum
    .init(raw: "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNL0", address: nil), // Contains '0' (not in Base58)
    .init(raw: "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kygt08", address: nil), // Too short
    .init(raw: "bc1zw508d6qejxtdg4y5r3zarvaryvg6kdaj", address: nil), // Invalid witness version
    .init(raw: "tc1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vq5zuyut", address: nil), // Invalid human-readable part
  ]
}

@Suite("Address + Bitcoin Tests")
fileprivate struct AddressBitcoinTests {
  @Test("Test valid cases", arguments: TestVector.valid)
  func valid(vector: TestVector) async throws {
    let address = Address(bitcoinAddress: vector.raw)
    #expect(address == vector.address)
  }
  
  @Test("Test invalid invalid cases", arguments: TestVector.invalid)
  func invalid(vector: TestVector) async throws {
    let address = Address(bitcoinAddress: vector.raw)
    #expect(address == nil)
  }
}
