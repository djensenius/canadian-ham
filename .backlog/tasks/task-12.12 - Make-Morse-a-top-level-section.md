---
id: TASK-12.12
title: Make Morse a top-level section
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-03 12:03'
updated_date: '2026-10-03 21:47'
labels:
  - web
  - apple
  - morse
  - accessibility
milestone: m-1
dependencies:
  - TASK-12.3
parent_task_id: TASK-12
priority: high
ordinal: 58000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the owner tried the preview and doesn't want Morse buried behind a Settings toggle (2026-10-02 decision in task-12). Morse becomes its own always-visible section, with its settings inside the section (web, iOS/iPadOS) or in native Settings on macOS (task-30). A small 'Preview' label stays until the course (task-12.5) and copy practice/exam (task-12.6) land.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Morse is a top-level section on every platform: web top navigation (#/morse), iOS/iPadOS tab or sidebar, macOS sidebar, tvOS and visionOS menu entry; the preview toggle and its gating/redirect code are removed, and task-12.10 is closed as obsolete with a note
- [x] #2 Morse settings (tone, speeds, timing profile, volume, ISED exam preset) live inside the Morse section on web and iOS/iPadOS; existing stored Morse preferences migrate without loss
- [x] #3 The section has a Morse home that will host Learn (course), Practice (copy) and Exam entries; for now it hosts the existing player, labelled Preview
- [x] #4 Accessibility audits (axe on web; light and dark Apple audits on iOS, tvOS and visionOS), French UI, and the web and four Apple xbuild suites pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Remove Morse preview-toggle gating and migrate stored preferences without the enabled flag.\n2. Promote Morse to a top-level destination on web and all Apple platforms, with a preview-labelled Morse home, placeholders, and platform-appropriate settings placement.\n3. Update launch-argument handling and UI/unit tests, then validate web and Apple checks before finalizing.

Fix review round: replace compact iPhone one-way Morse toolbar with a compact tab interface, add navigation/UI coverage, keep iPad/macOS sidebar behavior, and restore catalogue/web/documentation cleanup requested by review.

Review round 3: remove compact tab UIKit appearance customization, restore main's ISED draft-attribution wording, preserve compact per-tab navigation state, tighten iPhone tab UI tests, revert unrelated Home ordering, add release-checklist coverage, then run targeted checks followed by final platform suites.

Fix round 4: Step A (plain system TabView) still failed the iOS core accessibility audits, so compact iPhone now uses the native collapsed-sidebar NavigationStack root list. Preserve compact practice/mock in-progress state by hoisting their state above pushed views; keep language controls in content where needed instead of tab-bar chrome.

Fix round 5: audit the compact root list in light/dark, move transient mock-exam UI flags back to local view state, clear cached compact sessions on data revision changes, restore iPhone language pickers/timer/navigation behavior, update tests, and rerun targeted then final affected-platform validation.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented Morse as an always-visible top-level destination on web and Apple platforms; removed web/Apple preview-toggle UI and setting gates; moved web/iOS Morse settings into the Morse section; added Morse placeholders and Quick listen; updated tests and localization. Validation so far: web focused tests, pnpm test, web build, apple text-source check, apple l10n, macOS xbuild passed; iOS/tvOS/visionOS xbuild runs timed out before completion after many tests passed.

Validation gap: full iOS xbuild suite was rerun after fixing home-action clipping, but it timed out at 1200s while still executing UI tests; earlier failing clipping audits were fixed and the Morse UI test passed. tvOS and visionOS xbuild suites also timed out during UI tests after unit tests and several UI tests passed. AC4 remains unchecked pending full platform suite completion.

Final validation (2026-10-03): compact iPhone now exposes Morse from top-level navigation via the `compact-top-level-morse` toolbar button; `CanadianHamPracticeUITests.testCompactTopLevelNavigationExposesMorse` passed in the full iOS suite. Platform xbuild results: iOS `CanadianHam` on iPhone 17 Pro passed (`CanadianHamTests`: 30 tests, 0 failures; `CanadianHamUITests`: 30 tests, 0 failures; log `/tmp/task-12.12-ios-final.log`). tvOS `CanadianHamTV` on Apple TV 4K (3rd generation) passed (`CanadianHamTVTests`: 3 tests, 0 failures; `CanadianHamTVUITests`: 11 tests, 0 failures; log `/tmp/task-12.12-tvos.log`). visionOS `CanadianHamVision` on Apple Vision Pro passed (`CanadianHamVisionTests`: 3 tests, 0 failures; `CanadianHamVisionUITests`: 8 tests, 0 failures; log `/tmp/task-12.12-visionos.log`). Prior branch validation already recorded web focused tests, pnpm test, web build, text-source/l10n checks, and macOS xbuild passing.

