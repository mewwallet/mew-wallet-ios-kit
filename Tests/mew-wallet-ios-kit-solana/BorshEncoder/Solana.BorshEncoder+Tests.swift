//
//  Solana.BorshEncoder+Tests.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import Testing
@testable import mew_wallet_ios_kit_solana
@testable import mew_wallet_ios_kit

@Suite struct SolanaBorshEncoderTests {
    
    private enum Errors: Error {
        case invalidInput
    }
    
    // MARK: - Encoder Tests (Golden Tests)
    
    @Test("Encode AccountInfo with delegate and frozen state")
    func testEncodeAccountInfo() throws {
        let expectedBase64 = "BhrZ0FOHFUhTft4+JhhJo9+3/QL6vHWyI8jkatuFPQwCqmOzhzy1ve5l2AqL0ottCChJZ1XSIW3k3C7TaBQn7aCGAQAAAAAAAQAAAOt6vNDYdevCbaGxgaMzmz7yoxaVu3q9vGeCc7ytzeWqAQAAAAAAAAAAAAAAAGQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        
        // Decode the expected data first
        guard let expectedData = Data(base64Encoded: expectedBase64) else {
            throw Errors.invalidInput
        }
        
        let accountInfo = try expectedData.decodeBorsh(Solana.AccountInfo.self)
        
        // Now encode it back and verify it matches
        let encodedData = try accountInfo.encodeBorsh()
        let encodedBase64 = encodedData.base64EncodedString()
        
        #expect(encodedBase64 == expectedBase64)
    }
    
    @Test("Encode AccountInfo without delegate and with frozen state")
    func testEncodeAccountInfo2() throws {
        let expectedBase64 = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAOt6vNDYdevCbaGxgaMzmz7yoxaVu3q9vGeCc7ytzeWq"
        
        // Decode the expected data first
        guard let expectedData = Data(base64Encoded: expectedBase64) else {
            throw Errors.invalidInput
        }
        
        let accountInfo = try expectedData.decodeBorsh(Solana.AccountInfo.self)
        
        // Now encode it back and verify it matches
        let encodedData = try accountInfo.encodeBorsh()
        let encodedBase64 = encodedData.base64EncodedString()
        
        #expect(encodedBase64 == expectedBase64)
    }
    
    @Test("Encode TokenSwapInfo with all fields")
    func testEncodeTokenSwap() throws {
        let expectedBase64 = "AQH/Bt324ddloZPZy+FGzut5rBy0he1fWzeROoz1hX7/AKnPPnmVdf8VefedpPOl3xy2V/o+YvTT+f/dj/1blp9D9lI+9w67aLlO5X6dSFPB7WkhvyP+71AxESXk7Qw9nyYEYH7t0UamkBlPrllRfjnQ9h+sx/GQHoBS4AbWPpi2+m5dBuymmuZeydiI91aVN//6kR8bk4czKnvSXu1WXNW4hwabiFf+q4GE+2h/Y0YYwDXaxDncGus7VZig8AAAAAAB1UBY8wcrypvzuco4dv7UUURt8t9MOpnq7YnffB1OovkZAAAAAAAAABAnAAAAAAAABQAAAAAAAAAQJwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAUAAAAAAAAAGQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        
        // Decode the expected data first
        guard let expectedData = Data(base64Encoded: expectedBase64) else {
            throw Errors.invalidInput
        }
        
        let tokenSwapInfo = try expectedData.decodeBorsh(Solana.TokenSwapInfo.self, style: .universal)
        
        // Now encode it back and verify it matches
        let encodedData = try tokenSwapInfo.encodeBorsh()
        let encodedBase64 = encodedData.base64EncodedString()
        
        #expect(encodedBase64 == expectedBase64)
    }
    
    @Test("Encode Mint layout with authority and supply")
    func testEncodeMint() throws {
        let expectedBase64 = "AQAAAAYa2dBThxVIU37ePiYYSaPft/0C+rx1siPI5GrbhT0MABCl1OgAAAAGAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=="
        
        // Decode the expected data first
        guard let expectedData = Data(base64Encoded: expectedBase64) else {
            throw Errors.invalidInput
        }
        
        let mintLayout = try expectedData.decodeBorsh(Solana.Mint.self)
        
        // Now encode it back and verify it matches
        let encodedData = try mintLayout.encodeBorsh()
        let encodedBase64 = encodedData.base64EncodedString()
        
        #expect(encodedBase64 == expectedBase64)
    }
    
