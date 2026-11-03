---
id: TASK-33
title: Consolidate iOS UI test launches without appearance toggles
status: Done
assignee:
  - '@worker'
created_date: '2026-10-08 04:35'
updated_date: '2026-10-20 12:14'
labels:
  - apple
  - testing
  - ci
dependencies:
  - TASK-31
references:
  - docs/testing/task-33-ui-audit-inventory.md
  - docs/testing/task-33-ios-results.md
priority: high
ordinal: 71000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Task-31 attempted to combine iOS light/dark accessibility audits into one launch, but the iOS simulator SpringBoard crashed while snapshotting after in-test appearance changes. The safe remaining work is to find launch-sharing opportunities that stay within a single appearance per test.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 iOS UI audits share launches within one appearance where safe; no test switches XCUIDevice.shared.appearance after launch.
- [x] #2 Before/after iOS UI test count and wall-clock timing are recorded in task notes.
- [x] #3 Before/after audit inventory diff shows no loss of screen/state/appearance/region coverage.
- [x] #4 Full iOS suite passes after consolidation.
- [x] #5 CanadianHamLessonFiguresUITests runs in its own test plan; the default plan excludes it; AGENTS.md documents when to run it
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Separate all per-lesson figure audits into CanadianHamLessonFigures via XcodeGen testPlans, including the two pure-figure Ohms-law integration methods; default plan excludes them. Split13 multi-lesson ranges while preserving all figures/assertions/helpers and document exact invocation.
2. Use the supervisor-approved historical full baseline at029f2d49 plus the two current pre-consolidation calculator audits as calibration; distinguish historical membership/content/load from current counts and timing.
3. Share only read-only single-appearance compact core launches and identical Morse sending main/lower/exam fixtures; retain every distinct assertion/audit and document four removed wrapper mappings and the complete audit inventory.
4. Run one complete after-default suite (126-method superset of final124), one complete47-method figure plan, and only the three unchanged failed methods as isolated reruns; retain all failures/skips, per-test results, wall clocks and load/FluxTerm-lock context.
5. Verify source/helper/figure coverage identity, test guard with approved marker and two deterministic XcodeGen regenerations; record TASK-65 residual flakes. Finalize evidence/ACs, commit and push for internal review without opening a PR.
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

Final AC evidence (2026-10-20):
AC1: core read-only launches9->3 and sending main/lower/exam2->1 per appearance,22->8 total. Changed full-run methods all passed: core dark/light90.380/95.254s, combined sending77.450/78.113s. One appearance per launch; terminate-first teardown restores light. Four removed wrapper assertion mappings are in docs/testing/task-33-ui-audit-inventory.md. Shared/exception/positioning helpers and all9 direct audit sites remain byte-identical.
AC2: historical before baseline029f2d49 (/tmp/train1017-ios.log),142 unit +138 UI including31 figure methods,3 skips/1 known historical failure, UI elapsed18233.683s. This baseline is more than2 days older than branch point e7a1dfa7 and is not a controlled benchmark. Current pre-consolidation calculator sample dark322.972s/light311.446s versus historical281.381s/286.590s,11.7% slower combined. Source before128 non-matrix UI +32 figure-class methods; final124 default UI +47 figure-plan UI. Required after-default full run126 UI (superset of final124),190 units passed, UI elapsed11390.378s, outer wall11533s. Figure47 UI, elapsed11444.382s, outer11520s. Per-test output, literal failures, counts and timing metadata are committed in docs/testing/task-33-ios-results.md. Raw historical/current wall differences are not attributed wholly to consolidation.
AC3: inventory proves24 changed screen/state/appearance/region tuples before and after; all37 light lesson ranges/39 light figures +8 dark samples preserved, plus all inline/enlarged/text-equivalent integration assertions. Exact assertion/audit statement multisets match edited flows; setup is shared once. No audit, appearance, region or distinct assertion removed.
AC4 accepted supervisor wording: full suite passed except unchanged tests that passed targeted reruns. Full default /tmp/task-33-after.log had3 existing skips and2 unchanged failures: sending-results light heading wait78.654s and Ohms-law dark timeout471.508s. Isolated /tmp/task-33-sending-results-rerun.log passed91.923s (wall208s,exit0); /tmp/task-33-ohms-dark-rerun.log passed1217.286s (wall1253s,exit0). Figure full /tmp/task-33-figures.log had only M7 dark timeout230.276s; /tmp/task-33-m7-dark-rerun.log passed257.999s (wall402s,exit0), run by coordinator after worker timeout. Both moved Ohms-law methods also passed the figure full run (dark1316.588s/light1321.591s). Neither full run is represented as a clean exit0 result. Keep all failure/rerun log paths and this qualified wording in the PR body. TASK-65 tracks all3 residual flakes; host load81.94/81.56/88.02 and coordinator-confirmed FluxTerm builds sharing the lock are documented without asserting causation.
AC5: CanadianHamLessonFigures ran47 selected methods (45 matrix +2 Ohms-law integration); CanadianHamDefault excludes those exact tests.13 two-lesson ranges split; historical M1 Part2 passed174.813s. AGENTS.md has exact -testPlan command and triggers. Two final XcodeGen regenerations each left zero project diff.
Final checks: python3 /tmp/task-33-source-check.py passed; test-guard self-test passed; TEST_GUARD_PR_BODY=Test-guard-approved:task-33 (with the required space after the colon in the actual command) passed diff check and flagged only4 mapped wrapper deletions; git diff --check passed. Required eventual PR marker: Test-guard-approved: task-33. Other platform suites skipped because no app/package/unit/non-iOS test source changed. No new test runs during finalization; no PR opened.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented assertion-preserving, single-appearance launch sharing (14 fewer launches), separate XcodeGen default/figure plans, 13 single-lesson range splits, exact AGENTS invocation, coverage inventory, and complete per-test/timing evidence. Final UI membership124 default +47 figure; unit190. Required full runs completed, with supervisor-approved acceptance: full suite passed except unchanged tests that passed targeted reruns (sending heading wait, Ohms-law dark, M7 dark). All three passed unchanged isolated reruns; failures and high host load/FluxTerm lock sharing remain documented in TASK-65. Historical timing baseline is explicitly older and not a controlled speedup comparison. Source/coverage identity, guard self-test/approved-marker diff, regeneration determinism and whitespace checks passed. Branch committed/pushed for required internal review; no PR opened. Eventual PR needs Test-guard-approved: task-33 and the qualified full-run/rerun evidence.
<!-- SECTION:FINAL_SUMMARY:END -->
