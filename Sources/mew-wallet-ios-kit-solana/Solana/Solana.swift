//
//  File.swift
//  mew-wallet-ios-kit
//
//  Created by Mikhail Nikanorov on 8/8/25.
//

import Foundation

/// Root namespace for all Solana-related models, encoders, and instruction factories.
///
/// This empty enum is used as a namespace to organize Solana-specific submodules
/// without polluting the global scope.
///
/// ### Purpose
/// - Prevents accidental symbol conflicts with other blockchain modules (e.g., Ethereum, Bitcoin).
/// - Groups related Solana types logically, e.g.:
///   - `Solana.SystemProgram`
///   - `Solana.TokenProgram`
///   - `Solana.StakeProgram`
///   - `Solana.ComputeBudgetProgram`
///   - `Solana.AssociatedTokenProgram`
///   - `Solana.ShortVecEncoder`
///
/// ### Usage
/// ```swift
/// let tx = Solana.SystemProgram.transfer(params: ...)
/// ```
///
/// The enum is marked `public` so it can be imported and used by external modules
/// like `mew_wallet_ios_kit_solana` or higher-level transaction builders.
public enum Solana { }
