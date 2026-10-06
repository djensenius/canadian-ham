---
id: TASK-12.18
title: 'Sending practice: grading and teardown edge cases'
status: To Do
assignee: []
created_date: '2026-10-06 11:55'
labels: []
dependencies:
  - TASK-12.7
parent_task_id: TASK-12
priority: low
ordinal: 68000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: Copilot's last PR #144 (task-12.7) review listed four smaller items in unchanged code. Apple doesn't cancel a pending character finalisation when leaving the sending screen. On both platforms, grading at the deadline or by hand doesn't first finish a key that is still held, so the held element is left out and a held paddle keeps sounding. The Apple diff summary's French plural follows only the total count ('1 erronées').
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Leaving the Apple sending screen cancels and clears the pending character finalisation
- [ ] #2 Web and Apple grading first releases all keys (finishing a held straight-key element) and stops playback, with tests
- [ ] #3 The Apple Morse diff summary agrees in French for each count (plural per component, or count-invariant labels), with a LocalizationCatalogTests assertion
<!-- AC:END -->
