// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ARImagePlacement",
    platforms: [
        .iOS(.v18),
        .visionOS(.v2),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ARImagePlacement",
            targets: ["ARImagePlacement"]
        )
    ],
    targets: [
        .target(
            name: "ARImagePlacement",
            dependencies: []
        ),
        .testTarget(
            name: "ARImagePlacementTests",
            dependencies: ["ARImagePlacement"]
        )
    ]
)
