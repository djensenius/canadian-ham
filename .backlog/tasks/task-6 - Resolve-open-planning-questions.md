---
id: TASK-6
title: Resolve open planning questions
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-02 01:34'
labels:
  - docs
  - needs-decision
milestone: m-0
dependencies: []
ordinal: 13000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Open questions carried over from tasks/PLAN.md. Already resolved: minimum Apple OS (iOS/iPadOS 27.0, macOS 27.0, tvOS 27.0, visionOS 27.0, per task-23) and the French reference material (PDFs dropped). ISED permission is tracked in its own task.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The official French category names are verified, or the gap is documented (see docs/requirements.md)
- [ ] #2 The official Basic exam time limit is verified and recorded in docs/exam-facts.md, or marked unknown with a source
- [ ] #3 The minimum supported browser versions are decided and recorded in docs/requirements.md
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Update importer source data for the eight official French Basic category names and regenerate content/generated/basic-2025-07-15 rather than editing generated JSON by hand.
2. Update requirements/exam-facts documentation with cited ISED category names, no-time-limit guidance, information-circular status, and Vite 8.3.x browser target details after confirming the web build target.
3. Check French category display strings in web and Apple UI catalogues and replace any unofficial names with the official ISED names.
4. Run the requested pnpm checks and Apple xbuild suites if Apple strings or Swift change, then finalize task-6 with evidence.
<!-- SECTION:PLAN:END -->
