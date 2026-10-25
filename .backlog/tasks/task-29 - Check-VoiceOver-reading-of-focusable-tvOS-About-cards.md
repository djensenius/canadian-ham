---
id: TASK-29
title: Check VoiceOver reading of focusable tvOS About cards
status: In Progress
assignee:
  - '@pi-worker'
created_date: 2026-10-02 08:06
updated_date: '2026-10-25T17:19:00Z'
labels:
  - apple
  - tvos
  - accessibility
milestone: m-0
dependencies: []
priority: low
ordinal: 53000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: task-1.4 made each tvOS About card (attribution, disclaimer, privacy, sources) one focusable element so the remote can reach them. Combining a card into one element may make VoiceOver read the whole card as a heading (it inherits the title's header trait) and may drop the English language tag on legal text inside the French UI. The accessibility audit passes, but only a listening check on a device or simulator with VoiceOver confirms it.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 With VoiceOver on tvOS, each About card reads its title as a heading and its body as normal text, verified and recorded in docs/accessibility.md
- [ ] #2 In the French UI, the English legal text in the attribution and disclaimer cards is spoken with an English voice
- [ ] #3 If either fails, the header trait or language tag is moved to the right element and the tvOS suite, including accessibility audits, passes via xbuild
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect tvOS About focus/heading/language structure and capture EN/FR focused-card labels and debug descriptions with targeted UI tests before changing semantics.
2. Keep the existing visual cards and one remote focus stop per card; remove inherited whole-card Header traits and provide a single attributed legal-card label with explicit English body runs if needed. Extend structural EN/FR assertions without weakening audits.
3. Run targeted About tests and the existing tvOS UI/full suite through nohup xbuild with grep polling on Apple TV 4K (3rd generation); run localization/text-source checks.
4. Document structural evidence and exact owner VoiceOver listening steps; leave AC1/AC2 pending and TASK-29 In Progress, check AC3 only on passing suite, commit and push (no PR).
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Structural verification complete in EN/FR on Apple TV 4K (3rd generation), tvOS 27.0: baseline and final focused debugDescription captures report StaticText/Focused and no literal Header for all five cards (Bank included). The snapshot format does not expose every UIKit trait or attributed language run; no listening claim is made. Before: title child .isHeader plus implicit .combine and separate en-CA legal child labels. After: one explicit attributed label from the visible strings, title-only h2 run, normal body runs, en legal bodies/fr-CA French titles, aggregate .isHeader removed, .combine retained (no guarded .ignore or audit exceptions).
Added EN/FR UI assertions for single combined label, remote focus order, title/body/full legal paragraphs, StaticText and no reported Header; keepAlways full debugDescription attachments. Added TVAboutCardText unit tests for per-run headings/languages. Targeted xbuild About+metadata run passed 7/7 including existing light/dark About audits; pnpm check:apple-l10n and node scripts/check-apple-text-sources.ts passed. Full tvOS suite running via nohup/xbuild.
AC1/AC2 evidence: structural verification done; listening check pending owner. Exact owner EN/FR VoiceOver steps and structural limitations are documented in docs/accessibility.md; label/Attributes excerpts are in docs/evidence/tvos-about-card-accessibility.txt. TASK-29 remains In Progress.

Implementation code commit: 0e5a284d92d961477d2c92b6066d3d27bd26399d on task-29-tvos-about-voiceover. No PR opened. Test guard reports no guarded changes, so no Test-guard-approved marker is needed.

AC3 verified: full CanadianHamTV xbuild suite PASS, 26/26 (8 unit + 18 UI), including the unmodified default accessibility audits; UI duration 475.474 seconds (under 30 minutes). Command (nohup background; grep polling, shared build lock respected):
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHamTV -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' -resultBundlePath /Users/david/.cache/task-29/tvos-full.xcresult test CODE_SIGNING_ALLOWED=NO
Per-test full-suite results:
CanadianHamTVTests.CanadianHamTVTests.testAppBundleContainsOnlyBasicQuestionBankResources: PASS (1.186s)
CanadianHamTVTests.CanadianHamTVTests.testBundledQuestionBankLoadsForTVApp: PASS (0.031s)
CanadianHamTVTests.CanadianHamTVTests.testTVAboutCardTextKeepsHeadingOnTitleAndEnglishOnLegalBodyRuns: PASS (0.001s)
CanadianHamTVTests.CanadianHamTVTests.testTVAboutCardTextUsesInterfaceLanguageForNonLegalBody: PASS (0.001s)
CanadianHamTVTests.CanadianHamTVTests.testTVHintLadderHelpRecordingAndLessonAnchors: PASS (0.539s)
CanadianHamTVTests.CanadianHamTVTests.testTVPracticeQuestionDrawStaysInCategoryAndShufflesAnswers: PASS (0.019s)
CanadianHamTVTests.CanadianHamTVTests.testTVPracticeSeedsVaryAcrossSessionIDs: PASS (0.019s)
CanadianHamTVTests.CanadianHamTVTests.testTVReferencePointersAreHiddenBecauseReferenceSheetIsUnavailable: PASS (0.001s)
CanadianHamTVUITests.CanadianHamTVUITests.testAboutAccessibilityAuditLightAndDark: PASS (16.652s)
CanadianHamTVUITests.CanadianHamTVUITests.testAboutCardsExposeCombinedLabelsInEnglish: PASS (10.915s)
CanadianHamTVUITests.CanadianHamTVUITests.testAboutCardsExposeCombinedLabelsInFrench: PASS (10.587s)
CanadianHamTVUITests.CanadianHamTVUITests.testAboutLowerSectionsReachableWithRemote: PASS (14.087s)
CanadianHamTVUITests.CanadianHamTVUITests.testAboutShowsReleaseAttributionDisclaimerAndBankVersion: PASS (5.238s)
CanadianHamTVUITests.CanadianHamTVUITests.testCategoryGridAccessibilityAuditLightAndDark: PASS (14.457s)
CanadianHamTVUITests.CanadianHamTVUITests.testCategoryGridNavigatesToMorse: PASS (8.809s)
CanadianHamTVUITests.CanadianHamTVUITests.testFocusRingEvidenceScreenshots: PASS (64.489s)
CanadianHamTVUITests.CanadianHamTVUITests.testLayoutEvidenceScreenshots: PASS (84.753s)
CanadianHamTVUITests.CanadianHamTVUITests.testLessonTryItRevealsOnRemoteFocusAndSelectWithAccessibilityLightAndDark: PASS (89.976s)
CanadianHamTVUITests.CanadianHamTVUITests.testMorseAccessibilityAuditLightAndDark: PASS (14.458s)
CanadianHamTVUITests.CanadianHamTVUITests.testMorseScreenShowsPlaybackControls: PASS (7.290s)
CanadianHamTVUITests.CanadianHamTVUITests.testPracticeAccessibilityAuditLightAndDark: PASS (31.136s)
CanadianHamTVUITests.CanadianHamTVUITests.testPracticeHintLadderLessonLinkAndAudit: PASS (56.864s)
CanadianHamTVUITests.CanadianHamTVUITests.testPracticeInteractionUsesConfiguredLanguageShowsFeedbackAndAdvances: PASS (13.720s)
CanadianHamTVUITests.CanadianHamTVUITests.testPracticeKeepsQuestionBankWhenContentLibraryFails: PASS (4.746s)
CanadianHamTVUITests.CanadianHamTVUITests.testPracticeOneLevelHintHasNoHint2AndNonPracticeScreensHaveNoHint: PASS (14.842s)
CanadianHamTVUITests.CanadianHamTVUITests.testRemoteMenuReturnsPracticeAndAboutToCategoryGrid: PASS (12.456s)

Other validation: baseline EN/FR captures passed 2/2; targeted About + attributed-run tests passed 7/7 (testAboutAccessibilityAuditLightAndDark, testAboutCardsExposeCombinedLabelsInEnglish/French, testAboutShowsReleaseAttributionDisclaimerAndBankVersion, testAboutLowerSectionsReachableWithRemote, testTVAboutCardTextKeepsHeadingOnTitleAndEnglishOnLegalBodyRuns, testTVAboutCardTextUsesInterfaceLanguageForNonLegalBody). Final EN/FR UI assertion refinements (exact approved RBR-4/source references and aggregate-only Attributes Header check) passed 2/2 in about-final-labels.xcresult; production code unchanged from the full run. All xbuild logs/result bundles are under /Users/david/.cache/task-29/ (about-baseline, about-targeted, tvos-full, about-final-labels). Final captures are committed in docs/evidence/tvos-about-card-accessibility.txt; full debug descriptions are keepAlways attachments in xcresults.

pnpm check:apple-l10n PASS (catalogue unchanged); node scripts/check-apple-text-sources.ts PASS; pnpm check:apple-network PASS (78 Swift files; initial new assertion used a broad URL prefix, corrected to the exact already-approved RBR-4 citation without changing any allowlist); node scripts/check-test-guard.mjs --self-test PASS; node scripts/check-test-guard.mjs --base df921d06 --head 0e5a284d92d961477d2c92b6066d3d27bd26399d PASS/no guarded changes; git diff --check PASS. XcodeGen ran twice; generated project files match byte-for-byte. Focused card widths/heights match all ten baseline EN/FR captures; scroll Y origins vary by up to 5 pt while settling, so no exact-position claim is made.

Skipped iOS/macOS/visionOS test suites because changed app/helper source and tests compile only in the tvOS targets (project.yml verified). No web/package changes, so no unrelated pnpm typecheck/test suites. No visual restyling, official text changes, catalogue edits, audit exceptions or new networking.

AC1/AC2 remain unchecked: structural verification done; listening check pending owner. Follow the exact EN/FR tvOS VoiceOver steps in docs/accessibility.md; verify title-only heading speech and an English voice for every attribution/disclaimer legal paragraph before checking those criteria. TASK-29 intentionally remains In Progress pending that human verification and review.

Review notes applied (coordinator): legal paragraphs tagged en-CA via BankLanguage.english.accessibilityLanguageCode (matches the project's convention); the UI Header check is commented as evidence only (the baseline showed no Header either); listening steps now say a physical Apple TV is required (VoiceOver isn't in the tvOS Simulator), add the Back triple-click shortcut and the correct Language menu path, and give the expected speech plus what each outcome means. AC3 is unticked: the change was made pre-emptively (tvOS suite 26/26); whether VoiceOver honours the inline heading level is an untested bet that the owner's listening check settles. If no heading is spoken anywhere, the coordinator decides whether to add a separate heading element.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented one attributed accessibility label per tvOS About card, with title-only heading metadata, normal body runs, English legal-body language tags, and no aggregate Header trait. Existing focus/visual layout and audits remain intact; no guarded modifiers. Full tvOS suite 26/26, targeted About/metadata 7/7, and final EN/FR structural tests 2/2 pass; localization/text-source/no-network/test-guard checks pass. Structural evidence and owner listening steps are recorded in docs/accessibility.md. AC3 checked; AC1/AC2 and Done deliberately withheld pending owner VoiceOver listening.
<!-- SECTION:FINAL_SUMMARY:END -->
