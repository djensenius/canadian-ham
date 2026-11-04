---
id: TASK-1.7
title: Make the repository public
status: To Do
assignee: []
created_date: 2026-10-01 02:27
updated_date: '2026-11-04T03:32:00Z'
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

TASK-87 2026-11-03: owner steps and evidence format for this task are indexed in docs/release/owner-gates.md (Sitting 1: owner decisions; repository already public while TASK-1.1 is pending). The guide restates and links these criteria without changing them.

Owner sign-off required before App Store submission (from TASK-85 review): the Apple privacy manifests declare User defaults reason CA92.1 for CanadianHam, including the iOS/macOS read of the app's own-domain AppleLanguages key via persistentDomain(forName: Bundle.main.bundleIdentifier) (it can hold the per-app language chosen in system Settings). Coordinator decision 2026-11-02: keep CA92.1, with fallbacks (drop the external-selection adoption and legacy French nil check, or request a new reason from Apple). The owner must explicitly sign off this decision before submission; see docs/release/privacy-label-evidence.md, section 'Required-reason API review (TASK-85, 2026-11-03)' > 'Why these reasons', and the required-reason item in docs/release/release-checklist.md.

Owner update 2026-11-03: "Please push. ISED is done." Upload authorization and owner confirmation of ISED completion are now recorded on TASK-1.1. Read-only verification: repository is public; TASK-1.6 remains To Do with its release-candidate criteria unchecked. This request does not establish those checks/sign-offs or satisfy missing written-permission documentation. No App Store-eligible upload occurred; no internal-only packaging substitution, Cloud setting changes or build triggers were performed.
<!-- SECTION:NOTES:END -->
