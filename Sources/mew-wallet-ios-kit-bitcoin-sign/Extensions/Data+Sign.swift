//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/19/25.
//

import Foundation
import CryptoSwift
import mew_wallet_ios_kit
import mew_wallet_ios_secp256k1
import mew_wallet_ios_kit_bitcoin

extension Data {
  enum SignatureConstants {
    /// Expected SHA256 hash size
    static let hashLength = 32
    /// Size of entropy buffer for RFC6979
    static let extraEntropyLength = 32
    /// r (32 bytes) + s (32 bytes)
    static let compactSigLength = 64
    /// Max size of DER-encoded ECDSA signature
    static let derMaxLength = 72
    /// Max number of attempts to grind for low-R
    static let maxGrindAttempts: UInt32 = 100
  }
  
  /// Generates a canonical ECDSA signature (DER-encoded + sighashType) over a 32-byte message hash.
  ///
  /// This method performs the following:
  /// - Uses deterministic RFC6979 signing with optional entropy grind to produce low-R signatures
  /// - Normalizes the `s` component to low-s form (BIP-62 compliance)
  /// - Verifies the resulting signature against the public key derived from `key`
  ///
  /// Signature is serialized in DER format, with the `sigHash` type byte appended.
  ///
  /// - Parameters:
  ///   - key: The secp256k1 private key used to sign the hash
  ///   - sigHash: The sighash type to append to the signature (default is `.all`)
  /// - Returns: A valid, normalized DER-encoded ECDSA signature with appended sighash type
  /// - Throws:
  ///   - `.invalidHashLength` if the data is not exactly 32 bytes
  ///   - `.contextFailed` if the signing context could not be created
  ///   - `.badDerSignature` if the signature could not be produced or serialized
  ///   - `.verificationFailed` if the signature fails self-verification
  func signDER(key: PrivateKey, sigHash: Bitcoin.SigHash = .all) throws(Bitcoin.SignError) -> Data {
    // Ensure the input is a 32-byte hash
    guard self.count == SignatureConstants.hashLength else {
      throw .invalidHashLength
    }

    // Create signing + verification context
    guard let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY)) else {
      throw .contextFailed
    }
    defer { secp256k1_context_destroy(context) }

    var counter: UInt32 = 2
    // Hash to sign
    var message = self.byteArray
    var privateKey = key.data().byteArray
    var signature = secp256k1_ecdsa_signature()
    var extraEntropy = [UInt8](repeating: 0, count: SignatureConstants.extraEntropyLength)
    
    // Final DER + sighashType signature
    var signatureData: Data?

    grind: while counter < SignatureConstants.maxGrindAttempts {
      writeLE32(counter, to: &extraEntropy)

      // Sign the message hash using RFC6979 + extraEntropy
      guard secp256k1_ecdsa_sign(context, &signature, &message, &privateKey, secp256k1_nonce_function_rfc6979, extraEntropy) == 1 else {
        throw .badDerSignature
      }

      // Normalize the signature to low-s form (canonical)
      var normalizedSig = secp256k1_ecdsa_signature()
      secp256k1_ecdsa_signature_normalize(context, &normalizedSig, &signature)

      // Check r prefix for low-R (no leading 0x00 in DER)
      var compact = [UInt8](repeating: 0, count: SignatureConstants.compactSigLength)
      secp256k1_ecdsa_signature_serialize_compact(context, &compact, &normalizedSig)

      // If not low-R and we already found a fallback, keep grinding
      guard compact[0] < 0x80 || signatureData == nil else {
        counter += 1
        continue
      }

      // Verify the generated signature before using it
      var pubkey = secp256k1_pubkey()
      guard secp256k1_ec_pubkey_create(context, &pubkey, &privateKey) == 1,
            secp256k1_ecdsa_verify(context, &normalizedSig, &message, &pubkey) == 1 else {
        throw .verificationFailed
      }

      // Serialize normalized signature to DER format
      var der = [UInt8](repeating: 0, count: SignatureConstants.derMaxLength)
      var derLen = SignatureConstants.derMaxLength
      guard secp256k1_ecdsa_signature_serialize_der(context, &der, &derLen, &normalizedSig) == 1 else {
        throw .badDerSignature
      }
      
      // Save signature with sighashType byte appended
      signatureData = Data(der[..<derLen]) + [sigHash.type]
      
      // If low-R, break immediately. Otherwise, continue grinding.
      guard compact[0] < 0x80 else {
        counter += 1
        continue
      }
      break grind
    }

    // Make sure we produced a valid signature
    guard let signatureData else {
      throw .badDerSignature
    }
    return signatureData
  }

  /// Writes a UInt32 to a byte buffer in little-endian order.
  private func writeLE32(_ value: UInt32, to buffer: inout [UInt8]) {
    buffer[0] = UInt8(value & 0xff)
    buffer[1] = UInt8((value >> 8) & 0xff)
    buffer[2] = UInt8((value >> 16) & 0xff)
    buffer[3] = UInt8((value >> 24) & 0xff)
  }
}
