---
id: TASK-27
title: Apple TV header and card layout polish
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-02 03:45'
updated_date: '2026-10-02 04:29'
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
- [ ] #1 The practice header title fits on at most two lines in English and French without mid-word hyphenation at the default text size (e.g. layoutPriority, or controls stacked below the title)
- [ ] #2 Category card titles don't hyphenate mid-word, and cards in the same row share a height
- [ ] #3 Updated light/dark screenshots in docs/evidence and the tvOS suite (including accessibility audits) pass via xbuild
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Adjust tvOS category grid/card sizing so category titles wrap at word boundaries without mid-word hyphenation and row cards share a consistent height while preserving task-24 focus-ring clearance.\n2. Rework the tvOS practice header layout so the category title receives priority, wraps to at most two non-hyphenated lines in English and French, and controls remain accessible.\n3. Add/adjust UI-test coverage where useful, then capture lean light/dark English/French PNG evidence for category grid and practice header under docs/evidence and manually open each image.\n4. Run Apple text-source checking and the full tvOS xbuild suite including accessibility audits, then record evidence, check ACs, summarize, mark task-27 Done, and leave the branch clean.
<!-- SECTION:PLAN:END -->
