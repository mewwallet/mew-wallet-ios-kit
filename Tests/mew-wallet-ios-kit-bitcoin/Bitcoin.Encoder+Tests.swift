//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/18/25.
//

import Foundation
import Testing
@testable import mew_wallet_ios_kit_bitcoin
import CryptoSwift

@Suite("Bitcoin.Encoder Bitcoin.Script tests")
fileprivate struct EncoderScriptTests {
  
  /// Empty script
  ///
  /// 0x00 or [] ?
  @Test("Encode empty script")
  func emptyEncodeScript() async throws {
    let encoder = Bitcoin.Encoder()
    let script = Bitcoin.Script.empty
    let data = try encoder.encode(script)
    #expect(data == Data([]))
  }
  
  /// P2PK (pubkey)
  ///
  /// Pay to Public Key
  ///
  /// - **Format**:
  ///   ```
  ///   <pubkey> OP_CHECKSIG
  ///   ```
  ///
  /// - **Examples**:
  ///   ```
  ///   21 <33-byte pubkey> ac
  ///   ```
  ///   or
  ///   ```
  ///   41 <65-byte pubkey> ac
  ///   ```
  @Test("Encode P2PK script", arguments: zip(
    [
      [Bitcoin.Op.OP_PUSHBYTES(Data(repeating: 0x00, count: 33)), .OP_CHECKSIG],
      [.OP_PUSHBYTES(Data(repeating: 0x00, count: 65)), .OP_CHECKSIG],
    ],
    [
      Data(hex: "0x21000000000000000000000000000000000000000000000000000000000000000000ac"),
      Data(hex: "0x410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ac")
    ]
  ))
  func encodeP2PKScript(asm: [Bitcoin.Op], expected: Data) async throws {
    let encoder = Bitcoin.Encoder()
    let script = Bitcoin.Script(asm: asm)
    let data = try encoder.encode(script)
    #expect(data == expected)
  }
  
  /// P2PKH (pubkeyhash)
  ///
  /// Pay to PubKey Hash
  ///
  /// - **Format**:
  ///   ```
  ///   OP_DUP OP_HASH160 <20-byte hash> OP_EQUALVERIFY OP_CHECKSIG
  ///   ```
  ///
  /// - **Example**:
  ///   ```
  ///   76 a9 14 <20-byte> 88 ac
  ///   ```
  @Test("Encode P2PKH script", arguments: zip(
    [
      [Bitcoin.Op.OP_DUP, .OP_HASH160, .OP_PUSHBYTES(Data(repeating: 0x00, count: 20)), .OP_EQUALVERIFY, .OP_CHECKSIG],
    ],
    [
      Data(hex: "0x76a914000000000000000000000000000000000000000088ac"),
    ]
  ))
  func encodeP2PKHScript(asm: [Bitcoin.Op], expected: Data) async throws {
    let encoder = Bitcoin.Encoder()
    let script = Bitcoin.Script(asm: asm)
    let data = try encoder.encode(script)
    #expect(data == expected)
  }
  
  /// P2SH (scripthash)
  ///
  /// Pay to Script Hash
  ///
  /// - **Format**:
  ///   ```
  ///   OP_HASH160 <20-byte hash> OP_EQUAL
  ///   ```
  ///
  /// - **Example**:
  ///   ```
  ///   a9 14 <20-byte> 87
  ///   ```
  @Test("Encode P2SH script", arguments: zip(
    [
      [Bitcoin.Op.OP_HASH160, .OP_PUSHBYTES(Data(repeating: 0x00, count: 20)), .OP_EQUAL],
    ],
    [
      Data(hex: "0xa914000000000000000000000000000000000000000087"),
    ]
  ))
  func encodeP2SHScript(asm: [Bitcoin.Op], expected: Data) async throws {
    let encoder = Bitcoin.Encoder()
    let script = Bitcoin.Script(asm: asm)
    let data = try encoder.encode(script)
    #expect(data == expected)
  }
  
  /// Multisig (multisig)
  ///
  /// M-of-N multisig
  ///
  /// - **Format**:
  ///   ```
  ///   M <pubkey1> ... <pubkeyN> N OP_CHECKMULTISIG
  ///   ```
  ///
  /// - **Example**:
  ///   ```
  ///   starts with 52 (OP_2) etc., ends in ae
  ///   ```
  @Test("Encode Multisig script", arguments: zip(
    [
      [Bitcoin.Op.OP_1, .OP_PUSHBYTES(Data(repeating: 0x00, count: 33)), .OP_PUSHBYTES(Data(repeating: 0x00, count: 33)), .OP_PUSHBYTES(Data(repeating: 0x00, count: 33)), .OP_3, .OP_CHECKMULTISIG],
      [.OP_2, .OP_PUSHBYTES(Data(repeating: 0x00, count: 33)), .OP_PUSHBYTES(Data(repeating: 0x00, count: 65)), .OP_2, .OP_CHECKMULTISIG],
      [.OP_1, .OP_PUSHBYTES(Data(repeating: 0x00, count: 33)), .OP_1, .OP_CHECKMULTISIG],
      [.OP_1, .OP_PUSHBYTES(Data(repeating: 0x00, count: 65)), .OP_PUSHBYTES(Data(repeating: 0x00, count: 65)), .OP_2, .OP_CHECKMULTISIG],
    ],
    [
      Data(hex: "0x5121000000000000000000000000000000000000000000000000000000000000000000210000000000000000000000000000000000000000000000000000000000000000002100000000000000000000000000000000000000000000000000000000000000000053ae"),
      Data(hex: "0x522100000000000000000000000000000000000000000000000000000000000000000041000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000052ae"),
      Data(hex: "0x512100000000000000000000000000000000000000000000000000000000000000000051ae"),
      Data(hex: "0x5141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000041000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000052ae"),
    ]
  ))
  func encodeMultiScript(asm: [Bitcoin.Op], expected: Data) async throws {
    let encoder = Bitcoin.Encoder()
    let script = Bitcoin.Script(asm: asm)
    let data = try encoder.encode(script)
    #expect(data == expected)
  }
  
  /// Null Data (nulldata)
  ///
  /// OP_RETURN
  ///
  /// - **Format**:
  ///   ```
  ///   OP_RETURN <data>
  ///   ```
  ///
  /// - **Example**:
  ///   ```
  ///   6a <pushdata>
  ///   ```
  ///   or
  ///   ```
  ///   6a
  ///   ```
  @Test("Encode Null Data script", arguments: zip(
    [
      [Bitcoin.Op.OP_RETURN],
      [.OP_RETURN, .OP_PUSHBYTES(Data(repeating: 0x00, count: 1))],
      [.OP_RETURN, .OP_PUSHBYTES(Data(repeating: 0x00, count: 80))],
    ],
    [
      Data(hex: "0x6a"),
      Data(hex: "0x6a0100"),
      Data(hex: "0x6a500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"),
    ]
  ))
  func encodeNulldataScript(asm: [Bitcoin.Op], expected: Data) async throws {
    let encoder = Bitcoin.Encoder()
    let script = Bitcoin.Script(asm: asm)
    let data = try encoder.encode(script)
    #expect(data == expected)
  }
  
  /// P2WPKH (witness_v0_keyhash)
  ///
  /// SegWit v0, Pay to PubKey Hash
  ///
  /// - **Format**:
  ///   ```
  ///   OP_0 <20-byte pubkey hash>
  ///   ```
  ///
  /// - **Example**:
  ///   ```
  ///   00 14 <20-byte>
  ///   ```
  @Test("Encode P2WPKH script", arguments: zip(
    [
      [Bitcoin.Op.OP_0, .OP_PUSHBYTES(Data(repeating: 0x00, count: 20))]
    ],
    [
      Data(hex: "0x00140000000000000000000000000000000000000000"),
    ]
  ))
  func encodeP2WPKHScript(asm: [Bitcoin.Op], expected: Data) async throws {
    let encoder = Bitcoin.Encoder()
    let script = Bitcoin.Script(asm: asm)
    let data = try encoder.encode(script)
    #expect(data == expected)
  }
  
  /// P2WSH (witness_v0_scripthash)
  ///
  /// SegWit v0, Pay to Script Hash
  ///
  /// - **Format**:
  ///   ```
  ///   OP_0 <32-byte script hash>
  ///   ```
  ///
  /// - **Example**:
  ///   ```
  ///   00 20 <32-byte>
  ///   ```
  @Test("Encode P2WSH script", arguments: zip(
    [
      [Bitcoin.Op.OP_0, .OP_PUSHBYTES(Data(repeating: 0x00, count: 32))]
    ],
    [
      Data(hex: "0x00200000000000000000000000000000000000000000000000000000000000000000"),
    ]
  ))
  func encodeP2WSHScript(asm: [Bitcoin.Op], expected: Data) async throws {
    let encoder = Bitcoin.Encoder()
    let script = Bitcoin.Script(asm: asm)
    let data = try encoder.encode(script)
    #expect(data == expected)
  }
  
  /// P2TR (witness_v1_taproot)
  ///
  /// SegWit v1, Pay to Taproot
  ///
  /// - **Format**:
  ///   ```
  ///   OP_1 <32-byte x-only pubkey>
  ///   ```
  ///
  /// - **Example**:
  ///   ```
  ///   51 20 <32-byte>
  ///   ```
  @Test("Encode P2TR script", arguments: zip(
    [
      [Bitcoin.Op.OP_1, .OP_PUSHBYTES(Data(repeating: 0x00, count: 32))]
    ],
    [
      Data(hex: "0x51200000000000000000000000000000000000000000000000000000000000000000"),
    ]
  ))
  func encodeP2TRScript(asm: [Bitcoin.Op], expected: Data) async throws {
    let encoder = Bitcoin.Encoder()
    let script = Bitcoin.Script(asm: asm)
    let data = try encoder.encode(script)
    #expect(data == expected)
  }
  
  /// P2A (anchor)
  ///
  /// SegWit v1, Pay to Anchor — minimal script used for CPFP fee bumping
  ///
  /// - **Format**:
  ///   ```
  ///   OP_1 <0x4e73>
  ///   ```
  ///
  /// - **Example**:
  ///   ```
  ///   51 02 4e 73
  ///   ```
  ///
  /// - **Notes**:
  ///   - Spendable by anyone
  ///   - No witness data required
  ///   - Used primarily in ephemeral anchors (e.g. Lightning-related protocols)
  @Test("Encode P2A script", arguments: zip(
    [
      [Bitcoin.Op.OP_1, .OP_PUSHBYTES(Data(repeating: 0x00, count: 2))]
    ],
    [
      Data(hex: "0x51020000"),
    ]
  ))
  func encodeP2AScript(asm: [Bitcoin.Op], expected: Data) async throws {
    let encoder = Bitcoin.Encoder()
    let script = Bitcoin.Script(asm: asm)
    let data = try encoder.encode(script)
    #expect(data == expected)
  }
  
  /// Unknown Witness (witness_unknown)
  ///
  /// Future witness versions
  ///
  /// - **Format**:
  ///   ```
  ///   OP_n <data> where n > 0
  ///   ```
  ///
  /// - **Example**:
  ///   ```
  ///   51 20 <32-byte>  // OP_1 + 32 bytes
  ///   ```
  @Test("Encode witness_unknown script", arguments: zip(
    [
      [Bitcoin.Op.OP_2, .OP_PUSHBYTES(Data(repeating: 0x00, count: 20))],
    ],
    [
      Data(hex: "0x52140000000000000000000000000000000000000000"),
    ]
  ))
  func encodeWitnessUnknownScript(asm: [Bitcoin.Op], expected: Data) async throws {
    let encoder = Bitcoin.Encoder()
    let script = Bitcoin.Script(asm: asm)
    let data = try encoder.encode(script)
    #expect(data == expected)
  }
  
  @Test("Encode nonstandard script", arguments: zip(
    [
      [Bitcoin.Op.OP_4, .OP_PUSHBYTES(Data(repeating: 0x00, count: 33)), .OP_PUSHBYTES(Data(repeating: 0x00, count: 33)), .OP_PUSHBYTES(Data(repeating: 0x00, count: 33)), .OP_3, .OP_CHECKMULTISIG],
      [.OP_2, .OP_PUSHBYTES(Data(repeating: 0x00, count: 33)), .OP_PUSHBYTES(Data(repeating: 0x00, count: 41)), .OP_3, .OP_CHECKMULTISIG],
      [.OP_1, .OP_PUSHBYTES(Data(repeating: 0x00, count: 33)), .OP_1],
      [.OP_1, .OP_PUSHBYTES(Data(repeating: 0x00, count: 34)), .OP_1],
      [.OP_1, .OP_PUSHBYTES(Data(repeating: 0x00, count: 65)), .OP_PUSHBYTES(Data(repeating: 0x00, count: 41)), .OP_2, .OP_CHECKMULTISIG],
      [.OP_1, .OP_PUSHBYTES(Data(repeating: 0x00, count: 1))]
    ],
    [
      Data(hex: "0x5421000000000000000000000000000000000000000000000000000000000000000000210000000000000000000000000000000000000000000000000000000000000000002100000000000000000000000000000000000000000000000000000000000000000053ae"),
      Data(hex: "0x522100000000000000000000000000000000000000000000000000000000000000000029000000000000000000000000000000000000000000000000000000000000000000000000000000000053ae"),
      Data(hex: "0x512100000000000000000000000000000000000000000000000000000000000000000051"),
      Data(hex: "0x51220000000000000000000000000000000000000000000000000000000000000000000051"),
      Data(hex: "0x5141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000029000000000000000000000000000000000000000000000000000000000000000000000000000000000052ae"),
      Data(hex: "0x510100"),
    ]
  ))
  func encodeNonStandardScript(asm: [Bitcoin.Op], expected: Data) async throws {
    let encoder = Bitcoin.Encoder()
    let script = Bitcoin.Script(asm: asm)
    let data = try encoder.encode(script)
    #expect(data == expected)
  }
  
  @Test("Different push bytes script encoding/decoding roundtrip")
  func differentPushBytes() async throws {
    let hex = "0x4c03ffffff4d0500ffffffffff4e08000000ffffffffffffffff20ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4d0200ffff"
    let hexData = Data(hex: hex)
    let decoder = Bitcoin.ScriptDecoder()
    let decodedScript = try decoder.decode(Bitcoin.Script.self, from: hexData)
    
    let script = Bitcoin.Script(asm: [
      .OP_PUSHDATA1(Data(repeating: 0xFF, count: 3)),
      .OP_PUSHDATA2(Data(repeating: 0xFF, count: 5)),
      .OP_PUSHDATA4(Data(repeating: 0xFF, count: 8)),
      .OP_PUSHBYTES(Data(repeating: 0xFF, count: 32)),
      .OP_PUSHDATA2(Data(repeating: 0xFF, count: 2)),
    ])
    
    #expect(script == decodedScript)
    
    let encoder = Bitcoin.Encoder()
    let data = try encoder.encode(script)
    
    #expect(data == hexData)
  }
}

