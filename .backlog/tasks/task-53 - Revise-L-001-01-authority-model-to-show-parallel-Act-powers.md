---
id: TASK-53
title: Revise L-001-01 authority model to show parallel Act powers
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-16 12:06'
updated_date: '2026-10-16 12:43'
labels:
  - content
dependencies: []
priority: medium
ordinal: 130000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
L-001-01 currently teaches the Act, Regulations, and ISED standards as a linear stack. The task-50 hint review and owner ruling use the parallel model: the Act empowers both the Regulations and the department's technical operating standards. Revise the prose at content/lessons/m1-regulations-policies/l-001-01-authority-certificates-and-exams.md:111 and the illustration brief at :162 so learners do not learn the rejected Act → Regulations → standards stack.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Line 111's 'How these rules fit together' prose teaches that the Act empowers both the Regulations and the department's standards, while ISED administers the Act.
- [ ] #2 The illustration brief no longer asks for stacked Act → Regulations → ISED standards cards and instead describes a parallel authority model.
- [ ] #3 Lesson checks and originality checks pass for the revised lesson.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the current lesson section, figure directive, SVG, and hint anchors for L-001-01.\n2. Compare old vs revised taught facts to preserve coverage while replacing the rejected stacked authority model with the approved parallel model.\n3. Update the lesson prose, illustration brief, and any referenced figure/text equivalent if present.\n4. Regenerate/check figures, render/read the figure preview if changed, then run lesson, originality, link, hint, figure, and test commands.\n5. Record evidence, finalize TASK-53, and open the PR.
<!-- SECTION:PLAN:END -->
