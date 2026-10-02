---
id: TASK-1.5
title: Consolidated release checklist
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-02 11:52'
labels:
  - release
  - docs
  - 'legacy:T-006'
milestone: m-0
dependencies: []
modified_files:
  - docs/release/release-checklist.md
  - docs/content-licensing.md
  - docs/accessibility.md
  - docs/privacy.md
  - docs/apple-offline-smoke-test.md
  - docs/release/privacy-label-evidence.md
  - docs/content-update-process.md
parent_task_id: TASK-1
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Consolidate the release procedures currently spread across docs/content-licensing.md (release checklist, public-release gate), docs/accessibility.md (manual release checklist), docs/privacy.md (verification checklist) and docs/apple-offline-smoke-test.md into one release checklist. Legacy: T-006.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 One release checklist links or includes every licensing, privacy, accessibility, offline and source-verification check
- [x] #2 Each existing doc checklist points to the consolidated checklist
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inventory the referenced release, privacy, accessibility, offline, source-verification, and related task-gate checks.
2. Add docs/release/release-checklist.md as a release-day checklist organized by gates, content, privacy, accessibility, offline Apple, offline web, store submission, and public repo.
3. Add short pointers near existing checklist sections without deleting existing content.
4. Run pnpm check:links, adjust task-1.3 references if needed, then finalize Backlog with evidence.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented docs/release/release-checklist.md as a release-day procedure with gates, content, privacy, accessibility, offline Apple, offline web, store submission, and public repo sections. It consolidates the content-licensing release checklist and public-release gate, privacy verification checklist, accessibility manual release checklist, Apple offline smoke test, privacy-label evidence, source/content verification commands (checksum, pnpm import:check, pnpm check:schemas, explanation/quiz/coverage/originality checks, diff:banks), task-1.3 future web deploy/offline smoke paths, task-1.1/task-1.4/task-29 gates, and Backlog tasks task-1.1 through task-1.7. Added short pointers from docs/content-licensing.md, docs/accessibility.md, docs/privacy.md, docs/apple-offline-smoke-test.md, docs/release/privacy-label-evidence.md, and docs/content-update-process.md to the consolidated checklist. Removed the stale on-hold label after owner approval. Validation: pnpm check:links first failed only on the two future task-1.3 markdown links, so those references were converted to plain code paths and noted in the checklist; final pnpm check:links passed. A Node assertion script verified required sections, documents, commands, task references, and source-doc pointers are present.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Created docs/release/release-checklist.md and connected the existing release/privacy/accessibility/offline/content checklists to it without deleting their source content. The task description no longer says On hold, the stale on-hold label was removed after owner approval, both ACs are checked with evidence from pnpm check:links and a Node coverage assertion, and the task is ready for the release-candidate pass to consume.
<!-- SECTION:FINAL_SUMMARY:END -->
