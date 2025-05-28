//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/14/25.
//

import Foundation

/// A protocol that allows mapping string-based coding keys to `KeyPath`s into a data model.
///
/// Conforming types expose their internal `DataReader` layout, enabling dynamic access
/// to both single-value and multi-value fields during decoding.
///
/// This protocol is primarily used by custom decoders (`_Decoding`, `_Reader`)
/// to enable flexible binary parsing without hardcoding field access.
///
/// - Note:
///   All `KeyPath`s must point to properties of type `Data.SubSequence?` (for single values)
///   or `[Data.SubSequence]?` (for multiple values).
internal protocol KeypathProvider {
  /// A dictionary mapping key names (e.g. `"version"`, `"txid"`) to key paths
  /// for accessing single `Data.SubSequence?` properties.
  ///
  /// Used for decoding fixed-width integers, scripts, or single raw blobs.
  nonisolated(unsafe) static var keyPathSingle: [String: KeyPath<Self, Data.SubSequence?>] { get }
  
  /// A dictionary mapping key names to key paths for accessing arrays of
  /// `Data.SubSequence`, typically used for lists such as inputs, outputs,
  /// or script witnesses.
  ///
  /// Used when the data represents repeated values or collection fields.
  nonisolated(unsafe) static var keyPathMany: [String: KeyPath<Self, [Data.SubSequence]?>] { get }
}
