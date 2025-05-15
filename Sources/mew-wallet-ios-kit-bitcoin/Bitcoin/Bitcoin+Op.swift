//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/14/25.
//

import Foundation

extension Bitcoin {
  /// Represents an opcode in the Bitcoin Script language.
  /// Each opcode is either a constant, a data push instruction, a flow control instruction,
  /// or an arithmetic/logic/crypto operation defined by the Bitcoin protocol.
  public enum Op: Sendable {
    /// Dictionary mapping opcode bytes (UInt8) to statically known Bitcoin.Op cases.
    static let opcodeDict: [UInt8: Bitcoin.Op] = {
      var dict = [UInt8: Bitcoin.Op]()
      for op in Self.noDynamicPushDataCases {
        dict[op.rawValue] = op
      }
      return dict
    }()
    
    /// Array of numeric push opcodes (OP_1 to OP_16).
    static let nums: [Bitcoin.Op] = [
      .OP_1, .OP_2, .OP_3, .OP_4, .OP_5, .OP_6, .OP_7, .OP_8, .OP_9, .OP_10, .OP_11, .OP_12, .OP_13, .OP_14, .OP_15, .OP_16
    ]
    
    /// All opcodes that don't require dynamic payload handling.
    static let noDynamicPushDataCases: [Bitcoin.Op] = [
      // Constants / Push Value
      .OP_FALSE, .OP_1NEGATE, .OP_RESERVED, .OP_TRUE, .OP_2, .OP_3, .OP_4, .OP_5, .OP_6, .OP_7, .OP_8, .OP_9, .OP_10, .OP_11, .OP_12, .OP_13, .OP_14, .OP_15, .OP_16,
      // Flow Control
      .OP_NOP, .OP_VER, .OP_IF, .OP_NOTIF, .OP_VERIF, .OP_VERNOTIF, .OP_ELSE, .OP_ENDIF, .OP_VERIFY, .OP_RETURN,
      // Stack Operations
      .OP_TOALTSTACK, .OP_FROMALTSTACK, .OP_2DROP, .OP_2DUP, .OP_3DUP, .OP_2OVER, .OP_2ROT, .OP_2SWAP, .OP_IFDUP, .OP_DEPTH, .OP_DROP, .OP_DUP, .OP_NIP, .OP_OVER, .OP_PICK, .OP_ROLL, .OP_ROT, .OP_SWAP, .OP_TUCK,
      // Splice Operations (Disabled in Bitcoin Core)
      .OP_CAT, .OP_SUBSTR, .OP_LEFT, .OP_RIGHT, .OP_SIZE,
      // Bitwise Logic
      .OP_INVERT, .OP_AND, .OP_OR, .OP_XOR, .OP_EQUAL, .OP_EQUALVERIFY, .OP_RESERVED1, .OP_RESERVED2,
      // Arithmetic
      .OP_1ADD, .OP_1SUB, .OP_2MUL, .OP_2DIV, .OP_NEGATE, .OP_ABS, .OP_NOT, .OP_0NOTEQUAL, .OP_ADD, .OP_SUB, .OP_MUL, .OP_DIV, .OP_MOD, .OP_LSHIFT, .OP_RSHIFT, .OP_BOOLAND, .OP_BOOLOR, .OP_NUMEQUAL, .OP_NUMEQUALVERIFY, .OP_NUMNOTEQUAL, .OP_LESSTHAN, .OP_GREATERTHAN, .OP_LESSTHANOREQUAL, .OP_GREATERTHANOREQUAL, .OP_MIN, .OP_MAX, .OP_WITHIN,
      // Crypto
      .OP_RIPEMD160, .OP_SHA1, .OP_SHA256, .OP_HASH160, .OP_HASH256, .OP_CODESEPARATOR, .OP_CHECKSIG, .OP_CHECKSIGVERIFY, .OP_CHECKMULTISIG, .OP_CHECKMULTISIGVERIFY,
      // Expansion / Reserved
      .OP_NOP1, .OP_CHECKLOCKTIMEVERIFY, .OP_CHECKSEQUENCEVERIFY, .OP_NOP4, .OP_NOP5, .OP_NOP6, .OP_NOP7, .OP_NOP8, .OP_NOP9, .OP_NOP10,
    ]
    
    // MARK: - Constants / Push Value
    
