// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Octoid",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v5)
    ],
    products: [
        .library(
            name: "Octoid",
            targets: ["Octoid"]),
    ],
    dependencies: [
        .package(url: "https://github.com/elegantchaos/CollectionExtensions.git", from: "1.0.3"),
        .package(url: "https://github.com/elegantchaos/Logger.git", from: "1.5.5"),
        .package(url: "https://github.com/elegantchaos/JSONSession.git", from: "1.0.3"),
        .package(url: "https://github.com/elegantchaos/XCTestExtensions.git", from: "1.1.1"),
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
            resources: [.copy("Resources")]
        ),
    ]
)
