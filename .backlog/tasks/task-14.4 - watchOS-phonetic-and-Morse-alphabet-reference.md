---
id: TASK-14.4
title: watchOS phonetic and Morse alphabet reference
status: To Do
assignee: []
created_date: '2026-10-25T17:02:00Z'
labels:
  - apple
  - watchos
milestone: m-1
dependencies:
  - TASK-14.3
documentation:
  - docs/proposals/watchos-companion.md
parent_task_id: TASK-14
type: feature
ordinal: 158000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
A glanceable reference is useful between drills without the long lesson-reader navigation excluded from watch v1. Source phonetic spellings from the existing L-002-01 voice procedure table and Morse symbols from morse-swift; do not invent a second Morse mapping or copy the lesson/figure bundle.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The watch home navigation exposes a scrollable A-Z reference showing each letter, its standard phonetic spelling and its Morse dots/dashes, plus the Morse digits 0-9.
- [ ] #2 Reference values match the existing L-002-01 phonetic table and morse-swift morseCodeTable; unit tests cover all 26 letters and 10 digits with no duplicate or missing entries.
- [ ] #3 Rows remain readable and reachable on the smallest supported watch at large Dynamic Type, with VoiceOver labels that read letter/phonetic word and intelligible dot/dash names rather than punctuation alone.
- [ ] #4 Targeted watch unit/UI tests through xbuild cover reference entry, scrolling to the last row and back navigation; no lesson/figure assets, persistence or networking are added, and results are recorded.
<!-- AC:END -->