    /// Pushes 0 onto the stack. Also known as OP_0.
    case OP_FALSE
    public static var OP_0: Self { .OP_FALSE }
    
    /// Pushes arbitrary bytes (1–75 bytes) onto the stack.
    case OP_PUSHBYTES(Data)
    
    /// Pushes bytes using PUSHDATA1 format (1-byte length prefix).
    case OP_PUSHDATA1(Data)
    
    /// Pushes bytes using PUSHDATA2 format (2-byte length prefix).
    case OP_PUSHDATA2(Data)
    
    /// Pushes bytes using PUSHDATA4 format (4-byte length prefix).
    case OP_PUSHDATA4(Data)
    
    /// Pushes -1 onto the stack.
    case OP_1NEGATE
    
    /// Reserved for future upgrades.
    case OP_RESERVED
    
    /// Pushes 1 onto the stack. Also known as OP_TRUE.
    case OP_TRUE
    public static var OP_1: Self { .OP_TRUE }
    
    /// Pushes a numeric constant (2–16) onto the stack.
    case OP_2, OP_3, OP_4, OP_5, OP_6, OP_7, OP_8, OP_9, OP_10, OP_11, OP_12, OP_13, OP_14, OP_15, OP_16
    
    // MARK: - Flow Control
    
    /// Does nothing.
    case OP_NOP
    
    /// Always invalid. Reserved.
    case OP_VER
    
    /// Begins an "if" block.
    case OP_IF
    
    /// Begins a "not if" block.
    case OP_NOTIF
    
    /// Invalid. Reserved.
    case OP_VERIF
    
    /// Invalid. Reserved.
    case OP_VERNOTIF
    
    /// Begins an "else" block.
    case OP_ELSE
    
    /// Ends a conditional block.
    case OP_ENDIF
    
    /// Verifies top stack item is true, else fails.
    case OP_VERIFY
    
    /// Marks script as immediately invalid.
    case OP_RETURN
    
    // MARK: - Stack Operations
    
    /// Moves top stack item to alt stack.
    case OP_TOALTSTACK
    
    /// Moves top alt stack item back to main stack.
    case OP_FROMALTSTACK
    
    /// Drops the top 2 stack items.
    case OP_2DROP
    
    /// Duplicates top 2 stack items.
    case OP_2DUP
    
    /// Duplicates top 3 stack items.
    case OP_3DUP
    
    /// Copies 2 items starting from the 3rd.
    case OP_2OVER
    
    /// The fifth and sixth items back are moved to the top of the stack.
    case OP_2ROT
    
    /// Swaps the top two pairs of items.
    case OP_2SWAP
    
    /// If the top stack value is not 0, duplicate it.
    case OP_IFDUP
    
    /// Puts the number of stack items onto the stack.
    case OP_DEPTH
    
    /// Drops the top stack item.
    case OP_DROP
    
    /// Duplicates the top stack item.
    case OP_DUP
    
    /// Removes second item from top.
    case OP_NIP
    
    /// Copies the second item to the top.
    case OP_OVER
    
    /// Copies any item to the top.
    case OP_PICK
    
    /// Moves any item to the top.
    case OP_ROLL
    
    /// The 3rd item down the stack is moved to the top.
    case OP_ROT
    
    /// Swaps top two items.
    case OP_SWAP
    
    /// Copies top item and inserts beneath second item.
    case OP_TUCK
    
    // MARK: - Splice Operations (Disabled in Bitcoin Core)
    
    /// Concatenates two strings.
    case OP_CAT
    
    /// Returns substring.
    case OP_SUBSTR
    
    /// Returns left substring.
    case OP_LEFT
    
    /// Returns right substring.
    case OP_RIGHT
    
    /// Pushes string length.
    case OP_SIZE
    
    // MARK: - Bitwise Logic
    
    /// Bitwise NOT.
    case OP_INVERT
    
    /// Bitwise AND.
    case OP_AND
    
    /// Bitwise OR.
    case OP_OR
    
    /// Bitwise XOR.
    case OP_XOR
    
    /// Checks if top two items are equal.
    case OP_EQUAL
    
    /// Same as OP_EQUAL, but also OP_VERIFY.
    case OP_EQUALVERIFY
    
    /// Reserved (disabled).
    case OP_RESERVED1
    
