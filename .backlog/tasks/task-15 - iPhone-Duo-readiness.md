---
id: TASK-15
title: iPhone Duo readiness
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-18 12:50'
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
- [x] #1 The app builds with Xcode 27.1+ and runs on the iPhone Duo simulator
- [x] #2 Practice and mock exam state survives fold/unfold
- [x] #3 The layouts adapt between the outer and inner displays without truncation
- [x] #4 The UI tests and accessibility audits run on the iPhone Duo simulator
- [x] #5 Unfolded iPhone Duo shows the exam tools and the question side by side (width-driven, sharing the iPad side-panel code)
- [x] #6 In practice and review sessions, a slight open shows Hint 1 after a stable dwell; a normal unfold never triggers it; mock exams never peek
- [x] #7 A hint counts as used only after at least 0.5 s of visibility (button, peek or VoiceOver); unit tests cover the posture state machine and timing
- [x] #8 Hinge code is gated by #available(iOS 27.1, *) and an SDK-conditional build setting so the project still builds with older Xcode SDKs
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Run the iPhone Duo runtime experiment with xbuild/simctl/Simulator inspection and record findings before product changes.
2. Inspect the existing task-44.3 exam-tools split/sheet implementation and 50.12 hint paths, then replace iPhone idiom gating with a narrow width-driven unfolded split rule that preserves non-Duo iPhone behaviour.
3. Add a posture-provider seam with no hinge implementation yet, plus DEBUG-only test hooks for resize/size-class simulation where needed.
4. Add or update targeted unit/UI coverage for state preservation and width-driven panel selection, without weakening existing audits.
5. Validate with targeted iPhone Duo, iPhone 17 Pro, iPad, macOS, and web/l10n checks; check only AC1-AC5 and leave task-15 In Progress for part 2.

6. Address PR #286 review: root-measured unfolded iPhone split layout with regular size-class injection, hysteresis policy tests, runtime fold/unfold UI coverage, SDK flag inversion, and honest task evidence updates.

7. Implement TASK-15 part 2: add the gated UIHinge-backed posture provider plus DEBUG simulated posture sequences, route posture updates through a pure hinge-peek dwell state machine, reveal Hint 1 through the existing hint tool/timer only for eligible practice/review questions, and cover the state machine, visibility-timer integration, mock-exam gate and simulated UI flows without changing existing audits.
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

Part 1 validation after merging origin/main (merge commit b4cd582d): iPhone Duo simulator runtime remains iOS 27.1 with no fold/unfold control, so unfolded coverage uses the DEBUG-only -CanadianHamSimulatedWindowSize hook plus unit policy coverage. Main classification: the four named CanadianHamExamToolsUITests failures all reproduce on detached origin/main on iPhone Duo (log /tmp/task15-main-duo-four-20261017213848.log): testCalculatorAutoFocusesHardwareKeyboardOnOpen, testCalculatorKeyboardInputIsFocusScoped, testCalculatorValueResetsForNewMockExam, and testHintToolLadderAndLessonLink. Branch post-merge full Duo ExamTools log /tmp/task15-duo-examtools-postmerge-20261017215328.log executed 25 tests, 3 skipped, 4 failures: the same four. Diagnosis recorded for follow-up TASK-54: hardware key events do not reach focusable/onKeyPress calculator handling on Duo, and system NavigationBar back buttons are not exposed to XCTest; attempted product workarounds were reverted per coordinator decision because they would be simulator-specific.

Additional required Duo practice targets also reproduce on detached origin/main (main log /tmp/task15-main-duo-practice-targeted-20261017221356.log; branch log /tmp/task15-duo-practice-targeted-20261017221133.log): testAccessibilityAuditPracticeSessionLight and Dark fail with 'Dynamic Type font sizes are partially unsupported', and testLearnUserNavigationOpensLessonQuiz fails waiting for root-sidebar under forced-regular landscape. Follow-up TASK-55 tracks investigation/fix. Passing validation: DuoLayoutPolicyTests passed (5 tests, /tmp/task15-duo-layout-unit-postmerge-20261017230937.log); iPhone 17 Pro CanadianHamExamToolsUITests passed (25 executed, 3 skipped, /tmp/task15-iphone17-examtools-postmerge-20261017221639.log); iPad Pro 13-inch (M5) CanadianHamExamToolsUITests passed (25 executed, 6 skipped, /tmp/task15-ipad-examtools-postmerge-20261017225044.log); macOS unit tests passed (156 tests, /tmp/task15-macos-unit-postmerge-20261017230448.log); pnpm typecheck passed (/tmp/task15-pnpm-typecheck-20261017230551.log); pnpm test passed (127 node tests + 208 web tests, /tmp/task15-pnpm-test-20261017230625.log); pnpm check:apple-l10n passed without rewrite (/tmp/task15-apple-l10n-20261017230729.log); Apple text-source check passed (/tmp/task15-apple-text-sources-20261017230902.log). AC4 is checked for the Duo tests/audits that run or are classified: the remaining 7 Duo failures are main-reproduced and tracked in TASK-54/TASK-55.

