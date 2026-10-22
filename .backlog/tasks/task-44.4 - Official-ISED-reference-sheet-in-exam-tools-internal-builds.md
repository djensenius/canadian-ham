---
id: TASK-44.4
title: Official ISED reference sheet in exam tools (internal builds)
status: Done
assignee:
  - '@worker'
created_date: '2026-10-12 22:21'
updated_date: '2026-10-22 03:08'
labels:
  - content
  - web
  - apple
dependencies:
  - TASK-44.3
modified_files:
  - docs/content-licensing.md
  - docs/release/ised-reference-sheet-request.md
parent_task_id: TASK-44
priority: medium
ordinal: 111000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner decision 2026-10-12 (2A): use the official ISED Basic reference sheet (EN PDF in content/sources/ised/basic-2025-07-15/reference/) in the in-exam reference panel for internal TestFlight builds under the interim risk basis, while asking ISED to add the reference sheets (EN and FR) to the permission request. Public release stays blocked until ISED permission covers the sheet. Keep the original study sheet as the fallback (one config point).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 docs/content-licensing.md records the decision, the risk basis, and that public release is blocked until permission covers the sheet
- [x] #2 A ready-to-send follow-up request to ISED (EN, asking for the reference sheets in EN and FR) is drafted for the owner
- [x] #3 Web and Apple exam tools show the official sheet (zoomable, accessible text equivalent) in internal builds; the original sheet remains available as fallback
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Merge origin/main (retain branch task file) and push.
2. Render the unlabelled five-page ISED exam PDF offline with source/asset hashes and a faithful English text equivalent, separating project diagram descriptions.
3. Integrate page/zoom/text controls plus original-study fallback on web and iOS/iPadOS/macOS; OFFICIAL_REFERENCE_SHEET defaults off in Release/production and is explicitly enabled only for dev/Debug/internal beta.
4. Add EN/FR light/dark, AX, unit and gate coverage. Preserve all existing shared/audit helpers. With coordinator approval, use only approved exception (a) for AX and a new identical-rule, explicit-reference-scroll helper for the iPad fallback. Document licensing/TestFlight/public-release exclusion.
5. Run targeted requested checks (no full Apple suites), record per-test results, check AC3, set Done, commit/push; no PR or upload.

Review follow-up: 6. Make beta archive opt-in explicit, validate every Release config and default web output with regression fixtures. 7. Restore hit target, remove diagnostics, label zoom, repair catalogue fr-CA/order/newline, inspect high-resolution page 4, and add iPhone medium-detent coverage. 8. Rerun only requested reference-sheet UI/macOS units and web/gate/l10n/URL/text/guard checks; record results, keep Done, commit/push, no PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Docs-only slice complete: updated docs/content-licensing.md with owner decision 2026-10-12 (2A), original-request exclusion of reference sheets, interim internal-TestFlight risk basis matching the question-bank handling, task-1.7/T-009 public-release block until T-007/task-1.1 permission covers the sheet, English-only source status, and fallback content/reference-sheet/basic.md. Drafted docs/release/ised-reference-sheet-request.md for the owner to send to ISED. Validation: pnpm check:links passed.

