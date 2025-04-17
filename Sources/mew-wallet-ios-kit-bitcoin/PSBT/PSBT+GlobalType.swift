//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 4/13/25.
//

import Foundation

extension PSBT {
  /// Enumerates all recognized global key types used in a Partially Signed Bitcoin Transaction (PSBT).
  ///
  /// These keys appear in the *global* key-value map section of a PSBT.
  public enum GlobalType: UInt8, Sendable {
    /// The unsigned transaction serialized without witnesses.
    case PSBT_GLOBAL_UNSIGNED_TX                  = 0x00
    
    /// An extended public key with derivation path.
    case PSBT_GLOBAL_XPUB                         = 0x01
    
    /// Transaction version (PSBTv2+).
    case PSBT_GLOBAL_TX_VERSION                   = 0x02
    
    /// Fallback locktime (used if no inputs specify one).
    case PSBT_GLOBAL_FALLBACK_LOCKTIME            = 0x03
    
    /// Input count for PSBTv2 transactions.
    case PSBT_GLOBAL_INPUT_COUNT                  = 0x04
    
    /// Output count for PSBTv2 transactions.
    case PSBT_GLOBAL_OUTPUT_COUNT                 = 0x05
    
    /// Transaction modifiability flags (PSBTv2).
    case PSBT_GLOBAL_TX_MODIFIABLE                = 0x06
    
    /// Silent Payments: shared ECDH key.
    case PSBT_GLOBAL_SP_ECDH_SHARE                = 0x07
    
    /// Silent Payments: DLEQ proof.
    case PSBT_GLOBAL_SP_DLEQ                      = 0x08
    
    /// PSBT format version (1 or 2).
    case PSBT_GLOBAL_VERSION                      = 0xFB
    
    /// Vendor-specific or application-defined extensions.
    case PSBT_GLOBAL_PROPRIETARY                  = 0xFC
  }
  
  
  /// Enumerates all standard input key types used in a PSBT input map.
  /// These keys provide metadata necessary to validate or sign a transaction input.
  /// Most are defined in BIP 174, BIP 370, BIP 340–342, and BIP 352.
  public enum InputType: UInt8, Sendable {
    /// The full previous transaction that created the referenced output (non-witness).
    case PSBT_IN_NON_WITNESS_UTXO                 = 0x00
    
    /// The output being spent, serialized as a `TxOut` (witness inputs only).
    case PSBT_IN_WITNESS_UTXO                     = 0x01
    
    /// A map of partial signatures (`<pubkey>: signature`).
    case PSBT_IN_PARTIAL_SIG                      = 0x02
    
    /// The SIGHASH type for the signature.
    case PSBT_IN_SIGHASH_TYPE                     = 0x03
    
    /// The redeem script used in P2SH or P2SH-wrapped inputs.
    case PSBT_IN_REDEEM_SCRIPT                    = 0x04
    
    /// The witness script used in P2WSH or nested SegWit.
    case PSBT_IN_WITNESS_SCRIPT                   = 0x05
    
    /// A map of BIP32 derivation paths for public keys involved in this input.
    case PSBT_IN_BIP32_DERIVATION                 = 0x06
    
    /// Final scriptSig to be used in the transaction, if fully signed.
    case PSBT_IN_FINAL_SCRIPTSIG                  = 0x07
    
    /// Final scriptWitness to be used in the transaction, if fully signed.
    case PSBT_IN_FINAL_SCRIPTWITNESS              = 0x08
    
    /// Proof of Reserves commitment (optional).
    case PSBT_IN_POR_COMMITMENT                   = 0x09
    
    /// RIPEMD160 preimage for script verification.
    case PSBT_IN_RIPEMD160                        = 0x0A
    
    /// SHA256 preimage for script verification.
    case PSBT_IN_SHA256                           = 0x0B
    
    /// HASH160 preimage for script verification.
    case PSBT_IN_HASH160                          = 0x0C
    
    /// HASH256 preimage for script verification.
    case PSBT_IN_HASH256                          = 0x0D
    
    /// Explicit transaction ID of the previous output (PSBTv2).
    case PSBT_IN_PREVIOUS_TXID                    = 0x0E
    
