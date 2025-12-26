// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwiftUIMeasure",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(
            name: "SwiftUIMeasure",
            targets: ["SwiftUIMeasure"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftUIMeasure",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SwiftUIMeasureTests",
            dependencies: ["SwiftUIMeasure"]
        ),
    ]
)
