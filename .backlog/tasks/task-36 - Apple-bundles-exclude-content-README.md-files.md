---
id: TASK-36
title: Apple bundles exclude content README.md files
status: To Do
assignee: []
created_date: '2026-10-10 17:18'
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
