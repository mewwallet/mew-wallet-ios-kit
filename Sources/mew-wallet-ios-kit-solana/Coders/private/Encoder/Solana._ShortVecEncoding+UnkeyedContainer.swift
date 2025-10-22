//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation

extension Solana._ShortVecEncoding {
  /// An unkeyed encoding container for serializing ordered sequences in Solana’s
  /// positional wire format.
  ///
  /// ### What this container does
  /// - Appends each element **in order** to the shared output `storage`.
  /// - Provides helpers to encode **shortvec** (base-128 varint) for integer *lengths/counts*.
  /// - Leaves responsibility for *where* a shortvec length must be emitted to the caller
  ///   (this container does **not** auto-prefix a length for you).
  ///
  /// ### Supported element types
  /// - `Data` — appended verbatim (no implicit length prefix).
  /// - Fixed-width integers —
  ///   - **Unsigned**: encoded as **shortvec** (base-128 varint).
  ///   - **Signed**: only if **non-negative**, encoded via their unsigned magnitude as shortvec.
  ///
  /// ### Not supported
  /// - `Float`, `Double`, `String`, `Bool`, `nil`
  /// - Arbitrary `Encodable` values (to avoid format ambiguity). Use higher-level APIs or
  ///   switch to the appropriate container explicitly.
  struct UnkeyedContainer: Swift.UnkeyedEncodingContainer {
    /// The current path of coding keys associated with this container (diagnostics only).
    var codingPath: [any CodingKey] { encoder.codingPath }
    
    /// The key that resulted in creating this container (may be used by higher-level code).
    let key: (any CodingKey)?
    
    /// Number of elements encoded so far (increments **once per element**).
    var count: Int = 0
    
    /// The parent encoder and backing storage.
    private let encoder: Solana._ShortVecEncoding.Encoder
    
    /// Initializes a new unkeyed container.
    ///
    /// - Parameters:
    ///   - encoder: The parent encoder instance.
    ///   - key: The coding key that created this container (optional, for diagnostics).
    init(encoder: Solana._ShortVecEncoding.Encoder, key: (any CodingKey)?) {
      self.encoder = encoder
      self.key = key
    }
    
    // MARK: - Generic Encodable
    
    /// Encodes a generic `Encodable` element.
    ///
    /// - Important: Only `Data` is accepted here to avoid accidental, format-breaking recursion.
    ///   Use explicit integer methods for shortvec lengths, or construct nested containers
    ///   intentionally at higher levels.
    mutating func encode<T>(_ value: T) throws where T : Encodable {
      guard let data = value as? Data else {
        if let array = value as? [Any] {
          try self.encode(array.count)
        }
        // Encode using nested encoder
        let encoder = Solana._ShortVecEncoding.Encoder(
          codingPath: codingPath,
          userInfo: self.encoder.userInfo,
          storage: self.encoder.storage
        )
        try value.encode(to: encoder)
        return
      }
      
      // Directly encode raw data
      self.encoder.storage.append(data)
    }
    
    // MARK: - Fixed-width integer encoding (shortvec for lengths)
    
    mutating func encode(_ value: UInt64) throws { try self.encodeShortVecInteger(value) }
    mutating func encode(_ value: UInt32) throws { try self.encodeShortVecInteger(value) }
    mutating func encode(_ value: UInt16) throws { try self.encodeShortVecInteger(value) }
    mutating func encode(_ value: UInt8) throws { try self.encodeShortVecInteger(value) }
    mutating func encode(_ value: UInt) throws { try self.encodeShortVecInteger(value) }
    mutating func encode(_ value: Int64) throws { try self.encodeShortVecInteger(value) }
    mutating func encode(_ value: Int32) throws { try self.encodeShortVecInteger(value) }
    mutating func encode(_ value: Int16) throws { try self.encodeShortVecInteger(value) }
    mutating func encode(_ value: Int8) throws { try self.encodeShortVecInteger(value) }
    mutating func encode(_ value: Int) throws { try self.encodeShortVecInteger(value) }
    
    /// Encodes an **unsigned** integer using Solana shortvec (base-128 varint).
    ///
    /// - Important: This is **not** fixed-width little-endian; it is a variable-length
    ///   format used for lengths/counts. Emit it **only** where Solana specifies a shortvec.
    @inline(__always)
    mutating func encodeShortVecInteger<T>(_ value: T) throws where T: FixedWidthInteger {
      var value = value
      repeat {
        var byte = UInt8(truncatingIfNeeded: value & 0x7F)
        value >>= 7
        if value != 0 { byte |= 0x80 }
        self.encoder.storage.append(byte)
      } while value != 0
      count += 1
    }
    
    // MARK: - Unsupported types
    
    mutating func encode(_ value: Float) throws {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Float values are not supported"))
    }
    
    mutating func encode(_ value: Double) throws {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Double values are not supported"))
    }
    
    mutating func encode(_ value: String) throws {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "String values are not supported"))
    }
    
    mutating func encode(_ value: Bool) throws {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Bool values are not supported"))
    }
    
    mutating func encodeNil() throws {
      throw EncodingError.invalidValue("", EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Nil values are not supported"))
    }
    
    // MARK: - Nested container support
    
    /// Nested keyed containers are typically not used in Solana’s positional layout.
    /// If you expose them, ensure higher-level code controls their usage precisely.
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
      let container = KeyedContainer<NestedKey>(encoder: encoder)
      return KeyedEncodingContainer(container)
    }
    
    /// Creates a nested unkeyed container that appends to the same output storage.
    mutating func nestedUnkeyedContainer() -> Swift.UnkeyedEncodingContainer {
      return UnkeyedContainer(encoder: encoder, key: self.key)
    }
    
    /// Returns the parent encoder (rarely used for Solana wire output).
    mutating func superEncoder() -> Swift.Encoder {
      return encoder
    }
  }
}
