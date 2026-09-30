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
  questions/
    amat_basic_quest_delim.txt
    readme_basic.txt
    lisezmoi_base.txt
  pdf/
    <official-question-bank-pdf>.pdf
  reference/
    <official-reference-material-files-if-in-scope>
```

Rules:

- Commit official ISED files verbatim.
- Preserve TXT encoding and line endings exactly as supplied.
- Keep official source artifacts separate from original lessons and explanations.
- Keep reference PDFs as source artifacts only; current app bundles do not ship them.
- Preserve official EN/FR question and answer text exactly. Do not fix typos, normalize spacing, or translate missing French text.

## 4. Run and update the importer

The current importer is pinned to the active `basic-2025-07-15` bank. A future update should migrate the importer intentionally rather than changing generated files by hand.

Expected migration work:

1. Update the importer constants and expected bank counts for the new `<bank-id>`.
2. Keep strict parsing rules unless ISED has changed the source format and the format change is reviewed:
   - UTF-8 without BOM;
   - CRLF line endings;
   - semicolon delimiter;
   - 11 fields;
   - header names trimmed only;
   - field values preserved verbatim;
   - no embedded newlines;
   - no CSV quote wrappers or doubled-quote escapes.
3. Run the importer and review the generated output:

```sh
pnpm --filter @canadian-ham/content-tools import:basic
pnpm --filter @canadian-ham/content-tools import:basic:check
```

The importer writes deterministic JSON under `content/generated/<bank-id>/`. Do not edit generated JSON by hand.

## 5. Run validation checks

After importing the new bank, run the content-tool checks before touching app bundles:

```sh
pnpm --filter @canadian-ham/content-tools test
pnpm typecheck
pnpm test
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
pnpm diff:banks -- content/generated/basic-2025-07-15 content/generated/<bank-id> > /tmp/basic-bank-diff.md
pnpm diff:banks -- --json content/generated/basic-2025-07-15 content/generated/<bank-id> > /tmp/basic-bank-diff.json
```

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

### Explanations

Command:

```sh
pnpm --filter @canadian-ham/content-tools check:explanations
```

Likely failures and fixes:

- Unknown question ID: remove, replace, or rewrite the explanation for the new official ID.
- Changed official question or answer text: review whether the explanation still answers the new wording. Update only original explanation prose; never edit official generated text.
- Removed ID: retire the explanation or map the concept to a new official question after review.
- Added ID: author a new original explanation if release coverage requires it.

### Lesson quizzes

Command:

```sh
pnpm --filter @canadian-ham/content-tools check:quizzes
```

Likely failures and fixes:

- Quiz references an unknown official question ID: replace it with a current-bank ID or convert the item to an original concept-check question.
- Quoted official answer text no longer matches: update the quiz reference or original surrounding prose after reviewing the new generated data.
- Quiz subsection target changed: move the quiz item to the correct lesson or adjust lesson front matter if the official subsection changed.

### Lesson coverage

Command:

```sh
pnpm --filter @canadian-ham/content-tools check:coverage
```

Likely failures and fixes:

- Missing subsection: add or update lesson front matter so every generated subsection is covered.
- Unknown subsection: remove or replace lesson front matter that points at a subsection removed from the bank.
- Duplicate coverage: decide which lesson owns the subsection and keep the mapping unambiguous unless the checker explicitly allows shared coverage in a future task.

When the bank changes counts or IDs, update lesson prose only as original project content. Keep official text in `content/generated/<bank-id>/` and source artifacts in `content/sources/ised/<bank-id>/`.

## 8. Check progress-data compatibility

Progress stores can contain records for question IDs from an older bank. Import and migration paths must handle unknown IDs safely.

Required behaviour for web and Apple progress import:

- Do not crash when imported progress references an unknown question ID.
- Preserve or report unknown IDs as legacy data; do not treat them as current-bank due items.
- Exclude unknown IDs from current practice, readiness, weak-area, and mock-exam calculations.
- Show a user-facing import summary if records were skipped or retained as legacy unknown IDs.
- Keep export data explicit about the bank ID that produced each question-progress record when the platform supports it.

When testing a future bank migration, create a small progress export containing:

- a known current-bank question ID;
- a removed old-bank question ID;
- an added current-bank question ID with no prior progress.

Verify import, export, readiness, due-review counts, weak-area filtering, and reset behaviour on both web and Apple.

## 9. Update web and Apple bundles

After source, generated data, explanations, quizzes, and coverage are valid, update app bundle references from the old bank ID to the new bank ID.

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
