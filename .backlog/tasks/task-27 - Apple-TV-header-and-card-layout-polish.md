---
id: TASK-27
title: Apple TV header and card layout polish
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-02 03:45'
updated_date: '2026-10-02 04:40'
labels:
  - apple
  - tvos
  - design
milestone: m-0
dependencies: []
priority: low
ordinal: 51000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: task-24 screenshots show the tvOS practice header using about a third of the screen: the title wraps to three hyphenated lines ('Regula- / tions and / Policies') beside the language toggle, and the longer official French category names make it worse. Category card titles also hyphenate awkwardly ('Règle-ments', 'Exploita-tion') and cards in a row have uneven heights (B-003 is taller).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The practice header title fits on at most two lines in English and French without mid-word hyphenation at the default text size (e.g. layoutPriority, or controls stacked below the title)
- [x] #2 Category card titles don't hyphenate mid-word, and cards in the same row share a height
- [x] #3 Updated light/dark screenshots in docs/evidence and the tvOS suite (including accessibility audits) pass via xbuild
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Adjust tvOS category grid/card sizing so category titles wrap at word boundaries without mid-word hyphenation and row cards share a consistent height while preserving task-24 focus-ring clearance.
2. Rework the tvOS practice header layout so the category title receives priority, wraps to at most two non-hyphenated lines in English and French, and controls remain accessible.
3. Capture lean light/dark English/French PNG evidence for category grid and practice header under docs/evidence and manually open each image.
4. Run Apple text-source checking and the full tvOS xbuild suite including accessibility audits, then record evidence, check ACs, summarize, mark task-27 Done, and leave the branch clean.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented tvOS header/card polish in apps/apple/Platforms/tvOS/CanadianHamTVApp.swift: TVTopBar now gives the title full width above controls with a two-line limit; category grid uses three columns, fixed 280-point card height, and up to three word-wrapped title lines. Evidence captured under docs/evidence for category grid and practice header in en/fr and light/dark; opened all eight PNGs and confirmed practice header titles are one line in English and two lines in French with no mid-word hyphenation, category card titles wrap at word boundaries, focused B-001 ring remains unclipped, and first-row cards share height. Validation passed: node scripts/check-apple-text-sources.ts; full tvOS xbuild suite passed with 3 CanadianHamTVTests plus 6 CanadianHamTVUITests including category/practice/about accessibility audits.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Polished tvOS practice header and category grid/card layout. Header controls now sit below the full-width title, category cards use a wider three-column grid with fixed row/card height and non-hyphenated wrapping, and docs/evidence includes en/fr light/dark PNGs for category grid and practice header. Verified with Apple text-source checking and the full tvOS xbuild test suite including accessibility audits.
<!-- SECTION:FINAL_SUMMARY:END -->
