---
id: TASK-7
title: Harden CI and audit scripts
status: To Do
assignee: []
created_date: '2026-10-01 02:27'
labels:
  - ci
milestone: m-0
dependencies: []
ordinal: 14000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Non-blocking review notes on scripts/check-apple-no-network.sh, its self-test, the lesson originality checker and the CI workflow.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The Swift URL-literal scan treats grep exit 2 as an error, not as no matches
- [ ] #2 The self-test covers the grep-error branch and the plutil-missing skip branch
- [ ] #3 check-lesson-originality --all fails when it checks zero files
- [ ] #4 The lesson URL scan is case-insensitive (HTTPS://, WWW.)
- [ ] #5 The import-kind rule has a sample that only that rule can match (e.g. import enum WebKit.WKNavigationType)
<!-- AC:END -->