@Suite("Bitcoin.Encoder Bitcoin.Transaction.Output tests")
fileprivate struct EncoderTransactionOutputTests {
  @Test("tx output roundtrip", arguments: [
    Data(hex: "0xb80b00000000000017a9144e08faafb3244ae31492a3041cc29239d6fc215b87"),
    Data(hex: "0xdb03000000000000160014becb2a1cb327c74b96b1b5e4944f3155fa387939")
  ])
  func outputRoundtrip(original: Data) async throws {
    let decoder = Bitcoin.OutputDecoder()
    let output = try decoder.decode(Bitcoin.Transaction.Output.self, from: original)
    
    let encoder = Bitcoin.Encoder()
    let encoded = try encoder.encode(output)
    
    #expect(original == encoded)
  }
}

@Suite("Bitcoin.Encoder Bitcoin.Transaction.Input tests")
fileprivate struct EncoderTransactionInputTests {
  @Test("tx input roundtrip", arguments: [
    Data(hex: "0xfe75e238b96de138cff8297b65bc0cfd0587ca6a190e51d4c9205ee06ebc8ffa0300000000fdffffff"),
    Data(hex: "0x5aad8dd36cc3fbedcf225aae271873d98896adecfd419076e2dc7b82c0d854020300000000fdffffff"),
    Data(hex: "0x1f2ea84ef60e5172b036fda0caba09d7244cce6c40b30f41070d7d04dadf4c6e0300000000fdffffff"),
  ])
  func intputRoundtrip(original: Data) async throws {
    let decoder = Bitcoin.InputDecoder()
    let output = try decoder.decode(Bitcoin.Transaction.Input.self, from: original)
    
    let encoder = Bitcoin.Encoder()
    let encoded = try encoder.encode(output)
    #expect(original == encoded)
  }
}

