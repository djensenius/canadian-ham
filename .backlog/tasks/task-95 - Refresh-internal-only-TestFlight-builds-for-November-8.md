---
id: TASK-95
title: Refresh internal-only TestFlight builds for November 8
status: In Progress
assignee:
  - '@worker'
created_date: '2026-11-08T05:14:00Z'
labels:
  - release
  - apple
  - owner-gate
dependencies:
  - TASK-94
references:
  - docs/release/testflight.md
  - docs/release/distribution.md
documentation:
  - docs/release/owner-gates.md
priority: high
type: chore
ordinal: 178000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner request 2026-11-08: "Please upload a new internal testflght build". This explicitly authorizes a new internal-only refresh matching TASK-94 across iOS with embedded watchOS, macOS, tvOS and visionOS, using the documented temporary distribution:false fallback only while eligible. Accepted main is 20260a9c766889737d9f0f891b02e414688341d4, version 1.0.0; only release-record docs and build-number floors changed since the November 5 uploaded app source. No Xcode Cloud trigger or settings change, external testing, App Store submission or distribution-eligible upload is authorized. Verify live ASC/Cloud state first and stop affected fallback uploads if Cloud has already shipped that platform.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 New signed internal-only Release exports for all four platforms are built from accepted main and inspected before upload, including live fallback eligibility, increasing build numbers, signing/team, testFlightInternalTestingOnly, offline/no-cloud capabilities, privacy manifests, and matching phone/watch versions and payload.
- [ ] #2 Each inspected artifact is uploaded with external distribution disabled and the exact platform/version/build reaches VALID and internal-testable state, verified read-only in App Store Connect; no workflow, settings, tester groups, external delivery or submission is changed.
- [ ] #3 Verified uploaded build numbers are recorded in build-number-floors and the current release/watch documentation through the required reviewed PR; relevant release-script checks and links pass, and owner hardware gates stay pending.
- [ ] #4 Only generated files owned by this release are cleaned up; archives needed for crash symbolication are retained, and provenance, artifact hashes, processing evidence and limitations are recorded.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Read-only preflight of live ASC builds/Cloud provenance and signing/tool readiness; keep main at the accepted SHA and leave unrelated status.md untouched. Run required quick package checks and Apple guards on main; no full Apple suites for unchanged app code. 2. From main, export one platform at a time through fastlane distribution:false export_only:true and xbuild; inspect and hash each exact signed artifact before a separate explicit internal upload. 3. Verify each uploaded build reaches VALID/internal-only/internal-testable state with GET-only ASC checks. 4. In this task worktree only, update floors and directly related release/watch records; run pnpm test:xcode-cloud-scripts, pnpm check:links and diff checks; record evidence using Backlog CLI. 5. Retain the archives, clean owned temporary exports/inspection files, commit and request local review; coordinator pushes, obtains Copilot review and exact-head green CI, normally merges the records PR and runs post-merge quick checks.
<!-- SECTION:PLAN:END -->