Review follow-up TASK-56 tracks the remaining arbitrary deep Learn NavigationPath synchronization across compact/split Duo layout changes. This PR syncs the root selection and RootView-owned practice/mock/hint routes needed for the part 1 fold/unfold state test.

Review fix validation 2026-10-18: implemented root-measured unfolded iPhone layout with regular horizontal size-class injection, root window-size environment for exam tools, hysteresis policy coverage, deterministic DEBUG resize control, SDK flag inversion to NO_HINGE_API on iphone*27.0*, generated Xcode project twice, and TASK-56 for remaining arbitrary deep Learn path sync. Re-checked AC3/AC5 with qualified evidence: iPad Pro 13-inch new unfolded tests assert frames and full inspector audit; iPhone Duo runs the same simulated unfolded policy and fold/unfold state tests, but its current simulator renders a 382 pt window so frame/audit geometry is intentionally recorded only on real-width destinations. TASK-54 now includes real iPhone Duo unfolded/fold-unfold verification.

coordinator decision 2026-10-18, pending owner confirmation: unfolded Duo portrait (about 669 pt wide) leaves less than a 420 pt exam column beside the 380 pt inspector, so TASK-15 part 1 now enters the iPhone split/inspector path only at width >= 800 pt, height >= 600 pt and non-compact vertical size class, with hysteresis leaving below about 780 pt width. Unfolded landscape (about 951x669 pt) gets the split; unfolded portrait (about 669x951 pt) keeps the sheet. TASK-54 AC4 holds real-device verification for these boundaries.

N1-N7 post-merge validation 2026-10-18 (after merge of origin/main / TASK-57): implemented background root window measurement with keyboard-safe-area ignored only in the measuring background, cleared split navigationPath after copying into compact path on fold, raised the phone split/inspector threshold to 800x600 with 780/580 hysteresis, changed simulated size changes to a DEBUG-only user-triggered control with observable applied-size state, added unfolded->folded coverage, removed the compact root simultaneousGesture and duplicate 640x600 assertion, and kept #290's ExamToolButtons .accessibilityLabel(Text(tool.title)) line. AC3/AC5 evidence is qualified: iPad Pro 13-inch runs prove the iPad inspector/sidebar path; the phone-idiom injected-regular split/inspector path is policy/UI-hook covered on simulators but real unfolded Duo landscape/portrait verification remains TASK-54 AC4. Created TASK-58 for the separate iPhone 17 Pro Max calculator-key-percent forced-regular landscape failure. Latest post-merge results: macOS unit tests passed (157 tests, /tmp/task15-macos-unit-postmerge-20261018052548.log); iPad Pro 13-inch (M5) CanadianHamExamToolsUITests passed (30 executed, 6 skipped, /tmp/task15-ipad-examtools-postmerge-20261018052652.log); iPhone Duo CanadianHamExamToolsUITests executed 30, skipped 3, failed only the four known main-reproduced Duo simulator failures (calculator hardware keyboard tests and hint lesson back button, /tmp/task15-duo-examtools-postmerge-20261018054357.log); iPhone 17 Pro CanadianHamExamToolsUITests plus keyboard checks and practice audits passed (34 executed, 3 skipped, /tmp/task15-iphone17-examtools-keyboard-practice-postmerge-20261018060635.log), including testAccessibilityAuditPracticeSessionLight/Dark now passing after TASK-57/#290; pnpm check:apple-l10n passed without rewrite (/tmp/task15-apple-l10n-postmerge-20261018052141.log); node scripts/check-apple-text-sources.ts passed (/tmp/task15-apple-text-sources-postmerge-20261018052137.log). Previous main-reproduced iPhone 17 Pro practice Dynamic Type failures are now fixed on main by TASK-57/#290 rather than tracked as TASK-15 residual failures; the iPhone 17 Pro Max calculator-key-percent failure remains tracked in TASK-58.

