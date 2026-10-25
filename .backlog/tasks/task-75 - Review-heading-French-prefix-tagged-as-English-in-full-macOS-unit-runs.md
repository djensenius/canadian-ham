---
id: TASK-75
title: Review heading French prefix tagged as English in full macOS unit runs
status: Done
assignee: []
created_date: '2026-10-25T03:53:00Z'
updated_date: '2026-10-25T03:54:00Z'
labels:
  - bug
  - accessibility
dependencies: []
priority: high
ordinal: 154000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-46.7's lessonQuizReviewHeading built the localized prefix with AttributedString(localized:); in the full macOS unit run (order-dependent) the English title's language spread onto the French prefix, failing testReviewHeadingMarksEnglishFallbackTitleInsideFrenchText on main. Build the prefix as plain localized text and tag it explicitly with the interface language.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The French prefix is tagged with the interface language and the English title with en, deterministically; the full documented macOS unit run passes repeatedly
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Fix: prefix built with String(localized:bundle:) and tagged languageIdentifier fr/en by interface language; title keeps its own language. Full documented macOS unit command passed twice in a row (223/223 each). iPhone 17 Pro testReviewItemsFrenchLargestTypeLightAccessibility passed (239.8 s).
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
The review heading's French prefix is now explicitly tagged, so VoiceOver language switching is deterministic and the unit test is no longer order-dependent.
<!-- SECTION:FINAL_SUMMARY:END -->
