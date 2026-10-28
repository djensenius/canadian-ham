---
id: TASK-79
title: Run figure audits on a quiet build host so Code=-56 timeouts can't happen
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-28T01:32:00Z'
updated_date: '2026-10-28T15:12:00Z'
labels:
  - accessibility
  - performance
dependencies: []
priority: medium
ordinal: 164000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner 2026-10-28 chose option 2, after the lazy reader was closed (#1049): Code=-56 'Audit failed to complete in time' only occurred at host load averages of about 150-1000 (two Apple lanes plus other projects sharing the machine). Make figure-plan runs happen on a quiet host: a runner script waits for low load, runs the figure plan through xbuild and records load samples; AGENTS.md forbids parallel Apple lanes while it runs. No app change, retry, filter or exception.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 scripts/run-figure-plan-quiet.sh waits until the 5-minute load average is at most 1.5x the core count (configurable), then runs the CanadianHamLessonFigures plan (or -only-testing selections passed through) via xbuild with one iPhone 17 Pro destination, samples load every 60 s into a log, and reports the max and median load next to the xcodebuild exit code
- [ ] #2 AGENTS.md documents the rule: run the figure plan only through this script, and the coordinator launches no other Apple lanes while it runs. The figure-plan command in AGENTS.md points to the script
- [ ] #3 Under the script, testModule7LessonFigureDarkSample passes 5/5 and testOhmsLawLessonFiguresAndAccessibilityLight/Dark pass 3/3 each, with no Code=-56. Per-run durations and load are recorded in docs/testing/task-79-quiet-figure-runs.md
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Replace the closed lazy-reader plan with the owner-approved quiet-host runner, fast fake-command integration tests, and concise figure-plan-only coordination rules. Do not modify app/tests/audits or the shared xbuild wrapper.
2. Validate shell syntax/style, the runner integration tests, pnpm test, Apple text sources and the test guard; commit and push the implementation milestone.
3. Run only M7 dark five iterations, then Ohms light/dark three iterations each, serially through the runner; record exact durations, results, max/median load and artifacts. Stop on any low-load Code=-56.
4. Commit/push the evidence milestone, verify each AC with evidence, and finalize TASK-79 only if all three pass.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Milestones pushed: e0e3ed7634f04bfae54039ced91b36f284bd4e89 adds baseline capture tests; 183c6870 converts shared LessonMarkdownView to LazyVStack with IDs on direct children and adds offscreen heading/Try-it-state and figure-return tests. Existing Practice/figure tests and all shared helpers/audits verified byte-identical to main (strip only new methods and compare entire files). Baseline /tmp/task-79-baseline.xcresult passed 2/2: appearance 183.893 s, top counts 41.418 s. At top: L-005-02 330 descendants / 285 static texts; L-007-01 285 / 235; longest UTF-8 lesson L-008-01 316 / 267. Twelve full-screen before-images exported to /tmp/task-79-baseline-attachments; after smoke and full figure plan queued. Load sampled each minute; one-minute average exceeded 600 during baseline; no other processes modified.

Coordinator approval 2026-10-27: Practice scrollUntilPartiallyVisible now checks element.exists before reading its frame, matching the existing figure-class helper. Existing-element behavior and every assertion/audit unchanged. This is required because lazy offscreen targets do not exist yet; smoke failure at the old unguarded .frame is preserved in /tmp/task-79-after.xcresult (3/4 passed; offscreen-heading test failed). Coordinator also approved scrolling to each figure before TASK-65 structural uniqueness assertions, which are unchanged, plus a new assertion that the distant Ohms wheel is absent at launch. No other pre-existing helper or audit changed. After top counts: 59/27, 56/26, 58/25 descendants/static texts for L-005-02/L-007-01/L-008-01; figure sheet-return test passed 33.458 s; appearance capture passed 141.269 s.

AC4 coordinator approval 2026-10-27: all six AXXXXL lesson-content samples pixel-identical; default top/middle text +/-1 native pixel, bottom summary exact; footer +1 px light / +3 px dark (1 pt), registered residuals <=3/255; system clock/glass-back chrome and subpixel figure/table rasterization differ. No growing text drift, text/wrapping/spacing tokens/colour/size/style change. Exact raw/registered deltas and hashes in docs/testing/task-79-evidence.json; four after-images total 1,112,236 bytes, originals local. Approved differences accurately include corrected 3-px dark footer case.

The single targeted rerun after the approved existence guard passed: testLessonReaderOffscreenHeadingsAndTryItStateSurviveScrolling 566.029 s, /tmp/task-79-navigation-fix.xcresult, exit 0. This verifies beyond-first-screen headings in authored order and Try-it expansion retained after scrolling down to Summary and back, then collapse. Full figure-plan driver is now waiting on the shared xbuild lock. No test/audit skipped or filtered beyond the explicitly selected targeted test invocation.

Coordinator-approved early stop of first full figure plan after failures: /tmp/task-79-figures.xcresult finalized (exit75 following SIGINT, not timeout); structural test PASS 684.430 s; M1 dark PASS 201.552 s; M1 LightPart1 FAIL 156.861 s and NextLesson FAIL 155.781 s (Dynamic Type unsupported on Figure text equivalent); M1 LightPart2 FAIL 153.659 s (contrast on visible ordinary paragraph); Part3 cancelled, all later methods not run. No Code=-56. Complete issues/element screenshots exported to /tmp/task-79-figures-failure-attachments; originals retained. First failing M1 light method then PASS on detached origin/main 6a449802614303741ee5aa07f973803c46f535b7: 388.729 s, /tmp/task-79-main-comparison.xcresult, exit0. Reader SHA256 byte-identical to original main; detached comparison worktree removed. This establishes a lazy-reader regression, not a passing full plan. Investigating app-side control font/layout; audits/handlers untouched.

Blocked; stopping per coordinator explicit failure branch, not marking Done. Required eager main baseline was completed ONCE and PASS (388.729 s, origin/main 6a449802, result bundle main-comparison). Temporary diagnostic never committed and removed: dynamicType raw65536, Figure text equivalent StaticText frame before (52,872,298,28.333), at issue (52,199,298,28.333); scroll/content geometry changed during audit. No conclusive proof of node reuse. Semantic-font/intrinsic-height attempt failed all3 and reverted 2a83b14f. Coordinator-approved disclosure id(dynamicTypeSize) experiment also FAILED first method 206.499 s (/tmp/task-79-dynamic-type-id.xcresult, exit65), reverted 5a932cc7. Source is exactly the first lazy prototype again; no rejected fixes/grouping remain. Shared audit handlers untouched; approved existence guard and structural navigation/assertion are the only old-test adaptations. Full results/issues/remaining checks are committed in docs/testing/task-79-{lazy-lessons.md,results.json,evidence.json}. Full figure completion, repeated M7/Ohm, targeted old reader/iPad/title tests, macOS, tvOS/visionOS builds and full l10n export outstanding; individual audit-duration comparisons outstanding. Source/text/guard self-tests and parity checks pass; no skips/exceptions/retry wrapper. All ACs remain unchecked. Handoff /tmp/task-79-handoff.md; no PR.

Resumed under coordinator's bounded containment experiment direction. Fully read /tmp/task-79-handoff.md and AGENTS.md; previous attempts remain reverted and all ACs unchecked. No full plan, repeated iterations, audit changes, exception/filter/skip/retry/ignore or hidden content authorized.

FINAL containment experiment completed under coordinator direction and FAILED all3, then exactly reverted. Attempt e7a03cf5d64f4613c10e3cd72eb7189f0e175dc7; revert a08980ac89535a838bfb7cc0076c81c4e74645fe. One serial xbuild invocation per M1 light method in CanadianHamLessonFigures, iPhone17Pro, exactly1 visit each: Part1 FAIL179.412s, NextLesson FAIL204.911s, Part2 FAIL174.877s; all finalized Dynamic Type unsupported, exit65, no cancellation/retry/Code=-56. Elements: Figure text equivalent; Club-net plans; Identify the station, not just the person speaking... paragraph (full label committed). Shared handler does not log AX frames; failure screenshot-derived bounds in points: (52,199,298,28), (52,193,83.667,14.333), and approximate (40,191.333,322,86). First2 unique exact RGB crop matches; Part2 subpixel-rasterization best match, explicitly not exact AX geometry. Per-test one-minute load min-max:72.84-434.12(4),395.32-466.08(5),343.21-430.49(4), command-wide including build/lock wait; not normal-load evidence. Bundles /tmp/task-79-contain-{part1,next-lesson,part2}.xcresult; all issues, attachment paths/hashes, frame provenance, commands and load in results JSON/docs. Post-failure simulator diagnostic collection warned simctl lookup failed, but completed audit failures/screenshots/bundles finalized. Test guard/self-test passed with .contain present. Reader restored byte-for-byte to resumed HEAD/original lazy prototype (SHA256 372ea91b3d528f9298e2c1b0ecc5e29a8dcc9fd51ee1df6eb3f9bffdfe6d3c93); entire UI test files/shared handlers unchanged. No hidden content, new exception/filter/skip/retry/ignore, audit/helper weakening or timeout change. Failure branch: no navigation/count reruns, full figure plan or repetitions launched; no further experiment. All ACs unchecked; In Progress/blocked, coordinator will close lazy approach. Updated /tmp/task-79-handoff.md; push and stop.

Coordinator outcome 2026-10-28: the lazy approach is closed. The LazyVStack reader (branch task-79-lazy-lessons, head a08ac313) cut top-of-lesson AX trees about 5x but caused genuine full-audit regressions in the M1 light figure tests (Dynamic Type and contrast), because XCTest's audit self-scroll meets changing lazy height estimates (5951→5743 pt). The same test passes on eager main. Three bounded fixes failed and were reverted. Evidence: docs/testing/task-79-* (PR #1049). Owner 2026-10-28 then chose option 2: quiet-host figure runs.

Quiet-host implementation milestone: scripts/run-figure-plan-quiet.sh waits on 5-minute load (default 1.5 x logical CPUs, 7200s timeout), invokes unchanged serial figure-plan xbuild, logs runtime 1/5/15-minute loads every 60s plus endpoints, preserves xbuild exit and reports max/median/test lines. AGENTS requires the script and no concurrent coordinator Apple lanes including the wait. Six fake-command integration scenarios run via pnpm test without Xcode, including macOS Bash 3.2 empty passthrough. bash -n, shellcheck, integration tests, Apple text-source check/self-test, guard self-test/branch diff and pnpm test passed. No app, UI tests, audits, plans, shared helpers or shared xbuild edits. Runtime M7/Ohms repetitions are next, not yet claimed passed.
<!-- SECTION:NOTES:END -->
