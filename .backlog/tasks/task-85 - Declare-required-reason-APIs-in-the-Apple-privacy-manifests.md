---
id: TASK-85
title: Declare required-reason APIs in the Apple privacy manifests
status: In Progress
assignee:
  - '@worker'
created_date: '2026-11-03T02:32:00Z'
updated_date: '2026-11-03T03:03:00Z'
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
- [x] #1 Every required-reason API category used by each shipped target (CanadianHam for iOS/iPadOS/macOS, CanadianHamTV, CanadianHamVision, CanadianHamWatch), including linked local packages, is identified against Apple's current documentation, and the rationale is recorded in docs/release/privacy-label-evidence.md
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

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Worker evidence (2026-11-03 UTC, commit ff7d7c50):
- Apple docs: describing-use-of-required-reason-api, NSPrivacyAccessedAPIType and NSPrivacyAccessedAPITypeReasons, fetched 2026-11-03. Every category and reason is quoted in docs/release/privacy-label-evidence.md, 'Required-reason API review (TASK-85, 2026-11-03)'.
- Usage, from project.yml membership plus linked package Sources (no use in packages):
  - CanadianHam: UserDefaults and SystemBootTime (StudyViews:758 and DuoPostureProvider:296 systemUptime).
  - TV and Vision: UserDefaults only (MorseTrainerSettings.load()).
  - Watch: SystemBootTime only (WatchMorsePlayback:34).
- Manifests:
  - CanadianHam: UserDefaults [CA92.1] + SystemBootTime [35F9.1].
  - New Platforms/tvOS and Platforms/visionOS manifests: UserDefaults [CA92.1].
  - Watch: SystemBootTime [35F9.1].
  - Tracking stays false; tracking domains and collected data stay empty. plutil -lint OK on all four.
- AppleLanguages: the read uses persistentDomain(forName: bundle ID), the app's own domain only; the value is the user's per-app language choice. Declared CA92.1. The residual risk and remedies are documented as an owner decision point. No app code changed.
- Coordinator must apply: remove the explicit 'CanadianHam/Resources/PrivacyInfo.xcprivacy' (type: file, buildPhase: resources) source entries from CanadianHamTV and CanadianHamVision in apps/apple/project.yml, then regenerate with XcodeGen. Until then, pnpm check:apple-required-reasons fails ('found 2' manifests) and TV/Vision bundle the shared manifest, which over-declares SystemBootTime.
  - Verified on a /tmp scratch copy with that change: XcodeGen regenerated only the TV/Vision resource refs, the check passed, and the Release TV/Vision builds bundle only UserDefaults [CA92.1].
- Checks:
  - pnpm test:apple-required-reasons: passed.
  - pnpm check:apple-required-reasons: fails on this branch only because of the expected 2-manifest error; passes on the scratch copy with the project.yml change.
  - pnpm typecheck, check:apple-network, test:apple-network, check:apple-icloud-gate, test:apple-icloud-gate, check:links: passed.
  - Test guard (bf775940...HEAD): passed.
- xbuild Release builds (derived data /tmp/ch-task85-dd), all BUILD SUCCEEDED:
  - iOS Simulator with embedded watch, macOS, tvOS and visionOS on the branch.
  - tvOS and visionOS again from the scratch project.
  - plutil -p and cmp on the built manifests match their sources.
  - strings/nm on the binaries agree with the per-target categories.
- Watch unit test testIndependentOfflineBundle now asserts the exact SystemBootTime [35F9.1] entry. The watch scheme passed build-for-testing; the targeted test was not run because simulator boots were not allowed.
- AC2 and AC4 are left unchecked until the project.yml change lands and TV/Vision are rebuilt and re-inspected on the branch.
- AC3 is left unchecked until CI runs pnpm test:apple-required-reasons and pnpm check:apple-required-reasons.
<!-- SECTION:NOTES:END -->
