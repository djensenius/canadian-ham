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
