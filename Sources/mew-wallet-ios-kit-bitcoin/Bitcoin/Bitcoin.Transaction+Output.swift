//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/14/25.
//

import Foundation
#if canImport(CryptoSwift)
import CryptoSwift
#endif

extension Bitcoin.Transaction {
  /// Represents a Bitcoin transaction output.
  ///
  /// Each output includes a value (in satoshis) and a locking script (scriptPubKey)
  /// that specifies the conditions required to spend the output.
  public struct Output: Equatable, Sendable, Hashable {
    /// The amount of satoshis to be transferred.
    public let value: UInt64
    
    /// Optional output index (`vout`); mostly used when deserializing full transactions.
    /// This is not part of the raw Bitcoin transaction format but may appear in JSON.
    public let n: UInt32?
    
    /// The locking script (scriptPubKey) defining how the output can be spent.
    public let script: Bitcoin.Script
    
    /// Initializes a new output with the given value, index, and script.
    ///
    /// - Parameters:
    ///   - value: Amount in satoshis.
    ///   - n: Optional output index (`vout`), can be nil.
    ///   - script: The locking script (scriptPubKey).
    public init(value: UInt64, n: UInt32?, script: Bitcoin.Script) {
      self.value = value
      self.n = n
      self.script = script
    }
  }
}

extension Bitcoin.Transaction.Output: Codable {
  private enum CodingKeys: CodingKey {
    case value
    case n
    case scriptPubKey
  }
  
  /// Decodes a transaction output from a keyed container.
  ///
  /// - Parameters:
  ///   - decoder: The decoder to read data from.
  /// - Throws: Decoding errors if format is invalid.
  public init(from decoder: any Swift.Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.value = try container.decode(UInt64.self, forKey: .value)
    self.n = try container.decodeIfPresent(UInt32.self, forKey: .n)
    self.script = try container.decode(Bitcoin.Script.self, forKey: .scriptPubKey)
  }
  
  /// Encodes the transaction output into a keyed container.
  ///
  /// - Parameter encoder: The encoder to write data to.
  /// - Throws: Encoding errors if something goes wrong.
  public func encode(to encoder: any Swift.Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.value, forKey: .value)
    try container.encodeIfPresent(self.n, forKey: .n)
    try container.encode(self.script, forKey: .scriptPubKey)
  }
}

#if DEBUG
extension Bitcoin.Transaction.Output {
  /// Pretty-prints the transaction in JSON format, useful for debugging.
  public func _prettyPrint() -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted]
    encoder.dataEncodingStrategy = .custom({ data, encoder in
      var container = encoder.singleValueContainer()
#if canImport(CryptoSwift)
      try container.encode(data.toHexString())
#else
      try container.encode(data.base64EncodedString())
#endif
    })
    guard let encoded = try? encoder.encode(self) else {
      return "<failed>"
    }
    return String(data: encoded, encoding: .utf8) ?? "<failed>"
  }
}
#endif
