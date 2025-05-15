//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/11/25.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

extension PSBT {
  /// A decoder for parsing PSBT (Partially Signed Bitcoin Transaction) structures from binary data.
  ///
  /// This decoder validates the presence of the PSBT magic prefix (`0x70736274ff`, which corresponds to `psbt\xff`)
  /// before decoding the remainder of the data using the PSBT-specific decoding strategy.
  ///
  /// Example:
  /// ```swift
  /// let decoder = PSBT.Decoder()
  /// let psbt = try decoder.decode(PSBT.Transaction.self, from: psbtData)
  /// ```
  public final class Decoder {
    // TODO: Move this to map
    /// Magic bytes required at the start of every PSBT stream: "psbt" + 0xFF.
    /// Hex representation: `70 73 62 74 ff`
    static let magic: [UInt8] = [0x70, 0x73, 0x62, 0x74, 0xFF] // psbt + 0xFF
    
    /// Contextual user-provided information for decoding.
    public var userInfo: [CodingUserInfoKey : any Sendable] = [:]
    
    public init() {}
    
    /// Decodes a PSBT structure from raw binary data.
    ///
    /// - Parameters:
    ///   - type: The expected type to decode.
    ///   - data: A raw `Data` object containing the PSBT-encoded binary.
    /// - Returns: An instance of the decoded type.
    /// - Throws:
    ///   - `DecodingError.dataCorrupted`: If data is too short to contain a valid PSBT prefix.
    ///   - `DecodingError.valueNotFound`: If the PSBT magic prefix is missing or malformed.
    public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
      guard data.count > Self.magic.count else {
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Insufficient data: expected at least \(Self.magic.count + 1) bytes, got \(data.count)"))
      }
      guard data.prefix(Self.magic.count).elementsEqual(Self.magic) else {
        throw DecodingError.valueNotFound(Any?.self, DecodingError.Context(codingPath: [], debugDescription: "Missing PSBT magic prefix: expected [0x70, 0x73, 0x62, 0x74, 0xFF] ('psbt\\xFF')"))
      }
      
      let decoder = PSBT._Decoding.Decoder<_Reader.PSBT>(
        data: [data.dropFirst(Self.magic.count)], // Remove magic before decoding
        context: nil,
        map: nil,
        userInfo: self.userInfo
      )
      return try T(from: decoder)
    }
  }
}

#if canImport(Combine)
extension PSBT.Decoder: TopLevelDecoder {}
#endif
