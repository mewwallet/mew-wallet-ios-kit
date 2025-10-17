//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/10/25.
//

import Foundation

extension Solana._ShortVecDecoding {
  /// An unkeyed decoding container tailored for Solana wire formats.
  ///
  /// This container:
  /// - Walks through the binary payload using a shared `decoder.offset`.
  /// - Drives a light state-machine (`section`) that mirrors Solana `Transaction`,
  ///   `Message`/`MessageV0`, and their nested structures (account keys, instructions,
  ///   address table lookups).
  /// - Decodes shortvec (base-128 varint) for integer counts and length-prefixed fields.
  internal struct UnkeyedContainer: Swift.UnkeyedDecodingContainer {
    /// Current coding path, inherited from the parent decoder (diagnostics only).
    var codingPath: [any CodingKey] { decoder.codingPath }
    
    /// Total element count if known upfront (e.g. when a shortvec length was already read).
    var count: Int?
    
    /// Whether the cursor has reached the logical end of this container.
    var isAtEnd: Bool {
      guard let count else { return false }
      return currentIndex >= count
    }
    
    /// Current logical index within this container.
    var currentIndex: Int = 0
    
    /// Decoding state snapshot (the “sub-section” of the wire format we are in).
    var section: Solana._ShortVecDecoding.Decoder.Section
    
    /// Parent decoder used for shared offset and configuration.
    private let decoder: Solana._ShortVecDecoding.Decoder
    
    /// Initializes the container and, when possible, pre-populates `count` based on the section.
    init(decoder: Solana._ShortVecDecoding.Decoder) {
      self.section = decoder.section
      self.decoder = decoder
      
      switch decoder.section {
      case .message(.accountKeys(.publicKey(let count))),
          .message(.instructions(.instruction(let count))),
          .message(.addressTableLookups(.addressTableLookups(.addressTableLookup(let count)))):
        self.count = count
      default:
        self.count = nil
      }
    }
    
    /// Decodes the next value in this unkeyed sequence into a `Decodable` target type.
    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
      guard !isAtEnd else {
        throw DecodingError.valueNotFound(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Unkeyed container is at end."))
      }
      switch self.section {
        
        // MARK: Transaction.signatures -> [Data] (N signatures, each 64 bytes)
      case .transaction(.signatures) where type == [Data].self:
        let size = try self.decode(Int.self)
        var signatures: [Data] = []
        signatures.reserveCapacity(size)
        for _ in 0..<size {
          let signatureData: Data = try self.decoder.data.read(&self.decoder.offset, offsetBy: 64)
          signatures.append(signatureData)
        }
        self.section = .transaction(.message)
        return signatures as! T
        
        // MARK: Transaction.message (peek prefix to determine version; do not advance here)
      case .transaction(.message):
        let prefix = self.decoder.data[self.decoder.offset] // peek (no advance)
        let maskedPrefix = prefix & 0x7F
        if maskedPrefix == prefix {
          self.decoder.version = .legacy
          self.decoder.section = .message(.header)
        } else if maskedPrefix == 0 {
          self.decoder.version = .v0
          self.decoder.section = .message(.version)
        } else {
          self.decoder.version = .unknown(maskedPrefix)
          self.decoder.section = .message(.version)
        }
        return try T(from: decoder)
        
        // MARK: Message.version (consume 1 byte via nested decoding; then move to header if bytes remain)
      case .message(.version):
        let decoded = try T(from: self.decoder)
        guard decoder.offset.advanced(by: 1) != decoder.data.endIndex else {
          return decoded
        }
        self.section = .message(.header)
        return decoded
        
        // MARK: Message.header (3 bytes: u8,u8,u8) then read accountKeys length and switch state
      case .message(.header):
        let decoded = try T(from: self.decoder)
        guard decoder.offset.advanced(by: 1) != decoder.data.endIndex else {
          return decoded
        }
        let count = try self.decode(Int.self) // shortvec number of account keys
        self.section = .message(.accountKeys(.array(count: count)))
        return decoded
        
        // MARK: Message.accountKeys (read N keys of 32 bytes)
      case .message(.accountKeys(.array(let count))):
        self.decoder.section = .message(.accountKeys(.publicKey(count: count)))
        let decoded = try T(from: self.decoder)
        self.section = .message(.recentBlockhash)
        return decoded
        
        // MARK: Message.accountKeys.publicKey (one 32-byte key per element)
      case .message(.accountKeys(.publicKey)):
        let decoded = try T(from: self.decoder)
        currentIndex += 1
        if self.isAtEnd {
          self.decoder.section = .message(.recentBlockhash)
        }
        return decoded
        
        // MARK: Message.recentBlockhash (32 bytes) then instructions array length
      case .message(.recentBlockhash) where type == Data.self:
        let data: Data = try self.decoder.data.read(&self.decoder.offset, offsetBy: 32)
        let count = try self.decode(Int.self)
        self.section = .message(.instructions(.array(count: count)))
        return data as! T
        
        // MARK: Message.instructions (switch to per-instruction mode)
      case .message(.instructions(.array(let count))):
        self.decoder.section = .message(.instructions(.instruction(count: count)))
        let decoded = try T(from: self.decoder)
        switch self.decoder.version {
        case .v0:
          let count = try self.decode(Int.self) // shortvec number of address table lookups
          self.section = .message(.addressTableLookups(.array(count: count)))
        default:
          self.section = .universal
        }
        return decoded
        
        // MARK: Message.instructions.instruction (accounts indices) -> [UInt8]
      case .message(.instructions(.instruction)) where type == [UInt8].self:
        let size = try self.decode(Int.self)
        var decoded: [UInt8] = []
        decoded.reserveCapacity(size)
        for _ in 0..<size {
          let item: UInt8 = try self.decoder.data.read(&self.decoder.offset)
          decoded.append(item)
        }
        return decoded as! T
        
        // MARK: Message.instructions.instruction (data bytes) -> Data
      case .message(.instructions(.instruction)) where type == Data.self:
        let size = try self.decode(Int.self)
        let decoded: Data = try self.decoder.data.read(&self.decoder.offset, offsetBy: size)
        return decoded as! T
        
        // MARK: Message.instructions.instruction (structured fields; bump index)
      case .message(.instructions):
        let decoded = try T(from: self.decoder)
        currentIndex += 1
        return decoded
        
        // MARK: Message.addressTableLookups (enter lookup iteration)
      case .message(.addressTableLookups(.array(let count))):
        self.decoder.section = .message(.addressTableLookups(.addressTableLookups(.addressTableLookup(count: count))))
        let decoded = try T(from: self.decoder)
        self.section = .universal
        return decoded
        
        // MARK: Message.addressTableLookups.addressTableLookup (first field: table pubkey)
      case .message(.addressTableLookups(.addressTableLookups(.addressTableLookup(let count)))):
        self.decoder.section = .message(.addressTableLookups(.addressTableLookups(.publicKey(count: count))))
        let decoded = try T(from: self.decoder)
        self.section =  .message(.addressTableLookups(.addressTableLookups(.fields(count: count))))
        currentIndex += 1
        return decoded
        
        // MARK: Message.addressTableLookups.publicKey (consume 32-byte table address)
      case .message(.addressTableLookups(.addressTableLookups(.publicKey(let count)))):
        self.section = .message(.addressTableLookups(.addressTableLookups(.fields(count: count))))
        let decoded = try T(from: self.decoder)
        return decoded
        
        // MARK: Message.addressTableLookups.fields (read shortvec indices) -> [UInt8]
      case .message(.addressTableLookups(.addressTableLookups(.fields))) where type == [UInt8].self:
        let size = try self.decode(Int.self) // shortvec
        var decoded: [UInt8] = []
        decoded.reserveCapacity(size)
        for _ in 0..<size {
          let item: UInt8 = try self.decoder.data.read(&self.decoder.offset)
          decoded.append(item)
        }
        return decoded as! T
        
        // MARK: Message.addressTableLookups (structured; bump index and exit if done)
      case .message(.addressTableLookups):
        let decoded = try T(from: self.decoder)
        currentIndex += 1
        if self.isAtEnd {
          self.decoder.section = .universal
        }
        return decoded
        
      default:
        throw DecodingError.dataCorruptedError(in: self, debugDescription: "Unknown field")
      }
    }
    
