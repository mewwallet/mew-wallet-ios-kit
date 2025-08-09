//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/13/25.
//

import Foundation
import mew_wallet_ios_kit_utils

extension _Reader {
  /// Bitcoin-style variable-length integer.
  ///
  /// `VarInt` is used in Bitcoin serialization to represent integer values in a compact,
  /// space-efficient format. The number of bytes used depends on the value itself.
  ///
  /// ## Format:
  /// - `0x00...0xfc`: single-byte encoding
  /// - `0xfd`: next 2 bytes are a `UInt16`
  /// - `0xfe`: next 4 bytes are a `UInt32`
  /// - `0xff`: next 8 bytes are a `UInt64`
  ///
  /// ## Usage:
  /// - Use `init(head:)` to parse from data.
  /// - Use `write(to:)` to encode into a byte buffer.
  struct VarInt: RawRepresentable, Equatable, Sendable {
    /// Error type thrown during VarInt parsing.
    enum Error: Swift.Error {
      /// Data was empty, no byte to read
      case emptyData
      
      /// First byte did not match expected VarInt prefix rules
      case invalidData
      
      /// Declared length exceeded available data
      case tooShort
    }
    
    /// The decoded integer value.
    let rawValue: UInt64
    
    /// Number of bytes this integer will occupy when encoded.
    var size: Int {
      switch rawValue {
      case ..<0xfd:         return 1
      case ..<0xffff:       return 3
      case ..<0xffffffff:   return 5
      default:              return 9
      }
    }
    
    /// Returns the `rawValue` as a standard `Int`, clamped if necessary.
    var value: Int {
      Int(exactly: rawValue) ?? 0
    }
    
    init(rawValue: UInt64) {
      self.rawValue = rawValue
    }
    
    init(rawValue: Int) {
      self.init(rawValue: UInt64(clamping: rawValue))
    }
    
    /// Decodes a `VarInt` from the start of the given data buffer.
    ///
    /// - Parameter head: A data buffer starting with a `VarInt`.
    /// - Throws: `VarIntError.tooShort` or `.invalidData` if parsing fails.
    init(head: Data.SubSequence) throws(VarInt.Error) {
      var cursor = head.startIndex
      do {
        let firstByte: UInt8 = try head.read(&cursor)
        switch firstByte {
        case 0x00...0xfc:
          rawValue = UInt64(firstByte)
        case 0xfd:
          let value: UInt16 = try head.readLE(&cursor)
          rawValue = UInt64(value)
        case 0xfe:
          let value: UInt32 = try head.readLE(&cursor)
          rawValue = UInt64(value)
        case 0xff:
          let value: UInt64 = try head.readLE(&cursor)
          rawValue = value
        default:
          throw VarInt.Error.invalidData
        }
      } catch let error as VarInt.Error {
        throw error
      } catch {
        throw .tooShort
      }
    }
    
    /// Encodes the `VarInt` value into a binary buffer using Bitcoin's variable-length format.
    ///
    /// - Parameter storage: Target buffer to append encoded bytes.
    func write(to storage: BinaryStorage) {
      switch rawValue {
      case ..<0xfd:
        storage.append(UInt8(rawValue))
      case ..<0xffff:
        storage.append(UInt8(0xfd))
        storage.append(UInt16(rawValue).littleEndian)
      case ..<0xffffffff:
        storage.append(UInt8(0xfe))
        storage.append(UInt32(rawValue).littleEndian)
      default:
        storage.append(UInt8(0xff))
        storage.append(rawValue.littleEndian)
      }
    }
  }
}
