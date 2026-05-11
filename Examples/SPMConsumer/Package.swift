// swift-tools-version: 5.9
//
// Minimal SPM consumer for `beeping-ios` (BEE-80). Compiles a tiny
// library that does `import Beeping` and pokes the public surface;
// build success is the proof that the root package's `.binaryTarget`
// produces a library consumable from outside the host Xcode project.
//
// Driven by `scripts/test-spm-consumer.sh`, which runs `./build.sh`
// first so `dist/Beeping.xcframework` exists by the time SPM resolves.
//

import PackageDescription

let package = Package(
    name: "SPMConsumer",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "SPMConsumer",
            targets: ["SPMConsumer"]
        )
    ],
    dependencies: [
        .package(path: "../..")
    ],
    targets: [
        .target(
            name: "SPMConsumer",
            dependencies: [
                .product(name: "Beeping", package: "beeping-ios")
            ]
        )
    ]
)
