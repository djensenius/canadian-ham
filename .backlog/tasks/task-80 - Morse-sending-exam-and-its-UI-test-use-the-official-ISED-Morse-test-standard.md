---
id: TASK-80
title: Morse sending exam and its UI test use the official ISED Morse test standard
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-28T01:32:00Z'
updated_date: '2026-10-28T02:06:00Z'
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

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Research milestone: fetched RIC-1/CIR-1 §8, RIC-3/CIR-3 §5.2, RBR-4/IPR-4 Schedule I and official bilingual Basic bank B-001-004-005 on 2026-10-27 local / 2026-10-28 UTC. Bank TXT SHA unchanged. Recorded EN/FR quotations and CIR-3 French five-error discrepancy in docs/exam-facts.md. Production sending already uses 180 s, ≥75 weighted-character plain-language text and ≤5-error grading. Named the sourced duration in TS/Swift; target sending-results tests now use production duration with new 3:00 assertion, no old assertion/audit removed. Short timer lifecycle overrides remain. Paired engine tests + shared sending generation/exact five-six error fixtures added; no generator/grading behavior changed. Initial targeted TS engine 23/23 and web sending 14/14 pass. Apple/package/parity and bounded 3×3 sending validation pending.

Validation checkpoint: pnpm test passes (content-tools 250; Morse 23; calculator 127; web 283), targeted web sending 14/14, and Morse Swift package 6/6 including new duration/profile/generation tests and all shared fixtures. Initial typecheck failed before dependencies were installed (tsc missing); pnpm install --frozen-lockfile repaired the worktree environment, then pnpm typecheck passed. pnpm build:web, dist URL/CSP audit, Apple text-source self-test/check and test-guard self-test/check passed. Source comparison confirms all six existing navigation assertions and all five existing audit-helper assertion/audit lines preserved, with one additional 3:00 assertion in each flow. Serialized Apple driver running package/parity → three sending tests ×3 → macOS units; respecting shared lock.

Bounded iPhone run complete, exit 0: all three methods pass 3/3 with no skips/failures. Dark full audits: 101.507, 84.622, 72.277 s; light full audits: 95.015, 117.173, 106.086 s; navigation/debug-fill PASS assertions: 80.814, 198.256, 95.690 s. Total 9 tests, 951.439 s test time. /tmp/task-80-sending.log and /tmp/task-80-sending.xcresult. Original wrong-direction Grade preparation remains unchanged; XCTest auto-scroll still handles the tap and no local positioning fix was needed for the passing bounded run. macOS unit command queued on shared xbuild lock, not interrupted.
<!-- SECTION:NOTES:END -->
