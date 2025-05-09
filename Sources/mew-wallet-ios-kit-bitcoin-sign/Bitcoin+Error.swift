//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/17/25.
//

import Foundation
import mew_wallet_ios_kit_bitcoin

extension Bitcoin {
  /// Errors that can occur during the Bitcoin transaction signing process.
  public enum SignError: Swift.Error {
    
    /// The number of inputs in the PSBT does not match the number of inputs in the unsigned transaction.
    /// This often indicates a malformed or incomplete PSBT.
    case outputsNotMatch
    
    /// The output script is not in a recognized or supported format.
    /// This may happen if the script type is unknown or not implemented in the signer logic.
    case invalidOutputScript
    
    /// A general signing failure, often due to unexpected conditions.
    /// This is a fallback error for cases that don't fit into other categories.
    case signingError
    
    /// The hash used for signing is not the expected 32 bytes in length.
    /// ECDSA signing with `secp256k1` requires a SHA256-style 32-byte hash.
    case invalidHashLength
    
    /// Failed to create or initialize the `secp256k1` context.
    /// This usually indicates a problem with the cryptographic backend.
    case contextFailed
    
    /// Signature verification failed after signing.
    /// This is used as a safety check to ensure the produced signature is valid and can be verified.
    case verificationFailed
    
    /// An error occurred during DER encoding of the signature.
    /// This may happen if the signature is malformed or not normalized correctly.
    case badDerSignature
    
    /// The operation or script type is not supported by the signer.
    /// This includes unsupported script types (e.g. multisig, taproot) or sigHash variants not implemented.
    case notSupported
  }
}
