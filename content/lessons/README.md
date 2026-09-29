# content/lessons

Purpose: original, platform-neutral lesson Markdown and front matter.

Belongs here:

- Original lesson outlines and prose.
- Front matter mapping lessons to official categories and subsections.
- Links to permitted reference metadata where licensing allows.

Must not go here:

- Verbatim ISED question-bank records or PDFs.
- Copied RAC, Coax Publications, or other third-party study-guide prose.
- Generated importer output.

Relevant docs: [`../../docs/requirements.md`](../../docs/requirements.md), [`../../docs/architecture.md`](../../docs/architecture.md), [`../../docs/content-licensing.md`](../../docs/content-licensing.md).

## Outline structure

This outline contains 8 modules, one per official category, and 36 lesson outline files. Lesson bodies intentionally contain only learning objectives, key concepts, coverage IDs, and teaching notes. They cite official question IDs and subsection IDs, but do not paste official question or answer text.

## Pedagogical order

The recommended learning order is:

1. M5 — Basic Electronics and Theory (B-005): Start with quantities, circuit relationships, AC behaviour, and measurements before applying them to radio hardware.
2. M4 — Circuit Components (B-004): Introduce the parts used in transmitters, receivers, power supplies, and filters after the basic equations are familiar.
3. M6 — Feedlines and Antenna Systems (B-006): Apply circuit ideas to the path from transmitter to antenna, then to practical antenna dimensions and patterns.
4. M3 — Station Assembly, Practice and Safety (B-003): Build full station understanding from blocks, controls, power, and safety before operating scenarios.
5. M7 — Radio Wave Propagation (B-007): Explain how radio waves travel after learners know antennas and stations.
6. M8 — Interference and Suppression (B-008): Diagnose interference after learners understand stations, filtering, antennas, and signal quality.
7. M2 — Operating and Procedures (B-002): Teach practical on-air behaviour after the station and interference foundations are in place.
8. M1 — Regulations and Policies (B-001): Finish with the legal framework once learners understand the technical and operating context that the rules govern.

This starts with electrical quantities, parts, feedlines, antennas, station blocks, safety, propagation, and interference. Operating procedure comes after learners understand what their station is doing, and regulations come last so rule details can be attached to the technical and operating context they govern.

## Coverage check

Run the zero-dependency coverage checker from the repository root:

```sh
node packages/content-tools/src/check-lesson-coverage.ts
```

The checker parses lesson front matter, compares lesson `covers` entries with `content/generated/basic-2025-07-15/subsections.json`, fails on missing or unknown subsection IDs, fails on malformed lesson/module front matter, and reports duplicate subsection coverage for review.
