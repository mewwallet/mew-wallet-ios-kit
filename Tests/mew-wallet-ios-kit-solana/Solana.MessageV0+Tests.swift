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

@Suite("MessageV0 tests")
fileprivate struct SolanaMessageV0Tests {
  private func createTestKeys(count: Int) -> [PublicKey] {
    var keys = [PublicKey]()
    keys.reserveCapacity(count)
    
    for _ in 0..<count {
      try! keys.append(.unique())
    }
    return keys
  }
  
  
  private func createTestLookupTable(addresses: [PublicKey]) throws -> Solana.AddressLookupTableAccount {
    return try Solana.AddressLookupTableAccount(
      key: .unique(),
      state: .init(
        deactivationSlot: .max,
        lastExtendedSlot: 0,
        lastExtendedSlotStartIndex: 0,
        authority: .unique(),
        addresses: addresses
      )
    )
  }
  
  @Test("numAccountKeysFromLookups")
  func numAccountKeysFromLookups() async throws {
    var message = try Solana.MessageV0(
      payerKey: .unique(),
      instructions: [],
      recentBlockhash: ""
    )
    #expect(message.numAccountKeysFromLookups == 0)
    message.addressTableLookups = try [
      .init(
        accountKey: .unique(),
        writableIndexes: [0],
        readonlyIndexes: [1]
      ),
      .init(
        accountKey: .unique(),
        writableIndexes: [0, 2],
        readonlyIndexes: []
      )
    ]
    #expect(message.numAccountKeysFromLookups == 4)
  }
  
  @Test("getAccountKeys")
  func getAccountKeys() async throws {
    let staticAccountKeys = createTestKeys(count: 3)
    let lookupTable = try createTestLookupTable(addresses: createTestKeys(count: 2));
    
    let message = Solana.MessageV0(
      header: .init(
        numRequiredSignatures: 1,
        numReadonlySignedAccounts: 0,
        numReadonlyUnsignedAccounts: 0
      ),
      staticAccountKeys: staticAccountKeys,
      recentBlockhash: "test",
      compiledInstructions: [],
      addressTableLookups: [
        .init(
          accountKey: lookupTable.key,
          writableIndexes: [0],
          readonlyIndexes: [1]
        )
      ]
    )
    
    #expect(throws: Solana.MessageV0.Error.accountKeysAddressTableLookupsWereNotResolved, performing: {
      try message.getAccountKeys()
    })
    #expect(throws: Solana.MessageV0.Error.mismatchInNumberOfAccountKeysFromLookups, performing: {
      try message.getAccountKeys(
        accountKeysFromLookups: .init(
          writable: [PublicKey.unique()],
          readonly: []
        )
      )
    })
    let accountKeysFromLookups = try message.resolveAddressTableLookups(
      addressLookupTableAccounts: [lookupTable]
    )
    let expectedAccountKeys = Solana.MessageAccountKeys(
      staticAccountKeys: staticAccountKeys,
      accountKeysFromLookups: accountKeysFromLookups
    )
    try #expect(message.getAccountKeys(accountKeysFromLookups: accountKeysFromLookups) == expectedAccountKeys)
    try #expect(message.getAccountKeys(addressLookupTableAccounts: [lookupTable]) == expectedAccountKeys)
  }
  
  @Test("resolveAddressTableLookups")
  func resolveAddressTableLookups() async throws {
    let keys = createTestKeys(count: 7)
    let lookupTable = try createTestLookupTable(addresses: keys)
    let createTestMessage: ([Solana.MessageAddressTableLookup]) -> Solana.MessageV0 = { table in
      return Solana.MessageV0(
        header: .init(
          numRequiredSignatures: 1,
          numReadonlySignedAccounts: 0,
          numReadonlyUnsignedAccounts: 0
        ),
        staticAccountKeys: [],
        recentBlockhash: "test",
        compiledInstructions: [],
        addressTableLookups: table
      )
    }
    try #expect(createTestMessage([]).resolveAddressTableLookups(addressLookupTableAccounts: [lookupTable]) == .init(
      writable: [],
      readonly: []
    ))
    
    let key = try PublicKey.unique()
    #expect(throws: Solana.MessageV0.Error.missingTableKey(key), performing: {
      try createTestMessage([
        .init(
          accountKey: key,
          writableIndexes: [1, 3, 5],
          readonlyIndexes: [0, 2, 4]
        )
      ]).resolveAddressTableLookups(addressLookupTableAccounts: [lookupTable])
    })
    
    #expect(throws: Solana.MessageV0.Error.missingAddress(index: 10, key: lookupTable.key), performing: {
      try createTestMessage([
        .init(
          accountKey: lookupTable.key,
          writableIndexes: [10],
          readonlyIndexes: []
        )
      ]).resolveAddressTableLookups(addressLookupTableAccounts: [lookupTable])
    })
    
    try #expect(createTestMessage(
      [
        .init(
          accountKey: lookupTable.key,
          writableIndexes: [1, 3, 5],
          readonlyIndexes: [0, 2, 4]
        )
      ]
    ).resolveAddressTableLookups(addressLookupTableAccounts: [lookupTable]) == .init(
      writable: [keys[1], keys[3], keys[5]],
      readonly: [keys[0], keys[2], keys[4]]
    ))
  }
  
  @Test("compile")
  func compile() async throws {
    let keys = createTestKeys(count: 7)
    let recentBlockhash: String = try "test".data(using: .utf8)!.sha256().encodeBase58(.solana)
    let payerKey = keys[0]
    let instructions: [Solana.TransactionInstruction] = [
      .init(
        keys: [
          .init(pubkey: keys[1], isSigner: true, isWritable: true),
          .init(pubkey: keys[2], isSigner: false, isWritable: false),
          .init(pubkey: keys[3], isSigner: false, isWritable: false),
        ],
        programId: keys[4],
        data: Data(hex: "0x00")
      ),
      .init(
        keys: [
          .init(pubkey: keys[2], isSigner: true, isWritable: false),
          .init(pubkey: keys[3], isSigner: false, isWritable: true),
        ],
        programId: keys[1],
        data: Data(hex: "0x0000")
      ),
      .init(
        keys: [
          .init(pubkey: keys[5], isSigner: false, isWritable: true),
          .init(pubkey: keys[6], isSigner: false, isWritable: false),
        ],
        programId: keys[3],
        data: Data(hex: "0x000000")
      )
    ]
    let lookupTable = try createTestLookupTable(addresses: keys)
    let message = try Solana.MessageV0(
      payerKey: payerKey,
      instructions: instructions,
      recentBlockhash: recentBlockhash,
      addressLookupTableAccounts: [lookupTable]
    )
    
    #expect(message.staticAccountKeys == [
      payerKey, // payer is first
      keys[1], // other writable signer
      keys[2], // sole readonly signer
      keys[3], // sole writable non-signer
      keys[4], // sole readonly non-signer
    ])
    
    #expect(message.header == .init(
      numRequiredSignatures: 3,
      numReadonlySignedAccounts: 1,
      numReadonlyUnsignedAccounts: 1,
    ))
    
    // only keys 5 and 6 are eligible to be referenced by a lookup table
    // because they are not invoked and are not signers
    #expect(message.addressTableLookups == [
      .init(
        accountKey: lookupTable.key,
        writableIndexes: [5],
        readonlyIndexes: [6],
      )
    ])
    
    #expect(message.compiledInstructions == [
      .init(
        programIdIndex: 4,
        accountKeyIndexes: [1, 2, 3],
        data: Data(hex: "0x00")
      ),
      .init(
        programIdIndex: 1,
        accountKeyIndexes: [2, 3],
        data: Data(hex: "0x0000")
      ),
      .init(
        programIdIndex: 3,
        accountKeyIndexes: [5, 6],
        data: Data(hex: "0x000000")
      )
    ])
    
    #expect(message.recentBlockhash == recentBlockhash)
  }
  
  @Test("serialize and deserialize")
  func serializeAndDeserialize() async throws {
    let messageV0 = try Solana.MessageV0(
      header: .init(
        numRequiredSignatures: 1,
        numReadonlySignedAccounts: 0,
        numReadonlyUnsignedAccounts: 1
      ),
      staticAccountKeys: [
        PublicKey(hex: "0x01", network: .solana),
        PublicKey(hex: "0x02", network: .solana)
      ],
      recentBlockhash: PublicKey(hex: "0x00", network: .solana).address()!.address,
      compiledInstructions: [
        .init(
          programIdIndex: 1,
          accountKeyIndexes: [2, 3],
          data: Data(hex: "0x00000000000000000000")
          )
      ],
      addressTableLookups: [
        .init(
          accountKey: PublicKey(hex: "0x03", network: .solana),
          writableIndexes: [1],
          readonlyIndexes: []
        ),
        .init(
          accountKey: PublicKey(hex: "0x04", network: .solana),
          writableIndexes: [],
          readonlyIndexes: [2]
        )
      ]
    )
    
    let encoder = Solana.ShortVecEncoder()
    let serializedMessage = try encoder.encode(messageV0)
    
    #expect(serializedMessage.toHexString() == "800100010200000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000001010202030a000000000000000000000200000000000000000000000000000000000000000000000000000000000000030101000000000000000000000000000000000000000000000000000000000000000004000102")
    
    let decoder = Solana.ShortVecDecoder()
    decoder.decodingStyle = .messageV0
    let deserializedMessage = try decoder.decode(Solana.MessageV0.self, from: serializedMessage)
    
    #expect(messageV0 == deserializedMessage)
  }
  
  @Test("deserialize failures")
  func deserializeFailures() async throws {
    var data = Data([0x01])
    let decoder = Solana.ShortVecDecoder()
    decoder.decodingStyle = .messageV0
    
    #expect(throws: DecodingError.self, performing: {
      try decoder.decode(Solana.MessageV0.self, from: data)
    })
    
    data = Data([0x81])
    #expect(throws: DecodingError.self, performing: {
      try decoder.decode(Solana.MessageV0.self, from: data)
    })
  }
  
  @Test("isAccountWritable")
  func isAccountWritable() async throws {
    let staticAccountKeys = self.createTestKeys(count: 4)
    let recentBlockhash: String = try "test".data(using: .utf8)!.sha256().encodeBase58(.solana)
    
    let message = try Solana.MessageV0(
      header: .init(
        numRequiredSignatures: 2,
        numReadonlySignedAccounts: 1,
        numReadonlyUnsignedAccounts: 1
      ),
      staticAccountKeys: staticAccountKeys,
      recentBlockhash: recentBlockhash,
      compiledInstructions: [],
      addressTableLookups: [
        .init(
          accountKey: .unique(),
          writableIndexes: [0],
          readonlyIndexes: [1]
        ),
        .init(
          accountKey: .unique(),
          writableIndexes: [0],
          readonlyIndexes: [1]
        ),
      ]
    )
    #expect(message.isAccountWritable(index: 0) == true)
    #expect(message.isAccountWritable(index: 1) == false)
    #expect(message.isAccountWritable(index: 2) == true)
    #expect(message.isAccountWritable(index: 3) == false)
    
    #expect(message.isAccountWritable(index: 4) == true)
    #expect(message.isAccountWritable(index: 5) == true)
    
    #expect(message.isAccountWritable(index: 6) == false)
    #expect(message.isAccountWritable(index: 7) == false)
  }
  
  @Test("isAccountSigner")
  func isAccountSigner() async throws {
    let staticAccountKeys = self.createTestKeys(count: 4)
    let recentBlockhash: String = try "test".data(using: .utf8)!.sha256().encodeBase58(.solana)
    
    let message = try Solana.MessageV0(
      header: .init(
        numRequiredSignatures: 2,
        numReadonlySignedAccounts: 1,
        numReadonlyUnsignedAccounts: 1
      ),
      staticAccountKeys: staticAccountKeys,
      recentBlockhash: recentBlockhash,
      compiledInstructions: [],
      addressTableLookups: [
        .init(
          accountKey: .unique(),
          writableIndexes: [0],
          readonlyIndexes: [1]
        ),
        .init(
          accountKey: .unique(),
          writableIndexes: [0],
          readonlyIndexes: [1]
        ),
      ]
    )
    #expect(message.isAccountSigner(index: 0) == true)
    #expect(message.isAccountSigner(index: 1) == true)
    #expect(message.isAccountSigner(index: 2) == false)
    #expect(message.isAccountSigner(index: 3) == false)
    
    #expect(message.isAccountSigner(index: 4) == false)
    #expect(message.isAccountSigner(index: 5) == false)
    
    #expect(message.isAccountSigner(index: 6) == false)
    #expect(message.isAccountSigner(index: 7) == false)
  }
}
