//
//  EndianBytesDecodable.swift
//  mew-wallet-ios-kit-utils
//
//  Created by Mikhail Nikanorov on 8/9/25.
//

import Foundation
import BigInt

// MARK: - BigEndianBytesDecodable

/// Protocol for types that can be decoded from big-endian byte arrays.
public protocol BigEndianBytesDecodable {
    /// Decodes a value from a big-endian byte array.
    /// - Parameter bytes: The byte array to decode from
    /// - Returns: The decoded value, or `nil` if decoding fails
    static func decode(fromBigEndian bytes: [UInt8]) -> Self?

    /// Decodes an array of values from a big-endian byte array.
    /// - Parameters:
    ///   - size: Number of elements to decode
    ///   - type: The type to decode to
    ///   - bytes: The byte array to decode from
    ///   - cursor: The starting position in the byte array (will be updated)
    /// - Returns: An array of decoded values, or `nil` if decoding fails
    static func decodeArrayBigEndian<T: BigEndianBytesDecodable>(size: Int, type: T.Type, from bytes: [UInt8], cursor: inout Int) -> [T]?

    /// Decodes a value from a big-endian byte array at a specific cursor position.
    /// - Parameters:
    ///   - bytes: The byte array to decode from
    ///   - cursor: The starting position in the byte array (will be updated)
    /// - Returns: The decoded value, or `nil` if decoding fails
    static func decode(fromBigEndian bytes: [UInt8], cursor: inout Int) -> Self?
}

// MARK: - LittleEndianBytesDecodable

/// Protocol for types that can be decoded from little-endian byte arrays.
public protocol LittleEndianBytesDecodable {
    /// Decodes a value from a little-endian byte array.
    /// - Parameter bytes: The byte array to decode from
    /// - Returns: The decoded value, or `nil` if decoding fails
    static func decode(fromLittleEndian bytes: [UInt8]) -> Self?

    /// Decodes an array of values from a little-endian byte array.
    /// - Parameters:
    ///   - size: Number of elements to decode
    ///   - type: The type to decode to
    ///   - bytes: The byte array to decode from
    ///   - cursor: The starting position in the byte array (will be updated)
    /// - Returns: An array of decoded values, or `nil` if decoding fails
    static func decodeArrayLittleEndian<T: LittleEndianBytesDecodable>(size: Int, type: T.Type, from bytes: [UInt8], cursor: inout Int) -> [T]?

    /// Decodes a value from a little-endian byte array at a specific cursor position.
    /// - Parameters:
    ///   - bytes: The byte array to decode from
    ///   - cursor: The starting position in the byte array (will be updated)
    /// - Returns: The decoded value, or `nil` if decoding fails
    static func decode(fromLittleEndian bytes: [UInt8], cursor: inout Int) -> Self?
}

// MARK: - EndianBytesDecodable

/// Type alias combining both endian decodable protocols.
public typealias EndianBytesDecodable = BigEndianBytesDecodable & LittleEndianBytesDecodable

// MARK: - FixedWidthInteger Extensions

extension UInt8: BigEndianBytesDecodable, LittleEndianBytesDecodable {}
extension UInt16: BigEndianBytesDecodable, LittleEndianBytesDecodable {}
extension UInt32: BigEndianBytesDecodable, LittleEndianBytesDecodable {}
extension UInt64: BigEndianBytesDecodable, LittleEndianBytesDecodable {}

public extension BigEndianBytesDecodable where Self: FixedWidthInteger {
    static func decode(fromBigEndian bytes: [UInt8]) -> Self? {
        guard bytes.count >= MemoryLayout<Self>.size else { return nil }
        let data = Data(bytes.prefix(MemoryLayout<Self>.size))
        return data.withUnsafeBytes { $0.load(as: Self.self).bigEndian }
    }

    static func decodeArrayBigEndian<T: BigEndianBytesDecodable>(size: Int, type: T.Type, from bytes: [UInt8], cursor: inout Int) -> [T]? {
        var result: [T] = []
        let elementSize = MemoryLayout<T>.size

        for _ in 0..<size {
            guard cursor + elementSize <= bytes.count else { return nil }
            guard let element = T.decode(fromBigEndian: Array(bytes[cursor..<(cursor + elementSize)])) else { return nil }
            result.append(element)
            cursor += elementSize
        }

        return result
    }

    static func decode(fromBigEndian bytes: [UInt8], cursor: inout Int) -> Self? {
        guard cursor + MemoryLayout<Self>.size <= bytes.count else { return nil }
        let elementBytes = Array(bytes[cursor..<(cursor + MemoryLayout<Self>.size)])
        cursor += MemoryLayout<Self>.size
        return decode(fromBigEndian: elementBytes)
    }
}

