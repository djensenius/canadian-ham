// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "CanadianHamEngine",
    platforms: [
        .iOS(.v27),
        .macOS(.v27),
        .visionOS(.v27),
        .tvOS(.v27),
    ],
    products: [
        .library(
            name: "CanadianHamEngine",
            targets: ["CanadianHamEngine"]
        ),
    ],
    targets: [
        .target(
            name: "CanadianHamEngine",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "CanadianHamEngineTests",
            dependencies: ["CanadianHamEngine"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
