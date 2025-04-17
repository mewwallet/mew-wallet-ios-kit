//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 3/21/25.
//

import Foundation

/// A structure for Bech32 encoding and decoding.
public struct Bech32: Sendable {
  // MARK: - Encoding Type
  
  /// Supported encoding types for Bech32
  public enum Encoding: Sendable {
    case bech32
    case bech32m
    
    /// Constant used in checksum calculation depending on the encoding.
    fileprivate var const: UInt32 {
      switch self {
      case .bech32:   return 1
      case .bech32m:  return 0x2bc830a3
      }
    }
  }
  
  // MARK: - Error Definitions
  
  /// Possible errors that can occur during encoding/decoding.
  public enum Error: Swift.Error, Equatable {
    case exceedsLengthLimit
    case non5BitWord
    case dataTooShort
    case mixedCaseString
    case noSeparator
    case missingPrefix
    case unknownCharacter(Character)
    case invalidChecksum
    case excessPadding
    case nonZeroPadding
    case invalidPrefix
    
    /// Provides a human-readable description for each error.
    var description: String {
      switch self {
      case .exceedsLengthLimit:
        return "Exceeds length limit"
      case .non5BitWord:
        return "Non 5-bit word"
      case .dataTooShort:
        return "Data too short"
      case .mixedCaseString:
        return "Mixed-case string"
      case .noSeparator:
        return "No separator character"
      case .missingPrefix:
        return "Prefix is missing"
      case .unknownCharacter(let c):
        return "Unknown character \(c)"
      case .invalidChecksum:
        return "Invalid checksum"
      case .excessPadding:
        return "Excess padding"
      case .nonZeroPadding:
        return "Non-zero padding"
      case .invalidPrefix:
        return "Invalid prefix"
      }
    }
  }
  
  // MARK: - Properties
  
  /// The Bech32 alphabet used for encoding.
  private let alphabet: String = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"
  
  /// Dictionary mapping each character in the alphabet to its corresponding 5-bit value.
  private let charset: [Character: UInt8]
  
  /// Selected encoding type.
  private let encoding: Bech32.Encoding
  
  // MARK: - Initializer
  
  /// Initializes a Bech32 instance with the specified encoding type.
  /// - Parameter encoding: The encoding type (default is `.bech32`).
  public init(encoding: Bech32.Encoding = Bech32.Encoding.bech32) {
    self.charset = self.alphabet.enumerated().reduce([Character: UInt8]()) { partialResult, element in
      var partialResult = partialResult
      partialResult[element.element] = UInt8(element.offset)
      return partialResult
    }
    self.encoding = encoding
  }
  
  // MARK: - Public
  
  /// Converts a Data object into an array of 5-bit words (packed as Data).
  ///
  /// - Parameter data: The input Data.
  /// - Throws: Any conversion-related errors.
  /// - Returns: A Data object containing the 5-bit words.
  public func toWords(data: Data) throws(Bech32.Error) -> Data {
    let bytes = try toWords(bytes: data.bytes)
    return Data(bytes)
  }
  
  /// Converts a Data object into an array of 5-bit words.
  ///
  /// - Parameter data: The input Data.
  /// - Throws: Any conversion-related errors.
  /// - Returns: An array of UInt8 representing 5-bit words.
  public func toWords(data: Data) throws(Bech32.Error) -> [UInt8] {
    try toWords(bytes: data.bytes)
  }
  
  /// Converts an array of 8-bit bytes to an array of 5-bit words.
  ///
  /// - Parameter bytes: The input array of UInt8.
  /// - Throws: Any conversion-related errors.
  /// - Returns: An array of UInt8 representing the 5-bit words.
  public func toWords(bytes: [UInt8]) throws(Bech32.Error) -> [UInt8] {
    try convert(data: bytes, inBits: 8, outBits: 5, pad: true)
  }
  
