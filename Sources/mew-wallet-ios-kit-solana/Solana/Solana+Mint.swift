//
//  Solana+Mint.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/14/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
    public struct Mint: Equatable, Hashable, Encodable, Decodable {
        public let mintAuthorityOption: UInt32
        public let mintAuthority: PublicKey?
        public let supply: UInt64
        public let decimals: UInt8
        public let isInitialized: Bool
        public let freezeAuthorityOption: UInt32
        public let freezeAuthority: PublicKey?
        
        public init(
            mintAuthorityOption: UInt32,
            mintAuthority: PublicKey?,
            supply: UInt64,
            decimals: UInt8,
            isInitialized: Bool,
            freezeAuthorityOption: UInt32,
            freezeAuthority: PublicKey?
        ) {
            self.mintAuthorityOption = mintAuthorityOption
            self.mintAuthority = mintAuthority
            self.supply = supply
            self.decimals = decimals
            self.isInitialized = isInitialized
            self.freezeAuthorityOption = freezeAuthorityOption
            self.freezeAuthority = freezeAuthority
        }
        
        public init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            
            self.mintAuthorityOption = try container.decode(UInt32.self)
            let mintAuthorityData = try container.decode(PublicKey.self)
            self.mintAuthority = self.mintAuthorityOption == 1 ? mintAuthorityData : nil
            
            self.supply = try container.decode(UInt64.self)
            self.decimals = try container.decode(UInt8.self)
            self.isInitialized = try container.decode(Bool.self)
            self.freezeAuthorityOption = try container.decode(UInt32.self)
            let freezeAuthorityData = try container.decode(PublicKey.self)
            self.freezeAuthority = self.freezeAuthorityOption == 1 ? freezeAuthorityData : nil
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            
            try container.encode(mintAuthorityOption)
            
            // Always encode mintAuthority field (32 bytes) regardless of option
            // If mintAuthority is nil, encode a zero PublicKey
            if let mintAuthority {
                try container.encode(mintAuthority)
            } else {
                try container.encode(Data(repeating: 0, count: 32))
            }
            
            try container.encode(supply)
            try container.encode(decimals)
            try container.encode(isInitialized)
            try container.encode(freezeAuthorityOption)
            
            // Always encode freezeAuthority field (32 bytes) regardless of option
            // If freezeAuthority is nil, encode a zero PublicKey
            if let freezeAuthority {
                try container.encode(freezeAuthority)
            } else {
                try container.encode(Data(repeating: 0, count: 32))
            }
        }
    }
}
