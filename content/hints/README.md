# Question hints

Original per-question hints live under `content/hints/<category>/<questionId>.json`, mirroring `content/explanations/`.

Each Basic question hint file uses `packages/schemas/hint.schema.json`:

- `id`: `HINT-` plus the official Basic question ID.
- `questionId`: the official Basic question ID.
- `bankId`: the active Basic bank ID.
- `status`: content workflow state.
- `hints`: exactly two entries, `level` 1 then 2, each with original English and French text.
- `referenceSheetSection`: a section key for UI-provided reference-sheet pointers, or `null`/omitted when no pointer applies. Hint prose should remain generic so apps can hide the pointer when the reference sheet is unavailable.
- `licenseClass`: `original`.

Hints must not copy official ISED question text, answer option text, or reference-sheet content.

## Hint style rules

The owner rule is: Hint 2 never gives the answer. Apply these constraints to every hint file:

- Hints must never eliminate answer options. Do not paraphrase, list, contrast with, or otherwise point at wrong options.
- Do not name the correct answer, copy distinctive words from it, or point at those distinctive words with near-synonyms.
- Hint 1 nudges toward the concept, formula, relationship, or reference-sheet area.
- Hint 2 teaches the underlying relationship or setup well enough for the learner to reason from it. For recall questions, explain how the pieces fit together without singling out this question's option; for example, the Act empowers both the Regulations and the department's standards rather than forming one Act → Regulations → standards chain.
- Each hint must stand alone. Do not say "same as the previous question" or depend on practice order, because questions are randomized.
- Do not state a fact that answers another question in the same subsection.
- Use natural French with one term per concept across files. Prefer ISED terminology, including `stations de radioamateur`.
- Reference-sheet pointers belong in `referenceSheetSection`, not in hint prose. The UI decides whether a pointer label is available.

The checker deliberately treats some short distractor words as meaningful when they are the whole option. That can create safe false positives for common words such as "never"/"jamais"; rewrite the hint instead of weakening the checker unless a reviewer approves a narrower rule.

## Reviewer checklist

For each batch, reviewers should verify that hints:

- follow the two-step nudge-then-setup ladder without eliminating options;
- do not copy or closely paraphrase official question, answer, option, or reference-sheet wording;
- avoid answer aliases, acronyms, inflections, and distinctive partial copies that a checker may miss;
- do not leak equivalent unit conversions such as `1.5 MHz` for an official `1 500 kHz` answer;
- do not list distractor numeric values as eliminations, such as "it is not 24 V".

The checker covers common direct copies, numeric correct-answer values, selected aliases, and distinctive partial copies. Unit conversions and distractor values listed by value remain reviewer responsibilities.
