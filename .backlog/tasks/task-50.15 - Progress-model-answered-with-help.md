---
id: TASK-50.15
title: 'Progress model: answered with help'
status: Done
assignee:
  - '@worker'
created_date: '2026-10-16 08:12'
updated_date: '2026-10-17 01:37'
labels:
  - engine
dependencies: []
parent_task_id: TASK-50
priority: high
type: task
ordinal: 129000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Question hints need a durable progress state before UI work records hinted answers. The model must represent answered-with-help consistently across TypeScript and Swift engines, parity fixtures, progress/export schemas, sync device rows, and import compatibility so web and Apple UI tasks do not each invent separate semantics.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 engine-ts and engine-swift store answered with help as a flag alongside correct/incorrect outcomes, preserving accuracy stats while withholding mastery credit and weak-area clearing
- [x] #2 Shared parity fixtures cover hinted-answer scheduling and sooner spaced-review return behaviour
- [x] #3 common progress schema, progress export schema, sync device rows, and import compatibility accept and preserve the answered-with-help state
- [x] #4 Migration/backward-compatibility tests cover older progress exports or device rows that do not contain the new state
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Trace the TypeScript and Swift progress attempt models, scheduling, mastery, weak-area, export/import, and parity fixture flow.
2. Add an optional answered-with-help flag defaulting to false in schemas, fixtures, TS/Swift models, import/export, and any sync device rows while preserving older data.
3. Apply owner semantics consistently: hinted answers keep correct/incorrect accuracy, never grant mastery credit or clear weak areas, and use the incorrect/shortest review interval for spaced scheduling.
4. Add/update parity, migration/back-compat, TS and Swift tests for hinted correct, hinted incorrect, repeated hinted-to-unaided sequences, and older records without the field.
5. Document the semantics and run the requested package, schema, import, parity, Swift, and affected Apple checks before finalizing.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented answered-with-help as an additional flag alongside correct/incorrect outcomes. Scheduling rule chosen and documented: any answered-with-help attempt is proficiency-no-credit and uses the same immediate review scheduling as an incorrect answer (box 0, dueAt = now), while correctAttempts/recentResults still preserve actual accuracy. Added parallel recentAnsweredWithHelp so weak-area logic can treat helped correct answers as not proficiency-correct.

Opened PR #277 with Apple xbuild engine parity and macOS unit checks marked pending because /tmp/task-50.15-apple-checks.sh is still queued behind the shared xbuild lock. Non-Apple checks completed: pnpm typecheck, pnpm test, pnpm check:schemas, pnpm import:check, swift test in packages/engine-swift, and TS engine fixture tests.

Coordinator: r277 review fixes plus delta-review fixes landed (head 3c537d94). Scheduling rules chosen under owner delegation 2026-10-16: hinted correct keeps its box and is due now; hinted incorrect behaves as incorrect; weak areas exclude hinted-correct answers from both counts. Checks: pnpm typecheck/test/check:schemas/import:check/check:apple-l10n/text-sources passed; swift test 21; engine-ts 23; engine parity xbuild 21; iOS ProgressStoreTests 85/0; macOS unit 133/0. Waits for an Apple merge batch.

Copilot rollover finding: changed the weak-area rule so a hinted-correct answer counts as an attempt without proficiency credit (the exclusion rule let a helped answer evict an older failure and clear weakness). Both engines, docs and the fixture (weak-subsections-hinted-correct-rollover-counts-attempt-without-credit) are updated. engine-ts 23, swift test 21, parity xbuild passed, web tests and typecheck passed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Adds the answered-with-help flag alongside correct/incorrect in engine-ts and engine-swift, with matching scheduling (hinted correct keeps its box and is due now; hinted incorrect is treated as incorrect) and weak-area counting (hinted correct excluded from both counts). Parity fixtures, optional schema fields in progress export v1, sync device rows, IndexedDB and SwiftData v4 migration with back-compat tests, and docs.
<!-- SECTION:FINAL_SUMMARY:END -->