    // MARK: - Fixed-width integers
    
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 { try decodeShortVecInteger() }
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 { try decodeShortVecInteger() }
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 { try decodeShortVecInteger() }
    mutating func decode(_ type: UInt8.Type) throws -> UInt8 { try self.decoder.data.readLE(&self.decoder.offset) }
    mutating func decode(_ type: UInt.Type) throws -> UInt { try decodeShortVecInteger() }
    mutating func decode(_ type: Int64.Type) throws -> Int64 { try decodeShortVecInteger() }
    mutating func decode(_ type: Int32.Type) throws -> Int32 { try decodeShortVecInteger() }
    mutating func decode(_ type: Int16.Type) throws -> Int16 { try decodeShortVecInteger() }
    mutating func decode(_ type: Int8.Type) throws -> Int8 {
      let uint8: UInt8 = try self.decoder.data.readLE(&self.decoder.offset)
      return Int8(bitPattern: uint8)
    }
    mutating func decode(_ type: Int.Type) throws -> Int { try decodeShortVecInteger() }
    
    /// Decodes a shortvec (base-128 varint) integer and returns it as `T`.
    @inline(__always)
    mutating func decodeShortVecInteger<T>(_ type: T.Type = T.self) throws -> T where T: FixedWidthInteger {
      
      var result: T = 0
      var shift: Int = 0
      
      while true {
        let byte: UInt8 = try decoder.data.readLE(&decoder.offset)
        
        // add 7 low bits
        let low7 = T(byte & 0x7F)
        
        // overflow guard before shifting/appending
        if shift >= T.bitWidth || (low7 != 0 && shift > T.bitWidth - 7) {
          throw DecodingError.dataCorrupted(.init(codingPath: self.codingPath, debugDescription: "ShortVec overflow"))
        }
        
        result |= (low7 &<< T(shift))
        
        // if MSB not set — last byte
        if (byte & 0x80) == 0 { break }
        
        shift &+= 7
        if shift >= T.bitWidth {
          throw DecodingError.dataCorrupted(.init(codingPath: self.codingPath, debugDescription: "ShortVec overflow"))
        }
      }
      
      return result
    }
    
    // MARK: - Unsupported
    
    func decode(_ type: Float.Type) throws -> Float {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Float values are not supported"))
    }
    
    func decode(_ type: Double.Type) throws -> Double {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Double values are not supported"))
    }
    
    func decode(_ type: String.Type) throws -> String {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "String values are not supported"))
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Bool values are not supported"))
    }
    
    func decodeNil() throws -> Bool {
      throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Nil values are not supported"))
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> Swift.KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Nested keyed containers are not supported"))
    }
    
    func nestedUnkeyedContainer() throws -> any Swift.UnkeyedDecodingContainer {
      throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Nested unkeyed containers are not supported"))
    }
    
    func superDecoder() throws -> any Swift.Decoder {
      throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Super decoder is not supported"))
    }
  }
}
