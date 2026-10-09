# fixtures

Purpose: shared JSON fixtures that define cross-platform behaviour.

Belongs here:

- Engine fixtures under [`engine/`](engine/) that both TypeScript and Swift implementations must pass.
- Morse timing and grading fixtures under [`morse/`](morse/) that both Morse implementations must pass.
- Importer fixtures under [`importer/`](importer/) for source parsing and validation edge cases.

Must not go here:

- Runtime app code.
- Verbatim ISED source artifacts.
- Fixtures that depend on localized UI strings instead of stable IDs and invariants.

Relevant docs: [`../docs/architecture.md`](../docs/architecture.md), [`../docs/requirements.md`](../docs/requirements.md).

## Morse fixture contract

All Morse fixtures are plain JSON and have `schemaVersion: 1` with one of these `kind` values:

- `morse-timing`: text-to-timed-symbol profiles, including PARIS at `isedParis` (12.0 s), PARIS at `ric1Literal` (7.6 s), and effective-speed clamping.
- `morse-word-weighting`: RIC-1 section 8.2 weighted character counts. It includes the official RIC-1 section 8.3 English sample (Issue 8, May 2025) and the official CIR-1 section 8.3 French sample (8e édition, mai 2025), verbatim, with their weighted counts (task-12.8; sources in [`../docs/exam-facts.md`](../docs/exam-facts.md)).
- `morse-scoring`: RIC-1 section 8.7 / RIC-3 section 5.2 grading boundaries, including 5 errors passing, 6 failing, and inserted characters counting as errors.
- `morse-validation`: the RIC-1 section 8.2 character set (`A-Z`, `0-9`, `.`, `,`, `?`, `-`, `/`) and rejection cases.

The TypeScript Morse package and SwiftPM Morse package both load every JSON file under [`morse/`](morse/).

## Engine fixture contract

All engine fixtures are plain JSON and have:

```json
{
  "schemaVersion": 1,
  "kind": "fixture-kind"
}
```

Consumers must reject unknown `schemaVersion` or `kind` values. The TypeScript engine fixture runner deliberately loads only `fixtures/engine/**/*.json`; sibling fixture folders such as `fixtures/importer/` belong to other tools. Fixtures deliberately use stable IDs, source indexes, timestamps, and counts rather than localized UI strings.

Shared exactness rules:

- `choicePermutation[displayIndex] = sourceIndex`; source index `0` is the correct answer.
- `answerSourceIndexes` must be exactly `[0, 1, 2, 3]`; any other order or values are invalid.
- `categoryId` is the first five characters of `questionId` when it is derived.
- Timestamps must use canonical UTC millisecond format `YYYY-MM-DDTHH:MM:SS.sssZ` (for example, `2026-01-02T00:00:00.000Z`). Outputs use that format and runners compare timestamp strings exactly.
- Percent values are IEEE-754 doubles computed as `(correct / total) * 100` in that order; if `total === 0`, percent is `0`. Fixture comparisons are exact.
- Output ordering: `incorrectQuestionIds` preserve input item order; `weakSubsectionIds`, `dueQuestionIds`, `categoryBreakdown`, and Leitner sequence `records` are sorted by ordinal ID.
- Ordinal ID sorting compares raw UTF-8 bytes lexicographically. Implementations must not use locale-aware collation or JavaScript's native UTF-16 string comparison for fixture ordering.

### Engine fixture files and pinned rules

