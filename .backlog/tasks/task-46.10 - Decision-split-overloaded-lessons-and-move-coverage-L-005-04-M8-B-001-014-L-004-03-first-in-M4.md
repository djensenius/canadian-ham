---
id: TASK-46.10
title: >-
  Split overloaded lessons and move coverage (L-005-04, M8, B-001-014, L-004-03
  first in M4)
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-12 14:58'
updated_date: '2026-10-19 23:15'
labels:
  - content
dependencies: []
parent_task_id: TASK-46
priority: medium
ordinal: 108000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Needs an owner decision; see docs/lesson-review/README.md. Once decided, add the implementation plan and acceptance criteria, or close as declined.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Owner decision recorded
- [x] #2 Splits and moves done with coverage, quizzes, explanations, figures and links updated; saved lesson progress migrates on web and Apple
- [x] #3 L-005-04 and M8 are split into smaller lessons, B-001-014 moves to L-001-05, and L-004-03 comes first in M4
- [x] #4 Lesson coverage shows every question still covered exactly as intended, and all content checks pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the current lesson/review files, existing lesson IDs, quizzes, explanations, hints, figures, links, and progress-storage code paths.\n2. Restructure the affected lessons mechanically: split L-005-04 into AC/dB and reactance/resonance lessons, split M8 receiver/transmitter lessons, move B-001-014 coverage into L-001-05, and reorder M4 so L-004-03 is taught first.\n3. Update dependent content metadata and references: quizzes, explanations lesson links, hint lessonLink anchors, figure directives, cross-links, schemas, and tests that name changed lesson IDs/titles.\n4. Add explicit old-to-new lesson ID migration for web and Apple progress/quiz references, including import/load tests and documented split behavior.\n5. Run the requested content, web, and targeted Apple checks; record evidence, finalize the Backlog task, commit, push, and open the PR with migration notes.

6. Finish the inherited test decoder helper and add only the two version-validation localizations, verifying the catalogue preserves origin/main entries and key order. Run full macOS units, the eight affected iOS Learn/figure tests, and requested web/content checks; record per-test evidence before finalization and PR.

Review fixes: verify old/new concept texts; implement identical concept/score/read-credit and per-device migrations on web/Apple, persist the Apple marker atomically, add launch/import/schema regressions, fix impedance prerequisite, create the approved figure follow-up, then run requested checks and update PR #302.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner decision 2026-10-12: YES. Split L-005-04 (AC and dB vs reactance and resonance), split M8 (receiver-side vs transmitter-side), move B-001-014 to L-001-05, teach L-004-03 first in M4. Lesson IDs may change; migrate saved progress and quiz references. Start after the 38.x figure branches merge.

Owner decision 2026-10-12: yes, do it, including migrating saved lesson progress for moved or split lessons.

Resumed finalization: committed test-local archived-array decoder helper (8d31d867; assertions unchanged) and exactly two sorted version-validation localizations (b67bfb39). Python verified origin/main catalogue entries and order unchanged and exact OrderedDict round-trip formatting. Final macOS full units, eight affected iPhone Learn/figure tests, localization no-rewrite gate, and all requested web/content checks queued via nohup in /tmp/task-46.10-{apple3,web-content3}.sh. The initial foreground localization attempt timed out while waiting for the shared lock, with catalogue hash unchanged; queued retry uses nohup.

Coordinator-approved parity fix: web split-quiz migration now matches Apple by skipping a destination with no answered official questions unless it is the original quiz. Added regression covering top-level and legacy sync-row migration; it failed before the one-line fix and all 29 ProgressStore tests passed afterward (pnpm --dir apps/web exec vitest run src/lib/progressStore.test.ts). Existing assertions were not weakened.

