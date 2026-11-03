---
id: TASK-85
title: Declare required-reason APIs in the Apple privacy manifests
status: In Progress
assignee:
  - '@worker'
created_date: '2026-11-03T02:32:00Z'
updated_date: '2026-11-03T04:02:00Z'
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
- [x] #2 Each shipped target's PrivacyInfo.xcprivacy declares those categories with Apple-approved reason codes that match the actual behaviour, and declares none the target does not use
- [ ] #3 An automated check run in CI fails when Apple app or package sources use a required-reason API spelling that the relevant manifest does not declare
- [x] #4 Release builds made with xbuild for iOS (with the embedded watch app), macOS, tvOS and visionOS contain the expected manifests, confirmed by inspecting the built products
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

Doc drift follow-up (commit dc67a2ea, after coordinator b7877c4d): release-checklist.md required-reason item now points to the completed TASK-85 review (re-run pnpm check:apple-required-reasons and inspect bundled manifests on the release commit). privacy-label-evidence.md: dependency row lists all four local packages (CanadianHam links engine/content/morse/calculator; TV, Vision, Watch link engine/content/morse, verified in apps/apple/project.yml); recorded coordinator decision 2026-11-02 to keep CA92.1 for the app-domain AppleLanguages read, fallbacks retained; check row notes it passes on the branch since b7877c4d. Checker header now states the #if/string-literal limitation (already in the evidence doc). Checks: pnpm check:links -> 'Markdown relative links verified.'; pnpm check:apple-required-reasons -> passed (CanadianHam 53 files SystemBootTime [35F9.1], UserDefaults [CA92.1]; Watch 31 SystemBootTime [35F9.1]; TV 33 and Vision 32 UserDefaults [CA92.1]); pnpm test:apple-required-reasons -> 'passed self-test fixtures.'; git diff --check clean. No xbuild run (coordinator owns TV/Vision Release rebuild and watch test). AC2/AC3/AC4 left for the coordinator.

Coordinator native validation on b7877c4d+ (2026-11-02, xbuild, -derivedDataPath /tmp/ch-task85-dd): Release CanadianHamTV (generic tvOS Simulator) and CanadianHamVision (generic visionOS Simulator) built (exit 0); each .app contains exactly one PrivacyInfo.xcprivacy with NSPrivacyAccessedAPITypes = [UserDefaults CA92.1] only. iOS (with embedded watch) and macOS Release manifests were verified by the worker on the same sources (shared manifest unchanged by b7877c4d). Targeted watch test CanadianHamWatchTests/testIndependentOfflineBundle on Apple Watch Series 12 (42mm) OS 27.0: passed (1 test, 0 failures). pnpm check:apple-required-reasons passes for all four targets with exactly the used categories. AC3 waits for the CI steps (added in b7877c4d) to pass on the PR.

Review fixes (commit 498a7272): (1) check-apple-required-reasons.mjs now fails closed if a shipped target's sources or a linked local package's Sources contain .c/.m/.mm/.cpp/.cc/.cxx/.h/.hpp files (only Swift is scanned); test-only and unlinked-package C files stay allowed. (2) Every shipped manifest must have NSPrivacyTracking=false and present, empty NSPrivacyTrackingDomains and NSPrivacyCollectedDataTypes. Self-test adds 10 fixtures (tracking true/missing, tracking domain listed/missing, collected data type listed/missing, .m in TV, .mm in App, .h in Watch, .c in linked package); a mutation run removing the new logic made all 8 behaviour-specific fixtures fail. (3) Owner sign-off on AppleLanguages -> CA92.1 required before App Store submission: noted in privacy-label-evidence.md decision paragraph, release-checklist.md required-reason item, and TASK-1.7 notes (auto-commit 50bf4dbe). Evidence doc 'What fails' list updated. (4) #if limitation already documented; no change. Checks: pnpm test:apple-required-reasons -> 'passed self-test fixtures.'; pnpm check:apple-required-reasons -> passed (same per-target categories, now '... with approved app reasons, no tracking and no collected data.'); pnpm check:links -> 'Markdown relative links verified.'; git diff --check clean; node scripts/check-test-guard.mjs --base origin/main --head HEAD -> 'Test guard passed: no guarded changes found in 5abb6934...HEAD.' No xbuild run.