    /// Output index of the previous output (PSBTv2).
    case PSBT_IN_OUTPUT_INDEX                     = 0x0F
    
    /// Sequence number to be used in the final transaction (PSBTv2).
    case PSBT_IN_SEQUENCE                         = 0x10
    
    /// Required absolute time-based locktime for this input.
    case PSBT_IN_REQUIRED_TIME_LOCKTIME           = 0x11
    
    /// Required absolute block-height-based locktime for this input.
    case PSBT_IN_REQUIRED_HEIGHT_LOCKTIME         = 0x12

    /// Taproot key path signature (BIP 340).
    case PSBT_IN_TAP_KEY_SIG                      = 0x13
    
    /// Taproot script path signatures.
    case PSBT_IN_TAP_SCRIPT_SIG                   = 0x14
    
    /// Taproot script leaves.
    case PSBT_IN_TAP_LEAF_SCRIPT                  = 0x15
    
    /// Taproot BIP32 derivation for key-path spending.
    case PSBT_IN_TAP_BIP32_DERIVATION             = 0x16
    
    /// The untweaked internal key used in Taproot.
    case PSBT_IN_TAP_INTERNAL_KEY                 = 0x17
    
    /// Merkle root of Taproot script tree.
    case PSBT_IN_TAP_MERKLE_ROOT                  = 0x18
    
    /// List of participant public keys for MuSig2 signing session.
    case PSBT_IN_MUSIG2_PARTICIPANT_PUBKEYS       = 0x1A

    /// Public nonce for MuSig2 signing.
    case PSBT_IN_MUSIG2_PUB_NONCE                 = 0x1B
    
    /// MuSig2 partial signature from a participant.
    case PSBT_IN_MUSIG2_PARTIAL_SIG               = 0x1C
    
    /// Shared ECDH point used in Silent Payments (BIP 352).
    case PSBT_IN_SP_ECDH_SHARE                    = 0x1D
    
    /// DLEQ proof for verifying shared secret in Silent Payments.
    case PSBT_IN_SP_DLEQ                          = 0x1E

    /// Custom, application-specific key.
    case PSBT_IN_PROPRIETARY                      = 0xFC
  }
  
  /// Enumerates all standard output key types used in a PSBT output map.
  /// These keys define how a new output should be constructed, and additional metadata.
  /// Defined in BIP 174, BIP 370, BIP 342, and BIP 352.
  public enum OutputType: UInt8, Sendable {
    /// Redeem script for P2SH-based outputs.
    case PSBT_OUT_REDEEM_SCRIPT                   = 0x00
    
    /// Witness script for P2WSH-based outputs.
    case PSBT_OUT_WITNESS_SCRIPT                  = 0x01
    
    /// BIP32 derivation path associated with output keys.
    case PSBT_OUT_BIP32_DERIVATION                = 0x02
    
    /// Explicit amount in satoshis for the output (PSBTv2).
    case PSBT_OUT_AMOUNT                          = 0x03
    
    /// The scriptPubKey for this output.
    case PSBT_OUT_SCRIPT                          = 0x04
    
    /// Taproot internal key before tweaking.
    case PSBT_OUT_TAP_INTERNAL_KEY                = 0x05
    
    /// Taproot script tree representation.
    case PSBT_OUT_TAP_TREE                        = 0x06
    
    /// BIP32 derivation path for Taproot output key.
    case PSBT_OUT_TAP_BIP32_DERIVATION            = 0x07
    
    /// Public keys of MuSig2 participants for this output.
    case PSBT_OUT_MUSIG2_PARTICIPANT_PUBKEYS      = 0x08
    
    /// Silent Payments metadata (e.g. for recipient recovery).
    case PSBT_OUT_SP_V0_INFO                      = 0x09
    
    /// Human-readable label for Silent Payment.
    case PSBT_OUT_SP_V0_LABEL                     = 0x0A
    
    /// DNSSEC proof blob (experimental).
    case PSBT_OUT_DNSSEC_PROOF                    = 0x35
    
    /// Custom, application-specific key.
    case PSBT_OUT_PROPRIETARY                     = 0xFC
  }
}
