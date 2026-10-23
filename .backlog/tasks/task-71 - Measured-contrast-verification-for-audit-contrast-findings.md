---
id: TASK-71
title: Measured-contrast verification for audit contrast findings
status: Done
assignee:
  - '@worker'
created_date: '2026-10-23 12:50'
updated_date: '2026-10-23 13:06'
labels:
  - accessibility
  - tests
dependencies: []
priority: high
ordinal: 150000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner-delegated decision 2026-10-22 (owner: make the best decisions you can). XCTest's performAccessibilityAudit reports contrast findings on fully visible, visibly high-contrast lesson and lesson-quiz text in the new TASK-46.5 and TASK-46.6.1 tests (e.g. 'Correct 820 / 1 000 = 0.82 A…' on the success panel, a Try-it intro paragraph, 'Question 1 of 1'), while main's existing tests pass. Evidence is in TASK-65 and /tmp/task-46.6.1-iphone-final-failure-evidence.json. Add a shared UI-test helper that runs the full default audit and, for contrast findings only on a non-nil element, measures the WCAG contrast ratio from the element screenshot pixels and ignores the finding only when the measured ratio is at least 4.5:1, logging the label, frame and ratio. Measurement failure or a ratio below 4.5:1 still fails; all non-contrast issues still fail. Used only by the new TASK-46.5 and TASK-46.6.1 audits unless a later decision widens it.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A shared helper measures text/background contrast from the element screenshot (WCAG relative luminance), ignores contrast findings only when the measured ratio >= 4.5:1, and logs label, frame and ratio; non-contrast, nil-element, unmeasurable and < 4.5:1 findings fail
- [x] #2 Unit-style tests prove the measurement on synthetic images: dark-on-cream passes, mid-grey-on-cream (< 4.5:1) fails, two-colour panels and anti-aliased text are handled, and a uniform image is unmeasurable
- [x] #3 AGENTS.md records the dated owner-delegated decision and its scope; existing helpers and existing tests are unchanged
- [x] #4 Targeted proof: the helper passes on the known false-positive screens and fails on a deliberately low-contrast DEBUG-only fixture or an equivalent synthetic proof
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect failure screenshots and existing UI-test audit/target conventions.
2. Add a pure quantized WCAG contrast measurement helper, strict default-audit wrapper, synthetic proofs and three exported element-image resources; document the narrow approved scope.
3. Regenerate XcodeGen twice and verify no second-run changes; run only the new pure UI-test class on iPhone 17 Pro through nohup/xbuild, polling its log. Verify the test guard flags the handler.
4. Record evidence per AC, finalize TASK-71, commit and push the task branch (no PR).

5. Review fixes B1/B2: report the minimum significant non-background contrast, reject ambiguous multi-backgrounds, and discard only colour-line blends supported by spatial edge evidence; retain existing proofs and add mixed blocks/text/icon/panel/black-band and bold 3× edge-band regressions.
6. Review fixes S1/S2: reject empty/off-window/under-nav frames before screenshots; attach label/frame/ratio or unmeasurable for every contrast failure. Update measurement docs.
7. Run the targeted proof class via nohup/xbuild and grep polling, recheck the test guard with dated marker, record all results, restore Done, commit and push without a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implementation and evidence (2026-10-23):
AC1: UITestContrastMeasurement.swift implements native-pixel CGImage -> 5-bit RGB clusters (original-channel means), dominant background, >=2% candidate text, WCAG sRGB luminance/ratio; nil for uniform, transparent or insufficient foreground. auditVerifyingMeasuredContrast calls the full DEFAULT audit, guards exact .contrast + non-nil element + measurable screenshot + ratio>=4.5, logs label/frame/unrounded ratio in keepAlways XCTContext attachment, returns false otherwise. Code compiled by targeted iOS proof; no live audit call site changed.
AC2: UITestContrastMeasurementTests: 12/12 passed, 0 skipped/failures on iPhone 17 Pro iOS27.0. Includes near-black/cream15.9943, #9A9A9A/cream2.6591<4.5, pale/green10.5978, antialiased15pt high/low text, <2% high-contrast tail, uniform/tiny foreground/transparent nil, plus 3 real element exports. Final class2.372s; per-test results in docs/testing/task-71-measured-contrast.md. Initial12/12 passed too; fixed a new XCTContext actor warning with @MainActor and reran only this class. Final new Swift files have no warnings/errors.
AC3: AGENTS.md records owner-delegated decision2026-10-22 TASK-71 limited to NEW TASK-46.5/TASK-46.6.1 audits. git diff main --exit-code on all3 existing UI-test source files passed: existing tests/helpers byte-identical. Added only iOS UI-test target source/resources via project.yml; regenerated XcodeGen twice; full generated diff and project.pbxproj byte-identical on second run.
AC4: Unmodified exported Correct-feedback light8.344323837747055:1/dark11.403364958858397:1 and Try-it paragraph16.336427704401043:1 pass; deliberately low-contrast synthetic panel and antialiased text assert2.6591<4.5. Provenance, SHA256 and actual attachment ratios in docs/testing/task-71-measured-contrast.md. Final log /tmp/task-71-contrast-tests-final.log; bundle /tmp/task-71-contrast-tests-final.xcresult; summary /tmp/task-71-final-summary.json; measurements /tmp/task-71-final-proof-attachments/. Run used nohup/xbuild with -only-testing:CanadianHamUITests/UITestContrastMeasurementTests on the single requested destination and grep polling; no builds killed. No app launches in pure tests, no live screen-integration claim.
Guard: self-test passed. node scripts/check-test-guard.mjs --base main --head HEAD failed as expected(exit1) and flagged new handler/default audit call at UITestContrastMeasurement.swift72-73. Same check with TEST_GUARD_PR_BODY="Test-guard-approved: owner decision 2026-10-22" passed(exit0). Logs /tmp/task-71-test-guard-{unapproved,approved}.log. Required future PR marker documented. git diff --check passed. macOS/tvOS/visionOS and full iOS suites skipped: only the iOS UI-test target changed; integration into the two task branches remains separate. No PR opened.

