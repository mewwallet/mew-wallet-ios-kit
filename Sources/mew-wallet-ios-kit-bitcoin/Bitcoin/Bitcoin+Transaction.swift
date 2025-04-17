//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/11/25.
//

import Foundation

extension Bitcoin {
  /// A representation of a Bitcoin transaction, including inputs, outputs, version, and locktime.
  public struct Transaction: Equatable, Sendable, Hashable {
    /// Version number of the transaction.
    public let version: Bitcoin.Version
    
    /// List of transaction inputs.
    public let inputs: [Bitcoin.Transaction.Input]
    
    /// List of transaction outputs.
    public let outputs: [Bitcoin.Transaction.Output]
    
    /// Transaction locktime: either a block height or a Unix timestamp.
    public let locktime: Bitcoin.Locktime
    
    /// Initializes a new Bitcoin transaction.
    /// - Parameters:
    ///   - version: Transaction version.
    ///   - inputs: Array of inputs to spend previous outputs.
    ///   - outputs: Array of outputs to create new UTXOs.
    ///   - locktime: Specifies when the transaction can be added to the blockchain.
    public init(version: Bitcoin.Version, inputs: [Bitcoin.Transaction.Input], outputs: [Bitcoin.Transaction.Output], locktime: Bitcoin.Locktime) {
      self.version = version
      self.inputs = inputs
      self.outputs = outputs
      self.locktime = locktime
    }
  }
}

extension Bitcoin.Transaction: Codable {
  /// Coding keys used for (de)serialization of a Bitcoin transaction.
  enum CodingKeys: CodingKey {
    case witness_marker       // Always 0x00 if present.
    case witness_flag         // Always 0x01 if present.
    case version              // Transaction version.
    case locktime             // Transaction locktime.
    case vin                  // Transaction inputs.
    case vout                 // Transaction outputs.
    case script_witnesses     // SegWit witness data.
  }
  
  /// Decodes a Bitcoin transaction from a `Decoder`.
  ///
  /// This initializer supports decoding from both JSON (e.g. for testing or debugging)
  /// and binary formats (e.g. when using a custom binary `Decoder` such as `Bitcoin.Decoder`).
  ///
  /// Fields `vin`, `vout`, `version`, and `locktime` are required.
  /// SegWit fields like `script_witnesses`, `witness_marker`, and `witness_flag` are optional
  /// and may be ignored by JSON or legacy decoders.
  public init(from decoder: any Swift.Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    self.version = try container.decode(Bitcoin.Version.self, forKey: .version)
    self.inputs = try container.decode([Bitcoin.Transaction.Input].self, forKey: .vin)
    self.outputs = try container.decode([Bitcoin.Transaction.Output].self, forKey: .vout)
    self.locktime = try container.decode(Bitcoin.Locktime.self, forKey: .locktime)
  }
  
  /// Encodes a Bitcoin transaction using a `Swift.Encoder`.
  ///
  /// This method supports both binary encoders (e.g. `Bitcoin.Encoder`) and JSON encoders
  /// (e.g. `JSONEncoder` for testing or debugging).
  ///
  /// If any of the inputs contain witness data, the encoder emits SegWit-specific fields:
  /// - `witness_marker` (0x00)
  /// - `witness_flag` (0x01)
  /// - `script_witnesses` (as an array of witness arrays)
  ///
  /// These fields are omitted for non-SegWit transactions to preserve compatibility with legacy format.
  public func encode(to encoder: any Swift.Encoder) throws {
    var container = encoder.container(keyedBy: Bitcoin.Transaction.CodingKeys.self)
    
    try container.encode(self.version, forKey: .version)
    
    let hasWitness = self.inputs.contains(where: { (input: Bitcoin.Transaction.Input) in
      input.txinwitness?.isEmpty == false
    })
    
    if hasWitness {
      try container.encode(UInt8(0), forKey: .witness_marker)
      try container.encode(UInt8(1), forKey: .witness_flag)
    }
    
    try container.encode(self.inputs, forKey: .vin)
    try container.encode(self.outputs, forKey: .vout)
    
    if hasWitness {
      var witnessContainer = container.nestedUnkeyedContainer(forKey: .script_witnesses)
      try self.inputs.forEach { (input: Bitcoin.Transaction.Input) in
        try witnessContainer.encode(input.txinwitness ?? [])
      }
    }
    
    try container.encode(self.locktime, forKey: .locktime)
  }
}

#if DEBUG
extension Bitcoin.Transaction {
  /// Pretty-prints the transaction in JSON format, useful for debugging.
  public func _prettyPrint() -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted]
    encoder.dataEncodingStrategy = .custom({ data, encoder in
      var container = encoder.singleValueContainer()
      try container.encode(data.toHexString())
    })
    guard let encoded = try? encoder.encode(self) else {
      return "<failed>"
    }
    return String(data: encoded, encoding: .utf8) ?? "<failed>"
  }
}
#endif
