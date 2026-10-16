---
id: TASK-53
title: Revise L-001-01 authority model to show parallel Act powers
status: Done
assignee:
  - '@worker'
created_date: '2026-10-16 12:06'
updated_date: '2026-10-16 12:46'
labels:
  - content
dependencies: []
modified_files:
  - >-
    content/lessons/m1-regulations-policies/l-001-01-authority-certificates-and-exams.md
priority: medium
ordinal: 130000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
L-001-01 currently teaches the Act, Regulations, and ISED standards as a linear stack. The task-50 hint review and owner ruling use the parallel model: the Act empowers both the Regulations and the department's technical operating standards. Revise the prose at content/lessons/m1-regulations-policies/l-001-01-authority-certificates-and-exams.md:111 and the illustration brief at :162 so learners do not learn the rejected Act → Regulations → standards stack.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Line 111's 'How these rules fit together' prose teaches that the Act empowers both the Regulations and the department's standards, while ISED administers the Act.
- [x] #2 The illustration brief no longer asks for stacked Act → Regulations → ISED standards cards and instead describes a parallel authority model.
- [x] #3 Lesson checks and originality checks pass for the revised lesson.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the current lesson section, figure directive, SVG, and hint anchors for L-001-01.
2. Compare old vs revised taught facts to preserve coverage while replacing the rejected stacked authority model with the approved parallel model.
3. Update the lesson prose, illustration brief, and any referenced figure/text equivalent if present.
4. Regenerate/check figures, render/read the figure preview if changed, then run lesson, originality, link, hint, figure, and test commands.
5. Record evidence, finalize TASK-53, and open the PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented lesson prose and illustration-brief revision. Taught-facts comparison: old paragraph taught Act authority, Regulations service definition, ISED administration, and station-operation standards; revised paragraph retains those facts while replacing the rejected stack/top-layer framing with a parallel model where the Act grants powers, Regulations set binding rules including the amateur-service definition, ISED issues technical standards such as RBR-4, and ISED administers the Act. No ::figure directive is present in L-001-01, so there was no referenced SVG or PNG to update/render.

Validation passed: content assertion script confirmed both linked headings remain, the How these rules fit together prose teaches the parallel model with Act powers, Regulations binding rules, ISED technical standards/RBR-4, and ISED administration, and the illustration brief uses a parallel diagram without stacked-card wording. Commands passed: pnpm check:figures:fix; node packages/content-tools/src/check-lesson-coverage.ts; pnpm --dir packages/content-tools check:lesson-originality:all; pnpm check:links; pnpm check:hints; pnpm check:figures; pnpm test. Figure render note: L-001-01 has no ::figure directive and no referenced SVG, so no qlmanage PNG was applicable.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Revised L-001-01 to teach the owner-approved parallel authority model and updated the illustration brief away from stacked cards. Verified with content assertions, lesson coverage, originality, links, hints, figure sync/checks, and full pnpm test.
<!-- SECTION:FINAL_SUMMARY:END -->
