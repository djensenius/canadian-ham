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

## Quiz check

Run the strict full-repository quiz check from the repository root:

```sh
pnpm --dir packages/content-tools check:quizzes
```

To check only one module's authored quizzes while other modules are still in progress, pass that module's lesson root to the module script. For example:

```sh
pnpm --dir packages/content-tools check:quizzes:module ../../content/lessons/m4-circuit-components
```

A module-scoped run checks the quiz files referenced by lessons under that root and reports orphan quiz files only for that module's `QZ-L-00N-*` prefix.

The quiz checker also runs a **CONCEPT-CHECK OVERLAP** lint. For each concept check, it compares the prompt plus correct choice with every official question plus correct answer in the same quiz, and with each line in that lesson's `## Try it` section. The heuristic uses content-word token Jaccard after stop-word removal plus shared content-word 5-grams. Current thresholds are documented in `packages/content-tools/src/check-quizzes.ts`: Jaccard `>= 0.88`, at least `4` shared 5-grams, or at least `1` shared 5-gram with Jaccard `>= 0.82`. The check is intentionally narrow: it catches restatements of the official bank or Try-it items, but it does not attempt a broad "off-topic distractor" judgment.

## Explanation check

Run the zero-dependency explanation checker from the repository root:

```sh
pnpm --dir packages/content-tools check:explanations
```

The checker also supports category and module filters for focused content work, for example:

```sh
node packages/content-tools/src/check-explanations.ts --module M5
node packages/content-tools/src/check-explanations.ts --category B-005
```

The explanation checker includes three distractor-note lints in addition to schema, citation, and `DUPLICATE-NOTE` checks:

- Each explanation must use the `Why the distractors are wrong:` heading before per-choice notes.
- The distractor list must not include `sourceIndex 0`, and it must include a note for every incorrect choice (`sourceIndex` 1-3 in the current Basic bank).
- The **TEMPLATE** lint strips the quoted choice text, tokenizes each distractor note, and flags any word 6-gram that appears in distractor notes for at least 4 different questions within the same category. Allowed repeated technical phrases, if any, must be documented with reasons in [`../../packages/content-tools/explanation-template-allowlist.json`](../../packages/content-tools/explanation-template-allowlist.json).

## Lesson originality check

`check:lesson-originality` is a heuristic guard for keeping original lessons separate from official ISED question text.

- Numeric reuse is checked per heading block: the text under one `#`, `##`, or `###` heading up to the next `#`/`##`/`###` heading. Paragraphs, bullets, numbered items, and table rows in that block are checked together so worked examples cannot hide a copied question across separate list items.
- Numeric matching is scoped by the lesson's `categoryIds`, not just the narrower `covers` list. Number words from one through twenty, plus `twice`, `double`, `half`, `hundred`, and `thousand`, are normalized on both the lesson and question sides. Numbers with attached unit suffixes such as `12V`, `500Ω`, and `1.5kHz` are treated as the numbers `12`, `500`, and `1.5`.
- Near-verbatim wording is checked against the whole official bank. A heading block is flagged if it shares at least 5 word 5-grams with a question plus correct answer, shares at least 40% of that source record's 5-grams, or has a shared run of 8 or more consecutive words.
- Reviewed principle blocks that intentionally use standard definitions or tables are listed in [`originality-allowlist.json`](originality-allowlist.json). Each entry names the lesson id, the exact heading block, and the review reason. The allow-list is for narrow owner-approved principles, not for copied worked examples.