public extension LittleEndianBytesDecodable where Self: FixedWidthInteger {
    static func decode(fromLittleEndian bytes: [UInt8]) -> Self? {
        guard bytes.count >= MemoryLayout<Self>.size else { return nil }
        let data = Data(bytes.prefix(MemoryLayout<Self>.size))
        return data.withUnsafeBytes { $0.load(as: Self.self).littleEndian }
    }

    static func decodeArrayLittleEndian<T: LittleEndianBytesDecodable>(size: Int, type: T.Type, from bytes: [UInt8], cursor: inout Int) -> [T]? {
        var result: [T] = []
        let elementSize = MemoryLayout<T>.size

        for _ in 0..<size {
            guard cursor + elementSize <= bytes.count else { return nil }
            guard let element = T.decode(fromLittleEndian: Array(bytes[cursor..<(cursor + elementSize)])) else { return nil }
            result.append(element)
            cursor += elementSize
        }

        return result
    }

    static func decode(fromLittleEndian bytes: [UInt8], cursor: inout Int) -> Self? {
        guard cursor + MemoryLayout<Self>.size <= bytes.count else { return nil }
        let elementBytes = Array(bytes[cursor..<(cursor + MemoryLayout<Self>.size)])
        cursor += MemoryLayout<Self>.size
        return decode(fromLittleEndian: elementBytes)
    }
}

// MARK: - Bool Extension

extension Bool: BigEndianBytesDecodable {
    public static func decode(fromBigEndian bytes: [UInt8]) -> Self? {
        guard bytes.count >= 1 else { return nil }
        return bytes[0] != 0
    }

    public static func decodeArrayBigEndian<T: BigEndianBytesDecodable>(size: Int, type: T.Type, from bytes: [UInt8], cursor: inout Int) -> [T]? {
        var result: [T] = []

        for _ in 0..<size {
            guard cursor + 1 <= bytes.count else { return nil }
            guard let element = T.decode(fromBigEndian: [bytes[cursor]]) else { return nil }
            result.append(element)
            cursor += 1
        }

        return result
    }

    public static func decode(fromBigEndian bytes: [UInt8], cursor: inout Int) -> Self? {
        guard cursor + 1 <= bytes.count else { return nil }
        let value = bytes[cursor] != 0
        cursor += 1
        return value
    }
}

extension Bool: LittleEndianBytesDecodable {
    public static func decode(fromLittleEndian bytes: [UInt8]) -> Self? {
        guard bytes.count >= 1 else { return nil }
        return bytes[0] != 0
    }

    public static func decodeArrayLittleEndian<T: LittleEndianBytesDecodable>(size: Int, type: T.Type, from bytes: [UInt8], cursor: inout Int) -> [T]? {
        var result: [T] = []

        for _ in 0..<size {
            guard cursor + 1 <= bytes.count else { return nil }
            guard let element = T.decode(fromLittleEndian: [bytes[cursor]]) else { return nil }
            result.append(element)
            cursor += 1
        }

        return result
    }

    public static func decode(fromLittleEndian bytes: [UInt8], cursor: inout Int) -> Self? {
        guard cursor + 1 <= bytes.count else { return nil }
        let value = bytes[cursor] != 0
        cursor += 1
        return value
    }
}

// MARK: - Data Extension

extension Data: BigEndianBytesDecodable {
    public static func decode(fromBigEndian bytes: [UInt8]) -> Self? {
        return Data(bytes)
    }

    public static func decodeArrayBigEndian<T: BigEndianBytesDecodable>(size: Int, type: T.Type, from bytes: [UInt8], cursor: inout Int) -> [T]? {
        // For Data, we need to handle variable size differently
        // This is a placeholder - Data decoding should use a different approach
        return nil
    }

    public static func decode(fromBigEndian bytes: [UInt8], cursor: inout Int) -> Self? {
        // For Data, we need to handle variable size differently
        // This is a placeholder - Data decoding should use a different approach
        return nil
    }
}

extension Data: LittleEndianBytesDecodable {
    public static func decode(fromLittleEndian bytes: [UInt8]) -> Self? {
        return Data(bytes)
    }

    public static func decodeArrayLittleEndian<T: LittleEndianBytesDecodable>(size: Int, type: T.Type, from bytes: [UInt8], cursor: inout Int) -> [T]? {
        // For Data, we need to handle variable size differently
        // This is a placeholder - Data decoding should use a different approach
        return nil
    }

    public static func decode(fromLittleEndian bytes: [UInt8], cursor: inout Int) -> Self? {
        // For Data, we need to handle variable size differently
        // This is a placeholder - Data decoding should use a different approach
        return nil
    }
}

