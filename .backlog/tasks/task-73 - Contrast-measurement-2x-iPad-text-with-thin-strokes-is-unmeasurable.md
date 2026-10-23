---
id: TASK-73
title: 'Contrast measurement: 2x iPad text with thin strokes is unmeasurable'
status: To Do
assignee: []
created_date: '2026-10-23 16:51'
labels:
  - accessibility
  - tests
dependencies: []
priority: high
ordinal: 152000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Follow-up to TASK-71. On iPad Pro 13-inch (2x), auditVerifyingMeasuredContrast reports 'unmeasurable' for the fully visible, high-contrast line 'Given: initial report = S9 plus 19 dB; transmitter power falls from 48 W to 24 W.' (dark ink on paper; neighbouring lines in the same audit measure 16.34:1). Likely the 2-pixel '=' / ';' / thin stroke components lack boundary support at 2x scale. Fixture: /tmp/t73-fixtures/ipad-given-line-light-2x.png (copied from the TASK-46.5 iPad light run).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The iPad 2x fixture measures >= 4.5:1 (diagnose which rule rejects it and fix it in a scale-aware, conservative way)
- [ ] #2 Every existing adversarial regression in UITestContrastMeasurementTests still returns nil or < 4.5, and the existing real screenshots still measure as before
- [ ] #3 Add 2x variants of at least the inset-panel, chained-blend, partial-overlap and mixed-contrast adversarial fixtures, all failing safe
- [ ] #4 iPhone 17 Pro UITestContrastMeasurementTests pass and the documented macOS unit command builds and passes
<!-- AC:END -->
