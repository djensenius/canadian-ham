---
id: TASK-44.4
title: Official ISED reference sheet in exam tools (internal builds)
status: To Do
assignee: []
created_date: '2026-10-12 22:21'
updated_date: '2026-10-14 15:31'
labels:
  - content
  - web
  - apple
dependencies:
  - TASK-44.3
parent_task_id: TASK-44
priority: medium
ordinal: 111000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner decision 2026-10-12 (2A): use the official ISED Basic reference sheet (EN PDF in content/sources/ised/basic-2025-07-15/reference/) in the in-exam reference panel for internal TestFlight builds under the interim risk basis, while asking ISED to add the reference sheets (EN and FR) to the permission request. Public release stays blocked until ISED permission covers the sheet. Keep the original study sheet as the fallback (one config point).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 docs/content-licensing.md records the decision, the risk basis, and that public release is blocked until permission covers the sheet
- [ ] #2 A ready-to-send follow-up request to ISED (EN, asking for the reference sheets in EN and FR) is drafted for the owner
- [ ] #3 Web and Apple exam tools show the official sheet (zoomable, accessible text equivalent) in internal builds; the original sheet remains available as fallback
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Follow-up from task-44.3 review: replace or remove the dormant Apple reference-sheet loader/view/configuration code when task-44.4 implements the official ISED sheet (single configuration point, likely PDFKit), rather than leaving unreachable Markdown reference-sheet scaffolding.
<!-- SECTION:NOTES:END -->
