---
id: TASK-51
title: 'Plain study-guide wording: remove platform-specific intros'
status: In Progress
assignee:
  - '@worker'
created_date: '2026-10-16 08:06'
updated_date: '2026-10-16 08:07'
labels:
  - web
  - apple
  - content
dependencies: []
priority: medium
ordinal: 114000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner request 2026-10-16: treat the app as an amateur radio study guide and drop needlessly specific wording. Introductions and headers should not mention device families ('on iPhone, iPad, and Mac', 'for Apple devices'), the web app versus the native app, or bank version dates. The About page and Settings keep the factual details they need: bank version, privacy and storage statements, attribution. Applies to web and all Apple platforms, EN and FR.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Home and section intros on web and every Apple platform read as a plain study guide, with no device-family, platform or bank-date wording
- [ ] #2 Necessary facts stay where they belong (About: bank version and attribution; Settings: storage and privacy), and the App Store listing drafts are checked for the same issue
- [ ] #3 EN and FR updated; pnpm check:apple-l10n, check-apple-text-sources, web tests and the affected Apple UI tests pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Search web, Apple SwiftUI, string catalogues, tests, and App Store listing drafts for platform/device-family, web/native, and intro bank-date wording while preserving About, Settings/storage, and device-capability messages.
2. Rewrite affected EN/FR copy as plain Canadian Amateur Radio Basic study-guide wording with no layout changes.
3. Update tests that assert old copy, using the required Python JSON round-trip for Localizable.xcstrings.
4. Run the required web, localization, text-source, and targeted Apple checks; record before/after strings and finish TASK-51.
<!-- SECTION:PLAN:END -->
