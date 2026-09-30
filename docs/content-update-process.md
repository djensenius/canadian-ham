# Content update process

This process is for a future ISED Basic question-bank update. It keeps the active bank versioned, preserves official English and French text verbatim, and verifies source content by SHA-256 and validation checks rather than ZIP or file modification dates.

Related project rules:

- [AGENTS project instructions](../AGENTS.md)
- [exam facts](exam-facts.md)
- [content licensing](content-licensing.md)
- [architecture](architecture.md)
- [privacy](privacy.md)

Do not replace the active `content/generated/basic-2025-07-15/` bank in place. Create a new bank ID, source directory, generated directory, and reviewed migration branch for the new ISED release.

## Preconditions

1. Confirm the repository is still allowed to vendor the new official artifacts under [content licensing](content-licensing.md). If T-007 permission scope does not cover the future bank, treat the update as blocked until the owner records the needed permission or approves a private-development-only handling decision.
2. Create a dedicated worker branch for the bank update.
3. Read the current task row in `tasks/PLAN.md`, but do not edit `tasks/PLAN.md` from a worker branch; the coordinator owns plan status.
4. Choose a bank ID from the effective date or other official version marker, for example `basic-2026-01-01`. Use one spelling everywhere.

## 1. Obtain the official ZIP and source PDFs

