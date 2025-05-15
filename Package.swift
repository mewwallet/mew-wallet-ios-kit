// swift-tools-version:6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "mew-wallet-ios-kit",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_13)
  ],
  products: [
    .library(
      name: "mew-wallet-ios-kit",
      targets: ["mew-wallet-ios-kit"]
    ),
    .library(
      name: "mew-wallet-ios-kit-bitcoin",
      targets: ["mew-wallet-ios-kit-bitcoin"]
    ),
    .library(
      name: "mew-wallet-ios-kit-bitcoin-sign",
      targets: ["mew-wallet-ios-kit-bitcoin-sign"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "1.4.2")),
    .package(url: "https://github.com/attaswift/BigInt.git", from: "5.5.0"),
    .package(url: "https://github.com/mewwallet/mew-wallet-ios-secp256k1.git", exact: "1.0.4"),
    .package(url: "https://github.com/mewwallet/bls-eth-swift.git", exact: "1.0.2"),
    .package(url: "https://github.com/mewwallet/mew-wallet-ios-tweetnacl.git", .upToNextMajor(from: "1.0.2")),
    .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "3.0.0")),
    .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "9.0.0"))
  ],
  targets: [
    // Main evm target
    .target(
      name: "mew-wallet-ios-kit",
      dependencies: [
        "CryptoSwift",
        "mew-wallet-ios-secp256k1",
        "mew-wallet-ios-tweetnacl",
        "BigInt",
        .product(name: "bls-eth-swift", package: "bls-eth-swift", condition: .when(platforms: [.iOS, .macOS, .macCatalyst]))
      ],
      path: "Sources/mew-wallet-ios-kit"
    ),
    
    // Bitcoin target
    .target(
      name: "mew-wallet-ios-kit-bitcoin",
      dependencies: [
        "CryptoSwift"
      ],
      path: "Sources/mew-wallet-ios-kit-bitcoin"
    ),
    
    // Bitcoin signing
    .target(
      name: "mew-wallet-ios-kit-bitcoin-sign",
      dependencies: [
        "mew-wallet-ios-kit",
        "mew-wallet-ios-kit-bitcoin",
      ],
      path: "Sources/mew-wallet-ios-kit-bitcoin-sign"
    )
  ],
  swiftLanguageModes: [.v4, .v4_2, .v5, .v6]
)

// MARK: - Test targets

// MARK: mew-wallet-ios-kit-tests
package.targets.append(
  .testTarget(
    name: "mew-wallet-ios-kit-tests",
    dependencies: [
      "mew-wallet-ios-kit",
      "Quick",
      "Nimble"
    ],
    path: "Tests/mew-wallet-ios-kit"
  )
)

// MARK: - mew-wallet-ios-kit-bitcoin-sign-tests
package.targets.append(
  .testTarget(
    name: "mew-wallet-ios-kit-bitcoin-sign-tests",
    dependencies: [
      "mew-wallet-ios-kit-bitcoin-sign"
    ],
    path: "Tests/mew-wallet-ios-kit-bitcoin-sign-tests"
  )
)

// MARK: mew-wallet-ios-bitcoin-tests
package.targets.append(
  .testTarget(
    name: "mew-wallet-ios-kit-bitcoin-tests",
    dependencies: [
      "mew-wallet-ios-kit-bitcoin",
      "CryptoSwift",
    ],
    path: "Tests/mew-wallet-ios-kit-bitcoin"
  )
)