  /// Converts an array of 5-bit words back into 8-bit bytes.
  ///
  /// - Parameter words: The input array of 5-bit words.
  /// - Throws: Any conversion-related errors.
  /// - Returns: An array of UInt8 representing the original 8-bit bytes.
  public func fromWords(words: [UInt8]) throws -> [UInt8] {
    return try convert(data: words, inBits: 5, outBits: 8, pad: false)
  }
  
  // MARK: - Encoding & Decoding Methods
  
  /// Encodes a prefix and 5-bit words into a Bech32 string.
  ///
  /// - Parameters:
  ///   - prefix: The human-readable prefix.
  ///   - words: The data represented as an array of 5-bit words.
  ///   - limit: An optional limit on the maximum length of the output string (default is 90).
  /// - Throws: Errors related to input length or invalid words.
  /// - Returns: A Bech32 encoded string.
  public func encode(`prefix`: String, words: [UInt8], limit: Int? = 90) throws(Bech32.Error) -> String {
    let limit = limit ?? 90
    
    // Check if the total length exceeds the specified limit.
    guard `prefix`.count + 7 + words.count <= limit else { throw Bech32.Error.exceedsLengthLimit }
    
    // Work with lowercase prefix to ensure case consistency.
    let lowerPrefix = prefix.lowercased()
    var chk = try prefixChk(prefix: lowerPrefix)
    var result = lowerPrefix + "1"
    
    // Process each word, ensuring it fits in 5 bits and updating the checksum.
    for x in words {
      if (x >> 5) != 0 { throw Bech32.Error.non5BitWord }
      chk = polymodStep(chk) ^ UInt32(x)
      let idx = self.alphabet.index(self.alphabet.startIndex, offsetBy: Int(x))
      result.append(self.alphabet[idx])
    }
    
    // Append 6 checksum characters.
    for _ in 0..<6 {
      chk = polymodStep(chk)
    }
    chk ^= self.encoding.const
    
    // Convert the checksum into 6 characters and append to the result.
    for i in 0..<6 {
      let shift = (5 - i) * 5
      let v = Int((chk >> UInt32(shift)) & 0x1f)
      let idx = self.alphabet.index(self.alphabet.startIndex, offsetBy: v)
      result.append(self.alphabet[idx])
    }
    
    return result
  }
  
  /// Decodes a Bech32 string into its prefix and 5-bit words.
  ///
  /// - Parameters:
  ///   - string: The Bech32 encoded string.
  ///   - limit: An optional limit on the maximum allowed length of the input (default is 90).
  /// - Throws: Errors related to string length, case inconsistencies, unknown characters, or invalid checksum.
  /// - Returns: A tuple containing the prefix and an array of 5-bit words.
  public func decode(_ string: String, limit: Int? = 90) throws(Bech32.Error) -> (prefix: String, words: [UInt8]) {
    let limit = limit ?? 90
    
    // Ensure the string has a valid length.
    guard string.count >= 8 else { throw Bech32.Error.dataTooShort }
    guard string.count <= limit else { throw Bech32.Error.exceedsLengthLimit }
    
    // Check for case consistency: must be all lower-case or all upper-case.
    let lowered = string.lowercased()
    let uppered = string.uppercased()
    
    guard string == lowered || string == uppered else { throw Bech32.Error.mixedCaseString }
    
    let s = lowered
    
    // Find the separator character "1".
    guard let sepIndex = s.lastIndex(of: "1") else { throw Bech32.Error.noSeparator }
    
    // The prefix must not be empty.
    guard sepIndex != s.startIndex else { throw Bech32.Error.missingPrefix }
    
    let prefix = s[s.startIndex..<sepIndex]
    let wordChars = s[s.index(after: sepIndex)...]
    
    // There must be at least 6 characters for the checksum.
    guard wordChars.count >= 6 else { throw Bech32.Error.dataTooShort }
    
    var chk = try prefixChk(prefix: prefix)
    var words = [UInt8]()
    for (i, c) in wordChars.enumerated() {
      // Map each character back to its 5-bit value.
      guard let v = self.charset[c] else {
        throw Bech32.Error.unknownCharacter(c)
      }
      chk = polymodStep(chk) ^ UInt32(v)
      // Append characters that are not part of the final 6 checksum characters.
      if i + 6 < wordChars.count {
        words.append(v)
      }
    }
    
    // Validate the final checksum against the expected constant.
    guard chk == self.encoding.const else { throw Bech32.Error.invalidChecksum }
    return (String(prefix), words)
  }
  
