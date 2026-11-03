# TASK-65: bounded iPhone flake investigation

**Status: In Progress. Neither historical flake is claimed fixed.** Both sending
preparation attempts failed validation and were reverted under the coordinator’s
explicit fallback decision. The final change adds only a figure-tree regression
test and investigation evidence. All original tests, assertions, full audits and
shared helpers are byte-identical to main
`3872dc5410517d64172ed1b20c2d7f3d287eb606`; no app or test-plan changes remain.

## Sending: evidence and rejected fixes

The [historical failure](task-33-ios-results.md) was the five-second
`morse-sending-results-heading` wait after Grade (78.654 s); an unchanged isolated
rerun passed (91.923 s). The old TASK-33 bundles now lack `Info.plist`, so their
original failed hit point cannot be recovered with `xcresulttool`.

Current `gradeExam` synchronously finalizes keying, cancels the countdown, scores
and sets `presentedResult`. Audio work is queued asynchronously; the heading’s
150 ms focus request runs after `onAppear`. No awaited teardown/animation or new
app-side delay was demonstrated. Audio handling changed under TASK-41 after the
original failure, further limiting historical attribution.

A real preparation defect was reproduced in all ten baseline visits: Debug Fill
is **below** Grade, but the shared `scrollUntilHittable` only swipes up. It issues
eight wrong-direction swipes, then XCTest auto-scrolls during the Grade tap:

```text
baseline dark iteration 1:
t=96.53 Tap "morse-sending-grade-exam-button"
t=96.68 Scroll element to visible
t=96.81 Computed hit point {253.5, 189.1667} after scrolling to visible
t=97.13 Waiting 5.0s for "morse-sending-results-heading" Any to exist
```

| Version/method | Per-iteration seconds | Pass rate |
| --- | --- | --- |
| Baseline light | 85.078, 80.918, 86.145, 81.486, 78.102 | 5/5 |
| Baseline dark | 106.122, 86.385, 93.389, 84.131, 83.544 | 5/5 |
| Rejected middle-band positioning, dark | 188.408, 163.525, 167.180, 169.576 | 0/4; fifth interrupted; light not run |
| Rejected bidirectional-scroll + visibility assertion, light | 56.867, 61.231, 61.134 | 0/3 |
| Rejected bidirectional-scroll + visibility assertion, dark | 78.857, 55.531, 61.085 | 0/3 |

Attempt 1 reused the unchanged audit-positioning helper. Its whole-screen scans
outlasted the 120 s exam deadline: iteration 1 started the exam at t61.93, then
scanned Grade from t79–183; automatic grading removed the cached elements. The
failure snapshot contained only `morse-sending-results-start-another-button`.
The supervisor authorized stopping **only this lane’s** driver/build processes;
the four completed failures remain recorded, not represented as passes.

Attempt 2 kept only bidirectional scrolling plus existing full-visibility and
hittability assertions. All six failed **before tap/audit**: coarse scrolling left
Grade at y59–125.33 while the visible area starts at y117. The coordinator had
approved reverting sending completely if this bounded attempt failed; this was
done. No third approach or longer timeout was introduced. The five-second heading
wait and every original audit remain unchanged. Baseline sending passes ran the
full audits; the rejected attempts did not reach them.

The original navigation method was also run once after restoration to main’s
source; it passed (119.757 s). This is not validation of either rejected fix.

## Figure baseline: 12 completed iterations, coordinator stopped early

| Method | Iteration 1 | 2 | 3 | 4 | 5 | Pass rate |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| M7 dark sample | 314.139 | **FAIL 295.085** | 318.549 | 328.430 | 308.442 | 4/5 |
| Ohm’s-law dark | 1887.641 | 1783.377 | 1864.703 | 1920.290 | 1852.743 | 5/5 |
| Ohm’s-law light | 1808.428 | 1832.218 | cancelled | not run | not run | 2/2 completed |

