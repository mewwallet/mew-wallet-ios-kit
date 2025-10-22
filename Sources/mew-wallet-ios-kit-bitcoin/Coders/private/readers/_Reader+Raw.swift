//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/14/25.
//

import Foundation
import mew_wallet_ios_kit_utils

extension _Reader {
  /// A minimal, non-parsing data container conforming to `DataReader` and `KeypathProvider`.
  ///
  /// `Raw` is used to wrap binary blobs (e.g., sighash, scriptPubKey, unknown fields) where
  /// decoding is either deferred or not applicable. This type does not attempt to parse or
  /// validate the data, but simply provides access to it.
  ///
  /// - Important: This is often used in `SingleValueContainer` or as a payload container
  ///   for flexible PSBT field types or scripts.
  internal struct Raw: KeypathProvider, DataReader {
    /// The raw binary data this container holds.
    internal let raw: Data.SubSequence
    
    /// Optional decoding context, passed from the parent structure (e.g., witness payload).
    internal let context: DataReaderContext?
    
    /// There are no known single-value key paths for `Raw`, as it does not expose fields.
    nonisolated(unsafe) static var keyPathSingle: [String : KeyPath<_Reader.Raw, Data.SubSequence?>] = [:]
    
    /// There are no known multi-value key paths for `Raw`.
    nonisolated(unsafe) static var keyPathMany: [String : KeyPath<_Reader.Raw, [Data.SubSequence]?>] = [:]
    
    /// Initializes the raw container with the provided binary payload.
    ///
    /// - Parameters:
    ///   - data: The binary subsequence to store.
    ///   - context: Optional payload context, such as a witness or indexing info.
    ///   - configuration: Decoder configuration (ignored for this type).
    internal init(data: Data.SubSequence, context: DataReaderContext?, configuration: DataReaderConfiguration) throws(DataReaderError) {
      self.raw = data
      self.context = context
    }
  }
}
