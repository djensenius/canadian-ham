---
id: TASK-1.8
title: Purge out-of-scope reference PDFs from history before going public
status: To Do
assignee: []
created_date: '2026-10-02 15:27'
labels:
  - licensing
  - release
milestone: m-0
dependencies:
  - TASK-1.1
parent_task_id: TASK-1
priority: high
ordinal: 54000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the ISED request submitted on 2026-10-02 deliberately left out the Basic reference sheets (reference PDFs), but the English Basic reference PDFs are committed under content/sources/ised/basic-2025-07-15/ for private development. The public-release gate requires the repository history to hold nothing outside the recorded permission scope, so even if ISED grants everything requested, making the repo public would publish those PDFs. Remove them from history (git filter-repo) or publish from a fresh repository, as the gate's contingency allows, before task-1.7.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The reference PDFs and any other ISED artifact outside the recorded permission scope are absent from every commit of the repository that will be made public, verified by a history scan (e.g. git log --all -- <paths> and a blob-hash search)
- [ ] #2 The source manifest, SHA256SUMS and docs no longer reference the removed files, and pnpm import:check, pnpm check:links and the content checks pass
- [ ] #3 The chosen method (filter-repo or fresh repo) and its verification are recorded in docs/content-licensing.md and the release checklist
<!-- AC:END -->