The coordinator stopped the original figure driver/build after it had held the
shared lock for approximately **4.5 hours**. Light iteration 3 was interrupted;
iterations 4–5 were not executed. This is a partial, failing baseline, **not** a
clean completed run. The cancelled bundle may be incomplete; the console log
preserves each completed iteration.

M7 iteration 2 reproduced the original failure in the unchanged full-default
shared helper (line 343 at the tested revision):

```text
Error Domain=com.apple.xcode.xctest.accessibilityAudit Code=-56
"Audit failed to complete in time"
```

The 295.085 s is **whole-method time**, mostly scrolling/positioning, not audit
time. Geometry queries ended at t277.65; the timeout appeared before teardown at
t293.67 (about 16 s in the audit call, no issue-handler callbacks logged). Passing
M7 screenshot-to-termination intervals were approximately 12–17 s. Ohm’s-law
methods retain all three inline audits, three enlarged-figure audits and the
expanded text-equivalent audit. No retry, filtering or exception change was made.

## Host observations and limits

UTC `uptime`/top-process samples were recorded each minute on a ten-logical-CPU
host, including lock waits. Relevant one-minute load ranges:

| Run/sampling scope | Observations |
| --- | --- |
| Baseline sending, entire command | 16.47–401.91; ten full audits passed |
| Active figure execution, 14:58:44–19:25:00Z | 49.93–524.86; median 73.45 (263 samples) |
| M7 failed iteration interval | 15:03:47Z: 261.08/331.17/288.12; 15:07:29Z: 150.43/247.49/262.78 |
| Rejected middle-band sending, active samples | 134.00–314.68 |
| Final rejected sending attempt, active samples | 128.20–259.42 |

Several samples show three waiting `lockf` processes each using about one CPU
core, plus simulator startup, OrbStack, `diagnosticd` and `fseventsd` activity.
No other lane’s process was stopped. Active-figure samples exclude the preceding
lock wait. These observations document contention, **not proof** that host load
caused the timeout; tests also passed under higher load. Outer command wall times
include lock waits/builds/cleanup and must not be confused with per-test times.

## Reproduction and raw evidence

All runtime runs used `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`
with `xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam`, one
destination `platform=iOS Simulator,name=iPhone 17 Pro`,
`-parallel-testing-enabled NO`, and `test CODE_SIGNING_ALLOWED=NO`. No full suites
were run. `-test-iterations` repeats every selected test, not until-success retries.

- `CanadianHamDefault`, `-test-iterations 5`, only
  `CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditMorseSendingResultsLight`
  and `.../testAccessibilityAuditMorseSendingResultsDark`: baseline and rejected
  middle-band attempt.
- `CanadianHamDefault`, same two methods, `-test-iterations 3`: final rejected
  attempt, coordinator-approved bound.
- `CanadianHamLessonFigures`, `-test-iterations 5`, only
  `CanadianHamUITests/CanadianHamLessonFiguresUITests/testModule7LessonFigureDarkSample`
  and `CanadianHamUITests/CanadianHamPracticeUITests/testOhmsLawLessonFiguresAndAccessibilityLight`
  / `.../testOhmsLawLessonFiguresAndAccessibilityDark`: partial figure baseline.

Logs/result bundles use `/tmp/task-65-<run>.log` / `.xcresult`, with runs
`baseline-sending`, `baseline-figures`, `after-sending` (rejected middle-band),
`final-sending` (rejected minimal attempt), `final-sending-navigation`, and
`figure-tree`. Load files are `/tmp/task-65-<run>-load.log`. The two deliberately
interrupted runs do not have successful completion summaries. Driver commands
are retained in `/tmp/task-65-baseline.sh` and `/tmp/task-65-final.sh`.

## Structural regression and accessibility-tree counts

