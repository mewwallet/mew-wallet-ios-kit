//
//  Solana+TokenSwapInfo.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/14/25.
//

import Foundation
import mew_wallet_ios_kit

extension Solana {
    public struct TokenSwapInfo: Equatable, Hashable, Codable {
        public let version: UInt8
        public let isInitialized: Bool
        public let nonce: UInt8
        public let tokenProgramId: PublicKey
        public var tokenAccountA: PublicKey
        public var tokenAccountB: PublicKey
        public let tokenPool: PublicKey
        public var mintA: PublicKey
        public var mintB: PublicKey
        public let feeAccount: PublicKey
        public let tradeFeeNumerator: UInt64
        public let tradeFeeDenominator: UInt64
        public let ownerTradeFeeNumerator: UInt64
        public let ownerTradeFeeDenominator: UInt64
        public let ownerWithdrawFeeNumerator: UInt64
        public let ownerWithdrawFeeDenominator: UInt64
        public let hostFeeNumerator: UInt64
        public let hostFeeDenominator: UInt64
        public let curveType: UInt8
        public let payer: PublicKey
        
        public init(
            version: UInt8,
            isInitialized: Bool,
            nonce: UInt8,
            tokenProgramId: PublicKey,
            tokenAccountA: PublicKey,
            tokenAccountB: PublicKey,
            tokenPool: PublicKey,
            mintA: PublicKey,
            mintB: PublicKey,
            feeAccount: PublicKey,
            tradeFeeNumerator: UInt64,
            tradeFeeDenominator: UInt64,
            ownerTradeFeeNumerator: UInt64,
            ownerTradeFeeDenominator: UInt64,
            ownerWithdrawFeeNumerator: UInt64,
            ownerWithdrawFeeDenominator: UInt64,
            hostFeeNumerator: UInt64,
            hostFeeDenominator: UInt64,
            curveType: UInt8,
            payer: PublicKey
        ) {
            self.version = version
            self.isInitialized = isInitialized
            self.nonce = nonce
            self.tokenProgramId = tokenProgramId
            self.tokenAccountA = tokenAccountA
            self.tokenAccountB = tokenAccountB
            self.tokenPool = tokenPool
            self.mintA = mintA
            self.mintB = mintB
            self.feeAccount = feeAccount
            self.tradeFeeNumerator = tradeFeeNumerator
            self.tradeFeeDenominator = tradeFeeDenominator
            self.ownerTradeFeeNumerator = ownerTradeFeeNumerator
            self.ownerTradeFeeDenominator = ownerTradeFeeDenominator
            self.ownerWithdrawFeeNumerator = ownerWithdrawFeeNumerator
            self.ownerWithdrawFeeDenominator = ownerWithdrawFeeDenominator
            self.hostFeeNumerator = hostFeeNumerator
            self.hostFeeDenominator = hostFeeDenominator
            self.curveType = curveType
            self.payer = payer
        }
        
        public init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            
            self.version = try container.decode(UInt8.self)
            self.isInitialized = try container.decode(Bool.self)
            self.nonce = try container.decode(UInt8.self)
            self.tokenProgramId = try container.decode(PublicKey.self)
            self.tokenAccountA = try container.decode(PublicKey.self)
            self.tokenAccountB = try container.decode(PublicKey.self)
            self.tokenPool = try container.decode(PublicKey.self)
            self.mintA = try container.decode(PublicKey.self)
            self.mintB = try container.decode(PublicKey.self)
            self.feeAccount = try container.decode(PublicKey.self)
            self.tradeFeeNumerator = try container.decode(UInt64.self)
            self.tradeFeeDenominator = try container.decode(UInt64.self)
            self.ownerTradeFeeNumerator = try container.decode(UInt64.self)
            self.ownerTradeFeeDenominator = try container.decode(UInt64.self)
            self.ownerWithdrawFeeNumerator = try container.decode(UInt64.self)
            self.ownerWithdrawFeeDenominator = try container.decode(UInt64.self)
            self.hostFeeNumerator = try container.decode(UInt64.self)
            self.hostFeeDenominator = try container.decode(UInt64.self)
            self.curveType = try container.decode(UInt8.self)
            self.payer = try container.decode(PublicKey.self)
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.unkeyedContainer()

            try container.encode(version)
            try container.encode(isInitialized)
            try container.encode(nonce)
            try container.encode(tokenProgramId)
            try container.encode(tokenAccountA)
            try container.encode(tokenAccountB)
            try container.encode(tokenPool)
            try container.encode(mintA)
            try container.encode(mintB)
            try container.encode(feeAccount)
            try container.encode(tradeFeeNumerator)
            try container.encode(tradeFeeDenominator)
            try container.encode(ownerTradeFeeNumerator)
            try container.encode(ownerTradeFeeDenominator)
            try container.encode(ownerWithdrawFeeNumerator)
            try container.encode(ownerWithdrawFeeDenominator)
            try container.encode(hostFeeNumerator)
            try container.encode(hostFeeDenominator)
            try container.encode(curveType)
            try container.encode(payer)
        }
    }
}
