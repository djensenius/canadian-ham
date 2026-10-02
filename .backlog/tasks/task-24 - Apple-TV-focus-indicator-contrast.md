---
id: TASK-24
title: Apple TV focus indicator contrast
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-02 01:10'
updated_date: '2026-10-02 01:13'
labels:
  - apple
  - accessibility
  - tvos
milestone: m-0
dependencies: []
priority: medium
ordinal: 32000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the task-8 review found the tvOS focus ring (#8F2E1D) sits on the #A53A2A primary button at roughly 1.3:1, so focus shows mostly through the button growing. Answer and category buttons use the same colour pairing. tvOS users navigate entirely by focus, so the focused control must be clearly distinguishable (WCAG 2.2 SC 1.4.11 non-text contrast, with SC 2.4.13 focus appearance as the target). Fix the focus appearance across tvOS buttons in light and dark modes, keeping the ink-brush-on-cream design.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Every focusable tvOS control's focus indicator has at least 3:1 contrast against both the unfocused state and the adjacent background, in light and dark modes, with the measured values recorded in docs/accessibility.md
- [ ] #2 The indicator does not rely on scale alone (for example a light outer ring or a contrasting outline) and still works with Reduce Motion on
- [ ] #3 tvOS UI tests and the tvOS accessibility audit pass via xbuild, and updated screenshots of focused primary, answer and category buttons are committed under docs/evidence
<!-- AC:END -->
