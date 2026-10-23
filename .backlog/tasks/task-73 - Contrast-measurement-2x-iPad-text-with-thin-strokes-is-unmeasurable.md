---
id: TASK-73
title: 'Contrast measurement: 2x iPad text with thin strokes is unmeasurable'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-23 16:51'
updated_date: '2026-10-23 16:58'
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

Blocked after supervisor-authorized single bounded attempt. Real iPhone red fixture proof:1test failed at XCTUnwrap(nil),exit65,test0.978s,/tmp/task-73-before.log and .xcresult; no build killed. Per-pixel support prototype restores iPad16.336427704401043:1 but falsely passes existing subthreshold-panel15.9942758247219 and cross-core14.426790204267782 fixtures, plus new sparse-edge2x15.9942758247219. Supervisor permitted one final attempt banning ALL significant-bin support/bridge pixels. Full37-method host harness still has same3failures (34pass): offending panel bins are already sub2% (0.92%,0.60%,1.21% respectively), so restriction cannot address it. Bounded prototype /tmp/task-73-bounded-host-tests.swift SHA256 f59ceeb695320b8bed3d37d35f93fb202d83e4f844169ccb6f02d1dbc3ef9bf3; output /tmp/task-73-bounded-host-tests.log. Stopped as instructed. Removed temporary failing test and fixture from worktree; helper/app/tests/resources remain unchanged. No skipped/failing test pushed; evidence docs only. Remains In Progress with all ACs unchecked. Final iPhone class and macOS command not run because no safe implementation was retained.

Evidence retained in docs/testing/task-73-contrast-2x-blocked.md; TASK-71 measurement doc links the blocked investigation. git diff --check passed; git diff67c69cf6 --exit-code -- apps/apple confirms all Apple source/tests/resources/project files byte-identical to start. Test-guard self-test passed. No staged files before documentation commit. No final green class/macOS results claimed. Stopped under the explicit supervisor bounded-attempt instruction, leaving all ACs unchecked and task In Progress.
<!-- SECTION:NOTES:END -->