@Suite("Bitcoin.Encoder Bitcoin.Transaction tests")
fileprivate struct EncoderTransactionTests {
  @Test("tx roundtrip", arguments: [
    Data(hex: "0x0200000003fe75e238b96de138cff8297b65bc0cfd0587ca6a190e51d4c9205ee06ebc8ffa0300000000fdffffff5aad8dd36cc3fbedcf225aae271873d98896adecfd419076e2dc7b82c0d854020300000000fdffffff1f2ea84ef60e5172b036fda0caba09d7244cce6c40b30f41070d7d04dadf4c6e0300000000fdffffff02b80b00000000000017a9144e08faafb3244ae31492a3041cc29239d6fc215b87db03000000000000160014becb2a1cb327c74b96b1b5e4944f3155fa38793900000000"),
    Data(hex: "0x01000000000102fff7f7881a8099afa6940d42d1e7f6362bec38171ea3edf433541db4e4ad969f00000000494830450221008b9d1dc26ba6a9cb62127b02742fa9d754cd3bebf337f7a55d114c8e5cdd30be022040529b194ba3f9281a99f2b1c0a19c0489bc22ede944ccf4ecbab4cc618ef3ed01eeffffffef51e1b804cc89d182d279655c3aa89e815b1b309fe287d9b2b55d57b90ec68a0100000000ffffffff02202cb206000000001976a9148280b37df378db99f66f85c95a783a76ac7a6d5988ac9093510d000000001976a9143bde42dbee7e4dbe6a21b2d50ce2f0167faa815988ac000247304402203609e17b84f6a7d30c80bfa610b5b4542f32a8a0d5447a12fb1366d7f01cc44a0220573a954c4518331561406f90300e8f3358f51928d43c212a8caed02de67eebee0121025476c2e83188368da1ff3e292e7acafcdb3566bb0ad253f62fc70f07aeee635711000000")
  ])
  func txRoundtrip(original: Data) async throws {
    let decoder = Bitcoin.Decoder()
    let tx = try decoder.decode(Bitcoin.Transaction.self, from: original)
    
    let encoder = Bitcoin.Encoder()
    let encoded = try encoder.encode(tx)
    
    #expect(original == encoded)
  }
}
