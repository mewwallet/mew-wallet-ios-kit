// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "mew-wallet-ios-kit",
  platforms: [
    .iOS(.v11),
    .macOS(.v10_13)
  ],
  products: [
    .library(
      name: "mew-wallet-ios-kit",
      targets: ["mew-wallet-ios-kit"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "1.4.2")),
    .package(url: "https://github.com/attaswift/BigInt.git", from: "5.2.1"),
    .package(url: "https://github.com/mewwallet/mew-wallet-ios-secp256k1.git", .exact("1.0.4")),
    .package(url: "https://github.com/mewwallet/bls-eth-swift.git", .exact("1.0.2")),
    .package(url: "https://github.com/mewwallet/mew-wallet-ios-tweetnacl.git", .upToNextMajor(from: "1.0.2")),
    .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "3.0.0")),
    .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "9.0.0"))
  ],
  targets: [
    .target(
      name: "mew-wallet-ios-kit",
      dependencies: ["CryptoSwift", "mew-wallet-ios-secp256k1", "bls-eth-swift", "mew-wallet-ios-tweetnacl", "BigInt"],
      path: "Sources"
    ),
    .testTarget(
      name: "mew-wallet-ios-kit-tests",
      dependencies: ["mew-wallet-ios-kit", "Quick", "Nimble"],
      path: "Tests/Sources"
    )
  ],
  swiftLanguageVersions: [.v4, .v4_2, .v5]
)