    /// Reserved (disabled).
    case OP_RESERVED2
    
    // MARK: - Arithmetic
    
    /// Adds 1.
    case OP_1ADD
    
    /// Subtracts 1.
    case OP_1SUB
    
    /// Multiplies top two numbers.
    case OP_2MUL
    
    /// Divides second top number by top.
    case OP_2DIV
    
    /// Negates top item.
    case OP_NEGATE
    
    /// Absolute value.
    case OP_ABS
    
    /// Logical NOT.
    case OP_NOT
    
    /// Returns 1 if input is not zero.
    case OP_0NOTEQUAL
    
    /// Adds top two numbers.
    case OP_ADD
    
    /// Subtracts top from second top.
    case OP_SUB
    
    /// Multiplies.
    case OP_MUL
    
    /// Divides.
    case OP_DIV
    
    /// Remainder after division.
    case OP_MOD
    
    /// Logical left shift.
    case OP_LSHIFT
    
    /// Logical right shift.
    case OP_RSHIFT
    
    /// Logical AND of booleans.
    case OP_BOOLAND
    
    /// Logical OR of booleans.
    case OP_BOOLOR
    
    /// Equality comparison.
    case OP_NUMEQUAL
    
    /// Equality comparison + verify.
    case OP_NUMEQUALVERIFY
    
    /// Inequality comparison.
    case OP_NUMNOTEQUAL
    
    /// Less than.
    case OP_LESSTHAN
    
    /// Greater than.
    case OP_GREATERTHAN
    
    /// Less than or equal.
    case OP_LESSTHANOREQUAL
    
    /// Greater than or equal.
    case OP_GREATERTHANOREQUAL
    
    /// Minimum of top two.
    case OP_MIN
    
    /// Maximum of top two.
    case OP_MAX
    
    /// Checks if x is within range.
    case OP_WITHIN
    
    // MARK: - Crypto
    
    /// RIPEMD-160 hash.
    case OP_RIPEMD160
    
    /// SHA-1 hash.
    case OP_SHA1
    
    /// SHA-256 hash.
    case OP_SHA256
    
    /// HASH160 (RIPEMD160(SHA256(x))).
    case OP_HASH160
    
    /// Double SHA-256.
    case OP_HASH256
    
    /// Code separator (used in sighash).
    case OP_CODESEPARATOR
    
    /// Verifies ECDSA signature.
    case OP_CHECKSIG
    
    /// Verifies signature and enforces success.
    case OP_CHECKSIGVERIFY
    
    /// Verifies multiple signatures.
    case OP_CHECKMULTISIG
    
    /// Verifies multiple signatures and enforces success.
    case OP_CHECKMULTISIGVERIFY
    
    // MARK: - Expansion / Reserved
    
    /// Reserved NOP.
    case OP_NOP1
    
    /// Enables locktime-based spending. Formerly OP_NOP2
    case OP_CHECKLOCKTIMEVERIFY
    public static var OP_NOP2: Self { .OP_CHECKLOCKTIMEVERIFY }
    
    /// Enables sequence-based spending. Formerly OP_NOP3
    case OP_CHECKSEQUENCEVERIFY
    public static var OP_NOP3: Self { .OP_CHECKSEQUENCEVERIFY }
    
    /// Reserved NOP.
    case OP_NOP4, OP_NOP5, OP_NOP6, OP_NOP7, OP_NOP8, OP_NOP9, OP_NOP10
    
    // MARK: - Unknown Opcode
    
    /// Any unknown opcode.
    case _UNKNOWN(UInt8)
    
  }
}

// MARK: - Bitcoin.Op + RawRepresentable {

