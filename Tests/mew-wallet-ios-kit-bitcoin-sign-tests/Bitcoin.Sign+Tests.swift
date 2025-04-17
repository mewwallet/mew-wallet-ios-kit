//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/17/25.
//

import Foundation
import Testing
@testable import mew_wallet_ios_kit_bitcoin_sign
import mew_wallet_ios_kit
import mew_wallet_ios_kit_bitcoin

@Suite("Signing tests")
fileprivate struct EncoderTransactionOutputTests {
  @Test("Manually generated tx")
  func verifySignature() async throws {
    let psbt = "cHNidP8B+wQAAAAAAQCZAQAAAAHmNpswrwN9njvbFbE38R/QoNC6n82yo/iXFkGnmBr+eQAAAAAA/////wMKAAAAAAAAABl2qRRxBkbaA/xHLnBB/6WYk00xesovV4isDwAAAAAAAAAZdqkUKB25dV838rVLDvo4skq9BESs/26IrBQAAAAAAAAAGXapFFmN+c0IwgMl0XCkXDZ/r0h8N31TiKwAAAAAAAEAqgIAAAAAAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP////8CUQD/////AgDyBSoBAAAAGXapFDr38StazFkqL6pS43+NzvgJ3aDKiKwAAAAAAAAAACZqJKohqe3i9hw/cdHe/T+pmd+jaVN1XGkGiXmZYrSL69g2l06M+QEgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAIyEDhjJvTTI/CmelaanBFTLeSZcQDtWu1cEsW2NuddkMPiGsAAEAIyEDszO2G23z2UgYO2wLa8Qg9j+6pT9tyG0fYPj07fAH/MasAAEAIyECjU1+yHAlE3cuWRgSXy542Etzsi6NF0+ZEeY57lmCNUasAA=="
    let pk_hex = "58090c1431947cf63e5cd36943dcdc7f6bfc2ee92a8a6994f3c29712f48d9e24"
    let pub_hex = "033fff06f7c1e8a625a8b03d1c82e724203bc754e285f69076e9c3507a2ec8ebdf"
    let addr_str = "bc1q8tmlz266e3vj5ta22t3hlrwwlqyamgx296893w"
    
    let expected = "0100000001e6369b30af037d9e3bdb15b137f11fd0a0d0ba9fcdb2a3f8971641a7981afe79000000006a4730440220090a10ba43c8c95609f4cefe1c5dda2ebe1bd760102880db09ae5f1e40843d02022037e6df9ef4b769f22112e13b2ff455b5ce609dcfc17ee9a6288a45b607e5a7860121033fff06f7c1e8a625a8b03d1c82e724203bc754e285f69076e9c3507a2ec8ebdfffffffff030a000000000000001976a914710646da03fc472e7041ffa598934d317aca2f5788ac0f000000000000001976a914281db9755f37f2b54b0efa38b24abd0444acff6e88ac14000000000000001976a914598df9cd08c20325d170a45c367faf487c377d5388ac00000000"
    
    let privateKey = PrivateKey(privateKey: Data(hex: pk_hex), network: .bitcoin(.segwit))
    try #expect(privateKey.publicKey().data() == Data(hex: pub_hex))
    #expect(privateKey.address()?.address == addr_str)
    
    let decoder = PSBT.Decoder()
    let data = try #require(Data(base64Encoded: psbt))
    let tx = try decoder.decode(PSBT.Transaction.self, from: data)
    let signedTX = try tx.sign(key: privateKey)
    
    #expect(signedTX.toHexString() == expected)
  }
  
  @Test("Test P2PKH")
  func p2pkh() async throws {
    let wif_pk = "cThjSL4HkRECuDxUTnfAmkXFBEg78cufVBy3ZfEhKoxZo6Q38R5L"
    let utxo_hex = "4062b007000000001976a914a235bdde3bb2c326f291d9c281fdc3fe1e956fe088ac"
    let tx_hex = "0100000001449d45bbbfe7fc93bbe649bb7b6106b248a15da5dbd6fdc9bdfc7efede83235e0100000000ffffffff014062b007000000001976a914f86f0bc0a2232970ccdf4569815db500f126836188ac00000000"
    let expected = "0100000001449d45bbbfe7fc93bbe649bb7b6106b248a15da5dbd6fdc9bdfc7efede83235e010000006a473044022055d0127e9c6f9e289c473c4da2699687202bbc8b1e1c6ecff4fb91d7ab0f640e022074e1e1cd1fd153899a1ccf02ab39ee1d5acf39c2941c79f1e0ce3341b7b86323012103969a4ac9b1521cfae44a929a614193b0467a20e0a15973cae9ba1efb9627d830ffffffff014062b007000000001976a914f86f0bc0a2232970ccdf4569815db500f126836188ac00000000"
    
    let pk = try #require(PrivateKey(wif: wif_pk, network: .bitcoin(.legacyTestnet)))
    
    #expect(pk.address()?.address == "mvJe9AfPLrxpfHwjLNjDAiVsFSzwBGaMSP")
    
    let txDecoder = Bitcoin.TransactionDecoder()
    let utxoDecoder = Bitcoin.OutputDecoder()
    
    let tx = try txDecoder.decode(Bitcoin.Transaction.self, from: Data(hex: tx_hex))
    let utxo = try utxoDecoder.decode(Bitcoin.Transaction.Output.self, from: Data(hex: utxo_hex))
    
    let signed = try tx.sign(
      input: 0,
      utxo: utxo,
      key: pk
    )
    
    let encoder = Bitcoin.Encoder()
    let result = try encoder.encode(signed)
    
    #expect(result.toHexString() == expected)
  }
  
  @Test("Test WitnessV0")
  func nativeP2WPKH() async throws {
    let tx_hex = "0100000002fff7f7881a8099afa6940d42d1e7f6362bec38171ea3edf433541db4e4ad969f0000000000eeffffffef51e1b804cc89d182d279655c3aa89e815b1b309fe287d9b2b55d57b90ec68a0100000000ffffffff02202cb206000000001976a9148280b37df378db99f66f85c95a783a76ac7a6d5988ac9093510d000000001976a9143bde42dbee7e4dbe6a21b2d50ce2f0167faa815988ac11000000"
    let pk_hex = "58090c1431947cf63e5cd36943dcdc7f6bfc2ee92a8a6994f3c29712f48d9e24"
    let pub_hex = "033fff06f7c1e8a625a8b03d1c82e724203bc754e285f69076e9c3507a2ec8ebdf"
    let addr_str = "bc1q8tmlz266e3vj5ta22t3hlrwwlqyamgx296893w"
    
    let expected = "01000000000102fff7f7881a8099afa6940d42d1e7f6362bec38171ea3edf433541db4e4ad969f0000000000eeffffffef51e1b804cc89d182d279655c3aa89e815b1b309fe287d9b2b55d57b90ec68a0100000000ffffffff02202cb206000000001976a9148280b37df378db99f66f85c95a783a76ac7a6d5988ac9093510d000000001976a9143bde42dbee7e4dbe6a21b2d50ce2f0167faa815988ac000247304402205c8268a5920404919d9258de305d82b2b9aab7f2b322f48aea0a6567dbe0ffda02206da9b1a2cb5e074d64985bd5f441e50ade43446a894d1bd07ed06f627523d2790121033fff06f7c1e8a625a8b03d1c82e724203bc754e285f69076e9c3507a2ec8ebdf11000000"
    let privateKey = PrivateKey(privateKey: Data(hex: pk_hex), network: .bitcoin(.segwit))
    try #expect(privateKey.publicKey().data() == Data(hex: pub_hex))
    #expect(privateKey.address()?.address == addr_str)
    
    let scriptDecoder = Bitcoin.ScriptDecoder()
//    let utxo_script_1 = try scriptDecoder.decode(Bitcoin.Script.self, from: Data(hex: "2103c9f4836b9a4f77fc0d81f7bcb01b7f1b35916864b9476c241ce9fc198bd25432ac"))
    let utxo_script_2 = try scriptDecoder.decode(Bitcoin.Script.self, from: Data(hex: "00143af7f12b5acc592a2faa52e37f8dcef809dda0ca"))
    
    let txDecoder = Bitcoin.TransactionDecoder()
    let tx = try txDecoder.decode(Bitcoin.Transaction.self, from: Data(hex: tx_hex))
    
    let signed = try tx.sign(
      input: 1,
      utxo: Bitcoin.Transaction.Output(value: 6_0000_0000, n: nil, script: utxo_script_2),
      key: privateKey,
      redeemScript: nil,
      witnessScript: nil,
      sigHash: .all
    )
    
    let encoder = Bitcoin.Encoder()
    let signed_hex = try encoder.encode(signed).toHexString()
    
    #expect(signed_hex == expected)
  }
}
