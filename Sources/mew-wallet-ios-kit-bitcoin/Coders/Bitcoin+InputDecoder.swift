//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/18/25.
//

import Foundation

extension Bitcoin {
  /// A typealias for decoding Bitcoin transaction inputs.
  public typealias TransactionInputDecoder = Bitcoin.InputDecoder
  
  
  /// A custom decoder specialized for decoding Bitcoin transaction **inputs**.
  ///
  /// This class extends `Bitcoin.Decoder` and overrides its decoding logic
  /// to use the `_Reader.BitcoinTXInput` context, which is optimized
  /// for decoding raw transaction input data.
  ///
  /// This is useful in cases where you are parsing raw transaction data,
  /// such as inspecting or signing individual inputs in a partially signed transaction (PSBT).
  public final class InputDecoder: Bitcoin.Decoder {
    /// Decodes a `Decodable` type from raw input `Data`, using the Bitcoin transaction input reader.
    ///
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - data: The raw input data, typically a binary transaction input.
    ///
    /// - Returns: An instance of the specified `type`.
    /// - Throws: A decoding error if the data does not match the expected format.
    public override func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
      let configuration = DataReaderConfiguration(validation: self.validation)
      let decoder = Bitcoin._Decoding.Decoder<_Reader.BitcoinTXInput>(
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
