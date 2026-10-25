---
id: TASK-75
title: Review heading French prefix tagged as English in full macOS unit runs
status: To Do
assignee: []
created_date: '2026-10-25T03:53:00Z'
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
- [ ] #1 The French prefix is tagged with the interface language and the English title with en, deterministically; the full documented macOS unit run passes repeatedly
<!-- AC:END -->
