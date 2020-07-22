// swift-tools-version:5.2

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
        .package(url: "https://github.com/elegantchaos/Logger.git", from: "1.5.5"),
        .package(url: "https://github.com/elegantchaos/JSONSession.git", from: "1.0.2"),
        .package(url: "https://github.com/elegantchaos/XCTestExtensions.git", from: "1.1.1"),
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
            dependencies: ["Octoid", "XCTestExtensions"]),
    ]
)
