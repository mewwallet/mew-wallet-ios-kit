//
//  BLS+Sign.swift
//  
//
//  Created by Mikhail Nikanorov on 4/6/23.
//

import XCTest
@testable import mew_wallet_ios_kit

final class BLSSignTests: XCTestCase {
  func testSignature0() throws {
    let mnemonic = "sister protect peanut hill ready work profit fit wish want small inflict flip member tail between sick setup bright duck morning sell paper worry".components(separatedBy: " ")
    let toSign = Data(hex: "ea9b5656a364bc4d92aca5806b91a76fe538217e39e258d1b9874e776cb49904")
    let expected = Data(hex: "0x8cf4219884b326a04f6664b680cd9a99ad70b5280745af1147477aa9f8b4a2b2b38b8688c6a74a06f275ad4e14c5c0c70e2ed37a15ece5bf7c0724a376ad4c03c79e14dd9f633a3d54abc1ce4e73bec3524a789ab9a69d4d06686a8a67c9e4dc")
    
    let withdrawalWallet = try self.withdrawalWallet(mnemonic: mnemonic)
    let withdrawalKey = withdrawalWallet.privateKey.data()
    
    let secretKey = try withdrawalKey.blsSecretKey()
    let signature = try secretKey.sign(data: toSign)
    
    let publicKey = try secretKey.blsPublicKey
    let serialized = try signature.serialized
    
    XCTAssertNoThrow(try signature.verify(publicKey: publicKey, data: toSign))
    XCTAssertThrowsError(try signature.verify(publicKey: publicKey, data: Data(hex: "0x010203")))
    XCTAssertEqual(serialized.toHexString(), expected.toHexString())
  }
  
  func testSignature1() throws {
    let mnemonic = "sister protect peanut hill ready work profit fit wish want small inflict flip member tail between sick setup bright duck morning sell paper worry".components(separatedBy: " ")
    let toSign = Data(hex: "57cf2373cf3b58dd22f7e23b8d889012f0f4b167160135fedc762841c9ae7265")
    let expected = Data(hex: "0x95e5ceccbaa2e3983c7fbaf693cbe6f5033f73850ace3b0fbbccb9f652198b17d895e339c0a5462cda6c093754e04a0902da3525fac66312ce00c3af19235d722ffe9541a145e2c60a440196f343447ff55bcb62a0f35a4dddaccbaab5025bf6")
    
    let withdrawalWallet = try self.withdrawalWallet(mnemonic: mnemonic)
    let withdrawalKey = withdrawalWallet.privateKey.data()
    
    let secretKey = try withdrawalKey.blsSecretKey()
    let signature = try secretKey.sign(data: toSign)
    let serialized = try signature.serialized
    
    XCTAssertEqual(serialized.toHexString(), expected.toHexString())
  }
  
  // MARK: - Private
  
  private func withdrawalWallet(mnemonic: [String], index: UInt32 = 0) throws -> Wallet<SecretKeyEth2> {
    let network: Network = .eth2Withdrawal
    let suffix = network.pathSuffix()
    
    let bip39 = BIP39(mnemonic: mnemonic)
    let wallet = try Wallet<SecretKeyEth2>.restore(bip39: bip39, network: network)
    let rootWallet = try wallet.derive(network)
    
    let path = String(index) + suffix
    return try rootWallet.derive(path)
  }
}
