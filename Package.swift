// swift-tools-version:6.2

import PackageDescription

let package = Package(
  name: "Octoid",
  platforms: [
    .macOS(.v26), .macCatalyst(.v26), .iOS(.v26), .tvOS(.v26), .watchOS(.v11),
  ],
  products: [
    .library(
      name: "Octoid",
      targets: ["Octoid"])
  ],
  dependencies: [
    .package(url: "https://github.com/elegantchaos/Logger.git", from: "2.0.1"),
    .package(url: "https://github.com/elegantchaos/JSONSession.git", from: "2.0.0"),
    .package(url: "https://github.com/elegantchaos/ActionBuilderPlugin.git", from: "2.1.2"),
  ],
  targets: [
    .target(
      name: "Octoid",
      dependencies: [
        "Logger",
        "JSONSession",
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
