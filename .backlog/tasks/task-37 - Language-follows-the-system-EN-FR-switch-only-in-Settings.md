---
id: TASK-37
title: Language follows the system; EN/FR switch only in Settings
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 20:54'
updated_date: '2026-10-12 02:53'
labels:
  - apple
  - web
dependencies: []
priority: medium
ordinal: 77000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner feedback 2026-10-10: the English/French switch is too prominent. By default the app (UI and ISED question text) follows the system language (fr* → French, otherwise English). The only manual override is in Settings (Apple: native Settings/Preferences screen; web: settings page). Remove the language picker from the category list, practice, compact question screens and mock exams on iOS/iPadOS/macOS and web. tvOS/visionOS: same rule if they show a picker. ISED text stays verbatim.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Apple (iOS/iPadOS/macOS) and web default to the system language with no stored override; fr* locales get French, all others English
- [x] #2 A Language setting (System default / English / Français) exists only in Settings on Apple and web, persists, applies immediately on web, and on Apple applies ISED question text immediately while the full interface language applies on next launch
- [x] #3 No language picker remains on question, practice, mock exam, lesson or category screens on any platform (UI tests updated to assert absence and the Settings path, not deleted)
- [x] #4 Existing stored language preferences migrate sensibly (an explicit previous choice is kept as the override) and export/import still round-trip
- [x] #5 Accessibility audits pass on the changed screens in light and dark; French strings follow docs/french-style.md
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Finish r3 Apple defaults isolation: in-memory/open/reset use injected suites by default, guard standard domain against Apple language key mutations, and remove unused migration-marker test hook.\n2. Fix reset/import/legacy-French edge cases and add targeted unit coverage for reset failure, unchanged-language import, injected-suite import, removed-key adoption, registered-domain ignore, and existing-persistent legacy fr adoption.\n3. Strengthen changed UI teardown and largest-text French Settings coverage, run targeted iOS/macOS unit and changed iOS UI tests, then update notes and mark task-37 Done.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
WIP commit 24f62175: moved Apple/web language preference toward Settings-only, removed tvOS/visionOS prominent pickers, added web language resolution helper/tests, updated schema and converted key UI tests. Validation so far: pnpm typecheck passed; targeted web vitest command passed (it matched 15 files/160 tests due command syntax); pnpm check:schemas passed; apple text-source check passed; pnpm check:apple-l10n waited on xbuild lock and timed out twice, needs rerun. Remaining: fix any compile/test failures from targeted Apple tests, rerun l10n when lock available, add final notes/AC checks/Done.

Validation update: fixed Apple system-language resolver in commit c3bfd149. Commands run: python3 -m json.tool Localizable.xcstrings passed; pnpm typecheck passed; targeted web vitest (src/lib/languagePreference.test.ts src/lib/progressStore.test.ts src/App.test.tsx) passed 3 files/95 tests; pnpm test passed (content-tools, morse-engine, web: 15 files/160 tests); pnpm check:schemas passed; node scripts/check-apple-text-sources.ts passed. Apple xbuild-dependent validation remains blocked by another branch's full iOS suite holding the xbuild lock for >45 min; pnpm check:apple-l10n and targeted iOS xbuild both timed out while waiting, with no test execution for this branch yet.

Queued Apple validation chain under PID 73512: /tmp/task37-apple-l10n.log, ios-ui, ios-unit, mac-unit, tvos-ui, vision-ui logs/exit files. Chain blocks on xbuild lock and stops on first failure; polling at >=10 minute intervals per coordinator guidance.

Final validation passed:
- pnpm typecheck
- pnpm test
- pnpm --filter @canadian-ham/web exec vitest run src/lib/languagePreference.test.ts src/lib/progressStore.test.ts src/App.test.tsx (3 files / 95 tests)
- pnpm check:schemas
- node scripts/check-apple-text-sources.ts
- pnpm check:apple-l10n (/tmp/task37-apple-l10n-rerun3.log, exit 0)
- iOS UI targeted: testFrenchSystemLanguageNavigatesMainScreensAndAuditsHomeAndPractice, testCanPracticeInFrenchAndSeeFeedback, testLanguagePickerIsAbsentOnCategoryListAndPractice, testLanguagePickerIsAbsentOnCompactQuestionScreensAndMorse, and light/dark core/practice/learn/mock accessibility audits (/tmp/task37-ios-ui-rerun.log, exit 0)
- iOS unit targeted: LocalizationCatalogTests/testLanguagePreferenceResolvesSystemAndOverrides plus ProgressStoreTests language/export/migration tests (/tmp/task37-ios-unit.log, exit 0)
- macOS unit targeted: same language/export/migration tests (/tmp/task37-mac-unit.log, exit 0)
- tvOS targeted: testPracticeInteractionUsesConfiguredLanguageShowsFeedbackAndAdvances and testFocusRingEvidenceScreenshots (/tmp/task37-tvos-ui-rerun3.log, exit 0)
- visionOS targeted: testPracticeInteractionUsesConfiguredLanguageShowsFeedbackAndAdvances (/tmp/task37-vision-ui.log, exit 0)

