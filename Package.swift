// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ARImagePlacement",
    platforms: [
       .iOS(.v26),
        .visionOS(.v26),
        .macOS(.v26)
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
