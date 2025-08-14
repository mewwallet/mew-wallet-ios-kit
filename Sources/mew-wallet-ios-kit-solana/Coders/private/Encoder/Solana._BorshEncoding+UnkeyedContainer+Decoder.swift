//
//  Solana._BorshEncoding+UnkeyedContainer+Decoder.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation

extension Solana._BorshEncoding {
    /// A simple unkeyed decoding container for Borsh deserialization.
    internal struct UnkeyedDecodingContainer: Swift.UnkeyedDecodingContainer {
        /// The decoder this container belongs to.
        let decoder: Solana._BorshEncoding.Decoder
        
        /// The coding path for this container.
        var codingPath: [any CodingKey] { decoder.codingPath }
        
        /// The number of elements decoded so far.
        var count: Int? { nil } // We don't track count in this simple implementation
        
        /// Whether we've reached the end of the container.
        var isAtEnd: Bool { decoder.remainingDataLength <= 0 }
        
        /// The current index in the container.
        var currentIndex: Int { 0 } // We don't track index in this simple implementation
        
        /// Initializes a new unkeyed container.
        init(decoder: Solana._BorshEncoding.Decoder) {
            self.decoder = decoder
        }
        
        // MARK: - UnkeyedDecodingContainer
        
        mutating func decodeNil() throws -> Bool {
            // Borsh doesn't support nil values
            return false
        }
        
        mutating func decode(_ type: Bool.Type) throws -> Bool {
            let byte = try decoder.readBytes(1)
            return byte[0] != 0
        }
        
        mutating func decode(_ type: String.Type) throws -> String {
            let length = try decoder.readUInt32()
            let stringData = try decoder.readBytes(Int(length))
            guard let string = String(data: stringData, encoding: .utf8) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Invalid UTF-8 string data"
                ))
            }
            return string
        }
        
        mutating func decode(_ type: Double.Type) throws -> Double {
            let bytes = try decoder.readBytes(8)
            let bitPattern = bytes.withUnsafeBytes { $0.load(as: UInt64.self).littleEndian }
            return Double(bitPattern: bitPattern)
        }
        
        mutating func decode(_ type: Float.Type) throws -> Float {
            let bytes = try decoder.readBytes(4)
            let bitPattern = bytes.withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
            return Float(bitPattern: bitPattern)
        }
        
        mutating func decode(_ type: Int.Type) throws -> Int {
            let bytes = try decoder.readBytes(MemoryLayout<Int>.size)
            return bytes.withUnsafeBytes { $0.load(as: Int.self).littleEndian }
        }
        
        mutating func decode(_ type: Int8.Type) throws -> Int8 {
            let byte = try decoder.readBytes(1)
            return Int8(bitPattern: byte[0])
        }
        
        mutating func decode(_ type: Int16.Type) throws -> Int16 {
            let bytes = try decoder.readBytes(2)
            return bytes.withUnsafeBytes { $0.load(as: Int16.self).littleEndian }
        }
        
        mutating func decode(_ type: Int32.Type) throws -> Int32 {
            let bytes = try decoder.readBytes(4)
            return bytes.withUnsafeBytes { $0.load(as: Int32.self).littleEndian }
        }
        
        mutating func decode(_ type: Int64.Type) throws -> Int64 {
            let bytes = try decoder.readBytes(8)
            return bytes.withUnsafeBytes { $0.load(as: Int64.self).littleEndian }
        }
        
        mutating func decode(_ type: UInt.Type) throws -> UInt {
            let bytes = try decoder.readBytes(MemoryLayout<UInt>.size)
            return bytes.withUnsafeBytes { $0.load(as: UInt.self).littleEndian }
        }
        
        mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
            let byte = try decoder.readBytes(1)
            return byte[0]
        }
        
        mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
            let bytes = try decoder.readBytes(2)
            return bytes.withUnsafeBytes { $0.load(as: UInt16.self).littleEndian }
        }
        
        mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
            let bytes = try decoder.readBytes(4)
            return bytes.withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
        }
        
        mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
            let bytes = try decoder.readBytes(8)
            return bytes.withUnsafeBytes { $0.load(as: UInt64.self).littleEndian }
        }
        
        mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            let nestedDecoder = Solana._BorshEncoding.Decoder(
                codingPath: codingPath,
                userInfo: decoder.userInfo,
                data: decoder.data
            )
            return try T(from: nestedDecoder)
        }
        
        // MARK: - Required protocol methods (simplified)
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> Swift.KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Nested containers not supported in Borsh decoding"
            ))
        }
        
        func nestedUnkeyedContainer() throws -> Swift.UnkeyedDecodingContainer {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Nested unkeyed containers not supported in Borsh decoding"
            ))
        }
        
        func superDecoder() throws -> Swift.Decoder {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Super decoders not supported in Borsh decoding"
            ))
        }
    }
}
