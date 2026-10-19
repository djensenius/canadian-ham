---
id: TASK-47
title: >-
  Originality checker: flag real question-answer number pairs, not common
  numbers
status: Done
assignee:
  - '@worker'
created_date: '2026-10-12 15:48'
updated_date: '2026-10-19 13:19'
labels:
  - content
dependencies: []
priority: medium
ordinal: 110000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
check-lesson-originality rejects any worked-example block whose only numeric tokens are common values (2, 3, 10, 0.5) because some bank answer contains them. This pushed workers to delete dB working (task-46.1) instead of teaching it. Refine the rule so it flags reuse of a bank question's distinctive number set together with its keyed answer, while allowing ubiquitous values and standard step values (3 dB, 10 dB, x 2, x 10) in worked examples.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A worked example using 10 dB + 3 dB steps passes; copying a bank question's numbers with its keyed answer still fails (self-test cases)
- [x] #2 All lessons on main still pass; any newly allowed lines are reviewed
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect the existing lesson-originality numeric heuristic and tests, then capture the current all-lessons checker output for before/after comparison.
2. Refine numeric-overlap so a keyed numeric answer only fails when the block also carries a distinctive question number set or distinctive question context, while preserving near-verbatim word-overlap checks.
3. Add fixture tests for allowed common dB/ratio step values and rejected real leaks, including multi-number and unit scenarios.
4. Run targeted content-tools tests plus the required repository checks, compare all-lesson results before/after, record reviewed disappearing findings in task notes, then finalize the Backlog task and PR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented numeric-overlap refinement in `packages/content-tools/src/check-lesson-originality.ts`: a block must still contain all numeric tokens from the question and keyed answer, but now the question side must contribute either at least one non-common/distinctive numeric token or at least two distinctive context words from the question. Near-verbatim 5-gram/longest-run checks are unchanged, so copied question wording still fails independently.

Added tests in `packages/content-tools/test/check-lesson-originality.test.ts` for:
- allowed common dB/ratio examples using +10 dB and -3 dB steps plus repeated +3 dB steps;
- allowed standalone common numbers (`5`/`10`) without question context;
- rejected real numeric leaks with distinctive numbers, units, multi-number scenarios, and common numeric values when capacitor/series context is also present.

Before/after all-lessons comparison:
- Normal checker with committed allowlist: before `pnpm --dir packages/content-tools check:lesson-originality:all` passed with 36 lesson files, 984 questions, 39 allowlisted blocks, 0 issues; after it also passed with 36 lesson files, 984 questions, 39 allowlisted blocks, 0 issues.
- Empty-allowlist audit for review: current checker output dropped from 83 total findings / 46 numeric findings to 61 total findings / 24 numeric findings; no new findings appeared. The 22 disappearing numeric findings were reviewed as false positives because they are common/standalone numeric facts without the specific question context:
  - `L-001-04` Bandwidth and mode-fit cues vs `B-001-024-010` (`6`/`6`): unrelated Safety Code 6 number appearing in a bandwidth/mode reference block.
  - `L-002-04` grid locator code length vs `B-002-006-008` (`6`/`4`): standalone Maidenhead locator lengths, not copied question context.
  - `L-005-04` Decibels as power ratios vs `B-005-001-003`, `B-005-004-001`, `B-005-005-008`, `B-005-005-010`, `B-005-006-006`, `B-005-006-009`, `B-005-008-001`, `B-005-008-002`, `B-005-008-003`, `B-005-008-007`, `B-005-009-001`, `B-005-009-002`, `B-005-009-003`, `B-005-009-004`, `B-005-009-009`, `B-005-009-010`, and `B-005-011-007`: standard dB/power-ratio step values (`0.5`, `1`, `2`, `3`, `4`, `5`, `10`, `20`, `100`, `1000`) taught as estimating shortcuts rather than any one question scenario.
  - `L-006-02` reflected-power estimates vs `B-006-009-002`, `B-006-011-010`, and `B-006-013-010`: common ratio/SWR/Yagi-spacing numbers overlap the reflected-power table, but the lesson block lacks the source questions' matching contexts.

Review fix: added number+unit context evidence for common-number leaks, including µF/uF, mH, ohm/Ω, V and W examples from review, plus regression fixtures for one-context vs two-context boundary, low-context unit copies, French decimal commas, and k/Hz scaling. Normal all-lessons checker before this fix passed with 36 lesson files, 984 questions, 39 allowlisted blocks, 0 issues; after this fix it still passes with the same counts and 0 issues. Empty-allowlist audit before and after remained 61 total findings / 24 numeric / 37 five-gram, so no current lesson findings were newly added or removed by this review fix. The retained suppressed dB/ratio findings remain justified because dB unit matches are not context evidence by themselves; current metric conversion teaching is also not treated as a leak without additional question context. Created follow-up TASK-62 for stale allowlist auditing/reporting recommended by review.

