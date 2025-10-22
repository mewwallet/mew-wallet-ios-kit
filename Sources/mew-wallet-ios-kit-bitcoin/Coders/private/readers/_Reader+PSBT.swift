//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/15/25.
//

import Foundation
import mew_wallet_ios_kit_utils

extension _Reader {
  /// Low-level parser for a full PSBT (Partially Signed Bitcoin Transaction) binary blob.
  ///
  /// This struct implements linear deserialization of global, input, and output maps according to the BIP-174/BIP-370 spec.
  /// It uses a key-based decoding strategy where each key prefix defines the map segment (global/input/output), and a 0‑length key marks the end of a section.
  ///
  /// The implementation stores all raw subsections (`Data.SubSequence`) so they can later be lazily interpreted by specialized decoders.
  ///
  /// ## Parsing Strategy:
  /// - Global map must contain the unsigned transaction (`PSBT_GLOBAL_UNSIGNED_TX`), which is parsed using `_Reader.BitcoinTx`.
  /// - The counts of `vin` and `vout` are inferred from the unsigned transaction and used to bound the number of input/output maps.
  /// - Input and Output maps are buffered as raw PSBT map sections (for use with `PSBTInput` and `PSBTOutput`).
  ///
  /// ## Supported fields:
  /// - `tx`: The raw unsigned transaction (required).
  /// - `psbt_version`: Optional PSBT version field.
  /// - `global_xpubs`: Optional BIP-32 xpub metadata.
  /// - `inputs`/`outputs`: Lists of raw map sections to be interpreted downstream.
  ///
  /// - Important: Validation of fields is strict (non-empty keys, correct VarInt lengths, alignment with declared vin/vout count).
  /// - Throws: `DataReaderError` for any layout or semantic violation.
  internal struct PSBT: KeypathProvider, DataReader {
    internal let raw: Data.SubSequence
    internal let context: DataReaderContext?
    
    // MARK: - Parsed Fields
    
    /// Raw transaction (`PSBT_GLOBAL_UNSIGNED_TX`), required to determine vin/vout counts.
    var tx: Data.SubSequence? = nil
    
    /// Optional PSBT version (`PSBT_GLOBAL_VERSION`)
    var psbt_version: Data.SubSequence? = nil
    
    /// Extended public keys from global map (`PSBT_GLOBAL_XPUB`)
    var global_xpubs: [Data.SubSequence]? = nil
    
    /// Buffered input maps, one entry per PSBT input.
    var inputs: [Data.SubSequence]? = []
    
    /// Buffered output maps, one entry per PSBT output.
    var outputs: [Data.SubSequence]? = []
    
    // Lazy-parsed raw input/output maps
    nonisolated(unsafe) static var keyPathSingle: [String : KeyPath<_Reader.PSBT, Data.SubSequence?>] = [
      "tx": \.tx,
      "psbt_version": \.psbt_version
    ]
    
    // Multi-value key access
    nonisolated(unsafe) static var keyPathMany: [String : KeyPath<_Reader.PSBT, [Data.SubSequence]?>] = [
      "global_xpubs": \.global_xpubs,
      "inputs": \.inputs,
      "outputs": \.outputs
    ]
    
    init(data: Data.SubSequence, context: DataReaderContext?, configuration: DataReaderConfiguration) throws(DataReaderError) {
      self.raw = data
      self.context = context
      var cursor = data.startIndex
      var ioStartCursor: Data.SubSequence.Index? = nil
      var ioEndCursor: Data.SubSequence.Index? = nil
      
      var map: GlobalMap? = .global_map
      
      var vinCount: Int = 0
      var inputsCount: Int = 0
      var voutCount: Int = 0
      var outputsCount: Int = 0
      
      var previousKey: MapKey = .globalMap(.empty)
      
      while map != nil {
        let mapStart = cursor
        let keylen: VarInt = try data.read(&cursor)
        let key = try data.read(&cursor, offsetBy: keylen.value)
        let keytype = MapKey(map: map!, data: key)
        defer {
          previousKey = keytype
        }
        
        switch keytype {
          // MARK: Global Map Parsing
          
        case .globalMap(.known(.PSBT_GLOBAL_UNSIGNED_TX, let keydata)):
          guard keydata?.isEmpty ?? true else { throw DataReaderError.badValue }
          let valuelen: VarInt = try data.read(&cursor)
          let value = try data.read(&cursor, offsetBy: valuelen.value)
          self.tx = value
          let tx = try _Reader.BitcoinTx(data: value, context: nil, configuration: configuration)
          vinCount = tx.vin?.count ?? 0
          voutCount = tx.vout?.count ?? 0
          self.inputs?.reserveCapacity(vinCount)
          self.outputs?.reserveCapacity(voutCount)
          
        case .globalMap(.known(.PSBT_GLOBAL_VERSION, let keydata)):
          guard keydata?.isEmpty ?? true else { throw DataReaderError.badValue }
          let valuelen: VarInt = try data.read(&cursor)
          let value = try data.read(&cursor, offsetBy: valuelen.value)
          self.psbt_version = value
          
        case .globalMap(.known(.PSBT_GLOBAL_XPUB, let keydata)):
          guard keydata?.isEmpty ?? true else { throw DataReaderError.badValue }
          let valuelen: VarInt = try data.read(&cursor)
          let value = try data.read(&cursor, offsetBy: valuelen.value)
          var pubs = self.global_xpubs ?? []
          pubs.append(value)
          self.global_xpubs = pubs
          
        case .globalMap(.empty):
          if !previousKey.isEmpty {
            map = map?.next
          }
          
          // MARK: Input Map Buffering
          
        case .inputMap(.unknown), .inputMap(.known(_, _)):
          if ioStartCursor == nil {
            ioStartCursor = mapStart
          }
          let valuelen: VarInt = try data.read(&cursor)
          try data.seek(&cursor, offsetBy: valuelen.value)
          ioEndCursor = cursor
          
        case .inputMap(.empty):
          if let ioStartCursor, let ioEndCursor {
            self.inputs?.append(data[ioStartCursor..<ioEndCursor]) // zero-input marker
          }
          ioStartCursor = nil
          ioEndCursor = nil
          inputsCount += 1
          if previousKey.isEmpty {
            var inputs = self.inputs ?? []
            inputs.append(data[cursor..<cursor])
            self.inputs = inputs
          }
          if inputsCount >= vinCount {
            map = map?.next
          }
          
          // MARK: Output Map Buffering
          
        case .outputMap(.unknown), .outputMap(.known(_, _)):
          if ioStartCursor == nil {
            ioStartCursor = mapStart
          }
          let valuelen: VarInt = try data.read(&cursor)
          try data.seek(&cursor, offsetBy: valuelen.value)
          ioEndCursor = cursor
          
        case .outputMap(.empty):
          if let ioStartCursor, let ioEndCursor {
            self.outputs?.append(data[ioStartCursor..<ioEndCursor]) // zero-output marker
          }
          ioStartCursor = nil
          ioEndCursor = nil
          outputsCount += 1
          if previousKey.isEmpty {
            self.outputs?.append(data[cursor..<cursor])
          }
          if outputsCount >= voutCount {
            map = map?.next
          }
          
        default:
          break
        }
      }
      
      // Should be fully consumed
      guard cursor == data.endIndex else { throw DataReaderError.internalError }
    }
  }
}
