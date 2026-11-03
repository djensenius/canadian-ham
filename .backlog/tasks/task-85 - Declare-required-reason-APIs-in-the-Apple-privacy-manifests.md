---
id: TASK-85
title: Declare required-reason APIs in the Apple privacy manifests
status: To Do
assignee: []
created_date: '2026-11-03T02:32:00Z'
updated_date: '2026-11-03T02:39:00Z'
labels:
  - apple
  - privacy
  - release
milestone: m-0
dependencies: []
priority: high
type: bug
ordinal: 168000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-81 found that the Apple apps now read and write UserDefaults (Morse settings, language and bank selection through standard and persistentDomain(forName:) access, and local iCloud-sync helper keys) while both PrivacyInfo.xcprivacy manifests declare an empty NSPrivacyAccessedAPITypes array. Other required-reason categories are also used: ProcessInfo.systemUptime (system boot time) appears in the watch app (WatchMorsePlayback.swift), DuoPostureProvider.swift and StudyViews.swift, so the watch manifest cannot stay empty. App Store Connect rejects uploads that use required-reason APIs without approved reasons, so this blocks App Store distribution. Choose reasons from actual behaviour; for example, AppleLanguages domain access may not fit CA92.1. See docs/release/privacy-label-evidence.md, Required-reason review: OPEN.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Every required-reason API category used by each shipped target (CanadianHam for iOS/iPadOS/macOS, CanadianHamTV, CanadianHamVision, CanadianHamWatch), including linked local packages, is identified against Apple's current documentation, and the rationale is recorded in docs/release/privacy-label-evidence.md
- [ ] #2 Each shipped target's PrivacyInfo.xcprivacy declares those categories with Apple-approved reason codes that match the actual behaviour, and declares none the target does not use
- [ ] #3 An automated check run in CI fails when Apple app or package sources use a required-reason API spelling that the relevant manifest does not declare
- [ ] #4 Release builds made with xbuild for iOS (with the embedded watch app), macOS, tvOS and visionOS contain the expected manifests, confirmed by inspecting the built products
<!-- AC:END -->