extension Bitcoin.Op: RawRepresentable {
  /// Returns the byte value that corresponds to this opcode.
  public var rawValue: UInt8 {
    switch self {
      // Constants / Push Value
    case .OP_FALSE:                 return 0x00
    case .OP_PUSHBYTES(let data):   return UInt8(clamping: data.count)
    case .OP_PUSHDATA1:             return 0x4c
    case .OP_PUSHDATA2:             return 0x4d
    case .OP_PUSHDATA4:             return 0x4e
    case .OP_1NEGATE:               return 0x4f
    case .OP_RESERVED:              return 0x50
    case .OP_TRUE:                  return 0x51
    case .OP_2:                     return 0x52
    case .OP_3:                     return 0x53
    case .OP_4:                     return 0x54
    case .OP_5:                     return 0x55
    case .OP_6:                     return 0x56
    case .OP_7:                     return 0x57
    case .OP_8:                     return 0x58
    case .OP_9:                     return 0x59
    case .OP_10:                    return 0x5a
    case .OP_11:                    return 0x5b
    case .OP_12:                    return 0x5c
    case .OP_13:                    return 0x5d
    case .OP_14:                    return 0x5e
    case .OP_15:                    return 0x5f
    case .OP_16:                    return 0x60
      
      // Flow Control
    case .OP_NOP:                   return 0x61
    case .OP_VER:                   return 0x62
    case .OP_IF:                    return 0x63
    case .OP_NOTIF:                 return 0x64
    case .OP_VERIF:                 return 0x65
    case .OP_VERNOTIF:              return 0x66
    case .OP_ELSE:                  return 0x67
    case .OP_ENDIF:                 return 0x68
    case .OP_VERIFY:                return 0x69
    case .OP_RETURN:                return 0x6a
      
      // Stack Operations
    case .OP_TOALTSTACK:            return 0x6b
    case .OP_FROMALTSTACK:          return 0x6c
    case .OP_2DROP:                 return 0x6d
    case .OP_2DUP:                  return 0x6e
    case .OP_3DUP:                  return 0x6f
    case .OP_2OVER:                 return 0x70
    case .OP_2ROT:                  return 0x71
    case .OP_2SWAP:                 return 0x72
    case .OP_IFDUP:                 return 0x73
    case .OP_DEPTH:                 return 0x74
    case .OP_DROP:                  return 0x75
    case .OP_DUP:                   return 0x76
    case .OP_NIP:                   return 0x77
    case .OP_OVER:                  return 0x78
    case .OP_PICK:                  return 0x79
    case .OP_ROLL:                  return 0x7a
    case .OP_ROT:                   return 0x7b
    case .OP_SWAP:                  return 0x7c
    case .OP_TUCK:                  return 0x7d
      
      // Splice Operations (Disabled)
    case .OP_CAT:                   return 0x7e
    case .OP_SUBSTR:                return 0x7f
    case .OP_LEFT:                  return 0x80
    case .OP_RIGHT:                 return 0x81
    case .OP_SIZE:                  return 0x82
      
      // Bitwise Logic
    case .OP_INVERT:                return 0x83
    case .OP_AND:                   return 0x84
    case .OP_OR:                    return 0x85
    case .OP_XOR:                   return 0x86
    case .OP_EQUAL:                 return 0x87
    case .OP_EQUALVERIFY:           return 0x88
    case .OP_RESERVED1:             return 0x89
    case .OP_RESERVED2:             return 0x8a
      
      // Arithmetic
    case .OP_1ADD:                  return 0x8b
    case .OP_1SUB:                  return 0x8c
    case .OP_2MUL:                  return 0x8d
    case .OP_2DIV:                  return 0x8e
    case .OP_NEGATE:                return 0x8f
    case .OP_ABS:                   return 0x90
    case .OP_NOT:                   return 0x91
    case .OP_0NOTEQUAL:             return 0x92
      
    case .OP_ADD:                   return 0x93
    case .OP_SUB:                   return 0x94
    case .OP_MUL:                   return 0x95
    case .OP_DIV:                   return 0x96
    case .OP_MOD:                   return 0x97
    case .OP_LSHIFT:                return 0x98
    case .OP_RSHIFT:                return 0x99
      
    case .OP_BOOLAND:               return 0x9a
    case .OP_BOOLOR:                return 0x9b
    case .OP_NUMEQUAL:              return 0x9c
    case .OP_NUMEQUALVERIFY:        return 0x9d
    case .OP_NUMNOTEQUAL:           return 0x9e
    case .OP_LESSTHAN:              return 0x9f
    case .OP_GREATERTHAN:           return 0xa0
    case .OP_LESSTHANOREQUAL:       return 0xa1
    case .OP_GREATERTHANOREQUAL:    return 0xa2
    case .OP_MIN:                   return 0xa3
    case .OP_MAX:                   return 0xa4
    case .OP_WITHIN:                return 0xa5
      
      // Crypto
    case .OP_RIPEMD160:             return 0xa6
    case .OP_SHA1:                  return 0xa7
    case .OP_SHA256:                return 0xa8
    case .OP_HASH160:               return 0xa9
    case .OP_HASH256:               return 0xaa
    case .OP_CODESEPARATOR:         return 0xab
    case .OP_CHECKSIG:              return 0xac
    case .OP_CHECKSIGVERIFY:        return 0xad
    case .OP_CHECKMULTISIG:         return 0xae
    case .OP_CHECKMULTISIGVERIFY:   return 0xaf
      
      // Expansion / Reserved
    case .OP_NOP1:                  return 0xb0
    case .OP_CHECKLOCKTIMEVERIFY:   return 0xb1
    case .OP_CHECKSEQUENCEVERIFY:   return 0xb2
    case .OP_NOP4:                  return 0xb3
    case .OP_NOP5:                  return 0xb4
    case .OP_NOP6:                  return 0xb5
    case .OP_NOP7:                  return 0xb6
    case .OP_NOP8:                  return 0xb7
    case .OP_NOP9:                  return 0xb8
    case .OP_NOP10:                 return 0xb9
      
    case ._UNKNOWN(let value):      return value
    }
  }
  
