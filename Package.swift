// swift-tools-version: 5.9
//
// SPM manifest for `beeping-ios` (BEE-80). Distributes the SDK as a
// pre-built XCFramework via `.binaryTarget`. The path-based variant
// here is for local development against this repo and the in-tree
// `Examples/SPMConsumer/`. BEE-82 swaps `path:` for `url:checksum:`
// pointing at GitHub Releases once cosign + release-please are wired.
//
// To build the XCFramework before resolving the package locally:
//
//   ./build.sh
//
// The product wraps the C engine (BeepingCore.xcframework, statically
// linked into the `Beeping` framework binary) so consumers don't need
// to depend on it separately.
//

import PackageDescription

let package = Package(
    name: "Beeping",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Beeping",
            targets: ["Beeping"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "Beeping",
            path: "dist/Beeping.xcframework"
        )
    ]
)
