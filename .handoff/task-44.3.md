# task-44.3 review-fix handoff

Branch: `task-44.3-apple-exam-tools`

Review source: `/Users/david/.cache/canadian-ham-reviews/r443-4.md`.

Current review-fix status:
- Started from `d6db28419e98e85a167bf806c7300dcb90783e36`.
- High-group work in progress: restoring `auditIgnoringOccludedLessonTextContrast` in `CanadianHamPracticeUITests.swift` byte-identical to `origin/main`; deleting the broader exam-tools multi-scroll occluded filter; exam-tool large/largest/iPad inspector audits now call `auditIgnoringOccludedLessonTextContrast`; local ExamTools scroll helpers are renamed to avoid shadowing shared helper names.

Remaining requested work after the high helper group:
- Capture real origin/main vs branch iPad sidebar header screenshots and verify the PNGs show the app.
- Update audit inventory docs.
- Add dark runs for large-detent, largest Dynamic Type and iPad inspector audits.
- Match web keyboard mapping and calculator interface-locale behavior; add unit/UI coverage.
- Restore exact sidebar column visibility and update iPad tests.
- Delete this task's old `docs/evidence/task-44.3/resume-handoff.md` process note.
- Add new mock reset and app-level typeKey auto-focus UI tests.
- Check iPhone empty band/back-button evidence.
- Rebuild `Localizable.xcstrings` deterministically from origin/main order plus new keys.
- Run only affected tests with `xbuild` via nohup chains and no direct `xcodebuild`.
