---
id: TASK-15
title: iPhone Duo readiness
status: To Do
assignee: []
created_date: '2026-10-01 02:27'
updated_date: '2026-10-16 08:08'
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
<!-- SECTION:NOTES:END -->
