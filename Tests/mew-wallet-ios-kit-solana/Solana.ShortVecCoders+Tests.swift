//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import Testing
@testable import mew_wallet_ios_kit_solana
import CryptoSwift
import mew_wallet_ios_kit

@Suite("Solana.ShortVecEncoder tests")
fileprivate struct SolanaShortVecEncoderTests {
  @Test("Test encoder")
  func encoder() async throws {
    let encoder = Solana.ShortVecEncoder()
    
    try #expect(encoder.encode(0) == Data([0x00]))
    try #expect(encoder.encode(1) == Data([0x01]))
    try #expect(encoder.encode(127) == Data([0x7F]))
    try #expect(encoder.encode(128) == Data([0x80, 0x01]))
    try #expect(encoder.encode(300) == Data([0xAC, 0x02]))
    try #expect(encoder.encode(255) == Data([0xFF, 0x01]))
    try #expect(encoder.encode(256) == Data([0x80, 0x02]))
    try #expect(encoder.encode(32767) == Data([0xFF, 0xFF, 0x01]))
    try #expect(encoder.encode(2097152) == Data([0x80, 0x80, 0x80, 0x01]))
  }
}

@Suite("Solana.ShortVecDecoder tests")
fileprivate struct SolanaShortVecDecoderTests {
  @Test("Test decoder")
  func encoder() async throws {
    let encoder = Solana.ShortVecEncoder()
    
    try #expect(encoder.encode(0) == Data([0x00]))
    try #expect(encoder.encode(1) == Data([0x01]))
    try #expect(encoder.encode(127) == Data([0x7F]))
    try #expect(encoder.encode(128) == Data([0x80, 0x01]))
    try #expect(encoder.encode(300) == Data([0xAC, 0x02]))
    try #expect(encoder.encode(255) == Data([0xFF, 0x01]))
    try #expect(encoder.encode(256) == Data([0x80, 0x02]))
    try #expect(encoder.encode(32767) == Data([0xFF, 0xFF, 0x01]))
    try #expect(encoder.encode(2097152) == Data([0x80, 0x80, 0x80, 0x01]))
  }
}
