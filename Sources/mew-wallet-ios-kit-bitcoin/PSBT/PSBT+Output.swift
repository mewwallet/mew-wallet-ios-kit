//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/17/25.
//

import Foundation

extension PSBT {
  /// Represents a single output in a Partially Signed Bitcoin Transaction (PSBT).
  ///
  /// A PSBT output may include optional scripts that indicate how the output
  /// can be spent, such as a redeem script for P2SH or a witness script for P2WSH.
  ///
  /// This struct models output-specific metadata attached during wallet coordination.
  public struct Output: Equatable, Sendable {
    /// The redeem script associated with the output, if applicable.
    ///
    /// This is used in Pay-to-Script-Hash (P2SH) constructions,
    /// where the script is hashed in the `scriptPubKey` and revealed during spending.
    public let redeemScript: Bitcoin.Script?
    
    /// The witness script associated with the output, if applicable.
    ///
    /// This is used in Pay-to-Witness-Script-Hash (P2WSH) constructions,
    /// where the witness program is revealed in the witness stack.
    public let witnessScript: Bitcoin.Script?
  }
}

// MARK: - PSBT.Output + Codable

extension PSBT.Output: Codable {
  enum CodingKeys: CodingKey {
    case redeemScript
    case witnessScript
  }
  
  /// Decodes a PSBT output from a keyed container.
  ///
  /// Attempts to decode the optional `redeemScript` and `witnessScript` fields.
  public init(from decoder: any Swift.Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.redeemScript = try container.decodeIfPresent(Bitcoin.Script.self, forKey: .redeemScript)
    self.witnessScript = try container.decodeIfPresent(Bitcoin.Script.self, forKey: .witnessScript)
  }
  
  /// Encodes a PSBT output to a keyed container.
  ///
  /// Only non-nil scripts are encoded.
  public func encode(to encoder: any Swift.Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(redeemScript, forKey: .redeemScript)
    try container.encodeIfPresent(witnessScript, forKey: .witnessScript)
  }
}