Full macOS run: 180 tests executed; 179 passed and existing testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates failed nine assertions because migration merged/sorted invalid raw rows before validation. Coordinator approved fixing both import paths: raw rows now validate before any migration, including exact historical quiz membership from source commit 350a3b53658c64f12e89c0b48d6b97c7c3040e88; migrated rows then validate against current membership. Imports reject invalid data before writing. Existing validation assertions are unchanged and now also assert import rejection. New Apple/web tests cover invalid scores and historical top-level/sync quiz membership, including removed legacy concept C3. Corrected only the legacy L-005-05 mixed-row fixture from B-005-009-003 to historically correct B-005-012-001; v2 fixture and all migration assertions preserved. Historical membership tables were independently checked against source via Python; web ProgressStore 31 tests pass. macOS ProgressStore class rerun queued via nohup; initial typecheck caught missing test DB names, fixed, and retry passes.

macOS fix validation passed via xbuild: entire ProgressStoreTests class, 93 tests / zero failures, including unchanged testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates and the two new raw-validation regressions. Initial full run covered the other 89 unit tests successfully (180 total before adding two tests); combined final evidence covers 182 distinct passing tests. Full-run/fix-rerun per-test table prepared at /tmp/task-46.10-macos-per-test.md for the PR and task notes. Latest pnpm test passes 217 web + 21 Morse Vitest tests; typecheck, build and URL/CSP audit pass. iOS and localization checks remain queued.

Tightened historical validation tables from subsection prefixes to the exact sampled officialQuestionIds: the old quizzes selected questions, not whole subsections. Both tables now match all source official-question and concept IDs exactly (Python set comparison against commit 350a3b53658c64f12e89c0b48d6b97c7c3040e88). Verified every old official ID occurs in a current destination. Strengthened the historical-membership regression on Apple/web to reject same-subsection B-005-009-001, which was never in the old quiz, for both top-level and sync rows. Web ProgressStore 31 tests pass; latest targeted Apple historical-membership method is queued via nohup. No assertions removed.

Coordinator-approved final safety fix: move the local Apple migration completion marker after successful context.save(), so a save failure cannot suppress retry on the next launch. No cheap existing save-failure injection seam covers this private initializer migration (existing hooks are specific to language migration/import/quiz saves); no new testing scaffolding was added, per approval. Control-flow ordering is explicit; queued iOS/localization builds compile the change. Exact historical-ID macOS regression passed (1 test / zero failures), and final web ProgressStore 31 tests/typecheck/build/URL-CSP audit passed. No further scope expansion planned.

Coordinator final validation 2026-10-19 at the head after the save-ordering fix: macOS unit 182/0; pnpm check:apple-l10n passed with no rewrite; pnpm test passed; iPhone 17 Pro Learn + changed lesson-figure tests 6/0; content checks all passed (coverage 100/100, originality 0, explanations 984, quizzes 37, links, hints 984/984, figures 38, schemas 2034, import:check).

PR #302 review fixes in progress. Verified each explicit concept mapping by comparing prompts against quizzes at 350a3b53; the two old M8 filter checks have no current equivalent and are dropped. Coordinator decision 2026-10-19: read destinations only when every contributing old lesson was read; use latest readAt/minimum readCount, separately per device. Approved partial-quiz rule uses the answered concept prefix plus explicit wrong IDs (never invent correct answers for those wrong IDs); coherent raw device aggregates drive migrated top-level read progress, while incoherent exports retain fallback. Documented in docs/architecture.md. Added shared concept/score fixture plus web and Apple launch/import regressions. Full macOS unit run is queued behind the xbuild lock. Figure mismatch follow-up created; leave teaching-guide x notation unchanged.

Review fixes committed/pushed: 53205dd8 (explicit text-verified concept remapping, concept-inclusive partial scores, conservative all-source/per-device read credit, version-neutral sync deduplication, null rejection, atomic SwiftData marker, shared fixture and launch/import regressions), e3e41860 (L-006-01 prerequisite L-005-05 and three invalid version-3 schema fixtures). Full macOS xbuild units passed 186/186, including all 97 ProgressStoreTests and all four new review regressions; web ProgressStore 36/36 and typecheck pass. Schema checks pass 55 tests / 2034 targets. TASK-46.12 tracks the two figure/host-lesson mismatches; figures and x notation deliberately unchanged here. Full web/content and no-rewrite localization checks are running.