  /// Initializes an opcode using its raw UInt8 value.
  public init?(rawValue: UInt8) {
    if let op = Self.opcodeDict[rawValue] {
      self = op
    } else if !(0x01...0x4e).contains(rawValue) {
      self = ._UNKNOWN(rawValue)
    } else {
      return nil
    }
  }
  
  /// Initializes an opcode from its encoded payload.
  public init?(data: Data) {
    switch data.count {
    case 0:                   self = .OP_0
    case ...75:               self = .OP_PUSHBYTES(data)
    case ...Int(UInt8.max):   self = .OP_PUSHDATA1(data)
    case ...Int(UInt16.max):  self = .OP_PUSHDATA2(data)
    case ...Int(UInt32.max):  self = .OP_PUSHDATA4(data)
    default:                  return nil
    }
  }
  
  /// Initializes a pushdata-style opcode from opcode byte and data.
  public init?(rawValue: UInt8, data: Data) {
    switch rawValue {
    case 0x01...0x4b:
      self = .OP_PUSHBYTES(data)
    case 0x4c:
        self = .OP_PUSHDATA1(data)
    case 0x4d:
        self = .OP_PUSHDATA2(data)
    case 0x4e:
        self = .OP_PUSHDATA4(data)
    default:
      return nil
    }
  }
}

// MARK: - Bitcoin.Op + Convenience

extension Bitcoin.Op {
  /// Returns true if the opcode is numeric (OP_1–OP_16).
  var isNumeric: Bool { Self.nums.contains(self) }
  
