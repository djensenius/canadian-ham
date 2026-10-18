---
id: TASK-55
title: >-
  Investigate iPhone Duo practice audit Dynamic Type finding and forced-regular
  Learn sidebar
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-18 02:16'
updated_date: '2026-10-18 21:54'
labels:
  - apple
dependencies:
  - TASK-15
priority: high
ordinal: 134000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-15 part 1 required iPhone Duo practice audits and Learn navigation runs. Both this branch and detached origin/main fail on the iOS 27.1 iPhone Duo simulator: CanadianHamPracticeUITests/testAccessibilityAuditPracticeSessionLight and Dark report 'Dynamic Type font sizes are partially unsupported' at CanadianHamPracticeUITests.swift:2321, and testLearnUserNavigationOpensLessonQuiz fails waiting for root-sidebar under forced-regular landscape. Branch log: /tmp/task15-duo-practice-targeted-20261017221133.log. Main log: /tmp/task15-main-duo-practice-targeted-20261017221356.log.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Identify the element or elements behind the Duo 'Dynamic Type font sizes are partially unsupported' audit finding and fix app code if it is an app issue; do not filter or weaken the audit
- [ ] #2 Make CanadianHamPracticeUITests/testLearnUserNavigationOpensLessonQuiz pass on iPhone Duo, or document why forced-regular landscape has no root-sidebar on the iOS 27.1 Duo runtime
- [ ] #3 Rerun CanadianHamPracticeUITests/testAccessibilityAuditPracticeSessionLight, testAccessibilityAuditPracticeSessionDark and testLearnUserNavigationOpensLessonQuiz on iPhone Duo and record per-test results
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Reproduce the two practice accessibility audits and forced-regular Learn navigation failure on the iPhone Duo 27.1 simulator with result bundles under /tmp, then export xcresult attachments and inspect complete issue descriptions/screenshots for the failing elements.
2. Trace the identified practice clipping and forced-regular Learn layout through the SwiftUI views/policy in iOS-shared app code, fixing only app layout bugs without audit filtering, minimumScaleFactor, hidden visible text, fixed widths, or hard-coded colours.
3. Rerun the targeted Duo and iPhone 17 Pro tests, including CanadianHamExamToolsUITests for regression, then record per-test results/log paths in task notes and finalize the task evidence.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Review follow-up 2026-10-18: TASK-55 depends on TASK-15 part 1 / PR #286 because it investigates Duo simulator practice audit/navigation failures found by that work; it does not need part 2 hinge-peek work except insofar as Backlog cannot express a dependency on part 1 only.

