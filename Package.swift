// swift-tools-version: 5.9
//
// SPM manifest for `beeping-ios`. Distributes the SDK as a pre-built
// XCFramework via `.binaryTarget` pointing at the signed zip on the
// GitHub Release of this repo. cosign-keyless OIDC verification flow
// is documented in README under "Verifying releases".
//
// Consumer Podfile / Package.swift:
//
//   .package(url: "https://github.com/beeping-io/beeping-ios", branch: "main")
//
// Tag-pinned consumption (`from: "0.0.0"`) is correct from the next
// minor release onward: the release pipeline will rewrite this file
// AT the tag commit so the URL/checksum match the tag's own assets.
// Until then, `branch: "main"` resolves to whatever the latest
// uploaded release artifacts are. The `path:` variant is still
// supported for local development via `./build.sh` + an alternate
// Package.swift, but the canonical SPM consumption is `url:checksum:`.
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
            url:
                "https://github.com/beeping-io/beeping-ios/releases/download/v0.0.0/Beeping.xcframework.zip",
            checksum: "eb42d456dc8bb0421dd22563d2cc0b9815864a767033e3bd09f5f1d2e84b0117"
        )
    ]
)
