// swift-tools-version:5.8
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
        .package(url: "https://github.com/apple/swift-syntax", from: "510.0.1"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.1"),
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
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "SwiftStringObfuscatorTests",
            dependencies: ["SwiftStringObfuscatorCore"]
        ),
    ]
)
