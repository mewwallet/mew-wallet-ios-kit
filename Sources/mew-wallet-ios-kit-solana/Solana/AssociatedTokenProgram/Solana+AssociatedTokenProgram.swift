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
  /// Factory class for transaction instructions to interact with the Associated Token program
  public struct AssociatedTokenProgram {
    public enum Index: UInt8, EndianBytesEncodable, EndianBytesDecodable, Sendable {
      case requestHeapFrame         = 1
      case setComputeUnitLimit      = 2
      case setComputeUnitPrice      = 3
    }

    /// Public key that identifies the Associated Token program
    public static let programId: PublicKey = try! .init(base58: "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL", network: .solana)
    
    public static func createAssociatedTokenAccount(params: Solana.AssociatedTokenProgram.CreateAssociatedTokenAccountParams) throws -> TransactionInstruction {
      return try TransactionInstruction(
        keys: [
          .init(pubkey: params.payer, isSigner: true, isWritable: true),
          .init(pubkey: params.owner.associatedTokenAddress(
            tokenMint: params.mint,
            tokenProgramId: params.programId
          ), isSigner: false, isWritable: true),
          .init(pubkey: params.owner, isSigner: false, isWritable: false),
          .init(pubkey: params.mint, isSigner: false, isWritable: false),
          .init(pubkey: SystemProgram.programId, isSigner: false, isWritable: false),
          .init(pubkey: params.programId, isSigner: false, isWritable: false)//,
//          .init(pubkey: SysVar.rent, isSigner: false, isWritable: false),
        ],
        programId: Self.programId,
        data: []
      )
    }
  }
}
