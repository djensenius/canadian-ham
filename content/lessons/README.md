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

## Lesson prerequisites

Lesson front matter uses `prerequisites` for lesson IDs that should be studied before a lesson, including cross-module dependencies. Prerequisites must be real lesson IDs, must not form cycles, and must come earlier in the recommended learning order above (module order first, then each module's `lessonIds` order). Do not point a lesson at later material just because the current draft contains a forward reference; either define the term locally or schedule a content fix.

Use direct prerequisites that explain the dependency a learner needs, not a complete list of every transitive earlier lesson. Examples: M4 lessons may point back to M5 electronics lessons for Ohm's law, AC and dB; M6 lessons may point back to M5 impedance, reactance, resonance and dB; M7 points back to M6 wavelength and band-name context; M8 points back to M3/M4/M5 station, filtering, signal-quality and non-linear-device foundations; M2 and M1 point back to the relevant technical and operating lessons they rely on.

## Coverage check

Run the zero-dependency coverage checker from the repository root:

```sh
node packages/content-tools/src/check-lesson-coverage.ts
```

The checker parses lesson front matter, compares lesson `covers` entries with `content/generated/basic-2025-07-15/subsections.json`, fails on missing or unknown subsection IDs, fails on malformed lesson/module front matter, validates that every prerequisite exists, validates that prerequisites are acyclic and earlier than the dependent lesson in the recommended order, and reports duplicate subsection coverage for review.

## Explanatory lessons

Modules 2 through 8 teach through concept sections, worked examples, Try it, common mistakes, and original concept checks. Module 2 moved to this format under TASK-46.9 (owner approval 2026-10-12). Keep standard procedure facts accurate while explaining their purpose; do not restate bank questions or answers as practice items. Separate Try-it prompts from their feedback, and keep concept checks distinct from both the official bank and the Try-its.

Use the heading structure, plain-language rules, and calculation template in [`../../docs/teaching-guide.md`](../../docs/teaching-guide.md). Keep lesson IDs, coverage, figure directives, and quiz references valid when revising. Module 2 retains its exhaustive official quiz lists alongside its new concept checks.

## Reference-style lessons for rule-based modules

Some modules are primarily made of rule facts already enumerated by the official question bank. For those modules, such as Module 1 regulations, lessons use a reference-style format instead of homemade practice prompts:

- keep single facts in clearly labelled `Reference facts` tables;
- explain relationships in prose under a `How these rules fit together` section;
- do not include Try-its, question-and-answer worked examples, original practice items, or `Common mistakes` sections;
- phrase objectives, tables, and explanations as positive rule statements and avoid restating wrong answer options; and
- use lesson quiz JSON that includes all official question IDs for the covered subsections and `conceptChecks: []`.

The format lets the app teach the official rules without creating near-duplicate concept checks for a rule bank that is already exhaustive.

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

Every authored concept-check choice must carry `feedback: {"en": "...", "fr": null}` (or translated French text). Explain why that choice fits or which misconception it reveals, rather than repeating the generic explanation. The quiz checker requires complete feedback by default, including module-scoped runs with `--lesson-root=<module path>`. The earlier `--require-feedback` flag remains accepted but is no longer needed. The shared schema and readers still accept older content without feedback.

For calculation lessons, follow each worked-example set with `### Faded practice: ...`: supply the givens and formula, leave completion blanks, and offer a sanity-check cue. Put its solution under a separate `### Check your work: ...` heading. Keep the later Try-it prompts unscaffolded, with answers below a separate feedback heading, so practice moves from worked to faded to independent.

Review concept checks by hand against every Try-it and every `officialQuestionIds` entry in the same quiz. Official and concept items are shuffled together, so do not reveal a bank question and its answer through a renamed example. Test a changed condition, a transfer, or a model limit instead. Use plausible same-topic misconceptions for every distractor, positive stems, and exactly one correct answer. The overlap lint below is a narrow backstop, not a substitute for this review.

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

## Lesson figures

Lesson Markdown may reference drawn figures with the `::figure <id>` directive. Figure sources live in `content/figures/`, alt text lives in the directive, and the existing `## Illustration brief` section stays in the lesson source for authors but is not shown to learners. See [`../../docs/figures.md`](../../docs/figures.md) for naming, theming, Apple asset generation, text-equivalent, and check-script requirements.

## Lesson originality check

`check:lesson-originality` is a heuristic guard for keeping original lessons separate from official ISED question text.

- Numeric reuse is checked per heading block: the text under one `#`, `##`, or `###` heading up to the next `#`/`##`/`###` heading. Paragraphs, bullets, numbered items, and table rows in that block are checked together so worked examples cannot hide a copied question across separate list items.
- Numeric matching is scoped by the lesson's `categoryIds`, not just the narrower `covers` list. Number words from one through twenty, plus `twice`, `double`, `half`, `hundred`, and `thousand`, are normalized on both the lesson and question sides. Numbers with attached unit suffixes such as `12V`, `500Ω`, and `1.5kHz` are treated as the numbers `12`, `500`, and `1.5`.
- Near-verbatim wording is checked against the whole official bank. A heading block is flagged if it shares at least 5 word 5-grams with a question plus correct answer, shares at least 40% of that source record's 5-grams, or has a shared run of 8 or more consecutive words.
- Reviewed principle blocks that intentionally use standard definitions or tables are listed in [`originality-allowlist.json`](originality-allowlist.json). Each entry names the lesson id, the exact heading block, and the review reason. The allow-list is for narrow owner-approved principles, not for copied worked examples. Every entry must still hide a current issue: a full `--all` run fails on stale entries (or entries for missing lessons or headings), so remove the entry when a rewrite clears the flag. Partial runs only judge entries for the lessons they check; `--all` with `--lesson-root` set to a subset is a test hook and reports unselected lessons' entries as stale. The "Current checker" detail in each reason records what the entry hid when it was last reviewed (TASK-62); the stale check, not that text, is the guarantee.
- Reference-style rule modules keep single official facts in `Reference fact` Markdown tables; a table is allowlisted only while the checker would otherwise flag it. Their prose and summaries should explain relationships and operating flow, and their lesson bodies should omit `Common mistakes` sections so wrong bank alternatives are discussed only in per-question explanations.