Coordinator, final review R1: the DEBUG size-change control's accessibility value now reports '<WxH> <compact|split>' from the root compactNavigation decision. The fold/unfold tests assert compact→split and split→compact on phone idiom (iPad always splits), so the phone split wiring is exercised on every simulator. Six simulated-layout tests passed on iPhone Duo, iPhone 17 Pro and iPad Pro 13-inch (M5): 6/0 each (/tmp/t15-r1-*.log). R2/R3 were added to TASK-54.

TASK-15 part 2 validation 2026-10-18: implemented a pure HingePeekStateMachine (20–35° default slight-open band, 0.7 s dwell, edge-jitter tolerance), UIHingeInteraction provider behind #if !NO_HINGE_API and #available(iOS 27.1,*), DEBUG -CanadianHamSimulatedHingeSequence provider, and PracticeSessionView integration that reveals Hint 1 only for eligible practice/review questions using the existing HintToolView visibility timer. Mock exams never attach hint context or peek. TASK-54 now has real-device ACs for angle band, dwell, and normal-unfold non-peek verification. Validation: macOS unit tests passed 163/0 (/tmp/task15-peek-macos-unit-20261018073403.log, including 13 HintSessionStateTests for state machine/timer); iPhone 17 Pro CanadianHamExamToolsUITests passed 33 executed/3 skipped/0 failures (/tmp/task15-peek-iphone17-examtools-20261018073437.log, includes practice audits and new peek UI audit); iPhone Duo new simulated hinge peek UI tests passed 3/0 (/tmp/task15-peek-duo-new-peek-20261018081512.log); Duo hinge+hint targeted run executed 5 with only known TASK-54 simulator failure testHintToolLadderAndLessonLink (/tmp/task15-peek-duo-hinge-hint-20261018072858.log); iPad Pro 13-inch (M5) CanadianHamExamToolsUITests passed 33 executed/6 skipped/0 failures (/tmp/task15-peek-ipad-examtools-20261018081745.log); pnpm typecheck passed; pnpm test passed (131 content-tool tests + 21 morse tests + 127 calculator tests + 208 web tests); pnpm check:apple-l10n passed without rewrite; node scripts/check-apple-text-sources.ts passed. XcodeGen was run twice after project.yml and a third run confirmed deterministic project output.

Coordinator decisions for PR #292 review round (2026-10-18): H1 dwell must re-check at candidateStart+dwell using the last sample even without new hinge samples; cancel on reset or leaving the band. Stability: dwell starts only inside the real 20–35° band and restarts if the angle moves more than about 3° from the candidate start; jitter tolerance only keeps an already-active peek alive. H2 presentation is start-transition only: dismissal or tool switching suppresses reopen until the posture state machine resets, and refreshActiveHingePeek must never reopen a dismissed peek. Question changes close a peek-opened panel and require a fresh dwell. Peek-opened panels close on fully-open or closed; button-opened panels stay open; the previous tool is not restored. VoiceOver still uses the peek and posts the same Hint 1 shown announcement through shared code. H3 lifecycle must re-attach hinge interaction after a lesson round trip and clear/refresh onPostureChanged to avoid stale state/retain cycles. AC6 remains simulator/code-verified only; real-device verification pending TASK-54 AC5–7. NO_HINGE_API build evidence required.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
TASK-15 remains in progress for PR #292 review fixes. Part 1 delivered Duo simulator readiness and unfolded width-driven exam-tool split/inspector layout; part 2 adds the gated iOS 27.1+ hinge peek for Hint 1 in practice/review only, but review found dwell/presentation/lifecycle gaps that are being corrected. Current simulator/unit evidence proves the guarded route and qualifying gates; real-device posture calibration, angle band, dwell, and normal-unfold/non-peek verification remain pending TASK-54 AC5–7.
<!-- SECTION:FINAL_SUMMARY:END -->
