# Architecture plan

This document describes the planned monorepo, content pipeline, schemas, engines, platform apps, cross-platform fixtures, and CI outline for `canadian-ham`.

It assumes the product requirements in [requirements.md](requirements.md), exam facts in [exam-facts.md](exam-facts.md), privacy rules in [privacy.md](privacy.md), and licensing rules in [content-licensing.md](content-licensing.md).

## Monorepo layout

Decision: keep a single monorepo until real pain appears.

```text
canadian-ham/
  AGENTS.md
  apps/
    web/                    # Static Vite/React/TypeScript app
    apple/                  # SwiftUI multiplatform Xcode project/package for iOS, iPadOS, macOS, visionOS, and tvOS
  content/
    sources/
      ised/
        basic-2025-07-15/   # Vendored official source files plus checksums
    generated/
      basic-2025-07-15/     # Generated normalized JSON committed for app builds
    categories.json         # Hand-maintained category names and expected counts
    lessons/                # Platform-neutral Markdown lessons
    explanations/           # Original explanation records by question ID
    reference/              # Reference metadata/assets allowed by current licensing stage
  fixtures/
    engine/                 # Language-neutral engine fixtures
    importer/               # Importer validation fixtures
  packages/
    content-tools/          # TypeScript importer, validation, coverage, build scripts
    engine-ts/              # Web-side TypeScript engine implementation
    engine-swift/           # SwiftPM engine package, tested through xbuild
    schemas/                # JSON Schema or TypeScript schema definitions
  docs/
    requirements.md
    exam-facts.md
    architecture.md
    privacy.md
    content-licensing.md
  .backlog/
    (Backlog.md tasks, milestones and config; managed only with the backlog CLI)
  tasks/
    PLAN.md  (pointer to .backlog/ and legacy ID map)
```

Notes:

