//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/17/25.
//

import Foundation
import mew_wallet_ios_kit_utils

extension _Reader {
  /// PSBT output map parser (BIP-174).
  ///
  /// Extracts redeem and witness scripts attached to a transaction output.
  /// These scripts are optional and primarily used for signing or script path validation.
  internal struct PSBTOutput: KeypathProvider, DataReader {
    internal let raw: Data.SubSequence
    internal let context: DataReaderContext?
    
    // MARK: Known output fields
    
    // P2SH redeemScript
    var redeem_script: Data.SubSequence? = nil
    
    // P2WSH witnessScript
    var witness_script: Data.SubSequence? = nil
    
    nonisolated(unsafe) static var keyPathSingle: [String : KeyPath<_Reader.PSBTOutput, Data.SubSequence?>] = [
      "redeemScript": \.redeem_script,
      "witnessScript": \.witness_script,
      
      "redeem_script": \.redeem_script,
      "witness_script": \.witness_script,
    ]
    
    nonisolated(unsafe) static var keyPathMany: [String : KeyPath<_Reader.PSBTOutput, [Data.SubSequence]?>] = [:]
    
    init(data: Data.SubSequence, context: DataReaderContext?, configuration: DataReaderConfiguration) throws(DataReaderError) {
      self.raw = data
      self.context = context
      
      guard data.count >= 0 else { throw DataReaderError.badSize }
      
      var cursor = data.startIndex
      
      while cursor != data.endIndex {
        let keylen: VarInt = try data.read(&cursor)
        let key = try data.read(&cursor, offsetBy: keylen.value)
        let keytype = MapKey(map: .output_map, data: key)
        
        switch keytype {
        case .outputMap(.known(.PSBT_OUT_REDEEM_SCRIPT, let keydata)):
          guard keydata?.isEmpty ?? true else { throw DataReaderError.badValue }
          let valuelen: VarInt = try data.read(&cursor)
          self.redeem_script = try data.read(&cursor, offsetBy: valuelen.value)
          
        case .outputMap(.known(.PSBT_OUT_WITNESS_SCRIPT, let keydata)):
          guard keydata?.isEmpty ?? true else { throw DataReaderError.badValue }
          let valuelen: VarInt = try data.read(&cursor)
          self.witness_script = try data.read(&cursor, offsetBy: valuelen.value)
          
        case .outputMap(.known), .outputMap(.unknown):
          // Skip unhandled known or unknown keys
          let valuelen: VarInt = try data.read(&cursor)
          try data.seek(&cursor, offsetBy: valuelen.value)
          
        default:
          break
        }
      }
      
      // Should be fully consumed
      guard cursor == data.endIndex else { throw DataReaderError.internalError }
    }
  }
}
