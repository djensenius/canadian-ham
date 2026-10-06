---
id: TASK-12.17
title: Run Morse course accessibility audits on the real layout
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-04 13:22'
updated_date: '2026-10-06 11:58'
labels: []
milestone: m-1
dependencies: []
parent_task_id: TASK-12
ordinal: 64000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The current Morse course accessibility audit path uses the -CanadianHamMorseCourseAuditOnly launch argument to trim the Morse screen to course content. That kept the audit focused while the course shipped, but it means course audits do not exercise the real Morse section layout and surrounding content.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Morse course path, lesson, and summary accessibility audits launch the normal Morse section layout without -CanadianHamMorseCourseAuditOnly
- [ ] #2 The audits still reach the course path, first lesson, and summary deterministically in light and dark without handlers or audit filters
- [ ] #3 Regression tests or UI-test helpers are updated so the real-layout course audit remains stable
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the Morse course, Morse section navigation, and existing UI tests to identify the current route and accessibility audit seams.
2. Restructure Apple Morse navigation into real, short screens: Morse section home links to a Course home; Course home links to unit screens; unit screens link to lessons; lesson completion pushes summary, preserving progress, review, and playback registration.
3. Replace fixed course font sizing with Dynamic Type text styles/design tokens, avoiding hard-coded colors, LazyVStack, accessibilityHidden on visible text, and audit handlers.
4. Remove -CanadianHamMorseCourseAuditOnly and update iOS UI-test helpers/audits to exercise Morse home, Course home, a Unit screen, first lesson, and summary in light and dark, including scroll-and-reaudit coverage for long screens.
5. Run l10n/text checks, targeted iOS UI tests while iterating, then final platform checks per AGENTS.md task-execution and task-finalization policy; record per-test evidence before checking ACs and moving Done.
<!-- SECTION:PLAN:END -->
