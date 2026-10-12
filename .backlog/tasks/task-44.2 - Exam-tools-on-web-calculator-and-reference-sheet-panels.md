---
id: TASK-44.2
title: Exam tools on web (calculator and reference sheet panels)
status: Done
assignee:
  - '@worker'
created_date: '2026-10-12 14:39'
updated_date: '2026-10-12 16:21'
labels:
  - web
dependencies:
  - TASK-44.1
parent_task_id: TASK-44
priority: medium
ordinal: 95000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Web UI for the calculator and reference sheet in practice and mock exams: a side panel on wide screens, a bottom drawer on narrow ones; non-modal, so the question and answer choices stay visible and operable; keyboard input for the calculator; screen-reader labels and a live-region result; EN/FR. The reference sheet source (official ISED sheet or the original study sheet) is pluggable per the owner's decision on licensing.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Question and answers remain visible and operable with either tool open at 320 px, tablet and desktop widths (tests)
- [x] #2 Calculator fully keyboard-operable with screen-reader announcements; axe passes with the panels open in light and dark
- [x] #3 The mock exam timer is unaffected; tools are available in practice and mock exams
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add an original Basic reference-sheet Markdown source plus a content-tool check that verifies required sheet entries against the authored lessons and wires that check into content validation.
2. Add a swappable web reference-sheet data module, import @canadian-ham/calculator-engine into the web app, and render non-modal exam-tool toolbars/panels in Basic practice and mock exam sessions with focus return, keyboard-scoped calculator input, localized display/spoken announcements, and no persistent storage.
3. Style the shared tools as an existing-token side panel on wide screens and an in-flow bottom drawer on narrow screens so question and answer controls remain visible/operable.
4. Add Vitest/RTL coverage for practice and mock tool buttons, open/close focus management, calculator keyboard/live output/locales, answer operability with panels open, timer continuity, axe in light/dark, and representative 320/tablet/desktop widths.
5. Run targeted web/content checks, then full required typecheck, test, web build, content/import/schema checks, and dist URL audit; finalize Backlog ACs with evidence.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Coordinator: this lane owns content/reference-sheet/ (an original interim formula sheet, swappable for the official ISED sheet once the owner decides on licensing).

Implemented original Basic reference-sheet content with a lesson-backed content validation script, web calculator/reference sheet tool panels in practice and mock exams, localized calculator UI/live output, focus-return behavior, responsive side-panel/bottom-drawer styling, and targeted RTL coverage. Targeted validation so far: pnpm --filter @canadian-ham/web typecheck passed; pnpm --filter @canadian-ham/content-tools check:reference-sheet passed; targeted App exam-tool tests passed (5 tests).

Final validation: pnpm typecheck passed; TZ=UTC pnpm test passed (content-tools 108, morse-engine 21, calculator-engine 127, web 165); pnpm build:web passed with existing large-chunk warning; pnpm --filter @canadian-ham/web audit:urls passed; pnpm check:schemas passed (46 schema tests / 1049 validation targets); pnpm import:check passed including the new reference-sheet validation (34 entries). Apple suites skipped because this task changed web/content only.

After merging current main into task-44.2-web-exam-tools, reran validation: pnpm typecheck passed; TZ=UTC pnpm test passed (content-tools 108, morse-engine 21, calculator-engine 127, web 165); pnpm build:web passed with existing large-chunk warning; pnpm --filter @canadian-ham/web audit:urls passed; pnpm check:schemas passed (46 schema tests / 1049 validation targets); pnpm import:check passed including reference-sheet validation (34 entries).

Review fix pass for r442 started: fix calculator button key handling/modifier shortcuts/state retention, responsive tool layout/drawer/DOM order, toolbar/display/heading/table-label accessibility nits, and add regression tests before rerunning web validation.

Review r442 fixes: calculator key handling now ignores buttons/modifier shortcuts, calculator state lives in ExamTools and survives close/tool switching while clearing on new session key, tool layout reserves the side column only when open, narrow panels are sticky bottom drawers with capped height and content padding, DOM order matches toolbar/content/panel flow, reference sheet heading/table labels are corrected, toolbar role changed to group, output label restored, Escape closes the reference sheet, and Advanced mock exams keep the Basic reference sheet disabled. Validation: pnpm typecheck passed; TZ=UTC pnpm test passed (content-tools 108, morse-engine 21, calculator-engine 127, web 169); pnpm build:web passed with existing large-chunk warning; pnpm --filter @canadian-ham/web audit:urls passed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Addressed r442 review changes for web exam tools: fixed calculator keyboard/button semantics and shortcuts, state retention, responsive side-panel/drawer layout, DOM/focus/accessibility nits, and added regression tests. Verified with typecheck, full tests, web build, and dist URL/CSP audit.
<!-- SECTION:FINAL_SUMMARY:END -->