Copilot follow-up: normalized -ces/-ges plurals such as voltages and resistances by removing only the plural s, and added regression fixtures for the Copilot examples plus a context-only plural boundary. Re-ran ✔ Advanced parser explicitly detects Windows-1252 legacy input when UTF-8 decoding fails (1.043958ms)
✔ Advanced SHA256SUMS rejects a malformed checksum line (107.432334ms)
✔ Advanced SHA256SUMS rejects duplicate paths (59.876ms)
✔ Advanced SHA256SUMS rejects paths not listed in the source manifest (19.536209ms)
✔ Advanced SHA256SUMS rejects checksum drift against the source manifest (12.34ms)
✔ Advanced SHA256SUMS rejects a missing line for a manifest-listed file (13.635083ms)
✔ Advanced SHA256SUMS rejects a changed source file whose metadata is unchanged (23.926167ms)
✔ imports and validates the committed Advanced 2025-02-04 source bank (8.07425ms)
✔ shared bank-rule fixture agrees with content-tools and engine-ts (6.731834ms)
✔ content-tools bank rules accept future schema-valid Basic ids (0.139291ms)
✔ content-tools bank rules accept only schema-valid Basic and Advanced ids (0.257583ms)
✔ content bank rules expose Basic and Advanced exam shapes (12.425125ms)
✔ strict parser accepts UTF-8 CRLF semicolon rows and trims header names only (0.342042ms)
✔ strict parser rejects BOMs, invalid UTF-8, bare newlines, bare CRs, wrong field counts, and CSV quotes (0.519792ms)
✔ parser preserves literal quote characters that are part of source wording (0.12175ms)
✔ checksum mismatch against source manifest fails before parsing (61.834916ms)
✔ checksum mismatch against SHA256SUMS fails before parsing (25.948292ms)
✔ imports and validates the committed Basic 2025 source bank (36.128334ms)
✔ privilege citations in docs/exam-facts.md match imported correct answers (40.327542ms)
✔ position-dependent answer lint flags fixed-choice wording and avoids known false positives (0.371334ms)
✔ import fails on duplicate IDs, empty French fields, and position-dependent lint (135.814667ms)
✔ import fails with clear errors for invalid category French-name status combinations (197.434708ms)
✔ check mode detects drift in generated output without touching committed generated files (53.546542ms)
✔ explanation check accepts valid schema, exact choice quotes, short prefixes, and lesson coverage (32.597042ms)
✔ explanation check accepts https citation urls on allowed ISED hosts (20.6455ms)
✔ explanation check rejects citation urls that are not https urls on allowed ISED hosts (136.400792ms)
✔ explanation check rejects empty citation url strings when present (35.300833ms)
✔ explanation check rejects schema failures (8.880625ms)
✔ explanation check rejects a bank record whose correct sourceIndex is not zero (12.159833ms)
✔ explanation check rejects per-choice notes that do not start with the quoted official choice text (5.862833ms)
✔ explanation check rejects empty per-choice note bodies (28.847875ms)
✔ explanation check rejects generic filler phrases in per-choice notes (27.566417ms)
✔ explanation check rejects missing distractor-note header (13.123208ms)
✔ explanation check rejects sourceIndex 0 in the distractor-note list (16.209ms)
✔ explanation check requires a note for every distractor (11.15375ms)
✔ explanation check rejects rotating-opener TEMPLATE word 6-grams in one category (23.089208ms)
✔ explanation check rejects duplicate normalized note bodies in three or more files (30.002875ms)
✔ explanation check rejects missing or non-covering lesson citations (40.472708ms)
✔ explanation check supports category and module filters while full runs stay strict (31.411791ms)
✔ hint loader sorts records and exposes question lookup helpers (98.774792ms)
✔ hint loader reports parse errors with the file path and tolerates missing sort keys (19.95725ms)
✔ reference-sheet section keys stay aligned between schema, labels, and sheet headings (0.656667ms)
✔ lesson heading slugs match the shared lesson-heading fixture (2.055583ms)
✔ hint lesson-link anchors match headings rendered by lesson readers (0.785ms)
✔ hint check accepts valid EN/FR two-step hints (21.916458ms)
✔ hint check accepts one-level hints only with a reason and validates lesson links (52.616125ms)
✔ hint check rejects answer and question wording leakage (9.423708ms)
✔ hint checker self-test covers checker contract (1071.217125ms)
✔ coverage passes and reports duplicate subsection coverage (60.181542ms)
✔ coverage accepts a valid cross-module prerequisite that comes earlier in study order (21.513375ms)
✔ coverage accepts draft, review, and published status values (30.413834ms)
✔ coverage fails when an expected subsection is missing (53.989541ms)
✔ coverage fails when a lesson references an unknown subsection (20.519083ms)
✔ coverage fails on malformed lesson front matter (16.645625ms)
✔ coverage fails on malformed module front matter (147.118333ms)
✔ coverage fails on unquoted scalar values containing spaces (20.032208ms)
✔ coverage fails when a module lessonIds entry does not exist (26.603791ms)
✔ coverage fails when a module lessonIds entry belongs to another module (37.489583ms)
✔ coverage reports one malformed-file error for a duplicate module lessonIds entry (35.42925ms)
✔ coverage fails when a lesson is not listed in its module lessonIds (30.557584ms)
✔ coverage fails when a lesson moduleId does not match its ID prefix (20.006875ms)
✔ coverage fails when a module categoryId does not match its ID (20.326125ms)
✔ coverage fails when a lesson moduleId does not refer to an existing module (14.62125ms)
✔ coverage fails when a lesson prerequisite does not exist (17.749375ms)
✔ coverage fails when a lesson repeats a prerequisite ID (20.531458ms)
✔ coverage fails when a lesson prerequisite is not earlier in recommended order (23.551709ms)
✔ coverage fails when a cross-module prerequisite is not earlier in recommended order (24.833458ms)
✔ coverage fails when lesson prerequisites form a cycle (34.8785ms)
✔ coverage fails when a lesson covers entry does not match its categoryIds prefix (23.672459ms)
✔ coverage fails when module order values do not cover 1 through 8 (30.226833ms)
✔ CLI runs and exits non-zero on bad content (104.030458ms)
✔ real lesson content covers the generated Basic subsections (16.836375ms)
✔ originality check runs when invoked through a symlink (339.134125ms)
✔ originality check --all fails when no lesson files are checked (214.994292ms)
✔ originality check passes original numeric examples (6.918084ms)
✔ numeric originality allows common dB and ratio shortcut numbers without question context (3.746375ms)
✔ numeric originality allows standalone common numbers without distinctive context (4.640083ms)
✔ originality check rejects integer-only question and answer numbers in one heading block (4.489208ms)
✔ originality check rejects unit-word bank scenarios such as two 500 ohm 1 W resistors yielding 2 W (6.518584ms)
✔ numeric originality rejects common numbers when paired with distinctive question context (4.720208ms)
✔ numeric originality rejects common-number leaks when matching units replace missing nouns (17.17475ms)
✔ numeric originality normalizes voltage and resistance plurals for context (4.16575ms)
✔ numeric originality keeps the common-number context threshold boundary (6.277208ms)
✔ numeric originality flags low-context unit and scaled-prefix copies (14.786333ms)
✔ numeric originality parses French decimal commas with units (6.681708ms)
✔ originality check normalizes trailing zeros before comparing numeric values (8.592708ms)
✔ originality check normalizes number words and unit suffixes attached to numbers (11.527417ms)
✔ originality check rejects round-1 worked examples split across paragraph and bullets in one heading block (5.426167ms)
✔ originality check does not join numeric examples across different headings (9.5715ms)
✔ numeric originality uses lesson categoryIds rather than only covered subsections (5.869417ms)
✔ numeric originality does not compare against questions outside the lesson categories (5.052167ms)
✔ five-gram originality runs against the whole bank (5.84ms)
✔ five-gram originality rejects an eight-word shared run at the threshold boundary (5.363291ms)
✔ five-gram originality rejects a case at the 40 percent ratio boundary (4.326667ms)
✔ five-gram originality allows a case just below the ratio threshold (5.132416ms)
✔ slugForHeadingText matches the shared lesson-heading fixture (19.243292ms)
✔ checkMarkdownLinks verifies relative Markdown file and anchor targets (42.156667ms)
✔ checkMarkdownLinks reports missing relative Markdown targets (6.690375ms)
✔ checkMarkdownLinks verifies same-file anchors (9.152541ms)
✔ checkMarkdownLinks reports missing same-file anchors (18.659584ms)
✔ checkMarkdownLinks ignores links inside fenced code blocks (2.491417ms)
✔ checkMarkdownLinks only closes fenced code blocks on a bare fence line (10.589166ms)
✔ checkMarkdownLinks does not treat footnote definitions as link definitions (4.2315ms)
✔ checkMarkdownLinks follows GitHub heading slugs by replacing each whitespace character (3.991167ms)
✔ checkMarkdownLinks reports invalid URI encoding as one issue (3.105875ms)
✔ checkMarkdownLinks skips only generated fastlane release output (9.2685ms)
✔ quiz check accepts a valid lesson quiz file (77.037833ms)
✔ quiz check accepts an official-only quiz with an empty conceptChecks array (22.276ms)
✔ quiz check rejects unknown lesson IDs (12.44175ms)
✔ quiz check rejects official questions outside the lesson coverage (20.90975ms)
✔ quiz check rejects concept checks that overlap official questions in the same quiz (20.271333ms)
✔ quiz check rejects concept checks that overlap lesson Try-it lines (8.996166ms)
✔ quiz check rejects concept checks without exactly one correct choice (7.527041ms)
✔ quiz check rejects empty localized text (7.419916ms)
✔ quiz check accepts non-empty French localized text (6.263333ms)
✔ quiz check rejects empty French localized text (5.373708ms)
✔ quiz check rejects missing French localized text (5.547083ms)
✔ quiz check rejects missing quiz files referenced by lesson front matter (13.56175ms)
✔ quiz check rejects duplicate quizIds across lessons (128.849583ms)
✔ quiz check rejects duplicate concept-check IDs (7.651875ms)
✔ quiz check rejects duplicate official question IDs once per quiz (10.70775ms)
✔ quiz check rejects unknown official question IDs (6.226291ms)
✔ quiz check rejects orphan quiz files that no lesson references (5.9405ms)
✔ quiz check does not also report missing quiz file when a referenced quiz has shape failures (12.426167ms)
✔ quiz check validates unknown official IDs even when lessonId is unknown (8.400542ms)
✔ quiz check rejects duplicate lesson IDs (5.47625ms)
✔ quiz check scoped to a module ignores other modules' quiz files but keeps same-prefix orphan checks (39.468834ms)
✔ validateReferenceSheet accepts a valid fixture (75.249416ms)
✔ validateReferenceSheet rejects a missing heading (23.363084ms)
✔ validateReferenceSheet rejects a missing required section (7.373291ms)
✔ validateReferenceSheet rejects a missing required entry (26.431375ms)
✔ validateReferenceSheet rejects lesson drift (6.798875ms)
✔ validateReferenceSheet rejects prohibited official-reference wording (4.903042ms)
✔ diff report lists added, removed, changed text, changed answers, and subsection counts (19.553875ms)
✔ rendered diff report includes reviewable EN/FR and answer details (17.131875ms)
✔ CLI accepts a leading -- and emits parseable JSON (94.408333ms)
✔ CLI accepts --json in any argument position (93.176208ms)
✔ CLI reports usage with a non-zero exit code (77.549125ms)
✔ CLI resolves relative bank paths against INIT_CWD when set (85.737334ms)
ℹ tests 139
ℹ suites 0
ℹ pass 139
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 1502.054625, , and Lesson files checked: 36
Official questions checked: 984
Numeric originality window: one #/##/### heading block, scoped by lesson categoryIds; keyed answers require a distinctive question number, matching number+unit evidence, or 2 distinctive context words
Near-verbatim threshold: 5 shared word 5-grams, 40% of source 5-grams, or 8 shared words in a row, across the whole bank
Allow-listed heading blocks skipped: 39
Originality issues: 0; all passed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Refined the lesson originality numeric-overlap rule so common numeric values do not fail unless they are paired with distinctive question numbers or at least two distinctive question context words; near-verbatim checks remain unchanged. Added self-test fixtures covering allowed 10 dB/3 dB shortcut examples, standalone common numbers, and rejected real leaks with distinctive numbers, units, multi-number sets, and common-number capacitor/series context.

Validation passed: `pnpm --filter @canadian-ham/content-tools test -- check-lesson-originality.test.ts`, `pnpm --filter @canadian-ham/content-tools typecheck`, `pnpm typecheck`, `pnpm test`, `pnpm --dir packages/content-tools check:lesson-originality:all`, `pnpm --dir packages/content-tools check:explanations`, `pnpm check:hints -- --require-complete`, `pnpm check:links`, and `pnpm check:schemas`. Normal all-lessons originality output remained 0 issues before and after. Empty-allowlist comparison found 22 reviewed numeric false positives removed and no new findings.
<!-- SECTION:FINAL_SUMMARY:END -->
