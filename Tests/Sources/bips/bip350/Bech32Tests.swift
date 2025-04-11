//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 3/21/25.
//

import Foundation
import Testing
@testable import mew_wallet_ios_kit

@Suite("Bech32 Tests")
struct Bech32Tests {
  struct ValidTestVector {
    let encoding: Bech32.Encoding
    let string: String
    let prefix: String
    let hex: String
    let words: [UInt8]
    let limit: Int?
    
    init(_ encoding: Bech32.Encoding, _ string: String, _ prefix: String, _ hex: String, _ words: [UInt8], _ limit: Int? = nil) {
      self.encoding = encoding
      self.string = string
      self.prefix = prefix
      self.hex = hex
      self.words = words
      self.limit = limit
    }
  }
  
  struct InvalidTestVector {
    enum Source {
      case words([UInt8])
      case string(String)
      case prefixWordsLimit(String, [UInt8], Int?)
      case hex(String)
    }
    let encoding: Bech32.Encoding
    let source: Source
    let error: Bech32.Error
    
    init(_ encoding: Bech32.Encoding, _ source: Source, _ error: Bech32.Error) {
      self.encoding = encoding
      self.source = source
      self.error = error
    }
  }

  static let valid: [ValidTestVector] = [
    .init(.bech32, "A12UEL5L", "A", "", []),
    .init(.bech32, "an83characterlonghumanreadablepartthatcontainsthenumber1andtheexcludedcharactersbio1tt5tgs", "an83characterlonghumanreadablepartthatcontainsthenumber1andtheexcludedcharactersbio", "", []),
    .init(.bech32, "abcdef1qpzry9x8gf2tvdw0s3jn54khce6mua7lmqqqxw", "abcdef", "00443214c74254b635cf84653a56d7c675be77df", [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31]),
    .init(.bech32, "11qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqc8247j", "1", "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]),
    .init(.bech32, "split1checkupstagehandshakeupstreamerranterredcaperred2y9e3w", "split", "c5f38b70305f519bf66d85fb6cf03058f3dde463ecd7918f2dc743918f2d", [24,23,25,24,22,28,1,16,11,29,8,25,23,29,19,13,16,23,29,22,25,28,1,16,11,3,25,29,27,25,3,3,29,19,11,25,3,3,25,13,24,29,1,25,3,3,25,13]),
    .init(.bech32, "11qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq978ear", "1", "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], 300),
    .init(.bech32m, "A1LQFN3A", "A", "", []),
    .init(.bech32m, "a1lqfn3a", "a", "", []),
    .init(.bech32m, "an83characterlonghumanreadablepartthatcontainsthetheexcludedcharactersbioandnumber11sg7hg6", "an83characterlonghumanreadablepartthatcontainsthetheexcludedcharactersbioandnumber1", "", []),
    .init(.bech32m, "abcdef1l7aum6echk45nj3s0wdvt2fg8x9yrzpqzd3ryx", "abcdef", "ffbbcdeb38bdab49ca307b9ac5a928398a418820", [31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0]),
    .init(.bech32m, "11llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllludsr8", "1", "", [31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31]),
    .init(.bech32m, "split1checkupstagehandshakeupstreamerranterredcaperredlc445v", "split", "c5f38b70305f519bf66d85fb6cf03058f3dde463ecd7918f2dc743918f2d", [24,23,25,24,22,28,1,16,11,29,8,25,23,29,19,13,16,23,29,22,25,28,1,16,11,3,25,29,27,25,3,3,29,19,11,25,3,3,25,13,24,29,1,25,3,3,25,13]),
    .init(.bech32m, "?1v759aa", "?", "", []),
    .init(.bech32m, "11qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqszh4cp", "1", "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], 300),
  ]

  static let invalid: [InvalidTestVector] = [
    .init(.bech32, .words([14,20,15,7,13,26,0,25,18,6,11,13,8,21,4,20,3,17,2,29,3,0]), .excessPadding),
    .init(.bech32, .words([3,1,17,17,8,15,0,20,24,20,11,6,16,1,5,29,3,4,16,3,6,21,22,26,2,13,22,9,16,21,19,24,25,21,6,18,15,8,13,24,24,24,25,9,12,1,4,16,6,9,17,1]), .nonZeroPadding),
    .init(.bech32, .string("A12Uel5l"), .mixedCaseString),
    .init(.bech32, .string("1nwldj5"), .dataTooShort),
    .init(.bech32, .string("abc1rzg"), .dataTooShort),
    .init(.bech32, .string("an84characterslonghumanreadablepartthatcontainsthenumber1andtheexcludedcharactersbio1569pvx"), .exceedsLengthLimit),
    .init(.bech32, .string("x1b4n0q5v"), .unknownCharacter("b")),
    .init(.bech32, .string("1pzry9x0s0muk"), .missingPrefix),
    .init(.bech32, .string("pzry9x0s0muk"), .noSeparator),
    .init(.bech32, .string("abc1rzgt4"), .dataTooShort),
    .init(.bech32, .string("s1vcsyn"), .dataTooShort),
    .init(.bech32, .prefixWordsLimit("abc", [128], nil), .non5BitWord),
    .init(.bech32, .prefixWordsLimit("abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzfoobarfoobar", [128], nil), .exceedsLengthLimit),
    .init(.bech32, .prefixWordsLimit("foobar", [20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20], nil), .exceedsLengthLimit),
    .init(.bech32, .prefixWordsLimit("abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzfoobarfoobarfoobarfoobar", [128], 104), .exceedsLengthLimit),
    .init(.bech32, .string("11qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqc8247j"), .exceedsLengthLimit),
    .init(.bech32, .prefixWordsLimit("abc\u{00ff}", [18], nil), .invalidPrefix),
    .init(.bech32, .string("li1dgmt3"), .dataTooShort),
    .init(.bech32, .hex("6465316c67377774c3bf"), .unknownCharacter("ÿ")),
    .init(.bech32m, .string("A1LQfN3A"), .mixedCaseString),
    .init(.bech32m, .string("1xj0phk"), .dataTooShort),
    .init(.bech32m, .string("abc1rzg"), .dataTooShort),
    .init(.bech32m, .string("an84characterslonghumanreadablepartthatcontainsthetheexcludedcharactersbioandnumber11d6pts4"), .exceedsLengthLimit),
    .init(.bech32m, .string("qyrz8wqd2c9m"), .noSeparator),
    .init(.bech32m, .string("1qyrz8wqd2c9m"), .missingPrefix),
    .init(.bech32m, .string("y1b0jsk6g"), .unknownCharacter("b")),
    .init(.bech32m, .string("lt1igcx5c0"), .unknownCharacter("i")),
    .init(.bech32m, .string("in1muywd"), .dataTooShort),
    .init(.bech32m, .string("mm1crxm3i"), .unknownCharacter("i")),
    .init(.bech32m, .string("au1s5cgom"), .unknownCharacter("o")),
    .init(.bech32m, .string("M1VUXWEZ"), .invalidChecksum),
    .init(.bech32m, .string("16plkw9"), .dataTooShort),
    .init(.bech32m, .string("1p2gdwpf"), .missingPrefix),
    .init(.bech32m, .prefixWordsLimit("abc", [128], nil), .non5BitWord),
    .init(.bech32m, .prefixWordsLimit("abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzfoobarfoobar", [128], nil), .exceedsLengthLimit),
    .init(.bech32m, .prefixWordsLimit("foobar", [20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20], nil), .exceedsLengthLimit),
    .init(.bech32m, .prefixWordsLimit("abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzfoobarfoobarfoobarfoobar", [128], 104), .exceedsLengthLimit),
    .init(.bech32m, .string("11qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqc8247j"), .exceedsLengthLimit),
    .init(.bech32m, .prefixWordsLimit("abc\u{00ff}", [18], nil), .invalidPrefix),
    .init(.bech32m, .string("in1muywd"), .dataTooShort),
    .init(.bech32m, .hex("6465316c67377774c3bf"), .unknownCharacter("ÿ")),
  ]

  @Test("Test Bech32 valid cases", arguments: Bech32Tests.valid)
  func valid(vector: ValidTestVector) async throws {
    let bech32 = Bech32(encoding: vector.encoding)
    
    if !vector.hex.isEmpty {
      let words = try bech32.toWords(bytes: Data(hex: vector.hex).bytes)
      let bytes = try bech32.fromWords(words: vector.words)
      
      #expect(words == vector.words)
      #expect(bytes.toHexString() == vector.hex)
    }
    
    let encoded = try bech32.encode(prefix: vector.prefix, words: vector.words, limit: vector.limit)
    #expect(encoded == vector.string.lowercased())
    
    let decoded = try bech32.decode(vector.string, limit: vector.limit)
    #expect(vector.prefix.lowercased() == decoded.prefix)
    #expect(vector.words == decoded.words)
    
    if let index = vector.string.firstIndex(of: "1") {
      let offset = vector.string.distance(from: vector.string.startIndex, to: index) + 1
      if offset < vector.string.count {
        var data = vector.string.bytes
        
        data[offset] ^= 0x1
        
        if let modified = String(bytes: data, encoding: .utf8) {
          #expect(throws: Bech32.Error.self, performing: {
            try bech32.decode(modified, limit: vector.limit)
          })
        }
      }
    }
    
    let invalidBech = Bech32(encoding: vector.encoding == .bech32 ? .bech32m : .bech32)
    #expect(throws: Bech32.Error.invalidChecksum, performing: {
      try invalidBech.decode(vector.string, limit: vector.limit)
    })
  }
  
  @Test("Test Bech32 invalid cases", arguments: Bech32Tests.invalid)
  func invalid(vector: InvalidTestVector) async throws {
    let bech = Bech32(encoding: vector.encoding)
    switch vector.source {
    case .words(let words):
      #expect(throws: vector.error, performing: {
        try bech.fromWords(words: words)
      })
    case .string(let string):
      #expect(throws: vector.error, performing: {
        try bech.decode(string)
      })
    case .prefixWordsLimit(let prefix, let words, let limit):
      #expect(throws: vector.error, performing: {
        try bech.encode(prefix: prefix, words: words, limit: limit)
      })
    case .hex(let hex):
      #expect(throws: vector.error, performing: {
        let string = try #require(String(data: Data(hex: hex), encoding: .utf8))
        return try bech.decode(string)
      })
    }
  }
  
  @Test("Test Bech32 to words")
  func toWords() async throws {
    let bech = Bech32(encoding: .bech32)
    let words = try bech.toWords(bytes: [0x00, 0x11, 0x22, 0x33, 0xff])
    #expect(words == [0, 0, 8, 18, 4, 12, 31, 31])
  }
}
