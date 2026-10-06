---
id: TASK-12.7
title: Morse sending practice with tap timing
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-06 07:53'
labels:
  - web
  - apple
  - morse
milestone: m-1
dependencies:
  - TASK-12.6
parent_task_id: TASK-12
priority: medium
ordinal: 45000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the Morse qualification includes sending; the owner chose tap timing on keyboard or touch so no microphone permission is needed. See docs/proposals/morse-trainer.md (owner decisions in task-12 notes).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Straight-key and paddle emulation on keyboard and touch, with dot/dash ratio feedback
- [ ] #2 An exam-style check: whole text within 3:00, the 8-dot error signal and resend accepted, 5 or fewer errors to pass
- [x] #3 No microphone permission or new entitlements; tests pass on web and Apple
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect existing Morse engine/audio/copy exam flows and platform routing to identify narrow seams for sending practice.\n2. Add shared TS/Swift timing decode/scoring helpers plus JSON fixtures for tap classification and 8-dot error signal behavior.\n3. Add web sending practice and exam-style sending screens using the existing Morse audio controller and copy/exam corpus generator, with keyboard/touch controls and tests.\n4. Add iPhone/iPad/Mac sending practice/results screens using the Swift Morse engine/audio controller, DEBUG-only deterministic UI-test hook, localization strings, unit/UI tests, and leave tvOS/visionOS unchanged.\n5. Run targeted checks while iterating, then required web/package/Apple validations and record evidence before finalizing.

6. Address review findings: repair web/Apple keyboard and key lifecycle handling, correct timeout scoring to count remaining text as missing errors, add timeout/multi-element fixtures and tests, remove side effects from web state updates, add main sending screen audits, rerun validations, then re-check ACs only after evidence.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented Morse sending practice and review fixes: shared TS/Swift helpers classify straight-key timings, decode elements including the 8-dot error signal, apply delete/resend behavior, and score sending with existing exam diff/pass rules. Timeout now counts unsent characters as normal missing errors; it no longer forces failure or an invented 99%. Web sending practice grades from current refs after finalizing pending characters, restarts timers on exam restart/clear, releases stuck keys on blur/focus/visibility/lost pointer capture, registers with the shared playback coordinator, avoids hijacking Space from focused controls, uses current profile refs in release/listener paths, alternates iambic paddles from the opposite of the last sent element, uses duration+gap paddle repeat timing, and snapshots graded text. Apple iPhone/iPad/Mac sending practice is on a pushed screen; straight-key side-tone holds continuously until release, hardware keyboard handling uses onKeyPress for Space/J/K on a focusable screen, scenePhase and @GestureState cancellation stop held keys, paddle repeat uses duration+gap timing and clears the task handle only for the current task, iambic alternation starts from the opposite of the last sent element, and key buttons expose accessibility actions (straight-key Send dot/Send dash; paddle default activation sends one element). The sending entry is placed after existing Morse content so the Morse home layout audited by existing tests stays unchanged. tvOS and visionOS UI remain unchanged beyond linked shared Morse engine/audio changes. Banned workaround grep was clean: no branch-added accessibilityHidden, Color.black/Color.white, or audit-handler workaround. Merged origin/main cf81dcf in commit 55cb0cd7d114c0cf517901fb45b0c570cfc86e80 and resolved Localizable.xcstrings by JSON round-trip.

Validation summary on final code commit 652dfd95b22306a68c6d6fad774407c037552e47: pnpm typecheck passed; TZ=UTC pnpm test passed (content-tools 100 node tests, morse-engine 18 vitest tests, web 141 vitest tests); pnpm build:web passed; pnpm --filter @canadian-ham/web audit:urls passed; node --no-warnings scripts/check-apple-text-sources.ts passed; pnpm check:apple-network passed; packages/morse-swift swift test passed; pnpm check:apple-l10n passed; targeted iOS MorseTrainerTests + sending UI/audit tests passed; final full iOS, macOS, tvOS, and visionOS xbuild suites passed. Main sending screen audits added and passed: testAccessibilityAuditMorseSendingMainScreenLight and testAccessibilityAuditMorseSendingMainScreenDark.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented and review-fixed tap-based Morse sending practice. AC1 verified by web straight-key/paddle/stuck-key tests, shared 25/25 multi-element fixtures, Apple held-tone/hardware-key/accessibility-action code, and targeted/full iOS sending UI tests. AC2 verified by timeout/error-signal fixtures, corrected TS/Swift timeout scoring, web passing/restart/clear/timeout tests, and iOS exam-style sending flow/audits. AC3 verified with no microphone/entitlement changes, no-network/l10n/text-source checks, web checks, swift test, and final full iOS/macOS/tvOS/visionOS suites.
<!-- SECTION:FINAL_SUMMARY:END -->
