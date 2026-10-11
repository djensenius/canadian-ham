---
id: TASK-42
title: Morse course lower audit is flaky (Contrast failed on settings description)
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-11 18:37'
updated_date: '2026-10-11 18:38'
labels:
  - apple
  - testing
dependencies: []
priority: high
ordinal: 92000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
On main after the Morse polish merge, testAccessibilityAuditMorseCourseLessonAndSummaryLight and Dark fail intermittently with 'Contrast failed' (seen in task-36's pre-merge full iOS run at d25a368, 2026-10-11; the last element checked before the error was the Morse settings description 'These local settings control Morse tone, timing, and playback volume without network access.'). They passed in the Morse branch's own full run and 3 targeted runs. Likely a position-dependent false positive (text near an edge or under the bar) that the precise-positioning helper doesn't fully prevent.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The failing element and its on-screen position at failure are identified from the xcresult (exported issue and screenshot) and recorded
- [ ] #2 Root cause fixed with test-only positioning (or a genuine contrast fix if the colours really fail, measured), without loosening the audit, adding handlers or changing visuals without owner approval
- [ ] #3 Both audits pass 5 consecutive targeted runs each
<!-- AC:END -->
