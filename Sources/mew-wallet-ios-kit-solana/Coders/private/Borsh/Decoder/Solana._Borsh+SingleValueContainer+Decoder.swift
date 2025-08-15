//
//  Solana._BorshEncoding+SingleValueContainer+Decoder.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana._Borsh {
    /// A simple single-value decoding container for Borsh deserialization.
    internal struct SingleValueDecodingContainer: Swift.SingleValueDecodingContainer {
        /// The decoder this container belongs to.
        let decoder: Solana._Borsh.Decoder

        /// The coding path for this container.
        var codingPath: [any CodingKey] { decoder.codingPath }


        let section: Solana._Borsh.Decoder.Section

        /// Initializes a new single-value container.
        init(decoder: Solana._Borsh.Decoder) {
            self.decoder = decoder
            self.section = decoder.section
        }

        // MARK: - SingleValueDecodingContainer

        func decodeNil() -> Bool {
            // Borsh doesn't support nil values
            return false
        }

        func decode(_ type: Bool.Type) throws -> Bool {
            let byte: UInt8 = try decoder.data.readLE(&decoder.currentIndex)
            return byte != 0
        }

        func decode(_ type: String.Type) throws -> String {
            let length: UInt32 = try decoder.data.readLE(&decoder.currentIndex)
            let stringData = try decoder.data.read(&decoder.currentIndex, offsetBy: Int(length))
            guard let string = String(data: stringData, encoding: .utf8) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Invalid UTF-8 string data"
                ))
            }
            return string
        }

        func decode(_ type: Double.Type) throws -> Double {
            let value: UInt64 = try decoder.data.readLE(&decoder.currentIndex)
            return Double(value)
        }

        func decode(_ type: Float.Type) throws -> Float {
            let value: UInt32 = try decoder.data.readLE(&decoder.currentIndex)
            return Float(value)
        }

        func decode(_ type: Int.Type) throws -> Int {
            let value: UInt64 = try decoder.data.readLE(&decoder.currentIndex)
            return Int(value)
        }

        func decode(_ type: Int8.Type) throws -> Int8 {
            let value: UInt8 = try decoder.data.readLE(&decoder.currentIndex)
            return Int8(value)
        }

        func decode(_ type: Int16.Type) throws -> Int16 {
            let value: UInt16 = try decoder.data.readLE(&decoder.currentIndex)
            return Int16(value)
        }

        func decode(_ type: Int32.Type) throws -> Int32 {
            let value: UInt32 = try decoder.data.readLE(&decoder.currentIndex)
            return Int32(value)
        }

        func decode(_ type: Int64.Type) throws -> Int64 {
            let value: UInt64 = try decoder.data.readLE(&decoder.currentIndex)
            return Int64(value)
        }

        func decode(_ type: UInt.Type) throws -> UInt {
            let value: UInt64 = try decoder.data.readLE(&decoder.currentIndex)
            return UInt(value)
        }

        func decode(_ type: UInt8.Type) throws -> UInt8 {
            let value: UInt8 = try decoder.data.readLE(&decoder.currentIndex)
            return value
        }

        func decode(_ type: UInt16.Type) throws -> UInt16 {
            let value: UInt16 = try decoder.data.readLE(&decoder.currentIndex)
            return value
        }

        func decode(_ type: UInt32.Type) throws -> UInt32 {
            let value: UInt32 = try decoder.data.readLE(&decoder.currentIndex)
            return value
        }

        func decode(_ type: UInt64.Type) throws -> UInt64 {
            let value: UInt64 = try decoder.data.readLE(&decoder.currentIndex)
            return value
        }

        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            switch self.section {
            case .publicKey where type == Data.self:
                return try self.decoder.data.read(&self.decoder.currentIndex, offsetBy: 32) as! T
            default:
                throw DecodingError.dataCorruptedError(in: self, debugDescription: "Unknown field")
            }
        }
    }
}
