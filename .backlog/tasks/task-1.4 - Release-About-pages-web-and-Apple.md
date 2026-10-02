---
id: TASK-1.4
title: Release About pages (web and Apple)
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-02 07:28'
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
- [x] #1 The web app has an About page with attribution, disclaimer, sources, privacy summary and the bank version
- [x] #2 The Apple About screens match the same content on iOS/macOS, tvOS and visionOS
- [ ] #3 The attribution wording matches the recorded ISED permission
- [ ] #4 The legal text has been reviewed, and French translations are added or the English-only decision is documented
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Extend the existing web Settings/navigation surface with a reachable About route using current docs/content-licensing attribution/disclaimer drafts, manifest/source data, privacy copy, lang attributes for English legal text in French UI, and unit/a11y coverage.
2. Update the existing Apple About screens (shared iOS/macOS plus tvOS and visionOS) through Localizable.xcstrings-backed strings, preserving the no-network rule and showing source URLs as text except the existing RBR-4 citation behavior elsewhere.
3. Record the required TODO/status in docs/content-licensing.md and Backlog notes: attribution must be replaced after task-1.1 records ISED permission; legal French remains English-only with lang/accessibility tagging per docs/french-style.md pending human legal review.
4. Add or update web and Apple UI tests for About attribution, disclaimer, active bank version/effective date, and platform accessibility audits, then run requested pnpm checks plus DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild suites where possible.

Fix review round: restore pending-permission wording across web/Apple docs/task notes, make tvOS/iOS/visionOS lower About content visibly reachable and tested, narrow web lang attributes/selectors, document non-clickable source URLs, fix French wording/RBR-4 title handling, then rerun requested pnpm/node/xbuild validation and capture tvOS evidence.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented About content ahead of task-1.1 using the current docs/content-licensing.md draft attribution as a clearly marked draft/TODO. It must be replaced with the exact wording from recorded ISED permission before AC #3 can be checked; no permission reference/date/scope was invented. French choice: legal attribution/disclaimer/TODO text remains English-only in the French UI with web lang="en" and Apple English accessibility labels, per docs/french-style.md/content-licensing.md, pending human legal review, so AC #4 remains unchecked.

Validation evidence for AC #1/#2: web About route passed App.test About coverage and axe in pnpm test; pnpm build:web and web dist URL audit passed with official source URL allowlist. Apple About content passed iOS, macOS, tvOS, and visionOS xbuild suites on the implementation tip; iOS rerun passed 27 UI/unit tests after one transient failure in testCanPracticeInFrenchAndSeeFeedback, and the targeted retry also passed. Apple localization, text-source, and no-network checks passed. AC #3 remains unchecked pending task-1.1 recorded ISED permission. AC #4 remains unchecked pending human legal review of English-only legal text/French localization decision.

Fix round: relabelled the draft ISED attribution as not in effect with request status drafted; sent: pending; granted: pending across web, Apple and Localizable.xcstrings. Restored explicit pending-permission wording without claiming the request was sent or granted. tvOS About cards are focusable with a visible focus ring; targeted tvOS UI test testAboutLowerSectionsReachableWithRemote passed and docs/evidence/tvos-about-lower-sections-focus.png was opened/confirmed to show lower Disclaimer and Privacy sections with Privacy focused. Added iOS and visionOS UI reachability assertions for lower About text, plus an iOS French About test confirming legal text remains English. Updated release/privacy evidence docs to note RBR-4 and question-bank URLs are non-clickable About text. AC #3 and #4 remain unchecked pending task-1.1 and legal review.
<!-- SECTION:NOTES:END -->
