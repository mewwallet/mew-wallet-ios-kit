//
//  File.swift
//  
//
//  Created by Mikhail Nikanorov on 1/18/23.
//

import Foundation
import BigInt

public struct ZKSync {
  struct EIP712Message {
    static func domain(with chainId: Int?) -> TypedMessageDomain {
      return TypedMessageDomain(name: "zkSync",
                                version: "2",
                                chainId: chainId,
                                verifyingContract: nil)
    }
    
    static var types: MessageTypes {
      return [
        "EIP712Domain": [
          .init(name: "name",                     type: "string"),
          .init(name: "version",                  type: "string"),
          .init(name: "chainId",                  type: "uint256")
        ],
        "Transaction": [
          .init(name: "txType",                   type: "uint256"),
          .init(name: "from",                     type: "uint256"),
          .init(name: "to",                       type: "uint256"),
          .init(name: "ergsLimit",                type: "uint256"),
          .init(name: "ergsPerPubdataByteLimit",  type: "uint256"),
          .init(name: "maxFeePerErg",             type: "uint256"),
          .init(name: "maxPriorityFeePerErg",     type: "uint256"),
          .init(name: "paymaster",                type: "uint256"),
          .init(name: "nonce",                    type: "uint256"),
          .init(name: "value",                    type: "uint256"),
          .init(name: "data",                     type: "bytes"),
          .init(name: "factoryDeps",              type: "bytes32[]"),
          .init(name: "paymasterInput",           type: "bytes")
        ]
      ]
    }
  }
  
  public final class EIP712Transaction: Transaction {
    public final class Meta {
      public struct Paymaster {
        public enum `Type` {
          case general(innerInput: Data)
          case approvalBased(token: Address, minimalAllowance: BigInt, innerInput: Data)
        }
        
        public static func paymaster(with address: Address, type: `Type`) -> Paymaster {
          switch type {
          case .general(let innerInput):
            let function = ABI.Element.Function(name: "general",
                                                inputs: [
                                                  .init(name: "input", type: .dynamicBytes)
                                                ],
                                                outputs: [], constant: false, payable: false)
            let parameters: [AnyObject] = [
              innerInput as AnyObject
            ]
            
            let data = ABI.Element.function(function).encodeParameters(parameters)
            return Paymaster(paymaster: address, input: data)
          case .approvalBased(let token, let minimalAllowance, let innerInput):
            let function = ABI.Element.Function(name: "approvalBased",
                                                inputs: [
                                                  .init(name: "_token", type: .address),
                                                  .init(name: "_minAllowance", type: .uint(bits: 256)),
                                                  .init(name: "_innerInput", type: .dynamicBytes)
                                                ],
                                                outputs: [], constant: false, payable: false)
            let parameters: [AnyObject] = [
              token.address as AnyObject,
              minimalAllowance as AnyObject,
              innerInput as AnyObject
            ]
            
            let data = ABI.Element.function(function).encodeParameters(parameters)
            return Paymaster(paymaster: address, input: data)
          }
        }
        
        let paymaster: Address
        let input: Data?
      }
      
      public var ergsPerPubdata = BigInt(160000) //DEFAULT_ERGS_PER_PUBDATA_LIMIT
      public var customSignature: Data? = nil
      public var paymaster: Paymaster? = nil
      public var factoryDeps: [Data]? = nil
      
      public init(ergsPerPubdata: BigInt = BigInt(160000), customSignature: Data? = nil, paymaster: Paymaster? = nil, factoryDeps: [Data]? = nil) {
        self.ergsPerPubdata = ergsPerPubdata
        self.customSignature = customSignature
        self.paymaster = paymaster
        self.factoryDeps = factoryDeps
      }
    }
    
    internal var _maxPriorityFeePerErg: BigInt
    public var maxPriorityFeePerErg: Data {
      return _maxPriorityFeePerErg.data
    }
    
    internal var _maxFeePerErg: BigInt
    public var maxFeePerErg: Data {
      return _maxFeePerErg.data
    }
    internal var _ergsLimit: BigInt { _gasLimit }
    public var meta: Meta
    
    internal var _eip712Message: TypedMessage {
      get throws {
        guard let chainID = chainID else { throw TransactionSignError.invalidChainId }
        let input: [[String: AnyObject]] = [[
          "txType": Int(self.eipType.rawValue.stringRemoveHexPrefix(), radix: 16) as AnyObject,
          "from": (from?.address ?? "") as AnyObject,
          "to": (to?.address ?? "") as AnyObject,
          "ergsLimit": _ergsLimit as AnyObject,
          "ergsPerPubdataByteLimit": meta.ergsPerPubdata as AnyObject,
          "maxFeePerErg": _maxFeePerErg as AnyObject,
          "maxPriorityFeePerErg": _maxPriorityFeePerErg as AnyObject,
          "paymaster": (meta.paymaster?.paymaster.address ?? "") as AnyObject,
          "nonce": _nonce as AnyObject,
          "value": _value as AnyObject,
          "data": data as AnyObject,
          "factoryDeps": (meta.factoryDeps ?? []) as AnyObject,
          "paymasterInput": (meta.paymaster?.input ?? Data()) as AnyObject
        ]]
        
        return TypedMessage(types: ZKSync.EIP712Message.types,
                            primaryType: "Transaction",
                            domain: ZKSync.EIP712Message.domain(with: Int(chainID.decimalString)),
                            message: input,
                            version: .v4)
      }
    }
    
