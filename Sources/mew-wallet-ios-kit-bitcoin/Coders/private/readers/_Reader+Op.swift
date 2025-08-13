//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/15/25.
//

import Foundation
import mew_wallet_ios_kit_utils

extension _Reader {
  /// Binary reader for decoding Bitcoin script operations (`Script.asm`).
  ///
  /// Parses the input as a sequence of opcodes and (when applicable) associated data (e.g. for `OP_PUSHDATA` instructions).
  /// The `asm` property holds all parsed instructions and pushed data in the order they appear.
  ///
  /// - Note: This reader **does not** interpret opcodes semantically; it only segments the script.
  internal struct Op: KeypathProvider, DataReader {
    internal let raw: Data.SubSequence
    internal let context: DataReaderContext?
    
    /// Parsed ASM (opcode and data) segments from the script.
    var asm: [Data.SubSequence]?
    
    /// No scalar keys supported.
    nonisolated(unsafe) static var keyPathSingle: [String : KeyPath<_Reader.Op, Data.SubSequence?>] = [:]
    
    /// "raw" → list of opcode/data fragments
    nonisolated(unsafe) static var keyPathMany: [String : KeyPath<_Reader.Op, [Data.SubSequence]?>] = [
      "raw": \.asm
    ]
    
    /// Parses the script into opcode/data pairs.
    ///
    /// - Parameters:
    ///   - data: Full binary script.
    ///   - context: Unused.
    ///   - configuration: Unused.
    /// - Throws: `DataReaderError.badValue` if an invalid push size is encountered.
    init(data: Data.SubSequence, context: DataReaderContext?, configuration: DataReaderConfiguration) throws(DataReaderError) {
      self.raw = data
      self.context = context
      
      var script: [Data.SubSequence] = []
      var cursor = data.startIndex
      while cursor != data.endIndex {
        let op = try data.read(&cursor, offsetBy: 1)
        script.append(op)
        guard let opByte = op.first else { throw .badValue }
        switch opByte {
          // ._OP_PUSHBYTES(Data)
        case 0x01...0x4b:
          try script.append(data.read(&cursor, offsetBy: Int(opByte)))
          
          // .OP_PUSHDATA1
        case 0x4c:
          let size: UInt8 = try data[cursor...cursor].readLE()
          try data.seek(&cursor, offsetBy: 1)
          try script.append(data.read(&cursor, offsetBy: Int(size)))
          
          // .OP_PUSHDATA2
        case 0x4d:
          let size: UInt16 = try data[cursor...cursor+1].readLE()
          try data.seek(&cursor, offsetBy: 2)
          try script.append(data.read(&cursor, offsetBy: Int(size)))
          
          // .OP_PUSHDATA4
        case 0x4e:
          let size: UInt32 = try data[cursor...cursor+3].readLE()
          try data.seek(&cursor, offsetBy: 4)
          try script.append(data.read(&cursor, offsetBy: Int(size)))
          
        default:
          // Non-push opcode, already appended
          break
        }
      }
      self.asm = script
    }
  }
}
