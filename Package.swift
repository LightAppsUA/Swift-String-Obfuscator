// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "SwiftStringObfuscator",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .executable(name: "swift_string_obfuscator", targets: ["swift_string_obfuscator"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax", from: "508.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.2")
    ],
    targets: [
        .executableTarget(
            name: "swift_string_obfuscator",
            dependencies: [
                "SwiftStringObfuscatorCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "SwiftStringObfuscatorCore",
            dependencies: [
                .product(name: "SwiftSyntaxParser", package: "swift-syntax")
            ]
        ),
        .testTarget(
            name: "SwiftStringObfuscatorTests",
            dependencies: ["SwiftStringObfuscatorCore"]
        ),
    ]
)
