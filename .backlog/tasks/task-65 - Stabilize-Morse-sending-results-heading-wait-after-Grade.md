---
id: TASK-65
title: Stabilize Morse sending-results heading wait after Grade
status: To Do
assignee: []
created_date: '2026-10-20 06:58'
labels:
  - apple
  - testing
dependencies: []
references:
  - docs/testing/task-33-ios-results.md
priority: low
type: bug
ordinal: 140000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-33 default iOS run on iPhone 17 Pro hit an intermittent pre-audit failure in unchanged testAccessibilityAuditMorseSendingResultsLight: after Grade, morse-sending-results-heading did not exist within the existing 5-second wait (CanadianHamPracticeUITests.swift:1708 at task-33 commit 46f651f3). The dark case passed in 67.311s and the historical train-2026-10-17 light case passed in 72.445s. Full-run evidence: /tmp/task-33-after.log and /tmp/task-33-after.xcresult; preserved per-test evidence will be in docs/testing/task-33-ios-results.md. Supervisor approved tracking this separately rather than weakening tests or changing audit helpers in TASK-33. Investigate whether the Grade interaction or results transition causes the missed heading; do not assume a longer timeout is sufficient.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The cause of the intermittent post-Grade missing results heading is identified with evidence from the failed run or a targeted reproduction.
- [ ] #2 The light/dark sending-results tests reliably reach the real results screen and retain all existing assertions and accessibility audits without skips or relaxed audit handlers.
- [ ] #3 Relevant targeted iPhone 17 Pro test results and any remaining flakiness are recorded; no full-suite rerun is required solely for this fix.
<!-- AC:END -->
