//
//  Solana._BorshEncoding+UnkeyedContainer+Decoder.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit
import mew_wallet_ios_kit_utils

extension Solana._Borsh {
    /// An unkeyed decoding container for Borsh deserialization with AccountInfo sections.
    internal struct UnkeyedDecodingContainer: Swift.UnkeyedDecodingContainer {
        /// Current coding path, inherited from the parent decoder.
        var codingPath: [any CodingKey] { decoder.codingPath }

        /// The current index into the sequence of elements.
        var currentIndex: Int = 0

        /// Current section being decoded
        var section: Solana._Borsh.Decoder.Section

        /// Parent decoder used to propagate configuration and context.
        private let decoder: Solana._Borsh.Decoder

        init(decoder: Solana._Borsh.Decoder) {
            self.decoder = decoder
            self.section = decoder.section
            self.currentIndex = 0
        }

        /// The total number of decodable elements, if known.
        var count: Int?

        /// Boolean indicating if all elements have been decoded.
        var isAtEnd: Bool {
            guard let count = self.count else { return false }
            return currentIndex >= count
        }

        mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
            guard !isAtEnd else {
              throw DecodingError.valueNotFound(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Unkeyed container is at end."))
            }

            switch self.section {
            case .publicKey:
                let decoded = try T(from: self.decoder)
                return decoded
            case .universal:
                throw DecodingError.dataCorruptedError(in: self, debugDescription: "Unknown field")
            }
        }

        // MARK: - Unsupported

        func decodeNil() throws -> Bool {
            throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Nil values are not supported in Borsh"))
        }

        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> Swift.KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Nested keyed containers are not supported in Borsh"))
        }

        func nestedUnkeyedContainer() throws -> Swift.UnkeyedDecodingContainer {
            throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Nested unkeyed containers are not supported in Borsh"))
        }

        func superDecoder() throws -> Swift.Decoder {
            throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Super decoder is not supported in Borsh"))
        }
    }
}
