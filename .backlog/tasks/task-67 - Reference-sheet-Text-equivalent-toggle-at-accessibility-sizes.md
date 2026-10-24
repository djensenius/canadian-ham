---
id: TASK-67
title: Reference sheet Text equivalent toggle at accessibility sizes
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-22 03:34'
updated_date: '2026-10-24 20:25'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the reference toggle and scoped medium audit; preserve the approved audit rules and default-size appearance.
2. Implement a single native labelled Toggle with an adaptive accessibility-size layout; add AX-XXXL label-tap, single-element and state coverage.
3. Inventory medium-detent ignored findings and reduce their cause or provide bounded headroom without widening exception eligibility.
4. Run targeted iPhone/iPad reference-sheet tests, documented macOS unit command, localization, text-source and test-guard checks via nohup/polling. Record per-test evidence, complete ACs, commit and push without opening a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented a native labelled Toggle with a custom accessibility-size style: stacked visible label/native switch, tappable label, one native accessibility representation. Default-size switch remains native. AX-XXXL now checks one switch, exact label/no duplicate static text, and taps the label on/off with state/content assertions. Medium audit eligibility is unchanged; bounded cap 5→8 adds three findings of headroom, and each accepted finding now records identifier, label and frame in a keepAlways attachment. Targeted iPhone/iPad, documented macOS unit command, l10n/text/guard runner started with nohup (/tmp/task67-checks.log); no full simulator suites.
<!-- SECTION:NOTES:END -->
