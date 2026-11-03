---
id: TASK-44.5
title: Cover official reference sheet in Apple mock exams
status: Done
assignee:
  - '@worker'
created_date: 2026-10-22 02:16
updated_date: '2026-10-25T03:34:00Z'
labels:
  - apple
  - testing
dependencies:
  - TASK-44.4
modified_files:
  - apps/apple/CanadianHamUITests/CanadianHamExamToolsUITests.swift
  - AGENTS.md
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
- [x] #1 An Apple UI test opens the official sheet from a Basic mock exam and verifies page, zoom, accessible text and Study sheet fallback.
- [x] #2 Using and closing the sheet preserves the current mock question, selected answer and exam progress.
- [x] #3 Targeted iPhone and iPad checks and full-default accessibility audits pass, with only already-approved exception scopes if required.
- [x] #4 Advanced mock exams still do not offer the Basic reference sheet and no mock exam offers hints.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect TASK-44.4/TASK-67 and approved helpers, preserving every existing test/helper.
2. Add Basic mock light/running and dark/paused official sheet coverage (pages, zoom, accessible text, Study fallback, question/answer/progress/timer continuity) and Advanced/no-Hint negatives.
3. Apply superseding coordinator 2026-10-24 decision under owner delegation 2026-10-22: app visuals/source stay baseline; iPhone keeps every full-default audit, new iPad mock tests keep every behaviour assertion without full audits. Record AGENTS limitation and merge unresolved iPad caption/100%/150%/legacy compact-Questions findings into TASK-74.
4. Validate new tests on both requested devices, existing reference checks, six unchanged iPhone mock-seed regressions and documented iPad legacy limitations; run macOS units/UI-test compilation, l10n/text/guard/source proof. Record per-test evidence, check all ACs, finalize, commit and push without a PR.
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

SUPERSEDING DECISION — coordinator 2026-10-24 under owner delegation 2026-10-22:
The 150% alignment did NOT resolve iPad nil textClipped (new dark FAIL 56.335s / light FAIL 58.934s at raw image audit). The unchanged legacy light audit also flags the medium-weight exam-code caption for ui-a11y-mock-exam-timer. Existing legacy dark and AX-XXXL mock tests assume the compact Questions button and fail on the real iPad regular layout. Stop rule was honored: no further presentation or exception experiments.
Per explicit coordinator direction, reverted the medium caption, so StudyViews.swift and app visuals are byte-for-byte baseline again. Added only an iPad idiom condition to the NEW mock helper: every behaviour assertion remains, but all five full audits are iPhone-only; macOS compilation keeps the condition true under #if os(iOS) guarding UIKit. Existing tests and shared helpers stay unchanged. AGENTS.md records the dated iPad limitation, distinct from TASK-71/73 measured contrast; no new finding filter.
Search-first merged the earlier 100% follow-up into TASK-74, now titled iPad mock exam accessibility audits, covering thin-caption contrast, nil textClipped at 100% AND 150% on practice/mock paths, and legacy compact-Questions assumptions. Evidence: /tmp/task445-ipad-final.log; Test-CanadianHam-2026.10.24_21-16-19--0400.xcresult; /tmp/task445-ipad-150-{light,dark}; /tmp/task445-ipad-legacy-light/ECD64D0A-4E39-49F8-A543-5D3273666E85.png. Pre-existing iPad-incompatible legacy tests are not regressions and were not edited.
AC3 completion is explicitly defined by this decision as iPhone full-default audits plus iPad behaviour coverage under the documented temporary limitation. Eventual PR must disclose this scope, TASK-74 and the superseded 100%/150% experiments, and carry Test-guard-approved: owner decision 2026-10-24 on its own line for reviewer verification. L10n/text-source/test-guard self-test completed PASS at 21:24 local; catalogue unchanged. Final source reruns will confirm iPhone nine-method batch after the caption revert, iPad three new behaviour tests and documented macOS unit/UI-test-source build.

Final approved-source runner for resumption: /tmp/task445-approved-final.sh -> /tmp/task445-approved-final.log, per-command /tmp/task445-{iphone-approved,ipad-approved,macos-approved,guard-approved,unchanged-source}.log. It runs iPhone nine selected methods after the app revert, iPad three new behaviour methods under the explicit limitation, the exact documented macOS unit command, the branch guard with owner-decision-2026-10-24 marker and byte-for-byte unchanged existing-test/helper/app-source proof. Currently waiting on the shared xbuild lock (~22:03 local); no builds interrupted. Original /tmp/task445-checks.log completed l10n, text source and guard self-test with exit 0. ACs remain unchecked pending this final approved-source validation.

FINAL APPROVED-SOURCE VALIDATION — 2026-10-24 local (2026-10-25 UTC)

Source commit: b2fa8e717050f0bcf1b18a6ebe2ee6fa8ac34c58. Final branch task-44.5-mock-sheet-coverage. No app changes remain: StudyViews.swift and every existing UI test/helper are byte-for-byte baseline 65c5bd500e6d010c05faf79793dd83a1e0aba889. Only the new mock-test block, dated AGENTS limitation and task records differ. The medium caption experiment is reverted.

