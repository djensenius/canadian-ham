---
id: TASK-80
title: Morse sending exam and its UI test use the official ISED Morse test standard
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-28T01:32:00Z'
updated_date: '2026-10-28T01:33:00Z'
labels:
  - morse
  - accuracy
dependencies: []
priority: medium
ordinal: 164000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner 2026-10-27, on TASK-65: 'use the official standard for the test'. The Morse sending UI test (testAccessibilityAuditMorseSendingResultsLight/Dark) runs with a debug exam length (debugExamDurationSeconds, 120 s) that auto-grades mid-preparation under load. Find the official ISED Morse qualification test standard (speed, duration and sending test format) from primary sources (RIC-1/CIR-1, RIC-3/CIR-3, RBR-4, the Basic bank), make sure the app's sending exam matches it, and make the UI test fixture use that official timing instead of an arbitrary 120 s.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The official ISED Morse test standard (speed, sending duration and format) is cited from primary sources with section numbers and recorded in docs/exam-facts.md (EN/FR where available)
- [ ] #2 The app's Morse sending exam (iOS/iPadOS/macOS, web if it has one) matches the official standard, or any deliberate practice-mode difference is labelled. Morse engine/profile tests cover it
- [ ] #3 The sending UI tests use the official exam duration (no arbitrary debug length); the light and dark sending audit tests pass 3/3 each with every assertion and the full audit unchanged
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Fetch current ISED EN/FR primary sources and document sectioned Morse timing, format and grading facts.
2. Compare shared TS/Swift engines and Apple/web sending configuration; implement only verified standard corrections and parity tests.
3. Remove arbitrary UI-test duration override while preserving assertions/audits; fix local Grade navigation only if needed.
4. Run bounded package/parity, three sending tests (three iterations), macOS unit, text-source and guard checks; record evidence, commit/push milestones, and finalize.
<!-- SECTION:PLAN:END -->
