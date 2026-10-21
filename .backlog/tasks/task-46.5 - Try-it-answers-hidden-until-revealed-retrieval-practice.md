---
id: TASK-46.5
title: Try it answers hidden until revealed (retrieval practice)
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:57'
updated_date: '2026-10-21 22:23'
labels:
  - content
  - web
  - apple
dependencies: []
parent_task_id: TASK-46
priority: medium
ordinal: 103000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Today every Try it shows its answer on the same line, so there is no retrieval practice. Add a lesson-format convention for Try it answers and render them hidden behind an accessible Show answer control on web and Apple (iOS, iPadOS, macOS, visionOS; tvOS reveals on focus/select). Convert all existing Try it items.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Answers are hidden by default and revealed by an accessible control (keyboard, VoiceOver, screen readers; the state is announced)
- [ ] #2 All lessons converted; the content checker validates the format
- [ ] #3 Full default accessibility audits pass in light and dark on every platform that renders lessons
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Document paired numbered Try-it prompts and :::answer blocks; migrate all M2–M8 Try-its verbatim, with owner-approved minimal M4 prompt/answer repairs and anchor verification.
2. Validate the convention in the content checker with regressions; parse hidden answer blocks in web and content-swift.
3. Add EN/FR accessible reveal controls on web and all Apple platforms (tvOS focus/select), with unit, axe, and targeted reader tests.
4. Run content/web/package checks; commit before serialized nohup xbuild targeted iPhone/iPad, macOS, tvOS, visionOS checks. Record per-test evidence and changed figure lessons for coordinator, finalize, commit and push without opening a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
TASK-46.6 re-review follow-up (owner explicitly permits scoped README plus follow-up instead of converting legacy material now): content/lessons/README.md now applies separate feedback headings to new or restructured Try-its. Convert the remaining M3/M4 inline answers as part of this existing task, including l-003-08-access-grounding-lightning-rf-safety.md and l-004-01-amplifiers-and-diodes.md; inspect all eight M3 and three M4 lessons. Preserve prompts and identities while separating answers for the accessible reveal convention. This is already covered by AC #2 (all lessons converted), so no duplicate task was created.
<!-- SECTION:NOTES:END -->
