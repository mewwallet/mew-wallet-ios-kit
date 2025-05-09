//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/18/25.
//

import Foundation

extension Bitcoin {
  /// A typealias for decoding Bitcoin transaction outputs.
  public typealias TransactionOutputDecoder = Bitcoin.OutputDecoder
  
  /// A custom decoder specialized for decoding Bitcoin transaction **outputs**.
  ///
  /// This decoder is designed for parsing raw transaction output data from
  /// binary Bitcoin transaction payloads.
  ///
  /// It uses the internal `_Reader.BitcoinTXOutput` reader context, which is optimized
  /// for interpreting the `value` (amount) and `scriptPubKey` fields of a Bitcoin output.
  ///
  /// Typical usage includes:
  /// - Extracting output information from serialized transactions
  /// - Verifying destination addresses and amounts
  /// - Reconstructing transaction outputs in PSBT contexts
  public final class OutputDecoder: Bitcoin.Decoder {
    /// Decodes a `Decodable` type from raw output `Data`, using the Bitcoin transaction output reader.
    ///
    /// - Parameters:
    ///   - type: The type to decode. Usually `Bitcoin.Transaction.Output`.
    ///   - data: The raw binary data of the transaction output.
    ///
    /// - Returns: A decoded instance of the specified type.
    /// - Throws: An error if the data is malformed or does not match the expected format.
    public override func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
      let configuration = DataReaderConfiguration(validation: self.validation)
      let decoder = Bitcoin._Decoding.Decoder<_Reader.BitcoinTXOutput>(
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
