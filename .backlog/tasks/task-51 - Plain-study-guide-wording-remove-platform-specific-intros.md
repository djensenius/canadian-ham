---
id: TASK-51
title: 'Plain study-guide wording: remove platform-specific intros'
status: To Do
assignee: []
created_date: '2026-10-16 08:06'
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
