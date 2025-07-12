//
//  File.swift
//  
//
//  Created by Mikhail Nikanorov on 1/18/23.
//

import Foundation
import BigInt
import CryptoSwift

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
          .init(name: "gasLimit",                 type: "uint256"),
          .init(name: "gasPerPubdataByteLimit",   type: "uint256"),
          .init(name: "maxFeePerGas",             type: "uint256"),
          .init(name: "maxPriorityFeePerGas",     type: "uint256"),
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
      
      public var gasPerPubdata = BigInt(50000) //DEFAULT_GAS_PER_PUBDATA_LIMIT
      public var customSignature: Data? = nil
      public var paymaster: Paymaster? = nil
      public var factoryDeps: [Data]? = nil
      
      public init(gasPerPubdata: BigInt = BigInt(50000), customSignature: Data? = nil, paymaster: Paymaster? = nil, factoryDeps: [Data]? = nil) {
        self.gasPerPubdata = gasPerPubdata
        self.customSignature = customSignature
        self.paymaster = paymaster
        self.factoryDeps = factoryDeps
      }
    }
    
    internal var _maxPriorityFeePerGas: BigInt
    public var maxPriorityFeePerGas: Data {
      return _maxPriorityFeePerGas.data
    }
    
    internal var _maxFeePerGas: BigInt
    public var maxFeePerGas: Data {
      return _maxFeePerGas.data
    }
    public var meta: Meta
    
    internal var _eip712Message: TypedMessage {
      get throws {
        guard let chainID = chainID else { throw TransactionSignError.invalidChainId }
        let input: [[String: AnyObject]] = [[
          "txType":                   Int(self.eipType.rawValue.stringRemoveHexPrefix(), radix: 16) as AnyObject,
          "from":                     (from?.address ?? "") as AnyObject,
          "to":                       (to?.address ?? "") as AnyObject,
          "gasLimit":                 _gasLimit as AnyObject,
          "gasPerPubdataByteLimit":   meta.gasPerPubdata as AnyObject,
          "maxFeePerGas":             _maxFeePerGas as AnyObject,
          "maxPriorityFeePerGas":     _maxPriorityFeePerGas as AnyObject,
          "paymaster":                (meta.paymaster?.paymaster.address ?? "") as AnyObject,
          "nonce":                    _nonce as AnyObject,
          "value":                    _value as AnyObject,
          "data":                     data as AnyObject,
          "factoryDeps":              (meta.factoryDeps ?? []) as AnyObject,
          "paymasterInput":           (meta.paymaster?.input ?? Data()) as AnyObject
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
      maxPriorityFeePerGas: BigInt = BigInt(0x00),
      maxFeePerGas: BigInt = BigInt(0x00),
      gasLimit: BigInt = BigInt(0x00),
      from: Address? = nil,
      to: Address?,
      value: BigInt = BigInt(0x00),
      data: Data = Data(),
      chainID: BigInt? = nil,
      meta: Meta = Meta()
    ) {
      _maxPriorityFeePerGas = maxPriorityFeePerGas
      _maxFeePerGas = maxFeePerGas
      self.meta = meta
      
      super.init(
        nonce: nonce,
        gasLimit: gasLimit,
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
      maxPriorityFeePerGas: Data = Data([0x00]),
      maxFeePerGas: Data = Data([0x00]),
      gasLimit: Data = Data([0x00]),
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
          maxPriorityFeePerGas: BigInt(data: maxPriorityFeePerGas),
          maxFeePerGas: BigInt(data: maxFeePerGas),
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
          maxPriorityFeePerGas: BigInt(data: maxPriorityFeePerGas),
          maxFeePerGas: BigInt(data: maxFeePerGas),
          gasLimit: BigInt(data: gasLimit),
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
      maxPriorityFeePerGas: String = "0x00",
      maxFeePerGas: String = "0x00",
      gasLimit: String = "0x00",
      from: Address? = nil,
      to: Address?,
      value: String = "0x00",
      data: Data,
      chainID: Data? = nil,
      meta: Meta = Meta()
    ) throws {
      let nonce = BigInt(Data(hex: nonce.stringWithAlignedHexBytes()).byteArray)
      let maxPriorityFeePerGas = BigInt(Data(hex: maxPriorityFeePerGas.stringWithAlignedHexBytes()).byteArray)
      let maxFeePerGas = BigInt(Data(hex: maxFeePerGas.stringWithAlignedHexBytes()).byteArray)
      let gasLimit = BigInt(Data(hex: gasLimit.stringWithAlignedHexBytes()).byteArray)
      let value = BigInt(Data(hex: value.stringWithAlignedHexBytes()).byteArray)
      if let chainID = chainID {
        self.init(
          nonce: nonce,
          maxPriorityFeePerGas: maxPriorityFeePerGas,
          maxFeePerGas: maxFeePerGas,
          gasLimit: gasLimit,
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
          maxPriorityFeePerGas: maxPriorityFeePerGas,
          maxFeePerGas: maxFeePerGas,
          gasLimit: gasLimit,
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
      maxPriorityFeePerGas: Decimal?,
      maxFeePerGas: Decimal?,
      gasLimit: Decimal?,
      from: Address? = nil,
      to: Address?,
      value: Decimal?,
      data: Data,
      chainID: Data? = nil,
      meta: Meta = Meta()
    ) throws {
      let nonceBigInt: BigInt
      let maxPriorityFeePerGasBigInt: BigInt
      let maxFeePerGasBigInt: BigInt
      let gasLimitBigInt: BigInt
      let valueBigInt: BigInt
      
      if let nonceString = (nonce as NSDecimalNumber?)?.stringValue, !nonceString.isEmpty {
        nonceBigInt = BigInt(nonceString) ?? BigInt(0x00)
      } else {
        nonceBigInt = BigInt(0x00)
      }
      
      if let maxPriorityFeePerGasString = (maxPriorityFeePerGas as NSDecimalNumber?)?.stringValue {
        maxPriorityFeePerGasBigInt = BigInt(maxPriorityFeePerGasString) ?? BigInt(0x00)
      } else {
        maxPriorityFeePerGasBigInt = BigInt(0x00)
      }
      
      if let maxFeePerGasString = (maxFeePerGas as NSDecimalNumber?)?.stringValue {
        maxFeePerGasBigInt = BigInt(maxFeePerGasString) ?? BigInt(0x00)
      } else {
        maxFeePerGasBigInt = BigInt(0x00)
      }
      
      if let gasLimitString = (gasLimit as NSDecimalNumber?)?.stringValue {
        gasLimitBigInt = BigInt(gasLimitString) ?? BigInt(0x00)
      } else {
        gasLimitBigInt = BigInt(0x00)
      }
      
      if let valueString = (value as NSDecimalNumber?)?.stringValue {
        valueBigInt = BigInt(valueString) ?? BigInt(0x00)
      } else {
        valueBigInt = BigInt(0x00)
      }
      
      if let chainID = chainID {
        self.init(
          nonce: nonceBigInt,
          maxPriorityFeePerGas: maxPriorityFeePerGasBigInt,
          maxFeePerGas: maxFeePerGasBigInt,
          gasLimit: gasLimitBigInt,
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
          maxPriorityFeePerGas: maxPriorityFeePerGasBigInt,
          maxFeePerGas: maxFeePerGasBigInt,
          gasLimit: gasLimitBigInt,
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
      description += "Max Priority Fee Per Gas: \(self._maxPriorityFeePerGas.data.toHexString())\n"
      description += "Max Fee Per Gas: \(self._maxFeePerGas.data.toHexString())\n"
      description += "Gas Limit: \(self._gasLimit.data.toHexString())\n"
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
    // RLP([nonce, maxPriorityFeePerGas, maxFeePerGas, gasLimit, to? || "", value, input, (signatureYParity, signatureR, signatureS) || (chainID, "", ""), chainID, from, gasPerPubdata, factoryDeps || [], customSignature || Data(), [paymaster, paymasterInput] || []])
    //
    internal override func rlpData(chainID: BigInt? = nil, forSignature: Bool = false) -> [RLP] {
      guard !forSignature else {
        return []
      }
      guard let chainID = chainID else {
        return []
      }
      
      // 1: nonce
      // 2: maxPriorityFeePerGas
      // 3: maxFeePerGas
      // 4: gasLimit
      var fields: [RLP] = [
        _nonce.toRLP(),
        _maxPriorityFeePerGas.toRLP(),
        _maxFeePerGas.toRLP(),
        _gasLimit.toRLP(),
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
      // 11: gasPerPubdata
      fields.append(chainID.toRLP())
      fields.append(from!.address)
      fields.append(meta.gasPerPubdata.toRLP())
      
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
