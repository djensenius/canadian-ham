---
id: TASK-91
title: Refresh the owner-gates guide after TASK-54, TASK-85 and TASK-86
status: In Progress
assignee:
  - '@copilot'
created_date: '2026-11-03T04:10:00Z'
updated_date: '2026-11-03T05:19:00Z'
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
- [ ] #1 owner-gates.md has a sitting or section for the Xcode Cloud and App Store Connect setup that links distribution.md, including trying a Next Build Number above the highest recorded upload and choosing option (b) or (c) if App Store Connect refuses it
- [ ] #2 owner-gates.md lists the TASK-85 AppleLanguages CA92.1 sign-off as an owner decision before App Store submission
- [ ] #3 The TASK-54 Duo sitting reflects AC #1 being done on the iOS 27.2 simulator and asks the owner to check the back control's VoiceOver label and position for AC #2, and the open-gates table and coordinator upload wording match the Fastlane/Xcode Cloud state in distribution.md
- [ ] #4 pnpm check:links passes
<!-- AC:END -->