`testLessonFigureTextEquivalentsStartCollapsedAndExposeEachRowOnce` adds one launch
per lesson, no audits, and `keepAlways` debug-description/count attachments.
Existing plan membership includes its class only in `CanadianHamLessonFigures`,
not the default plan. It asserts each image button **and** explicit Enlarge
button occurs once, no collapsed text-equivalent rows, and exactly one of each
row after expansion.

First invocation exited 137: `xcodebuild` received SIGKILL before test execution;
no counts were produced and the cause is unknown. The supervisor approved one
identical-method rerun, not a changed test or timeout retry. It **passed 552.210 s**,
exit 0, no skips; outer wall 614 s. Log/bundle:
`/tmp/task-65-figure-tree-rerun.log` / `.xcresult`. All eight retained text
attachments were exported to `/tmp/task-65-figure-tree-rerun-attachments/`
(`manifest.json` maps tree/count names to files). Eleven command-wide load samples
ranged 110.09–337.82 (one-minute average).

| Lesson/state | All descendants | Static texts | Buttons | Scroll views | Text-equivalent rows |
| --- | ---: | ---: | ---: | ---: | ---: |
| L-005-02 collapsed | 331 | 285 | 18 | 2 | 0 |
| L-005-02 expanded | 343 | 297 | 18 | 2 | 12 |
| L-007-01 collapsed | 286 | 235 | 15 | 4 | 0 |
| L-007-01 expanded | 291 | 240 | 15 | 4 | 5 |

These are XCTest query counts for the **whole application tree** at the figure,
not counts of visible/focusable elements. Expansion adds exactly the authored
12/5 rows; no duplicated figure controls or text-equivalent rows were found.
`PlatformLessonMarkdownView.swift` eagerly renders the entire lesson in a
`VStack`, so an inline-figure audit sees hundreds of elements, including offscreen
lesson text. This is a plausible cost contributor, not demonstrated timeout
causality. Figures are asset-catalog images, not live SVG-path accessibility
subtrees. No app-side duplication fix, lazy conversion or audit change was made.

## Checks and owner decision

- macOS `xbuild ... -destination 'platform=macOS,arch=arm64' build-for-testing
  SDKROOT=macosx SUPPORTED_PLATFORMS=macosx CODE_SIGN_IDENTITY=-
  CODE_SIGNING_ALLOWED=YES`: **TEST BUILD SUCCEEDED**, exit 0. Outer wall 3451 s
  includes the shared-lock wait; `/tmp/task-65-macos-build-for-testing.log`.
- Text-source check/self-test and test-guard/self-test pass. A source comparison
  proves PracticeUITests and all pre-existing figure tests/helpers/audits are
  byte-identical to main; only the new structural method differs.
- No iPad, tvOS, visionOS, watchOS or full macOS runtime suites were run: final
  source changes are confined to the iOS figure-test target. No app text/catalogue
  changed. An optional full localization-export check was interrupted while
  waiting for the lock; its independent text-source gates passed.

**Owner decision required; TASK-65 remains In Progress:**

1. **Timeout-only shared-helper retry:** M7 timed out once in five full audits;
   the other four passed, as did all seven completed Ohm’s-law visits. Approve at
   most one rerun of the **full default audit**, only for `Code=-56`; any real
   finding must still fail. This changes a shared helper and needs owner approval.
   No such retry exists or was added here.
2. **Lazy long-lessons follow-up:** evaluate reducing eager exposure of 331/286
   descendants (285/235 static texts while equivalents are collapsed). A
   `LazyVStack` may reduce tree/snapshot cost but changes every lesson’s scrolling
   and audit behaviour; it requires separate scope and validation, not a local
   figure-test workaround.

**Sending open question, not a third option:** is the fixture’s 120 s auto-grade
too short for UI tests under heavy host load? Attempt 1 hit that deadline during
preparation; attempt 2 instead exposed a partially occluded Grade button. Neither
validated a fix. Both changes were reverted, and the original sending flake is
still unresolved.
