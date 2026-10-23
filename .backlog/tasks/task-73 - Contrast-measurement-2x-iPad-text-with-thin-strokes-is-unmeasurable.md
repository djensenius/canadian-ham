---
id: TASK-73
title: 'Contrast measurement: rounded-control measurement'
status: Done
assignee:
  - '@worker'
created_date: '2026-10-23 16:51'
updated_date: '2026-10-23 18:10'
labels:
  - accessibility
  - tests
dependencies: []
priority: high
ordinal: 152000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner-delegated decision 2026-10-22, coordinator: narrowly extend TASK-71 measured contrast for button screenshots with rounded ends/corners. The unaltered iPhone 17 Pro 3× Hide answer 1 fixture measures 1.199:1 over the full image because cream page corners and the beige pill are different background tones. Only buttons whose full-image measurement is nil or below4.5 may retry an inner native-pixel crop, retaining all conservative background/minimum-ratio/blend rules. Supervisor refinement: sweep horizontal caps4/6/8/12/16pt (vertical2pt), choose the smallest passing cap, and document excluded end text as a known limit. Non-buttons and existing audit scope remain unchanged. The prior2× iPad thin-stroke investigation remains unresolved; preserve its diagnostics in docs/testing/task-73-contrast-2x-blocked.md rather than adopting its unsafe prototype.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The unaltered 3× rounded-button fixture measures at least4.5 using the smallest passing horizontal cap from4/6/8/12/16pt and vertical2pt; crop and audit path apply only to buttons after a nil or below4.5 full-image measurement
- [x] #2 Low-contrast #9A9A9A pill text and retained low-contrast text beside high-contrast text fail safe; add explicit end-inset exclusion proof and document the limit
- [x] #3 All existing measurements/adversarial regressions remain unchanged for non-buttons; document fixture provenance, inset sweep and unresolved2× thin-stroke limitation without loosening the conservative algorithm
- [x] #4 iPhone17Pro UITestContrastMeasurementTests and the documented macOS unit command pass via nohup/xbuild with grep polling; commit and push branch without a PR
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Preserve2× diagnostic evidence and rescope Backlog to rounded controls. Sweep4/6/8/12/16pt horizontal caps at3× with vertical2pt; use the smallest passing cap (host sweep:6pt).
2. Add a button-gated native-pixel crop fallback and wire the shared audit path with element type and screenshot/frame scale; keep the base algorithm byte-identical. Bundle the unaltered fixture.
3. Add fixture, low-contrast, retained-near-end/middle, excluded-end, non-button, full-image-preservation and invalid-crop proofs; document all crop limits and future TASK-46.5/46.6.1 composite integration.
4. Run the iPhone proof class and macOS unit command through nohup/xbuild and grep polling, plus diff/guard checks. Record per-test results, finalize criteria, commit and push; no PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Pre-fix host diagnostics /tmp/task-73-diagnostics.log: only lower equals-sign component295 (16px at296,26...311,26) fails: boundary16,supported4,otherRetained0. Edge bin8422 count183 has1 pixel elsewhere without radius2 background; bin14796 count35 has1 elsewhere without radius2 core. Thus global bin veto, not label or low ratio. Supervisor approved per-pixel subthreshold support refinement under unchanged colour/distance/reachability/share/ratio constraints; invalid pixels cannot bridge. Red xbuild fixture proof queued with nohup; no source-helper edits until it completes.

Blocked after supervisor-authorized single bounded attempt. Real iPhone red fixture proof:1test failed at XCTUnwrap(nil),exit65,test0.978s,/tmp/task-73-before.log and .xcresult; no build killed. Per-pixel support prototype restores iPad16.336427704401043:1 but falsely passes existing subthreshold-panel15.9942758247219 and cross-core14.426790204267782 fixtures, plus new sparse-edge2x15.9942758247219. Supervisor permitted one final attempt banning ALL significant-bin support/bridge pixels. Full37-method host harness still has same3failures (34pass): offending panel bins are already sub2% (0.92%,0.60%,1.21% respectively), so restriction cannot address it. Bounded prototype /tmp/task-73-bounded-host-tests.swift SHA256 f59ceeb695320b8bed3d37d35f93fb202d83e4f844169ccb6f02d1dbc3ef9bf3; output /tmp/task-73-bounded-host-tests.log. Stopped as instructed. Removed temporary failing test and fixture from worktree; helper/app/tests/resources remain unchanged. No skipped/failing test pushed; evidence docs only. Remains In Progress with all ACs unchecked. Final iPhone class and macOS command not run because no safe implementation was retained.

