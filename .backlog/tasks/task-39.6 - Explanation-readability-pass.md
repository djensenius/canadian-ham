---
id: TASK-39.6
title: Explanation readability pass
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 22:15'
updated_date: '2026-10-11 00:16'
labels:
  - content
dependencies:
  - TASK-39.1
parent_task_id: TASK-39
priority: low
ordinal: 89000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Review the 984 per-question explanations in content/explanations for readability against docs/teaching-guide.md: plain language, defined terms, a short real-world tie-in where it helps. Prioritise technical categories (B-004 to B-008). Keep the explanation checker passing and never restate ISED question text beyond what the rules allow.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Every explanation in B-004 to B-008 is reviewed and revised where needed; B-001 to B-003 are reviewed for clarity
- [ ] #2 Explanation checker, originality and allowlist checks pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Review B-005 explanations against the generated question bank and teaching guide, updating only body.en for accuracy and readability.\n2. Run the B-005 explanation checker, inspect the diff for body.en-only changes, then commit that category.\n3. Review B-004 with the same body.en-only accuracy/readability pass and run its category checker.\n4. Run the full explanation checker plus link and test checks, add lane notes, and leave ACs/status for the coordinator.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
B-004/B-005 lane: reviewed all 205 explanations in scope against content/generated/basic-2025-07-15/questions.json. Updated only body.en prose in 56 B-005 files and 29 B-004 files for shorter sentences, clearer distractor reasons, SI spacing/unit style, and selective technical definitions/tie-ins. Accuracy fixes: none found; correct answers and existing quoted choice text were preserved. Checks: node packages/content-tools/src/check-explanations.ts --category B-005 (pass), --category B-004 (pass), pnpm --dir packages/content-tools check:explanations (pass), pnpm check:links (pass), TZ=UTC pnpm test initially hit two web timeout-related failures and passed on the requested rerun.
<!-- SECTION:NOTES:END -->
