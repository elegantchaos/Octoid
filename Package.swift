// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "Octoid",
    platforms: [
        .macOS(.v10_15), .macCatalyst(.v13), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)
    ],
    products: [
        .library(
            name: "Octoid",
            targets: ["Octoid"]),
    ],
    dependencies: [
        .package(url: "https://github.com/elegantchaos/Logger.git", from: "1.6.0"),
        .package(url: "https://github.com/elegantchaos/JSONSession.git", from: "1.1.1"),
    ],
    targets: [
        .target(
            name: "Octoid",
            dependencies: [
                "Logger",
                "JSONSession"
            ]),
        .testTarget(
            name: "OctoidTests",
            dependencies: ["Octoid"],
            resources: [
                .process("Resources")
            ]
        ),
    ],
    swiftLanguageModes: [.v5]
)