- `engine/rng-vectors.json` pins FNV-1a 64 seed hashing, PCG32 initialization, and uint32 draw order for multiple seed strings.
- `engine/exam-generation-small.json` pins subsection/question sorting, answerSourceIndexes `[0,1,2,3]`, exact RNG consumption order, item shuffle order, and choice permutations for a small synthetic exam.
- `engine/exam-generation-full-bank-basic-2025-07-15.json` pins the same exam-generation rules against `content/generated/basic-2025-07-15/questions.json`, including 100 items, one item per subsection, and category counts `25/9/21/6/13/13/8/5`.
- `engine/scoring.json` pins pass/honours thresholds, non-100 percentage thresholds for synthetic cases, unanswered-as-incorrect scoring, category breakdown sorting, `incorrectQuestionIds` input order, and exact percent values.
- `engine/weak-subsections.json` pins recent-result append/truncate order, pooled subsection attempts across multiple question records, below-70 weakness, exactly-70 not weak, a single pooled attempt not weak, and latest-exam misses/unanswered items unioned into the weak subsection set.
- `engine/leitner.json` pins canonical timestamp outputs, virtual box 0 first-answer handling, all promotion intervals (1, 3, 7, 14, and 30 days), box-5 cap, incorrect reset to immediate due, repeated-answer sequence ordering, due inclusivity, and ordinal sorting of due IDs/records.
- `engine/readiness.json` pins readiness sorting by `submittedAt` descending even when input is shuffled, rejection semantics for duplicate timestamps (covered by engine tests), last-three exam aggregation, weak-category precedence, due-review threshold `>= 5` including the count-4 boundary, honours/pass thresholds, final `needs-review` with `reasons: []`, and `consideredSubmittedAt` repeating input timestamp strings unchanged after sorting.

### `rng-vectors`

```json
{
  "schemaVersion": 1,
  "kind": "rng-vectors",
  "cases": [
    {
      "id": "rng-vector-fixture-seed-001",
      "rng": { "algorithm": "fnv1a64-pcg32-xsh-rr", "seed": "fixture-seed-001" },
      "expectedOutput": { "first8Uint32": [3349296149, 2984901485, 227229724] }
    }
  ]
}
```

The seed string is encoded as UTF-8 with no normalization, hashed with FNV-1a 64-bit, and used as PCG32 `initstate`. `first8Uint32` contains decimal uint32 values in draw order; the canonical full vectors live in [`engine/rng-vectors.json`](engine/rng-vectors.json).

### `exam-generation`

```json
{
  "schemaVersion": 1,
  "kind": "exam-generation",
  "id": "exam-generation-small-fixture-001",
  "bankId": "basic-2025-07-15",
  "rng": { "algorithm": "fnv1a64-pcg32-xsh-rr", "seed": "fixture-seed-001" },
  "input": {
    "sourceQuestionBankPath": "content/generated/basic-2025-07-15/questions.json",
    "subsections": [
      { "id": "B-001-001", "questionIds": ["B-001-001-001"] }
    ],
    "answerSourceIndexes": [0, 1, 2, 3],
    "requireFullMockExam": true
  },
  "expectedOutput": {
    "items": [
      {
        "position": 1,
        "questionId": "B-001-001-001",
        "subsectionId": "B-001-001",
        "categoryId": "B-001",
        "choicePermutation": [2, 0, 3, 1]
      }
    ],
    "examQuestionCount": 100,
    "oneQuestionPerInputSubsection": true,
    "choicePermutationDefinition": "choicePermutation[displayIndex] = sourceIndex; sourceIndex 0 is the correct answer",
    "categoryCounts": { "B-001": 25 }
  }
}
```

Generation order is: sort subsections by ordinal ID, sort question IDs by ordinal ID, select one question per subsection with bounded RNG, shuffle selected items, then shuffle choices for each final item in display order. `requireFullMockExam` is optional and defaults to `false`. Full-bank fixtures include all 100 input subsections and exact expected IDs/order/permutations. Canonical exact outputs live in [`engine/exam-generation-small.json`](engine/exam-generation-small.json) and [`engine/exam-generation-full-bank-basic-2025-07-15.json`](engine/exam-generation-full-bank-basic-2025-07-15.json).

### `scoring`

