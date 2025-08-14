//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/20/25.
//

import Foundation
import mew_wallet_ios_kit_utils

extension _Reader {
  /// A binary reader for parsing an outpoint in a Bitcoin transaction input.
  ///
  /// An outpoint is a reference to a specific UTXO (Unspent Transaction Output), and is composed of:
  /// ```
  /// [txid: 32 bytes]  ← transaction hash in little-endian (reversed from wire format)
  /// [vout: 4 bytes]   ← output index (zero-based)
  /// ```
  ///
  /// This struct extracts and exposes the outpoint components as two separate fields: `txid` and `vout`.
  ///
  /// - Requires: `data.count == 36`
  internal struct BitcoinTXInputOutpoint: KeypathProvider, DataReader {
    internal let raw: Data.SubSequence
    internal let context: DataReaderContext?
    
    /// The transaction ID (txid), reversed from little-endian to match Bitcoin's internal representation.
    var txid: Data.SubSequence? = nil
    
    /// The output index (`vout`) indicating which output of the referenced transaction is being spent.
    var vout: Data.SubSequence? = nil
    
    /// Single-value field mappings for decoding.
    nonisolated(unsafe) static var keyPathSingle: [String : KeyPath<_Reader.BitcoinTXInputOutpoint, Data.SubSequence?>] = [
      "txid": \.txid,
      "vout": \.vout
    ]
    
    /// This reader contains no multi-value fields.
    nonisolated(unsafe) static var keyPathMany: [String : KeyPath<_Reader.BitcoinTXInputOutpoint, [Data.SubSequence]?>] = [:]
    
    /// Parses a 36-byte outpoint from raw transaction input.
    ///
    /// - Parameters:
    ///   - data: The 36-byte binary data representing the outpoint.
    ///   - context: Unused for this reader.
    ///   - configuration: Unused for this reader.
    ///
    /// - Throws: `DataReaderError.badSize` if size is not exactly 36, or `DataReaderError.internalError` if cursor doesn't align.
    init(data: Data.SubSequence, context: DataReaderContext?, configuration: DataReaderConfiguration) throws(DataReaderError) {
      
      self.raw = data
      self.context = context
      guard data.count == 36 else { throw DataReaderError.badSize }
      
      var cursor = data.startIndex
      // Read txid in little-endian and reverse for canonical representation
      self.txid = try data.readReversed(&cursor, offsetBy: 32)
      
      // Read vout index (UInt32)
      self.vout = try data.read(&cursor, offsetBy: 4)
      
      // Should be fully consumed
      guard cursor == data.endIndex else { throw DataReaderError.internalError }
    }
  }
}