AC1: Both devices pass light/running and dark/paused Basic mock flows: select answers on two questions, remain on question 2/3, open official sheet, visit all five pages/back, verify endpoint enablement and page labels, zoom to 150% and back to 100%, show native accessible transcript/title/formula, restore image/page, switch to Study introduction/Ohm's law content, restore official image and close.
AC2: Both devices preserve exact current question ID/stem, selected answer label/selected state, exam seed, question index 2/3 and answered count 2/3 after closing. Paused timer text is identical and Resume remains available; running time stays monotonic and within bracketed snapshot-read/wall-time bounds. Final iPad timer attachment: 10→61 seconds, delta 51, allowed range 48.998...53.072s; no pause/reset. Screenshots/timer notes are keepAlways.
AC3: Final iPhone nine-method batch 9/9 PASS including every new full-default audit (five per Basic mock flow, light/dark) and six unchanged legacy mock regressions. Final iPad three new methods 3/3 PASS with EVERY behaviour assertion and no full audits, exactly per the superseding coordinator 2026-10-24 decision under owner delegation 2026-10-22, recorded in AGENTS. Existing reference matrix/AX/medium/availability per-device results below remain valid: those existing tests/helpers and app source are unchanged. The iPad medium test is skipped only by its pre-existing iPhone-only guard. The earlier iPad legacy attempt's three failures are recorded below, pre-existing and assigned to TASK-74, not silently removed or fixed here.
AC4: Both devices' new Advanced mock negative passes with an A- question, calculator present, Basic reference absent and Hint button/panel absent. Both Basic flows explicitly reject Hint before/after tool use.

LIMITATION / REQUIRED PR DISCLOSURE: TASK-74 is now iPad mock exam accessibility audits, incorporating the earlier 100% follow-up. It tracks fully visible thin exam-code contrast, nil-element official-sheet textClipped at BOTH 100% and 150%, and legacy dark/AX tests that assume a compact Questions button. The caption is visually baseline; new iPad mock tests retain behavior without full audits, while iPhone retains all full-default audits. No measured-contrast rule or finding filter was added/widened; no existing audit/test/helper was changed. New official-image audit aligns with the existing practice matrix at 150%; 100% zoom-out is still tapped/asserted. Future PR must disclose all these limits and include exactly:
Test-guard-approved: owner decision 2026-10-24
Reviewer must verify the documented delegation and local iPad-only audit condition. Independent review is still required; no PR was opened.

Final approved commands all exit 0 (/tmp/task445-approved-final.log): iPhone 9 UI tests; iPad 3 new UI tests; documented macOS 218 units plus UI-test target compilation; approved branch-diff guard; exact unchanged-source proof plus git diff --check. Original runner /tmp/task445-checks.log also completed pnpm check:apple-l10n (including tvOS/visionOS localization builds), node scripts/check-apple-text-sources.ts and guard --self-test with exit 0. Catalogue unchanged.

All Apple commands used xbuild with DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer, nohup runners, grep polling and one requested destination per run. No builds killed or extra simulators booted manually. Long shared-lock waits were allowed to finish. No full simulator suites, web/package tests, TestFlight/upload/public distribution or PR; web/packages unchanged, and tvOS/visionOS do not compile these app views or this UI-test target (their localization builds passed).

Artifacts: full stdout /tmp/task445-{iphone-approved,ipad-approved,macos-approved}.log; original reference outputs /tmp/task445-{iphone,ipad}.log; l10n/text/guard outputs /tmp/task445-{l10n,text-sources,guard-self-test,guard-approved,unchanged-source}.log. Final iPad/macOS bundles preserved as /tmp/task445-final-{ipad,macos}.xcresult. Xcode's two-result retention auto-rotated the final iPhone xcresult during subsequent iPad/macOS runs; its complete stdout and all nine per-test outcomes remain. Earlier iPhone caption/timer artifacts remain exported at /tmp/task445-iphone-light-after. No tests rerun solely to recreate artifacts.
Final reverted-caption iPad light app/caption/timer attachments: /tmp/task445-ipad-light-approved-artifacts/{1307C24C-52BB-4CA5-AFF5-D0EA44253C64.png,1A8CFD99-9309-462A-830E-A23FF3DE7845.png,878B6790-079B-4F23-A80E-F240548B06FD.txt}; dark app/caption: /tmp/task445-ipad-dark-approved-artifacts/{EE4BC082-D0F1-4AFC-A28C-DD67255390B8.png,572247D2-39F4-4CDB-AB54-6EB6C30DC192.png}. Before and failed medium-experiment screenshots are recorded above and in TASK-74. Retained final iPad bundle is Test-CanadianHam-2026.10.24_23-27-05--0400.xcresult, macOS Test-CanadianHam-2026.10.24_23-30-51--0400.xcresult under the same DerivedData Logs/Test directory. Earlier failed bundles may also rotate; exported before/after/failure PNGs and all stdout are retained in the cited /tmp directories.

Final iPhone 17 Pro — 9/9 PASS
- CanadianHamUITests.CanadianHamExamToolsUITests.testAdvancedMockExamHasNoBasicReferenceSheetOrHints: PASSED (37.207s).
- CanadianHamUITests.CanadianHamExamToolsUITests.testMockExamOfficialReferenceSheetDarkPreservesPausedExam: PASSED (190.432s).
- CanadianHamUITests.CanadianHamExamToolsUITests.testMockExamOfficialReferenceSheetLightPreservesRunningExam: PASSED (197.766s).
- CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditMockExamFlowDark: PASSED (123.051s).
- CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditMockExamFlowLight: PASSED (124.352s).
- CanadianHamUITests.CanadianHamPracticeUITests.testMockExamDoesNotShowCorrectnessBeforeSubmit: PASSED (22.509s).
- CanadianHamUITests.CanadianHamPracticeUITests.testMockExamHeaderControlsSupportLargestAccessibilityTextSize: PASSED (53.853s).
- CanadianHamUITests.CanadianHamPracticeUITests.testRegularWidthMockExamResultPersistsAfterSubmit: PASSED (57.185s).
- CanadianHamUITests.CanadianHamPracticeUITests.testSettingsResetClearsSavedMockExamProgress: PASSED (51.252s).

