//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/11/25.
//

import Foundation

extension PSBT {
  /// Represents a fully structured Partially Signed Bitcoin Transaction (PSBT).
  ///
  /// This object wraps an unsigned base `Bitcoin.Transaction` and associates
  /// PSBT-specific metadata for each input and output as defined in BIP-174 and BIP-370.
  ///
  /// This structure is typically the result of parsing or constructing a PSBT file.
  public struct Transaction: Equatable, Sendable {
    /// The unsigned or partially signed Bitcoin transaction.
    public let tx: Bitcoin.Transaction
    
    /// A list of input metadata entries, corresponding 1:1 with `tx.inputs`.
    ///
    /// Each input carries auxiliary PSBT data like UTXOs, scripts, and signatures.
    public let inputs: [PSBT.Input]
    
    /// A list of output metadata entries, corresponding 1:1 with `tx.outputs`.
    ///
    /// Each output may contain redeem scripts, witness scripts, or other commitments.
    public let outputs: [PSBT.Output]
  }
}

// MARK: - PSBT.Transaction + Codable

extension PSBT.Transaction: Codable {
  enum CodingKeys: String, CodingKey {
    case tx
    case inputs
    case outputs
  }
  
  /// Initializes a `PSBT.Transaction` by decoding the base transaction and its input/output metadata.
  ///
  /// - Throws: `DecodingError` if any of the fields are missing or mismatched in type.
  public init(from decoder: any Swift.Decoder) throws {
    let container = try decoder.container(keyedBy: PSBT.Transaction.CodingKeys.self)
    
    self.tx = try container.decode(Bitcoin.Transaction.self, forKey: .tx)
    self.inputs = try container.decode([PSBT.Input].self, forKey: .inputs)
    self.outputs = try container.decode([PSBT.Output].self, forKey: .outputs)
  }
  
  /// Encodes the full PSBT transaction and its associated metadata to the given encoder.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(tx, forKey: .tx)
    try container.encode(inputs, forKey: .inputs)
    try container.encode(outputs, forKey: .outputs)
  }
}
