---
id: TASK-68
title: Harden the web official-sheet exclusion check with asset hashes
status: To Do
assignee: []
created_date: '2026-10-22 03:34'
labels:
  - release
  - tests
dependencies: []
ordinal: 148000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-44.4 review note: the default web build check finds official pages by file name only; a renamed or inlined PNG would pass. Compare against the SHA-256 list in the reference README.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The default web build check fails when any output file matches an official page SHA-256, including renamed files
<!-- AC:END -->
