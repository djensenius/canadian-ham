---
id: TASK-12
title: Morse code 5 wpm trainer
status: To Do
assignee: []
created_date: '2026-10-01 02:27'
updated_date: '2026-10-02 01:11'
labels:
  - web
  - apple
  - 'legacy:T-702'
milestone: m-1
dependencies: []
ordinal: 20000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Investigate and later build a Morse code 5 wpm trainer module (Koch/Farnsworth drills, offline audio, visual and haptic alternatives, a practice exam in the Canadian format, tap-based sending practice without microphone access). Legacy: T-702.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The research is source-checked and committed under docs/proposals/
- [x] #2 The owner's decisions on placement, default speed and sending input are recorded
- [ ] #3 Implementation subtasks are created from the approved plan
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner decisions (2026-10-02, owner accepted all recommendations in docs/proposals/morse-trainer.md):
1. Placement: an in-app Morse route/tab in this monorepo (web and Apple), turned off by default until v1 Basic ships; not a separate app.
2. Default speed: 15 wpm characters at 5 wpm effective, with a one-tap 'ISED exam' preset at 12/5. Effective speed is clamped to at most the character speed.
3. Sending input: tap timing on keyboard or touch; no microphone permission.
4. Exam timing: default the mock exam to the PARIS-calibrated 12/5 profile (isedParis), with 'RIC-1 literal spacing (about 7.9 wpm, harder)' as an option.
5. Haptics: only where supportsHaptics is true (in practice iPhone); no haptic UI on tvOS or visionOS.
<!-- SECTION:NOTES:END -->
