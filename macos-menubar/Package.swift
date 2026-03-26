// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NBAScoreMenubar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "NBAScoreMenubar",
            targets: ["NBAScoreMenubar"]
        )
    ],
    targets: [
        .executableTarget(
            name: "NBAScoreMenubar"
        )
    ]
)
