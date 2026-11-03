# TASK-14.4 — watch alphabet reference

## Implementation and source boundaries

- Home → Alphabet now opens a native scrollable list: A–Z, then digits 0–9.
- `WatchAlphabetReference.swift` carries only the 26 ITU spellings from
  [L-002-01](../../content/lessons/m2-operating-procedures/l-002-01-voice-repeater-and-simplex-procedure.md):
  **Alfa**, **Juliett**, and **X-ray**, not alternate spellings. These international
  words stay unchanged in French. Morse patterns are computed directly from
  `CanadianHamMorseEngine.morseCodeTable`; no second Morse mapping is stored.
- Letters/Lettres and Digits/Chiffres are the only new catalogue keys. A Python
  JSON round-trip retained all existing keys, values and key order. Existing
  Dot/Point and Dash/Tiret translations provide spoken patterns.
- Each row combines its children into one VoiceOver element with an explicit
  label such as `A, Alfa, Dot Dash` / `A, Alfa, Point Tiret`. Visual patterns use
  `•` and `—`. Semantic headline/body fonts, unconstrained vertical sizing and
  ordinary wrapping avoid truncation, shrinking and fixed row heights.
- No lesson, figure, quiz or hint resources, persistence, networking, packages,
  entitlements or background modes were added. The existing `project.yml`
  directory source specifications already include the new watch/test files;
  XcodeGen regenerated their membership in the committed project. Two successive
  generations produced identical diffs.

## Why the lesson is checked outside the watch unit bundle

Lessons are intentionally absent from the watch app and test resources. The
watch unit tests use a literal expected ITU table, compare all 36 Morse patterns
with the shared package, and check order, counts and unique IDs. The Node check
`scripts/check-watch-alphabet-reference.mjs`, included in **`pnpm test`**, parses
L-002-01's named ITU table and the watch's phonetic entries and compares all 26
pairs verbatim. This catches source drift without shipping the Markdown bundle.

In a disposable directory, the parity check rejected each injected mutation:
`Alfa` → `Alpha`, B → duplicate A, and removal of Z. The restored source passed.

The formatter accepts localized dot/dash words from the view. Unit tests cover
both word sets for every entry; UI tests verify the actual bundled EN/FR labels.
`String(localized:locale:)` formats using a locale but does not independently
switch the bundle's preferred language. In-session language overrides belong to
TASK-14.5; it should account for this existing Foundation behavior across watch
views, including the pre-existing Morse view.

## Apple checks (2026-10-25)

All commands ran through **xbuild**, on one destination per test invocation.
Build-lock contention with the concurrent TestFlight build was respected; no
other build was stopped.

Watch destination: `platform=watchOS Simulator,name=Apple Watch Series 12 (42mm),OS=27.0`.
The final targeted results for each affected test are:

| Test | Result | Seconds | Result bundle below |
|---|---|---:|---|
| `WatchAlphabetReferenceTests.testAllLettersMatchL00201PhoneticsAndSharedMorseTable` | PASS | 0.001 | `watch-alphabet-final` |
| `WatchAlphabetReferenceTests.testAllDigitsMatchSharedMorseTableWithoutPhonetics` | PASS | 0.002 | `watch-alphabet-final` |
| `WatchAlphabetReferenceTests.testSpokenPatternsUseLocalizedWordsAndKeepInternationalPhonetics` | PASS | 0.002 | `watch-alphabet-final` |
| `CanadianHamWatchUITests.testLaunchAndNavigateEnglish` | PASS | 19.488 | `watch-alphabet-initial` |
| `CanadianHamWatchUITests.testLaunchAndNavigateFrench` | PASS | 14.755 | `watch-alphabet-initial` |
| `WatchAlphabetUITests.testEnglishReferenceScrollsToNineAndBack` | PASS | 60.415 | `watch-alphabet-touch-scroll` |
| `WatchAlphabetUITests.testFrenchReferenceAtLargeDynamicTypeScrollsToNineAndBack` | PASS | 84.018 | `watch-alphabet-touch-scroll` |

Local result bundles and logs are in `/tmp/task-14.4-evidence/`; each table bundle
name has the `.xcresult` extension and its command log uses `.log`.

