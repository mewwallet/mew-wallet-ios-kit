//
//  Solana._BorshEncoding+Decoder.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit_utils

extension Solana._BorshEncoding {
  /// A simple decoder for Borsh deserialization that handles basic types.
    internal final class Decoder: Swift.Decoder {

    /// The current coding path for nested container resolution.
    let codingPath: [any CodingKey]
    
    /// Any user-provided metadata or configuration during decoding.
    let userInfo: [CodingUserInfoKey : Any]
    
    /// The input data to decode from.
    let data: Data
    
    /// Current position in the data.
    internal var currentIndex: Int = 0
    
    /// Initializes a new decoder instance.
    init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any], data: Data) {
      self.codingPath = codingPath
      self.userInfo = userInfo
      self.data = data
      self.currentIndex = 0
    }
    
    /// Creates a keyed decoding container.
    func container<Key>(keyedBy type: Key.Type) throws -> Swift.KeyedDecodingContainer<Key> where Key : CodingKey {
      let container = Solana._BorshEncoding.KeyedDecodingContainer<Key>(decoder: self)
      return Swift.KeyedDecodingContainer(container)
    }
    
    /// Creates an unkeyed decoding container.
    func unkeyedContainer() throws -> Swift.UnkeyedDecodingContainer {
      let container = Solana._BorshEncoding.UnkeyedDecodingContainer(decoder: self)
      return container
    }
    
    /// Creates a single-value decoding container.
    func singleValueContainer() throws -> Swift.SingleValueDecodingContainer {
      let container = Solana._BorshEncoding.SingleValueDecodingContainer(decoder: self)
      return container
    }
    
    /// Reads the next bytes from the data.
    internal func readBytes(_ count: Int) throws -> Data {
      guard currentIndex + count <= data.count else {
        throw DecodingError.dataCorrupted(DecodingError.Context(
          codingPath: codingPath,
          debugDescription: "Insufficient data to read \(count) bytes"
        ))
      }
      
      let result = data[currentIndex..<(currentIndex + count)]
      currentIndex += count
      return Data(result)
    }
    
    /// Reads a UInt32 (little-endian) from the data.
    internal func readUInt32() throws -> UInt32 {
      let bytes = try readBytes(4)
      let value = bytes.withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
      return value
    }
    
    /// Reads a UInt64 (little-endian) from the data.
    internal func readUInt64() throws -> UInt64 {
      let bytes = try readBytes(8)
      let value = bytes.withUnsafeBytes { $0.load(as: UInt64.self).littleEndian }
      return value
    }
    
    /// Gets the remaining data length.
    internal var remainingDataLength: Int {
      return data.count - currentIndex
    }
  }
}
