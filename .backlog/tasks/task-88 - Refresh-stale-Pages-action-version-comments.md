---
id: TASK-88
title: Refresh stale Pages action version comments
status: To Do
assignee: []
created_date: '2026-11-03T02:45:00Z'
labels:
  - chore
  - github
dependencies: []
priority: low
ordinal: 171000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Dependabot PRs #147 (deploy-pages 5.0.1) and #148 (upload-pages-artifact 5.0.0) updated the pinned SHAs in .github/workflows/deploy-web.yml but left the human-readable version comments above them at v4.0.5 and v4.0.0. Update the comments so they match the pinned tags.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The deploy-web.yml comment above actions/upload-pages-artifact reads v5.0.0, matching pinned SHA fc324d35
- [ ] #2 The deploy-web.yml comment above actions/deploy-pages reads v5.0.1, matching pinned SHA 368f8252
- [ ] #3 Every other pinned action comment in .github/workflows still matches the tag of its pinned SHA
<!-- AC:END -->