    @Test("Encode AccountInfo with different styles")
    func testEncodeWithStyle() throws {
        let expectedBase64 = "BhrZ0FOHFUhTft4+JhhJo9+3/QL6vHWyI8jkatuFPQwCqmOzhzy1ve5l2AqL0ottCChJZ1XSIW3k3C7TaBQn7aCGAQAAAAAAAQAAAOt6vNDYdevCbaGxgaMzmz7yoxaVu3q9vGeCc7ytzeWqAQAAAAAAAAAAAAAAAGQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        
        // Decode the expected data first
        guard let expectedData = Data(base64Encoded: expectedBase64) else {
            throw Errors.invalidInput
        }
        
        let accountInfo = try expectedData.decodeBorsh(Solana.AccountInfo.self, style: .universal)
        
        // Now encode it back and verify it matches
        let encodedData = try accountInfo.encodeBorsh()
        let encodedBase64 = encodedData.base64EncodedString()
        
        #expect(encodedBase64 == expectedBase64)
    }
    
    // MARK: - Decoder Tests (Original Tests)
        
    @Test("Decode AccountInfo with delegate and frozen state")
    func testDecodingAccountInfo() throws {
        let string = #"BhrZ0FOHFUhTft4+JhhJo9+3/QL6vHWyI8jkatuFPQwCqmOzhzy1ve5l2AqL0ottCChJZ1XSIW3k3C7TaBQn7aCGAQAAAAAAAQAAAOt6vNDYdevCbaGxgaMzmz7yoxaVu3q9vGeCc7ytzeWqAQAAAAAAAAAAAAAAAGQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"#
        
        // Convert base64 string to Data and decode using Borsh
        guard let data = Data(base64Encoded: string) else {
            throw Errors.invalidInput
        }
        
        let accountInfo = try data.decodeBorsh(Solana.AccountInfo.self)
        #expect(accountInfo.mint.base58EncodedString == "QqCCvshxtqMAL2CVALqiJB7uEeE5mjSPsseQdDzsRUo")
        #expect(accountInfo.owner.base58EncodedString == "BQWWFhzBdw2vKKBUX17NHeFbCoFQHfRARpdztPE2tDJ")
        #expect(accountInfo.delegate?.base58EncodedString == "GrDMoeqMLFjeXQ24H56S1RLgT4R76jsuWCd6SvXyGPQ5")
        #expect(accountInfo.delegatedAmount == 100)
        #expect(accountInfo.isNative == false)
        #expect(accountInfo.isInitialized == true)
        #expect(accountInfo.isFrozen == false)
        #expect(accountInfo.rentExemptReserve == nil)
        #expect(accountInfo.closeAuthority == nil)
    }

    @Test("Decode AccountInfo without delegate and with frozen state")
    func testDecodingAccountInfo2() throws {
        let string = #"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAOt6vNDYdevCbaGxgaMzmz7yoxaVu3q9vGeCc7ytzeWq"#
        
        // Convert base64 string to Data and decode using Borsh
        guard let data = Data(base64Encoded: string) else {
            throw Errors.invalidInput
        }
        
        let accountInfo = try data.decodeBorsh(Solana.AccountInfo.self)
        #expect(accountInfo.delegate == nil)
        #expect(accountInfo.delegatedAmount == 0)
        #expect(accountInfo.isInitialized == false)
        #expect(accountInfo.isNative == false)
        #expect(accountInfo.rentExemptReserve == nil)
        #expect(accountInfo.closeAuthority?.base58EncodedString == "GrDMoeqMLFjeXQ24H56S1RLgT4R76jsuWCd6SvXyGPQ5")

        let string2 = #"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAOt6vNDYdevCbaGxgaMzmz7yoxaVu3q9vGeCc7ytzeWq"#
        
        // Convert base64 string to Data and decode using Borsh
        guard let data2 = Data(base64Encoded: string2) else {
            throw Errors.invalidInput
        }
        
        let accountInfo2 = try data2.decodeBorsh(Solana.AccountInfo.self)
        #expect(accountInfo2.isFrozen == true)
    }
    
