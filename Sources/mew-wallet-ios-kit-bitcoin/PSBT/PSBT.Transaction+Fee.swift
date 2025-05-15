//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 5/7/25.
//

import Foundation

extension PSBT.Transaction {
  public enum FeeError: Error, Equatable {
    /// An input had no UTXO attached (neither non-witness nor witness).
    case missingUTXO(index: Int)
    /// A non-witness UTXO referred to an out-of-bounds vout.
    case invalidVout(index: Int, vout: UInt32)
    /// Sum of inputs was smaller than sum of outputs (should never happen in a valid PSBT).
    case negativeFee
  }
  
  /// Returns the transaction fee in satoshis:
  /// ∑(input UTXO values) − ∑(unsigned tx outputs).
  ///
  /// - Throws:
  ///   - `PSBT.FeeError.missingUTXO` if an input has no UTXO attached.
  ///   - `PSBT.FeeError.invalidVout` if a non-witness UTXO’s `vout` is out of range.
  ///   - `PSBT.FeeError.negativeFee` if inputs sum to less than outputs.
  public var fee: UInt64 {
    get throws(PSBT.Transaction.FeeError) {
      // 1) sum up all input values
      var totalIn: UInt64 = 0
      for (i, inp) in inputs.enumerated() {
        switch inp.utxo {
        case .witnessUTXO(let out):
          totalIn &+= out.value
          
        case .nonWitnessUTXO(let prevTx):
          // grab the vout index from the global unsigned tx's outpoint
          let outpoint = tx.inputs[i].outpoint
          guard Int(outpoint.vout) < prevTx.outputs.count else {
            throw PSBT.Transaction.FeeError.invalidVout(index: i, vout: outpoint.vout)
          }
          totalIn &+= prevTx.outputs[Int(outpoint.vout)].value
          
        case .finalScriptSig, .none:
          throw PSBT.Transaction.FeeError.missingUTXO(index: i)
        }
      }
      
      // 2) sum all outputs in the unsigned transaction
      let totalOut: UInt64 = tx.outputs.reduce(0) { $0 &+ $1.value }
      
      // 3) fee = inputs − outputs
      guard totalIn >= totalOut else {
        throw PSBT.Transaction.FeeError.negativeFee
      }
      return totalIn - totalOut
    }
  }
}