1. Start from the official ISED downloads page recorded in [exam facts](exam-facts.md#official-and-reference-sources).
2. Download the Basic question-bank ZIP from ISED and record:
   - source URL;
   - download date;
   - ZIP member names;
   - SHA-256 for each vendored file after extraction.
3. Download any updated Basic question-bank PDF or reference materials that are in scope for private development or written permission.
4. Do not use file modification dates, ZIP timestamps, or webpage display dates as verification evidence. ISED may regenerate ZIPs with changed dates; content identity is based on SHA-256 plus importer validation.

## 2. Verify SHA-256 before committing

Use local checksum commands before adding files to Git:

```sh
shasum -a 256 path/to/amat_basic_quest_delim.txt
shasum -a 256 path/to/updated-question-bank.pdf
```

Record checksums in the new source manifest under `content/sources/ised/<bank-id>/manifest.json` and in `SHA256SUMS`. The importer must fail if the committed delimited TXT differs from the manifest or `SHA256SUMS` entry.

## 3. Vendor the new source under `content/sources/ised/<bank-id>/`

Create a new versioned directory. Do not overwrite the active source directory.

Recommended layout:

```text
content/sources/ised/<bank-id>/
  manifest.json
  SHA256SUMS
  <official-question-bank-pdf>.pdf
  questions/
    amat_basic_quest_delim.txt
    readme_basic.txt
    lisezmoi_base.txt
  reference/
    <official-reference-material-files-if-in-scope>
```

The active bank keeps its PDF at the source-directory root. Keep that layout for future official question-bank PDFs unless a migration task deliberately changes it. The importer only reads the delimited TXT plus `manifest.json` and `SHA256SUMS`; checksum files must record the exact committed relative path for PDFs and reference files.

Rules:

- Commit official ISED files verbatim.
- Preserve TXT encoding and line endings exactly as supplied.
- Keep official source artifacts separate from original lessons and explanations.
- Keep reference PDFs as source artifacts only; current app bundles do not ship them.
- Preserve official EN/FR question and answer text exactly. Do not fix typos, normalize spacing, or translate missing French text.

## 4. Run and update the importer

The current importer is pinned to the active `basic-2025-07-15` bank. A future update should migrate the importer intentionally rather than changing generated files by hand.

Expected migration work:

1. Update `packages/content-tools/src/active-bank.ts` for the new `<bank-id>`. This shared module defines the active bank ID, source directory, and generated directory used by `basic-importer.ts`, `check-explanations.ts`, `check-quizzes.ts`, `check-lesson-coverage.ts`, and `check-lesson-originality.ts`; do not add separate hard-coded active-bank paths in those tools.
2. Update importer expected dates, counts, source assumptions, and tests for the new bank.
3. Keep strict parsing rules unless ISED has changed the source format and the format change is reviewed:
   - UTF-8 without BOM;
   - CRLF line endings;
   - semicolon delimiter;
   - 11 fields;
   - header names trimmed only;
   - field values preserved verbatim;
   - no embedded newlines;
   - no CSV quote wrappers or doubled-quote escapes.
4. Run the importer and review the generated output:

```sh
pnpm --filter @canadian-ham/content-tools import:basic
pnpm --filter @canadian-ham/content-tools import:basic:check
```

The importer writes deterministic JSON under `content/generated/<bank-id>/`. Do not edit generated JSON by hand.

Concrete files to touch or review during the importer/content migration:

- `packages/content-tools/src/active-bank.ts` for the single active bank ID/source/generated directory switch.
- `packages/content-tools/src/basic-importer.ts` for effective date, expected counts, privilege assertions, source-format assumptions, and any path rules not derived from `active-bank.ts`.
- `content/explanations/**/*.json` `bankId` fields and explanation records for removed, added, or changed official question IDs.
- `packages/content-tools/test/**/*.ts` fixtures that assert the active bank ID, generated directory, or importer output.

## 5. Run validation checks

After importing the new bank, run the content-tool checks before touching app bundles:

```sh
pnpm --filter @canadian-ham/content-tools test
pnpm --filter @canadian-ham/content-tools check:explanations
pnpm --filter @canadian-ham/content-tools check:quizzes
pnpm --filter @canadian-ham/content-tools check:coverage
pnpm --filter @canadian-ham/content-tools check:lesson-originality:all
pnpm typecheck
pnpm test
pnpm import:check
pnpm check:links
```

Expected validation review:

- total question count;
- first and last question IDs;
- duplicate ID count;
- missing French question or answer text;
- category and subsection counts;
- answer-position lint;
- generated manifest path, source URL, checksum, encoding, and line-ending metadata;
- privilege question citations in [exam facts](exam-facts.md#privileges-for-learning-content), if those IDs or correct answers changed.

If the source format changed, stop and review the importer contract before accepting the bank. Do not silently relax parsing rules.

## 6. Generate a bank diff report

Use the zero-dependency diff script to compare the active generated bank with the candidate generated bank:

```sh
pnpm --silent diff:banks -- content/generated/basic-2025-07-15 content/generated/<bank-id> > /tmp/basic-bank-diff.md
pnpm --silent diff:banks -- --json content/generated/basic-2025-07-15 content/generated/<bank-id> > /tmp/basic-bank-diff.json
node -e 'JSON.parse(require("node:fs").readFileSync("/tmp/basic-bank-diff.json", "utf8"))'
```

Use `pnpm --silent` when redirecting so pnpm banner lines do not corrupt the saved Markdown or JSON. The direct equivalent is:

```sh
node packages/content-tools/src/diff-banks.ts --json content/generated/basic-2025-07-15 content/generated/<bank-id> > /tmp/basic-bank-diff.json
```

Relative bank paths resolve against `INIT_CWD` when that environment variable is set by pnpm, otherwise against the current working directory. Run the parse check after saving JSON; do not attach or archive a redirected JSON report until it parses.

The report lists:

- question IDs added;
- question IDs removed;
- EN/FR question text changes;
- answer text or correctness changes by `sourceIndex`;
- subsections added or removed;
- subsection question-count changes with old and new question ID lists.

Review the Markdown report for human sign-off. Keep the JSON report if another script needs stable machine-readable evidence.

## 7. Assess explanations, lesson quizzes, and lesson coverage

A bank update can invalidate original content that cites official IDs. Run these checks and fix failures in the same migration branch or in clearly sequenced follow-up branches.

The four content checkers use `packages/content-tools/src/active-bank.ts` for their default generated-bank paths. To switch them to a candidate bank, update that shared module before running the checks. Do not leave a checker pointed at `content/generated/basic-2025-07-15/` while reviewing a future bank.

### Explanations

Command:

```sh
pnpm --filter @canadian-ham/content-tools check:explanations
```

Likely failures and fixes:

- Unknown question ID: remove, replace, or rewrite the explanation for the new official ID.
- `bankId` mismatch in `content/explanations/**/*.json`: update records after the active bank switch and review the related question IDs at the same time.
- Changed official question or answer text, including quoted per-choice distractor notes: review whether the explanation still answers the new wording. Update only original explanation prose; never edit official generated text.
- Removed ID: retire the explanation or map the concept to a new official question after review.
- Added ID: author a new original explanation if release coverage requires it.

### Lesson quizzes

Command:

```sh
pnpm --filter @canadian-ham/content-tools check:quizzes
```

Likely failures and fixes:

- Quiz references an unknown official question ID: replace it with a current-bank ID or convert the item to an original concept-check question.
- Official question IDs are no longer covered by the lesson's subsection list: move the quiz item to the correct lesson or adjust lesson front matter after reviewing the new generated data.
- Concept-check prompt, choice, or explanation prose overlaps too closely with official question or answer text: rewrite the original quiz prose so it teaches the concept without copying official wording.

### Lesson coverage

Command:

```sh
pnpm --filter @canadian-ham/content-tools check:coverage
```

Likely failures and fixes:

- Missing subsection: add or update lesson front matter so every generated subsection is covered.
- Unknown subsection: remove or replace lesson front matter that points at a subsection removed from the bank.
- Duplicate coverage: decide which lesson owns the subsection and keep the mapping unambiguous unless the checker explicitly allows shared coverage in a future task.

### Lesson originality

Command:

```sh
pnpm --filter @canadian-ham/content-tools check:lesson-originality:all
```

Likely failures and fixes:

- Lesson prose now shares long word runs or too many five-grams with changed official question or answer text: rewrite the lesson example or explanation in original wording.
- Numeric examples now duplicate official question-and-answer values in one block: change the original example values while preserving the teaching point.
- Existing allowlist entries no longer apply cleanly to the new official text: review, remove, or update them rather than broadening allowlists silently.

When the bank changes counts or IDs, update lesson prose only as original project content. Keep official text in `content/generated/<bank-id>/` and source artifacts in `content/sources/ised/<bank-id>/`.

## 8. Check progress-data compatibility

Progress stores can contain records for question IDs from an older bank. Today's code does not yet have a compatibility migration for a new bank and must be treated as strict-reject behavior:

- Web `apps/web/src/lib/progressStore.ts` rejects imports when the top-level `bankId` differs from the active bank, when `questionProgress[].bankId` differs, or when a question ID is not in the active generated bank. Exam attempts and lesson-quiz attempts also validate against known current-bank question, category, subsection, lesson, and quiz IDs.
- Apple `apps/apple/CanadianHam/Services/ProgressStore.swift` does the same validation against `QuestionBank`: mismatched `bankId` values and unknown question IDs, exam-attempt item IDs, weak subsection IDs, and lesson-quiz official question IDs fail the import before any data is written.

Before shipping a new bank, the owner must choose and approve a progress-compatibility policy and the apps need a code change. Do not implement that policy as part of the bank-import documentation task. The policy options include:

- map old IDs to reviewed replacement IDs when ISED changed identifiers but the learning concept is equivalent;
- drop unknown or removed IDs with an explicit import/migration summary;
- keep legacy data isolated from the current bank so it can be exported or viewed historically without affecting current practice.

The decision must cover both imported export files and records already stored on devices: web IndexedDB records and Apple SwiftData entities with old `bankId` values, plus exam attempts and lesson-quiz attempts that reference removed question IDs, subsection IDs, category IDs, lesson IDs, or quiz IDs. Until that owner decision and code change exist, shipping a new bank would make older exports and some on-device history fail current import/validation paths.

When testing a future bank migration after the owner decision is implemented, create a small progress export containing:

- a known current-bank question ID;
- a removed old-bank question ID;
- an added current-bank question ID with no prior progress.

Verify import, export, readiness, due-review counts, weak-area filtering, and reset behaviour on both web and Apple.

## 9. Update web and Apple bundles

After source, generated data, explanations, quizzes, and coverage are valid, update app bundle references from the old bank ID to the new bank ID.

Concrete files to touch or review:

- `apps/web/src/data/bank.ts` and `apps/web/README.md`.
- `apps/apple/project.yml` for all four Apple targets, then run XcodeGen and commit the regenerated `apps/apple/CanadianHam.xcodeproj/project.pbxproj`.
- `apps/apple/CanadianHam/Services/QuestionBankStore.swift`.
- Hard-coded bank ID assertions in `apps/apple/CanadianHamTVTests/CanadianHamTVTests.swift` and `apps/apple/CanadianHamVisionTests/CanadianHamVisionTests.swift`.
- `packages/engine-ts/src/generate-fixtures.ts`, the full-bank engine fixture, and Swift engine parity fixtures/tests.
- `AGENTS.md` active question-bank SHA note.

Web checks:

1. Confirm the web content loader points at `content/generated/<bank-id>/` or the derived bundled location.
2. Rebuild the static bundle and inspect that it includes the new generated JSON and source manifest metadata.
3. Verify the service worker/offline cache includes the new bank files and no stale active-bank paths.
4. Run web tests through the root commands:

```sh
pnpm typecheck
pnpm test
pnpm build:web
```

Apple checks:

1. Update the Apple content bundle resource references for the new generated bank.
2. Confirm the app-visible bank version and source manifest metadata use the new bank ID.
3. Confirm no reference PDFs are added to app resources unless a future approved task changes the current policy.
4. Run Apple builds/tests through `xbuild` only, following [AGENTS.md](../AGENTS.md). Do not call `xcodebuild` directly.

## 10. Review and commit sequence

Use logical commits so reviewers can isolate source, generated data, validation fixes, and bundle changes. A typical sequence is:

1. Vendor new source files and checksum manifests.
2. Update importer constants/tests and generated JSON.
3. Add the bank diff report artifact if the coordinator asks for it, or record its path/output in the review notes.
4. Fix explanations, lesson quizzes, lesson coverage, and progress compatibility checks.
5. Update web and Apple bundle references.
6. Update docs that cite the active bank version, source URLs, checksums, or exam facts.

Before handing off for review, report:

- branch name;
- full 40-character HEAD SHA;
- changed files;
- commands run and results;
- residual risks, including any changed official facts or unresolved licensing questions.
