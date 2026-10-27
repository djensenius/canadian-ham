# TASK-65: targeted iPhone flake investigation

## Scope and historical evidence

This investigation covers the post-Grade Morse sending-results heading and the
Ohm’s-law/M7 figure audit timeouts from [TASK-33](task-33-ios-results.md). It does
not change accessibility exceptions or investigate the separate lesson-quiz and
Try-it contrast findings appended to TASK-65’s historical notes.

TASK-33 recorded:

- Sending-results light: the existing five-second heading existence assertion
  failed, 78.654 s; unchanged isolated rerun passed, 91.923 s.
- Ohm’s-law dark: XCTest accessibility audit `Code=-56`, “Audit failed to complete
  in time”, 471.508 s; unchanged isolated rerun passed, 1217.286 s.
- M7 dark: the same `Code=-56`, 230.276 s; unchanged isolated rerun passed,
  257.999 s.

The literal historical failure lines are retained in the TASK-33 document. The
old `/tmp/task-33-*.xcresult` directories now contain only `Data/`, not the required
`Info.plist`; `xcresulttool` cannot reopen them. No claim is made to have recovered
an original failed Grade hit point or hierarchy from those incomplete bundles.

## Sending: app-side investigation and local preparation fix

In `MorseSendingPracticeView.gradeExam`, Grade synchronously finalizes any held
key/character, cancels the countdown, scores the text, and assigns
`presentedResult`. There is no awaited teardown, deliberate transition delay or
`withAnimation` in this path. The current `MorseSendingKeyer` queues audio
operations in a task/actor chain; the actor’s fade/drain does not block Grade.
The 150 ms accessibility-focus request starts in the heading’s `onAppear`, so
it does not gate heading creation. The audio lifecycle has also changed under
TASK-41 since the historical TASK-33 failures. No new app-side race or delay was
demonstrated, and no app change is made here.

A concrete test-preparation defect **was** reproduced: Debug Fill is below Grade,
but `auditMorseSendingResults` used `scrollUntilHittable(grade)`, a shared helper
that only swipes up. After filling at the lower position, all ten baseline visits
issued eight further upward swipes, moving away from Grade. XCTest then had to
scroll the button into view as part of synthesizing the tap. For example, dark
iteration 1 records:

```text
t = 96.53s Tap "morse-sending-grade-exam-button" Button
t = 96.68s     Scroll element to visible
t = 96.81s     Computed hit point {253.49999999999997, 189.1666666666666} after scrolling to visible
t = 97.13s Waiting 5.0s for "morse-sending-results-heading" Any to exist
```

The supervisor approved a local fix on 2026-10-27: use the **unchanged**
bidirectional `scrollUntilPartiallyVisible`, the existing
`positionElementInMiddleVisibleBand`, and an additional hittability assertion
before tapping. The exact same wrong-direction pattern exists in
`testMorseSendingPracticeUsesDebugHookAndPushesResultsScreen` and is fixed there
too. The held-straight-key hook is below Start, so its forward-only scrolling is
not changed. There are no other Grade/Check return-to-earlier-control callers in
this file that demonstrate the same defect.

The five-second, condition-based results-heading wait and every subsequent
assertion/audit remain intact. This fixes a demonstrated tap-precondition defect;
because baseline heading assertions all passed, it does **not** prove that this
was the unique cause of the historical intermittent missing heading.

### Baseline sending repetitions

Code baseline: `3872dc5410517d64172ed1b20c2d7f3d287eb606` (main code at branch
creation; intervening task-metadata commits do not change app/tests).
Raw log: `/tmp/task-65-baseline-sending.log`; complete current result bundle:
`/tmp/task-65-baseline-sending.xcresult`. `xbuild` exit 0; outer wall 1083 s
(including fresh compilation, simulator launch, sampling and cleanup).

