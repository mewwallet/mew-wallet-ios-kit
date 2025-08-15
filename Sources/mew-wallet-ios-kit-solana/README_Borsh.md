# Borsh Encoder/Decoder for Solana

The Borsh encoder/decoder follows the same architectural pattern as the existing `ShortVecEncoder` in this codebase, providing a consistent API for Solana-specific serialization needs.

## Overview

Borsh is a binary serialization format designed for security-critical projects. It's deterministic, meaning that the same data will always be serialized to the same bytes, and it's self-describing, making it easier to work with than formats like Protocol Buffers.

## Implementation Status

✅ **AccountInfo Decoder**: Fully implemented and tested
- Successfully decodes 165-byte AccountInfo structs from Borsh binary data
- Handles optional fields correctly (delegate, closeAuthority)
- Computes derived properties (isInitialized, isFrozen, isNative, rentExemptReserve)
- Passes all golden tests

✅ **Mint Decoder**: Fully implemented and tested
- Successfully decodes SPL token mint accounts from Borsh binary data
- Handles optional fields correctly (mintAuthority, freezeAuthority)
- Passes all golden tests

✅ **TokenSwapInfo Decoder**: Fully implemented and tested
- Successfully decodes token swap program information from Borsh binary data
- Handles all required fields for token swap operations
- Passes all golden tests

## AccountInfo Struct

The `Solana.AccountInfo` struct represents a Solana account's information and can be decoded from Borsh-encoded binary data.

### Borsh Field Layout

The fields are stored in the following order with specific byte positions:

| Field | Type | Size | Position | Description |
|-------|------|------|----------|-------------|
| `mint` | PublicKey | 32 bytes | 0-31 | The mint address of the token |
| `owner` | PublicKey | 32 bytes | 32-63 | The owner of the account |
| `lamports` | UInt64 | 8 bytes | 64-71 | The number of lamports in the account |
| `delegateOption` | UInt32 | 4 bytes | 72-75 | Flag indicating if delegate is present (0 = nil, 1 = present) |
| `delegate` | PublicKey | 32 bytes | 76-107 | The delegate's public key (always present in binary, nil if delegateOption = 0) |
| `state` | UInt8 | 1 byte | 108 | Account state (0 = uninitialized, 1 = initialized, 2 = frozen) |
| `isNativeOption` | UInt32 | 4 bytes | 109-112 | Flag indicating if account is native (0 = false, 1 = true) |
| `isNativeRaw` | UInt64 | 8 bytes | 113-120 | Raw native value (rent exempt reserve if isNativeOption = 1) |
| `delegatedAmount` | UInt64 | 8 bytes | 121-128 | Amount delegated (0 if delegateOption = 0) |
| `closeAuthorityOption` | UInt32 | 4 bytes | 129-132 | Flag indicating if close authority is present (0 = nil, 1 = present) |
| `closeAuthority` | PublicKey | 32 bytes | 133-164 | The close authority's public key (always present in binary, nil if closeAuthorityOption = 0) |

**Total Buffer Length**: 165 bytes

### Computed Properties

- `isInitialized`: Returns `true` if `state != 0`
- `isFrozen`: Returns `true` if `state == 2`
- `isNative`: Returns `true` if `isNativeOption == 1`
- `rentExemptReserve`: Returns `isNativeRaw` if `isNativeOption == 1`, otherwise `nil`

### Important Notes

- All fields are always present in the binary data regardless of their "optional" status
- The `delegate` and `closeAuthority` fields consume 32 bytes each even when they represent `nil` values
- The `delegatedAmount` is automatically set to 0 when `delegateOption == 0`
- This struct follows the Solana token program's account layout specification

## Mint Struct

The `Solana.Mint` struct represents an SPL token mint account and can be decoded from Borsh-encoded binary data.

### Borsh Field Layout

| Field | Type | Size | Description |
|-------|------|------|-------------|
| `mintAuthorityOption` | UInt32 | 4 bytes | Flag indicating if mint authority is present (0 = nil, 1 = present) |
| `mintAuthority` | PublicKey | 32 bytes | The mint authority's public key (nil if mintAuthorityOption = 0) |
| `supply` | UInt64 | 8 bytes | Total supply of the token |
| `decimals` | UInt8 | 1 byte | Number of decimal places |
| `isInitialized` | Bool | 1 byte | Whether the mint is initialized |
| `freezeAuthorityOption` | UInt32 | 4 bytes | Flag indicating if freeze authority is present (0 = nil, 1 = present) |
| `freezeAuthority` | PublicKey | 32 bytes | The freeze authority's public key (nil if freezeAuthorityOption = 0) |

## TokenSwapInfo Struct

