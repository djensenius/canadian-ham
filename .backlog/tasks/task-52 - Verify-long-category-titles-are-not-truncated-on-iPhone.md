---
id: TASK-52
title: Verify long category titles are not truncated on iPhone
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-16 08:06'
updated_date: '2026-10-20 13:10'
labels:
  - apple
dependencies: []
priority: low
ordinal: 115000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Seen during task-44.3 work: long category titles such as 'Regulations and Policies' appeared truncated ('Regulations and Polici…') in some iPhone layouts. Check every category list, card and header on iPhone at default and large Dynamic Type sizes, and fix any truncation without minimumScaleFactor or layout changes made just to pass tests.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Every category title on iPhone wraps or fits at default and accessibility text sizes, with screenshots or a test as evidence
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect category title rendering in practice, study, mock and weak areas, including TASK-55 inline titles and existing UI-test patterns.
2. Add EN/FR default and maximum-accessibility iPhone UI coverage and screenshot evidence; apply only wrapping fixes if truncation remains.
3. Run only added/touched UI tests through nohup xbuild on iPhone 17 Pro, and macOS unit tests if app code changes; record evidence and finalize, commit and push.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Baseline targeted UI test confirms TASK-55 removed the original default-size English Regulations and Policies truncation; the longer Basic Station Assembly, Practice and Safety navigation title and wrapped content header also fit on iPhone 17 Pro. Continuing largest-accessibility French coverage and all shared category surfaces (including Advanced). Test header identifiers resolve to the existing combined accessibility header; tests preserve that hierarchy and all shared helpers.
<!-- SECTION:NOTES:END -->
