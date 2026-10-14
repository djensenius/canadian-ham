---
id: TASK-49
title: 'CI guard: flag changes to audit handlers and shared UI-test helpers'
status: Done
assignee:
  - '@worker'
created_date: '2026-10-14 15:28'
updated_date: '2026-10-14 15:45'
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
1. Add scripts/check-test-guard.mjs to parse PR git diffs, report guarded Apple-source changes with file:line/rule, and honor Test-guard-approved approval markers.
2. Include --self-test inline fixtures covering one passing and one failing diff per rule plus the approval-marker path.
3. Wire a pull_request CI job to run the self-test and guard with the PR body and fetch-depth 0.
4. Document the guard and approval-marker expectations in AGENTS.md, then run local validation.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented scripts/check-test-guard.mjs with inline self-tests for each guarded rule and approval-marker bypass. Wired a pull_request CI job with fetch-depth 0 and documented the guard/approval expectations in AGENTS.md. Validation passed: node scripts/check-test-guard.mjs --self-test; node scripts/check-test-guard.mjs --base main --head HEAD; git diff --check.

Addressing PR #240 review changes: merge-base old-side reads, broader audit/exception-helper detection, stricter approval markers, separate workflow, expanded helper list, robustness fixes, and expanded self-tests.

Review fixes landed for PR #240: the guard now computes merge-base for both diff and old-side reads, uses -w/-M, collapses added/deleted counts to avoid move/rename/comment false positives, guards audit call additions/deletions/narrowing/named handlers and exception-helper calls, accepts only task/owner-decision approval markers outside fences/comments, prints approved findings as warnings, and runs in a separate Test guard workflow on opened/edited/synchronize/reopened. Validation passed: node scripts/check-test-guard.mjs --self-test; node scripts/check-test-guard.mjs --base main --head HEAD; git diff --check main...HEAD.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added the CI test guard and addressed PR #240 review feedback with merge-base diffing, expanded guarded patterns/helpers, stricter approval markers, a separate Test guard workflow, and broader self-tests. Verified with the guard self-test, local main...HEAD guard run, and diff whitespace check; no Apple suites run because this is CI/docs/script-only work.
<!-- SECTION:FINAL_SUMMARY:END -->
