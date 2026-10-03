---
id: TASK-12.10
title: Gate platform Morse initial-screen launch arguments
status: Done
assignee: []
created_date: '2026-10-03 02:07'
updated_date: '2026-10-03 13:30'
labels: []
milestone: m-1
dependencies: []
parent_task_id: TASK-12
ordinal: 56000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Task-12.3 review found that platform-specific Morse initial-screen launch arguments can navigate to the Morse screen even when the preview setting is disabled, and the visionOS bypass is not limited to DEBUG builds. This follow-up keeps the default-off gate enforceable in automated launch paths before Morse ships.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 tvOS and visionOS initial-screen launch arguments respect the Morse isEnabled setting and keep the Morse screen hidden when the preview is off
- [ ] #2 Any test-only Morse launch bypass is DEBUG-only on platforms that need it
- [ ] #3 Platform UI tests cover that the Morse screen stays hidden when the preview is off on tvOS and visionOS
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Closed as obsolete for task-12.12: Morse is no longer gated by the preview setting, and platform Morse initial-screen launch arguments no longer bypass any off-by-default gate. Remaining platform initial-screen launch arguments are DEBUG-only on tvOS and visionOS.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Obsoleted by task-12.12 removing Morse preview gating; no launch-argument gate remains to enforce.
<!-- SECTION:FINAL_SUMMARY:END -->
