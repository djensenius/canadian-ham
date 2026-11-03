---
id: TASK-92
title: Align release instructions with owner-triggered Xcode Cloud
status: Done
assignee:
  - '@worker'
created_date: '2026-11-03T09:46:00Z'
updated_date: '2026-11-03T09:50:00Z'
labels:
  - documentation
  - release
dependencies:
  - TASK-86
  - TASK-91
priority: medium
type: docs
ordinal: 175000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The approved agentic delivery uses Xcode Cloud and does not authorize uploads. Active instructions still direct agents to upload with Fastlane after merges, contradicting that policy. Align the governing instructions and linked release runbooks without changing tooling, licensing gates, or historical evidence.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Active instructions prefer owner-triggered Xcode Cloud and explicitly state that merge or review approval does not authorize uploads or release-workflow triggers; no automatic post-merge upload direction remains.
- [x] #2 Fastlane export-only distribution checks and conditional explicitly authorized internal fallback instructions remain usable; build-number floors, option (b) platform restrictions, signing safeguards and all existing release gates are preserved.
- [x] #3 Linked TestFlight, distribution, owner-gates, release checklist and pending watch-delivery instructions agree; no upload, workflow trigger, Apple source/project or tool behavior changes are performed.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Read the six active policy documents and preserve existing release gates, historical evidence and fallback safeguards.
2. Align owner-triggered Xcode Cloud preference and separately authorized Fastlane fallback wording; keep local inspection exports explicitly export-only.
3. Run available documentation link checks, diff whitespace checks and a focused policy/anchor scan, then commit documentation with required trailers and finalize TASK-92 through the CLI.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implementation commit: ab9dd118e6850bbde885236e8a6d9eccdd4d947b on task-92-release-policy-alignment (accepted main baseline 369506ea4ec8e1db9e51233637e66f4686d429b7). Changed only AGENTS.md, docs/release/distribution.md, docs/release/testflight.md, docs/release/owner-gates.md, docs/release/release-checklist.md and docs/testing/task-14.6-watch-release.md; task metadata is CLI-managed. Required Copilot trailers are present.

AC1 evidence: inspected the complete six-file documentation diff and scanned active policy. All six prefer owner-connected/configured/triggered Xcode Cloud, deny merge/review/internal-eligibility upload authorization and automatic post-merge uploads/triggers, and require separate explicit owner authorization for any agent-run upload. Future release-tag triggers require separate explicit owner authorization; manual owner triggering is the default. No Cloud connection or delivery is claimed.

AC2 evidence: distribution export-only commands and dedicated signing-keychain instructions are unchanged. Internal Fastlane fallback commands and retries remain conditional on separate explicit authorization and existing gates. Option (b) forbids new-version timestamp uploads for iOS/tvOS/visionOS starting with the version-bump merge; option (c) macOS fallback is optional. Floor updates remain required immediately by PR before the next Cloud archive; the owner adjusts Next Build Number under option (a). Watch/container matching covers both integer Cloud numbers and Fastlane timestamps. Licensing, release, internal-only, OS27, xbuild and signing safeguards remain intact.

AC3 evidence: preserved all headings/anchors, all historical watch evidence before the pending-owner section, the floors section and local distribution checks. The full changed-path check against accepted main contains only the six documentation files and TASK-92 metadata. No Apple source/project/config, Fastlane implementation/generated README, build-number value or tool behavior changed.

Checks (all exit 0):
- COREPACK_ENABLE_NETWORK=0 pnpm check:links: Markdown relative links verified. pnpm automatically materialized 101 cached packages (downloaded 0); no install command was run and no tracked dependency/tooling files changed.
- git diff --check: PASS
- Focused policy scan: PASS (six active documents; no obsolete automatic delivery directions)
- Heading/anchor preservation: PASS (all six documents retain their headings)
- Safeguard preservation: PASS (watch history, floors, distribution export checks, dedicated signing keychain)
- Scope check: PASS (six documentation files only, plus CLI-managed TASK-92 metadata)

Not run: Apple builds/tests on all platforms and Fastlane/Xcode Cloud harnesses, because this is documentation-only. No upload, deploy, release/workflow trigger, push, PR, visibility/history change or root-checkout edit was performed. Remaining work is outside TASK-92: owner Cloud setup/build-number decision/manual triggers, separately authorized delivery if needed, permission/release gates and physical-device checks remain pending; existing visibility concerns are unchanged.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Aligned the six active release-policy documents with owner-triggered Xcode Cloud and no automatic post-merge delivery. Preserved export-only checks, separately authorized internal Fastlane fallbacks, build-number/platform collision safeguards, signing and release gates, and historical evidence. Documentation links, whitespace, active-policy, heading/history and scope checks passed. No builds, uploads, workflow triggers or tooling changes; owner setup, delivery authorization and existing release/manual gates remain pending. Implementation: ab9dd118e6850bbde885236e8a6d9eccdd4d947b.
<!-- SECTION:FINAL_SUMMARY:END -->