// MARK: - BigUInt Extension

extension BigUInt: BigEndianBytesDecodable {
    public static func decode(fromBigEndian bytes: [UInt8]) -> Self? {
        return BigUInt(Data(bytes))
    }

    public static func decodeArrayBigEndian<T: BigEndianBytesDecodable>(size: Int, type: T.Type, from bytes: [UInt8], cursor: inout Int) -> [T]? {
        var result: [T] = []

        for _ in 0..<size {
            guard cursor + 1 <= bytes.count else { return nil }
            // For BigUInt, we need to determine the size dynamically
            // This is a simplified approach
            let elementBytes = Array(bytes[cursor...])
            guard let element = T.decode(fromBigEndian: elementBytes) else { return nil }
            result.append(element)
            // Note: This doesn't advance cursor properly for variable-size types
            cursor += 1
        }

        return result
    }

    public static func decode(fromBigEndian bytes: [UInt8], cursor: inout Int) -> Self? {
        // For BigUInt, we need to determine the size dynamically
        // This is a simplified approach
        return BigUInt.decode(fromBigEndian: Array(bytes[cursor...]))
    }
}

extension BigUInt: LittleEndianBytesDecodable {
    public static func decode(fromLittleEndian bytes: [UInt8]) -> Self? {
        return BigUInt(Data(bytes.reversed()))
    }

    public static func decodeArrayLittleEndian<T: LittleEndianBytesDecodable>(size: Int, type: T.Type, from bytes: [UInt8], cursor: inout Int) -> [T]? {
        var result: [T] = []

        for _ in 0..<size {
            guard cursor + 1 <= bytes.count else { return nil }
            // For BigUInt, we need to determine the size dynamically
            // This is a simplified approach
            let elementBytes = Array(bytes[cursor...])
            guard let element = T.decode(fromLittleEndian: elementBytes) else { return nil }
            result.append(element)
            // Note: This doesn't advance cursor properly for variable-size types
            cursor += 1
        }

        return result
    }

    public static func decode(fromLittleEndian bytes: [UInt8], cursor: inout Int) -> Self? {
        // For BigUInt, we need to determine the size dynamically
        // This is a simplified approach
        return BigUInt.decode(fromLittleEndian: Array(bytes[cursor...]))
    }
}

// MARK: - BigInt Extension

extension BigInt: BigEndianBytesDecodable {
    public static func decode(fromBigEndian bytes: [UInt8]) -> Self? {
        // BigInt should decode as magnitude (unsigned), consistent with encoding tests
        // Use BigUInt to get the magnitude, then convert to BigInt
        guard let magnitude = BigUInt.decode(fromBigEndian: bytes) else { return nil }
        return BigInt(magnitude)
    }

    public static func decodeArrayBigEndian<T: BigEndianBytesDecodable>(size: Int, type: T.Type, from bytes: [UInt8], cursor: inout Int) -> [T]? {
        var result: [T] = []

        for _ in 0..<size {
            guard cursor + 1 <= bytes.count else { return nil }
            // For BigInt, we need to determine the size dynamically
            // This is a simplified approach
            let elementBytes = Array(bytes[cursor...])
            guard let element = T.decode(fromBigEndian: elementBytes) else { return nil }
            result.append(element)
            // Note: This doesn't advance cursor properly for variable-size types
            cursor += 1
        }

        return result
    }

    public static func decode(fromBigEndian bytes: [UInt8], cursor: inout Int) -> Self? {
        // For BigInt, we need to determine the size dynamically
        // This is a simplified approach
        return BigInt.decode(fromBigEndian: Array(bytes[cursor...]))
    }
}

extension BigInt: LittleEndianBytesDecodable {
    public static func decode(fromLittleEndian bytes: [UInt8]) -> Self? {
        // BigInt should decode as magnitude (unsigned), consistent with encoding tests
        // Use BigUInt to get the magnitude, then convert to BigInt
        guard let magnitude = BigUInt.decode(fromLittleEndian: bytes) else { return nil }
        return BigInt(magnitude)
    }

    public static func decodeArrayLittleEndian<T: LittleEndianBytesDecodable>(size: Int, type: T.Type, from bytes: [UInt8], cursor: inout Int) -> [T]? {
        var result: [T] = []

        for _ in 0..<size {
            guard cursor + 1 <= bytes.count else { return nil }
            // For BigInt, we need to determine the size dynamically
            // This is a simplified approach
            let elementBytes = Array(bytes[cursor...])
            guard let element = T.decode(fromLittleEndian: elementBytes) else { return nil }
            result.append(element)
            // Note: This doesn't advance cursor properly for variable-size types
            cursor += 1
        }

        return result
    }

