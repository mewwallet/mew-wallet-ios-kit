//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/9/25.
//

import Foundation
import BigInt

/// A convenience composition of both endian encodings.
/// Conforming values can produce **both** big-endian and little-endian byte arrays.
///
/// You typically use this as an existential for mixed payloads:
/// ```swift
/// let items: [any EndianBytesEncodable] = [UInt16(0x1234), true, Data([0xDE, 0xAD])]
/// let le = items.littleEndianBytes   // [0x34, 0x12, 0x01, 0xDE, 0xAD]
/// let be = items.bigEndianBytes      // [0x12, 0x34, 0x01, 0xDE, 0xAD]
/// ```
public typealias EndianBytesEncodable = BigEndianBytesEncodable & LittleEndianBytesEncodable

// MARK: - Big endian

/// Types that can encode themselves as **big-endian** byte arrays (network order).
///
/// - Important: For integer types, the resulting bytes are stable across platforms
///   because they are explicitly converted to `.bigEndian` before extraction.
public protocol BigEndianBytesEncodable {
  /// The value encoded as a big-endian byte array.
  var bigEndianBytes: [UInt8] { get }
}

extension UInt8:  BigEndianBytesEncodable {}
extension UInt16: BigEndianBytesEncodable {}
extension UInt32: BigEndianBytesEncodable {}
extension UInt64: BigEndianBytesEncodable {}
extension Bool:   BigEndianBytesEncodable {}
extension Data:   BigEndianBytesEncodable {}

public extension BigEndianBytesEncodable where Self: FixedWidthInteger {
  /// Default big-endian encoding for fixed-width integers.
  ///
  /// ```swift
  /// let v: UInt32 = 0x11223344
  /// v.bigEndianBytes  // [0x11, 0x22, 0x33, 0x44]
  /// ```
  @inlinable
  var bigEndianBytes: [UInt8] {
    withUnsafeBytes(of: self.bigEndian) { Array($0) }
  }
}

public extension BigEndianBytesEncodable where Self == Bool {
  /// Encodes `true` as `[1]` and `false` as `[0]`.
  @inlinable
  var bigEndianBytes: [UInt8] { self ? [1] : [0] }
}

public extension BigEndianBytesEncodable where Self == Data {
  /// For `Data`, bytes are returned as-is (endianness is not applicable).
  @inlinable
  var bigEndianBytes: [UInt8] { Array(self) }
}

/// Default big-endian encoding for enums with integer raw values.
/// Conform your enum to `BigEndianBytesEncodable` to use this implementation.
/// ```swift
/// enum Op: UInt16, BigEndianBytesEncodable { case a = 0x1234 }
/// Op.a.bigEndianBytes  // [0x12, 0x34]
/// ```
public extension BigEndianBytesEncodable where Self: RawRepresentable, RawValue: FixedWidthInteger {
  @inlinable
  var bigEndianBytes: [UInt8] {
    withUnsafeBytes(of: rawValue.bigEndian) { Array($0) }
  }
}

extension BigUInt: BigEndianBytesEncodable {
  /// `BigUInt.serialize()` is big-endian without leading zeros.
  @inlinable
  public var bigEndianBytes: [UInt8] {
    Array(self.serialize())
  }
}

extension BigInt: BigEndianBytesEncodable {
  /// Encodes the magnitude in big-endian (no two’s complement).
  @inlinable
  public var bigEndianBytes: [UInt8] {
    self.magnitude.bigEndianBytes
  }
}

// MARK: - Little endian

/// Types that can encode themselves as **little-endian** byte arrays.
///
/// - Important: For integer types, the resulting bytes are stable across platforms
///   because they are explicitly converted to `.littleEndian` before extraction.
public protocol LittleEndianBytesEncodable {
  /// The value encoded as a little-endian byte array.
  var littleEndianBytes: [UInt8] { get }
}

extension UInt8:  LittleEndianBytesEncodable {}
extension UInt16: LittleEndianBytesEncodable {}
extension UInt32: LittleEndianBytesEncodable {}
extension UInt64: LittleEndianBytesEncodable {}
extension Bool:   LittleEndianBytesEncodable {}
extension Data:   LittleEndianBytesEncodable {}

public extension LittleEndianBytesEncodable where Self: FixedWidthInteger {
  /// Default little-endian encoding for fixed-width integers.
  ///
  /// ```swift
  /// let v: UInt32 = 0x11223344
  /// v.littleEndianBytes  // [0x44, 0x33, 0x22, 0x11]
  /// ```
  @inlinable
  var littleEndianBytes: [UInt8] {
    withUnsafeBytes(of: self.littleEndian) { Array($0) }
  }
}

