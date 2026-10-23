---
id: TASK-73
title: 'Contrast measurement: 2x iPad text with thin strokes is unmeasurable'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-23 16:51'
updated_date: '2026-10-23 16:53'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Bundle the unaltered iPad 2x element fixture; add and run a >=4.5 regression against the unchanged helper.
2. Instrument a host-only diagnostic copy to identify rejecting colour bins/components, boundary support and blend classifications. Implement the smallest scale-aware conservative correction without changing 50% support or minimum-ratio semantics.
3. Add 2x inset-panel, chained-blend, partial-overlap and mixed-bold/grey adversarial proofs, retaining all existing tests and 3x screenshots; stop/escalate if safety conflicts.
4. Run targeted iPhone17Pro measurement class and documented macOS unit command through nohup/xbuild with grep polling. Document diagnostics, per-test evidence and residual limits; finalize ACs, commit and push (no PR).

5. Supervisor-approved diagnostic refinement: sub-2% support uses individually valid pixels (unchanged fraction<=.9/RGB8/core+background distance), same-core 4-connected background reachability through valid pixels only. Significant-blend exclusions remain globally strict. Scale-derived radius is capped at2; keep4px spatial floor or tighten. Add a2x inset-panel proof with some qualifying edge support but <50% boundary support. Stop if any adversarial proof passes.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Pre-fix host diagnostics /tmp/task-73-diagnostics.log: only lower equals-sign component295 (16px at296,26...311,26) fails: boundary16,supported4,otherRetained0. Edge bin8422 count183 has1 pixel elsewhere without radius2 background; bin14796 count35 has1 elsewhere without radius2 core. Thus global bin veto, not label or low ratio. Supervisor approved per-pixel subthreshold support refinement under unchanged colour/distance/reachability/share/ratio constraints; invalid pixels cannot bridge. Red xbuild fixture proof queued with nohup; no source-helper edits until it completes.
<!-- SECTION:NOTES:END -->
