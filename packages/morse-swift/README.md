# packages/morse-swift

SwiftPM implementation of the Canadian Morse timing and grading engine. It is intentionally offline-only: no networking, analytics, telemetry, remote assets, third-party runtime SDKs, or package dependencies. Foundation is allowed.

## Product

The package exposes the library product `CanadianHamMorseEngine` for iOS/iPadOS 27, macOS 27, visionOS 27, and tvOS 27, matching the platform floor used by `packages/engine-swift`.

Core APIs:

- `farnsworthTiming(characterWpm:effectiveWpm:)` for the ARRL/Bloom Farnsworth formula. Effective speed is clamped to the character speed.
- `profileForName(.isedParis)` for the PARIS-calibrated 12/5 profile and `profileForName(.ric1Literal)` for RIC-1 literal 0.7 s / 1.7 s spacing.
- `textToTimedMorse(_:profile:)` for dot, dash, intra-character gap, inter-character gap, and word-gap timing symbols.
- `validateMorseText(_:)` and `weightedCharacterCount(_:)` for the RIC-1 section 8.2 character set and section 8.2 word weighting.
- `scoreMorseCopy(expected:received:)` for RIC-1 section 8.7 / RIC-3 section 5.2 style edit-distance scoring: wrong, missing, and inserted characters are one error each; five errors or fewer passes.

## Fixture contract

The Swift and TypeScript Morse packages both load the shared JSON fixtures under [`../../fixtures/morse/`](../../fixtures/morse/). These pin the PARIS timing totals, the RIC-1 section 8.2 character set, the synthetic 78-weight RIC-1 section 8.3 sample stand-in, and grading boundaries.

## Tests and CI note

The current GitHub CI workflow has no macOS or SwiftPM job; `packages/engine-swift` tests are local-only. Run this package's tests locally from this directory through the serialized `xbuild` wrapper (as `scripts/check-engine-parity.sh` does for `packages/engine-swift`), never `xcodebuild` directly:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -scheme CanadianHamMorseEngine -destination 'platform=macOS' test
```

Do not wire this package into the Apple apps or `apps/apple/project.yml` until the follow-up Morse app tasks.
