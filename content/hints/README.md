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

## Good vs bad hint examples

Bad hints tell the learner to sort the question into generic buckets, reuse the same setup across many unrelated questions, or say to use the table row. For example, "Decide whether this is prohibited conduct, a process safeguard, or a consequence" is too generic for a false-distress penalty question, and "use the table row" is just a lookup instruction.

A good Hint 1 is specific to the question's concept without naming or eliminating an option. For a false-distress penalty question, a better Hint 1 is: "Misusing distress signals endangers lives, so review how the Act treats serious radio offences before recalling the penalty framework." It points at the topic without stating the exact penalty structure.

A good Hint 2 teaches the reasoning or distinction the question turns on. Shared distinctions are allowed only when the questions truly share the same idea, and even then the wording should be tailored to the current question. For pure recall facts where any useful Hint 2 would give away the answer, use a one-level ladder and include `singleLevelReason`.

Before accepting any hint, apply this self-test: could a learner who does not know the material pick the right option from this hint alone, or from Hint 1 plus Hint 2 together? Read the four options and ask whether the hint makes any one option more likely than the others. If yes, soften the hint so the learner still has to recall or reason out the decisive fact, or use a one-level ladder. For example, "not a waiting period before operating" eliminates waiting-period options, "more than one possible consequence" points directly at a combined penalty option, "independent branches rather than a locked sequence" is a near-synonym for an any-order answer, and "both sides of authority matter" gives away a both-people authorization answer.

For B-001 recall items, there is often no space between a useful content hint and the answer. In those cases, use B: Hint 1 is a neutral, learner-facing topic pointer that names the lesson topic, not the rule, and the lesson link carries the teaching location. Do not write meta text such as "This item tests" or lookup text such as "use the row." Do not reuse a lesson-table row label as the pointer when the label contains the fact the learner is being asked to recall. Good B-001 topic pointers include "Review how the rules treat low-power amateur stations" and "Review the band-sharing rules for the amateur service." Use a `singleLevelReason` such as "Pure recall: any content hint identifies or eliminates an option; topic pointer and lesson link only."

Keep two-level A+C hints where a method, formula, conversion, or principle helps the learner work the question. The option self-test applies to stating facts or results, not to teaching a method the learner still has to apply. Do not state the computed result, name the matching option, or eliminate options by listing them. If a method hint includes a selection rule such as "nearest", "just below", or "starts there", work it against all four options in EN and FR before accepting it.

For example, a band-name question can use the wavelength relationship without giving the range:

- Hint 1: "A band's name is roughly its wavelength. Convert with f (MHz) ≈ 300 / λ (m)."
- Hint 2: "Work out the frequency for 10 m, then compare how the candidate ranges line up with the conversion and the nearby HF-band pattern."

Use the lesson link to point to the method or band table section that supports the reasoning. Pure recall still uses B: topic pointer plus lesson link only.

## Reviewer checklist

For each batch, reviewers should verify that hints:

- follow the nudge-then-setup ladder, or include a specific one-level reason when Hint 2 would be a giveaway;
- do not copy or closely paraphrase official question, answer, option, or reference-sheet wording;
- avoid answer aliases, acronyms, inflections, and distinctive partial copies that a checker may miss;
- do not leak equivalent unit conversions such as `1.5 MHz` for an official `1 500 kHz` answer;
- do not list distractor numeric values as eliminations, such as "it is not 24 V";
- link to the lesson section that teaches the distinction or setup and verify that the linked heading is still present.

The checker covers common direct copies, numeric correct-answer values, selected aliases, distinctive partial copies, lesson-link existence, and single-level reasons. Unit conversions, distractor values listed by value, and correct-answer numbers that all appear in two or more options remain reviewer responsibilities.
