---
id: TASK-8
title: Apple accessibility follow-ups
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-01 21:59'
labels:
  - apple
  - accessibility
milestone: m-0
dependencies: []
ordinal: 15000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Reviews of the Apple accessibility and French interface lanes approved the work but noted issues that automated audits can't catch: a VoiceOver announcement that may be cut off when focus moves to the results heading, a tvOS focus ring that has only been proven in code (not seen), and English error detail read in a French voice. They need manual or targeted verification so v1 doesn't ship with them.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 After mock exam submission, focus moves to the results heading on appear and the announcement isn't cut off (verified with VoiceOver)
- [ ] #2 The tvOS 'Next question' focus ring visibly renders (screenshot or manual check recorded)
- [ ] #3 English system error details (e.g. QuestionBankLoadError) are tagged en or localised in the French UI
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Update mock exam results so the results heading owns the spoken submission summary and receives VoiceOver focus from onAppear after SwiftUI has laid out the result view, avoiding a separate announcement that focus could interrupt; cover the exposed heading label in XCUITest and document the remaining manual VoiceOver smoke check.
2. Extend tvOS UI coverage to capture a screenshot after the Next question button receives focus, save exported evidence under docs/evidence, and verify the focus ring remains rendered.
3. Tag English error detail text with the English language identifier in the shared Apple LocalizedErrorMessageText pattern (including tvOS), then run apple l10n and affected/full xbuild checks before finalizing.
<!-- SECTION:PLAN:END -->
