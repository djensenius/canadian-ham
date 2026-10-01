---
id: TASK-9
title: Web follow-ups
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-01 16:56'
labels:
  - web
  - accessibility
milestone: m-0
dependencies: []
ordinal: 16000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Reviews of the web accessibility and stale-load race lanes approved the work but left smaller defects: docs that contradict the answer-choice decision, a skip link skipped in development because of StrictMode, an error-screen skip link that pollutes the URL, a misleading 'Theme saved' after a superseded failed save, and a slow axe test close to the timeout that could become flaky again.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 docs/accessibility.md no longer says answer choices use radio groups (it matches the toggle-button decision)
- [ ] #2 The skip link is the first Tab stop in development (StrictMode) as well as production
- [ ] #3 The error-screen skip link moves focus without leaving #main in the URL
- [ ] #4 A superseded failed preference save doesn't show 'Theme saved'
- [ ] #5 The lesson quiz axe test runs comfortably under the default timeout (scan only the quiz section, cheaper queries)
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Align docs/accessibility.md keyboard/screen-reader guidance with the existing toggle-button answer-choice decision.\n2. Update App focus handling so initial route focus is skipped under React StrictMode, and wire the error-boundary skip link through the same preventDefault/focus behavior.\n3. Adjust preference-save status handling so only the latest successful save announces a theme-saved status; add a regression for a superseded failed save.\n4. Tighten the lesson quiz axe regression to scan the lesson quiz section only with cheaper DOM queries.\n5. Add focused tests for StrictMode skip-link tab order, error-boundary skip-link hash preservation/focus, stale preference saves, and the optimized lesson quiz axe path; then run the required checks.
<!-- SECTION:PLAN:END -->
