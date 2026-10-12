---
id: TASK-38.5
title: 'Figure checker: text overlap, edge and label-proximity checks'
status: Done
assignee:
  - '@worker'
created_date: '2026-10-12 15:42'
updated_date: '2026-10-12 15:50'
labels:
  - content
dependencies: []
parent_task_id: TASK-38
priority: high
ordinal: 91000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Two drawing lanes repeatedly shipped figures with overlapping labels, labels running into strokes, or text past the viewBox edge, because scripts/check-figures.mjs only checks text size and stroke-touching-text. Add conservative checks so these are caught mechanically.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 check-figures fails on text-text bbox overlap or a gap under a threshold, using a conservative width estimate (CoreSVG uses a wider proportional font)
- [x] #2 check-figures fails on text extending past the viewBox and reports text whose bbox intersects any stroke segment
- [x] #3 Self-test covers each new rule; all figures on main and task-38.1 pass or the failures are listed
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Extend check-figures.mjs with SVG text bbox collection (anchors, inherited text properties, tspans) and conservative stroke geometry sampling for supported shapes/paths.\n2. Add validation rules and --self-test fixtures covering pass/fail cases for text spacing, viewBox edges, and stroke intersections.\n3. Document the new figure-authoring/checker rules in docs/figures.md.\n4. Run figure, content, web, and self-test checks; adjust only checker estimates unless rendered source proves a real figure issue; then finalize task metadata and commit.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented conservative text geometry and stroke intersection checks in scripts/check-figures.mjs with inline --self-test fixtures. Rendered the three task-38.1 figures with qlmanage after initial checker false positives; visual review showed no real text/stroke or text/text overlap, so I tuned the stroke check to use estimated ink bounds and cap/lowercase-height text bounds rather than changing figure SVGs. pnpm check:figures now reports 3 SVG sources and 3 lesson references passing.

Validation passed: node scripts/check-figures.mjs --self-test (11 fixtures); pnpm check:figures (3 SVG sources, 3 lesson references, Apple assets in sync); pnpm build:web; pnpm --filter @canadian-ham/web test passed on rerun after one unrelated loading timeout; pnpm --filter @canadian-ham/content-tools test; pnpm check:links; pnpm check:schemas; pnpm import:check. No figure SVGs changed, so no Apple xbuild run.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added conservative figure text bounds, text proximity, viewBox edge, and stroke-intersection validation with inline self-tests and docs. Verified all three task-38.1 figures pass after qlmanage visual review and checker tuning; web/content figure-related checks pass.
<!-- SECTION:FINAL_SUMMARY:END -->