Investigation update 2026-10-18:
- Initial required Duo run (current main-equivalent app source) used `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone Duo,OS=27.1' -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditPracticeSessionLight -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditPracticeSessionDark -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testLearnUserNavigationOpensLessonQuiz -resultBundlePath /tmp/task55-duo-initial.xcresult test CODE_SIGNING_ALLOWED=NO`; log `/tmp/task55-duo-initial.log`; result bundle `/tmp/task55-duo-initial.xcresult`; exported attachments `/tmp/task55-duo-initial-attachments`.
- Duo practice audit finding: both Light and Dark failed with `Text clipped` at `CanadianHamPracticeUITests.swift:2320`. The exported Complete Issue Description files `/tmp/task55-duo-initial-attachments/DED4B428-191A-4397-9406-936F11FFF7DE.txt` and `/tmp/task55-duo-initial-attachments/4552277E-C74C-4EAE-8198-0E4E6DE59090.txt` say `Text of this UILabel may be clipped at larger Dynamic Type sizes.` Element screenshots `/tmp/task55-duo-initial-attachments/D5D5C30A-E75F-4000-86DB-2DFEF34FDF63.png` and `/tmp/task55-duo-initial-attachments/CCE586AF-2584-430E-B995-66C4BCB4A803.png` show the clipped element is the UIKit large navigation title `Regulations and Policies`, not the wrapping SwiftUI header card. The app screenshots `/tmp/task55-duo-initial-attachments/2087C10B-BB77-448F-B2B5-1FF133728480.png` and `/tmp/task55-duo-initial-attachments/E971B798-649F-415F-91CA-DA5838A1C926.png` show the header card title wraps correctly while the large nav title remains a single clipped line. The element PNG is 1074x126 px (about 358x42 pt at 3x) in a 1398x2034 px window (about 466x678 pt), matching the Duo runtime's narrow closed-display/safe-area geometry; the same run's UI hierarchy `/tmp/task55-duo-initial-attachments/46D17E61-32D9-4D82-80D9-BCD86865E390.txt` shows a 466x678 pt window with main content constrained to 382 pt and an 84 pt trailing reserved/safe area.
- Category/width evidence so far: observed clipping is for category B-001 title `Regulations and Policies` at the Duo iOS 27.1 closed/landscape-rendered width (466 pt window, 382 pt main safe/content width). It does not reproduce for the same audit at default text size on iPhone 17 Pro (402 pt window) or iPhone 17 Pro Max (440 pt window): `/tmp/task55-iphone17pro-default-title.log` passed with result `/tmp/task55-iphone17pro-default-title.xcresult`, and `/tmp/task55-iphone17promax-default-title.log` passed with result `/tmp/task55-iphone17promax-default-title.xcresult`. At `accessibility-extra-extra-extra-large`, iPhone 17 Pro and Pro Max runs did not report the nav-title clipped-text issue; they failed earlier on separate contrast findings in scroll content, with Complete Issue Description files `/tmp/task55-iphone17pro-axxxl-title-attachments/5135661B-5763-4B39-B8BE-777A6F593C19.txt` and `/tmp/task55-iphone17promax-axxxl-title-attachments/E8E07CDE-230A-4D04-8008-61567AEC2FDA.txt` both saying `Contrast failed for SwiftUI.AccessibilityNode`. The exported context files identify offscreen/edge scroll-content labels, not the navigation title: `/tmp/task55-iphone17pro-axxxl-title-attachments/8E9152EA-B8EE-442E-9F34-0B339160656D.txt`, `/tmp/task55-iphone17pro-axxxl-title-attachments/ADDCDF8E-7B56-4EA0-A037-A49B3C692252.txt`, and `/tmp/task55-iphone17promax-axxxl-title-attachments/3E39DA4B-AC04-4265-AC12-FB19858F6530.txt`.
- I tried a short generic iPhone navigation title locally, but reverted it per coordinator steering because it is a visible iPhone-wide product change. Owner decision options for the nav-title issue: (a) generic short nav title such as `Practice`, since the card already exposes the category; (b) inline title display mode for practice sessions; (c) a supported large-title wrapping/shrinking approach if available; (d) keep the current long large title and accept that the Duo runtime reports the finding.
- Learn sidebar AC2 investigation: the Duo `testLearnUserNavigationOpensLessonQuiz` failure is reproducible in `/tmp/task55-duo-initial.log` and the exported hierarchy `/tmp/task55-duo-initial-attachments/46D17E61-32D9-4D82-80D9-BCD86865E390.txt`. With `-CanadianHamForceRegularHorizontalSizeClass` plus landscape on the iOS 27.1 Duo simulator, the app still renders a 466x678 pt closed-display window, exposes a `Show Sidebar` navigation-bar button, and has no `root-sidebar` element in the hierarchy. RootView's part-1 unfolded policy intentionally enters the phone split/sidebar path only for a measured safe-area window at least 800x600 with non-compact vertical size; the current Duo simulator has no fold/unfold control and does not present unfolded landscape geometry. Forced regular horizontal size class alone does not force `NavigationSplitView` to keep the sidebar visible on this narrow phone window, so this appears to be a simulator/test-setup limitation rather than an app layout bug. I did not change the test or product code.
- Additional targeted evidence gathered during investigation: Duo `CanadianHamExamToolsUITests` log `/tmp/task55-duo-examtools.log` executed 35 tests, skipped 3, and failed the known Duo simulator issues plus the lesson-round-trip hinge test: `testCalculatorAutoFocusesHardwareKeyboardOnOpen`, `testCalculatorKeyboardInputIsFocusScoped`, `testCalculatorValueResetsForNewMockExam`, `testHintToolLadderAndLessonLink`, and `testSimulatedHingePeekStillWorksAfterHintLessonRoundTrip`. The iPhone 17 Pro combined practice/exam-tools run `/tmp/task55-iphone17-practice-examtools.log` passed 38 tests with 3 skipped, but note that run occurred before the temporary generic-title experiment was reverted, so the later default-title-specific logs above are the evidence for current practice-title behaviour.
- No acceptable source changes remain. TASK-55 is left In Progress awaiting the owner's navigation-title decision; PR should be Backlog-only.
<!-- SECTION:NOTES:END -->
