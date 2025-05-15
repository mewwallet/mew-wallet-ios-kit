//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 3/21/25.
//

import Foundation
import Foundation
import Testing
@testable import mew_wallet_ios_kit

fileprivate struct TestVector {
  let mnemonic: [String]
  let derivationPath: String
  let extendedPrivateKey: String?
  let extendedPublicKey: String?
  let privateKey: String?
  let publicKey: String?
  let address: Address?
  
  init(_ mnemonic: String, _ derivationPath: String, _ extendedPrivateKey: String?, _ extendedPublicKey: String?, _ privateKey: String?, _ publicKey: String?, _ address: String?) {
    self.mnemonic = mnemonic.components(separatedBy: " ")
    self.derivationPath = derivationPath
    self.extendedPrivateKey = extendedPrivateKey
    self.extendedPublicKey = extendedPublicKey
    self.privateKey = privateKey
    self.publicKey = publicKey
    if let address {
      self.address = Address(raw: address)
    } else {
      self.address = nil
    }
  }
  
  fileprivate static let valid: [TestVector] = [
    .init("abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about", "m/", "zprvAWgYBBk7JR8Gjrh4UJQ2uJdG1r3WNRRfURiABBE3RvMXYSrRJL62XuezvGdPvG6GFBZduosCc1YP5wixPox7zhZLfiUm8aunE96BBa4Kei5", "zpub6jftahH18ngZxLmXaKw3GSZzZsszmt9WqedkyZdezFtWRFBZqsQH5hyUmb4pCEeZGmVfQuP5bedXTB8is6fTv19U1GQRyQUKQGUTzyHACMF", nil, nil, nil),
    .init("abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about", "m/84'/0'/0'", "zprvAdG4iTXWBoARxkkzNpNh8r6Qag3irQB8PzEMkAFeTRXxHpbF9z4QgEvBRmfvqWvGp42t42nvgGpNgYSJA9iefm1yYNZKEm7z6qUWCroSQnE", "zpub6rFR7y4Q2AijBEqTUquhVz398htDFrtymD9xYYfG1m4wAcvPhXNfE3EfH1r1ADqtfSdVCToUG868RvUUkgDKf31mGDtKsAYz2oz2AGutZYs", nil, nil, nil),
    .init("abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about", "m/84'/0'/0'/0/0", nil, nil, "KyZpNDKnfs94vbrwhJneDi77V6jF64PWPF8x5cdJb8ifgg2DUc9d", "0330d54fd0dd420a6e5f8d3624f5f3482cae350f79d5f0753bf5beef9c2d91af3c", "bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu"),
    .init("abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about", "m/84'/0'/0'/0/1", nil, nil, "Kxpf5b8p3qX56DKEe5NqWbNUP9MnqoRFzZwHRtsFqhzuvUJsYZCy", "03e775fd51f0dfb8cd865d9ff1cca2a158cf651fe997fdc9fee9c1d3b5e995ea77", "bc1qnjg0jd8228aq7egyzacy8cys3knf9xvrerkf9g"),
    .init("abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about", "m/84'/0'/0'/1/0", nil, nil, "KxuoxufJL5csa1Wieb2kp29VNdn92Us8CoaUG3aGtPtcF3AzeXvF", "03025324888e429ab8e3dbaf1f7802648b9cd01e9b418485c5fa4c1b9b5700e1a6", "bc1q8c6fshw2dlwun7ekn9qwf37cu2rn755upcp6el"),
    
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m", "zprvAWgYBBk7JR8GmBMCvBAMRfRZiyf4s6fMwptub7QJvVS3Gu7U1uCkxGuze6RumMy2Dv7xDwQMNMUX7Xd81YDknx6hUM8Ph63nLkfYCHLpNe1", nil, nil, nil, nil),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0", "zprvAeU5LLZPoQwJaxVa7SbJB6uySQGA62AMXJLz1QBnq2fMdnqiFvxyLA5gdxBK4mTGrxunWJJ42TXW1EfG53njQjp9J8sMq7Z4eicWBWB2NJt", "zpub6sTRjr6HdnVboSa3DU8JYErhzS6eVUtCtXGaonbQPNCLWbAroUHDsxQAVC6th9uPik7HStyEpEjwu6L8kgJnLBtLGdFL5HkZBUb73AAQhdP", nil, nil, nil),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/0", nil, nil, "L3xiwYY5BNrfqjKXLUsrFC29gSFMW8sGn4xQwmVhoj6VZCuvMWVM", "03d3734821bd4d0795b86bbdcb7efda65f3f420b5b82336a2c0f7480eebeea2ac7", "bc1ql553te5z78dawhp688xcgqfdn5ea0yd4q4t8tq"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/1", nil, nil, "L3pwEeN7F9Ub6yfw53jimXhjWtZKKtj8D9DsBHqd5QThtN5ZNQPw", "02759030fd9cc2ee5b60f45b458060f524065a235612ecd79f660701936116c585", "bc1q8sl03afjhq42aptdeh9vfusgcyd9wz3v0mak2k"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/2", nil, nil, "L2PN53hfKCFdFCrbHtWyd8YfbTcvguhU4Su1VVh3Anjo1Ru8eXvm", "039195ad1e86380c37c3f0ae71d3ad3f73bb10d696b8f4c293a4adcc61b69fdc2a", "bc1qt8aplnml7j0wwy788a7sqruq044vhvqqujeumc"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/3", nil, nil, "L2n4NzyXmTMHPMWSmihUgb6C7k8948hxn2A1t5CNpHRrvwxWsLbY", "037123007b22757c22fc62a162f939d658149d33d2f1c1b4fd3428401d14875001", "bc1q477dtqgs6zwcx4t2tjjjndx4keeau50awzwmv9"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/4", nil, nil, "L43y1iHFNmZ2wbwTWh8eMZ5iLJA85Ni2ixPCbHAB2YgMKoNbUMau", "03a40bb25f6a559ef159deb51066f8501b82f104fee330a398a63a59efabfedad0", "bc1qk8856p55rtpyg399gn57jtnp28u8wvmfglj3sk"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/5", nil, nil, "L2GBvwoaQX3a1EBXgaPLCYJf6Q6hiZDtjrYNsk4a53VJQXBh8Aru", "02e96d8b07e4967ae339d4570acb4d8e9becee3a17e8368f161bac5c2a4100cde1", "bc1qu3v7qm3kngt7ed87eu8h9mgaqfcfn9fd7pqh2q"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/6", nil, nil, "L3efC6MGiuoZBZWeE8n44cD7chQK2dcUrX6CQMSKZeQopXXZmzYd", "023011b2ca53771a65776735605c30145b033e8bb5fe591d877d62e0b5fe2fe425", "bc1qlpmwacfv335per38qtjk6g9ykrjt8l9uwtahjf"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/7", nil, nil, "L5B2HiXtRBgTQzwo5K1YQk8mN4x9S3gGj1b6i6wTgXyCmRyJrjpv", "035d69c085cdec6f25c2effe1c3ca7d3049bc6a79ccd875c7fcca719a4349dd7e4", "bc1qcgjpz3q5r32yw9x7kxgfdau82639t8neg2mpkt"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/8", nil, nil, "Kx6RAAQ1rzDAshGbR6nZsJ3QyQxZaWJpEYNZL2QBw5VXYqYcnWZE", "02f725e17276fa99a881107d87ed87ee8d2977a17ed17739ac8034bfed1c99fa55", "bc1qr66mquzayrmec8k0qsh9qvh77yssdqnvd484m5"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/9", nil, nil, "Kx6Xgr1MhxzBvCo6eypodmzgFeFQCR3MNvhvUFT6rGj97a4P16f5", "02ab229e7e37641b6b52eb3063c790ad3b3bcc7473c316e80dcf8191314bc9f452", "bc1qmxdh7g9mt2p5a4elmzn2tfnamk45ur0sl7yg7a"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/10", nil, nil, "L3CFDJCCqCq9yuhsnJc4KXRhc7HwTGn3uuZdgGTgueDfNQB9RBBn", "03ee689f064c2a768b0b90411a9c15131d11df83c1af6ecd24402ea421f346a050", "bc1qdz3c2zgneq0uxa2dk4094a947m0st6nja2k64l"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/11", nil, nil, "KznY3Z8CVe22bUsGNcr7Y1QDPiEEYFWNerf5ZjSFGkEZ14s1Bxsu", "03b0a569404c72b4c59ce5b876ce8b88ea8fa3ffdf82fba9ffbfd1114ae8ec893a", "bc1qfamljcv8lr9jd40qkjd4dcyt5rheuxdaepv9nw"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/12", nil, nil, "Kyph4pdGKo8PywVoBEsE3Phaqc8jA9hSCCgYKEdgX5PLx2gN4b48", "0360ac8719adb8f5bd4190d9bb67498710f424baf962f9a12f770417e1167521c5", "bc1qf3dgzzs595hs657aeemtc0qwlyurh2ptaeku2u"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/13", nil, nil, "L4eze8THRayB6cVsGzNWvH7ZevS3mEooB1x79dnxR3skuay4FNzj", "03c4e206909199539809cbd38f12962007ab5c62f76b71950a0b4363069dfc380c", "bc1qt9cq3nv0gz6pmjq9lnxl870ac4khul82ap3k5h"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/14", nil, nil, "KxzkGQbxc34b2B2LUQh1AAyqBCai31fyiLhY9GoETjgw8TW9VZr3", "02a771514ad2465d1c5ffc76fb51a4a5f22e9eb95d126de9acf1366bf463474c13", "bc1q57mnr2whpnpfnxx7rjl2tn3fvnv97yta897lt9"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/15", nil, nil, "L4hgg7QFY6nwDPTfuRY8qqvoJGtZgZ2KABRDS1j8kbSXGLprt9DZ", "023430dbb5071a296540e5c0431ec564988dacde3737f78bc82bb3a01a397ad18e", "bc1q8rkdl9ksf5qvf6j9ryxvl750nd09epqxja0n8p"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/16", nil, nil, "L2dFfTwrP5w6txY3Gf7oPAG7dqGkdAKESJCsK13U8RhxGNtZX1cb", "0371fd3b1d43f53cf48dcafe5e4b0e977637d90124157f2ef4f60b2ceda0afc0fb", "bc1q3l4a7w70uz4wa6q4adv8vlfy0vxtvgljyqrrpg"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/17", nil, nil, "L1Uheget1bBPvnfEY698wSHn97z5pKdL8m3LHNeSWQZwLx3w3v9B", "03d2b1aa45a99bdb86d283bc5663abd2399558b5191464e554fb32b9c97ea7f072", "bc1qm2l9dxp5ys9qdwgy9njl9wqpze5uyajttufkn9"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/18", nil, nil, "L1P8ij8nDbiFUkmoCJW2TyrVHQDwCxYD4aR6FFHxfqVnEnzjjLND", "0363743e2879d2f59a27048374a2c7469add2c9c06572fa7512c03153070198f9c", "bc1qukvalfdv8wwa8q2q3y3fjd7g675snsy34y0gjq"),
    .init("close cream middle weasel flat mutual pair pelican nature mistake next celery", "m/84'/0'/0'/0/19", nil, nil, "L5MNJdwgVFFY5rgB8UftVzPMJFD7aYTvgqJMXmUgs6hc9uMEA9b6", "025df0c8f46d87d9b3ae454fd3d026b7ba668393f30557b0021f4a750c1570eb9c", "bc1qtv2yygv9z83meqgjaahslmfyw5v52zm36025a5"),
    
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m", "zprvAWgYBBk7JR8GkkkXTj4aoc1Rw8raGhNhzcZZdVgRaUCAZQBtj6jVqwTWfHHZrqrYfocc7EsQdPnUsCuLQzr2ngUQQRT4no6tDWUNYMDoA4S", nil, nil, nil, nil),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888", "zprvAfTHSoPSsjhF2wHMrP7GSyo4zuZkiGz6w9T2AtjKvVPtg5A7iX8zB93ZXU3DT4Hj9xbszNrszxZQmgnLuGs7joegr3kcvFHKM5Fgqc1m6kj", "zpub6tSdrJvLi7FYFRMpxQeGp7joYwQF7jhxJNNcyH8wUpvsYsVGG4TEiwN3NmK6Y3fqbrL6EpEy7u9vd5s7Yvg5iXBAiei7wNyALArNvhj2TCd", nil, nil, nil),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/0", nil, nil, "KwmUUWLk2pTf8R62rzLbrHPfJbcUdd9wg84wPSN2SKPgYFe4WqFA", "03293c46654ec74293ca89070d5ab948b8d0913c958815dd12dd80ef606f859fe6", "bc1q4h8t2sdg5ap72wgmaqyvyw8nqxsuvfemhqlndm"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/1", nil, nil, "L5k6Ze3sJfs9K9woaMkKJAhtruGiCjVCEDT8JDCcyiEwxRLwQvBA", "020c3446cc3d0f2664355c1bbd505dd46edfd6795b03f737c39b422691a6539a25", "bc1q55vuy292z7j226knsd7zueun36h2c5qjqx4vq5"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/2", nil, nil, "L5CZBdn1KY4H8hsSgAUvU4Wp5cH3omG6L3H3X2Cy79T1kq9JfMKY", "03cbddc8610cdf4d6a27b75ae71424cc2c5afb5dc65b9b42c98dac7b2e6ff328e4", "bc1qmx79yawplmxuelda7a00l9a27526x4w9f3yscl"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/3", nil, nil, "KzuzqLLrhUE2nDbSDPT8384n3x5sh4Frg7UfJ67EpoJQWbjscbNB", "02b914b14aa6b10e83e68c8be8f9818029681160f85b9e8c388cc1a5bf651c1f11", "bc1q7ud8a2mu6f0zmdegm6f6tdghscmkt83f5xhjsa"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/4", nil, nil, "L48Wd98kYarpjfgsnCzRWtdZGNWVqcNhZue7gzRwVCQaS9ydDXEu", "0337c20e20fcb1bbf94a0afe32b8c1c04ac52d942f8dcef6a0fdbacae61c37b069", "bc1qzu5rd97yfrcvwdrz7ljdms25njmnyk6q29uagg"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/5", nil, nil, "Kx1ESKD8ByG9LTZYutnXHwTirLPLQ8YijCQfDpB3cpgCeebtprxW", "03b0433e16e3f6d4717bdcadb1d301c331af08ab7b809e13d7904f522f10facbc1", "bc1q44yjdm85a0wh8vnsx75x2mr5prklnsfnl97myl"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/6", nil, nil, "L42ViLj13UGcYj7xYqvUapgbQ9EM6vo9HFbSMApJU18NGf4BFALm", "035fd670020cf699f18e12675f2b65ad550d70e787ea8ff07ea7ca622f58881527", "bc1q3g0zan9cs9hxcryyzhpwz7vgvpmhct69jjgmwd"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/7", nil, nil, "L1BL1cEUCrn8oj3n4mernigFTc16qf2XEnPsqE9bztinTL9weS23", "025daa3ace0be0df762ce32809cee0f35afd65ec67166539b2875f13350b1097e2", "bc1qgqjmn8w5dztagjzs6uu6ggfneal9stqlq6wp7z"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/8", nil, nil, "KwmXb53CkoYViob13giF1eAHCGtKcKowsa3wAwWXd4Ub4zZ32Y8M", "0347259c98302fb77342dcd81fbfd131a0845376b6d9829e2401c7b59880689c25", "bc1q4xn030qznve9yfvcr6regfreqs032z3nuatpuu"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/9", nil, nil, "L3sK9fYNTyK1sUxCZHwtMXuX74AxPMK5qPkbqGFRPu1UXzKXfj18", "02d03d69babdce238639294afba391739eddb2e885d475b029ab5ab3c2b5a533ef", "bc1qh7yc35q4l0wez50nmug9m3dxprffujhh6h6dt0"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/10", nil, nil, "L5MQN9NGTfpfgm4BKmgrR23YycATpZxvyjbJYQjDheXHJXd3zAtq", "03bdacedd04e5ee1f49699f7c8682cafb0a575a85832a0c7f5d62eb12fb55d8da6", "bc1qjjp7wych9wyxxa3060npr494wd9amqm2kwukxl"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/11", nil, nil, "Kz7iHjUoR5PruQ2JsAVMKi5cZfxLNCHWYjrLDFbc6jX5Gzx78qCT", "02bd50f3467ebd6ad1fededf358933a572d3a6acc366c09a73cebc36b53b723e35", "bc1qm6juwws8zut9enye848flj2kj03w5cp6l79n27"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/12", nil, nil, "KyffM9nU9q73ETxv3KcxXv7DTCjSKei6p2v4t9LiWrPDBZnVFzuH", "022efd548b426fd7f9a2c9a3c1b881041706c2a48b28d98fccbd3497ff30e7ca62", "bc1qcy58a442wmvwke0twy8g8ul24zpts3h0vwmfgn"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/13", nil, nil, "L4xX2oPxc9LkY3tQLBGafFpXYHrr1VNQX4KHG8FewUoE4p9EYj5Y", "03b9e4e4e16335561f0116bc78d2b3b7e8b7f30afbfcbb3e8e8e166e0df98d00e9", "bc1qj9rlhnf2ddvucqkjjceckqg9yfu3adrec0vrzm"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/14", nil, nil, "L2hKnJ7oZFL4bV4DFBxZmkoFynxBgpT85cdZpEJY2RPwjcH6r5F3", "02e61a2ae395298cf12c6b16428c24a3f9775122b2898d0891eb4316139574b904", "bc1q69asrsnm6aurzcd2z4xclsltkw7wyve9u7mvhg"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/15", nil, nil, "KxMr1FPidbHhCYyFx5xdMxJP2FjPnN45nSJJf8C5bwmXKVn5xSrG", "026522e19f02aaf39ea0c40f13f42ad27a32ab97a476dc5bf5cdb521cee5213f34", "bc1qly3adgdda0mwrn3ccj0zkfj0krgyfpyjh6x7fj"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/16", nil, nil, "L3KVGiCaRq44BfdPNsxg61EnrTqxBijszZg5X7SF9Eet1iK4UJNt", "0260fb7fc12690a6b5c4f33fc83f71c0cb98a30e727dd65b1c392d2908c31e6d29", "bc1qaut0cxx0va5zs6razp5qq6uv978yzxzujcepsu"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/17", nil, nil, "Ky3PazfLLeb99vDvTy8HcsuLrGHNCMM97q9XrUDxTZwuAq3xuDzu", "02682efd4580117a7f3bb460b302a6373594c60575bee125b6013ec5391bd3c14d", "bc1qthw2rhs7e5ys9lvwln2vnx3sf04frs60jp4phx"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/18", nil, nil, "KxjpNoGZic4F3NXTzEVTzHRoQenMcuohF6pk2tkJot8v6XHkiu99", "0308a573d00c2e42ffc42b1e3452fea21c1e0f6dde7bc843d0c8a1193eda254b49", "bc1qgf8z9f798q6695wu5s37lswfujs30a5hc8arvv"),
    .init("claim dutch shift banana wild curtain have visa wise memory bulk render eight seat zero mutual lake wonder", "m/84'/0'/6666'/8888/19", nil, nil, "L2VuJBwrqfRgUbyGRmcQVn5o95g2vjTrTaHcXmaM2eXXdtwD2WHN", "036799afe2d61dd4def4a2d95f93d5dccca1b92076584e8ed8437ef3cbf07c303c", "bc1qss99mff6tnyyyn4r0w8r5pkpdjw8gc42khwgqj"),
    
    .init("top helmet gasp face require maze near violin keen slogan twist shoot pitch finish upon crash forward scan team museum focus eight segment orient", Network.bitcoin(.segwit).path + "/0", nil, nil, nil, nil, "bc1qzcrxtfz9m2wkh0ffw4pdcnczjk0x6kwu3a72rp"),
    .init("piano cook sentence spatial dose federal pledge portion tape neck tail crew grain tail awkward plate sorry mandate anger piano behave shift subway brain", Network.bitcoin(.segwit).path + "/0", nil, nil, nil, nil, "bc1qxqhcvlthu3x5hwch679uur8h09namsel58087c")
  ]
}

