//
//  AccountInfo.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit

/// удалить
public protocol BufferLayout: Codable {
    static var BUFFER_LENGTH: UInt64 { get }
}

/**
 * Solana AccountInfo struct that conforms to BufferLayout protocol.
 * 
 * This struct represents a Solana account's information and can be decoded from Borsh-encoded binary data.
 * The total buffer length is 165 bytes.
 * 
 * ## Borsh Field Layout
 * 
 * The fields are stored in the following order with specific byte positions:
 * 
 * | Field | Type | Size | Position | Description |
 * |-------|------|------|----------|-------------|
 * | `mint` | PublicKey | 32 bytes | 0-31 | The mint address of the token |
 * | `owner` | PublicKey | 32 bytes | 32-63 | The owner of the account |
 * | `lamports` | UInt64 | 8 bytes | 64-71 | The number of lamports in the account |
 * | `delegateOption` | UInt32 | 4 bytes | 72-75 | Flag indicating if delegate is present (0 = nil, 1 = present) |
 * | `delegate` | PublicKey | 32 bytes | 76-107 | The delegate's public key (always present in binary, nil if delegateOption = 0) |
 * | `state` | UInt8 | 1 byte | 108 | Account state (0 = uninitialized, 1 = initialized, 2 = frozen) |
 * | `isNativeOption` | UInt32 | 4 bytes | 109-112 | Flag indicating if account is native (0 = false, 1 = true) |
 * | `isNativeRaw` | UInt64 | 8 bytes | 113-120 | Raw native value (rent exempt reserve if isNativeOption = 1) |
 * | `delegatedAmount` | UInt64 | 8 bytes | 121-128 | Amount delegated (0 if delegateOption = 0) |
 * | `closeAuthorityOption` | UInt32 | 4 bytes | 129-132 | Flag indicating if close authority is present (0 = nil, 1 = present) |
 * | `closeAuthority` | PublicKey | 32 bytes | 133-164 | The close authority's public key (always present in binary, nil if closeAuthorityOption = 0) |
 * 
 * ## Computed Properties
 * 
 * - `isInitialized`: Returns `true` if `state != 0`
 * - `isFrozen`: Returns `true` if `state == 2`
 * - `isNative`: Returns `true` if `isNativeOption == 1`
 * - `rentExemptReserve`: Returns `isNativeRaw` if `isNativeOption == 1`, otherwise `nil`
 * 
 * ## Important Notes
 * 
 * - All fields are always present in the binary data regardless of their "optional" status
 * - The `delegate` and `closeAuthority` fields consume 32 bytes each even when they represent `nil` values
 * - The `delegatedAmount` is automatically set to 0 when `delegateOption == 0`
 * - This struct follows the Solana token program's account layout specification
 */
extension Solana {
    public struct AccountInfo: BufferLayout, Decodable {
        /// The total size of the AccountInfo struct in bytes when encoded in Borsh format.
        /// This matches the sum of all field sizes: 32+32+8+4+32+1+4+8+8+4+32 = 165 bytes

        /// dont support
        public static let BUFFER_LENGTH: UInt64 = 165

        // Fields in correct Borsh binary order
        public let mint: PublicKey           // 32 bytes
        public let owner: PublicKey          // 32 bytes
        public let lamports: UInt64          // 8 bytes
        public let delegateOption: UInt32    // 4 bytes - option flag for delegate
        public var delegate: PublicKey?      // 32 bytes (optional, only if delegateOption != 0)
        public let state: UInt8              // 1 byte - derived: isInitialized = state != 0, isFrozen = state == 2
        public let isNativeOption: UInt32    // 4 bytes - option flag for rentExemptReserve
        public let isNativeRaw: UInt64       // 8 bytes - used for rentExemptReserve when isNativeOption == 1
        public var delegatedAmount: UInt64   // 8 bytes - only set when delegateOption != 0
        public let closeAuthorityOption: UInt32 // 4 bytes - option flag for closeAuthority
        public var closeAuthority: PublicKey? // 32 bytes (optional, only if closeAuthorityOption != 0)
        
        // Computed properties
        public var isInitialized: Bool { state != 0 }
        public var isFrozen: Bool { state == 2 }
        public var isNative: Bool { isNativeOption == 1 }
        public var rentExemptReserve: UInt64? { 
            isNativeOption == 1 ? isNativeRaw : nil 
        }
        
