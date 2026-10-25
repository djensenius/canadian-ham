# TASK-14.6 — watchOS internal release validation

2026-10-25 · branch `task-14.6-watch-release`. **No upload or PR.** Local signed
export/inspection and simulator evidence only. TASK-14.6 remains **In Progress**;
AC4 is intentionally unchecked for the approved post-merge internal upload,
App Store Connect processing and owner's physical-watch installation/offline pass.

## Provenance and scope

All runtime code, assets, project membership and Fastfile are unchanged from
`e69bfca9caed91b454dbb5223e33a51bb256efdd` (the initial task-plan commit on main
`b5090fe03c3c8559770b261a68f726151751e969`). Only docs/evidence and Backlog metadata
were edited during validation; no app/package/project/signing configuration changed. The existing
icon and `ios beta` embedding path already satisfy the implementation boundary;
this task validates and documents them rather than adding a second upload lane.

Apple archives, exports and tests use **xbuild only** with
`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. Fastlane also uses
`FASTLANE_SKIP_UPDATE_CHECK=1`. The runner invokes fastlane directly, **not wrapped
in lockf**. Shared-lock waits were respected and no other build was killed. The
normal dedicated `canadian-ham-build.keychain-db` and existing API-key paths were
used without printing secrets or handling the login keychain/password. The export
options keep `testFlightInternalTestingOnly=true` and
`manageAppVersionAndBuildNumber=false`.

## Icon visual review (AC1)

Reviewed the approved hex-beam/brush icon at native 1024 and circular **196, 88,
48 px**, not merely a scaled screenshot. Decision: **retain it unchanged**. All
six outer corners, the heavy perimeter, hub and six spreaders remain inside the
circle with ample cream breathing room. The 196px preview retains dry-brush cuts;
at 88/48px the finest cuts/splatter naturally merge, but the hex/spoke silhouette
and pale zigzag wires remain readable. No edge is clipped, and making the art
smaller or heavier would needlessly reduce the negative space. This is an agent
visual review, not a physical-watch display/owner design approval claim.

Before and after are deliberately **identical**: “before” is the existing family
export and “after” is the shipped watch icon, with no refinement needed. Both are
1024×1024 **RGB, no alpha**, cream **#E8D5B7**, SHA-256
`f908b05aa4a1410b1fb54e05ed82d7a314b9225ccb3e88e49c680c317b577f26`.
Only the review previews have transparent circular corners; the shipped icon
remains opaque and square, letting watchOS apply its own mask.

The icon was retained unchanged, so one set of previews serves as both "before" and "after".

![Circular review at 196, 88 and 48 px](../evidence/task-14.6/icon-small.png)

Individual circular files:
[1024](../evidence/task-14.6/icon-circle-1024.png),
[196](../evidence/task-14.6/icon-circle-196.png),
[88](../evidence/task-14.6/icon-circle-88.png),
[48](../evidence/task-14.6/icon-circle-48.png).

Reproduce from the repository root with ImageMagick 7:

```sh
python3 docs/evidence/task-14.6/render-icon-previews.py
magick identify -format '%f %wx%h %[channels] %[pixel:p{0,0}]\n' \
  design/app-icon/exports/app-icon-1024.png \
  apps/apple/Platforms/watchOS/Resources/Assets.xcassets/AppIcon.appiconset/watch-icon-1024.png