    init(
      nonce: BigInt = BigInt(0x00),
      maxPriorityFeePerErg: BigInt = BigInt(0x00),
      maxFeePerErg: BigInt = BigInt(0x00),
      ergsLimit: BigInt = BigInt(0x00),
      from: Address? = nil,
      to: Address?,
      value: BigInt = BigInt(0x00),
      data: Data = Data(),
      chainID: BigInt? = nil,
      meta: Meta = Meta()
    ) {
      _maxPriorityFeePerErg = maxPriorityFeePerErg
      _maxFeePerErg = maxFeePerErg
      self.meta = meta
      
      super.init(
        nonce: nonce,
        gasLimit: ergsLimit,
        from: from,
        to: to,
        value: value,
        data: data,
        chainID: chainID,
        eipType: .eip712
      )
    }
    
    public convenience init(
      nonce: Data = Data([0x00]),
      maxPriorityFeePerErg: Data = Data([0x00]),
      maxFeePerErg: Data = Data([0x00]),
      ergsLimit: Data = Data([0x00]),
      from: Address? = nil,
      to: Address?,
      value: Data = Data([0x00]),
      data: Data = Data(),
      chainID: Data?,
      meta: Meta = Meta()
    ) {
      if let chainID = chainID {
        self.init(
          nonce: BigInt(data: nonce),
          maxPriorityFeePerErg: BigInt(data: maxPriorityFeePerErg),
          maxFeePerErg: BigInt(data: maxFeePerErg),
          from: from,
          to: to,
          value: BigInt(data: value),
          data: data,
          chainID: BigInt(data: chainID),
          meta: meta
        )
      } else {
        self.init(
          nonce: BigInt(data: nonce),
          maxPriorityFeePerErg: BigInt(data: maxPriorityFeePerErg),
          maxFeePerErg: BigInt(data: maxFeePerErg),
          ergsLimit: BigInt(data: ergsLimit),
          from: from,
          to: to,
          value: BigInt(data: value),
          data: data,
          chainID: nil,
          meta: meta
        )
      }
    }
    
    public convenience init(
      nonce: String = "0x00",
      maxPriorityFeePerErg: String = "0x00",
      maxFeePerErg: String = "0x00",
      ergsLimit: String = "0x00",
      from: Address? = nil,
      to: Address?,
      value: String = "0x00",
      data: Data,
      chainID: Data? = nil,
      meta: Meta = Meta()
    ) throws {
      let nonce = BigInt(Data(hex: nonce.stringWithAlignedHexBytes()).bytes)
      let maxPriorityFeePerErg = BigInt(Data(hex: maxPriorityFeePerErg.stringWithAlignedHexBytes()).bytes)
      let maxFeePerErg = BigInt(Data(hex: maxFeePerErg.stringWithAlignedHexBytes()).bytes)
      let ergsLimit = BigInt(Data(hex: ergsLimit.stringWithAlignedHexBytes()).bytes)
      let value = BigInt(Data(hex: value.stringWithAlignedHexBytes()).bytes)
      if let chainID = chainID {
        self.init(
          nonce: nonce,
          maxPriorityFeePerErg: maxPriorityFeePerErg,
          maxFeePerErg: maxFeePerErg,
          ergsLimit: ergsLimit,
          from: from,
          to: to,
          value: value,
          data: data,
          chainID: BigInt(data: chainID),
          meta: meta
        )
      } else {
        self.init(
          nonce: nonce,
          maxPriorityFeePerErg: maxPriorityFeePerErg,
          maxFeePerErg: maxFeePerErg,
          ergsLimit: ergsLimit,
          from: from,
          to: to,
          value: value,
          data: data,
          meta: meta
        )
      }
    }
    
