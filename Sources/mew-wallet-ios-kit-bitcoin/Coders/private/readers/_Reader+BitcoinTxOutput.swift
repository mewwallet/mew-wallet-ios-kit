//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/14/25.
//

import Foundation
import mew_wallet_ios_kit_utils

extension _Reader {
  /// A binary reader for parsing a Bitcoin transaction output.
  ///
  /// Bitcoin transaction outputs follow the layout:
  /// ```
  /// [value: 8 bytes]              ← amount in satoshis, little-endian
  /// [scriptPubKey length: varint]
  /// [scriptPubKey: variable]
  /// ```
  /// If the output is part of a collection (e.g. multiple outputs in a transaction), the optional context field `n`
  /// will be captured and serialized for indexing or metadata usage.
  internal struct BitcoinTXOutput: KeypathProvider, DataReader {
    internal let raw: Data.SubSequence
    internal let context: DataReaderContext?
    
    /// 8-byte value in satoshis (little-endian).
    var value: Data.SubSequence? = nil
    
    /// Optional output index (`n`), passed via context.
    var n: Data.SubSequence? = nil
    
    /// Script used to lock the output (e.g. P2PKH, P2WPKH, etc.)
    var scriptPubKey: Data.SubSequence? = nil
    
    /// Mapping of single-value decoding keys to internal storage.
    nonisolated(unsafe) static var keyPathSingle: [String : KeyPath<_Reader.BitcoinTXOutput, Data.SubSequence?>] = [
      "value": \.value,
      "n": \.n,
      "scriptPubKey": \.scriptPubKey
    ]
    
    /// No array-based keypaths for this reader.
    nonisolated(unsafe) static var keyPathMany: [String : KeyPath<_Reader.BitcoinTXOutput, [Data.SubSequence]?>] = [:]
    
    /// Initializes the output reader and parses its components.
    ///
    /// - Parameters:
    ///   - data: Binary data containing the output (≥ 9 bytes).
    ///   - context: Optional context (e.g., to set output index `n`).
    ///   - configuration: Unused.
    ///
    /// - Throws:
    ///   - `.badSize` if the data is shorter than required.
    ///   - `.internalError` if parsing fails or extra bytes remain.
    init(data: Data.SubSequence, context: DataReaderContext?, configuration: DataReaderConfiguration) throws(DataReaderError) {
      self.raw = data
      self.context = context
      
      // If context carries an output index `n`, encode it as 4-byte little-endian.
      if let n = context?.n {
        var le = n.littleEndian
        self.n = withUnsafeBytes(of: &le) { Data($0) }
      }
      guard data.count >= 9 else { throw DataReaderError.badSize }
      
      var cursor = data.startIndex
      // Read 8-byte value in satoshis
      self.value = try data.read(&cursor, offsetBy: 8)
      
      // Read scriptPubKey (VarInt-prefixed)
      let scriptPubKeyLen: VarInt = try data.read(&cursor)
      self.scriptPubKey = try data.read(&cursor, offsetBy: scriptPubKeyLen.value)
      
      // Should be fully consumed
      guard cursor == data.endIndex else { throw DataReaderError.internalError }
    }
  }
}
