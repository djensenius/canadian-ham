---
id: TASK-93
title: Make App Store-eligible packaging the TestFlight default
status: In Progress
assignee:
  - '@worker'
created_date: '2026-11-04T02:25:00Z'
updated_date: '2026-11-04T02:32:00Z'
labels:
  - release
  - apple
dependencies:
  - TASK-86
  - TASK-85
priority: high
type: enhancement
ordinal: 176000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner request 2026-11-03: new TestFlight builds should also be eligible for later App Store distribution, and this should be the standard. Existing beta lanes default to internal-only exports and opt in the restricted official reference sheet. Change packaging defaults without changing permission, upload, tester, submission, Xcode Cloud ownership or signing gates. Requested upload is separately blocked by TASK-1.7; export-only preparation is allowed.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 All four beta lanes default to App Store-eligible export options and exclude the internal-only official reference sheet; explicit internal-only mode remains available.
- [ ] #2 Invalid and conflicting options fail closed; App Store-eligible uploads and protected distribution artifact uploads remain blocked by existing gates; permitted internal fallback delivery explicitly remains internal-only.
- [ ] #3 Active TestFlight, distribution, owner-gate and agent instructions consistently document the new default, explicit fallback, and unchanged owner/upload/licensing gates.
- [ ] #4 Focused Fastlane, reference-sheet, Xcode Cloud and documentation checks pass and signed export inspection evidence is recorded without claiming an upload.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Default the existing distribution option to true, retaining explicit distribution:false for the internal-only reference-sheet fallback and preserving export-only restrictions. 2. Add focused safety/default-mode tests and align active release documentation and agent guidance, including owner-only Xcode Cloud settings. 3. Run focused local harnesses; obtain independent and Copilot review and green exact-head CI before normal merge. 4. Prepare permitted signed export-only artifacts through xbuild, inspect packaging/privacy/entitlements and record actual evidence. Never upload before existing gates.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implementation prepared on task-93-appstore-beta-default: omitted distribution now means true for all four beta lanes; explicit distribution:false retains internal-only packaging and the decision-2A official-sheet opt-in. Supplied nil/empty/malformed booleans fail closed. Default/explicit App Store-eligible uploads still require export_only:true and wait for TASK-1.7/TASK-85; the existing protected artifact symlink/case guard is unchanged. Permitted internal fallback upload calls now explicitly set distribute_external:false, with no group changes. Active TestFlight/distribution/owner-gate/agent guidance plus dependent licensing and release-checklist references describe the default, explicit fallback, and unchanged gates. Historical evidence, Swift/project files, Xcode Cloud scripts and GitHub workflows were not edited.

Checks (macOS, stubbed build/sign/upload harnesses only): pnpm test:fastlane -> 12 runs, 976 assertions, 0 failures, 0 errors, 0 skips; ruby -c fastlane/Fastfile -> Syntax OK; pnpm test:official-reference-sheet -> Official reference sheet gate self-test: YAML scopes, all 13 generated Release configurations, renamed assets (all extensions), inline JS/CSS image data URLs, transcript content and clean study-sheet fixtures passed. / Official reference sheet gate: Debug/internal opt-in, default Release exclusion and stale-resource removal passed.; pnpm test:xcode-cloud-scripts -> xcode-cloud-ci-scripts-test: 131 passed, 0 failed (includes real no-network, iCloud and required-reason guards/self-tests); pnpm check:links -> Markdown relative links verified.; git diff --check -> exit 0, no findings. The first pnpm command automatically reused 101 cached packages (0 downloaded); no explicit install command or lockfile change. No Apple runtime suites: tooling/docs only.

Coordinator handoff: no real archive, export, upload, Apple account/credential change, Xcode Cloud change/trigger, push or PR. AC4 remains unchecked and task stays In Progress; signed export inspection and final acceptance/review belong to the coordinator. Current TASK-1.7 upload gate is still unsatisfied; packaging eligibility never grants permission. Never move a distribution artifact to bypass the protected-path guard. The coordinator reported latest ASC builds unchanged (iOS 202610271751, macOS 202610271753, tvOS 202610271756, visionOS 202610271757); this worker made no ASC calls.

No real archive/export/DerivedData directories were created. Default archive paths are fastlane/archives/appstore/<ios|mac|appletvos|xros>/<CanadianHam|CanadianHam|CanadianHamTV|CanadianHamVision>-<YYYYMMDDHHMM>.xcarchive; export directories are fastlane/builds/appstore/<platform>/<YYYYMMDDHHMM>/. Explicit internal-only mode uses the corresponding roots without appstore/. Fastfile does not set -derivedDataPath; current XBUILD_DERIVED_DATA_ROOT is unset. For isolated coordinator cleanup, set XBUILD_DERIVED_DATA_ROOT=/tmp/canadian-ham-task-93-derived-data on the Fastlane invocation; the installed wrapper and Fastlane working directory resolve its derived-data directory to /tmp/canadian-ham-task-93-derived-data/fastlane-d80e88a4. Run platforms serially and retain evidence before deleting only task-owned outputs, given the low free disk space.

Local post-archive guard: from this worktree run CI_XCODEBUILD_ACTION=archive CI_XCODEBUILD_EXIT_CODE=0 CI_ARCHIVE_PATH=<absolute .xcarchive path> bash apps/apple/ci_scripts/ci_post_xcodebuild.sh. CI_PRIMARY_REPOSITORY_PATH may be set to this worktree explicitly; otherwise ch_init uses the repository containing the script. CI_XCODE_SCHEME, CI_PRODUCT_PLATFORM and CI_BUILD_NUMBER are optional log context for this post guard. It scans every app/appex (including watch) for forbidden entitlements and official-sheet content, not export eligibility/privacy completeness; separately inspect the exported IPA/PKG and manifests. Do not set a nonzero CI_XCODEBUILD_EXIT_CODE, which intentionally skips failed archives.
<!-- SECTION:NOTES:END -->
