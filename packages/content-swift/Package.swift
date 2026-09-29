// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CanadianHamContent",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2),
        .tvOS(.v18),
    ],
    products: [
        .library(
            name: "CanadianHamContent",
            targets: ["CanadianHamContent"]
        ),
    ],
    targets: [
        .target(
            name: "CanadianHamContent",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "CanadianHamContentTests",
            dependencies: ["CanadianHamContent"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
