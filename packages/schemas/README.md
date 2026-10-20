# packages/schemas

JSON Schemas for Canadian Ham content, engine fixtures, and progress interchange contracts.

All schema files use JSON Schema draft 2020-12 and are intentionally data-only: they add no runtime dependencies. CI runs the schemas in `.github/workflows/ci.yml`, job `ci` (`Node and content checks`), step `Schema checks`, via `pnpm check:schemas` whenever full checks run.

## Schema inventory

| Schema | Validates |
| --- | --- |
| `generated-bank-manifest.schema.json` | `content/generated/basic-2025-07-15/manifest.json` |
| `generated-bank-categories.schema.json` | `content/generated/basic-2025-07-15/categories.json` |
| `generated-bank-questions.schema.json` | `content/generated/basic-2025-07-15/questions.json` |
| `generated-bank-subsections.schema.json` | `content/generated/basic-2025-07-15/subsections.json` |
| `subsection-titles.schema.json` | `content/subsection-titles.json` |
| `lesson-module-front-matter.schema.json` | `type: module` front matter in `content/lessons/**/*.md` |
| `lesson-front-matter.schema.json` | `type: lesson` front matter in `content/lessons/**/*.md` |
| `explanation.schema.json` | `content/explanations/**/*.json` |
| `progress-export-v1.schema.json` | Progress export/import JSON shared by the web `ProgressStore` and Apple `ProgressStoreService` |
| `engine-fixture.schema.json` | `fixtures/engine/*.json` language-neutral engine fixtures |
| `common.schema.json` | Shared `$defs` for IDs, localized strings, timestamps, progress records, exam attempts, and fixture records |

The progress schema describes version `1` of `canadian-ham.progress-export`. It keeps `lessonProgress`, `lessonQuizAttempts`, and `preferences.theme` optional because both current importers accept older compatible files without those keys, while current web and Apple exports include them. Exam timer durations allow non-negative numbers (not just integers) to match the web importer and Apple's fractional-value rounding import path.

Lesson quiz attempts optionally store `answeredWithHelpIds`: sorted unique official-question IDs, each in that attempt's `officialQuestionIds`. Missing means no helped answers. Correctness/quiz scores are unchanged; help qualifies only after a hint has been visible for 0.5 s before choice scoring. Import and sync validation enforce the same contract. Shared compatibility cases are in `fixtures/lesson-quiz-help.json`; Apple persistence adopts this field in TASK-50.14.2; until then, Apple builds accept the field on import and sync but drop it when they save or export an attempt (scores are unaffected).

## Validation

Run the zero-dependency validator from the repository root through the same script used by CI:

```sh
pnpm check:schemas
```

For direct debugging, the validator entry point is `node packages/schemas/validate.mjs`.

The script validates the real generated bank JSON, subsection titles, lesson front matter, explanation JSON, engine fixtures, and two progress-export samples that cover the current full export shape and the optional-field import compatibility accepted by both platforms, including non-negative fractional exam timer values. Lesson front matter is parsed through the canonical `packages/content-tools` parser before schema validation.

Expected success output:

```text
Schema validation passed: 1042 validation target(s).
Validated generated bank JSON, subsection titles, lesson front matter, explanations, engine fixtures, and progress export samples.
```

## Validator keyword subset

`validate.mjs` is deliberately small so this package stays dependency-free. The schemas therefore use only these supported keywords:

- `$schema`
- `$id`
- `title`
- `$defs`
- `$ref` for local and sibling schema-file references
- `type` including union arrays and `integer`
- `const`
- `enum`
- `oneOf`
- `allOf`
- `properties`
- `required`
- `additionalProperties`
- `items`
- `prefixItems`
- `minItems`
- `maxItems`
- `uniqueItems`
- `minimum`
- `maximum`
- `minLength`
- `maxLength`
- `pattern`
- `sortedSubset: { "childArray": "parentArray" }`, a project-specific object assertion requiring each present child ID array to be strictly sorted, unique and contained in the parent ID array
- `canonicalUtcTimestamp: true`, a project-specific assertion that the existing canonical timestamp pattern also round-trips through the calendar/time parser used by the engine/import contracts

Schema metadata such as `$schema`, `$id`, `title`, and `$defs` is supported as data needed for resolution or ignored when it does not affect validation. Schemas fail during loading if they use any keyword outside this list or place sibling keywords next to `$ref`, because this validator forbids rather than silently ignoring unsupported constraints.

## Scope notes

- The generated bank schemas target the active ISED Basic 2025-07-15 bank (`basic-2025-07-15`).
- Lesson and module status values use the same `outline`, `draft`, `review`, and `published` lifecycle accepted by `check-lesson-coverage.ts`; explanation status is any non-empty string because `check-explanations.ts` only enforces presence/non-emptiness today.
- Lesson schemas validate the front matter contract only; Markdown body content is checked by existing content tools.
- The schemas do not enforce cross-file referential integrity such as “this question ID exists in `questions.json`.” Existing content checks and app import validation cover those semantic relationships; these schemas cover JSON shape, scalar domains, and ID/timestamp formats.
