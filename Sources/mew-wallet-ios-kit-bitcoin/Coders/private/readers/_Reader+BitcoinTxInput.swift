//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/14/25.
//

import Foundation

extension _Reader {
  /// A binary reader for decoding a single transaction input (`vin`) in a Bitcoin transaction.
  ///
  /// This reader parses the following input layout:
  /// ```
  /// [outpoint: 36 bytes]
  /// [scriptSig length: varint]
  /// [scriptSig: bytes]
  /// [sequence: 4 bytes]
  /// ```
  ///
  /// If `context.payload` is present (e.g., from SegWit decoding), the `txinwitness` is also extracted from it:
  /// ```
  /// [witness count: varint]
  /// [witness_0 length: varint][witness_0 bytes]
  /// ...
  /// ```
  ///
  /// This struct supports validation, such as enforcing empty `scriptSig` in SegWit contexts.
  internal struct BitcoinTXInput: KeypathProvider, DataReader {
    internal let raw: Data.SubSequence
    internal let context: DataReaderContext?
    
    var outpoint: Data.SubSequence? = nil
    var scriptsig: Data.SubSequence? = nil
    var sequence: Data.SubSequence? = nil
    var txinwitness: [Data.SubSequence]? = nil
    
    /// Key paths to single-value fields (outpoint, scriptSig, sequence)
    nonisolated(unsafe) static var keyPathSingle: [String : KeyPath<_Reader.BitcoinTXInput, Data.SubSequence?>] = [
      "outpoint": \.outpoint,
      "sequence": \.sequence,
      "scriptSig": \.scriptsig,
    ]
    
    /// Key paths to multi-value fields (witness stack)
    nonisolated(unsafe) static var keyPathMany: [String : KeyPath<_Reader.BitcoinTXInput, [Data.SubSequence]?>] = [
      "witness": \.txinwitness,
      "txinwitness": \.txinwitness
    ]
    
    /// Parses a transaction input from binary.
    ///
    /// - Parameters:
    ///   - data: The raw input data (usually 41+ bytes).
    ///   - context: Optional witness payload from SegWit transactions.
    ///   - configuration: Reader configuration flags (e.g. for `scriptSig` validation).
    /// - Throws: `DataReaderError` if the structure is invalid or out of bounds.
    init(data: Data.SubSequence, context: DataReaderContext?, configuration: DataReaderConfiguration) throws(DataReaderError) {
      self.raw = data
      self.context = context
      guard data.count >= 41 else { throw DataReaderError.badSize }
      
      var cursor = data.startIndex
      // Outpoint = [txid (32 bytes)] + [vout (4 bytes)]
      self.outpoint = try data.read(&cursor, offsetBy: 36)
   
      // ScriptSig = [varint len] + bytes
      let scriptSigLen: VarInt = try data.read(&cursor)
      self.scriptsig = try data.read(&cursor, offsetBy: scriptSigLen.value)
      
      // Optional: Validate scriptSig is empty (e.g., required in some BIP143 contexts)
      if configuration.validation.contains(.inputScriptSig) {
        guard self.scriptsig?.isEmpty == true else {
          throw DataReaderError.badLayout
        }
      }
      
      // Sequence
      self.sequence = try data.read(&cursor, offsetBy: 4)
      
      // Should be fully consumed
      guard cursor == data.endIndex else { throw DataReaderError.internalError }
      
      // MARK: Witness stack (if provided via context)
      if let witness = context?.payload {
        var cursor = witness.startIndex
        let count: VarInt = try witness.read(&cursor)
        self.txinwitness = []
        self.txinwitness?.reserveCapacity(count.value)
        for _ in 0..<count.value {
          let size: VarInt = try witness.read(&cursor)
          let value = try witness.read(&cursor, offsetBy: size.value)
          self.txinwitness?.append(value)
        }

        // Should be fully consumed
        guard cursor == witness.endIndex else { throw DataReaderError.internalError }
      }
    }
  }
}
