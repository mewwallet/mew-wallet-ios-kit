//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 10/10/25.
//

import Foundation
import Testing
@testable import mew_wallet_ios_kit_solana
import CryptoSwift
import mew_wallet_ios_kit

@Suite("ComputeBudgetProgram tests")
fileprivate struct ComputeBudgetProgramTests {
  @Test("requestHeapFrame")
  func requestHeapFrame() async throws {
    let params = Solana.ComputeBudgetProgram.RequestHeapFrameParams(
      bytes: 33 * 1024
    )
    let ix = Solana.ComputeBudgetProgram.requestHeapFrame(
      params: params
    )
    let decodedParams = try Solana.ComputeBudgetInstruction.decodeRequestHeapFrame(instruction: ix)
    #expect(decodedParams == params)
    let type = try Solana.ComputeBudgetInstruction.decodeInstructionType(instruction: ix)
    #expect(type == .requestHeapFrame)
  }
  
  @Test("setComputeUnitLimit")
  func setComputeUnitLimit() async throws {
    let params = Solana.ComputeBudgetProgram.SetComputeUnitLimitParams(
      units: 50_000
    )
    let ix = Solana.ComputeBudgetProgram.setComputeUnitLimit(
      params: params
    )
    let decodedParams = try Solana.ComputeBudgetInstruction.decodeSetComputeUnitLimit(instruction: ix)
    #expect(decodedParams == params)
    let type = try Solana.ComputeBudgetInstruction.decodeInstructionType(instruction: ix)
    #expect(type == .setComputeUnitLimit)
  }
  
  @Test("setComputeUnitPrice")
  func setComputeUnitPrice() async throws {
    let params = Solana.ComputeBudgetProgram.SetComputeUnitPriceParams(
      microLamports: 100_000
    )
    let ix = Solana.ComputeBudgetProgram.setComputeUnitPrice(
      params: params
    )
    let decodedParams = try Solana.ComputeBudgetInstruction.decodeSetComputeUnitPrice(instruction: ix)
    #expect(decodedParams == params)
    let type = try Solana.ComputeBudgetInstruction.decodeInstructionType(instruction: ix)
    #expect(type == .setComputeUnitPrice)
  }
}
