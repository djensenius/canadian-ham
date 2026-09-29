// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CanadianHamEngine",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2),
        .tvOS(.v18),
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
