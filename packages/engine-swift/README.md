# packages/engine-swift

SwiftPM implementation of the Canadian Ham engine. It is intentionally offline-only: no networking, analytics, telemetry, remote assets, third-party runtime SDKs, or package dependencies. Foundation is allowed.

## Product

The package exposes the library product `CanadianHamEngine` for iOS 18, macOS 15, visionOS 2, and tvOS 18. Public `Sendable` value types mirror the shared fixture shapes and are `Codable` where fixture or app persistence needs JSON round trips.

Core APIs:

- `Pcg32`, `fnv1a64Utf8`, `firstUint32Values`, `pcg32DemoValues`, and `shuffled` for deterministic fixture RNG.
- `generateExam(_:)`, `GeneratedExam`, `GeneratedExamItem`, `ExamSubsectionInput`, and `categoryCounts(_:)` for mock-exam generation.
- `scoreExam(_:)`, `ExamScore`, `CategoryBreakdownEntry`, and `percentFor(correct:total:)` for scoring.
- `applyAnswer(existing:update:)`, `applyAnswerSequence(initialRecords:updates:)`, `dueQuestionIds(records:now:)`, `dueCount(records:now:)`, `weakSubsectionIds(records:latestExamItems:)`, and progress record value types for Leitner/spaced-repetition state.
- `computeReadiness(_:)`, `ReadinessInput`, `ReadinessResult`, and `ReadinessReason` for readiness classification.
- `CanonicalTimestamp` for strict UTC millisecond timestamp parsing/formatting.

## Parity rules

The TypeScript engine and the Swift engine are both bound by `../../fixtures/engine/*.json`, `../../fixtures/README.md`, and `../../docs/architecture.md`.

Pinned behaviours include:

- FNV-1a 64-bit seed hashing, PCG32 XSH RR output, unsigned wrapping arithmetic, and the `pcg32_srandom(42, 54)` sanity vector.
- Byte-wise UTF-8 ordinal ID sorting; no localized comparisons.
- Exam generation RNG consumption order: subsection sorting, question sorting, one selection draw per subsection, Fisher-Yates item shuffle, then Fisher-Yates choice shuffles in final display order.
- `answerSourceIndexes` must be exactly `[0, 1, 2, 3]`.
- Percent is `(Double(correct) / Double(total)) * 100`; `total == 0` returns `0`; fixture comparisons are exact.
- Timestamps must be fixed-width UTC milliseconds: `YYYY-MM-DDTHH:MM:SS.sssZ`. The Swift engine uses its own strict parser/formatter instead of ISO8601 formatter defaults.
- Readiness input rejects duplicate `submittedAt` timestamps.
- Output ordering follows the fixtures: incorrect question IDs preserve input item order; weak subsections, due IDs, category breakdowns, and Leitner records are ordinal-sorted.

## Tests and builds

Never call `xcodebuild` directly. Use `xbuild` with Xcode selected via `DEVELOPER_DIR`.

From this directory:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -list
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -scheme CanadianHamEngine -destination 'platform=macOS' test
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -scheme CanadianHamEngine -destination 'generic/platform=iOS Simulator' build
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -scheme CanadianHamEngine -destination 'generic/platform=tvOS Simulator' build
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -scheme CanadianHamEngine -destination 'generic/platform=visionOS Simulator' build
```

The fixture runner resolves the repository root relative to `#filePath`, loads every JSON file under `../../fixtures/engine/`, rejects unknown engine fixture schema/kind values, and asserts Swift output equality with fixture `expectedOutput` values.

## T-207 parity check note

`scripts/check-engine-parity.sh` at the repository root runs both sides of the contract: `node --test packages/engine-ts/test/` and the Swift package tests via `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild ...`.
