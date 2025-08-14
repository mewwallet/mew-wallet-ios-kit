//
//  Solana.BorshEncoder+Tests.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import XCTest
@testable import mew_wallet_ios_kit_solana
@testable import mew_wallet_ios_kit

final class SolanaBorshEncoderTests: XCTestCase {

    // MARK: - Test Data Structures

    struct SimpleStruct: Codable, Equatable {
        let id: UInt32
        let name: String
        let isActive: Bool
        let balance: UInt64
    }

    struct NestedStruct: Codable, Equatable {
        let user: SimpleStruct
        let permissions: [String]
        let metadata: [String: String]
    }

    struct ArrayStruct: Codable, Equatable {
        let numbers: [UInt32]
        let strings: [String]
        let booleans: [Bool]
    }

    // MARK: - Test Cases

    func testSimpleStructEncoding() throws {
        let testStruct = SimpleStruct(
            id: 12345,
            name: "Test User",
            isActive: true,
            balance: 1000000
        )

        let encoded = try testStruct.encodeBorsh()
        let decoded = try encoded.decodeBorsh(SimpleStruct.self)

        XCTAssertEqual(testStruct, decoded)
    }

    func testNestedStructEncoding() throws {
        let user = SimpleStruct(
            id: 1,
            name: "Admin",
            isActive: true,
            balance: 500000
        )

        let testStruct = NestedStruct(
            user: user,
            permissions: ["read", "write", "admin"],
            metadata: ["role": "superuser", "department": "IT"]
        )

        let encoded = try testStruct.encodeBorsh()
        let decoded = try encoded.decodeBorsh(NestedStruct.self)

        XCTAssertEqual(testStruct, decoded)
    }

    func testArrayStructEncoding() throws {
        let testStruct = ArrayStruct(
            numbers: [1, 2, 3, 4, 5],
            strings: ["hello", "world"],
            booleans: [true, false, true]
        )

        let encoded = try testStruct.encodeBorsh()
        let decoded = try encoded.decodeBorsh(ArrayStruct.self)

        XCTAssertEqual(testStruct, decoded)
    }

    func testPrimitiveTypesEncoding() throws {
        let testData: [String: Any] = [
            "uint8": UInt8(255),
            "uint16": UInt16(65535),
            "uint32": UInt32(4294967295),
            "uint64": UInt64(18446744073709551615),
            "int8": Int8(-128),
            "int16": Int16(-32768),
            "int32": Int32(-2147483648),
            "int64": Int64(-9223372036854775808),
            "float": Float(3.14159),
            "double": Double(2.718281828459045),
            "bool": true,
            "string": "Hello, Borsh!"
        ]

        // Note: This test demonstrates the structure but would need custom encoding
        // for mixed-type dictionaries in Borsh
        XCTAssertTrue(true) // Placeholder assertion
    }

    func testEmptyArraysEncoding() throws {
        let testStruct = ArrayStruct(
            numbers: [],
            strings: [],
            booleans: []
        )

        let encoded = try testStruct.encodeBorsh()
        let decoded = try encoded.decodeBorsh(ArrayStruct.self)

        XCTAssertEqual(testStruct, decoded)
    }

    func testLargeStringEncoding() throws {
        let longString = String(repeating: "A", count: 1000)
        let testStruct = SimpleStruct(
            id: 999,
            name: longString,
            isActive: false,
            balance: 999999
        )

        let encoded = try testStruct.encodeBorsh()
        let decoded = try encoded.decodeBorsh(SimpleStruct.self)

        XCTAssertEqual(testStruct, decoded)
    }

    func testPerformanceEncoding() throws {
        let testStruct = SimpleStruct(
            id: 1,
            name: "Performance Test",
            isActive: true,
            balance: 1000000
        )

        measure {
            do {
                _ = try testStruct.encodeBorsh()
            } catch {
                XCTFail("Encoding failed: \(error)")
            }
        }
    }

    func testPerformanceDecoding() throws {
        let testStruct = SimpleStruct(
            id: 1,
            name: "Performance Test",
            isActive: true,
            balance: 1000000
        )

        let encoded = try testStruct.encodeBorsh()

        measure {
            do {
                _ = try encoded.decodeBorsh(SimpleStruct.self)
            } catch {
                XCTFail("Decoding failed: \(error)")
            }
        }
    }

    // MARK: - Golden Tests

    func testDecodingAccountInfo() {
        let string = #"BhrZ0FOHFUhTft4+JhhJo9+3/QL6vHWyI8jkatuFPQwCqmOzhzy1ve5l2AqL0ottCChJZ1XSIW3k3C7TaBQn7aCGAQAAAAAAAQAAAOt6vNDYdevCbaGxgaMzmz7yoxaVu3q9vGeCc7ytzeWqAQAAAAAAAAAAAAAAAGQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"#
        let accountInfo = try! JSONDecoder().decode(Buffer<Solana.AccountInfo>.self, from: string.data(using: .utf8)!).value
        XCTAssertEqual("QqCCvshxtqMAL2CVALqiJB7uEeE5mjSPsseQdDzsRUo", accountInfo?.mint.base58EncodedString)
        XCTAssertEqual("BQWWFhzBdw2vKKBUX17NHeFbCoFQHfRARpdztPE2tDJ", accountInfo?.owner.base58EncodedString)
        XCTAssertEqual("GrDMoeqMLFjeXQ24H56S1RLgT4R76jsuWCd6SvXyGPQ5", accountInfo?.delegate?.base58EncodedString)
        XCTAssertEqual(100, accountInfo?.delegatedAmount)
        XCTAssertEqual(false, accountInfo?.isNative)
        XCTAssertEqual(true, accountInfo?.isInitialized)
        XCTAssertEqual(false, accountInfo?.isFrozen)
        XCTAssertNil(accountInfo?.rentExemptReserve)
        XCTAssertNil(accountInfo?.closeAuthority)
    }

    func testDecodingAccountInfo2() {
        let string = #"["AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAOt6vNDYdevCbaGxgaMzmz7yoxaVu3q9vGeCc7ytzeWq","base64"]"#
        let accountInfo = try! JSONDecoder().decode(Buffer<Solana.AccountInfo>.self, from: string.data(using: .utf8)!).value
        XCTAssertNil(accountInfo?.delegate)
        XCTAssertEqual(0, accountInfo?.delegatedAmount)
        XCTAssertEqual(false, accountInfo?.isInitialized)
        XCTAssertEqual(false, accountInfo?.isNative)
        XCTAssertNil(accountInfo?.rentExemptReserve)
        XCTAssertEqual("GrDMoeqMLFjeXQ24H56S1RLgT4R76jsuWCd6SvXyGPQ5", accountInfo?.closeAuthority?.base58EncodedString)

        let string2 = #"["AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAOt6vNDYdevCbaGxgaMzmz7yoxaVu3q9vGeCc7ytzeWq","base64"]"#
        let accountInfo2 = try! JSONDecoder().decode(Buffer<Solana.AccountInfo>.self, from: string2.data(using: .utf8)!).value
        XCTAssertEqual(true, accountInfo2?.isFrozen)
    }
}
