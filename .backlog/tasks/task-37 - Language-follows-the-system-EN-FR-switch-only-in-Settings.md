---
id: TASK-37
title: Language follows the system; EN/FR switch only in Settings
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 20:54'
updated_date: '2026-10-11 22:27'
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
- [ ] #1 Apple (iOS/iPadOS/macOS) and web default to the system language with no stored override; fr* locales get French, all others English
- [ ] #2 A Language setting (System default / English / Français) exists only in Settings on Apple and web, persists, applies immediately on web, and on Apple applies ISED question text immediately while the full interface language applies on next launch
- [ ] #3 No language picker remains on question, practice, mock exam, lesson or category screens on any platform (UI tests updated to assert absence and the Settings path, not deleted)
- [ ] #4 Existing stored language preferences migrate sensibly (an explicit previous choice is kept as the override) and export/import still round-trip
- [ ] #5 Accessibility audits pass on the changed screens in light and dark; French strings follow docs/french-style.md
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Reopen task-37 and address review findings H1/H2/M1/M2 plus coordinator-approved lows within existing scope.
2. Implement Apple migration to map old stored en defaults to system once, wire iOS/iPadOS/macOS Settings language to AppleLanguages for next-launch interface changes, and remove SwiftUI locale overrides.
3. Tighten Apple import validation/null handling, restore weakened UI assertions, add required Apple/web tests and small cleanup for approved lows.
4. Run targeted web/package/schema/l10n/text-source/Apple unit and UI checks, then re-check ACs with evidence and move the task back to Done.
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
<!-- SECTION:NOTES:END -->