```

The current Xcode **27.1 / 27A9275**, watchOS **27.0** SDK accepts the single
`idiom=universal, platform=watchos, size=1024x1024` AppIcon slot. The signed IPA's
`Assets.car` is **154,392 bytes**, with an opaque RGB `AppIcon` **1024×1024 Icon
Image** and a **MultiSized Image** entry (`1024x1024 index:1 idiom:watch`). The
watch Info.plist names AppIcon. No separate legacy size, dark/tinted or complication
variant is required by this build; no complications are shipped. Archive and
simulator asset-compiler warning searches are recorded with the command results
below. Other existing compiler/catalogue warnings are not represented as a
warning-free entire build.

## Signed export and watch inspection (AC2–3)

The existing **`fastlane ios beta`** is the watch beta entry path; no unsupported
ASC watch platform or second upload path was added. It passes one timestamp
`CURRENT_PROJECT_VERSION` to both iOS and watch targets. `export_only:true` runs
normal Release archive/export and returns **before** `upload_to_testflight`.

### iOS artifact

- Archive: `fastlane/archives/ios/CanadianHam-202610251833.xcarchive`
- IPA: `fastlane/builds/ios/202610251833/CanadianHam.ipa`
- IPA SHA-256: `4f95fb7527f6b45103e33535e296f11c7223ee0898c595a4afa41c45af9f1ddc`
- Watch: `Payload/CanadianHam.app/Watch/CanadianHamWatch.app`
- [Machine-readable inspection](../evidence/task-14.6/export-inspection.json)
  preserves metadata, **all** signed entitlements, icon renditions, linked
  libraries, exact non-study-file inventory, resource digest and signature results.

| Field | Exported value |
| --- | --- |
| Container ID | `org.davidjensenius.CanadianHam` |
| Watch ID | `org.davidjensenius.CanadianHam.watchkitapp` |
| Companion ID | `org.davidjensenius.CanadianHam` |
| `WKApplication` / independent flag | `true` / `true` |
| Container/watch version | `1.0.0` / `1.0.0` |
| Container/watch `CFBundleVersion` | **`202610251833` / `202610251833`**, matching timestamp |
| Watch platform / minimum | `WatchOS` / `27.0` |
| `UIBackgroundModes` / `WKBackgroundModes` | absent / absent |
| Signature | Apple Distribution: david jensenius (`9JALHNGRBQ`) |
| Verification | `codesign --verify --deep --strict --verbose=2` passes separately for phone and watch |
| Watch profile application identifier | `9JALHNGRBQ.org.davidjensenius.CanadianHam.watchkitapp` |
| Watch profile expiry | `2027-10-10T16:51:06Z` |
| Icon | `CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconName=AppIcon`, compiled opaque icon described above |

Phone **and** watch signed entitlements contain only `application-identifier`,
`com.apple.developer.team-identifier`, `beta-reports-active=true`,
`get-task-allow=false`. No iCloud/CloudKit/container, push/`aps-environment` or
App Groups entitlement exists. Development signing during archive and distribution
re-signing during export both succeeded without a workaround.

The watch manifest is byte-identical to its source
(`Platforms/watchOS/Resources/PrivacyInfo.xcprivacy`), SHA-256
`521eb6ef8430773e5c010e1838fe9dd8fa5d62b7b76d1cea8d7d8daadcb144e2`:

```text
NSPrivacyTracking = false
NSPrivacyTrackingDomains = []
NSPrivacyCollectedDataTypes = []
NSPrivacyAccessedAPITypes = []
```

`otool -L` lists only Apple libraries/frameworks: Foundation, AVFAudio,
Accessibility, CoreFoundation, SwiftUI, weak UIKit, WatchKit and system/Swift
runtime libraries (full list in the JSON). **No WatchConnectivity, Network,
CFNetwork, CloudKit, analytics/telemetry or third-party library is directly linked;
no Frameworks directory or nested executable is bundled.** Swift runtime weak
compatibility overlays (including CoreLocation/SceneKit/XPC) are not app-level
location/scene/network features. This checks direct binary links plus app source
and package membership via the guards, not the transitive internals of Apple's
frameworks. Nothing claims Apple system frameworks never use networking internally.

### Exact resource verification

Python `plistlib`/JSON assertions checked **all 1,004 regular watch files**, not
just a forbidden-name grep:

- **988 JSONs**: four `basic-2025-07-15/{questions,categories,subsections,manifest}.json`
  plus **984** `explanations/<category>/<question>.json`. The bank has **984**
  bilingual Basic questions. Every JSON path and byte is identical to the source;
  raw study data totals **2,360,969 bytes**.
- The only other 16 files are the executable, `Assets.car`, `Info.plist`,
  `PkgInfo`, manifest, provisioning profile, code-signature resources and three
  localization files for each of en/fr/fr-CA. Exact names are in the JSON.
- **No** lesson, quiz, hint, Advanced bank, figure, Markdown/README, loose image,
  PDF, official reference sheet or test fixture/plugin is present.
- The iOS container **does** include `official-basic-exam/` under the existing
  internal-only `OFFICIAL_REFERENCE_SHEET` beta opt-in. Its watch does **not**,
  despite using that container archive command. No distribution gate was relaxed.
- Watch bundle regular files total **4,228,159 logical bytes** in this signed
  export, not an installed/on-device size or retained-memory claim.

Resource digest: SHA-256 of sorted lines `relativePath + ' ' + SHA256(file) + '\n'`
for all 988 JSON files is
`9122182849a193f888a9979c58af8dca601b4466c83507fd914b9d655cc1f32b`.
The resource path/byte comparison can be independently repeated from the repo
root after expansion (the inspection also checks the 16 non-study files):

```sh
python3 - "$HOME/.cache/canadian-ham-task-14.6/ipa/Payload/CanadianHam.app/Watch/CanadianHamWatch.app" <<'PY'
from pathlib import Path
import hashlib, sys
watch = Path(sys.argv[1])
expected = {
    'basic-2025-07-15/' + file.name: file
    for file in Path('content/generated/basic-2025-07-15').glob('*.json')
}
expected.update({
    'explanations/' + str(file.relative_to('content/explanations')): file
    for file in Path('content/explanations').rglob('*.json')
})
actual = {str(file.relative_to(watch)) for file in watch.rglob('*.json')}
assert actual == set(expected) and len(actual) == 988
for relative, source in expected.items():
    assert (watch / relative).read_bytes() == source.read_bytes(), relative
