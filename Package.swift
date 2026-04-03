// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "sebbu-bitstream",
    platforms: [
        .macOS(.v11), .iOS(.v13), .watchOS(.v10), .tvOS(.v12)
    ],
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
