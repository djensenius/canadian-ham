---
id: TASK-59
title: Generalize the Dynamic Type accessibility label to all secondary buttons
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-18 08:37'
updated_date: '2026-10-20 01:59'
labels:
  - apple
  - accessibility
dependencies:
  - TASK-57
ordinal: 134000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Follow-up from the PR #290 review (TASK-57). The Hint button's visible label already scaled; SwiftUI's synthesized accessibility node lacked font metadata, so the Dynamic Type audit flagged it. Other short-titled AccessibleSecondaryButtonLabel buttons (Next, Done, Play, Previous in StudyViews, MorseCourseView, LearnViews) could hit the same finding in some layouts.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 AccessibleSecondaryButtonLabel (or its style) carries an explicit localized Text accessibility label so every secondary button exposes a scalable label, and the per-call-site label added in TASK-57 is removed if redundant
- [ ] #2 testLargestDynamicTypeKeepsHintToolButtonReachable additionally proves the visible Hint text grows (frame height at AX-XXXL greater than at the default size, or a targeted .dynamicType audit)
- [ ] #3 Targeted audits on iPhone 17 Pro, iPad and macOS unit tests pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect secondary-label consumers, explicit accessibility overrides, and project target membership; preserve existing localized text and outer overrides.
2. Add the shared Text-backed accessibility label, remove the redundant exam-tool override, and strengthen largest-size Hint coverage with two-launch frame and exact-label assertions.
3. Run focused iPhone and iPad practice audits, exam-tool/hint tests, affected Morse/Learn UI tests, macOS units, and localization/source checks through nohup xbuild with grep-only log polling; run tvOS/visionOS only if target membership requires them.
4. Record per-test evidence, verify the unchanged audit helpers, finalize TASK-59, commit/push the branch, and obtain required independent review before PR creation.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented shared .accessibilityLabel(Text(title)) on AccessibleSecondaryButtonLabel (LocalizedStringKey); removed the redundant exam-tool override. Existing Morse Play/Stop overrides remain on outer Buttons, with exact-label UI assertions. Added exact Previous/Next assertions in Learn and two-launch default-L vs AX-XXXL Hint frame-height comparison. No audit/exception/positioning helpers, visible layout, colours, or localization keys changed.
Target membership: CanadianHam includes the full CanadianHam directory for iOS/macOS. CanadianHamTV and CanadianHamVision list only Design/Tokens.swift, not AccessibleSecondaryButtonStyle.swift or the changed exam-tool views, so their test suites are not affected.
Implementation commit: 0ba702fd0fa95c120c58b4fbd7770d2ae9577e11. Text-source gate and test-guard self-test/base diff check passed. Nohup sequential test runner /tmp/task-59-runs.sh (PID 56658), logs /tmp/task-59-*.log, is queued on the shared xbuild lock; no other builds interrupted. Localization gate reruns in that runner (the initial foreground invocation timed out while waiting on the lock, before export).
<!-- SECTION:NOTES:END -->
