---
id: TASK-36
title: Apple bundles exclude content README.md files
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-10 17:18'
updated_date: '2026-10-10 18:49'
labels:
  - apple
dependencies: []
ordinal: 76000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Release archives copy content/lessons/README.md and content/explanations/README.md into the app bundle (seen in fastlane/archives/mac/.../Contents/Resources/{lessons,explanations}/README.md). They are authoring docs with repo-relative links, not app content.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 iOS/macOS/tvOS/visionOS app bundles contain no README.md (or other authoring Markdown) from content/
- [ ] #2 The bundle guard tests (11.11) assert it
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Confirm Apple content resource layout and which Markdown files are runtime lesson content versus authoring docs.\n2. Update apps/apple/project.yml so CanadianHam app/test content resources continue bundling runtime lesson Markdown while excluding content README.md/authoring Markdown, then regenerate the Xcode project twice and verify deterministic output.\n3. Extend bundle guard tests for iOS/macOS, tvOS, and visionOS to fail on bundled README.md files while preserving existing ContentLibrary load coverage.\n4. Prove the guard fails without the exclusion, restore the final code, run targeted tests, then commit and run the required full Apple suites, recording per-test evidence in Backlog.
<!-- SECTION:PLAN:END -->