Fix round implementation committed through 6d929a0. Web checks passed and targeted Apple tests passed, but final iOS full run exposed accessibility audit failures in compact navigation/home/practice after the TabView change; left task In Progress for follow-up.

Fix round 3 progress: restored main's ISED draft-attribution wording, removed global UITabBar.appearance customization, moved compact navigation to per-tab NavigationStack paths, added compact tab preservation UI tests, and kept the Home readiness action placement only for compact iPhone because the tab bar/accessibility audit still overlaps Home content. Targeted tab tests passed, but targeted iOS core accessibility audits still fail on the compact tab bar contrast; task remains In Progress and no final platform runs were attempted.

Fix round 4 final: Step A removed compact tab-bar chrome/tint/underlay but iOS core light/dark audits still failed, so Step B passed with the collapsed-sidebar root list (Home, Learn, Practice, Morse, Settings). No custom tab bar background, unselected colour, or content-covering underlay remains. Home readiness order was reverted; compact Home action buttons use a vertical layout only to avoid French text clipping, not as a tab-bar workaround. ISED legal text was not touched. Evidence on commit f7bcbaaf7ee19004aced3bcfcd703efa87377243: pnpm typecheck; pnpm test; pnpm build:web; pnpm --filter @canadian-ham/web audit:urls; pnpm check:links; pnpm check:apple-l10n; node scripts/check-apple-text-sources.ts; pnpm check:apple-network; full xbuild suites passed for iOS (/tmp/task-12.12-r4-ios-full-final2.log, 64 tests), macOS (/tmp/task-12.12-r4-macos-full-final.log, 32 tests), tvOS (/tmp/task-12.12-r4-tvos-full-final.log, 15 tests), and visionOS (/tmp/task-12.12-r4-visionos-full-final.log, 12 tests). Per-test names are recorded in those logs.

