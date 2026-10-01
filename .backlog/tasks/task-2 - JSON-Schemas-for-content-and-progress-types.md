---
id: TASK-2
title: JSON Schemas for content and progress types
status: Done
assignee:
  - '@pi-worker'
created_date: '2026-10-01 02:27'
updated_date: '2026-10-01 17:02'
labels:
  - content
  - 'legacy:T-003'
milestone: m-0
dependencies: []
ordinal: 9000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Content and progress data cross several boundaries: the ISED importer writes generated JSON, lessons and explanations are hand-written, and the web and Apple apps exchange progress through a shared export format. Today only scattered TypeScript types and ad-hoc checks guard those shapes, so a drifting field (e.g. an importer change or an export change on one platform) can break the other side silently. Explicit JSON Schemas give one contract that both platforms and the content tools can validate against. Legacy: T-003.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Schemas exist in packages/schemas for every listed type
- [x] #2 The schemas match the current generated bank JSON, the lesson front matter, the explanation JSON and the progress export format
- [x] #3 The schemas are documented in packages/schemas/README.md
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add draft 2020-12 JSON Schema files under packages/schemas for generated bank arrays/manifests, lesson/module front matter, explanations, progress exports, and engine fixtures, using shared definitions for IDs, localized text, timestamps, progress records, exam attempts, and fixture records.
2. Add a zero-dependency Node validation script in packages/schemas that implements the limited JSON Schema keywords used, parses lesson front matter into JSON, validates all real content/generated/basic-2025-07-15 JSON, content/lessons front matter, content/explanations JSON, fixtures/engine JSON, and representative progress exports covering web/Apple-compatible required and optional fields.
3. Document the schema inventory, draft/version, validator keyword subset, and validation command in packages/schemas/README.md.
4. Run the schema validation script plus pnpm typecheck, pnpm test, and pnpm check:links; then record evidence, check satisfied acceptance criteria, and finalize the task if all pass.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented draft 2020-12 schemas and zero-dependency validator in packages/schemas. Validation evidence: node packages/schemas/validate.mjs -> Schema validation passed: 1042 validation target(s). Validated generated bank JSON, subsection titles, lesson front matter, explanations, engine fixtures, and progress export samples. pnpm typecheck, pnpm test, and pnpm check:links passed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added draft 2020-12 JSON Schemas for generated bank content, lesson/module front matter, explanations, progress export v1, subsection titles, and engine fixtures under packages/schemas. Added packages/schemas/validate.mjs, a zero-dependency validator for the documented keyword subset, and documented inventory/usage/limitations in packages/schemas/README.md. Verified with node packages/schemas/validate.mjs (1042 validation targets), pnpm typecheck, pnpm test, and pnpm check:links.
<!-- SECTION:FINAL_SUMMARY:END -->
