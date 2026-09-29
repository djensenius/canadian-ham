# Canadian Ham Apple app

SwiftUI multiplatform first slice for iPhone, iPad, and Mac. The app is generated with XcodeGen and the generated `CanadianHam.xcodeproj` is committed so Xcode can open it directly.

## Structure

- `project.yml` — XcodeGen project specification and the source of truth for targets, resources, settings, and schemes.
- `CanadianHam.xcodeproj` — generated Xcode project committed for direct opening.
- `CanadianHam/` — app sources.
  - `Models/` — decodable question-bank models matching `content/generated/basic-2025-07-15/*.json`, plus SwiftData progress models.
  - `Services/` — bundled JSON loading, SwiftData progress storage, export/import validation, and Apple adapters over `CanadianHamEngine`.
  - `Practice/EngineShuffle.swift` — adapter from the app models to the shared Swift practice/exam engine in `packages/engine-swift`.
  - `Views/` — SwiftUI Home/readiness, Practice, Mock exam, Settings/export-import-reset, Learn placeholder, and About views.
  - `Resources/` — privacy manifest and macOS sandbox entitlements.
- `CanadianHamTests/` — unit tests for bundled content decoding and answer shuffling.
- `CanadianHamUITests/` — XCUITests for iPhone practice, subsection practice, settings reset, mock exams, split-view state persistence, and accessibility audits.

The generated Basic 2025 question-bank files are referenced from `project.yml` at `../../content/generated/basic-2025-07-15/` and are copied into app/test bundles by the build; they are not duplicated under `apps/apple/`.

## Open and regenerate

Open `apps/apple/CanadianHam.xcodeproj` in Xcode.

Regenerate after editing `project.yml` or changing target membership:

```sh
cd apps/apple
/opt/homebrew/bin/xcodegen generate --spec project.yml
```

Commit both `project.yml` and the regenerated `CanadianHam.xcodeproj`. To keep project-file churn deterministic, external `content/generated` resources opt out of intermediate parent groups in `project.yml`; after regeneration, run XcodeGen a second time and confirm `git diff -- apps/apple/CanadianHam.xcodeproj` is empty.

## Build and test

Use `xbuild`, never direct `xcodebuild`. `xcode-select` points at CommandLineTools on this machine, so include the `DEVELOPER_DIR` prefix. The iOS command runs both the unit-test target and the XCUITest target.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test CODE_SIGNING_ALLOWED=NO
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=macOS,arch=arm64' -skip-testing:CanadianHamUITests test SDKROOT=macosx SUPPORTED_PLATFORMS=macosx CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES
```

Scheme: `CanadianHam`.

## Progress, practice, and mock exams

The Apple app stores progress locally with SwiftData only. The schema is versioned in source with a migration-plan stub, and the runtime uses local app-container storage without iCloud. If the store cannot open, the app shows a recovery screen that still offers Reset local data.

Current implemented flows for iPhone, iPad, and Mac:

- Home readiness card using `CanadianHamEngine.computeReadiness` and local mock-exam/due-review records.
- Practice scopes for all questions, categories, subsections, weak areas, and due review; due review excludes unseen questions.
- Immediate-feedback and review-later preferences, with progress updates routed through `CanadianHamEngine.applyAnswer` using explicit canonical timestamps.
- Mock exam generation via `CanadianHamEngine.generateExam(requireFullMockExam: true)`, visible seed, question navigator, flag-for-review, submit confirmation, results, category breakdown, and wrong-answer review. The reference-sheet button is intentionally a placeholder for the separate reference-viewer task.
- Settings export/import/reset. Export JSON uses the web progress schema (`canadian-ham.progress-export`, version 1); import validates canonical timestamps, known question/lesson/quiz IDs, lesson-quiz question subsets, Leitner box range, and duplicate `submittedAt` values before replacement.

## Accessibility audit tests

The default iOS UI suite includes deterministic accessibility regressions that run `performAccessibilityAudit()` with no allow-list in light and dark appearances for the new top-level screens:

- Home/readiness;
- Practice hub and practice session;
- Mock exam start, question navigator/timer, and results;
- Learn placeholder;
- Settings;
- About;
- Store recovery.

The heavier T-516 diagnostic harness (screenshots and raw audit findings) is skipped by default. Run it only when collecting accessibility evidence. UI tests also use DEBUG-only launch arguments such as `-CanadianHamForceRegularHorizontalSizeClass` to exercise split-view state on an iPhone simulator:

```sh
CANADIAN_HAM_RUN_A11Y_DIAGNOSTICS=1 DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testA11yDiagnosticsEvidenceHarness test CODE_SIGNING_ALLOWED=NO
apps/apple/scripts/export_a11y_evidence.sh /path/to/Test-CanadianHam-....xcresult
apps/apple/scripts/measure_a11y_contrast.py apps/apple/docs/a11y-evidence
```

Do not commit refreshed `apps/apple/docs/a11y-evidence/` output unless the diagnostic was intentionally run for an evidence update.

## Privacy posture

- Fully offline runtime: no networking code, no analytics, no telemetry, no remote fonts/CDNs, no third-party SDKs, no iCloud/CloudKit.
- The macOS app sandbox entitlement is enabled and does not include client or server network entitlements.
- `PrivacyInfo.xcprivacy` declares tracking disabled, no tracking domains, and no collected data types.
- The app bundles generated content as local resources. Source URLs in the generated manifest are attribution/provenance strings, not runtime requests.
