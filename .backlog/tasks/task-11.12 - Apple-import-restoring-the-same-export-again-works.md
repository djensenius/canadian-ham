---
id: TASK-11.12
title: 'Apple import: restoring the same export again works'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-05 13:33'
updated_date: '2026-10-05 21:57'
labels: []
dependencies:
  - TASK-11.5
parent_task_id: TASK-11
priority: medium
ordinal: 65000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: ProgressModels marks questionId and attempt id as @Attribute(.unique). Since task-11.5, Apple import deletes the imported bank's records and reinserts them in one save. Re-importing the same export (the usual 'restore backup' case) has no test and could hit a uniqueness conflict. Found in the task-11.5 review (~/.cache/canadian-ham-reviews/t115-r2.md).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A unit test exports progress, then imports that same file twice; progress, exam attempts and lesson data are identical afterwards
- [x] #2 Any uniqueness conflict found is fixed; the macOS and iOS suites pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add Apple import regression coverage for exporting then importing the same file twice, and compare progress, attempts, lessons, Morse and preferences snapshots after each restore.
2. Fix any SwiftData uniqueness conflicts found by the regression and add import validation for Advanced attempts with honours=true on Apple and web.
3. Add focused Apple and web tests for rejecting honours=true when the target bank has no Honours result.
4. Run targeted import tests, then required web and Apple validation before checking acceptance criteria.

5. Address review round 1: add per-test full-run names/counts to task notes and re-run required checks after code changes.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Started implementation. Added scope from PR #141 Copilot final summary: Advanced imports must reject attempts marked honours=true on Apple and web because Advanced has no Honours result.

Implemented Apple same-export-twice regression and Advanced honours import rejection on Apple/web. Web pnpm test, typecheck, build, dist URL/CSP audit, and Apple text-source check passed; iOS targeted ProgressStoreTests are queued behind the xbuild lock in /tmp/t1112-ios-progressstore.log.

Validation passed:
- pnpm --filter @canadian-ham/web test -- src/lib/progressStore.test.ts src/App.test.tsx -t "rejects Advanced import attempts marked with Honours|confirms before a course switch discards an unfinished mock exam" (Vitest: 13 files, 129 tests passed).
- pnpm test (release/content/morse/web: 100 node tests, 17 Morse tests, 129 web tests passed).
- pnpm typecheck; pnpm build:web; pnpm --filter @canadian-ham/web exec node scripts/audit-dist-urls.ts.
- node scripts/check-apple-text-sources.ts.
- Targeted iOS xbuild ProgressStoreTests: 21 tests passed, including testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons and testAdvancedImportRejectsHonoursAttempts.
- Apple final suite via /tmp/t1112-apple-final-2.log: pnpm check:apple-l10n passed (Apple French localization export complete); iOS full suite 60 tests passed; macOS full suite 53 tests passed; tvOS full suite 12 tests passed; visionOS full suite 9 tests passed.

Review round 1 requested changes: per-test final full-run evidence names/counts were missing; reopening task for fix evidence updates.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented same-export-twice Apple import regression coverage, committed deletion saves to avoid SwiftData unique-ID conflicts on restore, and rejected honours=true imports for Advanced on Apple/web. Verified with web checks, targeted ProgressStoreTests, Apple l10n/text-source checks, and full iOS/macOS/tvOS/visionOS xbuild suites.
<!-- SECTION:FINAL_SUMMARY:END -->
