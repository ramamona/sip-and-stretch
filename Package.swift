// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "SipStretch",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "SipStretch", targets: ["SipStretch"]),
    ],
    targets: [
        // Pure, UI-free logic: scheduling, DND, stats, achievements, content. Fully unit tested.
        .target(name: "SipStretchCore"),
        // The menu bar app (SwiftUI + AppKit). Bundled into SipStretch.app by scripts/bundle.sh.
        .executableTarget(name: "SipStretch", dependencies: ["SipStretchCore"]),
        .testTarget(name: "SipStretchCoreTests", dependencies: ["SipStretchCore"]),
    ]
)