  /// A readable string representation of the opcode.
  public var word: String {
    switch self {
      // Constants / Push Value
    case .OP_FALSE:                 return "0"
    case .OP_PUSHBYTES(let data):   return "\(data.toHexString())"
    case .OP_PUSHDATA1(let data):   return "OP_PUSHDATA1 \(data.toHexString())"
    case .OP_PUSHDATA2(let data):   return "OP_PUSHDATA2 \(data.toHexString())"
    case .OP_PUSHDATA4(let data):   return "OP_PUSHDATA4 \(data.toHexString())"
    case .OP_1NEGATE:               return "OP_1NEGATE"
    case .OP_RESERVED:              return "OP_RESERVED"
    case .OP_TRUE:                  return "1"
    case .OP_2:                     return "2"
    case .OP_3:                     return "3"
    case .OP_4:                     return "4"
    case .OP_5:                     return "5"
    case .OP_6:                     return "6"
    case .OP_7:                     return "7"
    case .OP_8:                     return "8"
    case .OP_9:                     return "9"
    case .OP_10:                    return "10"
    case .OP_11:                    return "11"
    case .OP_12:                    return "12"
    case .OP_13:                    return "13"
    case .OP_14:                    return "14"
    case .OP_15:                    return "15"
    case .OP_16:                    return "16"
      
      // Flow Control
    case .OP_NOP:                   return "OP_NOP"
    case .OP_VER:                   return "OP_VER"
    case .OP_IF:                    return "OP_IF"
    case .OP_NOTIF:                 return "OP_NOTIF"
    case .OP_VERIF:                 return "OP_VERIF"
    case .OP_VERNOTIF:              return "OP_VERNOTIF"
    case .OP_ELSE:                  return "OP_ELSE"
    case .OP_ENDIF:                 return "OP_ENDIF"
    case .OP_VERIFY:                return "OP_VERIFY"
    case .OP_RETURN:                return "OP_RETURN"
      
      // Stack Operations
    case .OP_TOALTSTACK:            return "OP_TOALTSTACK"
    case .OP_FROMALTSTACK:          return "OP_FROMALTSTACK"
    case .OP_2DROP:                 return "OP_2DROP"
    case .OP_2DUP:                  return "OP_2DUP"
    case .OP_3DUP:                  return "OP_3DUP"
    case .OP_2OVER:                 return "OP_2OVER"
    case .OP_2ROT:                  return "OP_2ROT"
    case .OP_2SWAP:                 return "OP_2SWAP"
    case .OP_IFDUP:                 return "OP_IFDUP"
    case .OP_DEPTH:                 return "OP_DEPTH"
    case .OP_DROP:                  return "OP_DROP"
    case .OP_DUP:                   return "OP_DUP"
    case .OP_NIP:                   return "OP_NIP"
    case .OP_OVER:                  return "OP_OVER"
    case .OP_PICK:                  return "OP_PICK"
    case .OP_ROLL:                  return "OP_ROLL"
    case .OP_ROT:                   return "OP_ROT"
    case .OP_SWAP:                  return "OP_SWAP"
    case .OP_TUCK:                  return "OP_TUCK"
      
      // Splice Operations (Disabled)
    case .OP_CAT:                   return "OP_CAT"
    case .OP_SUBSTR:                return "OP_SUBSTR"
    case .OP_LEFT:                  return "OP_LEFT"
    case .OP_RIGHT:                 return "OP_RIGHT"
    case .OP_SIZE:                  return "OP_SIZE"
      
      // Bitwise Logic
    case .OP_INVERT:                return "OP_INVERT"
    case .OP_AND:                   return "OP_AND"
    case .OP_OR:                    return "OP_OR"
    case .OP_XOR:                   return "OP_XOR"
    case .OP_EQUAL:                 return "OP_EQUAL"
    case .OP_EQUALVERIFY:           return "OP_EQUALVERIFY"
    case .OP_RESERVED1:             return "OP_RESERVED1"
    case .OP_RESERVED2:             return "OP_RESERVED2"
      
      // Arithmetic
    case .OP_1ADD:                  return "OP_1ADD"
    case .OP_1SUB:                  return "OP_1SUB"
    case .OP_2MUL:                  return "OP_2MUL"
    case .OP_2DIV:                  return "OP_2DIV"
    case .OP_NEGATE:                return "OP_NEGATE"
    case .OP_ABS:                   return "OP_ABS"
    case .OP_NOT:                   return "OP_NOT"
    case .OP_0NOTEQUAL:             return "OP_0NOTEQUAL"
      
    case .OP_ADD:                   return "OP_ADD"
    case .OP_SUB:                   return "OP_SUB"
    case .OP_MUL:                   return "OP_MUL"
    case .OP_DIV:                   return "OP_DIV"
    case .OP_MOD:                   return "OP_MOD"
    case .OP_LSHIFT:                return "OP_LSHIFT"
    case .OP_RSHIFT:                return "OP_RSHIFT"
      
    case .OP_BOOLAND:               return "OP_BOOLAND"
    case .OP_BOOLOR:                return "OP_BOOLOR"
    case .OP_NUMEQUAL:              return "OP_NUMEQUAL"
    case .OP_NUMEQUALVERIFY:        return "OP_NUMEQUALVERIFY"
    case .OP_NUMNOTEQUAL:           return "OP_NUMNOTEQUAL"
    case .OP_LESSTHAN:              return "OP_LESSTHAN"
    case .OP_GREATERTHAN:           return "OP_GREATERTHAN"
    case .OP_LESSTHANOREQUAL:       return "OP_LESSTHANOREQUAL"
    case .OP_GREATERTHANOREQUAL:    return "OP_GREATERTHANOREQUAL"
    case .OP_MIN:                   return "OP_MIN"
    case .OP_MAX:                   return "OP_MAX"
    case .OP_WITHIN:                return "OP_WITHIN"
      
      // Crypto
    case .OP_RIPEMD160:             return "OP_RIPEMD160"
    case .OP_SHA1:                  return "OP_SHA1"
    case .OP_SHA256:                return "OP_SHA256"
    case .OP_HASH160:               return "OP_HASH160"
    case .OP_HASH256:               return "OP_HASH256"
    case .OP_CODESEPARATOR:         return "OP_CODESEPARATOR"
    case .OP_CHECKSIG:              return "OP_CHECKSIG"
    case .OP_CHECKSIGVERIFY:        return "OP_CHECKSIGVERIFY"
    case .OP_CHECKMULTISIG:         return "OP_CHECKMULTISIG"
    case .OP_CHECKMULTISIGVERIFY:   return "OP_CHECKMULTISIGVERIFY"
      
      // Expansion / Reserved
    case .OP_NOP1:                  return "OP_NOP1"
    case .OP_CHECKLOCKTIMEVERIFY:   return "OP_CHECKLOCKTIMEVERIFY"
    case .OP_CHECKSEQUENCEVERIFY:   return "OP_CHECKSEQUENCEVERIFY"
    case .OP_NOP4:                  return "OP_NOP4"
    case .OP_NOP5:                  return "OP_NOP5"
    case .OP_NOP6:                  return "OP_NOP6"
    case .OP_NOP7:                  return "OP_NOP7"
    case .OP_NOP8:                  return "OP_NOP8"
    case .OP_NOP9:                  return "OP_NOP9"
    case .OP_NOP10:                 return "OP_NOP10"
      
      // Unknown
    case ._UNKNOWN(let value):      return "_UNKNOWN(\(value))"
    }
  }
}