Review r1 reopened task-37. Coordinator decisions recorded: H1 maps old Apple stored preferences language "en" to "system" once behind a UserDefaults migration marker while preserving stored "fr" and later explicit English choices; H2 uses AppleLanguages on iOS/iPadOS/macOS so interface language changes after restart while ISED question text changes immediately. Full suites remain deferred to merge per testing policy; this fix round will run targeted tests only.

Review-fix implementation complete in commits f36e0c61 and bd032674. Apple: added one-time legacy stored-English migration to system behind a UserDefaults marker, preserved stored French, prevented remapping after a later explicit English choice, writes/removes AppleLanguages for iOS/iPadOS/macOS interface language on next launch, removed SwiftUI locale overrides, added restart notes in iOS/macOS Settings, tightened preferences.language import validation including explicit null, restored tvOS automatic Next question focus assertion, removed dead TVEvidenceFocus.language, and added Apple migration/import/settings/UI tests. Web: resolves system to the first supported preferred locale, mirrors explicit language preferences to localStorage to avoid load flash, keeps system clearing the mirror, removed dead language toggle strings/CSS, uses the current interface language for file-read errors, and added language import/round-trip tests. Notes: Apple question text switches immediately; Apple interface/VoiceOver/menu/window localization follows AppleLanguages on next launch; web still switches immediately. tvOS/visionOS remain system-only except debug launch arguments. Older exports without preferences.language import as system, matching theme. Full Apple suites remain deferred to merge per policy.

Validation passed in this fix round: git diff --check; pnpm typecheck; pnpm test; pnpm --filter @canadian-ham/web exec vitest run src/lib/languagePreference.test.ts src/lib/progressStore.test.ts src/App.test.tsx (3 files / 97 tests); pnpm check:schemas; node scripts/check-apple-text-sources.ts; pnpm check:apple-l10n; targeted iOS unit xbuild for LocalizationCatalogTests/testLanguagePreferenceResolvesSystemAndOverrides plus ProgressStoreTests language migration/import/export tests (8 tests); targeted macOS unit xbuild for the same language/import/export tests plus NativeSettings language binding (9 tests); targeted iOS UI xbuild for French system language/questions, Settings language path/restart note/French feedback title, picker absence, regular-width picker absence, and changed navigation test (5 tests); targeted tvOS UI xbuild for practice language/focus/advance (1 test). VisionOS targeted UI rerun was attempted twice but timed out waiting for the xbuild lock before execution; the branch still compiled visionOS during pnpm check:apple-l10n.

Review r2 reopened task-37. Addressing N1-N6 plus L4/L6/L8 with targeted tests only per policy; full suites remain deferred to merge.

Review r2 fixes complete in commits 1defa682 and f65b26b. Apple no longer applies AppleLanguages on every launch: it writes only on in-app language changes/import/reset and the one-time legacy stored-French migration, records a last-applied value, and adopts differing app-domain AppleLanguages from iOS/macOS Settings into stored preferences. Legacy English migration save failures no longer block startup and retry because the marker remains unset. UI cleanup adds teardown for the French feedback flow, verifies the next compact home test passes immediately after it, covers choosing System default after a French relaunch (English question stem immediately plus restart note), covers hidden restart note, and checks the Settings language control at largest accessibility text size. Web cleanup removed dead interface-language messages/helpers/tests. Catalogue ordering now restores the unrelated keys to main order and keeps the new language import key in sorted import-preference order. Notes for PR: under DebugCloudKit, the legacy-language migration marker is per device, so a first launch on another synced device can still remap a synced explicit English preference before its marker exists; legacy stored Apple fr now becomes an interface French next-launch preference, not just question-language French. Validation passed: git diff --check; pnpm typecheck; targeted web vitest (languagePreference/progressStore/App/i18n) 98 tests; pnpm test 160 web tests plus package tests; pnpm check:schemas; node scripts/check-apple-text-sources.ts; targeted iOS unit ProgressStore language tests 9/9; targeted macOS unit ProgressStore/NativeSettings language tests 10/10; targeted iOS UI French feedback followed immediately by compact home test 2/2; targeted iOS UI System default/restart note, hidden note, largest accessibility text size, and regular-width absence path 4/4. pnpm check:apple-l10n was attempted twice after the catalogue reorder but timed out waiting on the xbuild lock after the text-source/export phases; visionOS targeted UI was not retried because the lock remained unavailable.

Review r3 reopened task-37. N1-N4 are confirmed fixed; addressing blocking M-1 plus L-a/L-b, T-1..T-4, L8, and teardown robustness with targeted tests only. Coordinator is handling apple-l10n and visionOS.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Addressed review r2 for task-37: Apple now preserves user per-app language choices from iOS/macOS Settings by adopting app-domain AppleLanguages instead of overwriting them at launch, isolates AppleLanguages tests with injected defaults, makes legacy migration retry-safe, resets French UI-test state, and adds UI coverage for System default, restart-note visibility, largest accessibility text size, and the compact next-test sequence. Removed dead web language helpers and restored localization catalogue ordering. Verified with targeted web/package/schema/text-source/iOS/macOS unit and iOS UI checks; apple-l10n and visionOS remain blocked by the shared xbuild lock and should be rerun by the coordinator/reviewer when free.
<!-- SECTION:FINAL_SUMMARY:END -->
