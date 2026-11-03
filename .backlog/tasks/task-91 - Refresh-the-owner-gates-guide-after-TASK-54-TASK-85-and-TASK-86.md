---
id: TASK-91
title: Refresh the owner-gates guide after TASK-54, TASK-85 and TASK-86
status: Done
assignee:
  - '@copilot'
created_date: '2026-11-03T04:10:00Z'
updated_date: '2026-11-03T05:26:00Z'
labels:
  - docs
  - release
milestone: m-0
dependencies:
  - TASK-85
priority: medium
type: docs
ordinal: 174000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
docs/release/owner-gates.md (TASK-87) predates three changes: TASK-86 added Xcode Cloud distribution with owner-only App Store Connect steps and a build-number decision (docs/release/distribution.md); TASK-85 needs owner sign-off on declaring the AppleLanguages UserDefaults read under CA92.1 before App Store submission (noted on TASK-1.7); and TASK-54 AC #1 now has simulator results (all four tests fail only on the iPhone Duo simulator on iOS 27.1 and 27.2; the back control is exposed as an unlabelled Toolbar button 'BackButton'). The guide should index these so the owner has one place for every gate. It must restate and link task criteria without changing them.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 owner-gates.md has a sitting or section for the Xcode Cloud and App Store Connect setup that links distribution.md, including trying a Next Build Number above the highest recorded upload and choosing option (b) or (c) if App Store Connect refuses it
- [x] #2 owner-gates.md lists the TASK-85 AppleLanguages CA92.1 sign-off as an owner decision before App Store submission
- [x] #3 The TASK-54 Duo sitting reflects AC #1 being done on the iOS 27.2 simulator and asks the owner to check the back control's VoiceOver label and position for AC #2, and the open-gates table and coordinator upload wording match the Fastlane/Xcode Cloud state in distribution.md
- [x] #4 pnpm check:links passes
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Read owner-gates.md, distribution.md, privacy-label-evidence.md and the TASK-54, TASK-85, TASK-86 and TASK-1.7 notes (TASK-85 branch read-only for the CA92.1 wording).
2. owner-gates.md intro and open-gates table: note the owner-only items beyond owner-gate tasks; mark TASK-54 AC #1 done; add rows for the TASK-85 CA92.1 sign-off and the Xcode Cloud / App Store Connect setup.
3. Add a short section on where internal builds come from (Xcode Cloud release path, Fastlane temporary fallback per distribution.md) and use it in the Apple Watch, Apple TV and Duo sittings instead of the fixed Fastlane upload wording.
4. Sitting 1: add a TASK-85 CA92.1 sign-off decision before App Store submission, linking privacy-label-evidence.md.
5. Add a sitting for Xcode Cloud and App Store Connect setup linking distribution.md: try a Next Build Number above the highest recorded upload; if refused, choose option (b) and (c).
6. Sitting 4: record AC #1 done on the iOS 27.2 simulator (Duo-only failures, controls passed); AC #2 asks for the back control's VoiceOver label and position; the device run now serves AC #3.
7. Run pnpm check:links and git diff --check; finalize the task and commit.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Docs commit 3ba8fc55 (docs/release/owner-gates.md only).
AC1: new 'Sitting 6: Xcode Cloud and App Store Connect setup (no device)' links distribution.md (Xcode Cloud setup, Build numbers, Floors file, owner decision, While Fastlane uploads continue, Retiring Fastlane). Step 2 tries a Next Build Number above the highest recorded upload (floors on 2026-11-03, all 1.0.0: ios 202610271751, macos 202610271753, tvos 202610271756, visionos 202610271757; example 202610271758, option (a)); if App Store Connect refuses it, option (b) for iOS/iPadOS/tvOS/visionOS and option (c) for the Mac app. Open-gates table row added.
AC2: Sitting 1 adds 'TASK-85: sign off on CA92.1 before App Store submission' (owner decision, not a TASK-85 criterion; coordinator decision 2026-11-02 to keep CA92.1, fallbacks, links privacy-label-evidence.md and distribution.md#gates; PR #1064 referenced by number, no anchor into its unmerged section). Table row added.
AC3: Sitting 4 says AC #1 is done on the iOS 27.2 simulator (Duo-only failures; iPhone 18 Pro and iPad Air 11-inch (M4) 4/4) and the device run now serves AC #3; step 1 gives the unlabelled Toolbar 'BackButton' at {{399,179},{38,38}} in 466x678 pt and asks for the VoiceOver label and on-screen position for AC #2. Table row now AC #2-#7. New 'Internal builds for the sittings' section replaces the fixed 'fastlane ios beta'/'fastlane appletvos beta' wording in Sittings 2-4: Xcode Cloud once it ships a platform, Fastlane fallback until then, option (b) stops iOS/tvOS/visionOS Fastlane at the version-bump merge. Intro and reporting bullet updated.
AC4: pnpm check:links -> 'Markdown relative links verified.'; git diff --check clean.
Not changed (out of scope): distribution.md step 2 still says the repo stays private until TASK-1.7, but the repo is already public (TASK-1.7 notes). AGENTS.md/distribution.md say the coordinator uploads internal Fastlane builds; owner-gates.md uses neutral wording (builds come from the Fastlane fallback) to avoid contradicting either.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Refreshed docs/release/owner-gates.md after TASK-86, TASK-85 and TASK-54, linking sources rather than copying them.

- Sitting 6 (new): owner-only Xcode Cloud and App Store Connect setup from distribution.md, including a Next Build Number above the highest recorded upload (202610271757 on 2026-11-03) and the option (b)/(c) fallbacks if App Store Connect refuses it.
- Sitting 1: TASK-85 CA92.1 sign-off on the AppleLanguages read as an owner decision before App Store submission, linking privacy-label-evidence.md.
- Sitting 4: TASK-54 AC #1 done on the iOS 27.2 simulator; AC #2 asks for the back control's VoiceOver label and position; the Duo test run now serves AC #3.
- Open-gates table, intro, reporting bullet and a new Internal builds section now match distribution.md: Xcode Cloud is the path and Fastlane a temporary fallback.

Checks: pnpm check:links verified; git diff --check clean. Docs only; no Apple runs. Follow-ups: distribution.md still says the repository stays private until TASK-1.7; the TASK-85 'Why these reasons' anchor can be linked once PR #1064 merges.
<!-- SECTION:FINAL_SUMMARY:END -->