  // MARK: - Helper Functions
  
  /// Performs one step in the polymod checksum calculation.
  /// - Parameter pre: The current checksum value.
  /// - Returns: The updated checksum value.
  private func polymodStep(_ pre: UInt32) -> UInt32 {
    let b = pre >> 25
    var result = (pre & 0x1ffffff) << 5
    // XOR the result with generator coefficients when the corresponding bit in 'b' is set.
    if (b >> 0) & 1 != 0 { result ^= 0x3b6a57b2 }
    if (b >> 1) & 1 != 0 { result ^= 0x26508e6d }
    if (b >> 2) & 1 != 0 { result ^= 0x1ea119fa }
    if (b >> 3) & 1 != 0 { result ^= 0x3d4233dd }
    if (b >> 4) & 1 != 0 { result ^= 0x2a1462b3 }
    return result
  }
  
  /// Calculates the initial checksum value based on the prefix.
  ///
  /// This function iterates through the prefix characters and updates the checksum.
  ///
  /// - Parameter prefix: The human-readable part of the Bech32 string.
  /// - Throws: `Bech32.Error.invalidPrefix` if a character is outside the valid ASCII range.
  /// - Returns: The calculated checksum value.
  private func prefixChk<S: StringProtocol>(prefix: S) throws(Bech32.Error) -> UInt32 {
    var chk: UInt32 = 1
    // Pre-compute ASCII values to avoid duplicate computation.
    guard let asciiArray = try? `prefix`.map({ (char) -> UInt8 in
      guard let ascii = char.asciiValue, ascii >= 33, ascii <= 126 else {
        throw Bech32.Error.invalidPrefix
      }
      return ascii
    }) else {
      throw Bech32.Error.invalidPrefix
    }
    // First pass: incorporate high 3 bits.
    for ascii in asciiArray {
      chk = polymodStep(chk) ^ (UInt32(ascii) >> 5)
    }
    chk = polymodStep(chk)
    // Second pass: incorporate low 5 bits.
    for ascii in asciiArray {
      chk = polymodStep(chk) ^ (UInt32(ascii) & 0x1f)
    }
    return chk
  }
  
  /// Converts an array of data from one bit size to another.
  ///
  /// This is used for converting between 8-bit bytes and 5-bit words.
  ///
  /// - Parameters:
  ///   - data: The input array of UInt8 values.
  ///   - inBits: The bit size of the input values.
  ///   - outBits: The desired bit size for the output values.
  ///   - pad: Whether to add padding if there are remaining bits.
  /// - Throws: Padding-related errors if conversion is not clean.
  /// - Returns: The converted array of UInt8 values.
  private func convert(data: [UInt8], inBits: Int, outBits: Int, pad: Bool) throws(Bech32.Error) -> [UInt8] {
    var value = 0
    var bits = 0
    let maxV = (1 << outBits) - 1
    // Pre-allocate array capacity based on an estimated size.
    var result = [UInt8]()
    result.reserveCapacity((data.count * inBits + outBits - 1) / outBits)
    
    // Process each byte and extract outBits chunks.
    for d in data {
      value = (value << inBits) | Int(d)
      bits += inBits
      
      while bits >= outBits {
        bits -= outBits
        result.append(UInt8((value >> bits) & maxV))
      }
    }
    
    if pad {
      // If padding is allowed, pad the last chunk if needed.
      if bits > 0 {
        result.append(UInt8((value << (outBits - bits)) & maxV))
      }
    } else {
      // When no padding is allowed, ensure no excess or non-zero padding remains.
      guard bits < inBits else { throw Bech32.Error.excessPadding }
      guard (value << (outBits - bits)) & maxV == 0 else { throw Bech32.Error.nonZeroPadding }
    }
    
    return result
  }
}