Final iPad Pro 13-inch (M5) — 3/3 PASS (behaviour only, explicitly approved limitation)
- CanadianHamUITests.CanadianHamExamToolsUITests.testAdvancedMockExamHasNoBasicReferenceSheetOrHints: PASSED (16.485s).
- CanadianHamUITests.CanadianHamExamToolsUITests.testMockExamOfficialReferenceSheetDarkPreservesPausedExam: PASSED (81.966s).
- CanadianHamUITests.CanadianHamExamToolsUITests.testMockExamOfficialReferenceSheetLightPreservesRunningExam: PASSED (78.631s).

Existing iPhone reference-sheet checks — 4/4 PASS
- CanadianHamUITests.CanadianHamExamToolsUITests.testOfficialReferenceSheetLightAndDarkEnglishAndFrench: PASSED (224.881s).
- CanadianHamUITests.CanadianHamExamToolsUITests.testOfficialReferenceSheetMediumDetentControlsAndShowFullSheet: PASSED (110.354s).
- CanadianHamUITests.CanadianHamExamToolsUITests.testReferenceSheetLargestDynamicTypeKeepsControlsReachable: PASSED (132.575s).
- CanadianHamUITests.CanadianHamExamToolsUITests.testReferenceSheetToolAvailableOnlyForBasic: PASSED (18.713s).

Existing iPad reference-sheet checks — 3 PASS / 1 existing platform SKIP
- CanadianHamUITests.CanadianHamExamToolsUITests.testOfficialReferenceSheetLightAndDarkEnglishAndFrench: PASSED (182.702s).
- CanadianHamUITests.CanadianHamExamToolsUITests.testOfficialReferenceSheetMediumDetentControlsAndShowFullSheet: SKIPPED (6.216s).
- CanadianHamUITests.CanadianHamExamToolsUITests.testReferenceSheetLargestDynamicTypeKeepsControlsReachable: PASSED (56.543s).
- CanadianHamUITests.CanadianHamExamToolsUITests.testReferenceSheetToolAvailableOnlyForBasic: PASSED (16.065s).

Earlier iPad legacy attempt — unchanged tests, three pre-existing failures assigned to TASK-74
- CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditMockExamFlowDark: FAILED (28.769s).
- CanadianHamUITests.CanadianHamPracticeUITests.testAccessibilityAuditMockExamFlowLight: FAILED (19.434s).
- CanadianHamUITests.CanadianHamPracticeUITests.testMockExamDoesNotShowCorrectnessBeforeSubmit: PASSED (13.089s).
- CanadianHamUITests.CanadianHamPracticeUITests.testMockExamHeaderControlsSupportLargestAccessibilityTextSize: FAILED (27.970s).
- CanadianHamUITests.CanadianHamPracticeUITests.testRegularWidthMockExamResultPersistsAfterSubmit: PASSED (81.128s).
- CanadianHamUITests.CanadianHamPracticeUITests.testSettingsResetClearsSavedMockExamProgress: PASSED (41.592s).

