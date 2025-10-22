//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/14/25.
//

import Foundation
import mew_wallet_ios_kit_utils

extension _Reader {
  /// A binary parser for raw Bitcoin transactions, following BIP-144 (SegWit) and legacy formats.
  ///
  /// This reader parses a complete Bitcoin transaction and exposes its components through key paths.
  /// It distinguishes between SegWit and non-SegWit transactions by checking for the `[0x00, 0x01]` marker/flag.
  ///
  /// The layout is expected to follow the canonical structure:
  /// ```
  /// [version: 4 bytes]
  /// [marker=0x00, flag=0x01]?  ← SegWit only
  /// [input count: varint]
  /// [inputs...]
  /// [output count: varint]
  /// [outputs...]
  /// [witnesses... (if marker present)]
  /// [locktime: 4 bytes]
  /// ```
  internal struct BitcoinTx: KeypathProvider, DataReader {
    internal let raw: Data.SubSequence
    internal let context: DataReaderContext?

    // Parsed transaction fields
    var version: Data.SubSequence? = nil
    var vin: [Data.SubSequence]?
    var vout: [Data.SubSequence]?
    var vin_witness: [Data.SubSequence]?
    var locktime: Data.SubSequence? = nil
    
    var size: Int = 0
    var vsize: Int = 0
    var weight: Int = 0
    
    /// Static mapping from field name to optional `Data.SubSequence` key paths.
    nonisolated(unsafe) static var keyPathSingle: [String : KeyPath<_Reader.BitcoinTx, Data.SubSequence?>] = [
      "version": \.version,
      "locktime": \.locktime
    ]
    
    /// Static mapping from field name to optional array key paths (e.g. vin, vout).
    nonisolated(unsafe) static var keyPathMany: [String : KeyPath<_Reader.BitcoinTx, [Data.SubSequence]?>] = [
      "vin": \.vin,
      "inputs": \.vin,
      "vin_witness": \.vin_witness,
      "vout": \.vout,
      "outputs": \.vout
    ]
    
    /// Parses a raw transaction into its component slices.
    ///
    /// - Parameters:
    ///   - data: Full transaction binary data.
    ///   - context: Optional context passed during decoding.
    ///   - configuration: Reader configuration (e.g., validation rules).
    /// - Throws: `DataReaderError` if layout is invalid, truncated, or contains inconsistent data.
    init(data: Data.SubSequence, context: (DataReaderContext)?, configuration: DataReaderConfiguration) throws(DataReaderError) {
      self.raw = data
      self.context = context
      var hasWitness: Bool = false
      
      guard data.count >= 10 else {
        throw DataReaderError.badSize
      }
      self.size = data.count
      
      var cursor = data.startIndex
      // Read version (4 bytes)
      self.version = try data.read(&cursor, offsetBy: 4)
      
      // Check for SegWit marker (0x00 0x01)
      if data[cursor] == 0x00 {
        let segwit = try data.read(&cursor, offsetBy: 2)
        guard segwit.elementsEqual([0x00, 0x01]) else {
          throw DataReaderError.badLayout
        }
        hasWitness = true
      }
      
      // MARK: Parse inputs
      let tx_in_count: VarInt = try data.read(&cursor)
      self.vin = []
      self.vin!.reserveCapacity(tx_in_count.value)
      for _ in 0..<tx_in_count.value {
        let start = cursor
        try data.seek(&cursor, offsetBy: 32) // prev txid
        try data.seek(&cursor, offsetBy: 4) // output index
        let scriptSigLen: VarInt = try data.read(&cursor)
        try data.seek(&cursor, offsetBy: scriptSigLen.value) // signature script
        try data.seek(&cursor, offsetBy: 4) // sequence
        self.vin!.append(data[start..<cursor])
      }
      
      // MARK: Parse outputs
      let tx_out_count: VarInt = try data.read(&cursor)
      self.vout = []
      self.vout!.reserveCapacity(tx_out_count.value)
      for _ in 0..<tx_out_count.value {
        let start = cursor
        try data.seek(&cursor, offsetBy: 8) // value (sats)
        let pubKeyScriptLen: VarInt = try data.read(&cursor)
        try data.seek(&cursor, offsetBy: pubKeyScriptLen.value)
        self.vout!.append(data[start..<cursor])
      }
      
      // MARK: Parse witness (if SegWit)
      if hasWitness {
        self.vin_witness = []
        self.vin_witness!.reserveCapacity(self.vin!.count)
        
        for _ in 0..<self.vin!.count {
          let start = cursor
          let witness_count: VarInt = try data.read(&cursor)
          for _ in 0..<witness_count.value {
            let size: VarInt = try data.read(&cursor)
            try data.seek(&cursor, offsetBy: size.value)
          }
          self.vin_witness!.append(data[start..<cursor])
        }
      }
      
      // MARK: Parse witness (if SegWit)
      self.locktime = try data.read(&cursor, offsetBy: 4)
      
      // Should be fully consumed
      guard cursor == data.endIndex else { throw DataReaderError.internalError }
    }
  }
}
