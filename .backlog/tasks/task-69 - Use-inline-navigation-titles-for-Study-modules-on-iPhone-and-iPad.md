---
id: TASK-69
title: Use inline navigation titles for Study modules on iPhone and iPad
status: Done
assignee:
  - '@worker'
created_date: '2026-10-23 02:59'
updated_date: '2026-10-23 11:23'
labels:
  - apple
dependencies: []
references:
  - TASK-55
  - TASK-52
documentation:
  - docs/evidence/task-52/README.md
priority: medium
ordinal: 149000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner-delegated decision 2026-10-22: Study module screens on iOS/iPadOS use inline native navigation titles, like practice sessions (TASK-55). TASK-52 evidence found seven of eight large module titles cut at default size. Keep navigation title text and the full wrapped content header; preserve non-iOS behaviour. This replaces the earlier TASK-52 decision to retain automatic/large Study titles, without removing the native-title accessibility-label/content-header requirements.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Study module navigation titles are inline on iOS/iPadOS with unchanged title text and full wrapped content headers; macOS/tvOS/visionOS behaviour is unchanged.
- [x] #2 TASK-52 title sweeps still require full native accessibility labels and full wrapped module headers, and refreshed evidence documents inline module frames at EN/FR default and AX-XXXL sizes.
- [x] #3 All four CanadianHamTitleSweeps cases pass on iPhone 17 Pro; targeted existing Study/module navigation tests and light/dark Learn audits pass on iPhone and iPad, with per-test results recorded and no full suites.
- [x] #4 Apple text-source/localization checks and test guard pass; changes are committed and pushed without a PR.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add the iOS-only inline title modifier to ModuleLessonListView, following PracticeSessionView and preserving module title/header and all non-iOS behaviour.
2. Retain TASK-52 strict module header/full navigation-label checks, explicitly note native inline expectations, and refresh the module evidence/measurements rather than weakening assertions.
3. Run all four CanadianHamTitleSweeps cases via nohup xbuild on iPhone 17 Pro, then targeted existing Learn navigation/reader/light-dark audit tests on iPhone and iPad with -only-testing. Respect the shared lock, grep poll only, and run no full suites.
4. Run text-source/localization/test-guard checks, record per-test evidence and platform scope, finalize TASK-69, commit and push without a PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Coordinator confirmed IDs swapped across worktrees: this Study task is TASK-69 (audit lane is TASK-70). Renamed branch to task-69-study-module-inline-titles. ModuleLessonListView is shared by iOS/macOS only; tvOS/visionOS use their platform Learn views. Modifier will be #if os(iOS), so all non-iOS behaviour stays unchanged.

Implementation commit 23dc551b adds only #if os(iOS) navigationBarTitleDisplayMode(.inline) after the unchanged module title. Module content header is unchanged. Existing title sweeps keep their full-text/frame/height header assertions and now explicitly require module navigation element existence and absence of ellipsis in its complete accessibility label, matching practice. README marks the former large-title evidence historical. Text-source check, test-guard self-test, test-guard origin/main...HEAD (merge-base 49b318df5fc0ad8ca9876141bd2ddaa3b0d26d6b), and git diff --check pass. Nohup UI driver /tmp/task-69/run-ui.sh queues all four title sweeps then testLearnOpensLessonAndShowsFirstHeading, testLearnUserNavigationOpensLessonQuiz, testAccessibilityAuditLearnFlowLight and Dark on iPhone 17 Pro and iPad Pro 13-inch (M5); l10n check separately queued. All wait for shared lock; no other builds touched. Initial foreground l10n attempt timed out waiting for lock (no build/test result); restarted with nohup. Logs under /tmp/task-69.

Coordinator finished after the worker timeout: TitleSweeps 4/4 passed on iPhone 17 Pro (799/1289/666/1411 s); Learn open/quiz/light/dark audits passed on iPhone 17 Pro and iPad Pro 13-inch (M5). Inline module titles fit at default size in EN/FR; at AX-XXXL only B-003 is visually truncated (exception applies). Evidence README section 'TASK-69 inline Study module validation'; TSV module rows refreshed. Internal review approved with notes (README items addressed).
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Study module screens on iOS/iPadOS use inline navigation titles; default-size module titles now fit, and only B-003 is cut at AX-XXXL under the documented exception.
<!-- SECTION:FINAL_SUMMARY:END -->