The final watch unit invocation was:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild \
  -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamWatch \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 12 (42mm),OS=27.0' \
  -only-testing:CanadianHamWatchTests/WatchAlphabetReferenceTests \
  -only-testing:CanadianHamWatchUITests/WatchAlphabetUITests \
  -resultBundlePath /tmp/task-14.4-evidence/watch-alphabet-final.xcresult \
  test CODE_SIGNING_ALLOWED=NO
```

All three unit tests passed in that invocation; English UI positioning still
failed there. The final UI-only invocation fixed that failure and passed both
reference tests:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild \
  -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamWatch \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 12 (42mm),OS=27.0' \
  -only-testing:CanadianHamWatchUITests/WatchAlphabetUITests \
  -resultBundlePath /tmp/task-14.4-evidence/watch-alphabet-touch-scroll.xcresult \
  test CODE_SIGNING_ALLOWED=NO
```

The initial invocation additionally selected
`-only-testing:CanadianHamWatchUITests/CanadianHamWatchUITests`; both updated
navigation smoke tests passed. Iteration failures were the locale-only unit
setup described above and test positioning: native Crown row snapping could
jump over short headers/partly visible rows, and tiny Crown deltas did not move
them. The final helper uses short, slow touch drags and requires the target's
whole frame below the navigation bar and inside the screen. No app behavior,
accessibility audit or existing shared helper was weakened to address these
failures.

Both final UI tests enter Alphabet, verify translated section and spoken row
labels (including Alfa and Juliett), reach the complete last row 9 and navigate
back. French launches with `-UIPreferredContentSizeCategoryName
UICTContentSizeCategoryAccessibilityXXXL`; it then relaunches normally and asserts
that A's row height was greater at the requested large size. Thus this runtime
honored the launch argument rather than silently ignoring it. Keep-always
screenshots of fully visible J/Juliett and 9 in both languages are attached to the
passing result bundle. Exported copies are in
`/tmp/task-14.4-evidence/touch-scroll-attachments/`. Visual inspection confirmed
the large-size word and patterns are readable and not truncated.

The iOS distribution-container build also passed:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild \
  -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build-for-testing CODE_SIGNING_ALLOWED=NO
```

Result: **TEST BUILD SUCCEEDED**. The built iOS app contains
`Watch/CanadianHamWatch.app`; a recursive resource check found no lesson, figure,
quiz or hint assets in that embedded watch payload.

## Repository checks

| Command/check | Result |
|---|---|
| `pnpm test` | PASS: reference parity and existing gate checks; content-tools 250, Morse 21, calculator 127, web 281 tests |
| `pnpm typecheck` | PASS |
| `pnpm check:apple-l10n` | PASS, including export plus tvOS, visionOS and watch localization builds; catalogue unchanged by checker |
| `node scripts/check-apple-text-sources.ts --self-test` and normal check | PASS |
| `pnpm check:apple-network` | PASS (96 Swift files) |
| `pnpm check:apple-icloud-gate` | PASS |
| `node scripts/check-test-guard.mjs --self-test` | PASS |
| `node scripts/check-test-guard.mjs --base faaec618 --head HEAD` | PASS against implementation commit `214756f14ea799f222bfa4d882c25ec229208a55`; no guarded changes |
| XcodeGen twice, compare first/second project diffs | PASS, identical |
| Python catalogue comparison against main | PASS: original key/value order intact; only Letters/Digits added |
| `git diff --check` | PASS |

Existing web canvas warnings and Xcode SDK-build-number/debugger warnings were
non-fatal. An early localization command hit its shell timeout while waiting for
the next build lock; the complete localization check was subsequently rerun and
passed, including again after final view changes.

## Deferred validation / scope

No full platform suites ran: only the affected watch unit/UI classes and the
updated smoke class were selected, per the targeted-testing policy. iOS was
build-for-testing only to verify embedding. macOS/tvOS/visionOS tests were not
run because this adds no app code for those targets (the shared catalogue was
checked by the localization export/build checks). Full merge-batch suites remain
the coordinator's gate.

Physical-watch VoiceOver listening and the broader watch accessibility audits
remain TASK-14.5/hardware validation, not claims made by these structural/UI
checks. This reference adds no haptic playback, so tactile timing validation is
unchanged. No PR or distribution/upload was performed by this task.
