# Test evidence artifacts

Most UI evidence screenshots are attached to their XCTest result bundle automatically. Tests only write PNGs into the working tree or another directory when an explicit evidence directory is provided.

## Lesson figure screenshots

`CanadianHamLessonFiguresUITests` writes figure evidence PNGs only when `CANADIAN_HAM_FIGURE_EVIDENCE_DIR` is set to a non-empty directory path. Without the variable, the screenshots remain XCTest attachments and no files are written.

## Exam-tool screenshots

`CanadianHamExamToolsUITests/testCaptureCalculatorEvidenceScreenshots` writes calculator evidence PNGs only when `CANADIAN_HAM_EXAM_TOOLS_EVIDENCE_DIR` is set to a non-empty directory path. Without the variable, the screenshot-capture test is skipped and no files are written.

When passing either evidence path through an Xcode/xbuild UI-test runner environment, use the `TEST_RUNNER_` prefix form (for example, `TEST_RUNNER_CANADIAN_HAM_EXAM_TOOLS_EVIDENCE_DIR=/tmp/exam-tool-evidence`) so the value reaches the test runner process. Keep evidence paths outside the repository unless the task explicitly asks to refresh checked-in evidence.