Review-fix final non-Apple checks: pnpm test passed 222 web + 21 Morse Vitest tests, 144 content-tools and 127 calculator tests; typecheck, web build and URL/CSP audit passed. All requested content checks passed: coverage 100/100 across 37 lessons/8 modules, quizzes 37/521 official references/80 concepts, links, hints --require-complete 984/984, figures 38/38, explanations 984/2952 notes, originality 0, schemas 55 tests/2034 targets, Basic/Advanced import:check. Test guard and Apple text-source gate passed. Explicit Python comparison confirmed the 12 mapping entries identical on web/Apple: 10 preserved prompts equal the 350a3b53 originals, and both dropped filter prompts have no current equivalent. Removed the unused old forward read-credit map in 20cf2829; reran web ProgressStore 36/36 and typecheck green. PR #302 body now includes the complete per-test macOS table and Copilot was re-requested via API. Localization no-rewrite gate remains queued on the shared lock.

Latest full macOS xbuild per-test evidence (186 passed, zero failures; iOS/tvOS/visionOS suites not rerun for review migration fixes, with generic tvOS/visionOS builds included by localization gate):

| macOS unit test | Result | Duration |
| --- | --- | --- |
| `CanadianHamTests.DuoLayoutPolicyTests.testIPadInspectorRuleRemainsSizeClassDriven` | PASSED | 0.001 seconds |
| `CanadianHamTests.DuoLayoutPolicyTests.testMacAndOtherIdiomsNeverUseUnfoldedIPhoneRule` | PASSED | 0.001 seconds |
| `CanadianHamTests.DuoLayoutPolicyTests.testNilVerticalSizeClassDoesNotBlockWidthDrivenUnfoldedLandscapeLayout` | PASSED | 0.001 seconds |
| `CanadianHamTests.DuoLayoutPolicyTests.testOrdinaryIPhoneProMaxSizesKeepCompactSheetLayout` | PASSED | 0.001 seconds |
| `CanadianHamTests.DuoLayoutPolicyTests.testUnfoldedIPhoneEntryBoundaries` | PASSED | 0.001 seconds |
| `CanadianHamTests.DuoLayoutPolicyTests.testUnfoldedIPhoneHysteresisPreventsSmallSizeJitterFromClosingLayout` | PASSED | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutDoesNotScrollAtOrAboveHelpThresholdForNonAccessibilitySizes` | PASSED | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere` | PASSED | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutScrollsWhenCompactHeightCannotKeepMinimumKeys` | PASSED | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes` | PASSED | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale` | PASSED | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString` | PASSED | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testKeyHandlingProducesEngineDisplayAndSpokenResult` | PASSED | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testQuestionCardFocusResetKeepsTextSelectionEnabled` | PASSED | 0.004 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet` | PASSED | 0.001 seconds |
| `CanadianHamTests.ExamCalculatorViewModelTests.testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately` | PASSED | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testApplyPracticeAnswerSubmitsAnsweredWithHelpToEngine` | PASSED | 0.003 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekEligibilityAllowsPracticeReviewLaterButNeverMockExamOrScoredImmediateAnswer` | PASSED | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekEndsWhenPhoneFullyOpensOrCloses` | PASSED | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekFastUnfoldThroughBandNeverPeeks` | PASSED | 0.000 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekLeavingToleranceDoesNotResetDismissalSuppression` | PASSED | 0.000 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationAppearanceAllowsCurrentResetToClearSuppression` | PASSED | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationClosesPeekOpenedHintOnQuestionChangeAndRequiresFreshDwell` | PASSED | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationDismissalSuppressesReopenUntilReset` | PASSED | 0.000 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationImmediateAnswerEndsEligibility` | PASSED | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset` | PASSED | 0.000 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationLifecycleKeepsDismissalSuppressionAcrossDisappear` | PASSED | 0.000 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekPresentationStartsOnlyOnceUntilPostureReset` | PASSED | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekRecheckPeeksWithoutNewSamples` | PASSED | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekRequiresStableDwellInSlightOpenBand` | PASSED | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekSlowCloseThroughBandNeverPeeks` | PASSED | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek` | PASSED | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekToleratesSmallJitterOnlyAfterPeekStarts` | PASSED | 0.000 seconds |
| `CanadianHamTests.HintSessionStateTests.testHingePeekUnavailableSampleDoesNotResetDismissalSuppression` | PASSED | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHintQualificationMarksUnansweredQuestionAsQualifiedOnly` | PASSED | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp` | PASSED | 0.393 seconds |
| `CanadianHamTests.HintSessionStateTests.testHintVisibilityTimerDoesNotQualifyShortPeekRoute` | PASSED | 0.293 seconds |
| `CanadianHamTests.HintSessionStateTests.testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp` | PASSED | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable` | PASSED | 0.002 seconds |
| `CanadianHamTests.HintSessionStateTests.testReviewLaterHintAfterSelectionRecordsHelp` | PASSED | 0.001 seconds |
| `CanadianHamTests.HintSessionStateTests.testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission` | PASSED | 0.002 seconds |
| `CanadianHamTests.HintSessionStateTests.testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange` | PASSED | 2.673 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testEveryCatalogKeyHasFrenchTranslations` | PASSED | 0.020 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries` | PASSED | 0.005 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testLanguagePreferenceResolvesSystemAndOverrides` | PASSED | 0.001 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testLocalizedNullableTextAndLanguageFallsBackToEnglish` | PASSED | 0.001 seconds |
| `CanadianHamTests.LocalizationCatalogTests.testQuestionBankLoadErrorDescriptionUsesFrenchLocale` | PASSED | 0.004 seconds |
| `CanadianHamTests.MorseTrainerTests.testCompletedMorseCourseSessionIgnoresResubmittedAnswer` | PASSED | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testFixedTimingProfilesUseEngineValues` | PASSED | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testLessonBodyAndBulletContrastTokensMeetMinimumRatio` | PASSED | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp` | PASSED | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseAudioSessionStaysActiveUntilLastPlayerReleases` | PASSED | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins` | PASSED | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters` | PASSED | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone` | PASSED | 0.002 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseProgressIgnoresStoredProgressForAnotherCourse` | PASSED | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition` | PASSED | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseExamGeneratorMeetsReceivingExamConstraints` | PASSED | 0.003 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime` | PASSED | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying` | PASSED | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingClassifiesTimingAndErrorSignal` | PASSED | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingPendingFinalizationHelperCancelsAndClears` | PASSED | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingRemainingExamSecondsUsesFixedDeadline` | PASSED | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters` | PASSED | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsClampAndPreset` | PASSED | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsCodableRoundTripPreservesOutputMode` | PASSED | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsDecodesLegacyPayloadWithIsEnabled` | PASSED | 0.000 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast` | PASSED | 0.006 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseSettingsRoundTripThroughUserDefaults` | PASSED | 0.005 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseStopDelayDrainsFadeBeforeStoppingEngine` | PASSED | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced` | PASSED | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testReduceFlashingDecisionUsesInjectedFlags` | PASSED | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testReduceFlashingStopsOnlyRunningVisualBeacon` | PASSED | 0.001 seconds |
| `CanadianHamTests.MorseTrainerTests.testScheduleMorseVisualPlaybackInitialStateAndFallback` | PASSED | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress` | PASSED | 0.089 seconds |
| `CanadianHamTests.ProgressStoreTests.testAdvancedImportRejectsHonoursAttempts` | PASSED | 0.025 seconds |
| `CanadianHamTests.ProgressStoreTests.testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch` | PASSED | 0.004 seconds |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelPublishesMorseSettingsForRootViewSync` | PASSED | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement` | PASSED | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows` | PASSED | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore` | PASSED | 0.023 seconds |
| `CanadianHamTests.ProgressStoreTests.testDecodesLegacyBasicExportWithoutBankIdFields` | PASSED | 0.030 seconds |
| `CanadianHamTests.ProgressStoreTests.testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme` | PASSED | 0.030 seconds |
| `CanadianHamTests.ProgressStoreTests.testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker` | PASSED | 0.021 seconds |
| `CanadianHamTests.ProgressStoreTests.testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt` | PASSED | 0.060 seconds |
| `CanadianHamTests.ProgressStoreTests.testFreshInstallDefaultsLanguageToSystem` | PASSED | 0.014 seconds |
| `CanadianHamTests.ProgressStoreTests.testICloudAccountSignalsUseInitInjectedFactory` | PASSED | 0.072 seconds |
| `CanadianHamTests.ProgressStoreTests.testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot` | PASSED | 0.030 seconds |
| `CanadianHamTests.ProgressStoreTests.testICloudDeleteCanDeleteLocalDataAfterZoneDelete` | PASSED | 0.029 seconds |
| `CanadianHamTests.ProgressStoreTests.testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload` | PASSED | 0.138 seconds |
| `CanadianHamTests.ProgressStoreTests.testICloudMergeFixtureIsPermutationIndependentAndIdempotent` | PASSED | 0.002 seconds |
| `CanadianHamTests.ProgressStoreTests.testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal` | PASSED | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testICloudSyncToggleAndAccountSignalsPreserveLocalProgress` | PASSED | 0.049 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing` | PASSED | 0.035 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields` | PASSED | 0.037 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount` | PASSED | 0.049 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons` | PASSED | 0.067 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange` | PASSED | 0.034 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportLeavesTask4610Version2LessonSplitRowsUnchanged` | PASSED | 0.036 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportMigratesMixedTask4610SyncRowsByRowVersion` | PASSED | 0.039 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportMigratesTask4610LessonSplitProgressAndQuizAttempts` | PASSED | 0.037 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportOfOlderExportDoesNotRemoveExistingMorseProgress` | PASSED | 0.033 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportRejectsInvalidSyncDeviceRows` | PASSED | 0.046 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportRejectsUnsupportedLanguagePreferenceValues` | PASSED | 0.039 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses` | PASSED | 0.072 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackKeepsExistingDataWhenReplacementFails` | PASSED | 0.044 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportRollbackPropagatesMorseProgressRemovalFailure` | PASSED | 0.033 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress` | PASSED | 0.034 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt` | PASSED | 0.036 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues` | PASSED | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates` | PASSED | 0.039 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsDuplicateMorseDailyActivityDates` | PASSED | 0.039 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsInvalidMorseCourseProgress` | PASSED | 0.038 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsMismatchedScoreBankId` | PASSED | 0.038 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt` | PASSED | 0.034 seconds |
| `CanadianHamTests.ProgressStoreTests.testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges` | PASSED | 0.033 seconds |
| `CanadianHamTests.ProgressStoreTests.testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults` | PASSED | 0.039 seconds |
| `CanadianHamTests.ProgressStoreTests.testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference` | PASSED | 0.010 seconds |
| `CanadianHamTests.ProgressStoreTests.testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault` | PASSED | 0.014 seconds |
| `CanadianHamTests.ProgressStoreTests.testLaunchIgnoresRegisteredAppleLanguagesValue` | PASSED | 0.010 seconds |
| `CanadianHamTests.ProgressStoreTests.testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue` | PASSED | 0.009 seconds |
| `CanadianHamTests.ProgressStoreTests.testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries` | PASSED | 0.012 seconds |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun` | PASSED | 0.014 seconds |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting` | PASSED | 0.010 seconds |
| `CanadianHamTests.ProgressStoreTests.testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce` | PASSED | 0.009 seconds |
| `CanadianHamTests.ProgressStoreTests.testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure` | PASSED | 0.029 seconds |
| `CanadianHamTests.ProgressStoreTests.testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead` | PASSED | 0.051 seconds |
| `CanadianHamTests.ProgressStoreTests.testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution` | PASSED | 0.055 seconds |
| `CanadianHamTests.ProgressStoreTests.testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution` | PASSED | 0.036 seconds |
| `CanadianHamTests.ProgressStoreTests.testMigratesArchivedLessonProgressKeepsMaxOwnReadCount` | PASSED | 0.012 seconds |
| `CanadianHamTests.ProgressStoreTests.testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist` | PASSED | 0.034 seconds |
| `CanadianHamTests.ProgressStoreTests.testMigratesCommittedPreV2StoreFixtureWithAllDataIntact` | PASSED | 0.462 seconds |
| `CanadianHamTests.ProgressStoreTests.testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity` | PASSED | 0.022 seconds |
| `CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV1ToV2WithoutUniqueConstraints` | PASSED | 0.080 seconds |
| `CanadianHamTests.ProgressStoreTests.testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields` | PASSED | 0.080 seconds |
| `CanadianHamTests.ProgressStoreTests.testMockExamTimerRefreshPreservesFractionalRemainder` | PASSED | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testMorseCourseProgressRoundTripsTwentyRecentCharacterResults` | PASSED | 0.030 seconds |
| `CanadianHamTests.ProgressStoreTests.testMorseExportMapsHapticsToWebCompatibleAudio` | PASSED | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testMorseImportDecodesMissingAndPartialMorsePreferences` | PASSED | 0.055 seconds |
| `CanadianHamTests.ProgressStoreTests.testMorseImportRejectsExplicitNullMorseValues` | PASSED | 0.001 seconds |
| `CanadianHamTests.ProgressStoreTests.testMorseImportRejectsUnsupportedMorsePreferenceEnums` | PASSED | 0.039 seconds |
| `CanadianHamTests.ProgressStoreTests.testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference` | PASSED | 0.013 seconds |
| `CanadianHamTests.ProgressStoreTests.testNativeSettingsGeneralBindingsUpdatePracticePreferences` | PASSED | 0.011 seconds |
| `CanadianHamTests.ProgressStoreTests.testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows` | PASSED | 0.038 seconds |
| `CanadianHamTests.ProgressStoreTests.testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt` | PASSED | 0.012 seconds |
| `CanadianHamTests.ProgressStoreTests.testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences` | PASSED | 0.043 seconds |
| `CanadianHamTests.ProgressStoreTests.testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse` | PASSED | 0.036 seconds |
| `CanadianHamTests.ProgressStoreTests.testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints` | PASSED | 0.038 seconds |
| `CanadianHamTests.ProgressStoreTests.testProgressStoreRoundTripExportImportReset` | PASSED | 0.060 seconds |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataTurnsICloudSyncOptInOff` | PASSED | 0.013 seconds |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData` | PASSED | 0.131 seconds |
| `CanadianHamTests.ProgressStoreTests.testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure` | PASSED | 0.151 seconds |
| `CanadianHamTests.ProgressStoreTests.testResetClearsAppleLanguagesAndLanguagePreference` | PASSED | 0.019 seconds |
| `CanadianHamTests.ProgressStoreTests.testResetFailureKeepsPreviousAppleLanguagesAndPreference` | PASSED | 0.015 seconds |
| `CanadianHamTests.ProgressStoreTests.testResetRollsBackWhenMorseProgressRemovalFails` | PASSED | 0.016 seconds |
| `CanadianHamTests.ProgressStoreTests.testSavingLargeQuestionProgressBatchBuildsOneWriteContext` | PASSED | 1.794 seconds |
| `CanadianHamTests.ProgressStoreTests.testSharedAppleSettingsModelAppliesLivePreferenceUpdates` | PASSED | 0.115 seconds |
| `CanadianHamTests.ProgressStoreTests.testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules` | PASSED | 0.002 seconds |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries` | PASSED | 0.013 seconds |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress` | PASSED | 0.098 seconds |
| `CanadianHamTests.ProgressStoreTests.testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists` | PASSED | 0.064 seconds |
| `CanadianHamTests.ProgressStoreTests.testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite` | PASSED | 0.031 seconds |
| `CanadianHamTests.ProgressStoreTests.testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration` | PASSED | 0.010 seconds |
| `CanadianHamTests.ProgressStoreTests.testTask4610LaunchMigrationIsAtomicAndStableWithArchivedProgressAndMultipleDevices` | PASSED | 0.045 seconds |
| `CanadianHamTests.ProgressStoreTests.testTask4610LessonMigrationIsIdempotentAcrossRepeatedImports` | PASSED | 0.039 seconds |
| `CanadianHamTests.ProgressStoreTests.testTask4610RejectsInvalidLegacyQuizScoresBeforeMigration` | PASSED | 0.030 seconds |
| `CanadianHamTests.ProgressStoreTests.testTask4610RejectsNullLessonIDVersionAtTopLevelAndOnBothDeviceRowKinds` | PASSED | 0.029 seconds |
| `CanadianHamTests.ProgressStoreTests.testTask4610RequiresAllReadSourcesAndMergesEachDeviceBeforeAggregating` | PASSED | 0.105 seconds |
| `CanadianHamTests.ProgressStoreTests.testTask4610SharedConceptMappingAndConceptInclusiveScores` | PASSED | 0.101 seconds |
| `CanadianHamTests.ProgressStoreTests.testTask4610ValidatesHistoricalQuizMembershipBeforeMigratingTopLevelAndSyncRows` | PASSED | 0.040 seconds |
| `CanadianHamTests.ProgressStoreTests.testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync` | PASSED | 0.055 seconds |
| `CanadianHamTests.QuestionBankTests.testAdvancedBundledJSONDecodesExpectedCountsAndVerifiedFrenchCategoryNames` | PASSED | 0.012 seconds |
| `CanadianHamTests.QuestionBankTests.testAdvancedMockExamUsesFiftyQuestionsAndNoHonours` | PASSED | 0.013 seconds |
| `CanadianHamTests.QuestionBankTests.testAppBundleContainsNoReadmeFiles` | PASSED | 0.013 seconds |
| `CanadianHamTests.QuestionBankTests.testAppBundleContainsOnlyExpectedGeneratedBankDirectories` | PASSED | 0.001 seconds |
| `CanadianHamTests.QuestionBankTests.testBundledJSONDecodesExpectedCounts` | PASSED | 0.022 seconds |
| `CanadianHamTests.QuestionBankTests.testBundledLessonModelExposesPrerequisites` | PASSED | 0.561 seconds |
| `CanadianHamTests.QuestionBankTests.testBundledLessonsAndExplanationsLoadThroughContentLibrary` | PASSED | 0.711 seconds |
| `CanadianHamTests.QuestionBankTests.testEngineQuestionDrawKeepsQuestionInsideRequestedCategory` | PASSED | 0.019 seconds |
| `CanadianHamTests.QuestionBankTests.testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion` | PASSED | 0.081 seconds |
| `CanadianHamTests.QuestionBankTests.testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes` | PASSED | 0.001 seconds |
| `CanadianHamTests.QuestionBankTests.testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons` | PASSED | 0.566 seconds |
| `CanadianHamTests.ReadinessAndScoringTests.testAdvancedScoringAndReadinessSuppressHonours` | PASSED | 0.001 seconds |
| `CanadianHamTests.ReadinessAndScoringTests.testExamScoringBoundaries` | PASSED | 0.001 seconds |
| `CanadianHamTests.ReadinessAndScoringTests.testReadinessStates` | PASSED | 0.001 seconds |
| `CanadianHamTests.ReadinessAndScoringTests.testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate` | PASSED | 0.035 seconds |
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Split L-005-04 (AC and dB / reactance and resonance, plus new L-005-06 transformers and meters) and M8 (receiver / transmitter side), moved B-001-014 to L-001-05, and taught L-004-03 first in M4. Updated coverage, quizzes, explanations, hints, figures and links. Saved progress migrates on web (IndexedDB v6) and Apple (one-time local migration, marker after save). Imports and sync rows carry lessonIdVersion so only legacy data migrates. Raw rows are validated against exact historical quiz membership before migration, and migrated rows against current membership.
<!-- SECTION:FINAL_SUMMARY:END -->