lines = ''.join(relative + ' ' + hashlib.sha256((watch / relative).read_bytes()).hexdigest() + '\n'
                for relative in sorted(actual))
assert hashlib.sha256(lines.encode()).hexdigest() == '9122182849a193f888a9979c58af8dca601b4466c83507fd914b9d655cc1f32b'
print('PASS: 988 exact paths and byte-identical Basic/explanation JSONs')
PY
```

### Inspection commands

Local inspection root: `~/.cache/canadian-ham-task-14.6/` (`$EVIDENCE` below).
No profiles, certificates, signed apps/archives or secrets are committed. The
local `inspect-ipa.py` used `plistlib` and exact path/byte assertions as described
above; the committed JSON records its successful output.

```sh
EVIDENCE="$HOME/.cache/canadian-ham-task-14.6"
ditto -x -k fastlane/builds/ios/202610251833/CanadianHam.ipa "$EVIDENCE/ipa"
PHONE="$EVIDENCE/ipa/Payload/CanadianHam.app"
WATCH="$PHONE/Watch/CanadianHamWatch.app"
plutil -p "$WATCH/Info.plist"
plutil -p "$WATCH/PrivacyInfo.xcprivacy"
/usr/bin/assetutil --info "$WATCH/Assets.car"
codesign -d --entitlements :- "$PHONE"
codesign -d --entitlements :- "$WATCH"
codesign --verify --deep --strict --verbose=2 "$PHONE"
codesign --verify --deep --strict --verbose=2 "$WATCH"
codesign -dv --verbose=4 "$WATCH"
security cms -D -i "$WATCH/embedded.mobileprovision" # decode only, never commit profile
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun otool -L "$WATCH/CanadianHamWatch"
python3 "$EVIDENCE/inspect-ipa.py"
```

### macOS regression export

The unchanged `fastlane mac beta export_only:true` also archives/exports
successfully through the dedicated keychain:

- Archive: `fastlane/archives/mac/CanadianHam-202610251835.xcarchive`
- PKG: `fastlane/builds/mac/202610251835/CanadianHam.pkg`
- SHA-256: `4cba4dd28339ea2d12cb10f89a4c58824204d21f217d3d6d912d782f0ea287c0`
- `pkgutil --check-signature` confirms the Apple-issued **3rd Party Mac Developer
  Installer: david jensenius (9JALHNGRBQ)** chain.
- `pkgutil --expand-full` expands all payloads. Exactly one `CanadianHam.app`
  exists: ID `org.davidjensenius.CanadianHam`, MacOSX, version `1.0.0`, timestamp
  build `202610251835`. Deep/strict app signature verification passes. There are
  **zero** Watch directories, CanadianHamWatch entries or watchkit-named files.
- [Machine-readable macOS results](../evidence/task-14.6/mac-export-inspection.json).

```sh
pkgutil --check-signature fastlane/builds/mac/202610251835/CanadianHam.pkg
pkgutil --expand-full fastlane/builds/mac/202610251835/CanadianHam.pkg "$EVIDENCE/mac-pkg"
codesign --verify --deep --strict --verbose=2 \
  "$EVIDENCE/mac-pkg/org.davidjensenius.CanadianHam.pkg/Payload/CanadianHam.app"
