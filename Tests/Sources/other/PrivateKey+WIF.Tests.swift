//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/3/25.
//

import Foundation
import Foundation
import Testing
@testable import mew_wallet_ios_kit

@Suite("WIF Tests")
fileprivate struct WIFTests {
  struct TestVector {
    let mnemonic: [String]
    let derivationPath: String
    let privateKey: String
    let address: Address
    
    init(_ mnemonic: String, _ derivationPath: String, _ privateKey: String, _ address: String) {
      self.mnemonic = mnemonic.components(separatedBy: " ")
      self.derivationPath = derivationPath
      self.privateKey = privateKey
      self.address = Address(raw: address)
    }
  }
  
  static let valid: [TestVector] = [
    .init("abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about", "m/84'/0'/0'/0/0", "KyZpNDKnfs94vbrwhJneDi77V6jF64PWPF8x5cdJb8ifgg2DUc9d", "bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu"),
    .init("abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about", "m/84'/0'/0'/0/1", "Kxpf5b8p3qX56DKEe5NqWbNUP9MnqoRFzZwHRtsFqhzuvUJsYZCy", "bc1qnjg0jd8228aq7egyzacy8cys3knf9xvrerkf9g"),
    .init("abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about", "m/84'/0'/0'/1/0", "KxuoxufJL5csa1Wieb2kp29VNdn92Us8CoaUG3aGtPtcF3AzeXvF", "bc1q8c6fshw2dlwun7ekn9qwf37cu2rn755upcp6el"),
    
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/0", "L3xiwYY5BNrfqjKXLUsrFC29gSFMW8sGn4xQwmVhoj6VZCuvMWVM", "bc1ql553te5z78dawhp688xcgqfdn5ea0yd4q4t8tq"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/1", "L3pwEeN7F9Ub6yfw53jimXhjWtZKKtj8D9DsBHqd5QThtN5ZNQPw", "bc1q8sl03afjhq42aptdeh9vfusgcyd9wz3v0mak2k"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/2", "L2PN53hfKCFdFCrbHtWyd8YfbTcvguhU4Su1VVh3Anjo1Ru8eXvm", "bc1qt8aplnml7j0wwy788a7sqruq044vhvqqujeumc"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/3", "L2n4NzyXmTMHPMWSmihUgb6C7k8948hxn2A1t5CNpHRrvwxWsLbY", "bc1q477dtqgs6zwcx4t2tjjjndx4keeau50awzwmv9"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/4", "L43y1iHFNmZ2wbwTWh8eMZ5iLJA85Ni2ixPCbHAB2YgMKoNbUMau", "bc1qk8856p55rtpyg399gn57jtnp28u8wvmfglj3sk"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/5", "L2GBvwoaQX3a1EBXgaPLCYJf6Q6hiZDtjrYNsk4a53VJQXBh8Aru", "bc1qu3v7qm3kngt7ed87eu8h9mgaqfcfn9fd7pqh2q"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/6", "L3efC6MGiuoZBZWeE8n44cD7chQK2dcUrX6CQMSKZeQopXXZmzYd", "bc1qlpmwacfv335per38qtjk6g9ykrjt8l9uwtahjf"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/7", "L5B2HiXtRBgTQzwo5K1YQk8mN4x9S3gGj1b6i6wTgXyCmRyJrjpv", "bc1qcgjpz3q5r32yw9x7kxgfdau82639t8neg2mpkt"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/8", "Kx6RAAQ1rzDAshGbR6nZsJ3QyQxZaWJpEYNZL2QBw5VXYqYcnWZE", "bc1qr66mquzayrmec8k0qsh9qvh77yssdqnvd484m5"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/9", "Kx6Xgr1MhxzBvCo6eypodmzgFeFQCR3MNvhvUFT6rGj97a4P16f5", "bc1qmxdh7g9mt2p5a4elmzn2tfnamk45ur0sl7yg7a"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/10", "L3CFDJCCqCq9yuhsnJc4KXRhc7HwTGn3uuZdgGTgueDfNQB9RBBn", "bc1qdz3c2zgneq0uxa2dk4094a947m0st6nja2k64l"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/11", "KznY3Z8CVe22bUsGNcr7Y1QDPiEEYFWNerf5ZjSFGkEZ14s1Bxsu", "bc1qfamljcv8lr9jd40qkjd4dcyt5rheuxdaepv9nw"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/12", "Kyph4pdGKo8PywVoBEsE3Phaqc8jA9hSCCgYKEdgX5PLx2gN4b48", "bc1qf3dgzzs595hs657aeemtc0qwlyurh2ptaeku2u"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/13", "L4eze8THRayB6cVsGzNWvH7ZevS3mEooB1x79dnxR3skuay4FNzj", "bc1qt9cq3nv0gz6pmjq9lnxl870ac4khul82ap3k5h"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/14", "KxzkGQbxc34b2B2LUQh1AAyqBCai31fyiLhY9GoETjgw8TW9VZr3", "bc1q57mnr2whpnpfnxx7rjl2tn3fvnv97yta897lt9"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/15", "L4hgg7QFY6nwDPTfuRY8qqvoJGtZgZ2KABRDS1j8kbSXGLprt9DZ", "bc1q8rkdl9ksf5qvf6j9ryxvl750nd09epqxja0n8p"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/16", "L2dFfTwrP5w6txY3Gf7oPAG7dqGkdAKESJCsK13U8RhxGNtZX1cb", "bc1q3l4a7w70uz4wa6q4adv8vlfy0vxtvgljyqrrpg"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/17", "L1Uheget1bBPvnfEY698wSHn97z5pKdL8m3LHNeSWQZwLx3w3v9B", "bc1qm2l9dxp5ys9qdwgy9njl9wqpze5uyajttufkn9"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/18", "L1P8ij8nDbiFUkmoCJW2TyrVHQDwCxYD4aR6FFHxfqVnEnzjjLND", "bc1qukvalfdv8wwa8q2q3y3fjd7g675snsy34y0gjq"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/19", "L5MNJdwgVFFY5rgB8UftVzPMJFD7aYTvgqJMXmUgs6hc9uMEA9b6", "bc1qtv2yygv9z83meqgjaahslmfyw5v52zm36025a5"),
    
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/0", "KwmUUWLk2pTf8R62rzLbrHPfJbcUdd9wg84wPSN2SKPgYFe4WqFA", "bc1q4h8t2sdg5ap72wgmaqyvyw8nqxsuvfemhqlndm"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/1", "L5k6Ze3sJfs9K9woaMkKJAhtruGiCjVCEDT8JDCcyiEwxRLwQvBA", "bc1q55vuy292z7j226knsd7zueun36h2c5qjqx4vq5"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/2", "L5CZBdn1KY4H8hsSgAUvU4Wp5cH3omG6L3H3X2Cy79T1kq9JfMKY", "bc1qmx79yawplmxuelda7a00l9a27526x4w9f3yscl"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/3", "KzuzqLLrhUE2nDbSDPT8384n3x5sh4Frg7UfJ67EpoJQWbjscbNB", "bc1q7ud8a2mu6f0zmdegm6f6tdghscmkt83f5xhjsa"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/4", "L48Wd98kYarpjfgsnCzRWtdZGNWVqcNhZue7gzRwVCQaS9ydDXEu", "bc1qzu5rd97yfrcvwdrz7ljdms25njmnyk6q29uagg"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/5", "Kx1ESKD8ByG9LTZYutnXHwTirLPLQ8YijCQfDpB3cpgCeebtprxW", "bc1q44yjdm85a0wh8vnsx75x2mr5prklnsfnl97myl"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/6", "L42ViLj13UGcYj7xYqvUapgbQ9EM6vo9HFbSMApJU18NGf4BFALm", "bc1q3g0zan9cs9hxcryyzhpwz7vgvpmhct69jjgmwd"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/7", "L1BL1cEUCrn8oj3n4mernigFTc16qf2XEnPsqE9bztinTL9weS23", "bc1qgqjmn8w5dztagjzs6uu6ggfneal9stqlq6wp7z"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/8", "KwmXb53CkoYViob13giF1eAHCGtKcKowsa3wAwWXd4Ub4zZ32Y8M", "bc1q4xn030qznve9yfvcr6regfreqs032z3nuatpuu"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/9", "L3sK9fYNTyK1sUxCZHwtMXuX74AxPMK5qPkbqGFRPu1UXzKXfj18", "bc1qh7yc35q4l0wez50nmug9m3dxprffujhh6h6dt0"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/10", "L5MQN9NGTfpfgm4BKmgrR23YycATpZxvyjbJYQjDheXHJXd3zAtq", "bc1qjjp7wych9wyxxa3060npr494wd9amqm2kwukxl"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/11", "Kz7iHjUoR5PruQ2JsAVMKi5cZfxLNCHWYjrLDFbc6jX5Gzx78qCT", "bc1qm6juwws8zut9enye848flj2kj03w5cp6l79n27"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/12", "KyffM9nU9q73ETxv3KcxXv7DTCjSKei6p2v4t9LiWrPDBZnVFzuH", "bc1qcy58a442wmvwke0twy8g8ul24zpts3h0vwmfgn"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/13", "L4xX2oPxc9LkY3tQLBGafFpXYHrr1VNQX4KHG8FewUoE4p9EYj5Y", "bc1qj9rlhnf2ddvucqkjjceckqg9yfu3adrec0vrzm"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/14", "L2hKnJ7oZFL4bV4DFBxZmkoFynxBgpT85cdZpEJY2RPwjcH6r5F3", "bc1q69asrsnm6aurzcd2z4xclsltkw7wyve9u7mvhg"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/15", "KxMr1FPidbHhCYyFx5xdMxJP2FjPnN45nSJJf8C5bwmXKVn5xSrG", "bc1qly3adgdda0mwrn3ccj0zkfj0krgyfpyjh6x7fj"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/16", "L3KVGiCaRq44BfdPNsxg61EnrTqxBijszZg5X7SF9Eet1iK4UJNt", "bc1qaut0cxx0va5zs6razp5qq6uv978yzxzujcepsu"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/17", "Ky3PazfLLeb99vDvTy8HcsuLrGHNCMM97q9XrUDxTZwuAq3xuDzu", "bc1qthw2rhs7e5ys9lvwln2vnx3sf04frs60jp4phx"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/18", "KxjpNoGZic4F3NXTzEVTzHRoQenMcuohF6pk2tkJot8v6XHkiu99", "bc1qgf8z9f798q6695wu5s37lswfujs30a5hc8arvv"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/19", "L2VuJBwrqfRgUbyGRmcQVn5o95g2vjTrTaHcXmaM2eXXdtwD2WHN", "bc1qss99mff6tnyyyn4r0w8r5pkpdjw8gc42khwgqj"),
  ]
  
  @Test("Test WIF valid cases", arguments: WIFTests.valid)
  func valid(vector: TestVector) async throws {
    let bip39 = BIP39(mnemonic: vector.mnemonic)
    
    let seed = try #require(try bip39.seed())
    let wallet = try Wallet<PrivateKey>(seed: seed, network: .bitcoin(.segwit))
    let derived = try wallet.derive(vector.derivationPath)
    
    let privateKey = try #require(derived.privateKey.string())
    let address = try #require(derived.privateKey.address())
    
    #expect(privateKey == vector.privateKey)
    #expect(address == vector.address)
    
    let wifPK = try #require(PrivateKey(wif: vector.privateKey, network: .bitcoin(.segwit)))
    let wifPrivateKey = try #require(wifPK.string())
    let wifAddress = try #require(wifPK.address())
    
    #expect(wifPrivateKey == privateKey)
    #expect(wifAddress == address)
  }
  
  @Test("PrivateKey to WIF")
  func privateKeyToWIF() async throws {
    let data = Data(hex: "0C28FCA386C7A227600B2FE50B7CAE11EC86D3BF1FBE471BE89827E19D72AA1D")
    let pk = PrivateKey(privateKey: data, network: .bitcoin(.segwit))
    #expect(pk.string(compressedPublicKey: false) == "5HueCGU8rMjxEXxiPuD5BDku4MkFqeZyd4dZ1jvhTVqvbTLvyTJ")
  }
  
  @Test("WIF to PrivateKey")
  func wifToPrivateKey() async throws {
    let wif = "5HueCGU8rMjxEXxiPuD5BDku4MkFqeZyd4dZ1jvhTVqvbTLvyTJ"
    let pk = PrivateKey(wif: wif, network: .bitcoin(.segwit))
    
    #expect(pk?.data() == Data(hex: "0C28FCA386C7A227600B2FE50B7CAE11EC86D3BF1FBE471BE89827E19D72AA1D"))
  }
  
  @Test("Test WIF invalid cases")
  func invalid() async throws {
    let badWIF1 = PrivateKey(wif: "invalidWIF", network: .bitcoin(.segwit))
    #expect(badWIF1 == nil)
    
    let badWIF2 = PrivateKey(wif: "5HueCGU8rMjxEXxiPuD5BDku4MkFqeZyd4dZ1jvhTVqvbTLvyT_", network: .bitcoin(.segwit))
    #expect(badWIF2 == nil)
    
    let badNetwork = PrivateKey(wif: "5HueCGU8rMjxEXxiPuD5BDku4MkFqeZyd4dZ1jvhTVqvbTLvyTJ", network: .ethereum)
    #expect(badNetwork == nil)
    
    let badChecksum = PrivateKey(wif: "4HueCGU8rMjxEXxiPuD5BDku4MkFqeZyd4dZ1jvhTVqvbTLvyTJ", network: .bitcoin(.segwit))
    #expect(badChecksum == nil)
  }
}
