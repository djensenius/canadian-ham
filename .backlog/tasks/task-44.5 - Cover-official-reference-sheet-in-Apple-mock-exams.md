---
id: TASK-44.5
title: Cover official reference sheet in Apple mock exams
status: In Progress
assignee:
  - '@worker'
created_date: 2026-10-22 02:16
updated_date: '2026-10-25T00:57:00Z'
labels:
  - apple
  - testing
dependencies:
  - TASK-44.4
parent_task_id: TASK-44
priority: medium
ordinal: 146000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-44.4 internal review noted that the reference-sheet integration is exercised from practice but not mock exams. Cover the actual Basic mock-exam tool path without changing approved accessibility exceptions or exposing hints in mock exams. Official assets remain internal-only and Advanced has no Basic sheet.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 An Apple UI test opens the official sheet from a Basic mock exam and verifies page, zoom, accessible text and Study sheet fallback.
- [ ] #2 Using and closing the sheet preserves the current mock question, selected answer and exam progress.
- [ ] #3 Targeted iPhone and iPad checks and full-default accessibility audits pass, with only already-approved exception scopes if required.
- [ ] #4 Advanced mock exams still do not offer the Basic reference sheet and no mock exam offers hints.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect TASK-44.4/TASK-67, existing reference/mock tests and approved scope-specific helpers; leave existing tests/helpers unchanged.
2. Add Basic mock light/dark official-sheet coverage for pages, zoom, accessible text, Study fallback, question/answer/progress preservation and running/paused timer continuity; add Advanced/no-hints negative coverage. Fix only app bugs demonstrated by these tests.
3. Run targeted new and existing reference tests on iPhone 17 Pro and iPad Pro 13-inch (M5), the documented macOS unit command, l10n/text-source/test-guard checks via nohup and grep polling; no full simulator suites.
4. Record per-test evidence, finalize all four criteria, commit and push the task branch without a PR.

5. Coordinator-approved 2026-10-24 fix: change only exam-code caption weight to medium, preserve colour/size/text selection and all audit scopes. Retain before/after screenshots; rerun new mock flows and six existing mock-seed regressions on both requested devices. Stop/report if the fully visible caption is still flagged.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added three UI tests in CanadianHamExamToolsUITests: Basic mock light/running and dark/paused sheet flows plus Advanced/no-sheet/no-hints negative coverage. Basic fixtures answer two questions and remain on question 2/3, then exercise all five pages/back navigation, zoom in/out, accessible formula text and Study fallback before verifying question/answer/exam seed/answered count and timer continuity. Full-default audits use raw calls for official image/text and iPhone fallback, the unchanged TASK-44.4 reference-scroll helper only for iPad fallback, and the unchanged occluded mock-screen helper before/after. No existing tests, shared helpers or app source changed. Targeted iPhone/iPad, documented macOS units, l10n/text/guard checks are running via nohup (/tmp/task445-checks.log), one destination at a time; no full simulator suites or killed builds.

First targeted iPhone attempt reached Study fallback but failed a new over-strict heading assertion: LessonMarkdownView intentionally suppresses a level-1 heading matching its supplied title. Corrected the new test to assert the actual accessible Study introduction and Ohm\x27s law heading instead. Official transcript title/formula assertions passed. This is a test-fixture correction, not an app bug; existing tests/helpers remain unchanged. The ongoing runner is not interrupted; iPad will build the correction, and only the two affected iPhone mock methods will be rerun.

Source commit ebeedb0c (full SHA recorded at finalization) adds one block only: removing it restores the baseline CanadianHamExamToolsUITests.swift byte-for-byte, so every existing test/helper is unchanged. First iPhone existing reference regression results PASS: matrix 224.881s, medium 110.354s (5/6 already-approved findings), AX-XXXL 132.575s, Basic-only availability 18.713s; Advanced mock negative PASS 38.332s. Only the two new mock methods failed the intentionally omitted Study title expectation and are rerunning with the corrected actual introduction/Ohm's law assertion. The approved branch-diff guard passes with Test-guard-approved: owner decision 2026-10-12 (intentional new default audits and existing occlusion-helper call sites); no new measured-contrast or medium-detent exception scope. Future reviewer/PR must verify this marker and exact unchanged helper scope. No app bug found so far.

Corrected-Study iPhone rerun: dark/paused PASS (216.464s); light/running reached all sheet and question/answer/progress checks but failed the test's single-timestamp wall-time comparison (116s timer advance versus 112.942s wall time, 3s tolerance). XCUI label snapshot acquisition itself can take seconds; this was test instrumentation latency, not an app reset/pause. The new timing check brackets both snapshot reads and asserts elapsed against the minimum/maximum possible wall interval, allowing two seconds only for whole-second tick rounding/delivery. It retains monotonicity, exact running state, no-pause/no-reset bounds and a keepAlways before/after/range attachment. Only affected light/running methods will rerun on iPhone/iPad. Existing helpers/audits unchanged; current iPad run is left alone.

