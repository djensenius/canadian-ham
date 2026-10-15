# task-44.3 review-fix handoff

Branch: `task-44.3-apple-exam-tools`
Current HEAD after committing work so far: `7814b1bc` (`docs: update review fix evidence`).

Review source: `/Users/david/.cache/canadian-ham-reviews/r443-4.md`.

## Findings resolved so far

- HIGH H1: Done in `e0544e8c1dc60d932f5c369ce5bd8c38630e576e`. `auditIgnoringOccludedLessonTextContrast` in `CanadianHamPracticeUITests.swift` was restored byte-identical to `origin/main` for the function body, activity name, and note text.
- HIGH H2: Done in `e0544e8c1dc60d932f5c369ce5bd8c38630e576e`. The separate broader exam-tools occluded filter was deleted. ExamTools large/largest/iPad inspector audits now call the shared `auditIgnoringOccludedLessonTextContrast` logic in the new test file. The local ExamTools helpers were renamed from `scrollUntilHittable`/`preciseScroll` to `scrollExamToolUntilHittable`/`preciseExamToolScroll` to avoid shadowing shared helper names.
  - H2 scroll-view question evidence so far: no affected audit rerun yet after switching to the shared first-visible-scroll-view helper. If the shared helper chooses the wrong scroll view while a tool is open, stop and report with evidence; do not add another filter.
- MEDIUM M3/M4 and LOW 8: Done in `f780a9f7f48480bb18fd77e7fe8f0ed73e7cd19a`. Calculator keyboard mapping now follows the web mapping (reject Command/Control/Option only; no Shift branch; removed r/s/i/n shortcuts), calculator display/spoken value uses interface locale via `canadianHamInterfaceCalculatorLocale()`, the decimal key shows `,` for French, `updateLocale` refreshes display via `updateCalculatorLocale`, unit coverage was added, and first-responder resignation is iOS-only.
- MEDIUM M2, MEDIUM M5, LOW 2, LOW 3, LOW 4, LOW 5 partial: Done in `1f499300fb00a1fa116287d5cc2789d6b5142fb5`. Added dark loops for large-detent, largest Dynamic Type, and iPad inspector audits; restored exact sidebar column visibility; portrait iPad test records/asserts before state; renamed the overstated positioning test; added app-level `app.typeKey("7")` calculator auto-focus UI test; added UI test that starting a new mock exam resets calculator state. Some iPad non-skipped coverage is added but final iPad validation remains to run.
- LOW 1, LOW 9, MEDIUM M1: Done in `7814b1bc`. Deleted `docs/evidence/task-44.3/resume-handoff.md`; rebuilt `Localizable.xcstrings` deterministically from `origin/main` order with the 36 task keys inserted in sorted position; updated `docs/testing/ui-audit-inventory-after.md` to describe the real medium-detent exception, occluded-content rule use, plain navigator audits, and added rows for new exam-tool audit paths.
- LOW 7: Code adjusted in `e0544e8c`: the two mock navigator sheet audits reverted to plain `performAudit` because the reviewer asked to keep them plain if they pass. They still need validation in the practice/mock audit rerun.

## H3 sidebar screenshots

- Real landscape iPad sidebar comparison was refreshed and committed in `c6aebb97bcc9fa74271c1d5972429b0927c6e97a`:
  - `docs/evidence/task-44.3/sidebar-headers-before.png`
  - `docs/evidence/task-44.3/sidebar-headers-after.png`
- Capture log path: `/tmp/task-44.3-sidebar-capture-20261015-171356/`.
- `tail`/`sips` evidence after capture: both before/after files are 2500x1900 PNGs; `worktree-main 0`, `capture-origin-main 0`, and `capture-branch 0` in that log directory. Earlier portrait image inspection confirmed the origin/main capture was the real Canadian Ham app rather than SpringBoard; after coordinator steering, do not read more images in this worker.
- A fresh reviewer/worker may still need to visually confirm the final PNGs show `Study`, `Practice categories`, and `Tools` comparably, because this worker was instructed not to read images after the handoff update.

## LOW 6 empty band under back button

- Not resolved. I have not yet captured/compared the iPhone same-flow origin/main vs branch screenshots for the empty band under the back button.
- Existing reviewer observation: branch iPhone screenshots show an ~80 pt empty band, likely large-title area; must verify whether the same band exists on origin/main in the same flow. If not pre-existing, fix it; if pre-existing, report with screenshots.

## Remaining work

1. Finish/verify H3 sidebar before/after screenshots once the landscape capture finishes. Confirm they show the app, not SpringBoard, and are comparable (`Study`, `Practice categories`, `Tools` where possible).
2. Check LOW 6 empty band under back button with same-flow origin/main vs branch evidence.
3. Run validation with `nohup` chains, waiting for xbuild lock and never killing other builds:
   - iPhone full `CanadianHamExamToolsUITests` class.
   - Practice/mock audits (`testAccessibilityAuditPracticeSessionLight/Dark`, `testAccessibilityAuditMockExamFlowLight/Dark`).
   - iPad tests, including remaining non-skipped tests with `-only-testing` as requested.
   - macOS unit tests (shared code changed: calculator engine Swift + app model/views).
   - `pnpm check:apple-l10n`.
   - `node scripts/check-apple-text-sources.ts`.
   - `node scripts/check-test-guard.mjs --base origin/main --head HEAD`.
4. Update Backlog notes/AC/final summary only after validation.
5. Report final SHA, per-test results, and findings-resolution table.

## Current running/queued work

- Landscape sidebar capture still running/queued at last check: `/tmp/task-44.3-sidebar-capture-landscape.nohup.log` and `/tmp/task-44.3-sidebar-capture-20261015-171356/`.
- Other unrelated xbuild jobs were holding the shared lock; do not kill them.
