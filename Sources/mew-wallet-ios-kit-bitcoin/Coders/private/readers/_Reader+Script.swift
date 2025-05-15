//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/15/25.
//

import Foundation

extension _Reader {
  /// A Bitcoin script parser conforming to `DataReader` and `KeypathProvider`.
  ///
  /// This reader parses a raw Bitcoin script (locking or unlocking) into a linear sequence
  /// of opcodes and PUSHDATA payloads. The result is exposed through the `.script` array,
  /// where each entry is a raw `Data.SubSequence` representing either an opcode byte or
  /// a pushed data chunk.
  ///
  /// - Note: This reader does not interpret opcode semantics or validate the script.
  /// - Important: Script parsing is tolerant to malformed data sizes, but will throw
  ///   `.badValue` or `.outOfBounds` if declared lengths are invalid.
  internal struct Script: KeypathProvider, DataReader {
    /// The original binary script payload.
    internal let raw: Data.SubSequence
    
    /// Optional decoding context (usually unused for scripts).
    internal let context: DataReaderContext?
    
    /// Parsed script as a list of opcodes and data pushes.
    var script: [Data.SubSequence]?
    
    /// There are no known named single-value fields in a script.
    nonisolated(unsafe) static var keyPathSingle: [String : KeyPath<_Reader.Script, Data.SubSequence?>] = [:]
    
    /// Multi-value fields for script analysis.
    /// - `"asm"`: exposes parsed `Data.SubSequence` ops as-is.
    nonisolated(unsafe) static var keyPathMany: [String : KeyPath<_Reader.Script, [Data.SubSequence]?>] = [
      "asm": \.script,
      "script": \.script
    ]
    
    /// Parses the script into opcode/data fragments.
    ///
    /// - Parameters:
    ///   - data: The full script data.
    ///   - context: Optional decoding context.
    ///   - configuration: Decoder configuration (unused).
    /// - Throws: `DataReaderError.badValue` or `.outOfBounds` on malformed structure.
    init(data: Data.SubSequence, context: DataReaderContext?, configuration: DataReaderConfiguration) throws(DataReaderError) {
      self.raw = data
      self.context = context
      
      var script: [Data.SubSequence] = []
      var cursor = data.startIndex

      // Parse opcodes and pushdata segments
      while cursor != data.endIndex {
        let op = data[cursor]
        switch op {
          // ._OP_PUSHBYTES(Data) + payload
        case 0x01...0x4b:
          try script.append(data.read(&cursor, offsetBy: Int(op)+1))
          
          // .OP_PUSHDATA1: 1-byte size prefix
        case 0x4c:
          let size: UInt8 = try data[cursor+1...cursor+1].readLE()
          try script.append(data.read(&cursor, offsetBy: 2 + Int(size)))
          
          // .OP_PUSHDATA2: 2-byte size prefix
        case 0x4d:
          let size: UInt16 = try data[cursor+1...cursor+2].readLE()
          try script.append(data.read(&cursor, offsetBy: 3 + Int(size)))
          
          // .OP_PUSHDATA4: 4-byte size prefix
        case 0x4e:
          let size: UInt32 = try data[cursor+1...cursor+4].readLE()
          try script.append(data.read(&cursor, offsetBy: 5 + Int(size)))
          
          // Other opcode: single byte
        default:
          try script.append(data.read(&cursor, offsetBy: 1))
        }
      }
      self.script = script
    }
  }
}
