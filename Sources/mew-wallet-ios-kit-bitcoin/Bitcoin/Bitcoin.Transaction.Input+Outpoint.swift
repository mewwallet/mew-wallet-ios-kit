//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/20/25.
//

import Foundation

extension Bitcoin.Transaction.Input {
  /// Represents a reference to a previous transaction output (a.k.a. an outpoint).
  ///
  /// An input in a Bitcoin transaction spends an output from a previous transaction.
  /// This struct identifies that output by referencing the transaction ID and the output index (vout).
  public struct Outpoint: Equatable, Sendable, Hashable {
    /// The hash of the transaction containing the output being spent.
    /// This is the little-endian TXID (32 bytes).
    public let txid: Data
    
    /// The index of the output within the previous transaction.
    public let vout: UInt32
    
    /// Initializes a new outpoint.
    ///
    /// - Parameters:
    ///   - txid: The transaction ID of the previous transaction (as raw 32-byte `Data`, little-endian).
    ///   - vout: The output index within that transaction.
    public init(txid: Data, vout: UInt32) {
      self.txid = txid
      self.vout = vout
    }
  }
}

extension Bitcoin.Transaction.Input.Outpoint: Codable {
  private enum CodingKeys: CodingKey {
    case txid
    case vout
  }
  
  /// Decodes an outpoint from a keyed container.
  ///
  /// - Parameter decoder: The decoder to read from.
  /// - Throws: An error if decoding fails.
  public init(from decoder: any Swift.Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.txid = try container.decode(Data.self, forKey: .txid)
    self.vout = try container.decode(UInt32.self, forKey: .vout)
  }
  
  /// Encodes the outpoint into a keyed container.
  ///
  /// - Parameter encoder: The encoder to write to.
  /// - Throws: An error if encoding fails.
  public func encode(to encoder: any Swift.Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(txid, forKey: .txid)
    try container.encode(vout, forKey: .vout)
  }
}
