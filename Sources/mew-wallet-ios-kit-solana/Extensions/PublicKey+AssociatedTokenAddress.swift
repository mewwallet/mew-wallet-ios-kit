//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 10/10/25.
//

import Foundation
import mew_wallet_ios_kit
import BigInt
import mew_wallet_ios_tweetnacl

extension PublicKey {
  public enum AssociatedTokenError: Swift.Error {
    case ownerOffCurve
    case noAddress
    case maxSeedLengthExceeded
    case internalError
    case invalidSeed
    case underlying(any Swift.Error)
  }
  
  public func associatedTokenAddress(
    tokenMint: PublicKey,
    allowOwnerOffCurve: Bool = false,
    tokenProgramId: PublicKey = Solana.TokenProgram.programId,
    associatedTokenProgramId: PublicKey = Solana.AssociatedTokenProgram.programId) throws(AssociatedTokenError) -> PublicKey {
    if !allowOwnerOffCurve {
      do {
        guard try TweetNacl.isOnCurve(publicKey: self.data()) else { throw AssociatedTokenError.ownerOffCurve }
      } catch let error as AssociatedTokenError {
        throw error
      } catch {
        throw .underlying(error)
      }
    }
    let seeds = [
      self.data(),
      tokenProgramId.data(),
      tokenMint.data(),
    ]
    return try Self.findProgramAddress(data: seeds, programId: associatedTokenProgramId).0
  }
  
  static func findProgramAddress(data: [Data], programId: Self) throws(AssociatedTokenError) -> (Self, UInt8) {
    var nonce: UInt8 = .max
    while nonce > 0 {
      if let address = try? createProgramAddress(seeds: data + [Data([nonce])], programId: programId) {
        return (address, nonce)
      }
      nonce &-= 1
    }
    throw .noAddress
  }
  
  static func createProgramAddress(seeds: [Data], programId: PublicKey) throws(AssociatedTokenError) -> PublicKey {
    var data = Data()
    for seed in seeds {
      guard seed.count <= 32 else { throw .maxSeedLengthExceeded }
      data.append(seed)
    }
    data.append(programId.data())
    data.append("ProgramDerivedAddress".data(using: .utf8)!)
    
    let hash = data.sha256()
    guard let publicKeyBytes = BigInt.init(hash.toHexString(), radix: 16)?.bigEndianBytes else { throw .internalError }
    let pubkey = Data(publicKeyBytes)
    
    do {
      guard try TweetNacl.isOnCurve(publicKey: pubkey) == false else {
        throw AssociatedTokenError.invalidSeed
      }
      return try PublicKey(publicKey: Data(pubkey), index: 0, network: .solana)
    } catch let error as AssociatedTokenError {
      throw error
    } catch {
      throw .underlying(error)
    }
  }
}