```

Both lane logs explicitly say **`Export only; skipping TestFlight upload`** and
have no `upload_to_testflight` step. No upload was attempted. The four-platform
Fastfile table/lane implementations are unchanged. tvOS/visionOS exports and
full iOS/macOS/tvOS/visionOS test suites were **not rerun**: this task changes no
runtime or shared source, project or lane code; the requested signed iOS/macOS
exports and complete watch scheme cover the release-validation scope. No
figure/title-sweep, web/content/package or localization suite was needed for
docs/evidence-only changes. Merge-batch/release-candidate suites remain the
coordinator's gate, not replaced by these exports.

## Commands, outcomes and retained logs (AC1–3, AC5)

All commands below passed. Export runs were 22:33:20–22:35:21 UTC (iOS) and
22:35:21–22:36:30 UTC (macOS); the single full watch invocation was
22:36:30–22:52:01 UTC, including build/setup/diagnostics. No tests were changed,
excluded, retried or skipped. **56/56 pass: 29 unit + 27 UI**, including all **16
full default EN/FR accessibility audits**, largest-text flows and session-language
reset. This is one complete all-green scheme run on the final main feature code,
not a combination of fix runs. Hardware gates remain pending.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer FASTLANE_SKIP_UPDATE_CHECK=1 fastlane ios beta export_only:true
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer FASTLANE_SKIP_UPDATE_CHECK=1 fastlane mac beta export_only:true
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild \
  -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamWatch \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 12 (42mm),OS=27.0' \
  -resultBundlePath "$HOME/.cache/canadian-ham-task-14.6/watch-full.xcresult" \
  test CODE_SIGNING_ALLOWED=NO
```

| Check | Result |
| --- | --- |
| iOS signed archive/export | **ARCHIVE SUCCEEDED / EXPORT SUCCEEDED**; upload explicitly skipped; watch embedding/signing validated |
| macOS signed archive/export | **ARCHIVE SUCCEEDED / EXPORT SUCCEEDED**; upload explicitly skipped; no embedded watch |
| Full watch scheme | **TEST SUCCEEDED**, 56 passed / 0 failed / 0 skipped on Series 12 42mm, watchOS 27.0 (24R362) |
| `pnpm check:apple-network` | Passed: **98 Swift files, 6 plist/privacy files, 2 project config files** |
| `pnpm test:apple-network` | Passed self-test fixtures |
| `pnpm check:apple-icloud-gate` | Passed default Debug/Release gates; watch overrides inherited cloud flags and has no entitlements |
| `pnpm test:apple-icloud-gate` | Passed self-test fixtures |
| `pnpm test:fastlane` | **4 tests / 53 assertions**, 0 failures/errors/skips (export-only fail-safe behavior) |
| `ruby -c fastlane/Fastfile` | Syntax OK |
| IPA inspection, byte/path comparison, assetutil, entitlements/frameworks, codesign | Passed; committed inspection JSON and reproducible resource comparison above |
| macOS pkg signature, full expansion and app signature | Passed; committed macOS JSON |
| Icon preview regeneration | Passed; second render is byte-identical to committed previews |
| `pnpm check:links` | Markdown relative links verified |
| `node scripts/check-test-guard.mjs --base main --head HEAD` | Passed: no guarded changes (docs/metadata only) |
| `git diff --check` | Passed |

[Result-bundle summary](../evidence/task-14.6/watch-test-summary.json) is exported
using `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool
get test-results summary --path "$HOME/.cache/canadian-ham-task-14.6/watch-full.xcresult"`.
The result summary's `deviceName` says **iPhone Air**, a tool metadata mismatch;
its platform is watchOS Simulator, model is Apple Watch Series 12, and UUID is
`02C40D35-B5AD-40AF-B434-C63C5F294C27`. A post-run
`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl list devices -j`
confirms that exact UUID is **Apple Watch Series 12 (42mm)**, device type
`com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-12-42mm`, watchOS 27.0,
now Shutdown. No iPhone UI test destination was used or extra simulator booted.
The raw summary is retained unchanged rather than silently correcting its name.

