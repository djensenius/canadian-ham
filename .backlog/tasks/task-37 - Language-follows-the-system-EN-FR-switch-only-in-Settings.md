---
id: TASK-37
title: Language follows the system; EN/FR switch only in Settings
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 20:54'
updated_date: '2026-10-11 17:34'
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
