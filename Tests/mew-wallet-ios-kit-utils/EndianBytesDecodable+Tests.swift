//
//  EndianBytesDecodable+Tests.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/19/25.
//

import Foundation
import Testing
import BigInt
@testable import mew_wallet_ios_kit_utils

@Suite("EndianBytesDecodable tests")
fileprivate struct EndianBytesDecodableTests {
  
  // Enums with automatic EndianBytesDecodable conformance
  private enum OpCode: UInt16, EndianBytesDecodable {
    case load  = 0x1234
    case store = 0xABCD
  }
  
  private enum WideCode: UInt32, EndianBytesDecodable {
    case a = 0x01020304
    case b = 0xA1B2C3D4
  }

  // MARK: - Array Decoding Tests
  
  @Test("Array decoding with cursor - UInt16 big-endian")
  func testArrayDecodingWithCursorBigEndian() async throws {
    // Example: [0x1234, 0x5678, 0x9ABC]
    let bytes: [UInt8] = [0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC]
    var cursor = 0
    
    let decoded = UInt16.decodeArrayBigEndian(size: 3, type: UInt16.self, from: bytes, cursor: &cursor)
    
    #expect(decoded != nil)
    #expect(decoded?.count == 3)
    #expect(decoded?[0] == 0x1234)
    #expect(decoded?[1] == 0x5678)
    #expect(decoded?[2] == 0x9ABC)
    #expect(cursor == 6) // Should have advanced by 6 bytes (3 * 2 bytes each)
  }
  
  @Test("Array decoding with cursor - UInt32 little-endian")
  func testArrayDecodingWithCursorLittleEndian() async throws {
    // Example: [0x11223344, 0x55667788]
    let bytes: [UInt8] = [0x44, 0x33, 0x22, 0x11, 0x88, 0x77, 0x66, 0x55]
    var cursor = 0
    
    let decoded = UInt32.decodeArrayLittleEndian(size: 2, type: UInt32.self, from: bytes, cursor: &cursor)
    
    #expect(decoded != nil)
    #expect(decoded?.count == 2)
    #expect(decoded?[0] == 0x11223344)
    #expect(decoded?[1] == 0x55667788)
    #expect(cursor == 8) // Should have advanced by 8 bytes (2 * 4 bytes each)
  }
  
  @Test("Array decoding with cursor - Mixed types")
  func testArrayDecodingWithCursorMixedTypes() async throws {
    // Example: [UInt16(0x1234), Bool(true), UInt16(0x5678)]
    let bytes: [UInt8] = [0x12, 0x34, 0x01, 0x56, 0x78]
    var cursor = 0
    
    // Decode first UInt16
    let first = UInt16.decode(fromBigEndian: bytes, cursor: &cursor)
    #expect(first == 0x1234)
    #expect(cursor == 2)
    
    // Decode Bool
    let bool = Bool.decode(fromBigEndian: bytes, cursor: &cursor)
    #expect(bool == true)
    #expect(cursor == 3)
    
    // Decode second UInt16
    let second = UInt16.decode(fromBigEndian: bytes, cursor: &cursor)
    #expect(second == 0x5678)
    #expect(cursor == 5)
  }
  
  @Test("Mixed type decoding with DecodeContext")
  func testMixedTypeDecodingWithContext() async throws {
    // Example: [UInt16(0x1234), Bool(true), UInt32(0x55667788), UInt16(0x9ABC)]
    // Big-endian: [0x12, 0x34, 0x01, 0x55, 0x66, 0x77, 0x88, 0x9A, 0xBC]
    let bytes: [UInt8] = [0x12, 0x34, 0x01, 0x55, 0x66, 0x77, 0x88, 0x9A, 0xBC]
    
    let contexts: [any DecodeContextProtocol] = [
      DecodeContext.bigEndian(size: 1, type: UInt16.self),  // 0x1234
      DecodeContext.bigEndian(size: 1, type: Bool.self),    // true
      DecodeContext.bigEndian(size: 1, type: UInt32.self),  // 0x55667788
      DecodeContext.bigEndian(size: 1, type: UInt16.self)   // 0x9ABC
    ]
    
    let decoded = bytes.decode(contexts: contexts)

    #expect(decoded != nil)
    #expect(decoded?.count == 4)
    
    // Verify the decoded values
    if let result = decoded {
      #expect(result[0] as? UInt16 == 0x1234)
      #expect(result[1] as? Bool == true)
      #expect(result[2] as? UInt32 == 0x55667788)
      #expect(result[3] as? UInt16 == 0x9ABC)
    }
  }
  
  @Test("Mixed endianness decoding with DecodeContext")
  func testMixedEndiannessDecodingWithContext() async throws {
    // Example: [UInt16 big-endian(0x1234), UInt32 little-endian(0x55667788)]
    // Bytes: [0x12, 0x34, 0x88, 0x77, 0x66, 0x55]
    let bytes: [UInt8] = [0x12, 0x34, 0x88, 0x77, 0x66, 0x55]
    
    let contexts: [any DecodeContextProtocol] = [
      DecodeContext.bigEndian(size: 1, type: UInt16.self),     // 0x1234 (big-endian)
      DecodeContext.littleEndian(size: 1, type: UInt32.self)   // 0x55667788 (little-endian)
    ]
    
    let decoded = bytes.decode(contexts: contexts)

    #expect(decoded != nil)
    #expect(decoded?.count == 2)
    
    // Verify the decoded values
    if let result = decoded {
      #expect(result[0] as? UInt16 == 0x1234)
      #expect(result[1] as? UInt32 == 0x55667788)
    }
  }
  
  @Test("Multiple elements of same type with DecodeContext")
  func testMultipleElementsSameTypeWithContext() async throws {
    // Example: [3 × UInt16, 2 × Bool]
    // Bytes: [0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0x01, 0x00]
    let bytes: [UInt8] = [0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0x01, 0x00]
    
    let contexts: [any DecodeContextProtocol] = [
      DecodeContext.bigEndian(size: 3, type: UInt16.self),  // 3 UInt16s
      DecodeContext.bigEndian(size: 2, type: Bool.self)     // 2 Bools
    ]
    
    let decoded = bytes.decode(contexts: contexts)

    #expect(decoded != nil)
    #expect(decoded?.count == 5) // 3 UInt16s + 2 Bools = 5 total elements
    
    // Verify the decoded values
    if let result = decoded {
      #expect(result[0] as? UInt16 == 0x1234)
      #expect(result[1] as? UInt16 == 0x5678)
      #expect(result[2] as? UInt16 == 0x9ABC)
      #expect(result[3] as? Bool == true)
      #expect(result[4] as? Bool == false)
    }
  }
  
  @Test("Enum decoding with DecodeContext - using raw value types")
  func testEnumDecodingWithContext() async throws {
    // Example: [OpCode.load, OpCode.store, WideCode.a]
    // Bytes: [0x12, 0x34, 0xCD, 0xAB, 0x01, 0x02, 0x03, 0x04] (big-endian)
    let bytes: [UInt8] = [0x12, 0x34, 0xCD, 0xAB, 0x01, 0x02, 0x03, 0x04]
    
    // Use the raw value types (UInt16, UInt32) which conform to EndianBytesDecodable
    let contexts: [any DecodeContextProtocol] = [
      DecodeContext.bigEndian(size: 2, type: UInt16.self),   // 2 UInt16s (OpCode raw values)
      DecodeContext.bigEndian(size: 1, type: UInt32.self)    // 1 UInt32 (WideCode raw value)
    ]
    
    let decoded = bytes.decode(contexts: contexts)

    #expect(decoded != nil)
    #expect(decoded?.count == 3) // 2 UInt16s + 1 UInt32 = 3 total elements
    
    // Verify the decoded raw values
    if let result = decoded {
      #expect(result[0] as? UInt16 == 0x1234)  // OpCode.load.rawValue (0x12, 0x34)
      #expect(result[1] as? UInt16 == 0xCDAB)  // OpCode.store.rawValue (0xCD, 0xAB) - big-endian order
      #expect(result[2] as? UInt32 == 0x01020304) // WideCode.a.rawValue (0x01, 0x02, 0x03, 0x04)
    }
  }
  
  @Test("Enum decoding with DecodeContext - direct enum types")
  func testEnumDecodingDirectTypes() async throws {
    // Example: [OpCode.load, OpCode.store, WideCode.a]
    // Bytes: [0x12, 0x34, 0xAB, 0xCD, 0x01, 0x02, 0x03, 0x04] (big-endian)
    let bytes: [UInt8] = [0x12, 0x34, 0xAB, 0xCD, 0x01, 0x02, 0x03, 0x04]
    
    // Now we can use the actual enum types directly!
    let contexts: [any DecodeContextProtocol] = [
      DecodeContext.bigEndian(size: 2, type: OpCode.self),   // 2 OpCodes
      DecodeContext.bigEndian(size: 1, type: WideCode.self)  // 1 WideCode
    ]

    let decoded = bytes.decode(contexts: contexts)

    #expect(decoded != nil)
    #expect(decoded?.count == 3) // 2 OpCodes + 1 WideCode = 3 total elements
    
    // Verify the decoded enum values
    if let result = decoded {
      #expect(result[0] as? OpCode == .load)      // OpCode.load
      #expect(result[1] as? OpCode == .store)     // OpCode.store
      #expect(result[2] as? WideCode == .a)       // WideCode.a
    }
  }
  
  // MARK: - Golden Tests (Mirror of Encoding Tests)
  
  @Test("Golden test - UInt16 + LittleEndianBytesDecodable")
  func testGoldenUInt16LittleEndian() async throws {
    let bytes: [UInt8] = [0x34, 0x12]  // Little-endian for 0x1234
    let decoded = UInt16.decode(fromLittleEndian: bytes)
    #expect(decoded == 0x1234)
  }
  
  @Test("Golden test - UInt16 + BigEndianBytesDecodable")
  func testGoldenUInt16BigEndian() async throws {
    let bytes: [UInt8] = [0x12, 0x34]  // Big-endian for 0x1234
    let decoded = UInt16.decode(fromBigEndian: bytes)
    #expect(decoded == 0x1234)
  }
  
  @Test("Golden test - UInt32 + LittleEndianBytesDecodable")
  func testGoldenUInt32LittleEndian() async throws {
    let bytes: [UInt8] = [0x44, 0x33, 0x22, 0x11]  // Little-endian for 0x11223344
    let decoded = UInt32.decode(fromLittleEndian: bytes)
    #expect(decoded == 0x11223344)
  }
  
  @Test("Golden test - UInt32 + BigEndianBytesDecodable")
  func testGoldenUInt32BigEndian() async throws {
    let bytes: [UInt8] = [0x11, 0x22, 0x33, 0x44]  // Big-endian for 0x11223344
    let decoded = UInt32.decode(fromBigEndian: bytes)
    #expect(decoded == 0x11223344)
  }
  
  @Test("Golden test - Bool + LittleEndianBytesDecodable")
  func testGoldenBoolLittleEndian() async throws {
    let trueBytes: [UInt8] = [0x01]
    let falseBytes: [UInt8] = [0x00]
    
    let decodedTrue = Bool.decode(fromLittleEndian: trueBytes)
    let decodedFalse = Bool.decode(fromLittleEndian: falseBytes)
    
    #expect(decodedTrue == true)
    #expect(decodedFalse == false)
  }
  
  @Test("Golden test - Bool + BigEndianBytesDecodable")
  func testGoldenBoolBigEndian() async throws {
    let trueBytes: [UInt8] = [0x01]
    let falseBytes: [UInt8] = [0x00]
    
    let decodedTrue = Bool.decode(fromBigEndian: trueBytes)
    let decodedFalse = Bool.decode(fromBigEndian: falseBytes)
    
    #expect(decodedTrue == true)
    #expect(decodedFalse == false)
  }
  
  @Test("Golden test - Data + LittleEndianBytesDecodable")
  func testGoldenDataLittleEndian() async throws {
    let bytes: [UInt8] = [0xDE, 0xAD, 0xBE, 0xEF]
    let decoded = Data.decode(fromLittleEndian: bytes)
    #expect(decoded == Data([0xDE, 0xAD, 0xBE, 0xEF]))
  }
  
  @Test("Golden test - Data + BigEndianBytesDecodable")
  func testGoldenDataBigEndian() async throws {
    let bytes: [UInt8] = [0xDE, 0xAD, 0xBE, 0xEF]
    let decoded = Data.decode(fromBigEndian: bytes)
    #expect(decoded == Data([0xDE, 0xAD, 0xBE, 0xEF]))
  }
  
  @Test("Golden test - Sequence + LittleEndianBytesDecodable")
  func testGoldenSequenceLittleEndian() async throws {
    let bytes: [UInt8] = [0x34, 0x12, 0xCD, 0xAB]  // Little-endian for [0x1234, 0xABCD]
    var cursor = 0
    
    let first = UInt16.decode(fromLittleEndian: bytes, cursor: &cursor)
    let second = UInt16.decode(fromLittleEndian: bytes, cursor: &cursor)
    
    #expect(first == 0x1234)
    #expect(second == 0xABCD)
    #expect(cursor == 4)
  }
  
  @Test("Golden test - Sequence + BigEndianBytesDecodable")
  func testGoldenSequenceBigEndian() async throws {
    let bytes: [UInt8] = [0x12, 0x34, 0xAB, 0xCD]  // Big-endian for [0x1234, 0xABCD]
    var cursor = 0
    
    let first = UInt16.decode(fromBigEndian: bytes, cursor: &cursor)
    let second = UInt16.decode(fromBigEndian: bytes, cursor: &cursor)
    
    #expect(first == 0x1234)
    #expect(second == 0xABCD)
    #expect(cursor == 4)
  }
  
  @Test("Golden test - Mixed types + LittleEndianBytesDecodable")
  func testGoldenMixedTypesLittleEndian() async throws {
    let bytes: [UInt8] = [
      0xAA,       // UInt8
      0x34, 0x12, // UInt16 (little-endian)
      0x01,       // Bool true
      0xDE, 0xAD  // Data
    ]
    var cursor = 0
    
    let uint8 = UInt8.decode(fromLittleEndian: bytes, cursor: &cursor)
    let uint16 = UInt16.decode(fromLittleEndian: bytes, cursor: &cursor)
    let bool = Bool.decode(fromLittleEndian: bytes, cursor: &cursor)
    // Data cursor-based decoding is not implemented, so we'll test the non-cursor version
    let data = Data.decode(fromLittleEndian: Array(bytes[cursor...]))
    
    #expect(uint8 == 0xAA)
    #expect(uint16 == 0x1234)
    #expect(bool == true)
    #expect(data == Data([0xDE, 0xAD]))
    #expect(cursor == 4) // UInt8(1) + UInt16(2) + Bool(1) = 4 bytes
  }
  
  @Test("Golden test - Mixed types + BigEndianBytesDecodable")
  func testGoldenMixedTypesBigEndian() async throws {
    let bytes: [UInt8] = [
      0xAA,       // UInt8
      0x12, 0x34, // UInt16 (big-endian)
      0x01,       // Bool true
      0xDE, 0xAD  // Data
    ]
    var cursor = 0
    
    let uint8 = UInt8.decode(fromBigEndian: bytes, cursor: &cursor)
    let uint16 = UInt16.decode(fromBigEndian: bytes, cursor: &cursor)
    let bool = Bool.decode(fromBigEndian: bytes, cursor: &cursor)
    // Data cursor-based decoding is not implemented, so we'll test the non-cursor version
    let data = Data.decode(fromBigEndian: Array(bytes[cursor...]))
    
    #expect(uint8 == 0xAA)
    #expect(uint16 == 0x1234)
    #expect(bool == true)
    #expect(data == Data([0xDE, 0xAD]))
    #expect(cursor == 4) // UInt8(1) + UInt16(2) + Bool(1) = 4 bytes
  }
  
  @Test("Golden test - Mixed types + DecodeContext BigEndian")
  func testGoldenMixedTypesDecodeContextBigEndian() async throws {
    let bytes: [UInt8] = [
      0xAA,       // UInt8
      0x12, 0x34, // UInt16 (big-endian)
      0x01,       // Bool true
      0xDE, 0xAD  // Data
    ]
    
    let contexts: [any DecodeContextProtocol] = [
      DecodeContext.bigEndian(size: 1, type: UInt8.self),   // 1 UInt8
      DecodeContext.bigEndian(size: 1, type: UInt16.self),  // 1 UInt16
      DecodeContext.bigEndian(size: 1, type: Bool.self),    // 1 Bool
      DecodeContext.bigEndian(size: 2, type: Data.self)     // 1 Data (2 bytes)
    ]
    
    let decoded = bytes.decode(contexts: contexts)
    
    #expect(decoded != nil)
    #expect(decoded?.count == 4) // 1 + 1 + 1 + 1 = 4 total elements
    
    if let result = decoded {
      #expect(result[0] as? UInt8 == 0xAA)
      #expect(result[1] as? UInt16 == 0x1234)
      #expect(result[2] as? Bool == true)
      #expect(result[3] as? Data == Data([0xDE, 0xAD]))
    }
  }
  
  @Test("Golden test - Mixed types + DecodeContext LittleEndian")
  func testGoldenMixedTypesDecodeContextLittleEndian() async throws {
    let bytes: [UInt8] = [
      0xAA,       // UInt8
      0x34, 0x12, // UInt16 (little-endian)
      0x01,       // Bool true
      0xDE, 0xAD  // Data
    ]
    
    let contexts: [any DecodeContextProtocol] = [
      DecodeContext.littleEndian(size: 1, type: UInt8.self),   // 1 UInt8
      DecodeContext.littleEndian(size: 1, type: UInt16.self),  // 1 UInt16
      DecodeContext.littleEndian(size: 1, type: Bool.self),    // 1 Bool
      DecodeContext.littleEndian(size: 2, type: Data.self)     // 1 Data (2 bytes)
    ]
    
    let decoded = bytes.decode(contexts: contexts)
    
    #expect(decoded != nil)
    #expect(decoded?.count == 4) // 1 + 1 + 1 + 1 = 4 total elements
    
    if let result = decoded {
      #expect(result[0] as? UInt8 == 0xAA)
      #expect(result[1] as? UInt16 == 0x1234)
      #expect(result[2] as? Bool == true)
      #expect(result[3] as? Data == Data([0xDE, 0xAD]))
    }
  }
  
  @Test("Golden test - BigUInt + LittleEndianBytesDecodable")
  func testGoldenBigUIntLittleEndian() async throws {
    let bytes: [UInt8] = [0x04, 0x03, 0x02, 0x01]  // Little-endian for 0x01020304
    let decoded = BigUInt.decode(fromLittleEndian: bytes)
    #expect(decoded == BigUInt(0x01020304))
  }
  
  @Test("Golden test - BigUInt + BigEndianBytesDecodable")
  func testGoldenBigUIntBigEndian() async throws {
    let bytes: [UInt8] = [0x01, 0x02, 0x03, 0x04]  // Big-endian for 0x01020304
    let decoded = BigUInt.decode(fromBigEndian: bytes)
    #expect(decoded == BigUInt(0x01020304))
  }
  
  @Test("Golden test - Sequence + DecodeContext LittleEndian")
  func testGoldenSequenceDecodeContextLittleEndian() async throws {
    let bytes: [UInt8] = [0x34, 0x12, 0xCD, 0xAB]  // Little-endian for [0x1234, 0xABCD]
    
    let contexts: [any DecodeContextProtocol] = [
      DecodeContext.littleEndian(size: 2, type: UInt16.self)  // 2 UInt16s
    ]
    
    let decoded = bytes.decode(contexts: contexts)
    
    #expect(decoded != nil)
    #expect(decoded?.count == 2)
    
    if let result = decoded {
      #expect(result[0] as? UInt16 == 0x1234)
      #expect(result[1] as? UInt16 == 0xABCD)
    }
  }
  
  @Test("Golden test - Sequence + DecodeContext BigEndian")
  func testGoldenSequenceDecodeContextBigEndian() async throws {
    let bytes: [UInt8] = [0x12, 0x34, 0xAB, 0xCD]  // Big-endian for [0x1234, 0xABCD]
    
    let contexts: [any DecodeContextProtocol] = [
      DecodeContext.bigEndian(size: 2, type: UInt16.self)  // 2 UInt16s
    ]
    
    let decoded = bytes.decode(contexts: contexts)
    
    #expect(decoded != nil)
    #expect(decoded?.count == 2)
    
    if let result = decoded {
      #expect(result[0] as? UInt16 == 0x1234)
      #expect(result[1] as? UInt16 == 0xABCD)
    }
  }
  
  @Test("Golden test - Roundtrip validation")
  func testGoldenRoundtrip() async throws {
    // Test that encoding then decoding gives us back the same value
    let original: UInt16 = 0x1234
    
    // Encode to big-endian
    let encoded = original.bigEndianBytes
    #expect(encoded == [0x12, 0x34])
    
    // Decode from big-endian
    let decoded = UInt16.decode(fromBigEndian: encoded)
    #expect(decoded == original)
    
    // Encode to little-endian
    let encodedLE = original.littleEndianBytes
    #expect(encodedLE == [0x34, 0x12])
    
    // Decode from little-endian
    let decodedLE = UInt16.decode(fromLittleEndian: encodedLE)
    #expect(decodedLE == original)
  }
}