    public convenience init(
      nonce: Decimal? = nil,
      maxPriorityFeePerErg: Decimal?,
      maxFeePerErg: Decimal?,
      ergsLimit: Decimal?,
      from: Address? = nil,
      to: Address?,
      value: Decimal?,
      data: Data,
      chainID: Data? = nil,
      meta: Meta = Meta()
    ) throws {
      let nonceBigInt: BigInt
      let maxPriorityFeePerErgBigInt: BigInt
      let maxFeePerErgBigInt: BigInt
      let ergsLimitBigInt: BigInt
      let valueBigInt: BigInt
      
      if let nonceString = (nonce as NSDecimalNumber?)?.stringValue, !nonceString.isEmpty {
        nonceBigInt = BigInt(nonceString) ?? BigInt(0x00)
      } else {
        nonceBigInt = BigInt(0x00)
      }
      
      if let maxPriorityFeePerErgString = (maxPriorityFeePerErg as NSDecimalNumber?)?.stringValue {
        maxPriorityFeePerErgBigInt = BigInt(maxPriorityFeePerErgString) ?? BigInt(0x00)
      } else {
        maxPriorityFeePerErgBigInt = BigInt(0x00)
      }
      
      if let maxFeePerErgString = (maxFeePerErg as NSDecimalNumber?)?.stringValue {
        maxFeePerErgBigInt = BigInt(maxFeePerErgString) ?? BigInt(0x00)
      } else {
        maxFeePerErgBigInt = BigInt(0x00)
      }
      
      if let ergsLimitString = (ergsLimit as NSDecimalNumber?)?.stringValue {
        ergsLimitBigInt = BigInt(ergsLimitString) ?? BigInt(0x00)
      } else {
        ergsLimitBigInt = BigInt(0x00)
      }
      
      if let valueString = (value as NSDecimalNumber?)?.stringValue {
        valueBigInt = BigInt(valueString) ?? BigInt(0x00)
      } else {
        valueBigInt = BigInt(0x00)
      }
      
      if let chainID = chainID {
        self.init(
          nonce: nonceBigInt,
          maxPriorityFeePerErg: maxPriorityFeePerErgBigInt,
          maxFeePerErg: maxFeePerErgBigInt,
          ergsLimit: ergsLimitBigInt,
          from: from,
          to: to,
          value: valueBigInt,
          data: data,
          chainID: BigInt(data: chainID),
          meta: meta
        )
      } else {
        self.init(
          nonce: nonceBigInt,
          maxPriorityFeePerErg: maxPriorityFeePerErgBigInt,
          maxFeePerErg: maxFeePerErgBigInt,
          ergsLimit: ergsLimitBigInt,
          from: from,
          to: to,
          value: valueBigInt,
          data: data,
          meta: meta
        )
      }
    }

    public override var debugDescription: String {
      var description = "Transaction\n"
      description += "EIPType: \(self.eipType.data.toHexString())\n"
      description += "Nonce: \(self._nonce.data.toHexString())\n"
      description += "Max Priority Fee Per Erg: \(self._maxPriorityFeePerErg.data.toHexString())\n"
      description += "Max Fee Per Erg: \(self._maxFeePerErg.data.toHexString())\n"
      description += "Ergs Limit: \(self._gasLimit.data.toHexString())\n"
      description += "From: \(String(describing: self.from)) \n"
      description += "To: \(self.to?.address ?? "")\n"
      description += "Value: \(self._value.data.toHexString())\n"
      description += "Data: \(self.data.toHexString())\n"
      description += "ChainID: \(self.chainID?.data.toHexString() ?? "none")\n"
      description += "\(self.signature?.debugDescription ?? "Signature: none")\n"
      description += "Hash: \(self.hash()?.toHexString() ?? "none")"
      description += "Paymaster: \(self.meta.paymaster?.paymaster.address ?? "none")"
      return description
    }
    
    //
    // Creates and returns rlp array with order:
    // RLP([nonce, maxPriorityFeePerErg, maxFeePerErg, ergsLimit, to? || "", value, input, (signatureYParity, signatureR, signatureS) || (chainID, "", ""), chainID, from, ergPerPubdata, factoryDeps || [], customSignature || Data(), [paymaster, paymasterInput] || []])
    //
    internal override func rlpData(chainID: BigInt? = nil, forSignature: Bool = false) -> [RLP] {
      guard !forSignature else {
        return []
      }
      guard let chainID = chainID else {
        return []
      }
      
      // 1: nonce
      // 2: maxPriorityFeePerErg
      // 3: maxFeePerErg
      // 4: ergsLimit
      var fields: [RLP] = [
        _nonce.toRLP(),
        _maxPriorityFeePerErg.toRLP(),
        _maxFeePerErg.toRLP(),
        _ergsLimit.toRLP(),
      ]
      
      // 5: to || 0x
      if let address = to?.address {
        fields.append(address)
      } else {
        fields.append("")
      }
      
      // 6: value
      // 7: input
      fields += [_value.toRLP(), data]
      
      // 8: ([yParity, r, s] || (chainID, "", "")
      if let signature = signature, !forSignature {
        fields += [signature.signatureYParity, signature.r, signature.s]
      } else {
        fields.append(chainID.toRLP())
        fields.append("")
        fields.append("")
      }
      // 9: chainID
      // 10: from
      // 11: ergsPerPubdata
      fields.append(chainID.toRLP())
      fields.append(from!.address)
      fields.append(meta.ergsPerPubdata.toRLP())
      
      // 12: factoryDeps
      fields.append((meta.factoryDeps ?? []) as [RLP])
      
      // 13: Signature
      fields.append(meta.customSignature ?? Data())
      
      // 14: Paymaster
      if let paymaster = meta.paymaster {
        fields.append([paymaster.paymaster.address, paymaster.input ?? Data()])
      } else {
        fields.append([] as [RLP])
      }
      return fields
    }
  }
}