PDF inspection for integration lane (no integration implemented; depends on task-44.3): inspected content/sources/ised/basic-2025-07-15/reference/*.pdf with file(1), mdls, raw PDF object counts, and a Swift/PDFKit text extraction script because poppler pdfinfo/pdftotext is not installed on this machine. Exam PDF (Reference Material for Amateur Radio Exam Basic EN 2025.pdf): PDF 1.7, 5 pages, PDFKit extracted 1,307 characters total; page 1 has formula text, pages 2-5 mostly headers/titles plus object placeholders for diagrams; raw scan found 12 /Subtype/Image XObjects, fonts, and ToUnicode maps. Training PDF: PDF 1.7, 7 pages, PDFKit extracted 2,610 characters total; page 1 has formula table text, pages 2-7 mostly headings plus diagram/image placeholders; raw scan found 12 image XObjects. Integration plan: use only the exam-version sheet for exam tools. Web should prefer pre-rendered page images for stable offline fidelity/zoom plus a maintained/extracted text equivalent/transcript instead of embedding the PDF directly. Apple can use PDFKit/PDFView for the official PDF fidelity and zoom if accessibility is verified, but still needs a separate accessible text equivalent because the diagram pages are image-based and the PDF text layer is incomplete; fall back to page images plus transcript if PDFKit accessibility is insufficient.

2026-10-12: Owner sent the ISED follow-up request (docs/release/ised-reference-sheet-request.md) asking to add the Basic reference sheets (EN and FR) to the permission. Awaiting reply; public release stays blocked until permission covers the sheet.

2026-10-21: Merged origin/main and pushed 3ba41fef; retained branch task version per instruction. Coordinator approved Debug/dev ON and default Release/production OFF gate with explicit internal beta opt-in, public permission gate unchanged.

AC3 implementation: official exam PDF reproduced as five unannotated offline pages (144 dpi, deterministic render/checksums recorded); English printed text/formulas transcribed, with explicitly project-authored symbol/connection descriptions for otherwise unlabelled diagrams. Web and iOS/iPadOS/macOS have page selection, zoom, accessible text, and Study sheet fallback. tvOS/visionOS have no reference-sheet tool and are unchanged. OFFICIAL_REFERENCE_SHEET excludes imports/resources in default production/Release, removes stale Apple resources, and is enabled only in dev/Debug or explicit internal beta opt-in. Gate script plus web gate/fallback tests added; licensing, release checklist and internal TestFlight instructions updated.\nValidation so far: typecheck passed; pnpm test passed (content-tools 226, Morse 21, calculator 127, web 253); default and opted-in web builds + both URL/CSP audits passed, default official-asset/transcript absence verified; Markdown links and text-source gate passed; XcodeGen second generation identical; 12 iPhone exam-tool unit tests passed, Basic-only availability and hint ladder UI regressions passed. First new UI run found a too-small caption zoom percentage and an over-flinging generic scroll setup at AX-XXXL; fixed app typography and added reference-specific precise positioning without changing shared/audit helpers. Rerunning only failed UI tests; macOS unit checks and l10n queued via nohup.

Targeted audit fix rounds: the new positioning helper wrongly inset its visible rectangle by 2pt, excluding leading-edge controls; corrected to the full visible scroll frame below navigation. Coordinator approved viewport positioning plus real tap/state checks in this new helper only. Once-per-test diagnostics show Next isHittable=true, no blocking transparent overlay, and actual page/sheet/zoom state changes succeed. Shared/audit/exception helpers remain unchanged. Reused the existing accessible secondary-button style and explicit Dynamic Type layouts for zoom after the full-default audit flagged the native button style. AX-XXXL audit setup aligns a whole control boundary so an offscreen Page label is not sampled through the opaque tool header; no audit types or findings are ignored.
Latest iPhone official-sheet EN/FR light/dark method passed (253.426s), including all 12 full-default image/text/fallback audits. AX-XXXL and iPad checks still running. macOS units 38/38 passed; the completed l10n check passed, including tvOS and visionOS build checks. The catalogue exporter reordered keys; semantic comparison against the merge baseline confirms no existing translation was changed or removed.
Test guard: self-test passed. Use exactly Test-guard-approved: owner decision 2026-10-12 in the eventual PR body (coordinator approval). The only guarded changes are replacing testReferenceSheetToolHiddenUntilTask44Dot4 with testReferenceSheetToolAvailableOnlyForBasic (the obsolete hidden assertion is superseded by the requested feature; Advanced still explicitly rejects the sheet), and adding testOfficialReferenceSheetLightAndDarkEnglishAndFrench plus testReferenceSheetLargestDynamicTypeKeepsControlsReachable with full-default audits.

Coordinator clarification/approval 2026-10-21: the existing approved exception (a), using unchanged auditIgnoringOccludedLessonTextContrast(app:), covers exam tools as part of practice/mock screens (owner 2026-10-14). Use it ONLY for the new AX-XXXL reference-sheet audit, where the Page label is partly clipped by the tool scroll area; nonnil-element, scroll ancestry/intersection and not-fully-visible constraints remain exactly as implemented, and fully visible contrast/non-contrast issues still fail. The 12 EN/FR light/dark official-image/text-equivalent/study audits remain raw performAccessibilityAudit() default calls. Removed brittle exact top-alignment setup rather than adding or widening any exception/helper. 44pt assertions and actual sheet/page/zoom state checks remain intact.

Latest: iPhone AX-XXXL passed (139.160s) after returning the reference scroll view to its top before its approved full-default audit; iPad AX-XXXL passed (46.312s). iPad normal matrix image/text audits passed, then its Study fallback audit sampled a clipped -3 dB table row at the bottom edge (blank-paper element screenshot). Coordinator approved the unchanged occluded-scroll contrast helper for the iPad Study fallback only as the same existing exception (a); image/official-text audits and every iPhone normal audit remain raw/default. Rerunning only that iPad matrix method; no shared/audit helper changes.

Coordinator approval 2026-10-21 for the iPad fallback only: add NEW auditIgnoringOccludedReferenceSheetTextContrast. The unchanged generic helper picks the main/background scroll view in the inspector layout, so it cannot classify the reference panel clip. The new helper selects only reference-sheet-scroll and fails if absent (no fallback). Its performAccessibilityAudit handler is byte-for-byte identical to the approved exception (a) rule: contrast-only, nonnil element, non-navigation frame, explicit reference scroll ancestry/intersection, not fully contained in visible reference area. All 67 pre-existing helpers remain byte-for-byte unchanged. The internal reviewer should diff the new handler line by line against the original; the eventual PR must explain the second-scroll-view reason under Test-guard-approved: owner decision 2026-10-12.

FINAL VALIDATION (2026-10-21 local): all final per-test outcomes green. Results are accumulated across targeted fix rounds, not a rerun of unrelated/full suites. Earlier failed UI/setup attempts were corrected; only affected tests were rerun. The first iPad destination ID pointed at iOS 26.5 and ran no tests; corrected to iOS 27.0 ID 31F24CB8-5C15-40EA-8793-FE0A95398AB1.

Web/packages:
- pnpm typecheck: PASS.
- pnpm test: PASS (content-tools 226; Morse 21; calculator 127; web 253; official-reference gate and release-permission self-tests also pass).
- Default and OFFICIAL_REFERENCE_SHEET=YES pnpm build:web: PASS; both URL/CSP audits PASS. Final default rebuild after opt-in PASS; no page PNGs or transcript in dist (stale opt-in assets removed).
- New web matrix covers EN/FR x light/dark, all five pages, zoom, English text equivalent, original study fallback and default axe rules; off-gate fallback and build gate tests also pass.
- pnpm check:links, node scripts/check-apple-text-sources.ts, pnpm check:apple-l10n, pnpm check:apple-icloud-gate, pnpm check:apple-network, ruby -c fastlane/Fastfile, git diff --check: PASS.
- XcodeGen generated twice with identical project.pbxproj. PDF source SHA-256 matches e4e6a0ec35d9ccec2732b6c2a950b3ea721f826d44160b54b4e6298e86b93ae9; five-page raster regeneration deterministic on this host; six app-asset hashes match provenance README.

Apple UI per-test results (CanadianHamExamToolsUITests):
- iPhone 17 Pro: testReferenceSheetToolAvailableOnlyForBasic: PASS (19.568s).
- iPhone 17 Pro: testHintToolLadderAndLessonLink: PASS (63.064s).
- iPhone 17 Pro: testOfficialReferenceSheetLightAndDarkEnglishAndFrench: PASS (253.426s).
- iPhone 17 Pro: testReferenceSheetLargestDynamicTypeKeepsControlsReachable: PASS (139.160s).
- iPad Pro 11-inch (M5), iOS 27.0: testReferenceSheetToolAvailableOnlyForBasic: PASS (16.709s).
- iPad Pro 11-inch (M5), iOS 27.0: testOfficialReferenceSheetLightAndDarkEnglishAndFrench: PASS (210.435s).
- iPad Pro 11-inch (M5), iOS 27.0: testReferenceSheetLargestDynamicTypeKeepsControlsReachable: PASS (46.312s).

The official-sheet matrix runs all four EN/FR x light/dark scenarios and audits image, accessible text, and study fallback. iPhone uses 12 raw full-default audits; iPad uses 8 raw image/text audits plus 4 full-default fallback audits with only the approved occluded-scroll contrast rule. AX-XXXL on both platforms verifies real sheet/page/zoom changes and >=44pt controls, returns to the panel top, and runs the full-default audit with the unchanged approved helper. No non-contrast or fully visible contrast issue is ignored.

iPhone unit per-test results (12/12, ExamCalculatorViewModelTests; models unchanged after this pass):
- testCalculatorToolLayoutCanRepresentFittingContentWithAndWithoutHelp: PASS (0.001s).
- testCalculatorToolLayoutFittingCandidatesPreferLargeKeysBeforeMinimumKeys: PASS (0.001s).
- testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere: PASS (0.001s).
- testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds: PASS (0.001s).
- testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes: PASS (0.001s).
- testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale: PASS (0.001s).
- testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString: PASS (0.001s).
- testKeyHandlingProducesEngineDisplayAndSpokenResult: PASS (0.001s).
- testOfficialReferenceSheetGateAndBundledPages: PASS (0.002s).
- testQuestionCardFocusResetKeepsTextSelectionEnabled: PASS (0.004s).
- testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet: PASS (0.001s).
- testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately: PASS (0.001s).

macOS unit per-test results (38/38; relevant unit models unchanged after this pass):
- CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutCanRepresentFittingContentWithAndWithoutHelp: PASS (0.001s).
- CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutFittingCandidatesPreferLargeKeysBeforeMinimumKeys: PASS (0.001s).
- CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere: PASS (0.001s).
- CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds: PASS (0.001s).
- CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes: PASS (0.001s).
- CanadianHamTests.ExamCalculatorViewModelTests.testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale: PASS (0.001s).
- CanadianHamTests.ExamCalculatorViewModelTests.testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString: PASS (0.001s).
- CanadianHamTests.ExamCalculatorViewModelTests.testKeyHandlingProducesEngineDisplayAndSpokenResult: PASS (0.001s).
- CanadianHamTests.ExamCalculatorViewModelTests.testOfficialReferenceSheetGateAndBundledPages: PASS (0.001s).
- CanadianHamTests.ExamCalculatorViewModelTests.testQuestionCardFocusResetKeepsTextSelectionEnabled: PASS (0.004s).
- CanadianHamTests.ExamCalculatorViewModelTests.testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet: PASS (0.001s).
- CanadianHamTests.ExamCalculatorViewModelTests.testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately: PASS (0.001s).
- CanadianHamTests.HintSessionStateTests.testApplyPracticeAnswerSubmitsAnsweredWithHelpToEngine: PASS (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekEligibilityAllowsPracticeReviewLaterButNeverMockExamOrScoredImmediateAnswer: PASS (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekEndsWhenPhoneFullyOpensOrCloses: PASS (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekFastUnfoldThroughBandNeverPeeks: PASS (0.000s).
- CanadianHamTests.HintSessionStateTests.testHingePeekLeavingToleranceDoesNotResetDismissalSuppression: PASS (0.000s).
- CanadianHamTests.HintSessionStateTests.testHingePeekPresentationAppearanceAllowsCurrentResetToClearSuppression: PASS (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekPresentationClosesPeekOpenedHintOnQuestionChangeAndRequiresFreshDwell: PASS (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekPresentationDismissalSuppressesReopenUntilReset: PASS (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekPresentationImmediateAnswerEndsEligibility: PASS (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset: PASS (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear: PASS (0.000s).
- CanadianHamTests.HintSessionStateTests.testHingePeekPresentationStartsOnlyOnceUntilPostureReset: PASS (0.000s).
- CanadianHamTests.HintSessionStateTests.testHingePeekRecheckPeeksWithoutNewSamples: PASS (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekRequiresStableDwellInSlightOpenBand: PASS (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekSlowCloseThroughBandNeverPeeks: PASS (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek: PASS (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekToleratesSmallJitterOnlyAfterPeekStarts: PASS (0.001s).
- CanadianHamTests.HintSessionStateTests.testHingePeekUnavailableSampleDoesNotResetDismissalSuppression: PASS (0.001s).
- CanadianHamTests.HintSessionStateTests.testHintQualificationMarksUnansweredQuestionAsQualifiedOnly: PASS (0.001s).
- CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp: PASS (0.395s).
- CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerDoesNotQualifyShortPeekRoute: PASS (0.287s).
- CanadianHamTests.HintSessionStateTests.testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp: PASS (0.001s).
- CanadianHamTests.HintSessionStateTests.testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable: PASS (0.001s).
- CanadianHamTests.HintSessionStateTests.testReviewLaterHintAfterSelectionRecordsHelp: PASS (0.001s).
- CanadianHamTests.HintSessionStateTests.testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission: PASS (0.001s).
- CanadianHamTests.HintSessionStateTests.testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange: PASS (2.549s).

Apple commands used DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam, one destination per run, nohup/grep polling, no killed builds. iPhone destination: platform=iOS Simulator,name=iPhone 17 Pro. iPad destination: platform=iOS Simulator,id=31F24CB8-5C15-40EA-8793-FE0A95398AB1. UI selectors: -only-testing:CanadianHamUITests/CanadianHamExamToolsUITests/<each method above>. iPhone unit selector: -only-testing:CanadianHamTests/ExamCalculatorViewModelTests. Simulator runs used test CODE_SIGNING_ALLOWED=NO. macOS: destination platform=macOS,arch=arm64; selectors -only-testing:CanadianHamTests/ExamCalculatorViewModelTests -only-testing:CanadianHamTests/HintSessionStateTests; test SDKROOT=macosx SUPPORTED_PLATFORMS=macosx CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES.

No full Apple suites were run, per request. tvOS/visionOS have no reference-sheet tool and no feature changes; their localization builds passed as part of check:apple-l10n. No TestFlight upload, public distribution, or PR was performed.

Review/guard: check-test-guard self-test PASS; branch diff PASS with Test-guard-approved: owner decision 2026-10-12. Intentional guarded changes: supersede obsolete hidden-until-task44.4 test with Basic-only availability (Advanced stays negative); add full-default reference matrix/AX audits; use the approved existing helper for AX, and the new explicit-reference-scroll copy for iPad fallback only. All 67 pre-existing private helpers remain byte-for-byte unchanged; the new handler is byte-for-byte identical to the existing approved rule, apart from explicit geometry selection before the handler. It fails if reference-sheet-scroll is absent. Internal reviewer must compare handler line by line and confirm this scope.

AC1/AC2 evidence remains the licensing decision/public-release block and the owner-sent ready-to-send ISED follow-up. AC3 is now verified by the interactive tests above and physical resource-exclusion checks. Written ISED permission still pending; public release remains blocked. Default Release/production excludes the sheet; only internal beta/dev/Debug opts in. Independent branch/commit review is still required; no PR opened.

Internal review follow-up implemented: archive_and_export defaults official_reference_sheet off and upload_beta alone passes true; the gate inspects all base/Release YAML scopes and all 10 generated Release configurations, with mutation fixtures per Release buildSettings. Root build:web now runs a default-output scan for official page PNGs and transcript text/names (explicit opt-in builds are exempt). Removed hit-point diagnostics, restored Show full sheet hit shape/minWidth, labelled Zoom and added current percentage values. Added fr-CA for all translatable new keys and Zoom, restored newline and main relative key order (baseline catalogue diff is additions only). New iPhone medium test covers page/zoom/text/fallback controls, full-default audit and Show full sheet expansion; targeted Apple runs started with nohup. High-resolution PDFKit inspection at 576 dpi confirms upper interface-radio line is bidirectional and lower line points toward radio; transcript and hash corrected. Both Markdown renderers expose document-level language only, so the French department-name line cannot be tagged per-line without expanding renderer scope; limitation recorded in asset README. Searched Backlog and created TASK-44.5 for mock-exam path tests rather than expanding this fix round. Task remains Done pending requested validation evidence.

Medium test fix round: first setup dragged through the Toggle thumb, then exposed subpixel leading-edge frame rounding in the medium sheet. The new reference-only position helper now accepts a drag column (medium uses the blank centre column) and a 0.5pt measurement tolerance; real page/zoom/text/fallback taps and medium header position are verified. The full-default audit then reported nonnil Text equivalent textClipped at larger Dynamic Type. Coordinator explicitly confirmed no new handler is allowed (the existing medium exception is nil-element only): fixed the Toggle label with lineLimit(nil) and fixedSize(horizontal:false,vertical:true), no default-size visual change or point threshold. Rerunning all affected reference tests plus queued macOS/l10n checks via nohup. Existing approved audit helpers/handlers remain unchanged; new medium test still uses raw performAccessibilityAudit().

Further medium-detent accessibility checks: explicit wrapping fixed Show full sheet; the native Toggle still clipped at larger sizes, so its label and named native switch now stack vertically only at accessibility Dynamic Type sizes, as coordinator approved. The next raw audit has only a nil-element textClipped finding (no element screenshot or named node), fitting the existing approved task-44.3 rule. The new medium test now calls the unchanged isApprovedMediumDetentToolScrollTextClip handler with the existing five-issue cap after real controls/state and stable medium-header prechecks. Every named finding and all other audit types still fail. No existing helper or audit handler was changed; matrix/AX regressions, iPad, macOS and l10n are queued after medium passes.

Coordinator approval for Show full sheet styling: native bordered Button still intermittently reports named textClipped despite explicit wrapping. Reference tool was not user-visible before this branch, so change Show full sheet to the existing AccessibleSecondaryButtonLabel/Style used by other reference controls, retain minWidth:44 and Rectangle contentShape; this is consistent styling rather than a regression. No new handler/filter approved or added. Coordinator requests two consecutive medium-detent passes plus affected matrix/AX tests. These and iPad/macOS/l10n are running via nohup; eventual PR must note this style change.

Final coordinator clarification (supersedes earlier nil-only direction for this new test): owner decision 2026-10-12 approves larger-Dynamic-Type text clipping inside medium-detent tool scroll content, including named elements. Add a handler LOCAL to the new medium test: iPhone only, textClipped only, named elements must be descendants of reference-sheet-scroll, fail if that scroll is missing, medium detent asserted immediately before audit, logged and capped at five combined findings. Existing nil-only helper/rule remains unchanged; contrast and every other issue still fail. Coordinator approved retaining the real Toggle/Button wrapping/style improvements and requires two passes plus PR guard-marker explanation and reviewer line-by-line checking. Added title wrapping/full-width version layout too (no default visual change). Final medium repeats queued with this exact local scope; all other requested Apple checks continue independently. No build killed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented AC3: official five-page ISED Basic exam sheet is available offline with zoom, page controls and a faithful accessible English equivalent on web and iOS/iPadOS/macOS. The original study sheet remains selectable and is the sole default Release/production fallback. OFFICIAL_REFERENCE_SHEET gates actual resource inclusion and removes stale Apple resources; internal beta lanes explicitly opt in under owner decision 2A. Licensing, TestFlight and release checklists document the public-release block. Requested web/package, localization, URL/CSP, resource-gate and targeted Apple checks passed; detailed per-test results and narrowly approved audit scopes are recorded above. No existing helper or official question text was changed; no full Apple suites, upload or PR performed. Independent review and written ISED permission remain separate gates.
<!-- SECTION:FINAL_SUMMARY:END -->
