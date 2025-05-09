//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/14/25.
//

import Foundation

extension Bitcoin.Transaction {
  /// Represents a transaction input in a Bitcoin transaction.
  ///
  /// Each input references a previous transaction output via the `outpoint`,
  /// provides an unlocking script via `scriptSig`, and includes a `sequence` number.
  /// For SegWit transactions, `txinwitness` contains witness data.
  ///
  /// - Note: Coinbase inputs (used in block rewards) are currently not supported.
  // FIXME: Coinbase support
  public struct Input: Equatable, Sendable, Hashable {
    
    /// Reference to the output being spent (txid + output index).
    public let outpoint: Bitcoin.Transaction.Input.Outpoint
    
    /// The sequence number for this input.
    /// Often used for Replace-By-Fee (RBF) or time-locked transactions.
    public let sequence: Bitcoin.Sequence
    
    /// The unlocking script (scriptSig) providing authorization to spend the referenced output.
    public let scriptSig: Bitcoin.Script
    
    /// Optional witness data for SegWit inputs.
    public let txinwitness: [Data]?
    
    /// Initializes a Bitcoin input with all parameters.
    public init(outpoint: Bitcoin.Transaction.Input.Outpoint, sequence: Bitcoin.Sequence, scriptSig: Bitcoin.Script, txinwitness: [Data]?) {
      self.outpoint = outpoint
      self.sequence = sequence
      self.scriptSig = scriptSig
      self.txinwitness = txinwitness
    }
    
    /// Convenience initializer from raw txid and vout.
    public init(txid: Data, vout: UInt32, sequence: Bitcoin.Sequence, scriptSig: Bitcoin.Script, txinwitness: [Data]?) {
      self.init(
        outpoint: Outpoint(txid: txid, vout: vout),
        sequence: sequence,
        scriptSig: scriptSig,
        txinwitness: txinwitness
      )
    }
  }
}

extension Bitcoin.Transaction.Input: Codable {
  private enum CodingKeys: CodingKey {
    case txid
    case vout
    case outpoint
    case sequence
    case scriptSig
    case txinwitness
  }
  
  /// Decodes a transaction input from a keyed container.
  /// Expects an `outpoint`, `scriptSig`, `sequence`, and optional `txinwitness`.
  public init(from decoder: any Swift.Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.outpoint = try container.decode(Bitcoin.Transaction.Input.Outpoint.self, forKey: .outpoint)
    self.scriptSig = try container.decode(Bitcoin.Script.self, forKey: .scriptSig)
    self.sequence = try container.decode(Bitcoin.Sequence.self, forKey: .sequence)
    self.txinwitness = try container.decodeIfPresent([Data].self, forKey: .txinwitness)
  }
  
  /// Encodes the transaction input into a keyed container.
  /// Only `txid`, `vout`, `scriptSig`, and `sequence` are encoded.
  ///
  /// - Note: `txinwitness` is excluded here and expected to be handled separately
  ///   (e.g., as part of `script_witnesses` in SegWit serialization).
  public func encode(to encoder: any Swift.Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(outpoint.txid, forKey: .txid)
    try container.encode(outpoint.vout, forKey: .vout)
    try container.encode(scriptSig, forKey: .scriptSig)
    try container.encode(sequence, forKey: .sequence)
    // `txinwitness` is intentionally not encoded here
  }
}
