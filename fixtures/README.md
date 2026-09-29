# fixtures

Purpose: shared JSON fixtures that define cross-platform behaviour.

Belongs here:

- Engine fixtures under [`engine/`](engine/) that both TypeScript and Swift implementations must pass.
- Importer fixtures under [`importer/`](importer/) for source parsing and validation edge cases.

Must not go here:

- Runtime app code.
- Verbatim ISED source artifacts.
- Fixtures that depend on localized UI strings instead of stable IDs and invariants.

Relevant docs: [`../docs/architecture.md`](../docs/architecture.md), [`../docs/requirements.md`](../docs/requirements.md).

## Engine fixture contract

All engine fixtures are plain JSON and have:

```json
{
  "schemaVersion": 1,
  "kind": "fixture-kind"
}
```

Consumers must reject unknown `schemaVersion` or `kind` values. Fixtures deliberately use stable IDs, source indexes, timestamps, and counts rather than localized UI strings. `choicePermutation[displayIndex] = sourceIndex`; source index `0` is the correct answer.

### `rng-vectors`

```json
{
  "schemaVersion": 1,
  "kind": "rng-vectors",
  "cases": [
    {
      "id": "rng-vector-fixture-seed-001",
      "rng": { "algorithm": "fnv1a64-pcg32-xsh-rr", "seed": "fixture-seed-001" },
      "expectedOutput": { "first8Uint32": [0, 1, 2] }
    }
  ]
}
```

The seed string is encoded as UTF-8 with no normalization, hashed with FNV-1a 64-bit, and used as PCG32 `initstate`. `first8Uint32` contains decimal uint32 values in draw order.

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

Generation order is: sort subsections by ordinal ID, sort question IDs by ordinal ID, select one question per subsection with bounded RNG, shuffle selected items, then shuffle choices for each final item in display order. Full-bank fixtures include all 100 input subsections and exact expected IDs/order/permutations.

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

`selectedSourceIndex: null` means unanswered and is scored incorrect. Percent is numeric, not localized text.

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

`recentResults` is oldest to newest and keeps at most five booleans. Pooled subsection attempts count every boolean from every stored question record in that subsection. A subsection is weak when it has at least two pooled attempts and correctness below 70%, or when it was missed/unanswered in the latest mock exam.

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
          "now": "2026-01-02T00:00:00Z"
        }
      },
      "expectedOutput": { "record": {} }
    }
  ],
  "sequenceCases": [],
  "dueCases": []
}
```

`now` is always an explicit input. Implementations must not read the wall clock while applying fixture updates. Due intervals are fixed UTC multiples of 86,400 seconds. Unseen questions have no record and are not due; the virtual box 0 state is used only when applying the first answer.

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

Completed exams are sorted by `submittedAt` descending before evaluation. Only the most recent three are considered. Precedence is: fewer than two exams, weak category aggregate below 70%, due review count at least five, honours-ready, pass-ready, then needs-review.

## Ambiguities recorded for implementation

- `docs/architecture.md` defines pass and honours thresholds as `correct >= 70` and `correct >= 80` for 100-question mock exams. For non-100 scoring fixtures, this implementation applies the same thresholds to the percentage so small synthetic fixtures remain meaningful.
- `docs/architecture.md` names `Weak subsection detection` as both progress-derived and latest-exam-derived. The fixture format keeps progress-derived records and latest-exam misses in one expected `weakSubsectionIds` set.
