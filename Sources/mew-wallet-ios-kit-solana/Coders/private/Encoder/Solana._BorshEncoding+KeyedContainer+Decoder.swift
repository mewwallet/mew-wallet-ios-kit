//
//  Solana._BorshEncoding+KeyedContainer+Decoder.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana._BorshEncoding {
  /// A simple keyed decoding container for Borsh deserialization.
  internal struct KeyedDecodingContainer<Key: CodingKey>: Swift.KeyedDecodingContainerProtocol {
    typealias Key = Key
    
    /// The decoder this container belongs to.
    let decoder: Solana._BorshEncoding.Decoder
    
    /// The coding path for this container.
    var codingPath: [any CodingKey] { decoder.codingPath }
    
    /// All keys available in this container.
    var allKeys: [Key] { [] } // Borsh doesn't have explicit keys, so we return empty array
    
    /// Initializes a new keyed container.
    init(decoder: Solana._BorshEncoding.Decoder) {
      self.decoder = decoder
    }
    
    // MARK: - KeyedDecodingContainerProtocol
    
    func contains(_ key: Key) -> Bool {
      // In Borsh, all fields are encoded in order, so we assume all keys exist
      return true
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
      // Borsh doesn't support nil values
      return false
    }
    
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
      let byte = try decoder.readBytes(1)
      let value = byte[0] != 0
      return value
    }
    
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
      let length = try decoder.readUInt32()
      let stringData = try decoder.readBytes(Int(length))
      guard let string = String(data: stringData, encoding: .utf8) else {
        throw DecodingError.dataCorrupted(DecodingError.Context(
          codingPath: codingPath + [key],
          debugDescription: "Invalid UTF-8 string data"
        ))
      }
      return string
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
      let bytes = try decoder.readBytes(8)
      let bitPattern = bytes.withUnsafeBytes { $0.load(as: UInt64.self).littleEndian }
      let value = Double(bitPattern: bitPattern)
      return value
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
      let bytes = try decoder.readBytes(4)
      let bitPattern = bytes.withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
      let value = Float(bitPattern: bitPattern)
      return value
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
      let bytes = try decoder.readBytes(MemoryLayout<Int>.size)
      let value = bytes.withUnsafeBytes { $0.load(as: Int.self).littleEndian }
      return value
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
      let byte = try decoder.readBytes(1)
      let value = Int8(bitPattern: byte[0])
      return value
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
      let bytes = try decoder.readBytes(2)
      let value = bytes.withUnsafeBytes { $0.load(as: Int16.self).littleEndian }
      return value
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
      let bytes = try decoder.readBytes(4)
      let value = bytes.withUnsafeBytes { $0.load(as: Int32.self).littleEndian }
      return value
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
      let bytes = try decoder.readBytes(8)
      let value = bytes.withUnsafeBytes { $0.load(as: Int64.self).littleEndian }
      return value
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
      let bytes = try decoder.readBytes(MemoryLayout<UInt>.size)
      let value = bytes.withUnsafeBytes { $0.load(as: UInt.self).littleEndian }
      return value
    }
    
    func decode(_ type: Data.Type, forKey key: Key) throws -> Data {
      let raw = try decoder.readBytes(32)
      return raw
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
      let bytes = try decoder.readBytes(1)
      let value = bytes.first!
      return value
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
      let bytes = try decoder.readBytes(2)
      let value = bytes.withUnsafeBytes { $0.load(as: UInt16.self).littleEndian }
      return value
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
      let bytes = try decoder.readBytes(4)
      let value = bytes.withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
      return value
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
      let bytes = try decoder.readBytes(8)
      let value = bytes.withUnsafeBytes { $0.load(as: UInt64.self).littleEndian }
      return value
    }
    
    func decode(_ type: PublicKey.Type, forKey key: Key) throws -> PublicKey {
      // For Solana, PublicKey is exactly 32 bytes
      let raw = try decoder.readBytes(32)
      return try PublicKey(publicKey: raw, compressed: true, index: 0, network: .solana)
    }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
      // Special handling for PublicKey to use our custom method
      if T.self == PublicKey.self {
        let result = try decode(PublicKey.self, forKey: key)
        return result as! T
      }
      
      // Create a slice of data from the current position to the end
      let remainingData = decoder.data[decoder.currentIndex...]
      
      let nestedDecoder = Solana._BorshEncoding.Decoder(
        codingPath: codingPath + [key],
        userInfo: decoder.userInfo,
        data: Data(remainingData)
      )
      let result = try T(from: nestedDecoder)
      
      // Update the parent decoder's position based on how much the nested decoder consumed
      let consumedBytes = remainingData.count - nestedDecoder.remainingDataLength
      decoder.currentIndex += consumedBytes
      
      return result
    }
    
    // MARK: - Required protocol methods (simplified)
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> Swift.KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
      throw DecodingError.dataCorrupted(DecodingError.Context(
        codingPath: codingPath + [key],
        debugDescription: "Nested containers not supported in Borsh decoding"
      ))
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> Swift.UnkeyedDecodingContainer {
      throw DecodingError.dataCorrupted(DecodingError.Context(
        codingPath: codingPath + [key],
        debugDescription: "Nested unkeyed containers not supported in Borsh decoding"
      ))
    }
    
    func superDecoder() throws -> any Swift.Decoder {
      throw DecodingError.dataCorrupted(DecodingError.Context(
        codingPath: codingPath,
        debugDescription: "Super decoders not supported in Borsh decoding"
      ))
    }
    
    func superDecoder(forKey key: Key) throws -> any Swift.Decoder {
      throw DecodingError.dataCorrupted(DecodingError.Context(
        codingPath: codingPath + [key],
        debugDescription: "Super decoders not supported in Borsh decoding"
      ))
    }
  }
}
