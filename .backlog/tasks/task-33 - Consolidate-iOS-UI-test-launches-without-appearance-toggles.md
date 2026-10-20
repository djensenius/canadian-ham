---
id: TASK-33
title: Consolidate iOS UI test launches without appearance toggles
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-08 04:35'
updated_date: '2026-10-20 05:14'
labels:
  - apple
  - testing
  - ci
dependencies:
  - TASK-31
priority: high
ordinal: 71000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Task-31 attempted to combine iOS light/dark accessibility audits into one launch, but the iOS simulator SpringBoard crashed while snapshotting after in-test appearance changes. The safe remaining work is to find launch-sharing opportunities that stay within a single appearance per test.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 iOS UI audits share launches within one appearance where safe; no test switches XCUIDevice.shared.appearance after launch.
- [ ] #2 Before/after iOS UI test count and wall-clock timing are recorded in task notes.
- [ ] #3 Before/after audit inventory diff shows no loss of screen/state/appearance/region coverage.
- [ ] #4 Full iOS suite passes after consolidation.
- [ ] #5 CanadianHamLessonFiguresUITests runs in its own test plan; the default plan excludes it; AGENTS.md documents when to run it
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Separate figure audits into XcodeGen default/figure test plans first, split long ranges with exact figure/appearance preservation, document invocation, and verify regeneration determinism.
2. Capture baseline default iOS test counts/timing and a source-based audit inventory; identify only identical-state, single-appearance launch sharing opportunities.
3. Consolidate safe audit flows without changing shared/exception helpers or dropping assertions; record method-to-assertion and coverage mappings.
4. Run the default iOS suite and figure plan via nohup/xbuild on iPhone 17 Pro, use grep-only log polling, record per-test results and any flakes, and run focused static checks.
5. Verify AC evidence, finalize Backlog notes, commit and push for internal review; no PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner 2026-10-14: also move the per-lesson figure audits (CanadianHamLessonFiguresUITests) into a separate Xcode test plan run only when figures, lesson Markdown with figure directives, or the lesson reader change; default full-suite plan excludes it. Priority: next after the current Apple merge batch.

2026-10-15 merge batch (train-2026-10-15): testModule1LessonFiguresLightPart2 failed with 'Audit failed to complete in time' in the full iOS suite. That's the same timeout that forced the M8 split. When moving figure audits to their own plan, also split long figure ranges so each audit finishes reliably.

Figure plan implemented first: CanadianHamDefault excludes only CanadianHamLessonFiguresUITests; CanadianHamLessonFigures selects only that class. Split all 13 remaining two-lesson light ranges into single-lesson tests (32 -> 45 figure methods), preserving every existing figure/appearance and shared helper body. Historical Module 1 Part 2 now already contains one figure in L-001-03 following task-46 lesson splits, so it cannot be subdivided further without changing the audit itself. XcodeGen regenerated twice; complete project diffs byte-identical. Baseline default run launched via nohup (128 UI methods, unchanged audit flows). Initial test-plan decoding failed before tests because configurations.options was absent; corrected empty options and restarted as /tmp/task-33-baseline-v2.*.

Launch sharing committed as 5a3fc4be: core read-only screens 9->3 launches per appearance; sending main/lower/exam 2->1. All original assertions and audit call-line multisets retained. Four sending wrappers moved to two source-named combined methods; removal map and complete before/after coverage inventory are in docs/testing/task-33-ui-audit-inventory.md. Shared/exception/positioning helpers and every direct performAccessibilityAudit site remain byte-identical. Test guard self-test passes; diff flags exactly the four mapped wrapper deletions and passes with Test-guard-approved: task-33. Full after-default and figure runs are queued sequentially behind the baseline via nohup; no other builds killed.

Supervisor-approved baseline adjustment: current baseline single medium-detent audits passed in 322.972s dark and 311.446s light; full suites are known to take ~5 hours. Stop only this task own baseline process and use the existing full train-2026-10-17 baseline at main 029f2d49 (/tmp/train1017-ios.log: 138 UI + 142 unit tests, ~18,233 s UI), explicitly dated two days before the task branch point. Treat the two completed current medium-detent audits as a timed calibration sample; do not label the interrupted current baseline a full suite. Required complete after-default and figure-plan runs remain queued unchanged, without filtering or weakening coverage.
<!-- SECTION:NOTES:END -->
