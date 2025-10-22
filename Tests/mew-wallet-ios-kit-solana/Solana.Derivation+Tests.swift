//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/6/25.
//

import Foundation
import Testing
import mew_wallet_ios_kit
import mew_wallet_ios_tweetnacl

@Suite("Derivation test")
fileprivate struct SolanaWIPTests {
  @Test("Test derivation correctness")
  func hd() async throws {
    let mnem = "hat correct find conduct original nasty narrow slush wool smile spread pride spirit profit mention smart squeeze roast inhale claim frog eye leave step"
    
    let bip39 = BIP39(mnemonic: mnem.components(separatedBy: " "))
    
    let wallet = try Wallet<PrivateKey>(seed: bip39.seed(), network: .solana)
    let child = try wallet.derive(.solana, index: 0)
    
    try #expect(child.privateKey.data().toHexString() == "c0b9355922b6df97e88b04058dee478908328dd959adf61991d7ca64e4d27a8c")
    try #expect(child.privateKey.ed25519().toHexString() == "c0b9355922b6df97e88b04058dee478908328dd959adf61991d7ca64e4d27a8c5f9e678f7f5c32ead7d451255dcd2ae713d0a68dfb8ec8d952b545badc241843")
    try #expect(child.privateKey.publicKey().data().toHexString() == "5f9e678f7f5c32ead7d451255dcd2ae713d0a68dfb8ec8d952b545badc241843")
  }
}
