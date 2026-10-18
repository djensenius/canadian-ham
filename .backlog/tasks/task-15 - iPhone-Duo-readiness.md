---
id: TASK-15
title: iPhone Duo readiness
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-18 00:08'
labels:
  - apple
  - 'legacy:T-706'
milestone: m-1
dependencies:
  - TASK-44.3
priority: medium
ordinal: 25000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Prepare the Apple app for iPhone Duo (foldable; announced 2026-09-09, ships 2026-10-23): build with Xcode 27.1+, confirm the UIScene lifecycle, use freely resizable adaptive layouts (compact outer and regular inner display, posed states), avoid UIScreen.main assumptions, handle reserved regions and asymmetric safe areas, and preserve state across fold/unfold mid-practice or mid-exam. Ref: https://developer.apple.com/iphone-duo/. Legacy: T-706.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The app builds with Xcode 27.1+ and runs on the iPhone Duo simulator
- [ ] #2 Practice and mock exam state survives fold/unfold
- [ ] #3 The layouts adapt between the outer and inner displays without truncation
- [ ] #4 The UI tests and accessibility audits run on the iPhone Duo simulator
- [ ] #5 Unfolded iPhone Duo shows the exam tools and the question side by side (width-driven, sharing the iPad side-panel code)
- [ ] #6 In practice and review sessions, a slight open shows Hint 1 after a stable dwell; a normal unfold never triggers it; mock exams never peek
- [ ] #7 A hint counts as used only after at least 0.5 s of visibility (button, peek or VoiceOver); unit tests cover the posture state machine and timing
- [ ] #8 Hinge code is gated by #available(iOS 27.1, *) and an SDK-conditional build setting so the project still builds with older Xcode SDKs
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Run the iPhone Duo runtime experiment with xbuild/simctl/Simulator inspection and record findings before product changes.
2. Inspect the existing task-44.3 exam-tools split/sheet implementation and 50.12 hint paths, then replace iPhone idiom gating with a narrow width-driven unfolded split rule that preserves non-Duo iPhone behaviour.
3. Add a posture-provider seam with no hinge implementation yet, plus DEBUG-only test hooks for resize/size-class simulation where needed.
4. Add or update targeted unit/UI coverage for state preservation and width-driven panel selection, without weakening existing audits.
5. Validate with targeted iPhone Duo, iPhone 17 Pro, iPad, macOS, and web/l10n checks; check only AC1-AC5 and leave task-15 In Progress for part 2.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner decisions 2026-10-15:
- Unfolded: split layout with the exam tools (calculator, allowed reference sheet) on one side and the question on the other, driven by width and reusing the iPad side panel from task-44.3.
- Practice only (never mock exams): opening the phone slightly peeks Hint 1, via UIHingeInteraction / UIHinge status and angle (iOS 27.1+; the app minimum is 27.0, so use #available plus an SDK-conditional compile gate).
- A hint counts as used only after it has been visible for at least 0.5 s, by any route, and the hinge must be stable in the peek range for a dwell time, so a normal unfold never triggers a peek.
- The Hint button stays the primary, accessible path.
- Build only after hints (task-50) have shipped on web and iOS/iPadOS/macOS. A scout report on the SDK and simulator is pending.

Scout 2026-10-16 (SDK 27.1):
- The only foldable API is UIKit UIHinge and UIHingeInteraction (status closed/partiallyOpen/fullyOpen plus angle, iOS/tvOS/visionOS 27.1). There is no SwiftUI, CoreMotion, display-segment or hinge-rect API.
- XCUITest has no hinge or posture API, so tests need an app-level posture provider with a DEBUG launch-argument simulation, plus unit tests for the dwell and visibility timing.
- The iPhone Duo simulator needs the iOS 27.1 runtime (the only iPhone type on it, model iPhone19,4). Its profile shows no scripted hinge control.
- Runtime experiment still to run when the build lock is free: check whether Simulator.app exposes a hinge/posture control, which display the app uses when partly open, the window sizes in each posture, and whether UIHingeInteraction updates fire in the simulator.
- Build gate: the repo already uses [sdk=iphone*] conditions in project.yml. Add SWIFT_ACTIVE_COMPILATION_CONDITIONS[sdk=iphone*27.1*] HINGE_API (verify the pattern) plus @available(iOS 27.1, *).

Runtime experiment 2026-10-17 (iPhone Duo 0DEB0EAC-F45C-4251-82AA-146DAF2BD524, iOS 27.1, Xcode 27.1 / xbuild):
- `xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination "platform=iOS Simulator,name=iPhone Duo,OS=27.1" build CODE_SIGNING_ALLOWED=NO` succeeded and the built app installed/launched via `simctl launch` on the Duo.
- `simctl help`, `simctl ui`, and `simctl io` expose no fold/unfold, hinge, posture, or display-selection control. `simctl ui` only supports appearance/increase_contrast/content_size; `simctl io screenConfig` supports display power/geometry, screenshots, and video.
- Xcode 27.1 on this host has DeviceHub.app rather than a Simulator.app at the previous Developer/Applications path; command-line inspection and binary string search found no obvious hinge/fold/posture command surface.
- `simctl io enumerate` reports two integrated LCDs: `primary`/screen 1 at 1398x2034 pixels (preferred scale 3, portrait) and `primary-1`/screen 3 at 2007x2853 pixels (preferred scale 3, portrait), plus resizable/external displays.
- A temporary DEBUG diagnostic overlay (not committed) logged the launched app on the default/closed display at SwiftUI geometry 382x644 pt, safe area top 0 / bottom 34 / trailing 84, horizontal size class compact, vertical regular. UIHingeInteraction delivered an initial update with status closed (raw 1) and angle 0.0.
- Toggling screen 3 power with `simctl io screenConfig --display primary-1 power off/on` generated SwiftUI geometry changes (including a transient 2769x1973 pt report) but kept compact/regular size classes and UIHingeInteraction still reported closed angle 0.0; it did not simulate an unfolded posture.
- I did not find a simulator-controllable fold/unfold path, so part 1 tests should use width/size-class DEBUG launch hooks for unfolded layout and state-resize coverage. Part 2 can attach a real UIHingeInteraction provider behind availability/build gates.
<!-- SECTION:NOTES:END -->
