// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "CanadianHamContent",
    platforms: [
        .iOS(.v27),
        .macOS(.v27),
        .visionOS(.v27),
        .tvOS(.v27),
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
