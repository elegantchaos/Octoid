// swift-tools-version:5.6

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
        .package(url: "https://github.com/elegantchaos/CollectionExtensions.git", from: "1.1.1"),
        .package(url: "https://github.com/elegantchaos/Logger.git", from: "1.6.0"),
        .package(url: "https://github.com/elegantchaos/JSONSession.git", from: "1.1.1"),
        .package(url: "https://github.com/elegantchaos/XCTestExtensions.git", from: "1.3.2"),
    ],
    targets: [
        .target(
            name: "Octoid",
            dependencies: [
                "CollectionExtensions",
                "Logger",
                "JSONSession"
            ]),
        .testTarget(
            name: "OctoidTests",
            dependencies: ["Octoid", "XCTestExtensions"],
            resources: [
                .process("Resources")
            ]
        ),
    ]
)
