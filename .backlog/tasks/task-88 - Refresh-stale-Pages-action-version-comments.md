---
id: TASK-88
title: Refresh stale Pages action version comments
status: Done
assignee:
  - '@coordinator'
created_date: '2026-11-03T02:45:00Z'
updated_date: '2026-11-03T02:45:00Z'
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
- [x] #1 The deploy-web.yml comment above actions/upload-pages-artifact reads v5.0.0, matching pinned SHA fc324d35
- [x] #2 The deploy-web.yml comment above actions/deploy-pages reads v5.0.1, matching pinned SHA 368f8252
- [x] #3 Every other pinned action comment in .github/workflows still matches the tag of its pinned SHA
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Update the two stale comments in deploy-web.yml.
2. Verify all pinned SHAs against upstream tags with git ls-remote.
3. Commit, review, PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Verified with git ls-remote --tags: checkout 3d3c42e5=v7.0.1, pnpm/action-setup ea17c68d=v6.1.0, setup-node 82076278=v7.0.0, configure-pages 983d7736=v5.0.0, upload-pages-artifact fc324d35=v5.0.0, deploy-pages 368f8252=v5.0.1. Only the two Pages comments were stale (left by Dependabot #147/#148). Comment-only workflow change; deploy-web.yml is manual and permission-gated, so CI does not run it.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Updated the deploy-web.yml version comments for actions/upload-pages-artifact (v5.0.0) and actions/deploy-pages (v5.0.1) to match the SHAs pinned by Dependabot #147/#148. Checked every other pinned action comment against upstream tags; all match.
<!-- SECTION:FINAL_SUMMARY:END -->
