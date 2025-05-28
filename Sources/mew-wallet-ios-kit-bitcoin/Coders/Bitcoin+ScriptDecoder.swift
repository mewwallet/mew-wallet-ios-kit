//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/19/25.
//

import Foundation

extension Bitcoin {
  /// A custom decoder for parsing Bitcoin `Script` structures from raw binary data.
  ///
  /// `ScriptDecoder` is a specialized subclass of `Bitcoin.Decoder` that uses
  /// the internal `_Reader.Script` context to correctly interpret Bitcoin scripts,
  /// such as `scriptSig` and `scriptPubKey`.
  ///
  /// This is useful for decoding:
  /// - `scriptSig` in legacy transaction inputs
  /// - `scriptPubKey` in transaction outputs
  /// - Raw scripts in `redeemScript`, `witnessScript`, or `scriptCode` contexts
  ///
  /// Example:
  /// ```swift
  /// let decoder = Bitcoin.ScriptDecoder()
  /// let script = try decoder.decode(Bitcoin.Script.self, from: rawScriptData)
  /// ```
  public final class ScriptDecoder: Bitcoin.Decoder {
    /// Decodes a Bitcoin `Script` (or any `Decodable` type) from binary data.
    ///
    /// - Parameters:
    ///   - type: The type to decode (typically `Bitcoin.Script`).
    ///   - data: Raw binary data representing the script.
    ///
    /// - Returns: An instance of the decoded type.
    /// - Throws: An error if decoding fails due to malformed script or mismatched structure.
    public override func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
      let configuration = DataReaderConfiguration(validation: self.validation)
      let decoder = Bitcoin._Decoding.Decoder<_Reader.Script>(
        data: [data],
        context: nil,
        map: nil,
        userInfo: userInfo,
        configuration: configuration
      )
      return try T(from: decoder)
    }
  }
}
