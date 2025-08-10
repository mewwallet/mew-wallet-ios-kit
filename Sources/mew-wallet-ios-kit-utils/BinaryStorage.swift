//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/18/25.
//

import Foundation

/// A custom low-level binary buffer used by `Bitcoin.Encoder` and `Solana.ShortVecEncoder` for encoding transaction structures.
///
/// This class manages a manually allocated memory buffer that grows dynamically, allowing for efficient binary serialization
/// without intermediate allocations. It supports appending fixed-size primitives and raw byte buffers.
///
/// - Important: This buffer is *not* thread-safe.
/// - Warning: Once `encodedData()` is called, the buffer ownership is transferred and must not be mutated or deallocated manually.
package final class BinaryStorage {
  /// Pointer to the raw memory buffer.
  private var ptr: UnsafeMutableRawPointer
  
  /// Total capacity of the buffer in bytes.
  private var capacity: Int
  
  /// Number of bytes currently written into the buffer.
  package var length = 0
  
  /// Tracks whether ownership of the memory was transferred via `encodedData()`.
  private var didTransfer = false
  
  /// Initializes a new storage buffer with a given capacity.
  ///
  /// - Parameter initialCapacity: Initial size of the buffer in bytes (default is 4096).
  package init(initialCapacity: Int = 4096) {
    capacity = initialCapacity
    ptr = UnsafeMutableRawPointer.allocate(
      byteCount: capacity,
      alignment: MemoryLayout<UInt8>.alignment
    )
  }
  
  /// Deinitializes and deallocates memory unless ownership was transferred.
  deinit {
    guard !didTransfer else { return }
    ptr.deallocate()
  }
  
  /// Ensures the buffer has enough capacity to store an additional number of bytes.
  /// Grow the buffer (×2) if needed
  ///
  /// - Parameter additional: Number of bytes to be appended.
  private func ensureCapacity(_ additional: Int) {
    let needed = length + additional
    guard needed > capacity else { return }
    
    var newCap = capacity * 2
    while newCap < needed { newCap *= 2 }
    
    let newPtr = UnsafeMutableRawPointer.allocate(
      byteCount: newCap,
      alignment: MemoryLayout<UInt8>.alignment
    )
    newPtr.copyMemory(from: ptr, byteCount: length)
    ptr.deallocate()
    
    ptr = newPtr
    capacity = newCap
  }
  
  
  /// Appends the contents of another storage buffer.
  ///
  /// - If this buffer is empty, the other's buffer is taken via move semantics.
  /// - Otherwise, performs a full memory copy.
  ///
  /// - Parameter other: Another `Storage` buffer whose contents will be appended.
  package func append(storage other: BinaryStorage) {
    defer {
      other.didTransfer = true
    }
    // 1) if we're empty, just steal their pointer
    if self.length == 0 {
      // transfer ownership
      self.ptr       = other.ptr
      self.capacity  = other.capacity
      self.length    = other.length
      return
    }
    
    // 2) otherwise, grow+memcpy
    ensureCapacity(other.length)
    ptr
      .advanced(by: length)
      .copyMemory(from: other.ptr, byteCount: other.length)
    
    length += other.length
  }
  
  /// Appends a fixed-size primitive value (e.g. `UInt32`, `Int64`, etc.).
  ///
  /// - Parameter value: The fixed-width value to append in raw little-endian format.
  package func append<T>(_ value: T) {
    let size = MemoryLayout<T>.size
    ensureCapacity(size)
    withUnsafeBytes(of: value) { raw in
      ptr.advanced(by: length).copyMemory(from: raw.baseAddress!, byteCount: size)
    }
    length += size
  }
  
  /// Appends the bytes of a `DataProtocol`-conforming buffer (e.g. `Data`, `Array<UInt8>`).
  ///
  /// - Parameter value: Byte buffer to copy.
  package func append<D: DataProtocol>(_ value: D) {
    let size = value.count
    ensureCapacity(size)
    
    let dest = ptr.advanced(by: length).assumingMemoryBound(to: UInt8.self)
    let buffer = UnsafeMutableRawBufferPointer(start: dest, count: size)
    // 3) copy the bytes from the DataProtocol into it
    value.copyBytes(to: buffer)
    
    length += size
  }
  
  /// Transfers ownership of the buffer to a `Data` instance.
  ///
  /// - Returns: A `Data` instance that references the underlying memory directly (no copy).
  /// - Warning: Once called, the `Storage` instance must no longer be mutated or deallocated manually.
  package func encodedData() -> Data {
    didTransfer = true
    return Data(
      bytesNoCopy: ptr,
      count: length,
      deallocator: .free
    )
  }
}
