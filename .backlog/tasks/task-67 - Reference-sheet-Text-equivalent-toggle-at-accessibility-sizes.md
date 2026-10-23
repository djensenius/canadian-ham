---
id: TASK-67
title: Reference sheet Text equivalent toggle at accessibility sizes
status: To Do
assignee: []
created_date: '2026-10-22 03:34'
labels:
  - accessibility
  - tests
dependencies: []
ordinal: 147000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-44.4 review note: in the stacked accessibility-size layout VoiceOver reads 'Text equivalent' twice (visible text then switch) and tapping the text does not toggle; no test taps the switch at AX sizes. Also the medium-detent test's local textClipped handler hits its cap of 5 every run; list the ignored elements and consider a test-stable layout.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 At accessibility sizes the toggle exposes one accessible element with its label, the label is tappable, and a UI test toggles it at AX-XXXL
- [ ] #2 The medium-detent test's ignored findings are listed in the task notes; the cap has headroom or the cause is reduced
<!-- AC:END -->
