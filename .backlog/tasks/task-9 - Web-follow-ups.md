---
id: TASK-9
title: Web follow-ups
status: To Do
assignee: []
created_date: '2026-10-01 02:27'
updated_date: '2026-10-01 02:34'
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
