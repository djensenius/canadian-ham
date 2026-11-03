# TASK-80 — official Morse sending timing

**2026-10-27 local / 2026-10-28 UTC.** Implementation under test:
`d44db0ec40fd8da229b2f6ac457db293cfbab0e6` on
`task-80-morse-official-timing`, based on main
`0196bd85786d4cee5d37b3f990415fc49e82c0f2`.
Subsequent commits contain only Backlog updates and this evidence.

## Sourced contract and scope

The [primary-source comparison](../exam-facts.md#morse-qualification-test-standard-task-80)
records EN/FR quotations and section numbers from RIC-1/CIR-1 §8,
RIC-3/CIR-3 §5.2, RBR-4/IPR-4 Schedule I, and official bilingual Basic bank
`B-001-004-005`. Current pages and the bank ZIP were fetched directly from ISED;
no search/browser-fetch tool was available in this worker. The bank TXT hash
remains `34c7cd7967addfde648c566d0ecf25bf3d1e071c603b5101cfecc7bd0cbc284f`.

The official sending test uses ≥5 wpm, three consecutive minutes, plain language,
and at least 75 weighted characters. Candidate character speed is not graded;
≤5 errors is 100% and passes. The source comparison discloses both the French
CIR-3 five-error wording discrepancy and the approximate-spacing/PARIS mismatch.

Production Apple/web sending already had a 180-second allowance and compatible
text generation/grading. The change names that sourced duration in both engines,
uses it in both apps, and removes only the three sending-results tests' 120-second
launch overrides. Each flow additionally asserts the initial **3:00**. The DEBUG
fill hook still supplies the answer and manual Grade finishes promptly; neither
hook supplies a different deadline. Flexible speeds, early grading and on-screen
keys remain explicitly labelled sending practice / exam-style checks, not an
accredited qualification exam. Generator and grading behavior are unchanged.

New TS/Swift tests check the sourced duration, 12/5 profile, five PARIS words per
minute, and 32 generated sending passages' weighted length/allowed characters.
The shared fixture set adds a deterministic sending passage (≥75 weighted
characters, no receiving playback-duration constraint) and exact five/six
missing-character boundaries including figures and punctuation. Both engines
consume these same fixtures.

## iPhone: three methods × three iterations

**PASS: 9/9, zero failures or skips.** One bounded invocation, not until-success
retries. Each light/dark iteration runs the unchanged full default accessibility
audit, with no exception handler. Every prior assertion, audit call, five-second
results wait, and shared positioning/audit helper is unchanged.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam \
  -testPlan CanadianHamDefault \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -parallel-testing-enabled NO -test-iterations 3 \
  -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditMorseSendingResultsLight \
  -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditMorseSendingResultsDark \
  -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testMorseSendingPracticeUsesDebugHookAndPushesResultsScreen \
  -resultBundlePath /tmp/task-80-sending.xcresult test CODE_SIGNING_ALLOWED=NO
```

| Method (`CanadianHamPracticeUITests`) | Iteration 1 | Iteration 2 | Iteration 3 | Result |
|---|---:|---:|---:|---|
| `testAccessibilityAuditMorseSendingResultsLight` | 95.015 s | 117.173 s | 106.086 s | 3/3 PASS, full audits |
| `testAccessibilityAuditMorseSendingResultsDark` | 101.507 s | 84.622 s | 72.277 s | 3/3 PASS, full audits |
| `testMorseSendingPracticeUsesDebugHookAndPushesResultsScreen` | 80.814 s | 198.256 s | 95.690 s | 3/3 PASS, including PASS-result assertion |

Log/bundle: `/tmp/task-80-sending.log` / `/tmp/task-80-sending.xcresult`.
XCTest reports 951.439 s of test time; outer command ran 01:48:04–02:05:12 UTC,
including build/startup/cleanup. Whole-method times are not exam elapsed times.

The existing Grade preparation still swipes in the wrong direction after DEBUG
Fill, as documented in [TASK-65](task-65-flakes.md); XCTest auto-scrolls the Grade
tap. It did not prevent these nine passes with the official allowance. No local
positioning change was needed, and neither rejected TASK-65 preparation attempt
was reintroduced. This bounded result is not a guarantee against arbitrary future
host-load flakes.

## Packages, parity and macOS

All Apple commands used `xbuild` and the dedicated Xcode developer directory.
The sequential driver respected the shared build lock; no other build was killed.

```sh
(cd packages/morse-swift && \
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xbuild -scheme CanadianHamMorseEngine -destination 'platform=macOS' \
  -resultBundlePath /tmp/task-80-morse-swift.xcresult test)
bash scripts/check-engine-parity.sh
```

Morse Swift **6/6 PASS**, zero failures/skips, including all shared Morse fixtures:

| `MorseFixtureTests` method | Result | Seconds |
|---|---|---:|
| `testEveryMorseFixtureMatchesSwiftEngine` | PASS | 0.018 |
| `testGenerateMorseExamTextReportsUnsatisfiedConstraintsDistinctly` | PASS | 1.270 |
| `testMorseBeaconFlashSafetyMath` | PASS | 0.001 |
| `testRIC1Section82AndRIC3Section52SendingDurationAndProfile` | PASS | 0.001 |
| `testRIC1Section82SendingTextMeetsWeightedLengthAndCharacterSet` | PASS | 0.014 |
| `testVisualTapeAndHapticOutputMapping` | PASS | 0.001 |

Package log/bundle: `/tmp/task-80-morse-swift.log` /
`/tmp/task-80-morse-swift.xcresult`.

The requested parity script passes: basic engine TS **32/32**, Swift **22/22**,
log `/tmp/task-80-parity.log`. That existing script covers `fixtures/engine`,
not `fixtures/morse`; Morse parity is separately verified by the TS Morse suite
(**23/23**) and Swift suite above consuming the same Morse fixtures.

The full documented macOS app unit command passes **224/224**, zero failures/skips.
[Every test's result and duration](task-80-macos-unit-results.md) is committed.
No Apple test was rerun after these evidence/Backlog-only commits.

Command-wide load sampling (`/tmp/task-80-apple-load.log`) recorded 34 one-minute
load samples from 15.63 to 944.52, including lock waits and other lanes' work.
Those measurements show host contention, not causation for any test duration.

## Node/web and static gates

| Command | Result |
|---|---|
| `pnpm --filter @canadian-ham/morse-engine test` | PASS, 23 tests |
| `pnpm --filter @canadian-ham/web exec vitest run src/morse/sending/MorseSendingPracticeSection.test.tsx` | PASS, 14 tests; new fake-timer test verifies actual default 180-second deadline and ≥75 weighted-character passage |
| `pnpm test` | PASS: content-tools 250, Morse 23, calculator 127, web 283; reference/watch/release-permission gates pass |
| `pnpm typecheck` | Initial setup failure: `tsc` missing in fresh worktree; after `pnpm install --frozen-lockfile`, PASS for all packages/web |
| `pnpm build:web` | PASS, including official-reference-sheet exclusion gate; existing large-chunk warning |
| `pnpm --filter @canadian-ham/web audit:urls` | PASS, dist URL/CSP audit |
| `node scripts/check-apple-text-sources.ts --self-test` | PASS |
| `node scripts/check-apple-text-sources.ts` | PASS; no SwiftUI text/catalogue change |
| `node scripts/check-test-guard.mjs --self-test` | PASS |
| `node scripts/check-test-guard.mjs --base 0196bd85 --head HEAD` | PASS, no guarded changes; no approval marker needed |
| `git diff --check` | PASS |

Node logs: `/tmp/task-80-morse-ts.log`, `/tmp/task-80-web-sending.log`,
`/tmp/task-80-pnpm-test.log`, `/tmp/task-80-typecheck.log` (initial setup failure),
`/tmp/task-80-typecheck-installed.log`, `/tmp/task-80-install.log`,
`/tmp/task-80-build-web.log`, `/tmp/task-80-audit-urls.log`.
The web suite emits existing jsdom canvas warnings; all tests pass.

## Remaining coverage and review

No iPad, full iOS, tvOS, visionOS, or watchOS suites were run: this task explicitly
requested bounded sending tests on one iPhone plus macOS units. The shared Morse
package is linked by other Apple targets, so any required full platform suites
remain the coordinator's merge-batch responsibility, not claimed covered here.
No lesson figures, category layouts, localized strings, project membership or
accessibility exceptions changed. No PR or distribution build was created.
Independent branch/commit review is still required.
