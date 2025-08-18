//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/13/25.
//

import Foundation
import Testing
@testable import mew_wallet_ios_kit_solana
import CryptoSwift
import mew_wallet_ios_kit

@Suite("SystemProgram tests")
fileprivate struct SystemProgramTests {
  //  private func createTestKeys(count: Int) -> [PublicKey] {
  //    var keys = [PublicKey]()
  //    keys.reserveCapacity(count)
  //
  //    for _ in 0..<count {
  //      try! keys.append(.unique())
  //    }
  //    return keys
  //  }
  //
  //
  //  private func createTestLookupTable(addresses: [PublicKey]) throws -> Solana.AddressLookupTableAccount {
  //    return try Solana.AddressLookupTableAccount(
  //      key: .unique(),
  //      state: .init(
  //        deactivationSlot: .max,
  //        lastExtendedSlot: 0,
  //        lastExtendedSlotStartIndex: 0,
  //        authority: .unique(),
  //        addresses: addresses
  //      )
  //    )
  //  }
  //
//  @Test("createAccount")
//  func createAccount() async throws {
//    let transaction = Solana.Transaction()
//      .adding(transaction: <#T##Solana.Transaction#>)
//    
//    Solana.SystemProgram.cre
//  }
//  
//  it('', () => {
//      const params = {
//        fromPubkey: Keypair.generate().publicKey,
//        newAccountPubkey: Keypair.generate().publicKey,
//        lamports: 123,
//        space: 0,
//        programId: SystemProgram.programId,
//      };
//      const transaction = new Transaction().add(
//        SystemProgram.createAccount(params),
//      );
//      expect(transaction.instructions).to.have.length(1);
//      const [systemInstruction] = transaction.instructions;
//      expect(params).to.eql(
//        SystemInstruction.decodeCreateAccount(systemInstruction),
//      );
//    });
  
//  @Test("transfer")
//  func transfer() async throws {
//    let params: Solana.SystemProgram.TransferParams = try .init(
//      fromPubkey: .unique(),
//      toPubkey: .unique(),
//      lamports: 123
//    )
//    let transaction = try Solana.Transaction()
//      .adding(instructions: [
//        Solana.SystemProgram.transfer(params: params)
//      ])
//    #expect(transaction.instructions.count == 1)
//    
//    let systemInstruction = transaction.instructions
//    Solana.SystemIns
//    
//    
//  }
//  
//  it('', () => {
//      const params = {
//        fromPubkey: Keypair.generate().publicKey,
//        toPubkey: Keypair.generate().publicKey,
//        lamports: 123,
//      };
//      const transaction = new Transaction().add(SystemProgram.transfer(params));
//      expect(transaction.instructions).to.have.length(1);
//      const [systemInstruction] = transaction.instructions;
//      const decodedParams = {
//        ...params,
//        lamports: BigInt(params.lamports),
//      };
//      expect(decodedParams).to.eql(
//        SystemInstruction.decodeTransfer(systemInstruction),
//      );
//    });
}
