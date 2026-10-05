---
id: TASK-11.5
title: Course switcher and Advanced practice and mock exams
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-05 00:01'
labels:
  - web
  - apple
  - accessibility
milestone: m-1
dependencies:
  - TASK-11.4
parent_task_id: TASK-11
priority: medium
ordinal: 37000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the owner chose one app with a course switcher (2026-10-02). Learners need to pick Basic or Advanced and practise or sit 50-question mocks, without the Basic reference sheet being presented as allowed for Advanced. See docs/proposals/advanced-course.md (owner decisions in task-11 notes).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Web and Apple apps have an accessible course switcher, with the choice stored locally and no network use
- [ ] #2 Advanced practice by topic and 50-question mock exams work offline on web and Apple; Advanced shows no lessons until they exist
- [ ] #3 No Basic reference material is shown as exam-allowed for Advanced
- [ ] #4 Accessibility audits, French UI checks, web tests and the four-platform xbuild suites pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect existing multi-bank plumbing in engine-ts, engine-swift, generated Basic/Advanced data, web preferences/progress/exam flows, and Apple target membership in apps/apple/project.yml.\n2. Add a persisted Basic/Advanced course selection in web and Apple iPhone/iPad/Mac UI, defaulting to Basic, with accessible labels and French strings.\n3. Route web and Apple practice/mock/progress/readiness/export flows through the selected bank; hide lessons for Advanced and prevent Basic reference material from appearing as Advanced exam-allowed material.\n4. Bundle content/generated/advanced-2025-02-04 for web and the CanadianHam Apple target only, keep tvOS/visionOS Basic-only, regenerate XcodeGen twice, and update tests for switcher, Advanced 50-question mocks, scoring, persistence, accessibility and French behavior.\n5. Run targeted checks while iterating, then required web and affected Apple full suites; record per-test names and task evidence before finalizing.
<!-- SECTION:PLAN:END -->
