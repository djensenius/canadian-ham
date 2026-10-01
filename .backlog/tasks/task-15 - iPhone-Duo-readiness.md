---
id: TASK-15
title: iPhone Duo readiness
status: To Do
assignee: []
created_date: '2026-10-01 02:27'
labels:
  - apple
  - 'legacy:T-706'
milestone: m-1
dependencies: []
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
<!-- AC:END -->
