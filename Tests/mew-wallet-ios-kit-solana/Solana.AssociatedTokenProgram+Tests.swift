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

@Suite("AssociatedTokenProgram tests")
fileprivate struct AssociatedTokenProgramTests {
  @Test("associatedTokenAddress")
  func associatedTokenAddress() throws {
    let owner = try PublicKey(base58: "B8UwBUUnKwCyKuGMbFKWaG7exYdDk2ozZrPg72NyVbfj", network: .solana)
    let mint1 = try PublicKey(base58: "7o36UsWR1JQLpZ9PE2gn9L4SQ69CNNiWAXd4Jt7rqz9Z", network: .solana)
    
    let associatedPublicKey = try owner.associatedTokenAddress(tokenMint: mint1)
    
    let expectedAssociatedPublicKey = try PublicKey(base58: "DShWnroshVbeUp28oopA3Pu7oFPDBtC1DBmPECXXAQ9n", network: .solana)
    #expect(associatedPublicKey == expectedAssociatedPublicKey)
    
    let mint2 = try PublicKey(base58: "7o36UsWR1JQLpZ9PE2gn9L4SQ69CNNiWAXd4Jt7rqz9Z", network: .solana)
    
    #expect(throws: PublicKey.AssociatedTokenError.self, performing: {
      try associatedPublicKey.associatedTokenAddress(tokenMint: mint2)
    })
    
    let associatedPublicKeyOffCurve = try associatedPublicKey.associatedTokenAddress(tokenMint: mint2, allowOwnerOffCurve: true)
    let expectedAssociatedPublicKeyOffCurve = try PublicKey(base58: "F3DmXZFqkfEWFA7MN2vDPs813GeEWPaT6nLk4PSGuWJd", network: .solana)
    #expect(associatedPublicKeyOffCurve == expectedAssociatedPublicKeyOffCurve)
  }
}