Final documented macOS unit command — 218/218 individual PASS, UI-test source compiled
- CanadianHamTests.DuoLayoutPolicyTests.testCompactWidthIPhoneKeepsSheetPolicy: PASSED (0.001s).
- CanadianHamTests.DuoLayoutPolicyTests.testForcedRegularIPhoneLandscapeKeepsSheetPolicyWhenVerticalIsCompact: PASSED (0.001s).
- CanadianHamTests.DuoLayoutPolicyTests.testIPadInspectorRuleRemainsSizeClassDriven: PASSED (0.001s).
- CanadianHamTests.DuoLayoutPolicyTests.testMacAndOtherIdiomsNeverUseIPhonePolicy: PASSED (0.001s).
- CanadianHamTests.DuoLayoutPolicyTests.testNilVerticalSizeClassDoesNotBlockRegularWidthIPhonePolicy: PASSED (0.000s).
- CanadianHamTests.DuoLayoutPolicyTests.testRegularWidthIPhoneUsesUnfoldedInspectorPolicyWhenVerticalIsNotCompact: PASSED (0.001s).
- CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutCanRepresentFittingContentWithAndWithoutHelp: PASSED (0.001s).
- CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutFittingCandidatesPreferLargeKeysBeforeMinimumKeys: PASSED (0.001s).
- CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere: PASSED (0.001s).
- CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds: PASSED (0.001s).
- CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes: PASSED (0.001s).
- CanadianHamTests.ExamCalculatorViewModelTests.testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale: PASSED (0.001s).
- CanadianHamTests.ExamCalculatorViewModelTests.testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString: PASSED (0.001s).
- CanadianHamTests.ExamCalculatorViewModelTests.testKeyHandlingProducesEngineDisplayAndSpokenResult: PASSED (0.001s).
- CanadianHamTests.ExamCalculatorViewModelTests.testOfficialReferenceSheetGateAndBundledPages: PASSED (0.001s).
- CanadianHamTests.ExamCalculatorViewModelTests.testQuestionCardFocusResetKeepsTextSelectionEnabled: PASSED (0.004s).
- CanadianHamTests.ExamCalculatorViewModelTests.testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet: PASSED (0.001s).
- CanadianHamTests.ExamCalculatorViewModelTests.testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately: PASSED (0.001s).
- CanadianHamTests.HintSessionStateTests.testApplyPracticeAnswerSubmitsAnsweredWithHelpToEngine: PASSED (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekEligibilityAllowsPracticeReviewLaterButNeverMockExamOrScoredImmediateAnswer: PASSED (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekEndsWhenPhoneFullyOpensOrCloses: PASSED (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekFastUnfoldThroughBandNeverPeeks: PASSED (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekLeavingToleranceDoesNotResetDismissalSuppression: PASSED (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekPresentationAppearanceAllowsCurrentResetToClearSuppression: PASSED (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekPresentationClosesPeekOpenedHintOnQuestionChangeAndRequiresFreshDwell: PASSED (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekPresentationDismissalSuppressesReopenUntilReset: PASSED (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekPresentationImmediateAnswerEndsEligibility: PASSED (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset: PASSED (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear: PASSED (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekPresentationStartsOnlyOnceUntilPostureReset: PASSED (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekRecheckPeeksWithoutNewSamples: PASSED (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekRequiresStableDwellInSlightOpenBand: PASSED (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekSlowCloseThroughBandNeverPeeks: PASSED (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek: PASSED (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekToleratesSmallJitterOnlyAfterPeekStarts: PASSED (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekUnavailableSampleDoesNotResetDismissalSuppression: PASSED (0.000s).
- CanadianHamTests.HintSessionStateTests.testHintQualificationMarksUnansweredQuestionAsQualifiedOnly: PASSED (0.001s).
- CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp: PASSED (0.392s).
- CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerDoesNotQualifyShortPeekRoute: PASSED (0.289s).
- CanadianHamTests.HintSessionStateTests.testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp: PASSED (0.002s).
- CanadianHamTests.HintSessionStateTests.testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable: PASSED (0.002s).
- CanadianHamTests.HintSessionStateTests.testReviewLaterHintAfterSelectionRecordsHelp: PASSED (0.002s).
- CanadianHamTests.HintSessionStateTests.testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission: PASSED (0.002s).
- CanadianHamTests.HintSessionStateTests.testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange: PASSED (2.533s).
- CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusFrenchAndFallbackLanguageMetadata: PASSED (0.004s).
- CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusLegacyChoiceAndNoDisclosureBeforeSelection: PASSED (0.003s).
- CanadianHamTests.LocalizationCatalogTests.testConceptCheckAnswerStatusMapsShuffledSourceChoices: PASSED (0.003s).
- CanadianHamTests.LocalizationCatalogTests.testConceptCheckFeedbackFocusRequestOnlyAfterChoosingNotPreviousOrNext: PASSED (0.002s).
- CanadianHamTests.LocalizationCatalogTests.testEveryCatalogKeyHasFrenchTranslations: PASSED (0.010s).
- CanadianHamTests.LocalizationCatalogTests.testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries: PASSED (0.005s).
- CanadianHamTests.LocalizationCatalogTests.testLanguagePreferenceResolvesSystemAndOverrides: PASSED (0.001s).
- CanadianHamTests.LocalizationCatalogTests.testLocalizedNullableTextAndLanguageFallsBackToEnglish: PASSED (0.001s).
- CanadianHamTests.LocalizationCatalogTests.testQuestionBankLoadErrorDescriptionUsesFrenchLocale: PASSED (0.004s).
- CanadianHamTests.LocalizationCatalogTests.testTryItDisclosureLabelsStatesAndAnnouncementsLocalizeToFrench: PASSED (0.001s).
- CanadianHamTests.MorseTrainerTests.testCompletedMorseCourseSessionIgnoresResubmittedAnswer: PASSED (0.001s).
- CanadianHamTests.MorseTrainerTests.testFixedTimingProfilesUseEngineValues: PASSED (0.001s).
- CanadianHamTests.MorseTrainerTests.testLessonBodyAndBulletContrastTokensMeetMinimumRatio: PASSED (0.001s).
- CanadianHamTests.MorseTrainerTests.testMorseAudioDriverSendingRestartDetachesStoppedSourceAndBalancesSession: PASSED (1.654s).
- CanadianHamTests.MorseTrainerTests.testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp: PASSED (0.001s).
- CanadianHamTests.MorseTrainerTests.testMorseAudioSessionStaysActiveUntilLastPlayerReleases: PASSED (0.001s).
- CanadianHamTests.MorseTrainerTests.testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins: PASSED (0.001s).
- CanadianHamTests.MorseTrainerTests.testMorseBeaconSafetyNoteUsesSquarePointsAndGroupedAreas: PASSED (0.002s).
- CanadianHamTests.MorseTrainerTests.testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters: PASSED (0.001s).
- CanadianHamTests.MorseTrainerTests.testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone: PASSED (0.002s).
- CanadianHamTests.MorseTrainerTests.testMorseCourseProgressIgnoresStoredProgressForAnotherCourse: PASSED (0.001s).
- CanadianHamTests.MorseTrainerTests.testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition: PASSED (0.001s).
- CanadianHamTests.MorseTrainerTests.testMorseExamGeneratorMeetsReceivingExamConstraints: PASSED (0.002s).
- CanadianHamTests.MorseTrainerTests.testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime: PASSED (0.001s).
- CanadianHamTests.MorseTrainerTests.testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying: PASSED (0.106s).
- CanadianHamTests.MorseTrainerTests.testMorseSendingClassifiesTimingAndErrorSignal: PASSED (0.002s).
- CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerClassifiesPressWhenAudioFails: PASSED (0.007s).
- CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerClassifiesRecordedEventsWhileAudioStartupIsSuspended: PASSED (0.004s).
- CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerLeavingDuringFailedPreparationDoesNotReportStaleError: PASSED (0.107s).
- CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerLeavingDuringPreparationDoesNotStartALateTone: PASSED (0.005s).
- CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerReleaseCannotBeSupersededBySilence: PASSED (0.002s).
- CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerReportsPreparationFailureAfterKeyUpAndClassifiesPress: PASSED (0.002s).
- CanadianHamTests.MorseTrainerTests.testMorseSendingKeyerSuccessfulPrepareDoesNotClearEarlierAudioError: PASSED (0.110s).
- CanadianHamTests.MorseTrainerTests.testMorseSendingPendingFinalizationHelperCancelsAndClears: PASSED (0.002s).
- CanadianHamTests.MorseTrainerTests.testMorseSendingRemainingExamSecondsUsesFixedDeadline: PASSED (0.001s).
- CanadianHamTests.MorseTrainerTests.testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters: PASSED (0.002s).
- CanadianHamTests.MorseTrainerTests.testMorseSettingsClampAndPreset: PASSED (0.002s).
- CanadianHamTests.MorseTrainerTests.testMorseSettingsCodableRoundTripPreservesOutputMode: PASSED (0.002s).
- CanadianHamTests.MorseTrainerTests.testMorseSettingsDecodesLegacyPayloadWithIsEnabled: PASSED (0.002s).
- CanadianHamTests.MorseTrainerTests.testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast: PASSED (0.008s).
- CanadianHamTests.MorseTrainerTests.testMorseSettingsRoundTripThroughUserDefaults: PASSED (0.003s).
- CanadianHamTests.MorseTrainerTests.testMorseStopDelayDrainsFadeBeforeStoppingEngine: PASSED (0.001s).
- CanadianHamTests.MorseTrainerTests.testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced: PASSED (0.001s).
- CanadianHamTests.MorseTrainerTests.testNativeSettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess: PASSED (0.042s).
- CanadianHamTests.MorseTrainerTests.testReduceFlashingDecisionUsesInjectedFlags: PASSED (0.001s).
- CanadianHamTests.MorseTrainerTests.testReduceFlashingStopsOnlyRunningVisualBeacon: PASSED (0.001s).
- CanadianHamTests.MorseTrainerTests.testScheduleMorseVisualPlaybackInitialStateAndFallback: PASSED (0.001s).
- CanadianHamTests.MorseTrainerTests.testStudySettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess: PASSED (0.036s).
- CanadianHamTests.ProgressStoreTests.testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress: PASSED (0.077s).
- CanadianHamTests.ProgressStoreTests.testAdvancedImportRejectsHonoursAttempts: PASSED (0.023s).
- CanadianHamTests.ProgressStoreTests.testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch: PASSED (0.004s).
- CanadianHamTests.ProgressStoreTests.testAppSettingsModelPublishesMorseSettingsForRootViewSync: PASSED (0.001s).
- CanadianHamTests.ProgressStoreTests.testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement: PASSED (0.001s).
- CanadianHamTests.ProgressStoreTests.testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows: PASSED (0.001s).
- CanadianHamTests.ProgressStoreTests.testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore: PASSED (0.022s).
- CanadianHamTests.ProgressStoreTests.testDecodesLegacyBasicExportWithoutBankIdFields: PASSED (0.029s).
- CanadianHamTests.ProgressStoreTests.testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme: PASSED (0.028s).
- CanadianHamTests.ProgressStoreTests.testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker: PASSED (0.019s).
- CanadianHamTests.ProgressStoreTests.testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt: PASSED (0.057s).
- CanadianHamTests.ProgressStoreTests.testFreshInstallDefaultsLanguageToSystem: PASSED (0.009s).
- CanadianHamTests.ProgressStoreTests.testICloudAccountSignalsUseInitInjectedFactory: PASSED (0.062s).
- CanadianHamTests.ProgressStoreTests.testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot: PASSED (0.026s).
- CanadianHamTests.ProgressStoreTests.testICloudDeleteCanDeleteLocalDataAfterZoneDelete: PASSED (0.024s).
- CanadianHamTests.ProgressStoreTests.testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload: PASSED (0.034s).
- CanadianHamTests.ProgressStoreTests.testICloudMergeFixtureIsPermutationIndependentAndIdempotent: PASSED (0.002s).
- CanadianHamTests.ProgressStoreTests.testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal: PASSED (0.001s).
- CanadianHamTests.ProgressStoreTests.testICloudSyncToggleAndAccountSignalsPreserveLocalProgress: PASSED (0.046s).
- CanadianHamTests.ProgressStoreTests.testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing: PASSED (0.033s).
- CanadianHamTests.ProgressStoreTests.testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields: PASSED (0.035s).
- CanadianHamTests.ProgressStoreTests.testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount: PASSED (0.046s).
- CanadianHamTests.ProgressStoreTests.testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons: PASSED (0.063s).
- CanadianHamTests.ProgressStoreTests.testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange: PASSED (0.033s).
- CanadianHamTests.ProgressStoreTests.testImportLeavesTask4610Version2LessonSplitRowsUnchanged: PASSED (0.036s).
- CanadianHamTests.ProgressStoreTests.testImportMigratesMixedTask4610SyncRowsByRowVersion: PASSED (0.038s).
- CanadianHamTests.ProgressStoreTests.testImportMigratesTask4610LessonSplitProgressAndQuizAttempts: PASSED (0.039s).
- CanadianHamTests.ProgressStoreTests.testImportOfOlderExportDoesNotRemoveExistingMorseProgress: PASSED (0.032s).
- CanadianHamTests.ProgressStoreTests.testImportRejectsInvalidSyncDeviceRows: PASSED (0.041s).
- CanadianHamTests.ProgressStoreTests.testImportRejectsUnsupportedLanguagePreferenceValues: PASSED (0.037s).
- CanadianHamTests.ProgressStoreTests.testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses: PASSED (0.070s).
- CanadianHamTests.ProgressStoreTests.testImportRollbackKeepsExistingDataWhenReplacementFails: PASSED (0.043s).
- CanadianHamTests.ProgressStoreTests.testImportRollbackPropagatesMorseProgressRemovalFailure: PASSED (0.032s).
- CanadianHamTests.ProgressStoreTests.testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress: PASSED (0.033s).
- CanadianHamTests.ProgressStoreTests.testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt: PASSED (0.035s).
- CanadianHamTests.ProgressStoreTests.testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues: PASSED (0.001s).
- CanadianHamTests.ProgressStoreTests.testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates: PASSED (0.038s).
- CanadianHamTests.ProgressStoreTests.testImportValidationRejectsDuplicateMorseDailyActivityDates: PASSED (0.037s).
- CanadianHamTests.ProgressStoreTests.testImportValidationRejectsInvalidMorseCourseProgress: PASSED (0.037s).
- CanadianHamTests.ProgressStoreTests.testImportValidationRejectsMismatchedScoreBankId: PASSED (0.038s).
- CanadianHamTests.ProgressStoreTests.testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt: PASSED (0.033s).
- CanadianHamTests.ProgressStoreTests.testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges: PASSED (0.031s).
- CanadianHamTests.ProgressStoreTests.testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults: PASSED (0.037s).
- CanadianHamTests.ProgressStoreTests.testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference: PASSED (0.010s).
- CanadianHamTests.ProgressStoreTests.testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault: PASSED (0.013s).
- CanadianHamTests.ProgressStoreTests.testLaunchIgnoresRegisteredAppleLanguagesValue: PASSED (0.009s).
- CanadianHamTests.ProgressStoreTests.testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue: PASSED (0.009s).
- CanadianHamTests.ProgressStoreTests.testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries: PASSED (0.011s).
- CanadianHamTests.ProgressStoreTests.testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun: PASSED (0.013s).
- CanadianHamTests.ProgressStoreTests.testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting: PASSED (0.010s).
- CanadianHamTests.ProgressStoreTests.testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce: PASSED (0.009s).
- CanadianHamTests.ProgressStoreTests.testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure: PASSED (0.030s).
- CanadianHamTests.ProgressStoreTests.testLessonQuizHelpFixtureValidationAndPayloadRoundTrips: PASSED (0.134s).
- CanadianHamTests.ProgressStoreTests.testLessonQuizHelpValidationUsesOfficialMembershipAndKnownBankIdsNotBasicPrefix: PASSED (0.030s).
- CanadianHamTests.ProgressStoreTests.testLessonQuizHintVisibilityUsesHalfSecondAndFreezesHelpAtChoice: PASSED (2.744s).
- CanadianHamTests.ProgressStoreTests.testLessonQuizSessionCachePreservesAnswersAndFrozenHelpAcrossNavigation: PASSED (0.004s).
- CanadianHamTests.ProgressStoreTests.testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead: PASSED (0.066s).
- CanadianHamTests.ProgressStoreTests.testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution: PASSED (0.050s).
- CanadianHamTests.ProgressStoreTests.testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution: PASSED (0.035s).
- CanadianHamTests.ProgressStoreTests.testM1QuizRoundBoundariesPreserveOneSessionAnswersHelpAndDismissedCheckpoint: PASSED (0.559s).
- CanadianHamTests.ProgressStoreTests.testM1QuizRoundsRetainEveryItemAndSeededOrderWithinTeachingSections: PASSED (0.534s).
- CanadianHamTests.ProgressStoreTests.testMigratesArchivedLessonProgressKeepsMaxOwnReadCount: PASSED (0.011s).
- CanadianHamTests.ProgressStoreTests.testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist: PASSED (0.032s).
- CanadianHamTests.ProgressStoreTests.testMigratesCommittedPreV2StoreFixtureWithAllDataIntact: PASSED (0.374s).
- CanadianHamTests.ProgressStoreTests.testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity: PASSED (0.023s).
- CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV1ToV2WithoutUniqueConstraints: PASSED (0.070s).
- CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields: PASSED (0.076s).
- CanadianHamTests.ProgressStoreTests.testMockExamTimerRefreshPreservesFractionalRemainder: PASSED (0.001s).
- CanadianHamTests.ProgressStoreTests.testMorseCourseProgressRoundTripsTwentyRecentCharacterResults: PASSED (0.029s).
- CanadianHamTests.ProgressStoreTests.testMorseExportMapsHapticsToWebCompatibleAudio: PASSED (0.001s).
- CanadianHamTests.ProgressStoreTests.testMorseImportDecodesMissingAndPartialMorsePreferences: PASSED (0.050s).
- CanadianHamTests.ProgressStoreTests.testMorseImportRejectsExplicitNullMorseValues: PASSED (0.001s).
- CanadianHamTests.ProgressStoreTests.testMorseImportRejectsUnsupportedMorsePreferenceEnums: PASSED (0.035s).
- CanadianHamTests.ProgressStoreTests.testMountedLessonQuizRepopulatesAfterImportAndResetWithoutReshufflingOnRerender: PASSED (0.920s).
- CanadianHamTests.ProgressStoreTests.testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference: PASSED (0.016s).
- CanadianHamTests.ProgressStoreTests.testNativeSettingsGeneralBindingsUpdatePracticePreferences: PASSED (0.010s).
- CanadianHamTests.ProgressStoreTests.testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows: PASSED (0.036s).
- CanadianHamTests.ProgressStoreTests.testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt: PASSED (0.010s).
- CanadianHamTests.ProgressStoreTests.testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences: PASSED (0.040s).
- CanadianHamTests.ProgressStoreTests.testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse: PASSED (0.034s).
- CanadianHamTests.ProgressStoreTests.testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints: PASSED (0.037s).
- CanadianHamTests.ProgressStoreTests.testProgressStoreRoundTripExportImportReset: PASSED (0.054s).
- CanadianHamTests.ProgressStoreTests.testQuizRoundsWithConceptChecksKeepTheCompleteUngroupedOrder: PASSED (0.527s).
- CanadianHamTests.ProgressStoreTests.testResetAllDataTurnsICloudSyncOptInOff: PASSED (0.013s).
- CanadianHamTests.ProgressStoreTests.testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData: PASSED (0.025s).
- CanadianHamTests.ProgressStoreTests.testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure: PASSED (0.044s).
- CanadianHamTests.ProgressStoreTests.testResetClearsAppleLanguagesAndLanguagePreference: PASSED (0.013s).
- CanadianHamTests.ProgressStoreTests.testResetFailureKeepsPreviousAppleLanguagesAndPreference: PASSED (0.013s).
- CanadianHamTests.ProgressStoreTests.testResetRollsBackWhenMorseProgressRemovalFails: PASSED (0.014s).
- CanadianHamTests.ProgressStoreTests.testSavingLargeQuestionProgressBatchBuildsOneWriteContext: PASSED (1.703s).
- CanadianHamTests.ProgressStoreTests.testSharedAppleSettingsModelAppliesLivePreferenceUpdates: PASSED (0.016s).
- CanadianHamTests.ProgressStoreTests.testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules: PASSED (0.001s).
- CanadianHamTests.ProgressStoreTests.testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries: PASSED (0.006s).
- CanadianHamTests.ProgressStoreTests.testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress: PASSED (0.104s).
- CanadianHamTests.ProgressStoreTests.testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists: PASSED (0.064s).
- CanadianHamTests.ProgressStoreTests.testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite: PASSED (0.030s).
- CanadianHamTests.ProgressStoreTests.testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration: PASSED (0.010s).
- CanadianHamTests.ProgressStoreTests.testTask4610LaunchMigrationIsAtomicAndStableWithArchivedProgressAndMultipleDevices: PASSED (0.043s).
- CanadianHamTests.ProgressStoreTests.testTask4610LessonMigrationIsIdempotentAcrossRepeatedImports: PASSED (0.038s).
- CanadianHamTests.ProgressStoreTests.testTask4610RejectsInvalidLegacyQuizScoresBeforeMigration: PASSED (0.028s).
- CanadianHamTests.ProgressStoreTests.testTask4610RejectsNullLessonIDVersionAtTopLevelAndOnBothDeviceRowKinds: PASSED (0.028s).
- CanadianHamTests.ProgressStoreTests.testTask4610RequiresAllReadSourcesAndMergesEachDeviceBeforeAggregating: PASSED (0.097s).
- CanadianHamTests.ProgressStoreTests.testTask4610SharedConceptMappingAndConceptInclusiveScores: PASSED (0.232s).
- CanadianHamTests.ProgressStoreTests.testTask4610ValidatesHistoricalQuizMembershipBeforeMigratingTopLevelAndSyncRows: PASSED (0.039s).
- CanadianHamTests.ProgressStoreTests.testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync: PASSED (0.062s).
- CanadianHamTests.QuestionBankTests.testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames: PASSED (0.012s).
- CanadianHamTests.QuestionBankTests.testAdvancedMockExamUsesFiftyQuestionsAndNoHonours: PASSED (0.013s).
- CanadianHamTests.QuestionBankTests.testAppBundleContainsNoReadmeFiles: PASSED (0.013s).
- CanadianHamTests.QuestionBankTests.testAppBundleContainsOnlyExpectedGeneratedBankDirectories: PASSED (0.001s).
- CanadianHamTests.QuestionBankTests.testBundledJSONDecodesExpectedCounts: PASSED (0.019s).
- CanadianHamTests.QuestionBankTests.testBundledLessonModelExposesPrerequisites: PASSED (0.553s).
- CanadianHamTests.QuestionBankTests.testBundledLessonsAndExplanationsLoadThroughContentLibrary: PASSED (0.735s).
- CanadianHamTests.QuestionBankTests.testEngineQuestionDrawKeepsQuestionInsideRequestedCategory: PASSED (0.019s).
- CanadianHamTests.QuestionBankTests.testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion: PASSED (0.082s).
- CanadianHamTests.QuestionBankTests.testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes: PASSED (0.001s).
- CanadianHamTests.QuestionBankTests.testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons: PASSED (0.561s).
- CanadianHamTests.ReadinessAndScoringTests.testAdvancedScoringAndReadinessSuppressHonours: PASSED (0.001s).
- CanadianHamTests.ReadinessAndScoringTests.testExamScoringBoundaries: PASSED (0.001s).
- CanadianHamTests.ReadinessAndScoringTests.testReadinessStates: PASSED (0.001s).
- CanadianHamTests.ReadinessAndScoringTests.testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate: PASSED (0.034s).
- CanadianHamTests.RootNavigationMappingTests.testCompactHomeSessionAndSectionPushesUseVisibleDestination: PASSED (0.001s).
- CanadianHamTests.RootNavigationMappingTests.testEmptyCompactPathMapsToHome: PASSED (0.001s).
- CanadianHamTests.RootNavigationMappingTests.testEveryLearnRouteRoundTripsWithItsWholeStack: PASSED (0.001s).
- CanadianHamTests.RootNavigationMappingTests.testEveryRootSelectionRoundTrips: PASSED (0.001s).
- CanadianHamTests.RootNavigationMappingTests.testLessonQuizCurrentAndOtherHintLessonStacksPreserveQuizAcrossLayouts: PASSED (0.001s).
- CanadianHamTests.RootNavigationMappingTests.testPracticeHintLessonStackKeepsSessionAsSplitSelection: PASSED (0.001s).

Commands (initial combined reference commands retain their historical failed-new-test attempts, superseded by the final new-test passes above):
- DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testMockExamOfficialReferenceSheetLightPreservesRunningExam -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testMockExamOfficialReferenceSheetDarkPreservesPausedExam -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testAdvancedMockExamHasNoBasicReferenceSheetOrHints -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testMockExamDoesNotShowCorrectnessBeforeSubmit -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testRegularWidthMockExamResultPersistsAfterSubmit -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testSettingsResetClearsSavedMockExamProgress -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testMockExamHeaderControlsSupportLargestAccessibilityTextSize -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditMockExamFlowLight -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditMockExamFlowDark test CODE_SIGNING_ALLOWED=NO
- DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testMockExamOfficialReferenceSheetLightPreservesRunningExam -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testMockExamOfficialReferenceSheetDarkPreservesPausedExam -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testAdvancedMockExamHasNoBasicReferenceSheetOrHints test CODE_SIGNING_ALLOWED=NO
- DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=macOS,arch=arm64' -skip-testing:CanadianHamUITests test SDKROOT=macosx SUPPORTED_PLATFORMS=macosx CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES
- DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testMockExamOfficialReferenceSheetLightPreservesRunningExam -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testMockExamOfficialReferenceSheetDarkPreservesPausedExam -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testAdvancedMockExamHasNoBasicReferenceSheetOrHints -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testReferenceSheetToolAvailableOnlyForBasic -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testOfficialReferenceSheetLightAndDarkEnglishAndFrench -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testReferenceSheetLargestDynamicTypeKeepsControlsReachable -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testOfficialReferenceSheetMediumDetentControlsAndShowFullSheet test CODE_SIGNING_ALLOWED=NO
- DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testMockExamOfficialReferenceSheetLightPreservesRunningExam -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testMockExamOfficialReferenceSheetDarkPreservesPausedExam -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testAdvancedMockExamHasNoBasicReferenceSheetOrHints -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testReferenceSheetToolAvailableOnlyForBasic -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testOfficialReferenceSheetLightAndDarkEnglishAndFrench -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testReferenceSheetLargestDynamicTypeKeepsControlsReachable -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/testOfficialReferenceSheetMediumDetentControlsAndShowFullSheet test CODE_SIGNING_ALLOWED=NO
- pnpm check:apple-l10n
- node scripts/check-apple-text-sources.ts
- node scripts/check-test-guard.mjs --self-test
- TEST_GUARD_PR_BODY='Test-guard-approved: owner decision 2026-10-24' node scripts/check-test-guard.mjs --base 65c5bd500e6d010c05faf79793dd83a1e0aba889 --head HEAD
- git diff 65c5bd500e6d010c05faf79793dd83a1e0aba889 --check
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added three mock-exam UI tests covering all five official pages/back navigation, zoom, accessible formula text and Study fallback; preserves current question, selected answer, exam seed/progress and running/paused timer state; rejects Basic sheet in Advanced and hints in all mocks. Every existing test/helper and app source remains byte-for-byte baseline. Superseding coordinator decision 2026-10-24 is documented in AGENTS: iPhone keeps full-default light/dark audits; new iPad mock tests keep every behaviour assertion without full audits, with unresolved caption/nil-textClipped/legacy compact-Questions work consolidated in TASK-74. Final iPhone 9/9, iPad new 3/3, existing reference checks (iPhone 4 pass, iPad 3 pass + existing medium skip), documented macOS 218/218 plus UI-test compilation, localization/text/approved guard and unchanged-source proof pass. Per-test results, earlier failures, screenshots and exact commands are in notes. No full simulator suites, PR or upload; independent review and eventual owner-decision-2026-10-24 guard marker required.
<!-- SECTION:FINAL_SUMMARY:END -->