Local retained evidence root: **`~/.cache/canadian-ham-task-14.6/`**. This holds
`runner.log`, `ios-export.log`, `mac-export.log`, `watch-full.log`, `guards.log`,
`watch-full.xcresult`, expanded `ipa/` and `mac-pkg/`, raw `watch-assets.json`,
`{ios,watch}-entitlements.plist`, `watch-frameworks.txt`, profile/metadata/signature
inspection outputs and the local assertion helper. Signed archives and exports
remain in the gitignored fastlane paths above, not in the repository evidence.

### Asset warnings and nonfatal toolchain diagnostics

After the completed runs, the following asset diagnostic search returned **no
matches** (grep exit 1); all warning lines were also reviewed. No missing icon,
unassigned child, missing variant, signing or actool warning/error appeared in
the iOS/watch archive or simulator build. The macOS archive also had none.

```sh
grep -nEi 'com\.apple\.actool\.(warnings|errors)|actool.*warning:|warning:.*(actool|\.xcassets|app.?icon|iconset)' \
  "$HOME/.cache/canadian-ham-task-14.6/ios-export.log" \
  "$HOME/.cache/canadian-ham-task-14.6/mac-export.log" \
  "$HOME/.cache/canadian-ham-task-14.6/watch-full.log"
```

Existing nonfatal warnings remain: catalogue plural argument inference, watch/phone
AVAudioEngine and watch interruption API deprecations, unused resignFirstResponder
result, and AppIntents extraction without a framework dependency. The result
summary also records the existing synchronous main-thread AVAudioSession activation
warning (including the real-tone test); physical responsiveness/audio behavior
remains part of the owner check, not a simulator performance guarantee. Simulator
metadata/debugger logs report `invalidDigitCount(94232)` / no debugger version;
post-test diagnostics report `xcrun: unable to find utility "simctl"` (error 72).
The result bundle and tests were collected successfully, with **0 failures**;
none of those messages was hidden, skipped or made into an audit exception.

Current fresh-loader simulator probe: **0.327082084 s**, resident delta
**6,520,832 bytes** (237,043,712 → 243,564,544). The already-loaded second probe was
0.000101375 s with delta 0. Its **19,440,920** debug bundle logical bytes include
test/build overhead and are not the signed 4,228,159-byte export above. These are
simulator observations, not hardware launch/memory guarantees.

### Per-test results: single full watch run (56)

Every row below is from `watch-full.log` and the same result bundle; no exclusions.

