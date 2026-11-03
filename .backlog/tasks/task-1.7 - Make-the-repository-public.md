---
id: TASK-1.7
title: Make the repository public
status: To Do
assignee: []
created_date: 2026-10-01 02:27
updated_date: '2026-11-03T03:15:00Z'
labels:
  - release
  - legacy:T-009
  - owner-gate
milestone: m-0
dependencies:
  - TASK-1.1
  - TASK-1.6
  - TASK-1.8
parent_task_id: TASK-1
ordinal: 8000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Only after the ISED permission is recorded and the release candidate pass is complete, make djensenius/canadian-ham public. Legacy: T-009.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The ISED permission is recorded
- [ ] #2 The release candidate pass is Done
- [ ] #3 The owner has approved making the repository public
- [ ] #4 The repository visibility is public
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Coordinator 2026-11-03 (TASK-83 tracking pass): GitHub already reports djensenius/canadian-ham as public (isPrivate false), but TASK-1.1 still records the ISED permission as pending and TASK-1.8 (history purge) is not done. The owner needs to reconcile this: either record the permission and the decision to publish early, or return the repository to private until the gates pass. Agents must not change visibility.

Owner sign-off required before App Store submission (from TASK-85 review): the Apple privacy manifests declare User defaults reason CA92.1 for CanadianHam, including the iOS/macOS read of the app's own-domain AppleLanguages key via persistentDomain(forName: Bundle.main.bundleIdentifier) (it can hold the per-app language chosen in system Settings). Coordinator decision 2026-11-02: keep CA92.1, with fallbacks (drop the external-selection adoption and legacy French nil check, or request a new reason from Apple). The owner must explicitly sign off this decision before submission; see docs/release/privacy-label-evidence.md, section 'Required-reason API review (TASK-85, 2026-11-03)' > 'Why these reasons', and the required-reason item in docs/release/release-checklist.md.
<!-- SECTION:NOTES:END -->