Fix round 5 final validation (commit aa35ea4b0b8ab1d1f172a858d7755b37517630e7):
- Affected platforms from apps/apple/project.yml: RootView.swift, StudyViews.swift, AppSettingsModel.swift, NativeSettingsView.swift compile in the CanadianHam target for iOS and macOS; CanadianHamUITests are iOS-only. Localizable.xcstrings was updated for extracted strings and covered by apple localization/text-source checks. tvOS and visionOS full suites were skipped because their targets do not compile the changed Swift files; localization coverage was verified by pnpm check:apple-l10n.
- Commands passed: pnpm check:apple-l10n; node scripts/check-apple-text-sources.ts; full iOS xbuild /tmp/task-12.12-r5-ios-full-final2.log; full macOS xbuild /tmp/task-12.12-r5-macos-full.log.
- Warning check: grep found no "Publishing changes from within view updates" in /tmp/task-12.12-r5-ios-full-final2.log.
- iOS full xbuild (CanadianHam, iPhone 17 Pro): 67 tests, 0 failures.
  - CanadianHamTests/LocalizationCatalogTests/testEveryCatalogKeyHasFrenchTranslations: PASSED
  - CanadianHamTests/LocalizationCatalogTests/testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries: PASSED
  - CanadianHamTests/LocalizationCatalogTests/testLocalizedNullableTextAndLanguageFallsBackToEnglish: PASSED
  - CanadianHamTests/LocalizationCatalogTests/testQuestionBankLoadErrorDescriptionUsesFrenchLocale: PASSED
  - CanadianHamTests/MorseTrainerTests/testFixedTimingProfilesUseEngineValues: PASSED
  - CanadianHamTests/MorseTrainerTests/testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp: PASSED
  - CanadianHamTests/MorseTrainerTests/testMorseSettingsClampAndPreset: PASSED
  - CanadianHamTests/MorseTrainerTests/testMorseSettingsDecodesLegacyPayloadWithIsEnabled: PASSED
  - CanadianHamTests/MorseTrainerTests/testMorseSettingsRoundTripThroughUserDefaults: PASSED
  - CanadianHamTests/MorseTrainerTests/testMorseStopDelayDrainsFadeBeforeStoppingEngine: PASSED
  - CanadianHamTests/ProgressStoreTests/testAppSettingsModelPublishesMorseSettingsForRootViewSync: PASSED
  - CanadianHamTests/ProgressStoreTests/testDecodesLegacyBasicExportWithoutBankIdFields: PASSED
  - CanadianHamTests/ProgressStoreTests/testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme: PASSED
  - CanadianHamTests/ProgressStoreTests/testImportRollbackKeepsExistingDataWhenReplacementFails: PASSED
  - CanadianHamTests/ProgressStoreTests/testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt: PASSED
  - CanadianHamTests/ProgressStoreTests/testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues: PASSED
  - CanadianHamTests/ProgressStoreTests/testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates: PASSED
  - CanadianHamTests/ProgressStoreTests/testImportValidationRejectsMismatchedScoreBankId: PASSED
  - CanadianHamTests/ProgressStoreTests/testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt: PASSED
  - CanadianHamTests/ProgressStoreTests/testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure: PASSED
  - CanadianHamTests/ProgressStoreTests/testProgressStoreRoundTripExportImportReset: PASSED
  - CanadianHamTests/ProgressStoreTests/testSharedAppleSettingsModelAppliesLivePreferenceUpdates: PASSED
  - CanadianHamTests/QuestionBankTests/testBundledJSONDecodesExpectedCounts: PASSED
  - CanadianHamTests/QuestionBankTests/testBundledLessonsAndExplanationsLoadThroughContentLibrary: PASSED
  - CanadianHamTests/QuestionBankTests/testEngineQuestionDrawKeepsQuestionInsideRequestedCategory: PASSED
  - CanadianHamTests/QuestionBankTests/testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion: PASSED
  - CanadianHamTests/QuestionBankTests/testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes: PASSED
  - CanadianHamTests/QuestionBankTests/testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons: PASSED
  - CanadianHamTests/ReadinessAndScoringTests/testAdvancedScoringAndReadinessSuppressHonours: PASSED
  - CanadianHamTests/ReadinessAndScoringTests/testExamScoringBoundaries: PASSED
  - CanadianHamTests/ReadinessAndScoringTests/testReadinessStates: PASSED
  - CanadianHamTests/ReadinessAndScoringTests/testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testAboutShowsReleaseAttributionDisclaimerAndBankVersion: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditCoreScreensDark: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditCoreScreensLight: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditLearnFlowDark: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditLearnFlowLight: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditMockExamFlowDark: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditMockExamFlowLight: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditPracticeSessionDark: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditPracticeSessionLight: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testCanPracticeInFrenchAndSeeFeedback: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testCompactMockExamEndExamDiscardsInProgressSession: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testCompactRootNavigationPreservesMockExamState: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testCompactRootNavigationPreservesPracticeSessionState: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testCompactTopLevelListPushesMorseThenLearn: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testExplanationAppearsAfterAnsweringInPractice: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testFrenchAboutKeepsLegalTextInEnglish: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testFrenchSystemLanguageNavigatesMainScreensAndAuditsHomeAndPractice: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testLanguagePickerExistsOnCategoryListAndPractice: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testLanguagePickerExistsOnCompactHomeLearnMorseAndMockExam: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testLearnOpensLessonAndShowsFirstHeading: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testLearnUserNavigationOpensLessonQuiz: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testLessonQuizResultPersistsAfterRelaunch: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testLongestAnswerWrapsAtLargestAccessibilityTextSize: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testMockExamDoesNotShowCorrectnessBeforeSubmit: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testMockExamHeaderControlsSupportLargestAccessibilityTextSize: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testMockExamNextUnansweredJumpsAfterAnsweringFirstQuestion: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testMockExamResultHeadingCarriesVoiceOverSubmissionSummary: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testMorseSectionIsTopLevelAndShowsSettings: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testPracticeFlowSupportsLargestAccessibilityTextSize: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testPracticeImmediateFeedbackKeepsStateAfterFirstAnswer: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testRegularWidthMockExamResultPersistsAfterSubmit: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testReviewLaterHidesCorrectnessUntilSubmitAndResultsSurviveSave: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testSettingsResetClearsCompactMockExamCacheWithoutRelaunch: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testSettingsResetClearsSavedMockExamProgress: PASSED
  - CanadianHamUITests/CanadianHamPracticeUITests/testSubsectionPracticeOpensFromHubAndShowsReviewScreen: PASSED
