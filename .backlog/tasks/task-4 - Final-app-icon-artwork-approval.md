---
id: TASK-4
title: Final app icon artwork approval
status: In Progress
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-02 02:06'
labels:
  - design
  - blocked
  - 'legacy:T-011b'
milestone: m-0
dependencies: []
ordinal: 11000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner task. The current generated icon draft (design/app-icon/exports) is wired into all Apple targets, but the final artwork is not approved (the review scored it 5/10). Choose more generated rounds or a hand-drawn SVG, then replace the exports. Legacy: T-011b.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The owner has approved the final icon artwork
- [ ] #2 The exports in design/app-icon/exports are replaced
- [ ] #3 The icon assets are updated in every Apple target and the web manifest
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Promote the owner-approved round-3 01-hex-top hex-beam mark into a deterministic production renderer and retire obsolete antenna SVG/Swift sources.\n2. Regenerate the export contract in design/app-icon/exports, including layered Apple stacks, tvOS Top Shelf art, web icons, and the preview sheet.\n3. Install regenerated outputs into Apple asset catalogues and the web public assets without changing target membership.\n4. Inspect preview/small renders, run web and Apple validation, then check remaining acceptance criteria and mark task Done.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Generated four isolated app icon concepts under design/app-icon/concepts with deterministic raster brush script, descriptions, comparison sheet, and three README-recorded render/critique passes. Left task In Progress because AC #1 requires owner approval before exports/assets are replaced.

Round 2: replaced the hairline concept renderer with filled sumi-e stroke construction, regenerated four antenna concepts plus comparison/closeups, and recorded texture-test plus three render/critique passes. Task remains In Progress for owner review.

Round 2 steering: added owner-requested 05-hex-beam concept, expanded comparison.png and closeups.png to five columns/tiles, and kept task In Progress for owner artwork review.

Round 3: replaced the round-2 concept folders with four hex-beam studies, regenerated comparison/closeups, and recorded three render-critique passes. Task remains In Progress for owner artwork review.

Owner decision (2026-10-02): approved round-3 concept 1, design/app-icon/concepts/01-hex-top, the top-down hex beam with brushed hexagon perimeter, six straight dry-brush spreaders, hub dot, and pale zigzag W/M wire elements.
<!-- SECTION:NOTES:END -->