| Method | Iteration 1 | 2 | 3 | 4 | 5 | Pass rate |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| `testAccessibilityAuditMorseSendingResultsLight` | 85.078 | 80.918 | 86.145 | 81.486 | 78.102 | 5/5 |
| `testAccessibilityAuditMorseSendingResultsDark` | 106.122 | 86.385 | 93.389 | 84.131 | 83.544 | 5/5 |

Times are per-test seconds. Each repetition runs the original full default
accessibility audit. There were no automatic failure retries.

## Figure audit cost: source findings

`PlatformLessonMarkdownView.swift` uses an eager `VStack` over the rendered lesson
blocks. Thus an inline-figure audit traverses the **whole lesson**, not only the
one visible figure. The figure test positions the target below the opaque
navigation bar; it does not restrict the audit to that figure. Offscreen lesson
content is still exposed, and the unchanged approved handler filters only the
specific occluded-content contrast false positives, not other findings.

The inline figures are asset-catalog `Image` views, not live SVG path hierarchies.
There is no source-level expansion of every vector path into accessibility nodes.
Text equivalents use initially collapsed `DisclosureGroup`s: M7’s sampled figure
has five authored rows; the Ohm’s-law wheel has twelve, and the two triangles have
none. No source-level large duplicated text equivalent was found.

Both shared figure audit helpers call the full default
`performAccessibilityAudit`. Neither catches/retries `Code=-56`; no retry wrapper,
new handler, narrowed audit type, lazy-stack conversion or content suppression is
introduced. A lazy-stack change would affect scrolling/accessibility throughout
the lesson reader and is explicitly outside this task’s approved scope.

The supervisor approved a bounded structural regression test in
`CanadianHamLessonFiguresUITests`: one launch each for L-005-02 and L-007-01, one
image button per figure, absent text-equivalent rows while collapsed, exactly one
of each authored row after expansion, and `keepAlways` tree/count attachments.
It adds no audits and cannot replace any existing audit. Existing plan membership
puts it in `CanadianHamLessonFigures` and excludes the whole class from the
default plan without any test-plan edits.

## Reproduction method and host observations

All runtime tests use exactly `platform=iOS Simulator,name=iPhone 17 Pro`, through
`xbuild`, with parallel testing disabled. Only the affected methods are selected;
no full suites are run. `-test-iterations 5` requests five executions regardless
of result, not a pass-until-success retry. Each execution retains its own result.

The sending baseline command was:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild \
  -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam \
  -testPlan CanadianHamDefault \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -parallel-testing-enabled NO -test-iterations 5 \
  -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditMorseSendingResultsLight \
  -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditMorseSendingResultsDark \
  -resultBundlePath /tmp/task-65-baseline-sending.xcresult \
  test CODE_SIGNING_ALLOWED=NO
```

The figure baseline selects only:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild \
  -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam \
  -testPlan CanadianHamLessonFigures \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -parallel-testing-enabled NO -test-iterations 5 \
  -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testOhmsLawLessonFiguresAndAccessibilityLight \
  -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testOhmsLawLessonFiguresAndAccessibilityDark \
  -only-testing:CanadianHamUITests/CanadianHamLessonFiguresUITests/testModule7LessonFigureDarkSample \
  -resultBundlePath /tmp/task-65-baseline-figures.xcresult \
  test CODE_SIGNING_ALLOWED=NO
```

The driver samples UTC time, `uptime` and the top CPU processes each minute,
including lock wait. Files are `/tmp/task-65-<run>-load.log`. The host has ten
logical CPUs. Initial load at 13:25Z was 14.61/7.27/4.56; it subsequently exceeded
490 in the one-minute average during the sending run, despite those ten tests
passing. Three waiting `lockf` processes each used roughly a CPU core in several
samples; other samples show substantial OrbStack, simulator startup,
`diagnosticd`, and `fseventsd` activity. No processes were killed to reduce load.

The figure command waited on the shared build lock after the sending baseline.
Samples during this wait are **not figure-test execution load**. Lock wait is
included in outer wall timing but not per-test timing. Contention is observed;
there is not a controlled experiment proving it causes a particular audit
failure or a benchmark proving a runtime speedup.