- macOS full xbuild (CanadianHam, macOS arm64, UI tests skipped): 32 tests, 0 failures.
  - CanadianHamTests/LocalizationCatalogTests/testEveryCatalogKeyHasFrenchTranslations: PASSED
  - CanadianHamTests/LocalizationCatalogTests/testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries: PASSED
  - CanadianHamTests/LocalizationCatalogTests/testLocalizedNullableTextAndLanguageFallsBackToEnglish: PASSED
  - CanadianHamTests/LocalizationCatalogTests/testQuestionBankLoadErrorDescriptionUsesFrenchLocale: PASSED
  - CanadianHamTests/MorseTrainerTests/testFixedTimingProfilesUseEngineValues: PASSED
  - CanadianHamTests/MorseTrainerTests/testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp: PASSED
  - CanadianHamTests/MorseTrainerTests/testMorseSettingsClampAndPreset: PASSED
  - CanadianHamTests/MorseTrainerTests/testMorseSettingsDecodesLegacyPayloadWithIsEnabled: PASSED
  - CanadianHamTests/MorseTrainerTests/testMorseSettingsRoundTripThroughUserDefaults: PASSED
  - CanadianHamTests/MorseTrainerTests/testMorseStopDelayDrainsFadeBeforeStoppingEngine: PASSED
  - CanadianHamTests/ProgressStoreTests/testAppSettingsModelPublishesMorseSettingsForRootViewSync: PASSED
  - CanadianHamTests/ProgressStoreTests/testDecodesLegacyBasicExportWithoutBankIdFields: PASSED
  - CanadianHamTests/ProgressStoreTests/testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme: PASSED
  - CanadianHamTests/ProgressStoreTests/testImportRollbackKeepsExistingDataWhenReplacementFails: PASSED
  - CanadianHamTests/ProgressStoreTests/testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt: PASSED
  - CanadianHamTests/ProgressStoreTests/testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues: PASSED
  - CanadianHamTests/ProgressStoreTests/testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates: PASSED
  - CanadianHamTests/ProgressStoreTests/testImportValidationRejectsMismatchedScoreBankId: PASSED
  - CanadianHamTests/ProgressStoreTests/testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt: PASSED
  - CanadianHamTests/ProgressStoreTests/testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure: PASSED
  - CanadianHamTests/ProgressStoreTests/testProgressStoreRoundTripExportImportReset: PASSED
  - CanadianHamTests/ProgressStoreTests/testSharedAppleSettingsModelAppliesLivePreferenceUpdates: PASSED
  - CanadianHamTests/QuestionBankTests/testBundledJSONDecodesExpectedCounts: PASSED
  - CanadianHamTests/QuestionBankTests/testBundledLessonsAndExplanationsLoadThroughContentLibrary: PASSED
  - CanadianHamTests/QuestionBankTests/testEngineQuestionDrawKeepsQuestionInsideRequestedCategory: PASSED
  - CanadianHamTests/QuestionBankTests/testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion: PASSED
  - CanadianHamTests/QuestionBankTests/testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes: PASSED
  - CanadianHamTests/QuestionBankTests/testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons: PASSED
  - CanadianHamTests/ReadinessAndScoringTests/testAdvancedScoringAndReadinessSuppressHonours: PASSED
  - CanadianHamTests/ReadinessAndScoringTests/testExamScoringBoundaries: PASSED
  - CanadianHamTests/ReadinessAndScoringTests/testReadinessStates: PASSED
  - CanadianHamTests/ReadinessAndScoringTests/testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate: PASSED
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fix round 5 audited the compact root screen in light/dark, moved transient mock-exam UI flags back to local view state, invalidated cached compact practice/mock sessions on data replacement, restored compact language pickers and push-style Back behavior, added End exam, and updated UI coverage. Verified on aa35ea4b0b8ab1d1f172a858d7755b37517630e7 with pnpm check:apple-l10n, node scripts/check-apple-text-sources.ts, full iOS xbuild (67 tests), and full macOS xbuild (32 tests); tvOS/visionOS skipped because changed Swift files are not compiled by those targets.
<!-- SECTION:FINAL_SUMMARY:END -->
