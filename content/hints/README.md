# Question hints

Original per-question hints live under `content/hints/<category>/<questionId>.json`, mirroring `content/explanations/`.

Each Basic question hint file uses `packages/schemas/hint.schema.json`:

- `id`: `HINT-` plus the official Basic question ID.
- `questionId`: the official Basic question ID.
- `bankId`: the active Basic bank ID.
- `status`: content workflow state.
- `hints`: one or two entries with original English and French text. Level 1 is required; level 2 is optional only for approved single-level recall cases.
- `singleLevelReason`: required when `hints` contains only level 1. Record why a useful level 2 would give away the answer.
- `lessonLink`: `{ lessonId, sectionAnchor? }` pointing to the lesson section that teaches the hint topic. The checker verifies that the lesson exists, covers the question's subsection, and exposes the heading anchor the lesson readers will render (task-50.11–50.13). The shared slug rules are: lowercase, strip inline Markdown links/emphasis/code markers and HTML tags, drop punctuation except hyphens, and replace each whitespace character with `-`; duplicate headings receive `-1`, `-2`, and so on. The depth-1 lesson title and `Illustration brief` author section are not linkable.
- `referenceSheetSection`: a section key for UI-provided reference-sheet pointers, or `null`/omitted when no pointer applies. Hint prose should remain generic so apps can hide the pointer when the reference sheet is unavailable.
- `licenseClass`: `original`.

Hints must not copy official ISED question text, answer option text, or reference-sheet content.

## Hint style rules

The owner rule is: Hint 2 never gives the answer. The 2026-10-16 recall-question ruling is **A + C by default**:

- Hint 1 nudges toward the concept, formula, relationship, or reference-sheet area.
- Hint 2 teaches the distinctions between the concepts involved, not this question's answer. For example, teach what an Act, a regulation, a departmental standard, and a department are; use the correct model that the Act empowers both the Regulations and the department's standards, not a single Act → Regulations → standards chain.
- Hint 2 also carries a `lessonLink` to the lesson section that teaches the topic. Put the link in metadata, not prose.
- A one-level ladder is allowed only when no useful Hint 2 can avoid giving away the answer. In that case, include only level 1 and a specific `singleLevelReason`.

Apply these constraints to every hint file:

- Hints must never eliminate answer options. Do not paraphrase, list, contrast with, or otherwise point at wrong options.
- Do not name the correct answer, copy distinctive words from it, or point at those distinctive words with near-synonyms.
- Do not connect the asked-for function to one option in any hint level or across levels. Shared distinctions are fine; directly stating another question's answer is not.
- Each hint must stand alone. Do not say "same as the previous question" or depend on practice order, because questions are randomized.
- Use natural French with one term per concept across files. Prefer ISED terminology, including `stations de radioamateur`.
- Reference-sheet pointers belong in `referenceSheetSection`, not in hint prose. The UI decides whether a pointer label is available.

The checker deliberately treats some short distractor words as meaningful when they are the whole option. That can create safe false positives for common words such as "never"/"jamais"; rewrite the hint instead of weakening the checker unless a reviewer approves a narrower rule. The distinctive two-word check can also safely over-flag common phrases from long answers, such as "transmitter power", "ground wave", or "radio energy"; treat those as review prompts and rephrase rather than weakening the batch checker.

## Reviewer checklist

For each batch, reviewers should verify that hints:

- follow the nudge-then-setup ladder, or include a specific one-level reason when Hint 2 would be a giveaway;
- do not copy or closely paraphrase official question, answer, option, or reference-sheet wording;
- avoid answer aliases, acronyms, inflections, and distinctive partial copies that a checker may miss;
- do not leak equivalent unit conversions such as `1.5 MHz` for an official `1 500 kHz` answer;
- do not list distractor numeric values as eliminations, such as "it is not 24 V";
- link to the lesson section that teaches the distinction or setup and verify that the linked heading is still present.

The checker covers common direct copies, numeric correct-answer values, selected aliases, distinctive partial copies, lesson-link existence, and single-level reasons. Unit conversions, distractor values listed by value, and correct-answer numbers that all appear in two or more options remain reviewer responsibilities.
