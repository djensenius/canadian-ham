---
id: TASK-42
title: Morse course lower audit is flaky (Contrast failed on settings description)
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-11 18:37'
updated_date: '2026-10-11 22:23'
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
1. Inspect task-36 logs/xcresult artifacts and record the failing audit element/frame evidence. 2. Reproduce the Morse course light/dark audit failures with targeted xbuild runs before changing tests, preserving result bundles/logs. 3. Diagnose whether the failure is positional or genuine contrast; only make a test-only positioning fix unless measured colors genuinely fail. 4. Verify both audits with 5 consecutive targeted passes each, update task notes/ACs/final summary, and commit.

5. Inspect Morse home/course animation sources, temporarily instrument screenshots around the lower Morse audit to verify timing, then replace instrumentation with a bounded visual-stability wait if confirmed.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Evidence from task-36 failing iOS xcresult/log: xcresult at DerivedData/CanadianHam-arcztguauxjwwvggktczsyjdrwwc/Logs/Test/Test-CanadianHam-2026.10.11_13-43-12--0400.xcresult lacks Info.plist so xcresulttool object export cannot open it, but raw PNG attachments were copied from Data to /tmp/t42-evidence/t36-xcresult-pngs (full dark/light screenshots plus element crops). Session log shows both failures on the Morse settings description StaticText 'These local settings control Morse tone, timing, and playback volume without network access.' with frame {{40.0, 489.0}, {309.0, 64.3}} in a 402x874 window; the text is mid-screen (about 386 pt below an ~103 pt nav/status protected bottom and about 321 pt above the window bottom). Full screenshots show the lower Morse settings audit viewport includes content near the bottom edge while Xcode reports Contrast failed on the description crop. Token contrast is not genuinely low: ink on paper/paperElevated is ~14.95/16.34:1 in light and ~14.05/12.63:1 in dark.

Blocked after approved narrower positioning attempt: I added a condition that visible Morse settings card text must be fully visible and kept the existing top protected-area/middle-band assertions, then ran targeted audits. Dark passed 5 consecutive post-change targeted runs (card-dark plus verify dark #2-#5), but Light failed on run #2 with the same Contrast failed at CanadianHamPracticeUITests.swift:2000. The failure screenshot /tmp/t42-verify/light2-pngs/png-2.png and crop /tmp/t42-verify/light2-pngs/png-1.png again show the settings description fully visible mid-screen; token contrast remains high (light ink on paper/paperElevated ~14.95/16.34:1). Per supervisor direction, stopping for owner decision rather than adding audit handlers/filters, hiding sections, or changing visuals.
<!-- SECTION:NOTES:END -->
