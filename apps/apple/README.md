# Canadian Ham Apple app

SwiftUI multiplatform first slice for iPhone, iPad, and Mac. The app is generated with XcodeGen and the generated `CanadianHam.xcodeproj` is committed so Xcode can open it directly.

## Structure

- `project.yml` — XcodeGen project specification and the source of truth for targets, resources, settings, and schemes.
- `CanadianHam.xcodeproj` — generated Xcode project committed for direct opening.
- `CanadianHam/` — app sources.
  - `Models/` — decodable question-bank models matching `content/generated/basic-2025-07-15/*.json`.
  - `Services/` — bundled JSON loading.
  - `Practice/EngineShuffle.swift` — adapter from the app models to the shared Swift practice/exam engine in `packages/engine-swift`.
  - `Views/` — SwiftUI category list, practice, and about views.
  - `Resources/` — privacy manifest and macOS sandbox entitlements.
- `CanadianHamTests/` — unit tests for bundled content decoding and answer shuffling.
- `CanadianHamUITests/` — XCUITests for the compact iPhone practice flow.

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

## Accessibility audit tests

The default iOS UI suite includes a fast deterministic accessibility regression that runs `performAccessibilityAudit()` with no allow-list in light and dark appearances for:

- the category list;
- an unanswered fixed practice question (`B-004-005-008`);
- the same practice question after answering it correctly.

The heavier T-516 diagnostic harness (screenshots, position logs, and raw audit findings for the two-pass audit) is skipped by default. Run it only when collecting accessibility evidence:

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
