//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 10/10/25.
//

import Foundation
import mew_wallet_ios_kit
import mew_wallet_ios_kit_utils

extension Solana {
  /// Factory class for transaction instructions to interact with the Token program
  public struct TokenProgram {
    public enum Index: UInt8, EndianBytesEncodable, EndianBytesDecodable, Sendable {
      case transfer                 = 3
    }
    
    /// Public key that identifies the Token program
    public static let programId: PublicKey = try! .init(base58: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA", network: .solana)
    
    /**
     Buffer layout for de/serializing a token account
     
     Bytes count:
     
     ```
     export const AccountLayout = struct<RawAccount>([
        publicKey('mint'),            // 32
        publicKey('owner'),           // 32
        u64('amount'),                // 8
        u32('delegateOption'),        // 4
        publicKey('delegate'),        // 32
        u8('state'),                  // 1
        u32('isNativeOption'),        // 4
        u64('isNative'),              // 8
        u64('delegatedAmount'),       // 8
        u32('closeAuthorityOption'),  // 4
        publicKey('closeAuthority'),  // 32
     ]);
     ```
     */
    public static let accountSize: Int = 165
    
    /**
     * Generate a transaction instruction that transfers tokens from one account to another
     */
    public static func transfer(params: Solana.TokenProgram.TransferParams) -> TransactionInstruction {
      var keys: [Solana.AccountMeta] = []
      keys.reserveCapacity(3 + params.multiSigners.count)
      keys.append(.init(pubkey: params.source, isSigner: false, isWritable: true))
      keys.append(.init(pubkey: params.destination, isSigner: false, isWritable: true))
      keys.append(.init(pubkey: params.owner, isSigner: params.multiSigners.isEmpty, isWritable: false))
      keys.append(contentsOf: params.multiSigners.map({
        .init(pubkey: $0, isSigner: true, isWritable: false)
      }))
      
      return TransactionInstruction(
        keys: keys,
        programId: params.programId,
        data: Index.transfer, params.amount
      )
    }
  }
}