BLOCKER/FIX DECISION — iPad first run: both new mock methods failed the pre-sheet full-default audit on fully visible mock-exam-seed (light contrast failed, dark nearly passed). The unchanged occlusion helper correctly refused the findings. Before evidence: Test-CanadianHam-2026.10.24_19-02-02--0400.xcresult; light app/element PNGs exported under /tmp/task445-ipad-light-attachments (27C34C1F-C330-422B-9D5B-862B679E9418.png / B2933CAE-5FDC-4DA0-9FE6-AFF090645C02.png). Element crop includes regular-weight monospaced seed text plus card-border/next-heading edges.
Coordinator decision 2026-10-24 under owner delegation 2026-10-22: do NOT extend any exception; apply only .weight(.medium) to the existing exam-code caption, same ink/size and textSelection enabled. Implemented that one-line legibility fix. New tests retain app/seed keepAlways screenshots before the full audit for after evidence. Rerun all new mock flows plus the existing tests found via mock-exam-seed on iPhone/iPad, keeping every existing test/helper unchanged. Stop/report without further changes if the fully visible caption is still flagged. Existing iPad matrix PASS 182.702s, AX PASS 56.543s, availability PASS 16.065s, Advanced negative PASS 17.025s; medium SKIPPED by unchanged iPhone-only guard (6.216s). No build killed; queued running-timer-only tests will compile the approved caption fix.

Validation currently queued on the shared xbuild lock (2026-10-24 ~19:36 local); no builds interrupted. Persistent nohup runners: /tmp/task445-checks.sh -> /tmp/task445-checks.log (original targeted reference runs complete; documented macOS units/l10n/text/self-test pending), /tmp/task445-running-final.sh -> /tmp/task445-running-final.log (latest-source light/running on iPhone then iPad), and /tmp/task445-caption-regressions.sh -> /tmp/task445-caption-regressions.log (waits for both running-flow passes, then dark/Advanced and six unchanged existing mock-seed tests on each requested device; stops on failed command). After screenshot evidence is keepAlways in the new tests. No completion criteria checked yet.

Latest-source results: documented macOS command PASS 218/218 units, including compilation of CanadianHamUITests and the guarded iOS-only idiom check (20:14 local). Final iPhone light/running mock flow PASS 245.891s, including all five full-default audits and bounded running-timer continuity. Its medium-weight caption app/element screenshots and timer-range keepAlways attachment are retained in Test-CanadianHam-2026.10.24_20-15-29--0400.xcresult; exported to /tmp/task445-iphone-light-after. Final approved guard, exact existing-test/helper byte-for-byte proof and baseline diff whitespace check PASS (/tmp/task445-guard-final.log). iPad light/running and caption regressions still await the shared lock; current owner is the TASK-46.7 targeted iPad run, no builds interrupted.

Coordinator-approved audit-state alignment (2026-10-24): the medium caption resolves the iPad fully visible seed contrast finding. The next raw image audit at page 4 / 100% zoom fails one nil-element textClipped issue (no identifier or element screenshot), recorded in /tmp/task445-ipad-running-final.log and Test-CanadianHam-2026.10.24_20-50-46--0400.xcresult. This was not ignored or treated as an approved exception. Search-first follow-up TASK-74 was created on this branch to investigate the 100% state on BOTH practice and mock paths in light/dark; existing practice matrix also audits only at 150%. Coordinator explicitly approved aligning the new mock image audit to the same 150% state, while keeping the real 100% zoom-out tap/assertion. Audits/types/helpers otherwise unchanged. Eventual PR must name TASK-74 and disclose this state alignment / un-audited 100% state; no new iPad textClipped exception.
Before/after caption evidence: original iPad light seed crop /tmp/task445-ipad-light-attachments/B2933CAE-5FDC-4DA0-9FE6-AFF090645C02.png; after-medium crop /tmp/task445-ipad-light-after/25369C27-932F-43EC-97D0-E1F1FF6BB19F.png and app /tmp/task445-ipad-light-after/044E8782-0C03-4A17-A9F3-4D78C7BD3F61.png. Old dark crop /tmp/task445-ipad-dark-before/BDD80782-FBED-42E0-94BE-6596F7BB3132.png. All originals remain in their cited xcresults.
The original gated caption runner correctly did not start after the failed 100% audit. A replacement targeted runner will now run all three new mock tests and all six unchanged mock-seed regressions per device, followed by macOS relevant units/UI-test-source compile. Earlier existing reference checks remain green and unchanged; no full suites or interrupted builds.
<!-- SECTION:NOTES:END -->
