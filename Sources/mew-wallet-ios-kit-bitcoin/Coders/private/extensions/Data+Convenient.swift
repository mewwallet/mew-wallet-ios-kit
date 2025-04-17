//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/14/25.
//

import Foundation

extension Data {
  /// Moves the cursor forward by `offsetBy` bytes and returns the traversed range.
  ///
  /// - Parameters:
  ///   - cursor: The current index in the `Data` buffer (advanced in-place).
  ///   - offsetBy: Number of bytes to move forward.
  /// - Returns: A `Range<Data.Index>` representing the advanced region.
  /// - Throws: `DataReaderError.outOfBounds` if the cursor exceeds buffer bounds.
  @discardableResult
  internal func seek(_ cursor: inout Index, offsetBy: Int) throws(DataReaderError) -> Range<Self.Index> {
    guard cursor + offsetBy <= self.endIndex else { throw .outOfBounds }
    let newCursor = index(cursor, offsetBy: offsetBy)
    let range = cursor..<newCursor
    cursor = newCursor
    return range
  }
  
  /// Reads `offsetBy` bytes starting at the given cursor and advances it.
  ///
  /// - Parameters:
  ///   - cursor: Cursor position to read from (advanced in-place).
  ///   - offsetBy: Number of bytes to read.
  /// - Returns: A `SubSequence` view into the original `Data`.
  /// - Throws: `DataReaderError.outOfBounds` if out of bounds.
  internal func read(_ cursor: inout Index, offsetBy: Int) throws(DataReaderError) -> Data.SubSequence {
    guard cursor + offsetBy <= self.endIndex else { throw .outOfBounds }
    let newCursor = index(cursor, offsetBy: offsetBy)
    let data = self[cursor..<newCursor]
    cursor = newCursor
    return data
  }
  
  /// Reads `offsetBy` bytes from the cursor, reverses them, and returns the result.
  ///
  /// - Parameters:
  ///   - cursor: Cursor position to read from (advanced in-place).
  ///   - offsetBy: Number of bytes to read.
  /// - Returns: A reversed `Data` slice.
  /// - Throws: `DataReaderError.outOfBounds` if range is invalid.
  internal func readReversed(_ cursor: inout Index, offsetBy: Int) throws(DataReaderError) -> Data.SubSequence {
    return try Data(read(&cursor, offsetBy: offsetBy).reversed())
  }
  
  /// Reads a single byte at the cursor and advances.
  ///
  /// - Parameter cursor: Cursor to read from.
  /// - Returns: The byte read at the current position.
  /// - Throws: `DataReaderError.outOfBounds` if there is no data to read.
  internal func read(_ cursor: inout Index) throws(DataReaderError) -> Self.Element {
    return try self.read(&cursor, offsetBy: 1).first!
  }
  
  /// Reads a Bitcoin-style VarInt starting at the cursor.
  ///
  /// - Parameter cursor: Cursor to read from (advanced in-place).
  /// - Returns: A `VarInt` structure.
  /// - Throws: `.outOfBounds` or `.badValue` if invalid or truncated.
  internal func read(_ cursor: inout Index) throws(DataReaderError) -> _Reader.VarInt {
    guard cursor < self.endIndex else { throw DataReaderError.outOfBounds }
    do {
      let varInt = try _Reader.VarInt(head: self[cursor...])
      try self.seek(&cursor, offsetBy: varInt.size)
      return varInt
    } catch {
      throw DataReaderError.badValue
    }
  }
  
  /// Reads a fixed-width integer of type `T` from `cursor` using little-endian byte order.
  ///
  /// - Parameter cursor: Cursor to read from (advanced in-place).
  /// - Returns: The decoded integer value.
  /// - Throws: `.outOfBounds` or `.badSize` if the read is invalid.
  internal func readLE<T: FixedWidthInteger>(_ cursor: inout Index) throws(DataReaderError) -> T {
    let size = MemoryLayout<T>.size
    guard cursor + size <= self.endIndex else { throw DataReaderError.outOfBounds }
    let newCursor = index(cursor, offsetBy: size-1)
    let result: T = try self[cursor...newCursor].readLE()
    cursor = newCursor
    return result
  }
  
  /// Decodes a fixed-width integer from the data buffer assuming little-endian layout.
  ///
  /// - Returns: A decoded integer of type `T`.
  /// - Throws: `.badSize` if the data length does not match `T`'s size.
  internal func readLE<T: FixedWidthInteger>() throws(DataReaderError) -> T {
    guard self.count == MemoryLayout<T>.size else { throw DataReaderError.badSize }
    
    var result: T = 0
    var shift: T = 0
    
    // Iterate over the bytes. The iteration order is the same as the data’s natural order.
    // In little-endian, the least-significant byte comes first.
    for byte in self {
      result |= T(byte) << shift
      shift += 8
    }
    
    return result
  }
}
