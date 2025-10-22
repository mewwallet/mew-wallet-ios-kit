//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation
import mew_wallet_ios_kit
import mew_wallet_ios_kit_utils

extension Solana {
  /// A single instruction to be executed by a program during a transaction.
  ///
  /// An instruction contains:
  /// - the target `programId`,
  /// - the ordered list of account metas (`keys`) the program will read/write and/or
  ///   require signatures from, and
  /// - the program input payload (`data`), encoded per the program’s ABI.
  ///
  /// > Important:
  /// > 1. The **order** of `keys` is significant and must match the program’s expected layout.
  /// > 2. Each `AccountMeta` must accurately flag `isSigner` and `isWritable`, otherwise the
  /// >    runtime will reject the transaction or the program will fail.
  public struct TransactionInstruction: Equatable, Sendable {
    /// Ordered account metadata passed to the program.
    ///
    /// Each entry identifies a public key and whether that account:
    /// - must **sign** the transaction (`isSigner == true`), and/or
    /// - must be opened **writable** by the program (`isWritable == true`).
    ///
    /// The index position of each item is used when compiling the `Message` to produce
    /// per-instruction account indices. The same public key can appear in multiple
    /// instructions but is deduplicated at the message level.
    public let keys: [AccountMeta]
    
    /// The on-chain program that will process this instruction.
    ///
    /// This public key must correspond to a deployed program. During message compilation,
    /// it is included among the account keys and is always treated as a **readonly,
    /// non-signer** account (per Solana rules).
    public let programId: PublicKey
    
    /// Opaque input bytes consumed by `programId`.
    ///
    /// The content and encoding are program-specific. Many core programs expect little-endian
    /// scalars, short-vec lengths, or fixed-layout payloads. When using the convenience
    /// initializers in this type, values conforming to `EndianBytesEncodable` are bundled
    /// sequentially into this field in little-endian order.
    ///
    /// - Note: `nil` is treated as “no payload” and encoded as a zero-length data slice.
    public let data: Data?
    
    /// Creates an instruction with prebuilt payload bytes.
    ///
    /// - Parameters:
    ///   - keys: Ordered account metas expected by the program.
    ///   - programId: Program that will process this instruction.
    ///   - data: Program input bytes. Pass `nil` for an instruction with no payload.
    public init(keys: [AccountMeta], programId: PublicKey, data: Data? = nil) {
      self.keys = keys
      self.programId = programId
      self.data = data
    }
    
    /// Creates an instruction by concatenating multiple little-endian encodable values.
    ///
    /// Each element’s `littleEndianBytes` is appended in the order provided to form the
    /// instruction payload. This is useful for programs that define a simple, fixed layout
    /// (e.g. index/tag byte(s) followed by one or more ints).
    ///
    /// - Parameters:
    ///   - keys: Ordered account metas expected by the program.
    ///   - programId: Program that will process this instruction.
    ///   - data: Sequence of values conforming to `EndianBytesEncodable` which will be
    ///           concatenated (in order) into the payload as little-endian bytes.
    public init(keys: [AccountMeta], programId: PublicKey, data: [any EndianBytesEncodable]) {
      self.keys = keys
      self.programId = programId
      self.data = Data(data.littleEndianBytes)
    }
    
    /// Variadic convenience initializer for little-endian payload building.
    ///
    /// - Parameters:
    ///   - keys: Ordered account metas expected by the program.
    ///   - programId: Program that will process this instruction.
    ///   - data: Variadic list of `EndianBytesEncodable` values to form the payload.
    public init(keys: [AccountMeta], programId: PublicKey, data: any EndianBytesEncodable...) {
      self.init(keys: keys, programId: programId, data: data)
    }
  }
}
