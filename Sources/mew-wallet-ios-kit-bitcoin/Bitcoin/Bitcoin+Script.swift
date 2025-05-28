//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/15/25.
//

import Foundation

extension Bitcoin {
  /// Represents a parsed Bitcoin script.
  /// Contains an ordered list of script operations (`asm`)
  /// and an optional script type classification (`type`).
  public struct Script: Equatable, Sendable, Hashable {
    public static var empty: Self { .init(asm: []) }
    
    public let asm: [Bitcoin.Op]
    public let type: Bitcoin.Script.ScriptType?
    
    /// Initializes a script from a sequence of parsed operations.
    /// Also attempts to classify the script type based on its content.
    public init(asm: [Bitcoin.Op]) {
      self.asm = asm
      self.type = Bitcoin.Script.ScriptType(asm: asm)
    }
    
    public func hash(into hasher: inout Hasher) {
      hasher.combine(type)
    }
  }
}

extension Bitcoin.Script: Codable {
  private enum CodingKeys: CodingKey {
    case asm
    case type
  }

  /// Decodes a script from JSON or binary. Restores opcode array and tries to classify the script type.
  public init(from decoder: any Swift.Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    self.asm = try container.decode([Bitcoin.Op].self, forKey: .asm)
    self.type = Bitcoin.Script.ScriptType(asm: self.asm)
  }
  
  /// Encodes the script into a format with `asm` (array of opcodes) and `type` (if classified).
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    
    try container.encode(self.asm, forKey: .asm)

    /// Attempts to encode `type` as a string if it exists (used in JSON encoders).
    /// JSONEncoder will omit the field if `type` is nil.
    /// When using `Bitcoin.Encoder`, encoding a nil optional may throw an error,
    /// so `try?` is used here to silently ignore that case and maintain compatibility.
    try? container.encodeIfPresent(self.type?.rawValue, forKey: .type)
  }
}

// MARK: - Bitcoin.Script + ScriptType

extension Bitcoin.Script {
  /// Enumerates known Bitcoin script patterns (e.g. P2PKH, P2SH, P2WPKH, Taproot, etc.).
  /// Used for classification and signing decisions.
  public enum ScriptType: String, Equatable, Sendable, Hashable {
    /// Unknown or malformed script.
    case nonstandard
    
    /// Pay-to-pubkey (P2PK): `OP_PUSHBYTES(pubkey) OP_CHECKSIG`
    case pubkey
    
    /// Pay-to-pubkey-hash (P2PKH): `OP_DUP OP_HASH160 <20-byte hash> OP_EQUALVERIFY OP_CHECKSIG`
    case pubkeyhash
    
    /// Pay-to-script-hash (P2SH): `OP_HASH160 <20-byte hash> OP_EQUAL`
    case scripthash
    
    /// Multisignature script: `OP_N <pubkeys...> OP_M OP_CHECKMULTISIG`
    case multisig
    
    /// Null data (OP_RETURN) script, often used for metadata.
    case nulldata
    
    /// Witness v0 key-hash (P2WPKH): `OP_0 <20-byte pubkey hash>`
    case witness_v0_keyhash
    
    /// Witness v0 script-hash (P2WSH): `OP_0 <32-byte script hash>`
    case witness_v0_scripthash
    
    /// Witness v1 taproot (P2TR): `OP_1 <32-byte x-only pubkey>`
    case witness_v1_taproot
    
    /// Anchor commitment or sidechain marker: `OP_1 <2 bytes>` (non-standard use)
    case anchor
    
    /// Witness of unknown version (future versions): `OP_n <2-40 byte data>`, where `n > 1`
    case witness_unknown
    
    /// Attempts to classify a script based on its opcode pattern.
    /// Returns `nil` if classification cannot be determined from the provided assembly.
    init?(asm: [Bitcoin.Op]) {
      guard let op = asm.first else {
        return nil
      }
      switch op {
        // MARK: pubkey
      case .OP_PUSHBYTES(let data) where
        asm.count == 2 &&
        (data.count == 33 || data.count == 65) &&
        asm.last == .OP_CHECKSIG:
        
        self = .pubkey
        
        // MARK: pubkeyhash
      case .OP_DUP where
        asm.count == 5 &&
        {
          guard case .OP_PUSHBYTES(let data) = asm[2], data.count == 20 else { return false }
          return true
        }() &&
        asm == [.OP_DUP, .OP_HASH160, asm[2], .OP_EQUALVERIFY, .OP_CHECKSIG]:
        
        self = .pubkeyhash
        
        // MARK: scripthash
      case .OP_HASH160 where
        asm.count == 3 &&
        {
          guard case .OP_PUSHBYTES(let data) = asm[1] else { return false }
          return data.count == 20

        }() &&
        asm.last == .OP_EQUAL:
        
        self = .scripthash
        
        // MARK: multisig
      case _ where
        op.isNumeric &&
        asm.count >= 4 &&
        asm.last == .OP_CHECKMULTISIG &&
        {
          let M = asm[asm.count-2]
          guard M.isNumeric, op.rawValue <= M.rawValue else { return false }
          let bytes = asm[1..<asm.count-2]
          guard bytes.count == (M.rawValue - Bitcoin.Op.OP_TRUE.rawValue + 1) else { return false }
          return bytes.allSatisfy({
            guard case .OP_PUSHBYTES(let data) = $0 else { return false }
            return data.count == 33 || data.count == 65
          })
        }():
        
        self = .multisig
        
        // MARK: nulldata
      case .OP_RETURN where
        asm.count == 1 ||
        (
          asm.count == 2 &&
          {
            guard case .OP_PUSHBYTES(let data) = asm.last, data.isEmpty || data.count <= 80 else { return false }
            return true
          }()
        ):
        self = .nulldata
        
        // MARK: witness_v0_keyhash
      case .OP_0 where
        asm.count == 2 &&
        {
          guard case .OP_PUSHBYTES(let data) = asm.last, data.count == 20 else { return false }
          return true
        }():
        
        self = .witness_v0_keyhash
        
        // MARK: witness_v0_scripthash
      case .OP_0 where
        asm.count == 2 &&
        {
          guard case .OP_PUSHBYTES(let data) = asm.last, data.count == 32 else { return false }
          return true
        }():
        
        self = .witness_v0_scripthash
        
      case .OP_1 where
        asm.count == 2 &&
        {
          guard case .OP_PUSHBYTES(let data) = asm.last, data.count == 32 else { return false }
          return true
        }():
        
        self = .witness_v1_taproot
        
        // MARK: anchor
      case .OP_1 where
        asm.count == 2 &&
        {
          guard case .OP_PUSHBYTES(let data) = asm.last, data.count == 2 else { return false }
          return true
        }():
        
        self = .anchor
        
        // MARK: witness_unknown
      case _ where
        op.isNumeric &&
        op != .OP_0 &&
        {
          guard case .OP_PUSHBYTES(let data) = asm.last else { return false }
          return data.count >= 2 && data.count <= 40
        }():
        
        self = .witness_unknown
        
        // MARK: nonstandard
      default:
        self = .nonstandard
      }
    }
  }
}

#if DEBUG
extension Bitcoin.Script {
  public func _prettyPrint() -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted]
    encoder.dataEncodingStrategy = .custom({ data, encoder in
      var container = encoder.singleValueContainer()
      try container.encode(data.toHexString())
    })
    guard let encoded = try? encoder.encode(self) else {
      return "<failed>"
    }
    return String(data: encoded, encoding: .utf8) ?? "<failed>"
  }
}
#endif