    @Test("Decode TokenSwapInfo with all fields")
    func testDecodingTokenSwap() throws {
        let string = #"AQH/Bt324ddloZPZy+FGzut5rBy0he1fWzeROoz1hX7/AKnPPnmVdf8VefedpPOl3xy2V/o+YvTT+f/dj/1blp9D9lI+9w67aLlO5X6dSFPB7WkhvyP+71AxESXk7Qw9nyYEYH7t0UamkBlPrllRfjnQ9h+sx/GQHoBS4AbWPpi2+m5dBuymmuZeydiI91aVN//6kR8bk4czKnvSXu1WXNW4hwabiFf+q4GE+2h/Y0YYwDXaxDncGus7VZig8AAAAAAB1UBY8wcrypvzuco4dv7UUURt8t9MOpnq7YnffB1OovkZAAAAAAAAABAnAAAAAAAABQAAAAAAAAAQJwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAUAAAAAAAAAGQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"#
        
        // Convert base64 string to Data and decode using Borsh
        guard let data = Data(base64Encoded: string) else {
            throw Errors.invalidInput
        }
        
        // Try with specific decoding style
        let tokenSwapInfo = try data.decodeBorsh(Solana.TokenSwapInfo.self, style: .universal)
        #expect(tokenSwapInfo.version == 1)
        #expect(tokenSwapInfo.tokenProgramId.base58EncodedString == "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
        #expect(tokenSwapInfo.mintA.base58EncodedString == "7G93KAMR8bLq5TvgLHmpACLXCYwDcdtXVBKsN5Fx41iN")
        #expect(tokenSwapInfo.mintB.base58EncodedString == "So11111111111111111111111111111111111111112")
        #expect(tokenSwapInfo.curveType == 0)
        #expect(tokenSwapInfo.isInitialized == true)
        #expect(tokenSwapInfo.payer.base58EncodedString == "11111111111111111111111111111111")
    }
    
    @Test("Decode Mint layout with authority and supply")
    func testDecodingMint() throws {
        let string = #"AQAAAAYa2dBThxVIU37ePiYYSaPft/0C+rx1siPI5GrbhT0MABCl1OgAAAAGAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=="#
        
        guard let data = Data(base64Encoded: string) else {
            throw Errors.invalidInput
        }
        
        let mintLayout = try data.decodeBorsh(Solana.Mint.self)
        #expect(mintLayout.mintAuthority?.base58EncodedString == "QqCCvshxtqMAL2CVALqiJB7uEeE5mjSPsseQdDzsRUo")
        #expect(mintLayout.supply == 1000000000000)
        #expect(mintLayout.decimals == 6)
        #expect(mintLayout.isInitialized == true)
        #expect(mintLayout.freezeAuthority == nil)
    }
    
    @Test("Decode AccountInfo with different styles")
    func testDecodingWithStyle() throws {
        // Test that the style parameter works correctly
        let accountInfoString = #"BhrZ0FOHFUhTft4+JhhJo9+3/QL6vHWyI8jkatuFPQwCqmOzhzy1ve5l2AqL0ottCChJZ1XSIW3k3C7TaBQn7aCGAQAAAAAAAQAAAOt6vNDYdevCbaGxgaMzmz7yoxaVu3q9vGeCc7ytzeWqAQAAAAAAAAAAAAAAAGQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"#
        
        guard let accountInfoData = Data(base64Encoded: accountInfoString) else {
            throw Errors.invalidInput
        }
        
        // Test with explicit style
        let accountInfo = try accountInfoData.decodeBorsh(Solana.AccountInfo.self, style: .universal)
        #expect(accountInfo.mint.base58EncodedString == "QqCCvshxtqMAL2CVALqiJB7uEeE5mjSPsseQdDzsRUo")
        
        // Test with default style (should work the same)
        let accountInfo2 = try accountInfoData.decodeBorsh(Solana.AccountInfo.self)
        #expect(accountInfo2.mint.base58EncodedString == "QqCCvshxtqMAL2CVALqiJB7uEeE5mjSPsseQdDzsRUo")
    }
}
