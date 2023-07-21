// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "sebbu-bitstream",
    products: [
        .library(name: "SebbuBitStream", targets: ["SebbuBitStream"]),
        .library(name: "SebbuBitStreamFoundation", targets: ["SebbuBitStreamFoundation"])
    ],
    targets: [
        .target(name: "SebbuBitStream"),
        .target(name: "SebbuBitStreamFoundation", dependencies: ["SebbuBitStream"]),
        .testTarget(name: "SebbuBitStreamTests", dependencies: ["SebbuBitStream", "SebbuBitStreamFoundation"]),
    ]
)
