//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/18/25.
//

import Foundation
import mew_wallet_ios_kit_bitcoin

extension Bitcoin.Hasher {
  /// Represents errors that may occur during transaction signature hash (sighash) construction.
  enum Error: Swift.Error {
    /// Indicates that the current script type, sighash version, or configuration is not supported by the hasher.
    ///
    /// This is typically returned when trying to use unsupported features like:
    /// - Taproot/Tapscript (not yet implemented)
    /// - Multisig inputs (if hasher does not support them)
    /// - Unknown or malformed scripts
    case notSupported
    
    /// Indicates that one or more required keys (such as transaction, scriptCode, sighash, etc.)
    /// were not provided to the hasher before calling `finalize()`.
    ///
    /// - Parameter keys: The set of missing keys that were expected for sighash computation.
    ///
    /// Example:
    /// ```swift
    /// throw .missingKeys(keys: [.transaction, .inputIndex])
    /// ```
    case missingKeys(keys: Set<Bitcoin.Hasher.Key.ID>)
    
    /// Indicates that encoding the sighash preimage using `Bitcoin.Encoder` failed.
    ///
    /// This may happen if the internal structures are misconfigured or the encoder cannot serialize a required field.
    ///
    /// This error prevents generating the final sighash data for signature signing.
    case encodingFailed
  }
}
