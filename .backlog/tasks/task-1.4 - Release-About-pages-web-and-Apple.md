---
id: TASK-1.4
title: Release About pages (web and Apple)
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-02 05:57'
labels:
  - release
  - web
  - apple
  - 'legacy:T-606'
milestone: m-0
dependencies:
  - TASK-1.2
parent_task_id: TASK-1
ordinal: 5000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Complete the About pages on web and Apple with attribution, disclaimer, the source manifest, the privacy summary and the active bank version, using the attribution wording from docs/content-licensing.md once permission is recorded. Legal text is currently English-only in the French UI; get it reviewed and translated. Legacy: T-606.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The web app has an About page with attribution, disclaimer, sources, privacy summary and the bank version
- [ ] #2 The Apple About screens match the same content on iOS/macOS, tvOS and visionOS
- [ ] #3 The attribution wording matches the recorded ISED permission
- [ ] #4 The legal text has been reviewed, and French translations are added or the English-only decision is documented
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Extend the existing web Settings/navigation surface with a reachable About route using current docs/content-licensing attribution/disclaimer drafts, manifest/source data, privacy copy, lang attributes for English legal text in French UI, and unit/a11y coverage.
2. Update the existing Apple About screens (shared iOS/macOS plus tvOS and visionOS) through Localizable.xcstrings-backed strings, preserving the no-network rule and showing source URLs as text except the existing RBR-4 citation behavior elsewhere.
3. Record the required TODO/status in docs/content-licensing.md and Backlog notes: attribution must be replaced after task-1.1 records ISED permission; legal French remains English-only with lang/accessibility tagging per docs/french-style.md pending human legal review.
4. Add or update web and Apple UI tests for About attribution, disclaimer, active bank version/effective date, and platform accessibility audits, then run requested pnpm checks plus DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild suites where possible.
<!-- SECTION:PLAN:END -->
