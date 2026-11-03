---
id: TASK-85
title: Declare required-reason APIs in the Apple privacy manifests
status: In Progress
assignee:
  - '@worker'
created_date: '2026-11-03T02:32:00Z'
updated_date: '2026-11-03T02:43:00Z'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Fetch Apple's required-reason API docs; list categories and approved reason codes verbatim.
2. Inventory required-reason API usage per shipped target (CanadianHam iOS/macOS, CanadianHamTV, CanadianHamVision, CanadianHamWatch) incl. linked local Swift packages, using project.yml target membership.
3. Choose reason codes from actual behaviour; update the shared app manifest and watch manifest (propose per-target manifests + project.yml diff to coordinator if the shared manifest would over-declare).
4. Add scripts/check-apple-required-reasons.mjs + self-test with fixtures; add package.json scripts; report CI steps to coordinator.
5. Update docs/release/privacy-label-evidence.md with the completed review.
6. Validate: check + self-test, pnpm typecheck/test, network/icloud checks, Release xbuild compile-only builds for iOS (with watch), macOS, tvOS, visionOS; inspect built manifests with plutil -p.
7. Record evidence in notes, check verified ACs (AC3 waits for CI wiring), commit.
<!-- SECTION:PLAN:END -->
