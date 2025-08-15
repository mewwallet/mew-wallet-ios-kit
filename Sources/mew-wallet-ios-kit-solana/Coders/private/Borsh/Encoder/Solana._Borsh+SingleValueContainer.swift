//
//  Solana._BorshEncoding+SingleValueContainer.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation

extension Solana._Borsh {
  /// A simple single-value encoding container for Borsh serialization.
  internal struct SingleValueContainer: Swift.SingleValueEncodingContainer {
    /// The encoder this container belongs to.
    let encoder: Solana._Borsh.Encoder
    
    /// The coding path for this container.
    var codingPath: [any CodingKey] { encoder.codingPath }
    
    /// Initializes a new single-value container.
    init(encoder: Solana._Borsh.Encoder) {
      self.encoder = encoder
    }
    
    // MARK: - SingleValueEncodingContainer
    
    mutating func encodeNil() throws {
      // Borsh doesn't support nil values
      throw EncodingError.invalidValue(Optional<Never>.none, EncodingError.Context(
        codingPath: codingPath,
        debugDescription: "Borsh encoding does not support nil values"
      ))
    }
    
    mutating func encode(_ value: Bool) throws {
      encoder.storage.append(Data([value ? 1 : 0]))
    }
    
    mutating func encode(_ value: String) throws {
      let stringData = value.data(using: .utf8) ?? Data()
      let length = UInt32(stringData.count)
      
      // Write length as UInt32 (little-endian)
      let lengthBytes = withUnsafeBytes(of: length.littleEndian) { Data($0) }
      encoder.storage.append(lengthBytes)
      
      // Write string data
      encoder.storage.append(stringData)
    }
    
    mutating func encode(_ value: Double) throws {
      let bytes = withUnsafeBytes(of: value.bitPattern.littleEndian) { Data($0) }
      encoder.storage.append(bytes)
    }
    
    mutating func encode(_ value: Float) throws {
      let bytes = withUnsafeBytes(of: value.bitPattern.littleEndian) { Data($0) }
      encoder.storage.append(bytes)
    }
    
    mutating func encode(_ value: Int) throws {
      let bytes = withUnsafeBytes(of: value.littleEndian) { Data($0) }
      encoder.storage.append(bytes)
    }
    
    mutating func encode(_ value: Int8) throws {
      encoder.storage.append(Data([UInt8(bitPattern: value)]))
    }
    
    mutating func encode(_ value: Int16) throws {
      let bytes = withUnsafeBytes(of: value.littleEndian) { Data($0) }
      encoder.storage.append(bytes)
    }
    
    mutating func encode(_ value: Int32) throws {
      let bytes = withUnsafeBytes(of: value.littleEndian) { Data($0) }
      encoder.storage.append(bytes)
    }
    
    mutating func encode(_ value: Int64) throws {
      let bytes = withUnsafeBytes(of: value.littleEndian) { Data($0) }
      encoder.storage.append(bytes)
    }
    
    mutating func encode(_ value: UInt) throws {
      let bytes = withUnsafeBytes(of: value.littleEndian) { Data($0) }
      encoder.storage.append(bytes)
    }
    
    mutating func encode(_ value: UInt8) throws {
      encoder.storage.append(Data([value]))
    }
    
    mutating func encode(_ value: UInt16) throws {
      let bytes = withUnsafeBytes(of: value.littleEndian) { Data($0) }
      encoder.storage.append(bytes)
    }
    
    mutating func encode(_ value: UInt32) throws {
      let bytes = withUnsafeBytes(of: value.littleEndian) { Data($0) }
      encoder.storage.append(bytes)
    }
    
    mutating func encode(_ value: UInt64) throws {
      let bytes = withUnsafeBytes(of: value.littleEndian) { Data($0) }
      encoder.storage.append(bytes)
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
                  let nestedEncoder = Solana._Borsh.Encoder(
                codingPath: codingPath,
                userInfo: encoder.userInfo,
                storage: encoder.storage
            )
            try value.encode(to: nestedEncoder)
    }
  }
}
