//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/14/25.
//

import Foundation
import mew_wallet_ios_kit_utils

/// A protocol representing a type that can parse and interpret binary data
/// for use in custom decoding flows like Bitcoin or PSBT transaction decoding.
///
/// Conforming types are responsible for extracting structured data from a raw
/// `Data.SubSequence`, optionally using contextual information such as payloads
/// or validation rules.
internal protocol DataReader {
  /// The raw binary slice this reader was initialized with.
  var raw: Data.SubSequence { get }
  
  /// Optional contextual information, e.g. index, witness, or payload metadata.
  var context: DataReaderContext? { get }
  
  /// Initializes the reader with raw binary data and an optional context.
  ///
  /// - Parameters:
  ///   - data: The binary input to decode.
  ///   - context: Optional additional decoding context (such as payloads).
  ///   - configuration: Validation configuration for this decoding session.
  ///
  /// - Throws: `DataReaderError` if parsing fails or data is invalid.
  init(data: Data.SubSequence, context: DataReaderContext?, configuration: DataReaderConfiguration) throws(DataReaderError)
}

/// Contextual metadata passed to a `DataReader` to inform decoding.
/// This can represent witness payloads, index positions, or PSBT-specific info.
internal struct DataReaderContext: Sendable, Equatable {
  /// Optional payload associated with the reader — e.g. witness data or script.
  let payload: Data.SubSequence?
  
  /// Optional index (e.g., input/output number in a transaction).
  var n: UInt32? = nil
  
  /// Creates a new context with the given payload.
  ///
  /// - Parameter payload: Optional binary slice providing additional context.
  init(payload: Data.SubSequence?) {
    self.payload = payload
  }
}

/// Configuration for how a `DataReader` validates its input during decoding.
internal struct DataReaderConfiguration: Sendable, Equatable {
  /// Validation flags specifying what checks should be performed.
  var validation: Bitcoin.Decoder.Validation
  
  /// Creates a configuration object for binary decoding.
  ///
  /// - Parameter validation: The desired level of validation for parsing.
  init(validation: Bitcoin.Decoder.Validation) {
    self.validation = validation
  }
}