@Suite("BIP84 Tests")
fileprivate struct BIP84Tests {
  @Test("Test BIP84 valid cases", arguments: TestVector.valid)
  func valid(vector: TestVector) async throws {
    let bip39 = BIP39(mnemonic: vector.mnemonic)
    
    let seed = try bip39.seed()
    let wallet = try Wallet<PrivateKey>(seed: seed, network: .bitcoin(.segwit))
    let derived = try wallet.derive(vector.derivationPath)
    
    
    let extendedPublicKey = try #require(derived.privateKey.publicKey().extended())
    let extendedPrivateKey = try #require(derived.privateKey.extended())
    let privateKey  = try #require(derived.privateKey.string())
    let publicKey = try #require(derived.privateKey.publicKey().string())
    let address = try #require(derived.privateKey.address())
    
    #expect(extendedPrivateKey == vector.extendedPrivateKey || vector.extendedPrivateKey == nil)
    #expect(extendedPublicKey == vector.extendedPublicKey   || vector.extendedPublicKey == nil)
    #expect(privateKey == vector.privateKey                 || vector.privateKey == nil)
    #expect(publicKey == vector.publicKey                   || vector.publicKey == nil)
    #expect(address == vector.address                       || vector.address == nil)
  }
  
  @Test("Test Enkrypt generation")
  func enkrypt() async throws {
    let raw = Data(hex: "0x021aa21d5f77b1be591d0a0a847cb7412a344f4e768b93d55b3eeab3b7e8a4a252")
    let publicKey0 = try PublicKey(publicKey: raw, index: 0, network: .bitcoin(.segwit))
    #expect(publicKey0.address() == Address(raw: "bc1qnjmf6vcjpyru5t8y2936260mrqa305qactwds2"))
    
    let publicKey1 = try PublicKey(publicKey: raw, index: 0, network: .bitcoin(.segwitTestnet))
    #expect(publicKey1.address() == Address(raw: "tb1qnjmf6vcjpyru5t8y2936260mrqa305qajd47te"))
  }
  
  @Test("Test simple key to address")
  func simpleToAddress() async throws {
    let privateKey = PrivateKey(privateKey: Data(hex: "0000000000000000000000000000000000000000000000000000000000000001"), network: .bitcoin(.segwit))
    #expect(privateKey.address() == Address(raw: "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"))
    
    let publicKey = try PublicKey(publicKey: Data(hex: "0x030000000000000000000000000000000000000000000000000000000000000001"), index: 0, network: .bitcoin(.segwit))
    #expect(publicKey.address() == Address(raw: "bc1qz69ej270c3q9qvgt822t6pm3zdksk2x35j2jlm"))
  }
}
