---
id: TASK-11.2
title: Extend the interim content policy to Advanced source files
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-02 01:12'
updated_date: '2026-10-02 11:52'
labels:
  - content
  - docs
milestone: m-1
dependencies: []
parent_task_id: TASK-11
priority: medium
ordinal: 34000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Why: the owner approved (2026-10-02) extending the interim private-development policy so verbatim Advanced bank files can be vendored. Advanced ingestion is blocked until docs/content-licensing.md says so. See docs/proposals/advanced-course.md (owner decisions in task-11 notes).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 docs/content-licensing.md covers verbatim Advanced source files under content/sources/ised/advanced-*/ with the same conditions as Basic (private repo, attribution, permission tracked by task-1.1)
- [x] #2 AGENTS.md project notes no longer say the Basic 2025 bank is the only allowed source, and name the Advanced exception
- [x] #3 pnpm check:links passes
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Review the approved Advanced-course decisions and current licensing/project-note wording.
2. Update docs/content-licensing.md to extend the private-development policy and content-class table to Advanced source directories without changing public-release gates.
3. Update AGENTS.md project notes to keep Basic active while naming the Advanced vendoring exception.
4. Run pnpm check:links, then record evidence, check acceptance criteria, summarize, and mark Done.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented documentation-only policy update in AGENTS.md and docs/content-licensing.md. Evidence: docs/content-licensing.md now names content/sources/ised/advanced-<title-page-date>/ under the interim private-development policy with private-repo constraints, verbatim storage, SHA-256 source manifests, attribution/disclaimer, and T-007/task-1.1 permission tracking; AGENTS.md keeps Basic 2025-07-15 as the active app bank and names the Advanced vendoring exception with no active Advanced app bank. Validation passed: pnpm check:links; git diff --check origin/main...HEAD; no files under content/sources/ised/advanced* in this branch.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Extended the interim private-development policy to Advanced source files without vendoring any files. Updated AGENTS.md so Basic 2025-07-15 remains the active app bank while Advanced source vendoring is allowed only under docs/content-licensing.md and no Advanced bank is active in apps. Verified with pnpm check:links, git diff --check origin/main...HEAD, and an empty content/sources/ised/advanced* branch diff.
<!-- SECTION:FINAL_SUMMARY:END -->
