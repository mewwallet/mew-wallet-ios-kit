//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
  /// A pair consisting of a transaction signature and its corresponding public key.
  ///
  /// This structure is used within Solana transactions to maintain the mapping
  /// between each account's public key and its associated 64-byte Ed25519 signature.
  /// If a signature is missing (`nil`), it indicates that the account has not signed
  /// the transaction yet.
  public struct SignaturePubkeyPair: Equatable, Sendable {
    /// The 64-byte Ed25519 signature corresponding to `publicKey`.
    /// If `nil`, a placeholder (zeroed 64-byte array) will be encoded.
    public var signature: Data?
    
    /// The public key of the signer.
    public var publicKey: PublicKey
    
    /// Creates a new pair of signature and public key.
    ///
    /// - Parameters:
    ///   - signature: Optional signature data (64 bytes expected).
    ///   - publicKey: The public key corresponding to the signature.
    public init(signature: Data?, publicKey: PublicKey) {
      precondition(signature == nil || signature?.count == 64)
      self.signature = signature
      self.publicKey = publicKey
    }
  }
}

/// Decoding is intentionally not supported at this level.
/// `SignaturePubkeyPair` instances are constructed manually when parsing
/// transaction wire formats, so decoding from `Codable` is not implemented.
extension Solana.SignaturePubkeyPair: Codable {
  public init(from decoder: any Decoder) throws {
    fatalError("Not implemented")
  }
  
  /// Encodes only the signature portion of the pair.
  ///
  /// When serializing a transaction for signing or submission, only the
  /// 64-byte signature array (or 64 zero bytes if unsigned) is emitted.
  /// The corresponding public keys are serialized separately as part of
  /// the message account keys.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    if let signature {
      try container.encode(signature)
    } else {
      // If the account hasn’t signed, encode a 64-byte zero array.
      try container.encode(Data(repeating: 0x00, count: 64))
    }
  }
}