| Test | Result | Seconds |
| --- | --- | ---: |
| `CanadianHamWatchTests.CanadianHamWatchTests.testIndependentOfflineBundle` | PASS | 0.005 |
| `CanadianHamWatchTests.CanadianHamWatchTests.testPlannedSections` | PASS | 0.001 |
| `CanadianHamWatchTests.CanadianHamWatchTests.testSessionLanguageUsesRealBundlesForLabelsFeedbackAndErrors` | PASS | 0.003 |
| `CanadianHamWatchTests.CanadianHamWatchTests.testSharedPackagesOnWatch` | PASS | 0.003 |
| `CanadianHamWatchTests.WatchAlphabetReferenceTests.testAllDigitsMatchSharedMorseTableWithoutPhonetics` | PASS | 0.001 |
| `CanadianHamWatchTests.WatchAlphabetReferenceTests.testAllLettersMatchL00201PhoneticsAndSharedMorseTable` | PASS | 0.002 |
| `CanadianHamWatchTests.WatchAlphabetReferenceTests.testSpokenPatternsUseLocalizedWordsAndKeepInternationalPhonetics` | PASS | 0.002 |
| `CanadianHamWatchTests.WatchMorseTests.testCancelBeforeStartAndMidSequenceInvalidatesEvenStaleCallbacks` | PASS | 0.001 |
| `CanadianHamWatchTests.WatchMorseTests.testDelayedSchedulerDoesNotCollapsePresets` | PASS | 0.001 |
| `CanadianHamWatchTests.WatchMorseTests.testFourDistinctSeededChoicesGradingAndNextReset` | PASS | 0.007 |
| `CanadianHamWatchTests.WatchMorseTests.testHapticSpacingSurvivesLeavingAndReenteringMorse` | PASS | 0.001 |
| `CanadianHamWatchTests.WatchMorseTests.testHapticStylesMapEveryPairAndReachOutput` | PASS | 0.014 |
| `CanadianHamWatchTests.WatchMorseTests.testLocalToneDriverRendersOffMainActorAndRestartsAfterStop` | PASS | 0.489 |
| `CanadianHamWatchTests.WatchMorseTests.testNextCancelsAndPreservesPresetCooldown` | PASS | 0.001 |
| `CanadianHamWatchTests.WatchMorseTests.testOnlyBeganAudioInterruptionCancelsPlayback` | PASS | 0.001 |
| `CanadianHamWatchTests.WatchMorseTests.testOutputsAreIndependentOffDoesNotStartAndToneFailureStops` | PASS | 0.005 |
| `CanadianHamWatchTests.WatchMorseTests.testReplayCannotOverlapAndCompletedReplayUsesSameSequence` | PASS | 0.001 |
| `CanadianHamWatchTests.WatchMorseTests.testSpeedClampsAndAllLettersRespectCadenceFloor` | PASS | 0.002 |
| `CanadianHamWatchTests.WatchMorseTests.testTimingFixturesMapToWatchPresetsAndToneSegments` | PASS | 0.005 |
| `CanadianHamWatchTests.WatchMorseTests.testVoiceOverStartDelayAppliesToBothOutputsAndCanBeCancelled` | PASS | 0.001 |
| `CanadianHamWatchTests.WatchPracticeTests.testAColdBundledPracticeLoadMeasurements` | PASS | 0.338 |
| `CanadianHamWatchTests.WatchPracticeTests.testDistractorNotesFollowDisplayedOrderWithOfficialChoiceText` | PASS | 0.307 |
| `CanadianHamWatchTests.WatchPracticeTests.testEmptyLoadErrorAndMissingResourcesFailSafely` | PASS | 0.001 |
| `CanadianHamWatchTests.WatchPracticeTests.testFrenchExplanationFallbackHasEnglishAccessibilityLanguage` | PASS | 0.307 |
| `CanadianHamWatchTests.WatchPracticeTests.testMeasureBundledPracticeLoad` | PASS | 0.151 |
| `CanadianHamWatchTests.WatchPracticeTests.testNewSessionRestoresNeitherAnswerNorQuestionSequence` | PASS | 0.146 |
| `CanadianHamWatchTests.WatchPracticeTests.testRenderedExplanationsNeverExposeAuthoringLabels` | PASS | 0.416 |
| `CanadianHamWatchTests.WatchPracticeTests.testSeededShuffleGradesSourceIndexNotDisplayPositionAndLocksSubmission` | PASS | 0.183 |
| `CanadianHamWatchTests.WatchPracticeTests.testWatchBundleContainsCompleteBasicBankAndOnlyPracticeContent` | PASS | 0.165 |
| `CanadianHamWatchUITests.CanadianHamWatchUITests.testLaunchAndNavigateEnglish` | PASS | 18.109 |
| `CanadianHamWatchUITests.CanadianHamWatchUITests.testLaunchAndNavigateFrench` | PASS | 15.427 |
| `CanadianHamWatchUITests.WatchAccessibilityUITests.testEnglishHomeAudit` | PASS | 5.301 |
| `CanadianHamWatchUITests.WatchAccessibilityUITests.testEnglishLargestTextControlsAndLongQuestion` | PASS | 89.835 |
| `CanadianHamWatchUITests.WatchAccessibilityUITests.testEnglishMorseAfterAnswerAudit` | PASS | 15.324 |
| `CanadianHamWatchUITests.WatchAccessibilityUITests.testEnglishMorseBeforeAnswerAudit` | PASS | 12.550 |
| `CanadianHamWatchUITests.WatchAccessibilityUITests.testEnglishMorseSettingsAudit` | PASS | 11.801 |
| `CanadianHamWatchUITests.WatchAccessibilityUITests.testEnglishPracticeFeedbackAudit` | PASS | 9.657 |
| `CanadianHamWatchUITests.WatchAccessibilityUITests.testEnglishPracticeQuestionAudit` | PASS | 6.958 |
| `CanadianHamWatchUITests.WatchAccessibilityUITests.testEnglishReferenceAudit` | PASS | 7.181 |
| `CanadianHamWatchUITests.WatchAccessibilityUITests.testEnglishSettingsAudit` | PASS | 8.221 |
| `CanadianHamWatchUITests.WatchAccessibilityUITests.testFrenchHomeAudit` | PASS | 5.122 |
| `CanadianHamWatchUITests.WatchAccessibilityUITests.testFrenchLargestTextControlsAndLongQuestion` | PASS | 79.838 |
| `CanadianHamWatchUITests.WatchAccessibilityUITests.testFrenchMorseAfterAnswerAudit` | PASS | 15.277 |
| `CanadianHamWatchUITests.WatchAccessibilityUITests.testFrenchMorseBeforeAnswerAudit` | PASS | 12.356 |
| `CanadianHamWatchUITests.WatchAccessibilityUITests.testFrenchMorseSettingsAudit` | PASS | 11.456 |
| `CanadianHamWatchUITests.WatchAccessibilityUITests.testFrenchPracticeFeedbackAudit` | PASS | 9.566 |
| `CanadianHamWatchUITests.WatchAccessibilityUITests.testFrenchPracticeQuestionAudit` | PASS | 6.975 |
| `CanadianHamWatchUITests.WatchAccessibilityUITests.testFrenchReferenceAudit` | PASS | 7.043 |
| `CanadianHamWatchUITests.WatchAccessibilityUITests.testFrenchSettingsAudit` | PASS | 8.178 |
| `CanadianHamWatchUITests.WatchAccessibilityUITests.testSessionLanguageOverrideUpdatesSwiftUIAndBundleLookupsAndResets` | PASS | 110.657 |
| `CanadianHamWatchUITests.WatchAlphabetUITests.testEnglishReferenceScrollsToNineAndBack` | PASS | 54.521 |
| `CanadianHamWatchUITests.WatchAlphabetUITests.testFrenchReferenceAtLargeDynamicTypeScrollsToNineAndBack` | PASS | 78.346 |
| `CanadianHamWatchUITests.WatchMorseUITests.testIndependentOutputsTextAlternativeAndSessionOnlySettings` | PASS | 135.232 |
| `CanadianHamWatchUITests.WatchMorseUITests.testPlayReplayAnswerNextAndNoEarlyReveal` | PASS | 49.547 |
| `CanadianHamWatchUITests.WatchPracticeUITests.testCrownSelectionRequiresConfirmAndFrenchFeedbackLabelsEnglishFallback` | PASS | 53.901 |
| `CanadianHamWatchUITests.WatchPracticeUITests.testTapFeedbackNextAndRelaunchDoesNotRestoreAnswer` | PASS | 32.297 |

