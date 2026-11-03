---
id: TASK-80
title: Morse sending exam and its UI test use the official ISED Morse test standard
status: Done
assignee:
  - '@worker'
created_date: '2026-10-28T01:32:00Z'
updated_date: '2026-10-28T02:18:00Z'
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
- [x] #1 The official ISED Morse test standard (speed, sending duration and format) is cited from primary sources with section numbers and recorded in docs/exam-facts.md (EN/FR where available)
- [x] #2 The app's Morse sending exam (iOS/iPadOS/macOS, web if it has one) matches the official standard, or any deliberate practice-mode difference is labelled. Morse engine/profile tests cover it
- [x] #3 The sending UI tests use the official exam duration (no arbitrary debug length); the light and dark sending audit tests pass 3/3 each with every assertion and the full audit unchanged
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

Final validation complete: macOS app unit command passed 224/224, zero failures/skips (23.848 s test time; outer command includes shared-lock wait). All 224 per-test results and exact command are committed in docs/testing/task-80-macos-unit-results.md; docs/testing/task-80-morse-official-timing.md records the 3/3 light, 3/3 dark and 3/3 navigation results, package tests, parity, static/web gates and skipped platforms. Morse shared fixtures pass in TS 23/23 and Swift 6/6; requested base-engine parity script passes TS 32/32 and Swift 22/22. Driver ran once per Apple command, no retries, no other build killed. No new audit exceptions, positioning changes, official-data edits, SwiftUI strings, or PR. AC1 verified by current EN/FR primary-source quotations and section numbers in docs/exam-facts.md; AC2 by production duration use, existing practice labels, paired engine tests/shared fixtures and web fake-timer test; AC3 by all six unchanged full audits and all three navigation iterations. Other Apple full suites deferred to coordinator merge batch per bounded task/test policy; independent branch review remains required.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Use the sourced ISED three-minute sending allowance, not a 120-second debug fixture, in all three sending-results UI tests. Production Apple/web configuration already matched the ≥5 wpm / ≥75 weighted-character standard; named the duration in TS/Swift, retained grading and clearly documented practice differences. Added paired engine/profile tests, shared sending/boundary fixtures and a web default-deadline regression. All required checks pass, including light/dark audits 3/3 each, navigation 3/3, and macOS 224/224. EN/FR source discrepancies, the initial dependency-only typecheck failure/recovery, skipped platform suites and unchanged Grade auto-scroll are documented. No PR created; ready for independent review.
<!-- SECTION:FINAL_SUMMARY:END -->