```json
{
  "schemaVersion": 1,
  "kind": "scoring",
  "cases": [
    {
      "id": "scoring-boundary-70",
      "input": {
        "items": [
          {
            "questionId": "B-001-001-001",
            "categoryId": "B-001",
            "subsectionId": "B-001-001",
            "selectedSourceIndex": 0
          }
        ]
      },
      "expectedOutput": {
        "correct": 1,
        "total": 1,
        "percent": 100,
        "passed": true,
        "honours": true,
        "categoryBreakdown": [
          { "categoryId": "B-001", "correct": 1, "total": 1, "percent": 100 }
        ],
        "incorrectQuestionIds": [],
        "weakSubsectionIds": []
      }
    }
  ]
}
```

`selectedSourceIndex: null` means unanswered and is scored incorrect. Percent is numeric, not localized text. For non-100 synthetic fixtures, pass and honours compare against percent (`>= 70` and `>= 80`) so the small cases remain meaningful.

### `weak-subsections`

```json
{
  "schemaVersion": 1,
  "kind": "weak-subsections",
  "recentResultCases": [
    {
      "id": "recent-results-append-truncates-to-five-oldest-to-newest",
      "input": { "existing": [true, false, true, false, true], "newest": false },
      "expectedOutput": { "recentResults": [false, true, false, true, false] }
    }
  ],
  "cases": [
    {
      "id": "weak-subsections-threshold-and-latest-exam-misses",
      "input": {
        "records": [],
        "latestExamItems": []
      },
      "expectedOutput": { "weakSubsectionIds": [] }
    }
  ]
}
```

`recentResults` is oldest to newest and keeps at most five booleans. Progress-derived weakness pools every boolean from every stored question record in a subsection. A subsection is weak when it has at least two pooled attempts and correctness below 70%. Latest-exam misses and unanswered items are separately added to the same output set, so `weakSubsectionIds` is the sorted union of progress-derived weak subsections and latest-exam weak subsections.

### `leitner`

```json
{
  "schemaVersion": 1,
  "kind": "leitner",
  "answerCases": [
    {
      "id": "leitner-unseen-correct-uses-virtual-box-zero-and-promotes-to-box-one",
      "input": {
        "existing": null,
        "update": {
          "questionId": "B-006-004-001",
          "bankId": "basic-2025-07-15",
          "isCorrect": true,
          "now": "2026-01-02T00:00:00.000Z"
        }
      },
      "expectedOutput": { "record": {} }
    }
  ],
  "sequenceCases": [],
  "dueCases": []
}
```

`now` is always an explicit canonical timestamp input. Implementations must not read the wall clock while applying fixture updates. Due intervals are fixed UTC multiples of 86,400 seconds. Unseen questions have no record and are not due; the virtual box 0 state is used only when applying the first answer.

### `readiness`

```json
{
  "schemaVersion": 1,
  "kind": "readiness",
  "cases": [
    {
      "id": "readiness-new-user-not-enough-data-and-due-count-zero",
      "input": { "completedExams": [], "dueReviewCount": 0 },
      "expectedOutput": {
        "state": "not-enough-data",
        "consideredExamCount": 0,
        "consideredSubmittedAt": [],
        "reasons": [{ "type": "not-enough-exams", "completedExamCount": 0 }]
      }
    }
  ]
}
```

Completed exams may be supplied in any order and are sorted by `submittedAt` descending before evaluation. Duplicate `submittedAt` timestamps are rejected because ties are not defined. Only the most recent three are considered. Precedence is: fewer than two exams, weak category aggregate below 70%, due review count at least five, honours-ready, pass-ready, then needs-review. The final fallback `needs-review` has `reasons: []`.

## Ambiguities recorded for implementation

- `docs/architecture.md` defines pass and honours thresholds as `correct >= 70` and `correct >= 80` for 100-question mock exams. For non-100 scoring fixtures, this implementation applies the same thresholds to the percentage so small synthetic fixtures remain meaningful.
- `docs/architecture.md` names `Weak subsection detection` as both progress-derived and latest-exam-derived. The fixture format keeps progress-derived records and latest-exam misses in one expected `weakSubsectionIds` set.
