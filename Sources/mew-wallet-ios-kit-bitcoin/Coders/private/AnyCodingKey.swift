//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/14/25.
//

import Foundation

/// A generic `CodingKey` implementation that can be initialized with any string or integer value.
///
/// Useful when you need to dynamically construct coding keys, such as when decoding/encoding dictionaries
/// with unknown or runtime-defined keys.
///
/// Common use cases:
/// - Custom coding containers with dynamic key access
/// - Bridging between `String` and `Int` keys
///
/// Example:
/// ```swift
/// let key = AnyCodingKey(stringValue: "dynamicKey")
/// let intKey = AnyCodingKey(intValue: 5)
/// ```
internal struct AnyCodingKey: CodingKey {
  /// The string representation of the coding key.
  var stringValue: String
  
  /// The integer representation of the coding key, if applicable.
  var intValue: Int?
  
  /// Creates a new instance from a string key.
  /// If the string represents an integer, `intValue` will also be set.
  ///
  /// - Parameter stringValue: The string representation of the key.
  init(stringValue: String) {
    self.stringValue = stringValue
    self.intValue = Int(stringValue)
  }
  
  /// Creates a new instance from an integer key.
  /// `stringValue` will be the string form of the integer.
  ///
  /// - Parameter intValue: The integer representation of the key.
  init(intValue: Int) {
    self.intValue = intValue
    self.stringValue = "\(intValue)"
  }
}