Evidence retained in docs/testing/task-73-contrast-2x-blocked.md; TASK-71 measurement doc links the blocked investigation. git diff --check passed; git diff67c69cf6 --exit-code -- apps/apple confirms all Apple source/tests/resources/project files byte-identical to start. Test-guard self-test passed. No staged files before documentation commit. No final green class/macOS results claimed. Stopped under the explicit supervisor bounded-attempt instruction, leaving all ACs unchecked and task In Progress.

New approved scope: rounded-control measurement only; previous2× notes remain historical unresolved evidence. Supervisor explicitly requested smallest passing cap among4/6/8/12/16pt. Host-only unchanged-algorithm sweep on452×151px fixture at3×: full1.1993729121750754;4pt1.1994004247924492;6pt13.620392055674973;8pt13.620385825726265;12pt13.620313173154122;16pt13.620293214245946. Selected6pt; vertical2pt. Sweep/log /tmp/task-73-control-inset-sweep.{swift,log}. No base-algorithm changes approved.

Rounded-control implementation0a617ef6 and per-test evidence ddcedc84 committed and pushed to origin/task-73-contrast-2x (no PR). Added measuredControlTextContrast(in:scale:isButton:) with6pt horizontal/2pt vertical native crop only for buttons after nil/below4.5 full measurement. Base measuredTextContrast and all31 old test methods byte-identical to57f7991a; no app/project membership changes. Actual452×151 fixture: full1.1993729121750754, selected6pt crop13.620392055674973. Eight new methods cover fixture/non-button equality, low contrast2×/3×, retained end/middle text, excluded-end false-pass, passing full-image preservation, invalid scale/empty crop and nil non-button. Excluded6pt ends/2pt top-bottom remain an explicit false-pass limit, not a full-control proof;2× thin-stroke limitation is still unresolved. Shared wrapper passes actual.button type and screenshot/frame scale; TASK-46.5/46.6.1 composites must call the same function in their own integration changes.

Validation via nohup/xbuild with grep polling; no builds killed. Initial iPhone17Pro class /tmp/task-73-control-iphone.{log,xcresult}:37passed/2failed methods/0skipped (39total), exit65. Fixed raw negative CGRect dimension validation and exclusion proof nil expectation; targeted two-method rerun /tmp/task-73-control-iphone-fix.{log,xcresult}:2passed/0failed/0skipped,exit0. All39 methods now have green results across full+targeted fix runs, not a claimed single final full-class run. macOS documented unit command /tmp/task-73-control-macos.{log,xcresult}:210passed/0failed/0skipped,exit0; UI-test target compiled too. Added@MainActor to platform-safe screenshot bridge to eliminate isolation warning. No changed-source warnings in final commands; unrelated deprecation/plural/AppIntents warnings and expected corrupt-store diagnostics remain. tvOS/visionOS/full iOS suites skipped because only UI-test helper/proofs changed. Complete per-test tables and commands are in docs/testing/task-73-rounded-control-measurement.md. Test-guard self-test passed; focused57f7991a...0a617ef6 check passed with Test-guard-approved: owner decision 2026-10-22, reporting intended wrapper findings. git diff --check passed. Independent branch review remains required; no live audit integration claimed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented rounded-control measurement under the narrowed owner-delegated scope. Smallest passing tested horizontal cap6pt plus2pt vertical inset raises the unaltered Hide answer1 fixture from1.199:1 to13.620:1 while leaving the conservative base algorithm and non-button behavior unchanged. Added8 regression methods; all39 iPhone methods have green results across class+two-method fix runs; macOS210 unit tests pass and UI-test sources compile. Documented excluded-end false-pass risk and retained all blocked2× diagnostics as unresolved. Code/evidence committed and pushed on task-73-contrast-2x; no PR. TASK-46.5/46.6.1 composite-helper integration and independent review remain separate.
<!-- SECTION:FINAL_SUMMARY:END -->