        public init(
            mint: PublicKey,
            owner: PublicKey,
            lamports: UInt64,
            delegateOption: UInt32,
            delegate: PublicKey?,
            state: UInt8,
            isNativeOption: UInt32,
            isNativeRaw: UInt64,
            delegatedAmount: UInt64,
            closeAuthorityOption: UInt32,
            closeAuthority: PublicKey?
        ) {
            self.mint = mint
            self.owner = owner
            self.lamports = lamports
            self.delegateOption = delegateOption
            self.delegate = delegate
            self.state = state
            self.isNativeOption = isNativeOption
            self.isNativeRaw = isNativeRaw
            self.delegatedAmount = delegatedAmount
            self.closeAuthorityOption = closeAuthorityOption
            self.closeAuthority = closeAuthority
        }
        
        /**
         * Custom Decodable implementation for AccountInfo.
         * 
         * This implementation handles the specific Borsh binary layout where:
         * - All fields are always present in the binary data (165 bytes total)
         * - Optional fields like `delegate` and `closeAuthority` consume their full 32-byte space
         * - The `delegateOption` and `closeAuthorityOption` flags determine if these fields are nil
         * - Computed properties are derived from the raw binary values
         * 
         * The decoding follows the exact byte positions specified in the struct documentation.
         */
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // Decode fields in the order they appear in the binary data
            mint = try container.decode(PublicKey.self, forKey: .mint)
            owner = try container.decode(PublicKey.self, forKey: .owner)
            lamports = try container.decode(UInt64.self, forKey: .lamports)
            delegateOption = try container.decode(UInt32.self, forKey: .delegateOption)
            
            // Always read delegate field (32 bytes) regardless of option
            let delegateKey = try container.decode(PublicKey.self, forKey: .delegate)
            
            if delegateOption == 0 {
                delegate = nil
            } else {
                delegate = delegateKey
            }
            
            state = try container.decode(UInt8.self, forKey: .state)
            isNativeOption = try container.decode(UInt32.self, forKey: .isNativeOption)
            isNativeRaw = try container.decode(UInt64.self, forKey: .isNativeRaw)
            delegatedAmount = try container.decode(UInt64.self, forKey: .delegatedAmount)
            closeAuthorityOption = try container.decode(UInt32.self, forKey: .closeAuthorityOption)
            
            // Always read closeAuthority field (32 bytes) regardless of option
            let closeAuthorityKey = try container.decode(PublicKey.self, forKey: .closeAuthority)
            
            if closeAuthorityOption == 0 {
                closeAuthority = nil
            } else {
                closeAuthority = closeAuthorityKey
            }
            
            // Set computed properties
            if delegateOption == 0 {
                delegatedAmount = 0
            }
        }
        
        private enum CodingKeys: String, CodingKey {
            case mint, owner, lamports, delegateOption, delegate, state, isNativeOption, isNativeRaw, delegatedAmount, closeAuthorityOption, closeAuthority
        }
    }
}

// delete
public struct Buffer<T: BufferLayout>: Codable {
    public let value: T?

    public init(value: T?) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // decode parsedJSON
        if let parsedData = try? container.decode(T.self) {
            value = parsedData
            return
        }

        // Try to decode as array first (format: ["base64string", "base64"])
        if let array = try? container.decode([String].self), array.count >= 1 {
            let base64String = array[0]
            guard let data = Data(base64Encoded: base64String),
                  data.count >= T.BUFFER_LENGTH else {
                value = nil
                return
            }
            // Use the existing Borsh decoder
            value = try? data.decodeBorsh(T.self)
            return
        }

        // Try to decode as single string
        if let string = try? container.decode(String.self),
           let data = Data(base64Encoded: string),
           data.count >= T.BUFFER_LENGTH {
            // Use the existing Borsh decoder
            value = try? data.decodeBorsh(T.self)
            return
        }

        value = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let value = value {
            try container.encode(value)
        } else {
            try container.encodeNil()
        }
    }
}

// MARK: - PublicKey Extension for Solana

extension PublicKey {
    public var base58EncodedString: String? {
        guard self.network == .solana else {
            return nil
        }
        return self.address()?.address
    }
}
