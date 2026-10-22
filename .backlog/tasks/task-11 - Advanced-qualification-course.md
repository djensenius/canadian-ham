---
id: TASK-11
title: Advanced qualification course
status: In Progress
assignee: []
created_date: '2026-10-01 02:27'
updated_date: '2026-10-16 08:04'
labels:
  - content
  - 'legacy:T-701'
milestone: m-1
dependencies: []
ordinal: 18000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Investigate and later build an Advanced qualification course as a separate scope from Basic. The research brief (to be source-checked) suggests building multi-bank support now and writing content after the new Advanced bank lands (ISED/RAC rewrite expected around late 2026). Legacy: T-701.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The research is source-checked and committed under docs/proposals/
- [x] #2 The owner's decisions on timing and packaging are recorded
- [x] #3 Implementation subtasks are created from the approved plan
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner decisions (2026-10-02, owner accepted all recommendations in docs/proposals/advanced-course.md):
1. Timing: build multi-bank support (Phases A-C) now, after v1, on the current 549-question Advanced bank. Defer curriculum authoring until ISED publishes the new Advanced bank, with a review date of 2027-03-31 to reconsider if it still has not been published.
2. Packaging: one app with a course switcher (web and Apple), not a separate Advanced app.
3. ISED permission scope: the request covers the current Advanced bank (TXT and PDFs), future revisions and the structured offline format; it already names these (task-1.1 tracks sending it).
4. Interim private-development policy: approved in principle to extend to verbatim Advanced source files under content/sources/ised/advanced-*/; the docs/content-licensing.md change is its own subtask and gates Advanced ingestion.

2026-10-02: implementation subtasks created from the approved plan (see Subtasks).

Blocked (2026-10-16 board cleanup): multi-bank plumbing, the current Advanced bank and the course switcher are done (11.1-11.5, 11.8-11.14). Remaining work waits for ISED: 11.6 ingest the new Advanced bank when published and 11.7 author the Advanced curriculum. No Advanced bank is active in the apps.
<!-- SECTION:NOTES:END -->