    public static func decode(fromLittleEndian bytes: [UInt8], cursor: inout Int) -> Self? {
        // For BigInt, we need to determine the size dynamically
        // This is a simplified approach
        return BigInt.decode(fromLittleEndian: Array(bytes[cursor...]))
    }
}

// MARK: - RawRepresentable Extension

public extension RawRepresentable where Self.RawValue: FixedWidthInteger & BigEndianBytesDecodable {
    static func decode(fromBigEndian bytes: [UInt8]) -> Self? {
        guard let rawValue = RawValue.decode(fromBigEndian: bytes) else { return nil }
        return Self(rawValue: rawValue)
    }

    static func decodeArrayBigEndian<T: BigEndianBytesDecodable>(size: Int, type: T.Type, from bytes: [UInt8], cursor: inout Int) -> [T]? {
        // If T is Self (the enum type), decode arrays of the enum type itself
        if T.self == Self.self {
            var result: [Self] = []
            let elementSize = MemoryLayout<RawValue>.size
            
            for _ in 0..<size {
                guard cursor + elementSize <= bytes.count else { return nil }
                let elementBytes = Array(bytes[cursor..<(cursor + elementSize)])
                guard let element = Self.decode(fromBigEndian: elementBytes) else { return nil }
                result.append(element)
                cursor += elementSize
            }
            return result as? [T]
        }
        
        // Otherwise, fall back to generic decoding
        var result: [T] = []
        for _ in 0..<size {
            guard let element = T.decode(fromBigEndian: bytes, cursor: &cursor) else { return nil }
            result.append(element)
        }
        return result
    }

    // Add method to decode arrays of the enum type itself
    static func decodeArrayBigEndian(size: Int, from bytes: [UInt8], cursor: inout Int) -> [Self]? {
        var result: [Self] = []
        let elementSize = MemoryLayout<RawValue>.size

        for _ in 0..<size {
            guard cursor + elementSize <= bytes.count else { return nil }
            let elementBytes = Array(bytes[cursor..<(cursor + elementSize)])
            guard let element = Self.decode(fromBigEndian: elementBytes) else { return nil }
            result.append(element)
            cursor += elementSize
        }

        return result
    }



    static func decode(fromBigEndian bytes: [UInt8], cursor: inout Int) -> Self? {
        guard let rawValue = RawValue.decode(fromBigEndian: bytes, cursor: &cursor) else { return nil }
        return Self(rawValue: rawValue)
    }

}

public extension RawRepresentable where Self.RawValue: FixedWidthInteger & LittleEndianBytesDecodable {
    static func decode(fromLittleEndian bytes: [UInt8]) -> Self? {
        guard let rawValue = RawValue.decode(fromLittleEndian: bytes) else { return nil }
        return Self(rawValue: rawValue)
    }

    static func decodeArrayLittleEndian<T: LittleEndianBytesDecodable>(size: Int, type: T.Type, from bytes: [UInt8], cursor: inout Int) -> [T]? {
        // If T is Self (the enum type), decode arrays of the enum type itself
        if T.self == Self.self {
            var result: [Self] = []
            let elementSize = MemoryLayout<RawValue>.size
            
            for _ in 0..<size {
                guard cursor + elementSize <= bytes.count else { return nil }
                let elementBytes = Array(bytes[cursor..<(cursor + elementSize)])
                guard let element = Self.decode(fromLittleEndian: elementBytes) else { return nil }
                result.append(element)
                cursor += elementSize
            }
            return result as? [T]
        }
        
        // Otherwise, fall back to generic decoding
        var result: [T] = []
        for _ in 0..<size {
            guard let element = T.decode(fromLittleEndian: bytes, cursor: &cursor) else { return nil }
            result.append(element)
        }
        return result
    }

    // Add method to decode arrays of the enum type itself
    static func decodeArrayLittleEndian(size: Int, from bytes: [UInt8], cursor: inout Int) -> [Self]? {
        var result: [Self] = []
        let elementSize = MemoryLayout<RawValue>.size

        for _ in 0..<size {
            guard cursor + elementSize <= bytes.count else { return nil }
            let elementBytes = Array(bytes[cursor..<(cursor + elementSize)])
            guard let element = Self.decode(fromLittleEndian: elementBytes) else { return nil }
            result.append(element)
            cursor += elementSize
        }

        return result
    }

    static func decode(fromLittleEndian bytes: [UInt8], cursor: inout Int) -> Self? {
        guard let rawValue = RawValue.decode(fromLittleEndian: bytes, cursor: &cursor) else { return nil }
        return Self(rawValue: rawValue)
    }
}


