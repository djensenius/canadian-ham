---
id: TASK-12.9
title: Morse text Unicode consistency across TS and Swift
status: To Do
assignee: []
created_date: '2026-10-02 14:52'
labels:
  - web
  - apple
  - morse
milestone: m-1
dependencies:
  - TASK-12.2
parent_task_id: TASK-12
priority: low
ordinal: 55000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the task-12.2 re-review found two small TS/Swift differences in text handling. (1) TS treats U+FEFF (byte-order mark) as whitespace but not U+0085 (NEL); Swift does the reverse, so pasted text can be skipped in one language and reported invalid in the other. (2) A decomposed É in the learner's typed copy scores as a correct E plus an inserted mark, while a precomposed É scores as one wrong character; pass/fail is the same but the error breakdown differs.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 TS and Swift use one explicit shared whitespace list, with fixtures for U+FEFF and U+0085
- [ ] #2 The received copy is NFC-normalised before scoring in both languages, with a fixture showing decomposed and precomposed É score identically
- [ ] #3 pnpm test and swift test in packages/morse-swift pass
<!-- AC:END -->
