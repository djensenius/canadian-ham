---
id: TASK-95
title: Refresh internal-only TestFlight builds for November 8
status: In Progress
assignee:
  - '@worker'
created_date: '2026-11-08T05:14:00Z'
updated_date: '2026-11-08T05:31:00Z'
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

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
2026-11-08 preflight: confirmed accepted main HEAD and origin/main 20260a9c766889737d9f0f891b02e414688341d4, branch main, no tracked changes; unrelated untracked status.md untouched. Relative to TASK-94 source a98b5375, only floors, three release-record docs and Backlog metadata differ; app/runtime/content/project/Fastfile/privacy sources are unchanged. Existing accepted app-test evidence is therefore reused; no iOS/macOS/tvOS/visionOS/watchOS full suite, figure plan or title sweep is warranted for this release-records-only refresh. Required fresh main checks pass: pnpm typecheck (six package checks Done), pnpm test (250 content-tools, 23 Morse, 127 calculator, 283 web tests passed, zero failures, plus figure/alphabet/official-sheet/release-permission guards), and Apple network/iCloud/required-reason guards plus all three self-tests. Disk 63 GiB; Xcode 27.2 (27B52); dedicated build keychain has three valid identities for team 9JALHNGRBQ, credential files exist mode 600 without revealing contents. Installed Homebrew Spaceship 2.241.2 is used with its existing Ruby/gem paths; no dependencies installed. Fastfile archive paths already include platform and build timestamp, so old archives/dSYMs are not overwritten. Session-only sanitized logs and GET/inspection helpers live under /Users/david/.copilot/session-state/42bab210-ecdc-4814-aef6-1c5b86a47bf0/files/task-95; live ASC/Cloud eligibility remains to be verified before any export.

Blocked 2026-11-08T05:23:25Z before any export or upload. The GET-only live preflight successfully resolved org.davidjensenius.CanadianHam to app 6821356982 (HTTP 200), read all 114 builds (HTTP 200, total 114, no next page), all 127 build-upload records (HTTP 200, total 127, no next page), and one beta group (HTTP 200, no next page). The next required request, GET https://api.appstoreconnect.apple.com/v1/apps/6821356982/ciProduct, failed with Spaceship::UnexpectedResponse: The specified resource does not exist - There is no resource of type apps with id 6821356982. The client exception did not expose its HTTP status, so none is inferred. Stopped immediately without retrying or probing another live endpoint. Missing Cloud data is not evidence that Cloud never shipped: live fallback eligibility remains unresolved for all four platforms. Complete build/group state summaries were not persisted before failure; the retained evidence proves request counts/statuses, not eligibility or current per-platform states. No export, archive, artifact inspection, upload or processing-verification lane ran; no artifact hashes or new build numbers exist. No ASC mutations, cloud/release workflow triggers, settings/tester-group changes, push, PR or merge occurred.

Blocked handoff and cleanup: kept nonsecret evidence under /Users/david/.copilot/session-state/42bab210-ecdc-4814-aef6-1c5b86a47bf0/files/task-95, especially asc-preflight-failure.json, blocked-summary.json, initial-owned-paths.json, the eight sanitized check logs and their result JSON. Removed only this session’s two helper scripts and Python bytecode; the evidence credential/JWT scan passed. All 110 pre-existing .xcarchive paths under /Users/david/Developer/canadian-ham/fastlane/archives remain unchanged (full list in initial-owned-paths.json); all old/new dSYMs are retained and no new archives were created. No export/extraction/DerivedData cleanup was needed, and no other task cache was touched. Main remains accepted SHA 20260a9c766889737d9f0f891b02e414688341d4 with only its pre-existing untracked status.md; disk 60 GiB free. No release-record source file was changed, so pnpm test:xcode-cloud-scripts and pnpm check:links were not run; git diff --check on task-note changes passed. Current recorded floors remain TASK-94 values: iOS/watch 202611050831, macOS 202611050836, tvOS 202611050840, visionOS 202611050844 (all version 1.0.0); these are historical records, not newly verified builds in this session. All TASK-95 ACs remain unchecked and status In Progress. No release-record implementation commit is justified without successful verified uploads; only CLI-managed task notes are committed. Coordinator/owner must resolve live Cloud provenance/fallback eligibility before resuming; hardware gates and TASK-1.7 distribution restrictions remain pending and unchanged.

2026-11-08 coordinator resolved the Cloud lookup blocker using the documented GET /v1/ciProducts list endpoint (Apple documentation: https://developer.apple.com/documentation/appstoreconnectapi/get-v1-ciproducts). The complete product list and each APP product app relationship succeeded: 11 products, 12 HTTP 200 requests, no product matching Canadian Ham app 6821356982 / org.davidjensenius.CanadianHam, no remaining pagination. Evidence: session files/task-95/cloud-products-resolution.json, observed 2026-11-08T05:30:16Z. Cloud is not configured for this app; the prior app/ciProduct error is not being treated as an authorization bypass. The documented internal-only fallback may proceed under this request, after confirming live latest build numbers/pending uploads. All prior passing unchanged-source quick checks and guards are retained; do not rerun them unnecessarily. No export or upload has yet occurred.
<!-- SECTION:NOTES:END -->