/// Byte order for decoding
public enum Endianness {
    case bigEndian
    case littleEndian
}

/// A context that describes how to decode a specific type from bytes.
public struct DecodeContext<T: EndianBytesDecodable> {
    /// The number of elements of this type to decode
    public let size: Int

    /// The type to decode
    public let type: T.Type

    /// Whether to use big-endian or little-endian byte order
    public let endianness: Endianness

    /// Creates a decode context for big-endian decoding
    /// - Parameters:
    ///   - size: Number of elements to decode
    ///   - type: The type to decode to
    /// - Returns: A decode context configured for big-endian decoding
    public static func bigEndian(size: Int, type: T.Type) -> DecodeContext<T> {
        DecodeContext(size: size, type: type, endianness: .bigEndian)
    }

    /// Creates a decode context for little-endian decoding
    /// - Parameters:
    ///   - size: Number of elements to decode
    ///   - type: The type to decode to
    /// - Returns: A decode context configured for little-endian decoding
    public static func littleEndian(size: Int, type: T.Type) -> DecodeContext<T> {
        DecodeContext(size: size, type: type, endianness: .littleEndian)
    }
}

// MARK: - Array Extension for Mixed Type Decoding

public extension Array where Element == UInt8 {
    /// Decodes a mixed array of values from bytes using decode contexts.
    /// - Parameter contexts: Array of decode contexts describing what to decode
    /// - Returns: An array of decoded values, or `nil` if decoding fails
    func decode(contexts: [any DecodeContextProtocol]) -> [Any]? {
        var cursor = 0
        var result: [Any] = []

        for context in contexts {
            switch context.endianness {
            case .bigEndian:
                guard let decoded = context.decodeBigEndian(from: self, cursor: &cursor) else {
                    return nil
                }
                result.append(contentsOf: decoded)

            case .littleEndian:
                guard let decoded = context.decodeLittleEndian(from: self, cursor: &cursor) else {
                    return nil
                }
                result.append(contentsOf: decoded)
            }
        }

        return result
    }

    /// Helper method to decode big-endian values for a given context
    private func decodeBigEndian<T: EndianBytesDecodable>(
        context: DecodeContext<T>,
        cursor: inout Int
    ) -> [Any]? {
        // Since we know T conforms to EndianBytesDecodable, we can use it directly
        return T.decodeArrayBigEndian(size: context.size, type: T.self, from: self, cursor: &cursor)
    }

    /// Helper method to decode little-endian values for a given context
    private func decodeLittleEndian<T: EndianBytesDecodable>(
        context: DecodeContext<T>,
        cursor: inout Int
    ) -> [T]? {
        // Since we know T conforms to EndianBytesDecodable, we can use it directly
        return T.decodeArrayLittleEndian(size: context.size, type: T.self, from: self, cursor: &cursor)
    }
}

// MARK: - DecodeContext Protocol for Mixed Types

/// Protocol that allows DecodeContext to work with mixed types
public protocol DecodeContextProtocol {
    var size: Int { get }
    var endianness: Endianness { get }

    func decodeBigEndian(from bytes: [UInt8], cursor: inout Int) -> [Any]?
    func decodeLittleEndian(from bytes: [UInt8], cursor: inout Int) -> [Any]?
}

extension DecodeContext: DecodeContextProtocol {
  public func decodeBigEndian(from bytes: [UInt8], cursor: inout Int) -> [Any]? {
    // Special case for Data: just take raw bytes and convert to Data
    if T.self == Data.self {
      guard cursor + size <= bytes.count else { return nil }
      let dataBytes = Array(bytes[cursor..<(cursor + size)])
      cursor += size
      return [Data(dataBytes)]
    }
    
    // Use the generic array decoding method for other types
    guard let result = T.decodeArrayBigEndian(size: size, type: T.self, from: bytes, cursor: &cursor) else {
      return nil
    }
    return result.map { $0 as Any }
  }
  
  public func decodeLittleEndian(from bytes: [UInt8], cursor: inout Int) -> [Any]? {
    // Special case for Data: just take raw bytes and convert to Data
    if T.self == Data.self {
      guard cursor + size <= bytes.count else { return nil }
      let dataBytes = Array(bytes[cursor..<(cursor + size)])
      cursor += size
      return [Data(dataBytes)]
    }
    
    // Use the generic array decoding method for other types
    guard let result = T.decodeArrayLittleEndian(size: size, type: T.self, from: bytes, cursor: &cursor) else {
      return nil
    }
    return result.map { $0 as Any }
  }
}
