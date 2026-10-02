---
id: TASK-11.5
title: Course switcher and Advanced practice and mock exams
status: To Do
assignee: []
created_date: '2026-10-02 01:12'
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
