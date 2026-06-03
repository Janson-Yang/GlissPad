// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "glisspad",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "glisspad", targets: ["GlissPad"])
    ],
    targets: [
        .target(
            name: "GlissPadCore",
            linkerSettings: [
                // MultitouchSupport is private, so SwiftPM needs the SDK stub path explicitly.
                .unsafeFlags([
                    "-F/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/PrivateFrameworks",
                    "-F/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/PrivateFrameworks",
                    "-framework",
                    "MultitouchSupport"
                ])
            ]
        ),
        .executableTarget(
            name: "GlissPad",
            dependencies: ["GlissPadCore"]
        ),
        .testTarget(
            name: "GlissPadCoreTests",
            dependencies: ["GlissPadCore"]
        )
    ]
)