## Owner upload and physical-watch results (pending)

**Not performed.** No TestFlight upload, processing, invitation, physical install,
VoiceOver listening or tactile validation was done by this agent. Export-only
build numbers above are **not processed TestFlight builds**. AC4 remains unchecked
and TASK-14.6 In Progress. After review/merge approval, the coordinator uploads from
main through the existing internal iOS lane; the owner records the processed
build/commit, watch model/watchOS, installation method and pass/fail observations.
No external groups, public link or App Store submission is authorized.

Follow the [installation and physical-watch checklist](../release/testflight.md#watchos-beta-entry-path-and-installation),
including phone out of range, explicit radio-off/Airplane Mode, practice/Crown
Confirm, Morse/reference/EN/FR, resident-bank memory/launch feel and cached-load
recovery. Complete **all three haptic styles in the same session** from
[TASK-14.3](task-14.3-watch-morse.md#owner-hardware-check), and
[TASK-14.5's listening/layout checks](task-14.5-watch-a11y.md#owner-manual-checks--pending-do-not-mark-ac4-complete).
Keep their hardware criteria blocked until actual observations exist; simulator
accessibility audits cannot establish heard speech or fixed-preset fidelity.

| Owner gate | Result |
| --- | --- |
| Approved upload / processed ASC version/build/commit | Pending post-merge |
| Physical watch model/watchOS/install method/tester/date | Pending owner |
| Practice, Morse, reference, EN/FR with phone absent and network off | Pending owner |
| Same-session three-style haptics, Silent Mode, tone alignment/cancellation | Pending owner; TASK-14.3 AC2 still open |
| VoiceOver, largest text, smallest hardware, language reset | Pending owner; TASK-14.5 owner gate still open |
| Memory/first-touch/launch feel and failure recovery | Pending owner |
