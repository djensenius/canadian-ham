---
id: TASK-33
title: Consolidate iOS UI test launches without appearance toggles
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-08 04:35'
updated_date: '2026-10-20 10:40'
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

Baseline adjustment approved by supervisor: use full train-2026-10-17 evidence at 029f2d49, explicitly distinguish its older membership and known failure from current source counts, and use the completed current dark/light calculator audits as a timing calibration. Complete the after-default and figure runs in full.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner 2026-10-14: also move the per-lesson figure audits (CanadianHamLessonFiguresUITests) into a separate Xcode test plan run only when figures, lesson Markdown with figure directives, or the lesson reader change; default full-suite plan excludes it. Priority: next after the current Apple merge batch.

2026-10-15 merge batch (train-2026-10-15): testModule1LessonFiguresLightPart2 failed with 'Audit failed to complete in time' in the full iOS suite. That's the same timeout that forced the M8 split. When moving figure audits to their own plan, also split long figure ranges so each audit finishes reliably.

Figure plan implemented first: CanadianHamDefault excludes only CanadianHamLessonFiguresUITests; CanadianHamLessonFigures selects only that class. Split all 13 remaining two-lesson light ranges into single-lesson tests (32 -> 45 figure methods), preserving every existing figure/appearance and shared helper body. Historical Module 1 Part 2 now already contains one figure in L-001-03 following task-46 lesson splits, so it cannot be subdivided further without changing the audit itself. XcodeGen regenerated twice; complete project diffs byte-identical. Baseline default run launched via nohup (128 UI methods, unchanged audit flows). Initial test-plan decoding failed before tests because configurations.options was absent; corrected empty options and restarted as /tmp/task-33-baseline-v2.*.

Launch sharing committed as 5a3fc4be: core read-only screens 9->3 launches per appearance; sending main/lower/exam 2->1. All original assertions and audit call-line multisets retained. Four sending wrappers moved to two source-named combined methods; removal map and complete before/after coverage inventory are in docs/testing/task-33-ui-audit-inventory.md. Shared/exception/positioning helpers and every direct performAccessibilityAudit site remain byte-identical. Test guard self-test passes; diff flags exactly the four mapped wrapper deletions and passes with Test-guard-approved: task-33. Full after-default and figure runs are queued sequentially behind the baseline via nohup; no other builds killed.

Supervisor-approved baseline adjustment: current baseline single medium-detent audits passed in 322.972s dark and 311.446s light; full suites are known to take ~5 hours. Stop only this task own baseline process and use the existing full train-2026-10-17 baseline at main 029f2d49 (/tmp/train1017-ios.log: 138 UI + 142 unit tests, ~18,233 s UI), explicitly dated two days before the task branch point. Treat the two completed current medium-detent audits as a timed calibration sample; do not label the interrupted current baseline a full suite. Required complete after-default and figure-plan runs remain queued unchanged, without filtering or weakening coverage.

Required after-default run: changed core audits passed dark/light 90.380/95.254s; combined sending main/lower/exam passed 77.450/78.113s. Unchanged testAccessibilityAuditMorseSendingResultsLight failed at the 5-second results-heading wait after Grade (line1708), before its audit; dark passed67.311s; full log /tmp/task-33-after.log. Supervisor decision: if an isolated unchanged rerun passes, AC4 may be checked explicitly as full suite except this documented flake, with both log paths in task/PR body; if it fails again, leave TASK-33 In Progress. Search found no existing matching task; a separate low-priority follow-up tracks the post-Grade heading flake.

Supervisor-approved plan refinement after full-run timeout: testOhmsLawLessonFiguresAndAccessibilityDark failed in unchanged audit code with accessibilityAudit Code=-56, Audit failed to complete in time (471.508s). Inspection confirms both light/dark methods cover figures/text equivalent only; moved both intact by exact-method plan selection into CanadianHamLessonFigures and out of CanadianHamDefault. No helper or assertion changed. Final UI membership124 default +47 figure. The active126-method default run is a superset of final default membership; the required figure run will also exercise both moved methods. Queue an isolated unchanged dark rerun after figure and sending-flake reruns. Supervisor accepts documented timeout plus isolated pass; otherwise keep In Progress.

Required after-default run completed:190 unit tests passed;126 UI methods (superset of final124) with3 unchanged platform/evidence skips and2 discussed failures, UI elapsed11390.378s, outer wall11533s. Required figure run has an additional unchanged single-figure timeout: testModule7LessonFigureDarkSample Code=-56 at293,230.276s; cannot split its one-lesson/one-figure range further. Supervisor accepts each documented unchanged failure if its isolated rerun passes; TASK-65 now tracks sending heading wait + Ohm dark + M7 dark timeouts together. Host load sampled2026-10-20T10:39:35Z:81.94/81.56/88.02, testmanagerd99.9%CPU, lockf84.9%/84.1%, diagnosticd55.8%, simulator diagnosticd50.2%; one active xcodebuild. No other lane process touched; load does not prove causation. All three isolated reruns are queued sequentially after the figure run.
<!-- SECTION:NOTES:END -->
