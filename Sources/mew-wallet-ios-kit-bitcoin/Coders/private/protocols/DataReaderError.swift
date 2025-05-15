//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/22/25.
//

import Foundation

/// Represents possible errors thrown during binary decoding via a `DataReader`.
///
/// These errors are typically thrown when parsing malformed, incomplete,
/// or otherwise invalid Bitcoin or PSBT structures.
internal enum DataReaderError: Error, Sendable, Equatable {
  /// The size of a field or segment was invalid (too short, too long, or mismatched).
  case badSize
  
  /// The value encountered does not conform to the expected format or constraints.
  case badValue
  
  /// A duplicate key was found when uniqueness was required (e.g., PSBT key map).
  case duplicateKey
  
  /// The feature or operation is not implemented in the current decoder.
  case notImplemented
  
  /// A read or access exceeded the bounds of the input data.
  case outOfBounds
  
  /// The internal data layout is invalid or corrupted (e.g., bad offsets or structure).
  case badLayout
  
  /// An unexpected internal error occurred — likely a logic bug or edge case not handled.
  case internalError
}
