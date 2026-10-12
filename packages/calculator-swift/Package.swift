// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "CanadianHamCalculatorEngine",
    platforms: [
        .iOS(.v27),
        .macOS(.v27),
        .visionOS(.v27),
        .tvOS(.v27),
    ],
    products: [
        .library(
            name: "CanadianHamCalculatorEngine",
            targets: ["CanadianHamCalculatorEngine"]
        ),
    ],
    targets: [
        .target(
            name: "CanadianHamCalculatorEngine",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "CanadianHamCalculatorEngineTests",
            dependencies: ["CanadianHamCalculatorEngine"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
