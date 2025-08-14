//
//  Solana._BorshEncoding+KeyedContainer.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation

extension Solana._BorshEncoding {
    /// A simple keyed encoding container for Borsh serialization.
    internal struct KeyedContainer<Key: CodingKey>: Swift.KeyedEncodingContainerProtocol {
        typealias Key = Key
        
        /// The encoder this container belongs to.
        let encoder: Solana._BorshEncoding.Encoder
        
        /// The coding path for this container.
        var codingPath: [any CodingKey] { encoder.codingPath }
        
        /// Initializes a new keyed container.
        init(encoder: Solana._BorshEncoding.Encoder) {
            self.encoder = encoder
        }
        
        // MARK: - KeyedEncodingContainerProtocol
        
        mutating func encodeNil(forKey key: Key) throws {
            // Borsh doesn't support nil values, so we throw an error
            throw EncodingError.invalidValue(Optional<Never>.none, EncodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Borsh encoding does not support nil values"
            ))
        }
        
        mutating func encode(_ value: Bool, forKey key: Key) throws {
            encoder.storage.append(Data([value ? 1 : 0]))
        }
        
        mutating func encode(_ value: String, forKey key: Key) throws {
            let stringData = value.data(using: .utf8) ?? Data()
            let length = UInt32(stringData.count)
            
            // Write length as UInt32 (little-endian)
            let lengthBytes = withUnsafeBytes(of: length.littleEndian) { Data($0) }
            encoder.storage.append(lengthBytes)
            
            // Write string data
            encoder.storage.append(stringData)
        }
        
        mutating func encode(_ value: Double, forKey key: Key) throws {
            let bytes = withUnsafeBytes(of: value.bitPattern.littleEndian) { Data($0) }
            encoder.storage.append(bytes)
        }
        
        mutating func encode(_ value: Float, forKey key: Key) throws {
            let bytes = withUnsafeBytes(of: value.bitPattern.littleEndian) { Data($0) }
            encoder.storage.append(bytes)
        }
        
        mutating func encode(_ value: Int, forKey key: Key) throws {
            let bytes = withUnsafeBytes(of: value.littleEndian) { Data($0) }
            encoder.storage.append(bytes)
        }
        
        mutating func encode(_ value: Int8, forKey key: Key) throws {
            encoder.storage.append(Data([UInt8(bitPattern: value)]))
        }
        
        mutating func encode(_ value: Int16, forKey key: Key) throws {
            let bytes = withUnsafeBytes(of: value.littleEndian) { Data($0) }
            encoder.storage.append(bytes)
        }
        
        mutating func encode(_ value: Int32, forKey key: Key) throws {
            let bytes = withUnsafeBytes(of: value.littleEndian) { Data($0) }
            encoder.storage.append(bytes)
        }
        
        mutating func encode(_ value: Int64, forKey key: Key) throws {
            let bytes = withUnsafeBytes(of: value.littleEndian) { Data($0) }
            encoder.storage.append(bytes)
        }
        
        mutating func encode(_ value: UInt, forKey key: Key) throws {
            let bytes = withUnsafeBytes(of: value.littleEndian) { Data($0) }
            encoder.storage.append(bytes)
        }
        
        mutating func encode(_ value: UInt8, forKey key: Key) throws {
            encoder.storage.append(Data([value]))
        }
        
        mutating func encode(_ value: UInt16, forKey key: Key) throws {
            let bytes = withUnsafeBytes(of: value.littleEndian) { Data($0) }
            encoder.storage.append(bytes)
        }
        
        mutating func encode(_ value: UInt32, forKey key: Key) throws {
            let bytes = withUnsafeBytes(of: value.littleEndian) { Data($0) }
            encoder.storage.append(bytes)
        }
        
        mutating func encode(_ value: UInt64, forKey key: Key) throws {
            let bytes = withUnsafeBytes(of: value.littleEndian) { Data($0) }
            encoder.storage.append(bytes)
        }
        
        mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            let nestedEncoder = Solana._BorshEncoding.Encoder(
                codingPath: codingPath + [key],
                userInfo: encoder.userInfo,
                storage: encoder.storage
            )
            try value.encode(to: nestedEncoder)
        }
        
        // MARK: - Required protocol methods (simplified)
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> Swift.KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            let nestedEncoder = Solana._BorshEncoding.Encoder(
                codingPath: codingPath + [key],
                userInfo: encoder.userInfo,
                storage: encoder.storage
            )
            let container = Solana._BorshEncoding.KeyedContainer<NestedKey>(encoder: nestedEncoder)
            return KeyedEncodingContainer(container)
        }
        
        mutating func nestedUnkeyedContainer(forKey key: Key) -> any UnkeyedEncodingContainer {
            let nestedEncoder = Solana._BorshEncoding.Encoder(
                codingPath: codingPath + [key],
                userInfo: encoder.userInfo,
                storage: encoder.storage
            )
            return nestedEncoder.unkeyedContainer()
        }
        
        mutating func superEncoder() -> Swift.Encoder {
            let nestedEncoder = Solana._BorshEncoding.Encoder(
                codingPath: codingPath,
                userInfo: encoder.userInfo,
                storage: encoder.storage
            )
            return nestedEncoder
        }
        
        mutating func superEncoder(forKey key: Key) -> Swift.Encoder {
            let nestedEncoder = Solana._BorshEncoding.Encoder(
                codingPath: codingPath + [key],
                userInfo: encoder.userInfo,
                storage: encoder.storage
            )
            return nestedEncoder
        }
    }
}