PR #1064 Copilot fixes (commit 32c31959): (1) Function references: fstat/lstat/fstatat, statfs/statvfs/fstatfs/fstatvfs and getattrlist family now match as word-bounded identifiers (no '(' needed), so 'let read = Darwin.fstat' counts; bare 'stat' matches only as a call, a C-module-qualified name (Darwin/Glibc/SwiftGlibc/Musl/Foundation/ucrt .stat) or the whole RHS of an assignment, so Swift vars named stat (e.g. morse-swift MorseCourse.swift) do not match. (2) Regex literals: comment stripper now keeps extended #/.../# (multi-line, escapes skipped) and bare /.../ literals following Swift 6 lexer behaviour verified with 'swiftc -swift-version 6 -dump-parse' probes (left-bound division incl. postfix !, keyword exception e.g. return/case, first unescaped / closes, / followed by / or * is a comment, no closing after whitespace). Fails closed on a comment marker straight after a backslash, an unterminated block comment, or an unterminated extended regex. (3) Added .hh/.hxx/.inl/.ipp/.s/.S to the non-Swift list. Self-test: 10 new failing fixtures plus stat-identifier and division/regex trailing-comment lines in the clean fixture; the HEAD (pre-fix) checker fails all 10 new fixtures, and 8 targeted mutations (loose stat, no left-bound, no keyword exception, no backslash guard, no unterminated report, no extended regex, no bare regex, old C list) each fail at least one fixture. Real-tree --verbose evidence is identical before/after (43 call-site lines). Checks: pnpm test:apple-required-reasons -> 'passed self-test fixtures.'; pnpm check:apple-required-reasons -> passed (CanadianHam 53 SystemBootTime [35F9.1], UserDefaults [CA92.1]; Watch 31 SystemBootTime [35F9.1]; TV 33 / Vision 32 UserDefaults [CA92.1]); pnpm check:links passed; git diff --check clean; test guard 'Test guard passed: no guarded changes found in 5abb6934...HEAD.' No xbuild run.

PR #1064 Copilot round 3 (commit 1bf0a0a1a2739129d0bc6f4a61e7f253bb43933d). (1) Module-qualified bypass: the UserDefaults pattern '@AppStorage' missed '@SwiftUI.AppStorage'; it now matches the name AppStorage, covering @SwiftUI.AppStorage, a '@SwiftUI' qualifier with '.AppStorage' on the next line, and AppStorage(wrappedValue:_:) (swiftc -swift-version 6 accepts the qualified forms and rejects '@ AppStorage' and a '(' on the next line). Audit of the other patterns: Foundation.UserDefaults, Foundation.ProcessInfo...systemUptime, Darwin.mach_absolute_time, Foundation.FileAttributeKey.modificationDate, Foundation.URLResourceKey.volumeAvailableCapacity*Key and UIKit.UITextInputMode.activeInputModes were already matched (whole-word names); the only other gap was module-qualified stat with a line break before the '.', fixed below. swiftc rejects whitespace after '.', so no pattern needs it. (2) Multi-line: apiUsage now runs every pattern (flags gm) over the whole comment-stripped file and reports each usage on the line where the match starts (binary search over line offsets), once per spelling and line, sorted by line then pattern, so the evidence order is unchanged. Qualified stat allows whitespace or a line break before the '.', and lookbehinds keep the reported line on 'stat'. The comment/regex stripper is unchanged. Note: swiftc -dump-parse shows 'stat' followed by '(path, ptr)' on the next line is an unapplied reference plus a separate tuple, not a call; it is still matched conservatively. (3) Evidence doc: Scanning/Self-test text updated, and the Limitations now list the bare-stat value uses that are not flagged (apply(stat), return stat, [stat], x ?? stat). Fixtures: @SwiftUI.AppStorage (including the multi-line form); module-qualified spellings in all five categories (checks line order and per-line dedupe); multi-line stat spellings (stat then '(' on the next line, '=' then 'stat' on the next line, Darwin then '.stat', Glibc then '.statfs'); multi-line creationDate/systemUptime; a 'return stat' false-positive guard in the clean fixture. Mutations: the HEAD checker fails the four new or changed fixtures. Each of line-based matching, the qualified stat without a line break, @AppStorage-only, no line sort, no per-line dedupe, an off-by-one line number, and no m flag fails at least one fixture. The real-tree --verbose output is identical before and after (43 evidence lines). Checks: node scripts/test-check-apple-required-reasons.mjs -> 'passed self-test fixtures.'; node scripts/check-apple-required-reasons.mjs -> passed (CanadianHam 53 SystemBootTime [35F9.1], UserDefaults [CA92.1]; Watch 31 SystemBootTime [35F9.1]; TV 33 / Vision 32 UserDefaults [CA92.1]); pnpm typecheck exit 0; pnpm test exit 0 (Vitest 2 files / 23 tests and 18 files / 283 tests passed); pnpm check:links 'Markdown relative links verified.'; git diff --check clean; test guard 'Test guard passed: no guarded changes found in ae1449ad...HEAD.' No xbuild run; AC2-AC4 left to the coordinator.
<!-- SECTION:NOTES:END -->
