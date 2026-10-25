---
id: TASK-76
title: 'French Morse dah term: make ''points et traits'' consistent with ''Tiret'''
status: To Do
assignee: []
created_date: '2026-10-25T22:27:00Z'
labels:
  - l10n
dependencies: []
priority: low
ordinal: 161000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The app's Dash key translates to 'Tiret', and the watch uses 'tiret'. One iOS Morse string (Meet %@… dits and dahs) still says 'points et traits'. Pick one French term for dah across iOS, macOS, tvOS, visionOS and watch ('trait' is common in French Morse usage; 'tiret' is what the app uses now) and make every string consistent. Found in the TASK-14.5 review.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 One French dah term is used in every Apple string-catalogue entry and the web French copy where Morse appears
- [ ] #2 pnpm check:apple-l10n and the affected Apple l10n tests pass
<!-- AC:END -->
