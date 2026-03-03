// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "RulerCore",
    platforms: [
        .iOS(.v13),
        .macOS(.v13)
    ],
    products: [
        .library(name: "RulerCore", targets: ["RulerCore"])
    ],
    targets: [
        .target(
            name: "RulerCore",
            path: "Ruler/Core"
        ),
        .testTarget(
            name: "RulerCoreTests",
            dependencies: ["RulerCore"],
            path: "Tests/RulerCoreTests"
        )
    ]
)
