// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "CanadianHamMorseEngine",
    platforms: [
        .iOS(.v27),
        .macOS(.v27),
        .visionOS(.v27),
        .tvOS(.v27),
    ],
    products: [
        .library(
            name: "CanadianHamMorseEngine",
            targets: ["CanadianHamMorseEngine"]
        ),
    ],
    targets: [
        .target(
            name: "CanadianHamMorseEngine",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "CanadianHamMorseEngineTests",
            dependencies: ["CanadianHamMorseEngine"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