Internal review fixes (2026-10-23), B1/B2/S1/S2/S3:
AC1/B1: minimum WCAG ratio across all remaining >=2% non-background clusters replaces maximum luminance difference. Discard only colour-line blends (8 RGB units perpendicular tolerance) with EVERY pixel within two native pixels of both background and significant core. This spatial constraint prevents solid or separate blend-coloured grey text from being discarded. Background <=50%, another >=25% tone, and significant <=1.1:1 noise fail closed with nil. S1: non-empty frame must be fully window-contained and below navigation/status bars before screenshot; pure geometry test proves rejection. S2: BOTH successful and failed contrast findings attach keepAlways label/frame/ratio or unmeasurable; non-contrast always false.
AC2/B2/S3: all original 12 tests retained; 11 added for 3% high+low blocks, exact colour-line solid block, mixed bold15pt3x lines, 5.4% dark icon+grey text, cream/green panel+dark text, equal large tones, near-background noise, 3% black offscreen band+grey text, significant6.4% synthetic AA bands, actual bold3x significant AA cluster coverage, and geometry. Actual bold15pt3x edge cluster2.6666667% passes core15.9942758247219:1, so no cutoff/tolerance widening needed.
AC3: scope remains only new TASK-46.5/46.6.1 audits. Existing pre-TASK-71 UI-test files unchanged; app code, existing audit helpers/calls, project membership and resources untouched by fix. XcodeGen not needed.
AC4: all23 targeted iPhone17Pro/iOS27.0 tests PASSED,0 failures/skips, class3.469s, xbuild exit0. Re-run real screenshot ratios remain8.344323837747055/11.403364958858397/16.336427704401043:1. Mixed grey tests assert2.6591 within0.01/0.1 or panel nil. Log/tmp/task-71-review-tests.log; bundle/tmp/task-71-review-tests.xcresult; summary/tmp/task-71-review-summary.json; exported keepAlways proofs/tmp/task-71-review-proof-attachments/. Run used nohup bash /tmp/task-71-review-tests.sh and grep polling; no other builds killed. Detailed per-test results in docs/testing/task-71-measured-contrast.md. No Swift errors/warnings in changed files (unrelated AppIntents metadata warning). No live app launch/audit integration claimed. Other platforms/full suites skipped because only iOS UI-test target changed.
Guard self-test passed; unapproved main...HEAD correctly failed(exit1) at handler/default audit lines128/136; same diff with standalone Test-guard-approved: owner decision 2026-10-22 passed(exit0). Logs/tmp/task-71-review-test-guard-{self,unapproved,approved}.log. git diff --check passed. Implementation commit6b6af119c04597bcca616f71d75ed0fd7f9671fd. Independent re-review remains required; no PR opened.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Addressed internal review B1/B2/S1/S2/S3 with conservative minimum-ratio WCAG measurement, colour-line-plus-spatial antialias filtering, fail-closed background ambiguity checks, pre-screenshot window/below-bar geometry, and keepAlways failure diagnostics. Retained all12 original tests and added11 regressions. All23 targeted iPhone17Pro tests passed with0 failures/skips; three real screenshots still measure8.3443/11.4034/16.3364:1. Bold15pt3x edge coverage2.6667% and synthetic6.4% bands pass without weakening the2% cutoff; mixed low-contrast content fails. Dated guard marker passes; existing app/tests/helpers unchanged. Evidence and per-test results: docs/testing/task-71-measured-contrast.md. Pure image/geometry proofs only: no live audit integration claimed; dominant-background/<2% coverage limitations remain, and ambiguous/noisy backgrounds fail closed. Done pending independent re-review; no PR.
<!-- SECTION:FINAL_SUMMARY:END -->
