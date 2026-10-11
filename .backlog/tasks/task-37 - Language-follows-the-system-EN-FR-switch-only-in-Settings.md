---
id: TASK-37
title: Language follows the system; EN/FR switch only in Settings
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 20:54'
updated_date: '2026-10-11 18:32'
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
- [ ] #2 A Language setting (System default / English / Français) exists only in Settings on Apple and web, persists, and applies immediately
- [ ] #3 No language picker remains on question, practice, mock exam, lesson or category screens on any platform (UI tests updated to assert absence and the Settings path, not deleted)
- [ ] #4 Existing stored language preferences migrate sensibly (an explicit previous choice is kept as the override) and export/import still round-trip
- [ ] #5 Accessibility audits pass on the changed screens in light and dark; French strings follow docs/french-style.md
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add shared Apple/web language preference models with system/en/fr resolution from platform preferred languages, preserving existing en/fr records as explicit overrides and defaulting newly-created preferences to system.
2. Move the manual selector into Settings only (Apple SettingsView/NativeSettingsView and web settings), remove question-language controls from headers/question flows, and wire immediate UI/question-language updates through the effective resolved language.
3. Keep export/import compatible by accepting old exports without language and including the new optional setting where schema/types require it.
4. Convert existing Apple and web tests from picker-presence coverage to absence-on-content-screens plus Settings persistence/system-language coverage, including tvOS/visionOS if pickers exist.
5. Run targeted unit/UI/web/l10n/text-source checks, record evidence in Backlog, then finalize ACs and Done.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
WIP commit 24f62175: moved Apple/web language preference toward Settings-only, removed tvOS/visionOS prominent pickers, added web language resolution helper/tests, updated schema and converted key UI tests. Validation so far: pnpm typecheck passed; targeted web vitest command passed (it matched 15 files/160 tests due command syntax); pnpm check:schemas passed; apple text-source check passed; pnpm check:apple-l10n waited on xbuild lock and timed out twice, needs rerun. Remaining: fix any compile/test failures from targeted Apple tests, rerun l10n when lock available, add final notes/AC checks/Done.

Validation update: fixed Apple system-language resolver in commit c3bfd149. Commands run: python3 -m json.tool Localizable.xcstrings passed; pnpm typecheck passed; targeted web vitest (src/lib/languagePreference.test.ts src/lib/progressStore.test.ts src/App.test.tsx) passed 3 files/95 tests; pnpm test passed (content-tools, morse-engine, web: 15 files/160 tests); pnpm check:schemas passed; node scripts/check-apple-text-sources.ts passed. Apple xbuild-dependent validation remains blocked by another branch's full iOS suite holding the xbuild lock for >45 min; pnpm check:apple-l10n and targeted iOS xbuild both timed out while waiting, with no test execution for this branch yet.

Queued Apple validation chain under PID 73512: /tmp/task37-apple-l10n.log, ios-ui, ios-unit, mac-unit, tvos-ui, vision-ui logs/exit files. Chain blocks on xbuild lock and stops on first failure; polling at >=10 minute intervals per coordinator guidance.
<!-- SECTION:NOTES:END -->
