//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/16/25.
//

import Foundation

extension _Reader {
  /// Parser and raw representation of a single **PSBT input map section**, as per BIP-174.
  ///
  /// This struct provides low-level access to known and raw fields from a serialized PSBT input map.
  /// It implements strict decoding of keys with validation for duplicates and structural layout.
  ///
  /// ## Decoded Fields:
  /// - `non_witness_utxo`: Full previous transaction (required for legacy P2PKH/P2SH).
  /// - `witness_utxo`: Output being spent (for segwit inputs).
  /// - `final_scriptSig`: ScriptSig used when input is finalized.
  /// - `final_scriptWitness`: Witness stack when input is finalized.
  /// - `witness_script`: Witness redeem script (if applicable).
  /// - `redeem_script`: Redeem script (if applicable).
  /// - `sighash`: Explicit SIGHASH flag.
  ///
  /// ## Behavior:
  /// - Rejects duplicate keys (throws `.duplicateKey`).
  /// - Ensures keys match expected empty prefix (no additional data).
  /// - Gracefully skips unknown known-key types (`.known` with unsupported types).
  /// - Throws `.notImplemented` for unsupported or unknown key categories.
  ///
  /// - Note: Does **not** validate script structure or signatures — only layout.
  internal struct PSBTInput: KeypathProvider, DataReader {
    internal let raw: Data.SubSequence
    internal let context: DataReaderContext?
    
    // MARK: Known single-value fields
    /// Full previous transaction (non-segwit)
    var non_witness_utxo: Data.SubSequence? = nil
    
    /// Output being spent (segwit)
    var witness_utxo: Data.SubSequence? = nil
    
    /// Final scriptSig if input finalized
    var final_scriptSig: Data.SubSequence? = nil
    
    /// Final witness stack if input finalized
    var final_scriptWitness: Data.SubSequence? = nil
    
    /// Witness redeemScript (for P2WSH)
    var witness_script: Data.SubSequence? = nil
    
    /// Legacy redeemScript (for P2SH)
    var redeem_script: Data.SubSequence? = nil
    
    /// Optional sighash flag override
    var sighash: Data.SubSequence? = nil
    
    nonisolated(unsafe) static var keyPathSingle: [String : KeyPath<_Reader.PSBTInput, Data.SubSequence?>] = [
      "tx": \.non_witness_utxo,
      "nonwitnessutxo": \.non_witness_utxo,
      "witnessutxo": \.witness_utxo,
      "witnessscript": \.witness_script,
      "redeemscript": \.redeem_script,
      
      "non_witness_utxo": \.non_witness_utxo,
      "witness_utxo": \.witness_utxo,
      "final_scriptSig": \.final_scriptSig,
      "witness_script": \.witness_script,
      "redeem_script": \.redeem_script,
      "sighash": \.sighash
    ]
    
    nonisolated(unsafe) static var keyPathMany: [String : KeyPath<_Reader.PSBTInput, [Data.SubSequence]?>] = [:]
    
    init(data: Data.SubSequence, context: DataReaderContext?, configuration: DataReaderConfiguration) throws(DataReaderError) {
      self.raw = data
      self.context = context
      
      guard data.count >= 0 else { throw DataReaderError.badSize }
      
      var cursor = data.startIndex
      
      while cursor != data.endIndex {
        let keylen: _Reader.VarInt = try data.read(&cursor)
        let key = try data.read(&cursor, offsetBy: keylen.value)
        let keytype = MapKey(map: .input_map, data: key)
        
        switch keytype {
        case .inputMap(.known(.PSBT_IN_NON_WITNESS_UTXO, let keydata)):
          guard keydata?.isEmpty ?? true else { throw DataReaderError.badValue }
          guard self.non_witness_utxo == nil else { throw DataReaderError.duplicateKey }
          let valuelen: _Reader.VarInt = try data.read(&cursor)
          self.non_witness_utxo = try data.read(&cursor, offsetBy: valuelen.value)
          
        case .inputMap(.known(.PSBT_IN_WITNESS_UTXO, let keydata)):
          guard keydata?.isEmpty ?? true else { throw DataReaderError.badValue }
          guard self.witness_utxo == nil else { throw DataReaderError.duplicateKey }
          let valuelen: _Reader.VarInt = try data.read(&cursor)
          self.witness_utxo = try data.read(&cursor, offsetBy: valuelen.value)
          
        case .inputMap(.known(.PSBT_IN_WITNESS_SCRIPT, let keydata)):
          guard keydata?.isEmpty ?? true else { throw DataReaderError.badValue }
          guard self.witness_script == nil else { throw DataReaderError.duplicateKey }
          let valuelen: _Reader.VarInt = try data.read(&cursor)
          self.witness_script = try data.read(&cursor, offsetBy: valuelen.value)
          
        case .inputMap(.known(.PSBT_IN_REDEEM_SCRIPT, let keydata)):
          guard keydata?.isEmpty ?? true else { throw DataReaderError.badValue }
          guard self.redeem_script == nil else { throw DataReaderError.duplicateKey }
          let valuelen: _Reader.VarInt = try data.read(&cursor)
          self.redeem_script = try data.read(&cursor, offsetBy: valuelen.value)
          
        case .inputMap(.known(.PSBT_IN_SIGHASH_TYPE, let keydata)):
          guard keydata?.isEmpty ?? true else { throw DataReaderError.badValue }
          guard self.sighash == nil else { throw DataReaderError.duplicateKey }
          let valuelen: _Reader.VarInt = try data.read(&cursor)
          self.sighash = try data.read(&cursor, offsetBy: valuelen.value)
          
        case .inputMap(.known(.PSBT_IN_FINAL_SCRIPTSIG, let keydata)):
          guard keydata?.isEmpty ?? true else { throw DataReaderError.badValue }
          guard self.final_scriptSig == nil else { throw DataReaderError.duplicateKey }
          let valuelen: _Reader.VarInt = try data.read(&cursor)
          self.final_scriptSig = try data.read(&cursor, offsetBy: valuelen.value)
          
        case .inputMap(.known(.PSBT_IN_FINAL_SCRIPTWITNESS, let keydata)):
          guard keydata?.isEmpty ?? true else { throw DataReaderError.badValue }
          guard self.final_scriptWitness == nil else { throw DataReaderError.duplicateKey }
          let valuelen: _Reader.VarInt = try data.read(&cursor)
          self.final_scriptWitness = try data.read(&cursor, offsetBy: valuelen.value)
          
        case .inputMap(.known), .inputMap(.unknown):
          // Skip unhandled known or unknown keys
          let valuelen: _Reader.VarInt = try data.read(&cursor)
          try data.seek(&cursor, offsetBy: valuelen.value)
          
        default:
          throw DataReaderError.notImplemented
        }
      }
      
      // Should be fully consumed
      guard cursor == data.endIndex else { throw DataReaderError.internalError }
    }
  }
}
