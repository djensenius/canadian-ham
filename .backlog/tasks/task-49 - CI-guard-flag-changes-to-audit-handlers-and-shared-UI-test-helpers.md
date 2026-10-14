---
id: TASK-49
title: 'CI guard: flag changes to audit handlers and shared UI-test helpers'
status: Done
assignee:
  - '@worker'
created_date: '2026-10-14 15:28'
updated_date: '2026-10-14 15:56'
labels:
  - ci
  - apple
dependencies: []
priority: high
ordinal: 113000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Workers repeatedly weakened UI tests when stuck (audit filters, rewritten shared helpers, hidden content). Add a CI check that fails a PR touching accessibility-audit handlers (performAccessibilityAudit closures), the approved-exception helpers, or shared UI-test positioning helpers unless the PR body contains an explicit approval marker referencing an owner decision or task. Also flag new accessibilityHidden(true), .accessibilityElement(children: .ignore), and XCTSkip additions in Apple sources/tests.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A CI job (the separate Test guard pull-request workflow) runs scripts/check-test-guard.mjs on the PR diff and fails on the listed patterns without an approval marker like 'Test-guard-approved: task-49' or 'Test-guard-approved: owner decision YYYY-MM-DD' in the PR body
- [x] #2 Self-tests cover each pattern, robustness/review cases, and the approval path; documented in AGENTS.md
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Replace range event count-cancellation with old/new per-file guarded-range comparisons using comment-stripped, whitespace-normalized text with strings preserved.
2. Replace changed-line pattern matching with per-file stripped-content comparisons for added line-pattern counts plus disappeared test/audit-wrapper names.
3. Update workflow to execute the base-branch checker when present and make checker/workflow edits marker-gated.
4. Add the requested self-tests and docs wording, then rerun self-test and main...HEAD guard.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented scripts/check-test-guard.mjs with inline self-tests for each guarded rule and approval-marker bypass. Wired a pull_request CI job with fetch-depth 0 and documented the guard/approval expectations in AGENTS.md. Validation passed: node scripts/check-test-guard.mjs --self-test; node scripts/check-test-guard.mjs --base main --head HEAD; git diff --check.

Addressing PR #240 review changes: merge-base old-side reads, broader audit/exception-helper detection, stricter approval markers, separate workflow, expanded helper list, robustness fixes, and expanded self-tests.

Review fixes landed for PR #240: the guard now computes merge-base for both diff and old-side reads, uses -w/-M, collapses added/deleted counts to avoid move/rename/comment false positives, guards audit call additions/deletions/narrowing/named handlers and exception-helper calls, accepts only task/owner-decision approval markers outside fences/comments, prints approved findings as warnings, and runs in a separate Test guard workflow on opened/edited/synchronize/reopened. Validation passed: node scripts/check-test-guard.mjs --self-test; node scripts/check-test-guard.mjs --base main --head HEAD; git diff --check main...HEAD.

Final PR #240 review round: replacing range count-cancellation with old/new normalized range comparisons, per-file full-content line-pattern comparisons, base-copy workflow execution, guard self-protection, and requested robustness/self-tests.

Final review fixes landed: range guarding now compares old/new normalized range bodies with comments stripped and strings preserved; line-pattern checks compare per-file stripped effective contents and disappeared test/audit-wrapper names; workflow runs the base checker when available; checker/workflow edits require an approval marker; CODEOWNERS added for guard files; AGENTS.md clarifies edited-event reruns and heuristic-review responsibility. Validation passed: node --check scripts/check-test-guard.mjs; node scripts/check-test-guard.mjs --self-test; TEST_GUARD_PR_BODY='Test-guard-approved: task-49' node scripts/check-test-guard.mjs --base main --head HEAD; git diff --check main...HEAD.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented the CI test guard and final review hardening: base-copy workflow execution, self-protection for guard files, range-body comparisons, per-file line-pattern checks, requested bypass self-tests, and documentation updates. Verified with syntax check, expanded self-tests, approved local main...HEAD guard run, and diff whitespace check; no Apple suites run because this is CI/docs/script-only work.
<!-- SECTION:FINAL_SUMMARY:END -->
