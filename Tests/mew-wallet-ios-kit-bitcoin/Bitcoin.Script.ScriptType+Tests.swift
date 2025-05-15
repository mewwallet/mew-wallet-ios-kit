//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/17/25.
//

import Foundation
import Testing
@testable import mew_wallet_ios_kit_bitcoin

@Suite("Bitcoin.Script.ScriptType tests")
fileprivate struct ScriptTypeTests {
  
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
  @Test(
    "pubkey valid", arguments: [[Bitcoin.Op]]([
      [.OP_PUSHBYTES(Data(repeating: 0x00, count: 33)), .OP_CHECKSIG],
      [.OP_PUSHBYTES(Data(repeating: 0x00, count: 65)), .OP_CHECKSIG],
    ])
  )
  func pubkey(asm: [Bitcoin.Op]) async throws {
    let type = Bitcoin.Script.ScriptType(asm: asm)
    #expect(type == .pubkey)
  }
  
  @Test(
    "pubkey invalid", arguments: [[Bitcoin.Op]]([
      [.OP_PUSHBYTES(Data(repeating: 0x00, count: 30)), .OP_CHECKSIG],
      [.OP_PUSHBYTES(Data(repeating: 0x00, count: 40)), .OP_CHECKSIG],
    ])
  )
  func nonstandard_pubkey(asm: [Bitcoin.Op]) async throws {
    let type = Bitcoin.Script.ScriptType(asm: asm)
    #expect(type == .nonstandard)
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
  @Test(
    "pubkeyhash valid", arguments: [[Bitcoin.Op]]([
      [.OP_DUP, .OP_HASH160, .OP_PUSHBYTES(Data(repeating: 0x00, count: 20)), .OP_EQUALVERIFY, .OP_CHECKSIG],
    ])
  )
  func pubkeyhash(asm: [Bitcoin.Op]) async throws {
    let type = Bitcoin.Script.ScriptType(asm: asm)
    #expect(type == .pubkeyhash)
  }
  
  @Test(
    "pubkeyhash invalid", arguments: [[Bitcoin.Op]]([
      [.OP_DUP, .OP_HASH160, .OP_PUSHBYTES(Data(repeating: 0x00, count: 32)), .OP_EQUALVERIFY, .OP_CHECKSIG],
    ])
  )
  func nonstandard_pubkeyhash(asm: [Bitcoin.Op]) async throws {
    let type = Bitcoin.Script.ScriptType(asm: asm)
    #expect(type == .nonstandard)
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
  @Test(
    "scripthash valid", arguments: [[Bitcoin.Op]]([
      [.OP_HASH160, .OP_PUSHBYTES(Data(repeating: 0x00, count: 20)), .OP_EQUAL],
    ])
  )
  func scripthash(asm: [Bitcoin.Op]) async throws {
    let type = Bitcoin.Script.ScriptType(asm: asm)
    #expect(type == .scripthash)
  }
  
  @Test(
    "scripthash invalid", arguments: [[Bitcoin.Op]]([
      [.OP_HASH160, .OP_PUSHBYTES(Data(repeating: 0x00, count: 32)), .OP_EQUAL],
    ])
  )
  func nonstandard_scripthash(asm: [Bitcoin.Op]) async throws {
    let type = Bitcoin.Script.ScriptType(asm: asm)
    #expect(type == .nonstandard)
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
  @Test(
    "multisig valid", arguments: [[Bitcoin.Op]]([
      [.OP_1, .OP_PUSHBYTES(Data(repeating: 0x00, count: 33)), .OP_PUSHBYTES(Data(repeating: 0x00, count: 33)), .OP_PUSHBYTES(Data(repeating: 0x00, count: 33)), .OP_3, .OP_CHECKMULTISIG],
      [.OP_2, .OP_PUSHBYTES(Data(repeating: 0x00, count: 33)), .OP_PUSHBYTES(Data(repeating: 0x00, count: 65)), .OP_2, .OP_CHECKMULTISIG],
      [.OP_1, .OP_PUSHBYTES(Data(repeating: 0x00, count: 33)), .OP_1, .OP_CHECKMULTISIG],
      [.OP_1, .OP_PUSHBYTES(Data(repeating: 0x00, count: 65)), .OP_PUSHBYTES(Data(repeating: 0x00, count: 65)), .OP_2, .OP_CHECKMULTISIG],
    ])
  )
  func multisig(asm: [Bitcoin.Op]) async throws {
    let type = Bitcoin.Script.ScriptType(asm: asm)
    #expect(type == .multisig)
  }
  
  @Test(
    "multisig invalid", arguments: [[Bitcoin.Op]]([
      [.OP_4, .OP_PUSHBYTES(Data(repeating: 0x00, count: 33)), .OP_PUSHBYTES(Data(repeating: 0x00, count: 33)), .OP_PUSHBYTES(Data(repeating: 0x00, count: 33)), .OP_3, .OP_CHECKMULTISIG],
      [.OP_2, .OP_PUSHBYTES(Data(repeating: 0x00, count: 33)), .OP_PUSHBYTES(Data(repeating: 0x00, count: 41)), .OP_3, .OP_CHECKMULTISIG],
      [.OP_1, .OP_PUSHBYTES(Data(repeating: 0x00, count: 33)), .OP_1],
      [.OP_1, .OP_PUSHBYTES(Data(repeating: 0x00, count: 34)), .OP_1],
      [.OP_1, .OP_PUSHBYTES(Data(repeating: 0x00, count: 65)), .OP_PUSHBYTES(Data(repeating: 0x00, count: 41)), .OP_2, .OP_CHECKMULTISIG],
    ])
  )
  func nonstandard_multisig(asm: [Bitcoin.Op]) async throws {
    let type = Bitcoin.Script.ScriptType(asm: asm)
    #expect(type == .nonstandard)
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
  @Test(
    "nulldata valid", arguments: [[Bitcoin.Op]]([
      [.OP_RETURN],
      [.OP_RETURN, .OP_PUSHBYTES(Data(repeating: 0x00, count: 1))],
      [.OP_RETURN, .OP_PUSHBYTES(Data(repeating: 0x00, count: 80))],
    ])
  )
  func nulldata(asm: [Bitcoin.Op]) async throws {
    let type = Bitcoin.Script.ScriptType(asm: asm)
    #expect(type == .nulldata)
  }
  
  @Test(
    "nulldata invalid", arguments: [[Bitcoin.Op]]([
      [.OP_RETURN, .OP_PUSHBYTES(Data(repeating: 0x00, count: 81))]
    ])
  )
  func nonstandard_nulldata(asm: [Bitcoin.Op]) async throws {
    let type = Bitcoin.Script.ScriptType(asm: asm)
    #expect(type == .nonstandard)
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
  @Test(
    "witness_v0_keyhash valid", arguments: [[Bitcoin.Op]]([
      [.OP_0, .OP_PUSHBYTES(Data(repeating: 0x00, count: 20))]
    ])
  )
  func witness_v0_keyhash(asm: [Bitcoin.Op]) async throws {
    let type = Bitcoin.Script.ScriptType(asm: asm)
    #expect(type == .witness_v0_keyhash)
  }
  
  @Test(
    "witness_v0_keyhash invalid", arguments: [[Bitcoin.Op]]([
      [.OP_0, .OP_PUSHBYTES(Data(repeating: 0x00, count: 21))]
    ])
  )
  func nonstandard_witness_v0_keyhash(asm: [Bitcoin.Op]) async throws {
    let type = Bitcoin.Script.ScriptType(asm: asm)
    #expect(type == .nonstandard)
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
  @Test(
    "witness_v0_scripthash valid", arguments: [[Bitcoin.Op]]([
      [.OP_0, .OP_PUSHBYTES(Data(repeating: 0x00, count: 32))]
    ])
  )
  func witness_v0_scripthash(asm: [Bitcoin.Op]) async throws {
    let type = Bitcoin.Script.ScriptType(asm: asm)
    #expect(type == .witness_v0_scripthash)
  }
  
  @Test(
    "witness_v0_scripthash invalid", arguments: [[Bitcoin.Op]]([
      [.OP_0, .OP_PUSHBYTES(Data(repeating: 0x00, count: 33))]
    ])
  )
  func nonstandard_witness_v0_scripthash(asm: [Bitcoin.Op]) async throws {
    let type = Bitcoin.Script.ScriptType(asm: asm)
    #expect(type == .nonstandard)
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
  @Test(
    "witness_v1_taproot valid", arguments: [[Bitcoin.Op]]([
      [.OP_1, .OP_PUSHBYTES(Data(repeating: 0x00, count: 32))]
    ])
  )
  func witness_v1_taproot(asm: [Bitcoin.Op]) async throws {
    let type = Bitcoin.Script.ScriptType(asm: asm)
    #expect(type == .witness_v1_taproot)
  }
  
  @Test(
    "witness_v1_taproot invalid", arguments: [[Bitcoin.Op]]([
      [.OP_1, .OP_PUSHBYTES(Data(repeating: 0x00, count: 33))]
    ])
  )
  func nonstandard_witness_v1_taproot(asm: [Bitcoin.Op]) async throws {
    let type = Bitcoin.Script.ScriptType(asm: asm)
    #expect(type == .witness_unknown)
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
  @Test(
    "anchor valid", arguments: [[Bitcoin.Op]]([
      [.OP_1, .OP_PUSHBYTES(Data(repeating: 0x00, count: 2))]
    ])
  )
  func anchor(asm: [Bitcoin.Op]) async throws {
    let type = Bitcoin.Script.ScriptType(asm: asm)
    #expect(type == .anchor)
  }
  
  @Test(
    "anchor invalid", arguments: [[Bitcoin.Op]]([
      [.OP_1, .OP_PUSHBYTES(Data(repeating: 0x00, count: 1))]
    ])
  )
  func nonstandard_anchor(asm: [Bitcoin.Op]) async throws {
    let type = Bitcoin.Script.ScriptType(asm: asm)
    #expect(type == .nonstandard)
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
  @Test(
    "witness_unknown valid", arguments: [[Bitcoin.Op]]([
      [.OP_2, .OP_PUSHBYTES(Data(repeating: 0x00, count: 20))],
    ])
  )
  func witness_unknown(asm: [Bitcoin.Op]) async throws {
    let type = Bitcoin.Script.ScriptType(asm: asm)
    #expect(type == .witness_unknown)
  }
  
  @Test(
    "witness_unknown invalid", arguments: [[Bitcoin.Op]]([
      [.OP_2, .OP_PUSHBYTES(Data(repeating: 0x00, count: 1))],
      [.OP_15, .OP_PUSHBYTES(Data(repeating: 0x00, count: 41))],
    ])
  )
  func nonstandard_witness_unknown(asm: [Bitcoin.Op]) async throws {
    let type = Bitcoin.Script.ScriptType(asm: asm)
    #expect(type == .nonstandard)
  }
}