// MARK: - Bitcoin.Op + Codable

extension Bitcoin.Op: Codable {
  /// Decodes an `Op` from an unkeyed container.
  /// Supports both basic opcodes and pushdata formats.
  public init(from decoder: any Swift.Decoder) throws {
    var container = try decoder.unkeyedContainer()
    let code = try container.decode(UInt8.self)
    if let op = Self(rawValue: code) {
      self = op
      return
    }
    let data = try container.decode(Data.self)
    guard let op = Self(rawValue: code, data: data) else {
      throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Invalid data"))
    }
    self = op
  }
  
  /// Encodes the `Op` into a single value container.
  /// Attempts to encode a human-readable `word` representation first (e.g. for `JSONEncoder`).
  /// If encoding `word` fails (e.g. in binary format), falls back to encoding raw opcode and associated data if applicable.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    do {
      /// Bitcoin.Encoder will throw an error
      try container.encode(self.word)
    } catch {
      switch self {
      case .OP_PUSHBYTES(let data):
        try container.encode(UInt8(clamping: data.count))
        try container.encode(data)
      case .OP_PUSHDATA1(let data):
        try container.encode(self.rawValue)
        try container.encode(UInt8(clamping: data.count))
        try container.encode(data)
      case .OP_PUSHDATA2(let data):
        try container.encode(self.rawValue)
        try container.encode(UInt16(clamping: data.count))
        try container.encode(data)
      case .OP_PUSHDATA4(let data):
        try container.encode(self.rawValue)
        try container.encode(UInt32(clamping: data.count))
        try container.encode(data)
      case ._UNKNOWN(let op):
        try container.encode(op)
      default:
        try container.encode(self.rawValue)
      }
    }
  }
}

extension Bitcoin.Op: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    guard lhs.rawValue == rhs.rawValue else { return false }
    
    switch (lhs, rhs) {
    case (.OP_PUSHBYTES(let lhs), .OP_PUSHBYTES(let rhs)),
         (.OP_PUSHDATA1(let lhs), .OP_PUSHDATA1(let rhs)),
         (.OP_PUSHDATA2(let lhs), .OP_PUSHDATA2(let rhs)),
         (.OP_PUSHDATA4(let lhs), .OP_PUSHDATA4(let rhs)):
      return lhs == rhs
    default:
      return true
    }
  }
}

extension Bitcoin.Op: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.rawValue)
    switch self {
    case .OP_PUSHBYTES(let data),
         .OP_PUSHDATA1(let data),
         .OP_PUSHDATA2(let data),
         .OP_PUSHDATA4(let data):
      hasher.combine(data)
    default:
      break
    }
  }
}
