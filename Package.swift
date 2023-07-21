// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "sebbu-bitstream",
    products: [
        .library(
            name: "SebbuBitStream",
            targets: ["SebbuBitStream"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SebbuBitStream"),
        .testTarget(
            name: "SebbuBitStreamTests",
            dependencies: ["SebbuBitStream"]),
    ]
)