The `Solana.TokenSwapInfo` struct represents token swap program information and can be decoded from Borsh-encoded binary data.

### Borsh Field Layout

| Field | Type | Size | Description |
|-------|------|------|-------------|
| `version` | UInt8 | 1 byte | Version of the token swap |
| `isInitialized` | Bool | 1 byte | Whether the swap is initialized |
| `nonce` | UInt8 | 1 byte | Nonce for the swap |
| `tokenProgramId` | PublicKey | 32 bytes | Token program ID |
| `tokenAccountA` | PublicKey | 32 bytes | Token account A |
| `tokenAccountB` | PublicKey | 32 bytes | Token account B |
| `tokenPool` | PublicKey | 32 bytes | Token pool account |
| `mintA` | PublicKey | 32 bytes | Mint A |
| `mintB` | PublicKey | 32 bytes | Mint B |
| `feeAccount` | PublicKey | 32 bytes | Fee account |
| `tradeFeeNumerator` | UInt64 | 8 bytes | Trade fee numerator |
| `tradeFeeDenominator` | UInt64 | 8 bytes | Trade fee denominator |
| `ownerTradeFeeNumerator` | UInt64 | 8 bytes | Owner trade fee numerator |
| `ownerTradeFeeDenominator` | UInt64 | 8 bytes | Owner trade fee denominator |
| `ownerWithdrawFeeNumerator` | UInt64 | 8 bytes | Owner withdraw fee numerator |
| `ownerWithdrawFeeDenominator` | UInt64 | 8 bytes | Owner withdraw fee denominator |
| `hostFeeNumerator` | UInt64 | 8 bytes | Host fee numerator |
| `hostFeeDenominator` | UInt64 | 8 bytes | Host fee denominator |
| `curveType` | UInt8 | 1 byte | Curve type |
| `payer` | PublicKey | 32 bytes | Payer account |

## Decoding Styles

The Borsh decoder supports different decoding styles for different data structures:

- **`.accountInfo`**: For decoding `Solana.AccountInfo` structs
- **`.mint`**: For decoding `Solana.Mint` structs  
- **`.tokenSwapInfo`**: For decoding `Solana.TokenSwapInfo` structs

## Convenience Methods

The `Data` extension provides methods for decoding with specific decoding styles:

```swift
// Generic decoding (uses default style)
let accountInfo = try data.decodeBorsh(Solana.AccountInfo.self)

// Decoding with specific style
let mint = try data.decodeBorsh(Solana.Mint.self, style: .mint)
let tokenSwap = try data.decodeBorsh(Solana.TokenSwapInfo.self, style: .tokenSwapInfo)

// Using the decoder directly with custom style
let decoder = Solana.BorshDecoder()
decoder.decodingStyle = .mint
let mint = try decoder.decode(Solana.Mint.self, from: data)
```

## Usage Example

```swift
// Decode AccountInfo from base64-encoded Borsh data
let base64String = "BhrZ0FOHFUhTft4+JhhJo9+3/QL6vHWyI8jkatuFPQwCqmOzhzy1ve5l2AqL0ottCChJZ1XSIW3k3C7TaBQn7aCGAQAAAAAAAQAAAOt6vNDYdevCbaGxgaMzmz7yoxaVu3q9vGeCc7ytzeWqAQAAAAAAAAAAAAAAAGQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"

// Convert base64 string to Data and decode using Borsh
guard let data = Data(base64Encoded: base64String) else {
    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Invalid base64 string"))
}

let accountInfo = try data.decodeBorsh(Solana.AccountInfo.self)

// Access decoded properties
print("Mint: \(accountInfo.mint.base58EncodedString ?? "nil")")
print("Owner: \(accountInfo.owner.base58EncodedString ?? "nil")")
print("Lamports: \(accountInfo.lamports)")
print("Is Initialized: \(accountInfo.isInitialized)")
print("Is Frozen: \(accountInfo.isFrozen)")


```

## Architecture

The Borsh decoder follows a layered architecture:

1. **Decoder**: Core binary reading logic with position tracking
2. **KeyedContainer**: Handles struct field decoding
3. **SingleValueContainer**: Handles primitive type decoding
4. **Custom Types**: Specialized decoding for Solana types like `PublicKey`

## Testing

The implementation includes comprehensive golden tests that verify:
- Correct field positioning and byte reading
- Optional field handling
- Computed property derivation
- Multiple test cases with different data patterns

All tests pass successfully, confirming the decoder works correctly with real Solana account data.

## Future Enhancements

- Support for additional Solana structs
- Encoding capabilities (currently only decoding is implemented)
- Performance optimizations for large data sets
- Additional validation and error handling
