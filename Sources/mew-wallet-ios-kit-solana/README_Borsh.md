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

## Usage Example

```swift
// Decode AccountInfo from base64-encoded Borsh data
let base64String = "BhrZ0FOHFUhTft4+JhhJo9+3/QL6vHWyI8jkatuFPQwCqmOzhzy1ve5l2AqL0ottCChJZ1XSIW3k3C7TaBQn7aCGAQAAAAAAAQAAAOt6vNDYdevCbaGxgaMzmz7yoxaVu3q9vGeCc7ytzeWqAQAAAAAAAAAAAAAAAGQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
let jsonString = #"["\(base64String)","base64"]"#

let accountInfo = try! JSONDecoder().decode(Buffer<Solana.AccountInfo>.self, from: jsonString.data(using: .utf8)!).value

// Access decoded properties
print("Mint: \(accountInfo?.mint.base58EncodedString ?? "nil")")
print("Owner: \(accountInfo?.owner.base58EncodedString ?? "nil")")
print("Lamports: \(accountInfo?.lamports ?? 0)")
print("Is Initialized: \(accountInfo?.isInitialized ?? false)")
print("Is Frozen: \(accountInfo?.isFrozen ?? false)")
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
