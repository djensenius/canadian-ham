---
id: TASK-65
title: Investigate residual iOS heading-wait and single-figure audit flakes
status: To Do
assignee: []
created_date: '2026-10-20 06:58'
updated_date: '2026-10-23 12:31'
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
TASK-33 required iPhone 17 Pro runs exposed three unchanged test flakes. (1) testAccessibilityAuditMorseSendingResultsLight failed before its audit because morse-sending-results-heading did not exist within the existing 5-second wait after Grade (CanadianHamPracticeUITests.swift:1708, /tmp/task-33-after.log; dark passed67.311s and historical light passed72.445s). (2) testOhmsLawLessonFiguresAndAccessibilityDark failed with XCTest accessibilityAudit Code=-56, Audit failed to complete in time (471.508s, /tmp/task-33-after.log). Its light/dark pure-figure methods were moved intact into the figure plan under supervisor approval. (3) testModule7LessonFigureDarkSample failed with the same XCTest Code=-56 (230.276s, /tmp/task-33-figures.log); it already audits one lesson and one figure, so it cannot be range-split further. All audit/positioning/exception helpers are byte-identical to branch baseline. Raw result bundles share the corresponding log basename; durable per-test output is in docs/testing/task-33-ios-results.md. Supervisor approved one low-priority follow-up covering all three; investigate Grade interaction/results transition and residual single-figure audit timing without assuming longer waits or suppressing audit failures.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The causes of the intermittent post-Grade missing heading and residual single-figure XCTest audit timeouts are investigated with failure evidence, targeted reproduction, and host-load observations.
- [ ] #2 Relevant light/dark sending-results and Ohms-law/M7 figure tests retain every existing assertion and accessibility audit without skips, narrowed audit types, or relaxed exception handlers.
- [ ] #3 Targeted iPhone 17 Pro results for the affected methods and any residual flakiness are recorded; do not repeat full suites solely for this follow-up.
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
TASK-33 final evidence (all tests unchanged; no flake fix claimed):
1. Sending-results light failed at the 5 s post-Grade heading wait in /tmp/task-33-after.log (78.654 s); isolated /tmp/task-33-sending-results-rerun.log passed 91.923 s, outer wall208 s, exit0.
2. Ohms-law dark failed with accessibilityAudit Code=-56 in /tmp/task-33-after.log (471.508 s); the figure full run subsequently passed dark1316.588 s and light1321.591 s; isolated /tmp/task-33-ohms-dark-rerun.log passed1217.286 s, outer wall1253 s, exit0. Both pure-figure methods moved intact into the figure plan.
3. Single-figure M7 dark failed with Code=-56 in /tmp/task-33-figures.log (230.276 s); coordinator-run isolated /tmp/task-33-m7-dark-rerun.log passed257.999 s, outer wall402 s, exit0. It already has one lesson and one figure and cannot be range-split further.
Full-run totals: default126 UI (superset of final124),3 existing skips,2 failures, UI elapsed11390.378 s/outer11533 s; figure47 UI,1 failure, elapsed11444.382 s/outer11520 s. Units190 passed. Complete per-test results and literal failure lines: docs/testing/task-33-ios-results.md; result bundles use corresponding /tmp log basenames.
Host-load evidence at2026-10-20T10:39:35Z: load81.94/81.56/88.02, simulator testmanagerd99.9%CPU, two lockf84.9%/84.1%, host/simulator diagnosticd55.8%/50.2%, exactly one active xcodebuild observed. Coordinator confirmed FluxTerm builds shared the xbuild lock. No other lane process stopped; contention is context, not demonstrated causation. Supervisor approved TASK-33 acceptance with these documented unchanged failures plus passing isolated reruns; this follow-up remains To Do.

TASK-46.5 follow-up evidence (coordinator requested 2026-10-23): after merging TASK-70, unchanged testLessonTryItRevealAndAccessibilityLight on iPhone 17 Pro failed its temporary preceding-section workaround audit (314.438 s) on fully visible paragraph 'Compare blue-red-brown and blue-red-orange value bands. Their first two bands match.' The audit auto-scrolled away from the recorded Check-your-work/Try-it position to Faded practice; element screenshot shows high-contrast dark ink on paper. No exception authorized or added for this paragraph. Source log: /tmp/task-46.5-aligned-iphone.log; result bundle path: /tmp/task-46.5-aligned-iphone-xcresult-path.txt; exported element screenshot: /tmp/task-46.5-aligned-iphone-attachments/326FDD52-FACC-4AB9-8299-C9F343F47B21.png; app screenshot: /tmp/task-46.5-aligned-iphone-attachments/D55ADC5C-56D4-4765-AB04-513C81901DA7.png; manifest and Complete Issue Description in same directory. Coordinator authorized removing only that obsolete preceding-section detour from the new Try-it tests now TASK-70 handles offscreen content; direct Try-it audits must still fail all fully visible nonbullet findings. No production or shared helper change made for this finding.

TASK-46.5 direct-anchor reproduction 2026-10-23: after removing the preceding-section workaround, testLessonTryItRevealAndAccessibilityLight on iPhone 17 Pro still failed a full collapsed Try-it audit (332.957 s). It first asserted Try-it heading, prompt and Show answer fully visible below navigation; recorded heading y123.06 and control y193.67. The audit auto-scrolled upward and flagged fully visible nonbullet 'Answer: value = 4 700 ohms.' in preceding unchanged worked-example list. Element screenshot is high-contrast dark ink on paper. Log /tmp/task-46.5-direct-iphone-light.log; result path /tmp/task-46.5-direct-iphone-light-xcresult-path.txt; exported element /tmp/task-46.5-direct-iphone-light-attachments/0112CD4E-9436-4E51-BC5D-D112E6AE723A.png; app /tmp/task-46.5-direct-iphone-light-attachments/FE79754A-86F7-45DA-B38C-6D5F56966BA4.png; manifest in same directory. Alongside prior 'Compare blue-red-brown...' evidence above, this is residual contrast-audit auto-scroll evidence, not a claimed product contrast regression or an approved exception. Coordinator instructed no additional exception and authorized using the shortest Try-it lesson for new reveal full audits, retaining a no-audit long-lesson reveal behaviour test. Shared aligned helper remains unchanged; original failures preserved.

TASK-46.5 shortest-lesson control evidence 2026-10-23 (coordinator paused lane pending main/environment investigation): retargeted only new full Try-it audits to shortest authored Try-it lesson L-005-04 AC and decibels (8,985 Markdown body chars; Try-it starts at6,951, vs L-004-03 13,735/10,731). On iPhone17 Pro, unchanged full default collapsed-state audit with byte-identical aligned shared helper FAIL156.348s on fully visible nonbullet 'Try these before reading the feedback below.' Initial heading/prompt/Show answer visibility assertions passed. Element screenshot high-contrast dark ink on paper; app screenshot fully visible paragraph plus prompt/buttons. Exported element /tmp/task-46.5-short-iphone-light-attachments/BBEAFF9A-A75C-44FD-AFEF-AF3DF818B0E0.png; app /tmp/task-46.5-short-iphone-light-attachments/2D4A4655-2EE1-466D-B30D-D958EFFABA12.png; log /tmp/task-46.5-short-iphone-light.log; result path /tmp/task-46.5-short-iphone-light-xcresult-path.txt. No exception/audit suppression added; serial script stopped before remaining methods. Coordinator reports both lanes see fully visible high-contrast false positives, suspects simulator/environment or main, and TASK-46.6.1 lane is running a main control. This is evidence, not a demonstrated cause or resolved flake.
<!-- SECTION:NOTES:END -->
