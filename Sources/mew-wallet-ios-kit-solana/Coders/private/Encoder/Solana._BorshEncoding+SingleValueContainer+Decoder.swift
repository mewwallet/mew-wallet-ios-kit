//
//  Solana._BorshEncoding+SingleValueContainer+Decoder.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana._BorshEncoding {
  /// A simple single-value decoding container for Borsh deserialization.
  internal struct SingleValueDecodingContainer: Swift.SingleValueDecodingContainer {
    /// The decoder this container belongs to.
    let decoder: Solana._BorshEncoding.Decoder
    
    /// The coding path for this container.
    var codingPath: [any CodingKey] { decoder.codingPath }
    
    /// Initializes a new single-value container.
    init(decoder: Solana._BorshEncoding.Decoder) {
      self.decoder = decoder
    }
    
    // MARK: - SingleValueDecodingContainer
    
    func decodeNil() -> Bool {
      // Borsh doesn't support nil values
      return false
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
      let byte = try decoder.readBytes(1)
      return byte[0] != 0
    }
    
    func decode(_ type: String.Type) throws -> String {
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
    
    func decode(_ type: Double.Type) throws -> Double {
      let bytes = try decoder.readBytes(8)
      let bitPattern = bytes.withUnsafeBytes { $0.load(as: UInt64.self).littleEndian }
      return Double(bitPattern: bitPattern)
    }
    
    func decode(_ type: Float.Type) throws -> Float {
      let bytes = try decoder.readBytes(4)
      let bitPattern = bytes.withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
      return Float(bitPattern: bitPattern)
    }
    
    func decode(_ type: Int.Type) throws -> Int {
      let bytes = try decoder.readBytes(MemoryLayout<Int>.size)
      return bytes.withUnsafeBytes { $0.load(as: Int.self).littleEndian }
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
      let byte = try decoder.readBytes(1)
      return Int8(bitPattern: byte[0])
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
      let bytes = try decoder.readBytes(2)
      return bytes.withUnsafeBytes { $0.load(as: Int16.self).littleEndian }
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
      let bytes = try decoder.readBytes(4)
      return bytes.withUnsafeBytes { $0.load(as: Int32.self).littleEndian }
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
      let bytes = try decoder.readBytes(8)
      return bytes.withUnsafeBytes { $0.load(as: Int64.self).littleEndian }
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
      let bytes = try decoder.readBytes(MemoryLayout<UInt>.size)
      return bytes.withUnsafeBytes { $0.load(as: UInt.self).littleEndian }
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
      let byte = try decoder.readBytes(1)
      return byte[0]
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
      let bytes = try decoder.readBytes(2)
      return bytes.withUnsafeBytes { $0.load(as: UInt16.self).littleEndian }
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
      let bytes = try decoder.readBytes(4)
      return bytes.withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
      let bytes = try decoder.readBytes(8)
      let value = bytes.withUnsafeBytes { $0.load(as: UInt64.self).littleEndian }
      print("🔍 [Borsh] Decoding UInt64: \(value)")
      return value
    }
    
    func decode(_ type: Data.Type) throws -> Data {
      // For Borsh, Data is typically a fixed-size field
      // For Solana public keys, this should be 32 bytes
      let bytes = try decoder.readBytes(32)
      print("🔍 [Borsh] Decoding Data: \(bytes.count) bytes")
      return bytes
    }
    
    func decode(_ type: PublicKey.Type) throws -> PublicKey {
      // For Solana, PublicKey is exactly 32 bytes
      let raw = try decoder.readBytes(32)
      print("🔍 [Borsh] Decoding PublicKey: \(raw.count) bytes")
      return try PublicKey(publicKey: raw, compressed: true, index: 0, network: .solana)
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
      // Special handling for PublicKey to use our custom method
      if T.self == PublicKey.self {
        let result = try decode(PublicKey.self)
        return result as! T
      }
      
      // Create a slice of data from the current position to the end
      let remainingData = decoder.data[decoder.currentIndex...]
      
      let nestedDecoder = Solana._BorshEncoding.Decoder(
        codingPath: codingPath,
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
  }
}