public extension LittleEndianBytesEncodable where Self == Bool {
  /// Encodes `true` as `[1]` and `false` as `[0]`.
  @inlinable
  var littleEndianBytes: [UInt8] { self ? [1] : [0] }
}

public extension LittleEndianBytesEncodable where Self == Data {
  /// For `Data`, bytes are returned as-is (endianness is not applicable).
  @inlinable
  var littleEndianBytes: [UInt8] { Array(self) }
}

/// Default little-endian encoding for enums with integer raw values.
/// Conform your enum to `LittleEndianBytesEncodable` to use this implementation.
/// ```swift
/// enum Op: UInt16, LittleEndianBytesEncodable { case a = 0x1234 }
/// Op.a.littleEndianBytes  // [0x34, 0x12]
/// ```
public extension LittleEndianBytesEncodable where Self: RawRepresentable, RawValue: FixedWidthInteger {
  @inlinable
  var littleEndianBytes: [UInt8] {
    withUnsafeBytes(of: rawValue.littleEndian) { Array($0) }
  }
}

extension BigUInt: LittleEndianBytesEncodable {
  /// Little-endian from `BigUInt` by reversing its big-endian serialization.
  @inlinable
  public var littleEndianBytes: [UInt8] {
    return self.serialize().reversed()
  }
}

extension BigInt: LittleEndianBytesEncodable {
  /// Encodes the magnitude in little-endian (no two’s complement).
  @inlinable
  public var littleEndianBytes: [UInt8] {
    self.magnitude.littleEndianBytes
  }
}

// MARK: - Sequences

public extension Sequence where Element: LittleEndianBytesEncodable {
  /// Concatenates little-endian encodings of all elements in the sequence.
  ///
  /// Works for any sequence (`Array`, `Set`, `Slice`, etc.) whose elements
  /// conform to `LittleEndianBytesEncodable`.
  ///
  /// ```swift
  /// let xs: [UInt16] = [0x1234, 0xABCD]
  /// xs.littleEndianBytes  // [0x34, 0x12, 0xCD, 0xAB]
  /// ```
  @inlinable
  var littleEndianBytes: [UInt8] { flatMap { $0.littleEndianBytes } }
}
public extension Sequence where Element: BigEndianBytesEncodable {
  /// Concatenates big-endian encodings of all elements in the sequence.
  ///
  /// Works for any sequence (`Array`, `Set`, `Slice`, etc.) whose elements
  /// conform to `BigEndianBytesEncodable`.
  ///
  /// ```swift
  /// let xs: [UInt16] = [0x1234, 0xABCD]
  /// xs.bigEndianBytes  // [0x12, 0x34, 0xAB, 0xCD]
  /// ```
  @inlinable
  var bigEndianBytes: [UInt8] { flatMap { $0.bigEndianBytes } }
}

// MARK: - Mixed existential arrays

public extension Array where Element == any EndianBytesEncodable {
  /// Concatenates **little-endian** encodings for a mixed array of existential elements.
  ///
  /// Useful when the array contains heterogeneous types, e.g. `[UInt16, Bool, Data]`.
  ///
  /// ```swift
  /// let mixed: [any EndianBytesEncodable] = [UInt8(0xAA), UInt16(0x1234), true]
  /// mixed.littleEndianBytes  // [0xAA, 0x34, 0x12, 0x01]
  /// ```
  @inlinable
  var littleEndianBytes: [UInt8] { flatMap { $0.littleEndianBytes } }
  
  /// Concatenates **big-endian** encodings for a mixed array of existential elements.
  ///
  /// ```swift
  /// let mixed: [any EndianBytesEncodable] = [UInt8(0xAA), UInt16(0x1234), true]
  /// mixed.bigEndianBytes  // [0xAA, 0x12, 0x34, 0x01]
  /// ```
  @inlinable
  var bigEndianBytes: [UInt8] { flatMap { $0.bigEndianBytes } }
}

// MARK: - Sequences of RawRepresentable integers (no protocol conformance needed)

public extension Sequence where Element: RawRepresentable, Element.RawValue: FixedWidthInteger {
  /// Concatenates little-endian encodings of raw integer values.
  @inlinable
  var littleEndianBytes: [UInt8] {
    flatMap { elem in
      withUnsafeBytes(of: elem.rawValue.littleEndian) { Array($0) }
    }
  }

  /// Concatenates big-endian encodings of raw integer values.
  @inlinable
  var bigEndianBytes: [UInt8] {
    flatMap { elem in
      withUnsafeBytes(of: elem.rawValue.bigEndian) { Array($0) }
    }
  }
}
