---
id: TASK-81
title: Refresh release audit coverage and current privacy inventory
status: Done
assignee:
  - '@copilot-worker'
created_date: '2026-10-29T00:01:00Z'
updated_date: '2026-10-29T00:05:00Z'
labels:
  - release
  - docs
dependencies: []
references:
  - docs/release/release-checklist.md
  - docs/release/privacy-label-evidence.md
type: docs
ordinal: 165000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Fleet reconnaissance found that the consolidated release checklist does not explicitly schedule the audit plans excluded from the default Apple plan, and the historical privacy snapshot predates current Morse settings UserDefaults persistence. Refresh documentation without treating a rehearsal as release approval or making unsupported required-reason compliance claims. Related existing work: TASK-1.5 and TASK-1.2; preserve their statuses and release gates.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Release checklist explicitly requires the separate figure and title-sweep plans, exclusive quiet-host figure scheduling, and per-test evidence.
- [x] #2 A dated source-revision-identified privacy addendum preserves historical evidence, inventories current preference persistence and manifest declarations, and explicitly records unresolved required-reason review without invented reasons or compliance clearance.
- [x] #3 Links and focused source/configuration cross-checks pass; only the two release documents and CLI-managed task records change; parent statuses, release gates, and owner status.md remain untouched.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Compare release checklist with current Apple default/figure/title test plans and quiet-host runner; preserve all release/device/ISED gates.
2. Inventory current Apple preference persistence, manifest declarations and target membership at source SHA a69c27400b88302c9f8ce393ea98ae01b73cfd25; append dated historical-preserving evidence with required-reason review OPEN.
3. Run pnpm check:links and focused source/configuration comparisons; no Apple suites for docs-only edits. Verify scoped diff and unchanged parent statuses; record evidence, finalize TASK-81 and commit documentation.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented only the two release documents. AC1: checklist now explicitly schedules CanadianHamLessonFigures only through scripts/run-figure-plan-quiet.sh, forbids concurrent Apple lanes during wait/run, requires the full RC figure selections and separate CanadianHamTitleSweeps xbuild command, and requires per-test evidence. AC2: appended 2026-10-28 inventory at audited source SHA a69c27400b88302c9f8ce393ea98ae01b73cfd25, preserving the original privacy document verbatim as a prefix. Inventory covers all six preference-API matching Swift files, Morse load/save/reset lines 161-176 and call sites, ProgressStore defaults (including ungated local iCloud-helper accesses), SwiftData preferences/migration marker, TV/Vision reads and watch memory-only settings. Both source manifests have false tracking and empty domains/collection/accessed-API arrays; generated resource phases and source memberships were parsed for all four app targets and compared with project.yml. Required-reason applicability/reasons/shipped-target review remains OPEN, not violation proven or clearance; no reason codes selected and no code/manifest remediation made.
AC3 checks: pnpm check:links passed twice, final actual output: Markdown relative links verified. Initial pnpm invocation automatically installed 100 existing locked packages from cache (downloaded 0); no dependency/lockfile changes. git diff --check passed (exit 0, no output). Focused Python assertions actual result lines:
PASS: historical privacy snapshot and every existing checklist line/release gate preserved.
PASS: default excludes exactly 3 figure selections + 4 title sweeps; test methods, quiet runner artifacts/exclusivity and AGENTS title command agree.
PASS: bounded recursive preference scan matches all 6 inventoried Swift files; Morse lines 161-176 and ProgressStore keys agree.
PASS: both manifests have the documented empty declarations; all 4 generated app resource/source memberships match inventory.
PASS: changed paths limited to the two release docs and TASK-81 record; audited app/package/script sources unchanged from identified SHA.
plutil -p parsed both manifests successfully; plutil JSON inspection verified CanadianHamWatch resource phase E9EC76AE96F86E7F7A62BF9C and all other table IDs. Parent TASK-1.2 remains In Progress (AC3 unchecked); TASK-1.5 remains Done; parent-record/status.md baseline diff exit 0. Root checkout and owner untracked status.md never edited. Initial multithreaded rg hit transient os error 35; rerun with --threads 1 and independent recursive Python scan completed successfully.
Skipped iOS/iPadOS, macOS, tvOS, visionOS and watchOS suites, including figure/title plans, because changes are docs-only per testing policy. No full web/package tests or release builds/network checks run. Follow-up: release owner must resolve required-reason review, authorize any separate remediation if needed, inspect shipped manifests and collect fresh RC/device/ISED/privacy evidence; this task closes none of those release gates.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Refreshed release audit scheduling and appended a source-SHA-identified current preference/manifest inventory while preserving historical evidence and all release gates. Links, focused plan/source/manifest comparisons and scoped/whitespace checks passed. Required-reason applicability, approved reasons and shipped-target coverage remain OPEN for release-owner review and separate remediation if needed; TASK-1.2/TASK-1.5 statuses unchanged. No Apple suites run for docs-only changes.
<!-- SECTION:FINAL_SUMMARY:END -->
