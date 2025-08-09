//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/18/25.
//

import Foundation
import mew_wallet_ios_kit_utils

extension Bitcoin._Encoding {
  /// A custom keyed encoding container used for serializing Bitcoin-related types into raw binary format.
  ///
  /// This is a low-level encoder conforming to `KeyedEncodingContainerProtocol`, specialized for Bitcoin transaction
  /// encoding, including PSBT fields and transaction components. It handles binary layout, size-prefixing, script encoding,
  /// and field-specific quirks (like little-endian transaction IDs).
  ///
  /// ### Supported types:
  /// - `Data`: Encoded directly, with optional `VarInt` length prefix depending on `sizeEncodingFormat`.
  /// - `FixedWidthInteger` types (`UInt32`, `Int`, etc.): Encoded in little-endian.
  /// - `Encodable` values: Encoded via nested containers using `Bitcoin._Encoding.Encoder`.
  ///
  /// ### Special behavior:
  /// - Fields named `"txid"` are reversed before encoding (due to little-endian hash encoding).
  /// - Fields `"vin"`, `"vout"`, `"inputs"`, `"outputs"`, `"script_witnesses"` prepend a count using `VarInt`.
  /// - The `"n"` field is intentionally skipped (often used for metadata indexes).
  /// - `"asm"` is encoded without size-prefixing to match expected script layout.
  ///
  /// ### Limitations:
  /// - `Float`, `Double`, `String`, `Bool`, and `nil` values are **not supported**.
  /// - JSON encoding is not supported; this encoder emits raw binary for Bitcoin use.
  struct KeyedContainer<Key: CodingKey>: Swift.KeyedEncodingContainerProtocol {
    var codingPath: [any CodingKey] { encoder.codingPath }
    
    /// The parent encoder used to access configuration and binary output buffer.
    private let encoder: Bitcoin._Encoding.Encoder
    
    /// Initializes a new keyed encoding container.
    ///
    /// - Parameter encoder: The parent encoder.
    init(encoder: Bitcoin._Encoding.Encoder) {
      self.encoder = encoder
    }
    
    /// Encodes any `Encodable` value, using heuristics for special keys and size-prefixed arrays.
    ///
    /// - If the value is `Data`, it's written directly.
    /// - If the key is `"txid"`, the data is reversed before encoding (Bitcoin little-endian txid).
    /// - If the key represents a collection (`vin`, `vout`, etc.), a `varInt` count is prefixed before encoding.
    /// - For other values, a nested encoder is used, respecting `sizeEncodingFormat`.
    mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
      // If the value is raw `Data`, encode directly.
      guard let data = value as? Data else {
        let storage = BinaryStorage()
        let encoder: Bitcoin._Encoding.Encoder
        
        // Disable size encoding for scripts like `asm`.
        if key.stringValue == "asm" {
          encoder = Bitcoin._Encoding.Encoder(
            codingPath: codingPath + [key],
            userInfo: self.encoder.userInfo,
            storage: storage,
            sizeEncodingFormat: .disabled
          )
        } else {
          encoder = Bitcoin._Encoding.Encoder(
            codingPath: codingPath + [key],
            userInfo: self.encoder.userInfo,
            storage: storage,
            sizeEncodingFormat: self.encoder.sizeEncodingFormat
          )
        }
        
        try value.encode(to: encoder)
        
        // Handle special field prefixes.
        switch key.stringValue {
        case "asm", "sequence", "version", "locktime", "transaction", "sighash":
          break // No prefix
        case "vin", "inputs", "vout", "outputs", "script_witnesses":
          if let array = value as? [Any] {
            let size = _Reader.VarInt(rawValue: array.count)
            size.write(to: self.encoder.storage)
          }
        default:
          switch self.encoder.sizeEncodingFormat {
          case .varInt:
            let size = _Reader.VarInt(rawValue: storage.length)
            size.write(to: self.encoder.storage)
          case .disabled:
            break
          }
        }
        self.encoder.storage.append(storage: storage)
        return
      }
      
      // Special handling for txid (reversed little-endian).
      switch key.stringValue {
      case "txid":
        self.encoder.storage.append(data.reversed())
      default:
        switch self.encoder.sizeEncodingFormat {
        case .varInt:
          let size = _Reader.VarInt(rawValue: data.count)
          size.write(to: self.encoder.storage)
        case .disabled:
          break
        }
        self.encoder.storage.append(data)
      }
    }
    
    // MARK: - Fixed-Width Integer Support
    
    mutating func encode(_ value: UInt64, forKey key: Key) throws { try encodeFixedWidthInteger(value, for: key) }
    mutating func encode(_ value: UInt32, forKey key: Key) throws { try encodeFixedWidthInteger(value, for: key) }
    mutating func encode(_ value: UInt16, forKey key: Key) throws { try encodeFixedWidthInteger(value, for: key) }
    mutating func encode(_ value: UInt8, forKey key: Key) throws { try encodeFixedWidthInteger(value, for: key) }
    mutating func encode(_ value: UInt, forKey key: Key) throws { try encodeFixedWidthInteger(value, for: key) }
    mutating func encode(_ value: Int64, forKey key: Key) throws { try encodeFixedWidthInteger(value, for: key) }
    mutating func encode(_ value: Int32, forKey key: Key) throws { try encodeFixedWidthInteger(value, for: key) }
    mutating func encode(_ value: Int16, forKey key: Key) throws { try encodeFixedWidthInteger(value, for: key) }
    mutating func encode(_ value: Int8, forKey key: Key) throws { try encodeFixedWidthInteger(value, for: key) }
    mutating func encode(_ value: Int, forKey key: Key) throws { try encodeFixedWidthInteger(value, for: key) }
    
    /// Encodes a fixed-width integer unless the key is `"n"` (which is ignored).
    @inline(__always)
    mutating func encodeFixedWidthInteger<T>(_ value: T, for key: Key) throws where T: FixedWidthInteger {
      guard key.stringValue != "n" else { return }
      self.encoder.storage.append(value)
    }
    
    // MARK: - Unsupported Encodings
    
    mutating func encode(_ value: Float, forKey key: Key) throws {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Float values are not supported"))
    }
    
    mutating func encode(_ value: Double, forKey key: Key) throws {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Double values are not supported"))
    }
    
    mutating func encode(_ value: String, forKey key: Key) throws {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "String values are not supported"))
    }
    
    mutating func encode(_ value: Bool, forKey key: Key) throws {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Bool values are not supported"))
    }
    
    mutating func encodeNil(forKey key: Key) throws {
      throw EncodingError.invalidValue("", EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Nil values are not supported"))
    }
    
    // MARK: - Nested Containers
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
      return KeyedEncodingContainer(KeyedContainer<NestedKey>(encoder: encoder))
    }
    
    mutating func nestedUnkeyedContainer(forKey key: Key) -> Swift.UnkeyedEncodingContainer {
      return UnkeyedContainer(encoder: self.encoder, key: key)
    }
    
    mutating func superEncoder() -> Swift.Encoder {
      encoder
    }
    
    mutating func superEncoder(forKey key: Key) -> Swift.Encoder {
      encoder
    }
  }
}
