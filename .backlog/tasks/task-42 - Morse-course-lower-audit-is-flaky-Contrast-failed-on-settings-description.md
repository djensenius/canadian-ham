---
id: TASK-42
title: Morse course lower audit is flaky (Contrast failed on settings description)
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-11 18:37'
updated_date: '2026-10-12 18:36'
labels:
  - apple
  - testing
dependencies: []
priority: high
ordinal: 92000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
On main after the Morse polish merge, testAccessibilityAuditMorseCourseLessonAndSummaryLight and Dark fail intermittently with 'Contrast failed' (seen in task-36's pre-merge full iOS run at d25a368, 2026-10-11; the last element checked before the error was the Morse settings description 'These local settings control Morse tone, timing, and playback volume without network access.'). They passed in the Morse branch's own full run and 3 targeted runs. Likely a position-dependent false positive (text near an edge or under the bar) that the precise-positioning helper doesn't fully prevent.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The failing element and its on-screen position at failure are identified from the xcresult (exported issue and screenshot) and recorded
- [ ] #2 Root cause fixed with test-only positioning (or a genuine contrast fix if the colours really fail, measured), without loosening the audit, adding handlers or changing visuals without owner approval
- [ ] #3 Both audits pass 5 consecutive targeted runs each
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add the owner-approved task-42-only contrast exception handler to the Morse home lower accessibility audit and tag the Morse settings description with a stable accessibility identifier.
2. Add a unit test that parses the actual DesignTokens RGB values for ink and paperElevated and asserts the settings-description WCAG contrast is at least 4.5:1 in light and dark.
3. Document the owner-approved 2026-10-12 exception in AGENTS.md and docs/testing/ui-audit-inventory-after.md.
4. Validate with five consecutive targeted iOS runs of each Morse course audit plus the contrast unit test on iOS and macOS, then update ACs/final summary and mark Done.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Evidence from task-36 failing iOS xcresult/log: xcresult at DerivedData/CanadianHam-arcztguauxjwwvggktczsyjdrwwc/Logs/Test/Test-CanadianHam-2026.10.11_13-43-12--0400.xcresult lacks Info.plist so xcresulttool object export cannot open it, but raw PNG attachments were copied from Data to /tmp/t42-evidence/t36-xcresult-pngs (full dark/light screenshots plus element crops). Session log shows both failures on the Morse settings description StaticText 'These local settings control Morse tone, timing, and playback volume without network access.' with frame {{40.0, 489.0}, {309.0, 64.3}} in a 402x874 window; the text is mid-screen (about 386 pt below an ~103 pt nav/status protected bottom and about 321 pt above the window bottom). Full screenshots show the lower Morse settings audit viewport includes content near the bottom edge while Xcode reports Contrast failed on the description crop. Token contrast is not genuinely low: ink on paper/paperElevated is ~14.95/16.34:1 in light and ~14.05/12.63:1 in dark.

Blocked after approved narrower positioning attempt: I added a condition that visible Morse settings card text must be fully visible and kept the existing top protected-area/middle-band assertions, then ran targeted audits. Dark passed 5 consecutive post-change targeted runs (card-dark plus verify dark #2-#5), but Light failed on run #2 with the same Contrast failed at CanadianHamPracticeUITests.swift:2000. The failure screenshot /tmp/t42-verify/light2-pngs/png-2.png and crop /tmp/t42-verify/light2-pngs/png-1.png again show the settings description fully visible mid-screen; token contrast remains high (light ink on paper/paperElevated ~14.95/16.34:1). Per supervisor direction, stopping for owner decision rather than adding audit handlers/filters, hiding sections, or changing visuals.

Timing investigation: MorseTrainerView/MorseCourseView grep found no .animation, withAnimation, .transition, TimelineView, repeatForever, phaseAnimator, or symbolEffect in the Morse home/course path. Relevant async sources are dormant visual playback Task schedules in MorseTrainerView/Course (only after Play), course load .task, playback stop tasks, and a DispatchQueue.main.async accessibility refocus only when entering lesson/review sessions. Temporary lower-audit probe captured 3 screenshots 200 ms apart just before the light lower Morse audit; /tmp/t42-light-instrumented-1.log recorded appRunningForeground=true, diff12=0, diff23=0, and the targeted light audit passed. Evidence points to needing a bounded test-side settle/stability wait before auditing rather than a running app animation.

Blocked/timing hypothesis disproven: replacing the temporary probe with a bounded visual-stability wait (foreground wait plus up to 6 screenshots 200 ms apart, returning only after two consecutive screenshots matched pixel-for-pixel) did not fix the light lower audit. Targeted command DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -project apps/apple/CanadianHam.xcodeproj -scheme CanadianHam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CanadianHamUITests/CanadianHamPracticeUITests/testAccessibilityAuditMorseCourseLessonAndSummaryLight test CODE_SIGNING_ALLOWED=NO failed at CanadianHamPracticeUITests.swift:2002 with Contrast failed on the same settings description after the wait (/tmp/t42-light-final-smoke.log; xcresult Test-CanadianHam-2026.10.11_18-31-54--0400.xcresult). Because the probe showed diff12=0/diff23=0 and the bounded stability wait still failed, I reverted the temporary test code and am stopping without app-side changes.

Owner-decision implementation status (2026-10-12): added the approved single handler for the Morse home lower audit only, matching `.contrast` issues tied to accessibility identifier `morse-settings-description`; added the identifier to the settings description Text; added `MorseTrainerTests.testMorseSettingsDescriptionInkOnCardBackgroundMeetsWCAGContrast`; documented the exception in AGENTS.md and docs/testing/ui-audit-inventory-after.md.

New blocking evidence found during validation: after the approved handler, the light targeted audit still intermittently fails Contrast on the lower Morse settings area, with the last audit activity on `morse-settings-fixed-timing-description`. Failure examples: `/tmp/t42-light-consecutive-1-attempt-1.log`, `/tmp/t42-light-consecutive-1-attempt-2.log`, and `/tmp/t42-light-final-streak-2.log` all fail at CanadianHamPracticeUITests.swift:2107 with Contrast failed after finding `morse-settings-fixed-timing-description`; `/tmp/t42-light-final-streak-2.log` uses xcresult `/Users/david/Library/Developer/Xcode/DerivedData/CanadianHam-efrzkhuqjhxzruczkrbjyuwjvlgv/Logs/Test/Test-CanadianHam-2026.10.12_14-30-57--0400.xcresult`. Extracted screenshots: full screen `/tmp/t42-final-streak2-data/data.0~OP7I7Fe9AGcAX8gE_30Cna1fOQzIvOJsUA96Y8H_PVSqwBKX6LfELsKV5Ws-6hC7ff_d-UqocOrsjOVkdasMgg==.png`, crop `/tmp/t42-final-streak2-data/data.0~AYxmerj_pUFPjOa_eM4AZpdZWqWO4etjHzMm5DYBphkEUfw1UibiAQXZtoFWCq-fntqQdarWXFnB0e9XUCtF-rNV61JDq-PRi_2yiBwXg==.png` (see corrected crop file actually ending `AYxmerj_pUFPjOa_eM4AZpdZWqWO4t3uijtzwOEaVWMJPvfXaTMlSm-il8BrPulBxp7ADn5RuifX0gISRPKFbg==.png`). The 1206x2622 screenshot maps to a 402x874 pt window; the opaque nav/status protected area ends around y≈89 pt, while the fixed-timing text card is fully visible around y≈728-860 pt inside the scroll viewport, with its bottom close to the screen bottom/scroll edge. The element is visually stable and fully visible in the captured screen, but near the lower edge; this matches the suspected shared content-under-opaque-bar/edge false positive from task-38.1. Observed rate in final validation attempts: light failed 2 consecutive attempts, then passed 5 consecutive attempts, then failed again on a later streak run; dark was not rerun after this new unapproved issue was discovered.

Blocked: awaiting owner decision on content-under-opaque-bar (shared with task-38.1). Per supervisor instruction I did not widen the task-42 exception beyond `morse-settings-description` and left task-42 In Progress.
<!-- SECTION:NOTES:END -->
