---
id: TASK-9
title: Web follow-ups
status: To Do
assignee: []
created_date: '2026-10-01 02:27'
labels:
  - web
  - accessibility
milestone: m-0
dependencies: []
ordinal: 16000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Non-blocking review notes from the web accessibility and stale-load race lanes.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 docs/accessibility.md no longer says answer choices use radio groups (it matches the toggle-button decision)
- [ ] #2 The skip link is the first Tab stop in development (StrictMode) as well as production
- [ ] #3 The error-screen skip link moves focus without leaving #main in the URL
- [ ] #4 A superseded failed preference save doesn't show 'Theme saved'
- [ ] #5 The lesson quiz axe test runs comfortably under the default timeout (scan only the quiz section, cheaper queries)
<!-- AC:END -->
