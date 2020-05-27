// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Octoid",
    platforms: [
        .macOS(.v10_15), .iOS(.v12), .tvOS(.v12), .watchOS(.v5)
    ],
    products: [
        .library(
            name: "Octoid",
            targets: ["Octoid"]),
    ],
    dependencies: [
        .package(url: "https://github.com/elegantchaos/Logger.git", from: "1.5.5"),
    ],
    targets: [
        .target(
            name: "Octoid",
            dependencies: ["Logger"]),
        .testTarget(
            name: "OctoidTests",
            dependencies: ["Octoid"]),
    ]
)