- The layout separates ISED data from original lessons and explanations.
- `content/sources/ised/basic-2025-07-15/` contains the official Basic 2025 TXT, question-bank PDF, English reference PDFs, and checksum files for private development while the repository stays private; the reference PDFs are not shipped in the apps, and public exposure and distribution are gated by the [content licensing public-release gate](content-licensing.md#public-release-gate).
- `content/generated/` contains generated app-ready normalized JSON only after the importer is implemented and reviewed.
- Shared fixtures in `fixtures/` are the contract between TypeScript and Swift engines.

## Content pipeline

Tooling decisions:

- Web/package management uses pnpm.
- Importer and content tooling are TypeScript files run directly by Node using Node's type-stripping support (Node >= 23.6; the development machine has Node 26).
- Importer tests use `node:test`.
- The importer has zero runtime dependencies unless a future task explicitly changes that decision.

### Inputs

- Official delimited TXT described in [exam-facts.md](exam-facts.md).
- Official English PDF question bank for human cross-checks.
- Official English reference material ZIP/PDF files for provenance and lesson context; these PDFs are not shipped in the apps.
- Hand-maintained category metadata.
- Original lesson Markdown.
- Original explanation JSON.

### Pipeline stages

1. Vendor the official Basic 2025 TXT, question-bank PDF, and English reference PDFs under `content/sources/ised/basic-2025-07-15/` for private development under the [interim private-development policy](content-licensing.md#interim-private-development-policy); the reference PDFs remain source artifacts and are not shipped in the apps, and public exposure and distribution remain gated by the [public-release gate](content-licensing.md#public-release-gate).
2. Record SHA-256 checksums in a manifest and fail import on any checksum mismatch.
3. Parse the committed delimited TXT in importer and CI runs with strict format checks: trim header names only, preserve field values exactly, reject wrapper-shaped CSV fields and doubled-quote CSV escapes, reject embedded newlines, and preserve quote characters that are part of official wording.
4. Normalize records into JSON with stable IDs and language-keyed text under `content/generated/basic-2025-07-15/`.
5. Derive categories and subsections from question IDs.
6. Join hand-maintained category metadata.
7. Lint answer text for position-dependent phrases before allowing answer shuffling.
8. Validate counts against [exam-facts.md](exam-facts.md).
9. Validate lesson coverage for all 100 subsections.
10. Validate explanations against known question IDs and licensing rules.
11. Emit committed app-ready generated JSON under `content/generated/basic-2025-07-15/`, then app bundles for web and Apple.
12. Run TypeScript and Swift engines against shared fixtures.

### Generated artifacts

Generated artifacts are committed under `content/generated/basic-2025-07-15/` and should include a source manifest so apps can display or log the active bank version without contacting a server.

Example manifest (deterministic: no generated timestamps):

```json
{
  "bankId": "basic-2025-07-15",
  "certificate": "canadian-amateur-basic",
  "effectiveDate": "2025-07-15",
  "source": {
    "path": "content/sources/ised/basic-2025-07-15/questions/amat_basic_quest_delim.txt",
    "sha256": "34c7cd7967addfde648c566d0ecf25bf3d1e071c603b5101cfecc7bd0cbc284f",
    "url": "https://apc-cap.ic.gc.ca/datafiles/amat_basic_quest.zip#amat_basic_quest_delim.txt",
    "encoding": "UTF-8",
    "lineEndings": "CRLF"
  },
  "importer": {
    "name": "packages/content-tools/src/import-basic.ts",
    "version": "1"
  },
  "counts": {
    "questions": 984,
    "categories": 8,
    "subsections": 100
  }
}
```

## Data schemas

Schema definitions should be versioned. JSON examples below show the intended shape, not final JSON Schema syntax. Additive optional progress-export fields may stay on the current version when older imports and rows load unchanged with documented defaults.

### Question

Official ISED text is stored separately from original explanation content. Answer order in source remains correct first; presentation order is generated by engines.

```json
{
  "id": "B-001-001-001",
  "bankId": "basic-2025-07-15",
  "categoryId": "B-001",
  "subsectionId": "B-001-001",
  "sourceOrder": 1,
  "text": {
    "en": "Official English question text kept verbatim.",
    "fr": "Texte français officiel conservé tel quel."
  },
  "answers": [
    {
      "sourceIndex": 0,
      "isCorrect": true,
      "text": {
        "en": "Official correct answer in English.",
        "fr": "Réponse correcte officielle en français."
      }
    },
    {
      "sourceIndex": 1,
      "isCorrect": false,
      "text": {
        "en": "Official distractor 1 in English.",
        "fr": "Distracteur officiel 1 en français."
      }
    },
    {
      "sourceIndex": 2,
      "isCorrect": false,
      "text": {
        "en": "Official distractor 2 in English.",
        "fr": "Distracteur officiel 2 en français."
      }
    },
    {
      "sourceIndex": 3,
      "isCorrect": false,
      "text": {
        "en": "Official distractor 3 in English.",
        "fr": "Distracteur officiel 3 en français."
      }
    }
  ]
}
```

### Category

```json
{
  "id": "B-001",
  "bankId": "basic-2025-07-15",
  "name": {
    "en": "Regulations and Policies",
    "fr": "Règlements et politiques"
  },
  "frenchNameStatus": "verified",
  "questionCount": 199,
  "subsectionCount": 25,
  "examQuestionCount": 25,
  "nameSource": "hand-maintained from verified ISED/RAC materials"
}
```

### Subsection

```json
{
  "id": "B-001-001",
  "bankId": "basic-2025-07-15",
  "categoryId": "B-001",
  "questionIds": [
    "B-001-001-001",
    "B-001-001-002",
    "B-001-001-003",
    "B-001-001-004"
  ],
  "questionCount": 4,
  "lessonIds": ["L-001-01"],
  "title": {
    "en": null,
    "fr": null
  }
}
```

### Module front matter

Module `index.md` files store the ordering and lesson list for each curriculum module. Validation requires `order` values 1 through 8 to be unique across modules.

```json
{
  "type": "module",
  "id": "M5",
  "categoryId": "B-005",
  "order": 1,
  "title": {
    "en": "Basic Electronics and Theory",
    "fr": null
  },
  "lessonIds": ["L-005-01", "L-005-02", "L-005-03", "L-005-04", "L-005-05"],
  "status": "outline"
}
```

### Lesson front matter

Lesson files may store front matter as YAML in Markdown, but validation should parse it into this JSON shape.

```json
{
  "id": "L-001-03",
  "title": {
    "en": "Bands, privileges, and power",
    "fr": null
  },
  "moduleId": "M1",
  "categoryIds": ["B-001"],
  "covers": [
    "B-001-011",
    "B-001-012",
    "B-001-013",
    "B-001-014",
    "B-001-015",
    "B-001-016",
    "B-001-017"
  ],
  "prerequisites": ["L-001-01"],
  "estimatedMinutes": 30,
  "quizIds": ["QZ-L-001-03-A"],
  "status": "outline"
}
```

### Lesson quiz files

Lesson front matter `quizIds` refer to JSON files at `content/quizzes/{quizId}.json` with `{ id, lessonId, officialQuestionIds, conceptChecks }`, where each concept check stores localized prompt text, choices with exactly one `isCorrect: true`, and localized explanation text. Concept checks are pedagogically optional: rule-based reference-style modules may use official-question-only lesson quizzes with `conceptChecks: []`, and the engine must render the resulting official items normally.

### Explanation

Explanations are original project content and must not copy study-guide prose. Per-choice notes in explanation bodies are keyed by official answer `sourceIndex` and start with the choice's quoted short value so shuffled review screens can label them unambiguously.

```json
{
  "id": "EXP-B-001-015-003",
  "questionId": "B-001-015-003",
  "bankId": "basic-2025-07-15",
  "status": "draft",
  "body": {
    "en": "Original explanation text that teaches why the correct answer is correct.",
    "fr": null
  },
  "citations": [
    {
      "type": "rbr-4",
      "url": "https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service"
    },
    {
      "type": "question",
      "id": "B-001-015-003"
    }
  ],
  "licenseClass": "original"
}
```

### ExamAttempt

`selectedSourceIndex` is nullable; an unanswered mock-exam item is recorded with `selectedSourceIndex: null` and scored incorrect.

```json
{
  "id": "attempt-2026-01-02T03:04:05Z-local-uuid",
  "bankId": "basic-2025-07-15",
  "mode": "mock-exam",
  "seed": "exam-fixture-001",
  "startedAt": "2026-01-02T03:04:05.000Z",
  "submittedAt": "2026-01-02T04:10:00.000Z",
  "timer": {
    "enabled": false,
    "secondsAllowed": null,
    "secondsElapsed": 3955
  },
  "items": [
    {
      "position": 1,
      "questionId": "B-007-003-002",
      "subsectionId": "B-007-003",
      "categoryId": "B-007",
      "choicePermutation": [2, 0, 3, 1],
      "selectedSourceIndex": 0,
      "isCorrect": true
    }
  ],
  "score": {
    "correct": 80,
    "total": 100,
    "percent": 80,
    "passed": true,
    "honours": true
  }
}
```

### QuestionProgress

```json
{
  "questionId": "B-006-004-007",
  "bankId": "basic-2025-07-15",
  "attempts": 5,
  "correctAttempts": 3,
  "lastAttemptedAt": "2026-01-02T04:10:00.000Z",
  "lastResult": "incorrect",
  "lastAnsweredWithHelp": false,
  "recentResults": [true, true, false, true, false],
  "recentAnsweredWithHelp": [false, false, false, false, false],
  "leitner": {
    "box": 0,
    "dueAt": "2026-01-02T04:10:00.000Z"
  },
  "notes": null
}
```

### Engine fixture

Fixtures are language-neutral JSON inputs and expected outputs. They should avoid relying on localized strings. RNG and exam fixtures deliberately record exact outputs so TypeScript and Swift implementations cannot drift. Canonical reference outputs now live in `fixtures/engine/`: RNG vectors in `fixtures/engine/rng-vectors.json`, the small exam-generation fixture in `fixtures/engine/exam-generation-small.json`, and the full-bank exam-generation fixture in `fixtures/engine/exam-generation-full-bank-basic-2025-07-15.json`.

RNG vector fixture shape:

```json
{
  "id": "rng-vector-fixture-seed-001",
  "rng": {
    "algorithm": "fnv1a64-pcg32-xsh-rr",
    "seed": "fixture-seed-001"
  },
  "expectedOutput": {
    "first8Uint32": [3349296149, 2984901485, 227229724, 3559621342, 747151403, 1723737868, 1078516364, 1488100801]
  }
}
```

Small exam-generation fixture shape:

```json
{
  "id": "exam-generation-small-fixture-001",
  "bankId": "basic-2025-07-15",
  "rng": {
    "algorithm": "fnv1a64-pcg32-xsh-rr",
    "seed": "fixture-seed-001"
  },
  "input": {
    "subsections": [
      {
        "id": "B-001-001",
        "questionIds": ["B-001-001-001", "B-001-001-002", "B-001-001-003", "B-001-001-004"]
      },
      {
        "id": "B-001-002",
        "questionIds": ["B-001-002-001", "B-001-002-002", "B-001-002-003", "B-001-002-004"]
      },
      {
        "id": "B-002-001",
        "questionIds": ["B-002-001-001", "B-002-001-002", "B-002-001-003", "B-002-001-004"]
      }
    ],
    "answerSourceIndexes": [0, 1, 2, 3]
  },
  "expectedOutput": {
    "items": "see fixtures/engine/exam-generation-small.json for exact final question IDs/order and choicePermutation arrays",
    "examQuestionCount": 3,
    "oneQuestionPerInputSubsection": true,
    "choicePermutationDefinition": "choicePermutation[displayIndex] = sourceIndex; sourceIndex 0 is the correct answer"
  }
}
```

Full-bank exam fixtures use the same shape with all 100 subsections and additionally assert category counts `25/9/21/6/13/13/8/5`; the exact output is in `fixtures/engine/exam-generation-full-bank-basic-2025-07-15.json`.

## Engine design

### Randomness

Both engines use the same deterministic seeded RNG for fixture mode: FNV-1a 64-bit seed hashing feeding PCG32 XSH RR 64/32. Production sessions generate a random seed locally and store it with the attempt, but the generation algorithm from a seed string is the same.

Seed hashing:

- Convert the seed string to UTF-8 bytes without normalization.
- FNV-1a 64-bit offset basis: `14695981039346656037` (`0xcbf29ce484222325`).
- FNV-1a 64-bit prime: `1099511628211` (`0x00000100000001b3`).
- For each byte: `hash = hash XOR byte`; then `hash = hash * prime mod 2^64`.
- The final 64-bit hash is PCG `initstate`.

PCG32 initialization and output:

- Algorithm: PCG32 XSH RR 64/32, matching the reference `pcg32_srandom` procedure.
- Multiplier: `6364136223846793005` (`0x5851f42d4c957f2d`).
- Fixed `initseq`: `1442695040888963407` (`0x14057b7ef767814f`). This value is passed as `initseq`, so `inc = (initseq << 1) | 1 = 0x280af6fdeecf029f`; implementers must not use `1442695040888963407` directly as `inc`.
- Initialization procedure, with all arithmetic modulo `2^64`:
  1. `state = 0`.
  2. `inc = (initseq << 1) | 1`.
  3. Draw and discard one `pcg32` value.
  4. `state = state + initstate`.
  5. Draw and discard one `pcg32` value.
- `pcg32` draw procedure:
  1. `oldstate = state`.
  2. `state = oldstate * multiplier + inc`.
  3. `xorshifted = (((oldstate >> 18) XOR oldstate) >> 27) & 0xffffffff`.
  4. `rot = oldstate >> 59`.
  5. Return `rotateRight32(xorshifted, rot)`, equivalent to `(xorshifted >> rot) | (xorshifted << ((-rot) & 31))` masked to 32 bits.

Bounded integers and shuffles:

- `bounded(n)` requires `1 <= n <= 2^32`.
- Compute `threshold = (2^32 - n) mod n` using a 64-bit intermediate.
- Draw `r = pcg32()` until `r >= threshold`; return `r mod n`.
- Fisher-Yates shuffle: for `i` from `array.count - 1` down to `1`, draw `j = bounded(i + 1)` and swap indexes `i` and `j`.

Rules:

- The seed is recorded in every quiz or exam attempt.
- Engine fixtures specify the RNG algorithm and seed.
- TypeScript and Swift must use unsigned wrapping arithmetic and pass the shared RNG vector fixture before exam fixtures are trusted.
- Random calls happen only in the documented order for the relevant algorithm.
- Engines use the Fisher-Yates algorithm above with the shared RNG.

### Exam generation algorithm

Input:

- Normalized question records.
- Derived subsection list containing exactly 100 subsection IDs for a full mock exam, or a smaller explicit subsection list for engine fixtures.
- Seed.

Algorithm and exact RNG consumption order:

1. Group questions by subsection ID.
2. Assert a full mock exam has exactly 100 groups. Fixture inputs may use a smaller explicit group count and must assert that count instead. Sort subsection IDs ascending by ordinal byte/ASCII comparison of the ID string, and sort question IDs within each subsection ascending by the same ordinal byte/ASCII comparison.
3. For each subsection in sorted order, choose `questionIds[bounded(questionIds.count)]` from that subsection's sorted question ID list. This consumes one bounded RNG result per subsection before any shuffling.
4. Create an exam item with question ID, category ID, subsection ID, and source answer indexes exactly `[0, 1, 2, 3]`; any other answer source index list is invalid. Source index `0` is the correct answer because the importer preserves ISED's correct-answer column first. When derived from the question ID, `categoryId` is the first five characters.
5. Shuffle the selected exam items using Fisher-Yates and the same seeded RNG. This consumes all question-order shuffle draws after selection and before answer shuffles.
6. For each item in final question order, shuffle answer source indexes `[0, 1, 2, 3]` using Fisher-Yates and record the resulting `choicePermutation`. This consumes all choice-shuffle draws in final display order.
7. Persist the seed, selected question IDs, order, and answer permutations.
8. Present answer choices by following `choicePermutation`.

`choicePermutation[displayIndex] = sourceIndex`; for example, `choicePermutation: [2, 0, 3, 1]` means display choice 0 uses source answer 2, display choice 1 uses the correct source answer 0, and so on. `requireFullMockExam` is optional in fixture input and defaults to `false`.

Required invariants for full mock exams:

- Exactly 100 items.
- Exactly one item from each subsection.
- Category counts match `25/9/21/6/13/13/8/5`.
- Every item has one correct answer source index.
- Answer display order can be reconstructed for review.

### Practice generation algorithm

Practice sessions use the same item representation as mock exams.

Supported scopes:

- `category`: selected category IDs.
- `subsection`: selected subsection IDs.
- `weak`: subsections whose recent performance is below threshold.
- `due`: questions with a stored progress record whose Leitner `dueAt <= now`; unseen questions with no stored progress record are not due and are excluded from this scope.
- `all`: all active questions.

Default item selection:

1. Build eligible question IDs from the selected scope.
2. Exclude questions only if the user explicitly chooses an exclusion filter.
3. Prioritize due questions, then unseen questions, then other questions ordered by weakest recent performance. In the `due` scope, eligible questions are only stored progress records with `dueAt <= now`, so unseen questions are excluded.
4. Shuffle ties with seeded RNG.
5. Record answer choice permutations.

### Scoring and readiness

Score thresholds:

- Pass: `correct >= 70` out of 100.
- Basic with Honours: `correct >= 80` out of 100.
- Non-100 engine scoring fixtures apply the same thresholds to percent (`>= 70` and `>= 80`) so synthetic cases remain meaningful.
- Unanswered mock-exam items have `selectedSourceIndex: null` and count as incorrect.

Percent formula:

- Percent is the IEEE-754 double result of `(correct / total) * 100`, computed in that order.
- If `total == 0`, percent is `0`.
- Engine fixture runners compare percent values exactly.

Mock exam report:

- Raw score.
- Percent.
- Pass boolean.
- Honours boolean.
- Category breakdown sorted by ordinal category ID.
- Incorrect and unanswered question list in input item order.
- Weak subsections list sorted by ordinal subsection ID.

Readiness inputs for v1:

- Completed mock exams may be supplied in any order; engines sort them by `submittedAt` descending before evaluation.
- Duplicate `submittedAt` timestamps are rejected because tie-breaking is undefined.
- Timestamps are canonical UTC strings in `YYYY-MM-DDTHH:MM:SS.sssZ` format. Outputs repeat timestamp strings exactly, and fixture runners compare them as strings.
- The most recent three completed mock exams, or all completed mock exams if only two exist.
- Per-attempt category breakdowns from those same attempts.
- Current due-review item count from stored Leitner progress records where `dueAt <= now`; unseen questions with no record are not counted.

Readiness aggregation and precedence:

1. If there are fewer than two completed mock exams, return `not-enough-data`; show study/practice guidance but do not claim pass or honours readiness.
2. Aggregate each category across the considered attempts as `sum(correct) / sum(total)`. If any category aggregate is below 70%, return `needs-review` and identify those categories.
3. If due-review item count is at least 5, return `needs-review` and identify due review as the reason.
4. If at least two considered attempts score 80 or higher, return `honours-ready`.
5. If at least two considered attempts score 70 or higher, return `pass-ready`.
6. Otherwise return `needs-review` with `reasons: []`.

This order is fixture-testable: fixtures provide mock attempts, per-category totals, due-review count, and the expected readiness state/reasons. A new user with zero stored progress records has due-review count `0`; with fewer than two completed mock exams, readiness is `not-enough-data`. The due-review threshold is `>= 5`, so a due-review count of `4` does not block pass/honours readiness.

Weak subsection detection:

- `recentResults` has maximum length 5 per question record, is ordered oldest to newest, and is updated by appending the newest result then truncating from the front until at most 5 entries remain. `lastAnsweredWithHelp` flags whether the latest answer was submitted after a hint was shown, and `recentAnsweredWithHelp` is the same-length oldest-to-newest flag array for `recentResults`. Missing help fields in older exports, IndexedDB rows, or SwiftData rows default to `false`.
- Basic progress exports carry `lessonIdVersion: 2` after the TASK-46.10 lesson split. Missing `lessonIdVersion`, or `lessonIdVersion: 1`, means legacy lesson IDs and quiz IDs whose meanings changed with that split; imports migrate only those legacy rows. Sync payloads also mark each lesson progress and lesson quiz device row with `lessonIdVersion` so a legacy device row arriving after migration is rewritten while a v2 row is preserved unchanged. The top-level schema `version` remains `1` because the field is additive and backward compatible. Imports validate raw rows before migration (including duplicate IDs, timestamps, scores, and exact version-1 quiz membership), then validate migrated rows against current membership; migration must not repair an invalid import into an accepted one.
- TASK-46.10 read credit is conservative (coordinator decision 2026-10-19): a destination counts as read only when **every** old lesson contributing to it was read, with `readAt` the latest source timestamp and `readCount` the minimum source count. Thus new L-005-05 needs both old L-005-04 and L-005-05; both M8 destinations need both old M8 lessons; L-001-05 needs both old L-001-03 and L-001-05. L-005-06 needs only old L-005-05. Missing sources receive no credit; under-crediting is safer for learning. Apply this rule separately per device before summing counts across devices. If the raw per-device rows reproduce the raw top-level lesson progress, derive the migrated top level from the migrated device rows (sum of per-device minima, not minimum of aggregate sums). Incoherent exports retain the top-level migration fallback rather than letting device rows change their read credit.
- Split quiz migration maps old concept-check IDs explicitly by their text at `350a3b53`, not by reused ID numbers. The two old M8 filter checks have no current equivalent and are dropped explicitly. Recomputed totals include assigned official questions and concept checks; correct concepts equal assigned concepts minus mapped wrong concepts. For partial attempts, `total − officialQuestionIds.count` identifies the answered prefix of the old ordered concept checks (the UI asks them in order). Explicit wrong concept IDs outside that prefix are always included as wrong; inconsistent historical rows never gain inferred correct answers for those IDs. Official questions use subsection prefixes on both platforms so older local IDs outside the sampled historical quiz are preserved; imports still reject IDs outside exact historical membership before migration.
- Apple's launch migration rewrites lesson and quiz device rows and inserts a keyed, local SwiftData `PreferencesEntity` marker in the same `context.save()` transaction. Marker presence, not UserDefaults, prevents replay. The marker survives user-preference reset/rollback and split-store preference copies. Web's IndexedDB upgrade clears/replaces legacy lesson stores in its upgrade transaction. Pure sync deduplication does not migrate IDs on either platform. An explicitly null `lessonIdVersion` is invalid (only omission, `1`, or `2` is supported).
- A subsection's recent attempts are the multiset union of every boolean in `recentResults` from stored progress records for active questions in that subsection; duplicate true/false entries are counted, and questions with no progress record contribute zero attempts. Accuracy remains based on actual correctness, so a hinted correct answer still increments `correctAttempts` and stores `lastResult: "correct"`.
- Helped correct answers do not clear weak areas: when deriving weak subsections, a `true` result whose paired `recentAnsweredWithHelp` flag is `true` counts as an attempt but not as proficiency-correct, so a helped answer that rolls an older failure out of the five-result window still cannot clear the weak area. Helped incorrect answers count as incorrect attempts.
- A subsection is weak if that proficiency-correct union has at least two attempts and `correct / total < 70%`; exactly 70% is not weak, and a single pooled attempt is not enough to classify weakness.
- A subsection is also weak if it was missed or unanswered on the latest mock exam.
- The output is the sorted union of progress-derived weak subsections and latest-exam missed/unanswered subsections.
- Fixtures must cover the max length, ordering, append/truncate behaviour, pooled attempts, exact-threshold behaviour, and latest-exam union behaviour.
- If confidence ratings are later added, they must remain local-only and fixture-tested before affecting readiness.

### Spaced repetition

Use a simple Leitner scheme precise enough for both engines to fixture-test.

State per stored question record:

- `box`: integer from 0 to 5.
- `dueAt`: UTC timestamp.
- `attempts`, `correctAttempts`, `lastAnsweredWithHelp`, `recentResults`, and `recentAnsweredWithHelp` where the recent arrays follow the max-length and ordering rules above.

Time rules:

- `now` is an explicit engine input for every progress update; engines must not read wall-clock time inside the Leitner update function.
- `now`, `dueAt`, `lastAttemptedAt`, and other engine timestamps use canonical UTC millisecond strings in `YYYY-MM-DDTHH:MM:SS.sssZ` format. Outputs emit that format and fixture runners compare timestamp strings exactly.
- Interval units are fixed multiples of 86,400 seconds in UTC, not calendar days in local time.
- A question is due only when it has a stored progress record and `dueAt <= now`; unseen questions have no stored record, are not due, and are excluded from due-review counts and the `due` practice scope. Due question IDs are output sorted by ordinal question ID.
- The virtual `box = 0` state is used only as the starting point when applying the first answer to an unseen question.
- A correct answer before `dueAt` still promotes; v1 does not block early promotion.
- Repeated answers to the same question in one session are applied in answer order, each with its own explicit `now` value or the session submit time if the mode batches updates. Sequence-case output records are sorted by ordinal question ID.

Answered-with-help rule:

- Practice/review UI may set `answeredWithHelp` on an answer update after a hint was shown. Mock exams do not set this flag.
- The correctness outcome is still stored in `lastResult`, `recentResults`, and `correctAttempts`; answered-with-help is an additional flag, not a third result.
- A helped answer gives no new mastery credit and does not clear weak areas. A helped correct answer keeps the current Leitner box without promotion and is due immediately (`dueAt = now`); a helped incorrect answer behaves exactly like any incorrect answer.

On unaided correct answer:

- New box is `min(box + 1, 5)`.
- Due interval by box after promotion:
  - Box 1: `1 * 86400` seconds.
  - Box 2: `3 * 86400` seconds.
  - Box 3: `7 * 86400` seconds.
  - Box 4: `14 * 86400` seconds.
  - Box 5: `30 * 86400` seconds.
- New `dueAt = now + intervalSeconds`.

On helped correct answer:

- New box remains the current box.
- Due interval is immediate (`dueAt = now`).

On incorrect answer, including helped incorrect:

- New box is `0`.
- Due interval is immediate (`dueAt = now`).

Session mode:

- Practice immediate feedback updates after each answer.
- Review-later practice updates on submit, applying answers in session order.
- Mock exam updates on submit only, applying answers in exam order.

## Platform apps

### Web app

Decision: the web app uses a Vite + React + TypeScript static build with pnpm as the package manager.

Web app components:

- Static app shell.
- Content loader for bundled JSON/Markdown.
- TypeScript engine.
- IndexedDB progress store, with localStorage only for small preferences if needed.
- Service worker for offline PWA caching.
- Settings screen with export, import, and reset all data.
- No server, accounts, analytics, third-party requests, or remote fonts.

### Apple app

Apple app components:

- SwiftUI multiplatform target for iOS/iPadOS 27.0+, macOS 27.0+, visionOS 27.0+, and tvOS 27.0+. watchOS remains later.
- Shared practice, lessons, mock exams, progress, and settings adapt per platform: navigation/window layout on iOS, iPadOS, macOS, and visionOS; focus-engine navigation, large type, and overscan-safe margins on tvOS.
- Bundled generated content, design tokens, and layered icon artwork; reference PDFs are not shipped in the apps, and release bundles must satisfy the [public-release gate](content-licensing.md#public-release-gate).
- Native Swift engine matching fixtures.
- SwiftData local progress models.
- File import/export for progress JSON.
- No networking code, no third-party SDKs, no iCloud sync, analytics, or telemetry in v1.

Build rule:

- Use `xbuild` for all Apple builds and tests. Never call `xcodebuild` directly.

## Shared cross-platform test fixtures

Fixture categories:

- Importer fixtures: header trimming, checksum manifest, checksum-mismatch failure, count validation, duplicate detection, missing French detection, category counts, untrimmed field values, and rejection of quoted fields or embedded newlines.
- Engine fixtures: deterministic mock exam generation, RNG vectors, answer permutation recording, scoring boundary cases (`0`, `69`, `70`, `79`, `80`, `100`), exact percent values, unanswered-as-incorrect scoring, category breakdown, weak-subsection detection including pooled attempts and latest-exam misses, readiness aggregation including shuffled input and due-review boundaries, and Leitner updates including all box-promotion intervals.
- Progress fixtures: export/import round trip, reset semantics, schema version migration when needed.
- Content coverage fixtures: all 100 subsections mapped to lessons; unknown subsection IDs fail validation; explanations reference known question IDs.

Fixture requirements:

- Fixtures are plain JSON.
- Swift and TypeScript read the same engine fixture files under `fixtures/engine/**`; other fixture directories belong to their owning tools.
- Fixtures avoid localized UI strings.
- Fixtures include expected output or expected invariant assertions.
- Any fixture change is reviewed as a product behaviour change.

## Build and CI outline

Initial CI should run without network-dependent tests after pnpm dependencies are installed.

Suggested jobs:

1. Markdown link check for `docs/` and `tasks/`.
2. Content schema validation.
3. Importer validation against vendored source files.
4. Lesson coverage check.
5. TypeScript lint and tests for web packages.
6. Static web build.
7. Swift formatting or linting if selected.
8. Swift unit tests for engine fixtures.
9. Apple app build through `xbuild` only.
10. Privacy audit checks: forbidden dependency names, network usage grep, app offline smoke test procedure.

CI should not call `xcodebuild` directly.

## Content and lesson coverage plan

Lesson coverage starts with category-level modules and subsection ranges from [requirements.md](requirements.md). Once subsection titles are available, each lesson front matter should enumerate exact subsection IDs.

Minimum coverage implementation:

- `B-001`: 25 subsections across four lessons.
- `B-002`: 9 subsections across three lessons.
- `B-003`: 21 subsections across four lessons.
- `B-004`: 6 subsections across two lessons.
- `B-005`: 13 subsections across three lessons.
- `B-006`: 13 subsections across three lessons.
- `B-007`: 8 subsections across two lessons.
- `B-008`: 5 subsections across two lessons.

Coverage script pseudo-logic:

```text
expected = all subsection IDs derived from normalized question IDs
covered = union of lesson.frontMatter.covers
unknown = covered - expected
missing = expected - covered
if unknown not empty: fail
if missing not empty: fail
print duplicate coverage for author review
```

## Open architecture questions

- Confirm T-007 permission scope covers public bundling of verbatim question text as app data before publication or distribution; reference PDFs remain source artifacts and are not shipped in the apps.
