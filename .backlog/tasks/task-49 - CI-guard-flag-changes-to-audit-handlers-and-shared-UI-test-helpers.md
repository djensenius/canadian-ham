---
id: TASK-49
title: 'CI guard: flag changes to audit handlers and shared UI-test helpers'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-14 15:28'
updated_date: '2026-10-14 15:28'
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
- [ ] #1 A CI job (in .github/workflows/ci.yml) runs scripts/check-test-guard.mjs on the PR diff and fails on the listed patterns without an approval marker like 'Test-guard-approved: <task or decision>' in the PR body
- [ ] #2 Self-tests cover each pattern and the approval path; documented in AGENTS.md
<!-- AC:END -->
