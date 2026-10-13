---
id: TASK-38.5
title: 'Figure checker: text overlap, edge and label-proximity checks'
status: Done
assignee:
  - '@worker'
created_date: '2026-10-12 15:42'
updated_date: '2026-10-13 21:54'
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

Follow-up refinement: relaxed text proximity to 0.08 × smaller font only for aligned vertical stacks; offset stacks/side neighbours stay at 0.25 × size and true overlaps still fail. Validation: self-test now has 13 fixtures; current branch pnpm check:figures passes 3 figures; running this script from task-38.2 passes 8 figures. qlmanage thumbnails for task-38.2 resistor-colour-code and metric-prefix-ladder showed no real overlap. Read-only task-38.3 still fails overlap cases in batteries-dc-supplies-ripple, control-terminals, distress-urgency-safety-board, grounding-lightning-rf-safety, records-maps-locators, and yagi-receiver-specs. Read-only task-38.4 still fails daytime-absorption-frequency-window, filter-response-sketches, loop-antenna-patterns, and transformer-resonance-meters.

Review a1805a9 follow-up: fixed items 1-8 by adding a monospace width floor, loud failures for unsupported SVG/text/path features, per-line tspan measurement, S/T and relative path parsing self-tests, restored 0.25× font-size edge clearance, shape pass fixtures, and filled polygon/circle checks. Validation: node --check scripts/check-figures.mjs; node scripts/check-figures.mjs --self-test (33 fixtures); pnpm check:figures on this branch/38.1 (3 SVGs); read-only task-38.2 script run passed 8 SVGs after qlmanage review of newly flagged approved figures showed false positives; read-only task-38.3 still fails amplifiers-diodes, batteries-dc-supplies-ripple, control-terminals, controls-digital-voice-packet; read-only task-38.4 still fails daytime-absorption-frequency-window, interference-troubleshooting-map, loop-antenna-patterns, propagation-paths-skip-zone, transformer-resonance-meters, vhf-unusual-propagation-modes.

Re-review approve-with-notes follow-up: applied notes from r385-2. Fill checks now use per-glyph fill bounds with descender bottoms, near-miss/just-touching fill fixtures, a differing-anchor stack fixture, <style> failures even inside skipped defs, marker-* failures, meaningful S/T and inline-tspan fixtures, dx/dy-only tspan failure, unitless shape geometry, transparent fill handling, accented-capital height, and pnpm check:figures now runs --self-test. Validation: node --check scripts/check-figures.mjs; node scripts/check-figures.mjs --self-test (45 fixtures); pnpm check:figures on this branch/38.1 (3 SVGs); read-only task-38.2 passed 8 SVGs; read-only task-38.3 passed 23 SVGs; read-only task-38.4 passed 13 SVGs.

Merged into task-38.1-figure-pipeline after reconciling with task-38.1's Apple metadata generation, directive/DOCTYPE hardening, CI self-test wiring, and docs. Validation on the reconciled branch: node scripts/check-figures.mjs --self-test (52 fixtures); pnpm check:figures; pnpm check:figures:fix produced no diff; pnpm check:schemas; pnpm import:check; content explanation/quiz/coverage/originality checks; pnpm --filter @canadian-ham/web test.

Confirmed task-38.5 is included in PR #212 via the task-38.1 branch and remains Done for merge with task-38.1.

Copilot PR #212 figure-checker follow-up landed on task-38.1: nested <tspan> elements now fail with self-test coverage, and --fix skips asset generation whenever validation/reference errors already exist. Validation: node --check scripts/check-figures.mjs; node scripts/check-figures.mjs --self-test (53 fixtures); pnpm check:figures; destructive --fix temp-copy check kept generated asset checksum unchanged on malformed input.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added conservative figure text bounds, text proximity, viewBox edge, and stroke-intersection validation with inline self-tests and docs. Verified all three task-38.1 figures pass after qlmanage visual review and checker tuning; web/content figure-related checks pass.
<!-- SECTION:FINAL_SUMMARY:END -->
