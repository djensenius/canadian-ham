---
id: TASK-23
title: Raise the Apple apps to OS 27 minimums and Swift tools 6.4
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 18:11'
updated_date: '2026-10-01 18:12'
labels:
  - apple
milestone: m-0
dependencies: []
ordinal: 31000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The owner decided to target only the latest Apple platforms: iOS/iPadOS 27, macOS 27, tvOS 27 and visionOS 27, replacing the earlier minimums (iOS 18, macOS 15, tvOS 18, visionOS 2). This drops support for older devices in exchange for using current SwiftUI and platform APIs without availability checks. Xcode 27 and Swift 6.4 are already installed, but the project and Swift packages still declare the older settings.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 apps/apple/project.yml sets every target's deployment target to 27.0 (iOS, macOS, tvOS, visionOS), the project is regenerated with XcodeGen deterministically, and the Swift packages declare swift-tools-version 6.4 with matching platform minimums
- [ ] #2 Availability checks and fallbacks that only existed for older OS versions are removed, and new deprecation warnings introduced by the higher targets are fixed (no new warnings left unexplained)
- [ ] #3 The full iOS, macOS, tvOS and visionOS suites pass via xbuild on the final commit, including the accessibility audits, with per-test results in the PR
- [ ] #4 Docs that state the minimum OS versions (AGENTS.md project notes, docs/requirements.md, docs/architecture.md, apps/apple/README.md and any others) say OS 27
- [ ] #5 pnpm check:apple-network and pnpm check:apple-l10n still pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Update Apple project configuration and Swift package manifests to Swift tools 6.4 with OS 27 deployment/platform minimums, then regenerate apps/apple/CanadianHam.xcodeproj twice with XcodeGen and confirm the second generation is deterministic. 2. Remove obsolete pre-OS-27 availability fallbacks and update all minimum-OS documentation references. 3. Run package validation, pnpm Apple policy checks, warning scan, and final xbuild suites for iOS, macOS, tvOS, and visionOS using the documented destinations; record evidence before checking acceptance criteria.
<!-- SECTION:PLAN:END -->
