//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/12/25.
//

import Foundation
import mew_wallet_ios_kit
import mew_wallet_ios_tweetnacl

extension Solana {
  /// A version-agnostic Solana transaction wrapper that pairs a `VersionedMessage`
  /// (either legacy or v0) with its signature list in wire-compatible order.
  ///
  /// ### Wire layout
  /// Matches Solana’s canonical encoding:
  /// 1. ShortVec-encoded signature count (must equal `message.header.numRequiredSignatures`)
  /// 2. `count` × 64-byte Ed25519 signatures (zeroed signatures mean “absent”)
  /// 3. Serialized `VersionedMessage` (legacy or v0)
  ///
  /// ### Invariants
  /// - `signatures.count == message.header.numRequiredSignatures`
  /// - Each signature (if present) is exactly 64 bytes
  /// - For legacy messages there’s no version byte in the message; for v0, a version
  ///   discriminator byte precedes the header (handled by `MessageV0.encode/decode`).
  ///
  /// ### Notes
  /// - This type does not perform cryptographic verification. It only carries bytes
  ///   and preserves wire order/shape. Signature verification should be performed by
  ///   your crypto layer (e.g., TweetNaCl).
  /// - The `recentBlockhash` property mutates the underlying message while preserving
  ///   the enum case (`.legacy` vs `.v0`).
  public struct VersionedTransaction {
    public enum Error: Swift.Error, Equatable {
      /// A provided signature does not have the expected 64-byte length.
      case invalidSignature
      /// The number of signatures does not match `numRequiredSignatures`.
      case invalidSignaturesCount
      /// Attempted to set/provide a signature for an account that isn't required to sign.
      case signerIsNotRequired(PublicKey)
    }
    
    /// Signatures in the same order as the first `numRequiredSignatures` account keys
    /// of the underlying message. A zeroed 64-byte entry denotes “no signature”.
    public var signatures: [Data]
    
    /// The wrapped message (legacy or v0). This determines both the number of required
    /// signatures and the message serialization shape.
    public private(set) var message: VersionedMessage
    
    /// The message version (convenience mirror of `message.version`).
    public var version: Solana.Version {
      return message.version
    }
    
    /// Convenience accessor to the message’s recent blockhash. Setting this mutates the
    /// inner message while preserving its variant (`.legacy` or `.v0`).
    public var recentBlockhash: String {
      get {
        switch message {
        case .legacy(let message):    return message.recentBlockhash
        case .v0(let message):        return message.recentBlockhash
        }
      }
      set {
        switch message {
        case .legacy(var message):
          message.recentBlockhash = newValue
          self.message = .legacy(message)
        case .v0(var message):
          message.recentBlockhash = newValue
          self.message = .v0(message)
        }
      }
    }
    
    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - message: The versioned message to wrap.
    ///   - signatures: Optional signatures array. If omitted, the array is created and
    ///     filled with 64 zero bytes per required signature.
    ///
    /// - Throws:
    ///   - `invalidSignaturesCount` if the provided count does not match the
    ///     message’s `numRequiredSignatures`.
    ///   - `invalidSignature` if any provided signature is not exactly 64 bytes long.
    public init(message: VersionedMessage, signatures: [Data]? = nil) throws {
      if let signatures {
        guard signatures.count == message.header.numRequiredSignatures else { throw Error.invalidSignaturesCount }
        // Safety: enforce 64-byte signatures
        guard signatures.allSatisfy({ $0.count == 64 }) else { throw Error.invalidSignature }
        self.signatures = signatures
      } else {
        self.signatures = [Data](repeating: Data(repeating: 0x00, count: 64), count: Int(message.header.numRequiredSignatures))
      }
      self.message = message
    }
  }
}

extension Solana.VersionedTransaction: Codable {
  public init(from decoder: any Decoder) throws {
    var container = try decoder.unkeyedContainer()

    // signatures vec
    let rawSignatures = try container.decode([Data].self)
    
    // versioned message
    let message = try container.decode(Solana.VersionedMessage.self)

    // Validate counts and signature sizes
    guard rawSignatures.count == message.header.numRequiredSignatures else {
      throw Error.invalidSignaturesCount
    }
    guard rawSignatures.allSatisfy({ $0.count == 64 }) else {
      throw Error.invalidSignature
    }

    self.signatures = rawSignatures
    self.message = message
  }
  
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.unkeyedContainer()
    
    try container.encode(self.signatures)
    
    try container.encode(self.message)
  }
}
