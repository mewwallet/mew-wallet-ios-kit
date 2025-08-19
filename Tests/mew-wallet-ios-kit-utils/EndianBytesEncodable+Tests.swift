//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/9/25.
//

import Foundation
import Testing
import BigInt
@testable import mew_wallet_ios_kit_utils

@Suite("EndianBytesEncodable tests")
fileprivate struct SolanaTransactionCompileMessageTests {
  @Test("UInt16 + LittleEndianBytesEncodable")
  func testUInt16LittleEndian() async throws  {
    let value: UInt16 = 0x1234
    #expect(value.littleEndianBytes == [0x34, 0x12])
  }
  
  @Test("UInt16 + BigEndianBytesEncodable")
  func testUInt16BigEndian() async throws  {
    let value: UInt16 = 0x1234
    #expect(value.bigEndianBytes == [0x12, 0x34])
  }
  
  @Test("UInt32 + LittleEndianBytesEncodable")
  func testUInt32LittleEndian() async throws  {
    let value: UInt32 = 0x11223344
    #expect(value.littleEndianBytes == [0x44, 0x33, 0x22, 0x11])
  }
  
  @Test("UInt32 + BigEndianBytesEncodable")
  func testUInt32BigEndian() async throws  {
    let value: UInt32 = 0x11223344
    #expect(value.bigEndianBytes == [0x11, 0x22, 0x33, 0x44])
  }
  
  @Test("Bool + LittleEndianBytesEncodable")
  func testBoolLittleEndian() async throws  {
    #expect(true.littleEndianBytes == [0x01])
    #expect(false.littleEndianBytes == [0x00])
  }
  
  @Test("Bool + BigEndianBytesEncodable")
  func testBoolBigEndian() async throws  {
    #expect(true.bigEndianBytes == [0x01])
    #expect(false.bigEndianBytes == [0x00])
  }
  
  @Test("Data + LittleEndianBytesEncodable")
  func testDataLittleEndian() async throws  {
    let data = Data([0xDE, 0xAD, 0xBE, 0xEF])
    #expect(data.littleEndianBytes == [0xDE, 0xAD, 0xBE, 0xEF])
  }
  
  @Test("Data + BigEndianBytesEncodable")
  func testDataBigEndian() async throws {
    let data = Data([0xDE, 0xAD, 0xBE, 0xEF])
    #expect(data.bigEndianBytes == [0xDE, 0xAD, 0xBE, 0xEF])
  }
  
  @Test("Sequence + LittleEndianBytesEncodable")
  func testSequenceLittleEndian() async throws  {
    let values: [UInt16] = [0x1234, 0xABCD]
    #expect(values.littleEndianBytes == [0x34, 0x12, 0xCD, 0xAB])
  }
  
  @Test("Sequence + BigEndianBytesEncodable")
  func testSequenceBigEndian() async throws  {
    let values: [UInt16] = [0x1234, 0xABCD]
    #expect(values.bigEndianBytes == [0x12, 0x34, 0xAB, 0xCD])
  }
  
  @Test("Mixed types + LittleEndianBytesEncodable")
  func testMixedTypesLittleEndianEncodableArray() async throws  {
    typealias EndianBytesEncodable = BigEndianBytesEncodable & LittleEndianBytesEncodable
    
    let mixed: [any EndianBytesEncodable] = [
      UInt8(0xAA),
      UInt16(0x1234),
      true,
      Data([0xDE, 0xAD])
    ]
    
    let le = mixed.flatMap { $0.littleEndianBytes }
    #expect(le == [
      0xAA,       // UInt8
      0x34, 0x12, // UInt16
      0x01,       // Bool true
      0xDE, 0xAD  // Data
    ])
  }
  
  @Test("Mixed types + BigEndianBytesEncodable")
  func testMixedTypesBigEndianEncodableArray() async throws  {
    typealias EndianBytesEncodable = BigEndianBytesEncodable & LittleEndianBytesEncodable
    
    let mixed: [any EndianBytesEncodable] = [
      UInt8(0xAA),
      UInt16(0x1234),
      true,
      Data([0xDE, 0xAD])
    ]
    
    let be = mixed.flatMap { $0.bigEndianBytes }
    #expect(be == [
      0xAA,       // UInt8
      0x12, 0x34, // UInt16
      0x01,       // Bool true
      0xDE, 0xAD  // Data
    ])
    }
  
  // MARK: - BigInt/BigUInt
  
  @Test("BigUInt Short Roundtrip (LE <-> BE) + EndianBytesEncodable")
  func testBigUIntLE_BE_Short() {
    let u = BigUInt(0x01020304)
    
    // endian bytes
    #expect(u.bigEndianBytes == [0x01, 0x02, 0x03, 0x04])
    #expect(u.littleEndianBytes == [0x04, 0x03, 0x02, 0x01])
    
    // round-trip from BE bytes
    let rtBE = BigUInt(Data(u.bigEndianBytes))
    #expect(rtBE == u)
    
    // round-trip from LE bytes (reverse to BE for constructor)
    let rtLE = BigUInt(Data(u.littleEndianBytes.reversed()))
    #expect(rtLE == u)
  }
  
  @Test("BigUInt Long Roundtrip (LE <-> BE) + EndianBytesEncodable")
  func testBigUIntLE_BE_Long() {
    // 0x01 02 03 04 05 06 07 08 09 0A
    let hex = "0102030405060708090A"
    let uHex = BigUInt(hex, radix: 16)!
    
    // endian bytes
    #expect(uHex.bigEndianBytes == [0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A])
    #expect(uHex.littleEndianBytes == [0x0A,0x09,0x08,0x07,0x06,0x05,0x04,0x03,0x02,0x01])
    
    // round-trip from BE bytes
    let rtBE = BigUInt(Data(uHex.bigEndianBytes))
    #expect(rtBE == uHex)
    
    // round-trip from LE bytes (reverse to BE for constructor)
    let rtLE = BigUInt(Data(uHex.littleEndianBytes.reversed()))
    #expect(rtLE == uHex)
    
    // no unexpected leading zeros in BE serialization
    #expect(uHex.bigEndianBytes.first != 0)
  }
  
  @Test("BigInt Roundtrip (LE <-> BE) + EndianBytesEncodable")
  func testBigIntUsesMagnitude() {
    let pos = BigInt(0x0102)
    let neg = BigInt(-0x0102)
    
    // magnitude-based encoding (no two’s complement)
    #expect(pos.bigEndianBytes == [0x01, 0x02])
    #expect(pos.littleEndianBytes == [0x02, 0x01])
    #expect(neg.bigEndianBytes == [0x01, 0x02])
    #expect(neg.littleEndianBytes == [0x02, 0x01])
    
    // round-trip via BigUInt using magnitude bytes
    let posRT = BigUInt(Data(pos.bigEndianBytes))
    let negRT = BigUInt(Data(neg.bigEndianBytes))
    #expect(posRT == BigUInt(0x0102))
    #expect(negRT == BigUInt(0x0102))
  }
}
