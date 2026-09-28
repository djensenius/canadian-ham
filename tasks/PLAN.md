# canadian-ham running plan

Status values: `todo`, `in progress`, `in review`, `done`, `blocked`, `blocked on owner input`.

Owner-type is `worker` unless a future task explicitly needs coordinator action. Each implementation task should be small enough for one worker branch and should be reviewed before integration.

## Phase summary

| Phase | Goal | Exit criteria | Status |
|---|---|---|---|
| P0 | Foundations | Monorepo skeleton, schemas, tooling, CI skeleton, and docs baseline exist. | todo |
| P1 | Question bank pipeline | Official 2025 Basic source is vendored and importer emits validated EN+FR JSON. | todo |
| P2 | Shared engine spec and fixtures | TypeScript and Swift fixture contracts define exam, quiz, scoring, and spaced repetition. | todo |
| P3 | Web MVP | Static web app supports lesson rendering, lesson quizzes, practice immediate/review-later modes, mock exam with reference sheet access, readiness guidance, local progress, export/import/reset, and offline PWA. | todo |
| P4 | Curriculum | Lesson outline covers all 100 subsections; first authored lessons and explanations are tracked by coverage. | todo |
| P5 | Apple app | SwiftUI iPhone/iPad/Mac app works fully offline with bundled lessons, quizzes, content, SwiftData progress, practice, mock exams, reference viewer, and no network code. | todo |
| P6 | Polish and release | Accessibility, French UI, privacy label, web deployment, content-update process, and release checklists are complete. | todo |
| Later | Deferred scope | Advanced, Morse trainer, watchOS, visionOS, and other deferred ideas are revisited only after v1. | todo |

## Task list

| ID | Phase | Status | Owner-type | Dependencies | Acceptance criteria |
|---|---|---|---|---|---|
| T-000 | P0 | in review | worker | none | Initial docs exist: `docs/requirements.md`, `docs/exam-facts.md`, `docs/architecture.md`, `docs/privacy.md`, `docs/content-licensing.md`, `tasks/PLAN.md`; AGENTS project notes filled; markdown links checked; branch committed. |
| T-001 | P0 | todo | worker | T-000 | Create monorepo directories `content/`, `apps/web/`, `apps/apple/`, `packages/`, `fixtures/`; add placeholder READMEs that explain ownership; do not add app code. |
| T-002 | P0 | todo | worker | T-001 | Add package manager choice and base tooling files for documentation/content scripts; include markdown/link check command; no web or Apple app implementation. |
| T-003 | P0 | todo | worker | T-001 | Define initial JSON Schemas for Question, Category, Subsection, Lesson front matter, Explanation, ExamAttempt, QuestionProgress, and EngineFixture. |
| T-004 | P0 | todo | worker | T-003 | Add schema validation tests using small synthetic fixtures; tests pass locally and in CI skeleton. |
| T-005 | P0 | todo | worker | T-002,T-004 | Add CI skeleton for markdown links, schema validation, content validation placeholder, and web/package tests placeholder. |
| T-006 | P0 | todo | worker | T-000 | Add documentation release checklist issue template or task checklist covering licensing, privacy, and source verification. |
| T-007 | P0 | blocked on owner input | owner/coordinator | none | Record the ISED permission reference number/date/scope in `docs/content-licensing.md`; do not commit private correspondence unless explicitly approved. |
| T-101 | P1 | todo | worker | T-001,T-007 | Vendor the official 2025-07-15 Basic question-bank TXT and PDF under `content/sources/ised/basic-2025-07-15/` after T-007 records the permission reference/date/scope; include checksum manifest for covered artifacts; for artifacts outside the recorded scope, commit only URL plus checksum metadata. |
| T-102 | P1 | todo | worker | T-003,T-101 | Implement importer parser for semicolon-delimited UTF-8 CRLF TXT; trim header names only; preserve field values verbatim; assert no quoting and no embedded newlines for the current source. |
| T-103 | P1 | todo | worker | T-102 | Add importer validation tests asserting 984 questions, 100 subsections, 11 fields, first/last IDs, 0 duplicate IDs, 0 missing French, category counts, and the privilege question-ID citations in `exam-facts.md` against imported correct answers. |
| T-104 | P1 | todo | worker | T-102 | Add position-dependent answer lint; fail on phrases requiring fixed answer letters or positions; document reviewed exceptions if any. |
| T-106 | P1 | todo | worker | T-102,T-103 | Add hand-maintained `content/categories.json` with eight English names, verified counts, and pending French names. |
| T-105 | P1 | todo | worker | T-102,T-103,T-104,T-106 | Emit normalized `basic-2025-07-15` JSON for questions, subsections, categories, and source manifest. |
| T-107 | P1 | todo | worker | T-105 | Add import reproducibility test comparing normalized output from source to committed/generated expected output. |
| T-201 | P2 | todo | worker | T-003 | Create shared fixture format for seeded RNG, question selection, answer shuffling, scoring, category breakdown, weak subsections, readiness aggregation, and Leitner updates. |
| T-202 | P2 | todo | worker | T-201 | Add deterministic exam-generation fixtures requiring exactly one question per subsection, category counts 25/9/21/6/13/13/8/5, specified RNG vector outputs, final question order, and choice permutations. |
| T-203 | P2 | todo | worker | T-201 | Add scoring fixtures for boundary scores 0, 69, 70, 79, 80, and 100, per-category breakdown, and unanswered mock questions counted incorrect with `selectedSourceIndex: null`. |
| T-204 | P2 | todo | worker | T-201 | Add Leitner fixtures for correct promotions, correct-before-due promotion, incorrect reset to box 0, fixed 86,400-second UTC due intervals, unseen virtual state for first answer only, explicit `now`, repeated session answers applied in order, and a new user with 0 progress records having due count 0. |
| T-208 | P2 | todo | worker | T-201 | Add readiness guidance fixtures for fewer than two exams, last-three aggregation, category-precedence checks, due-review precedence, pass-ready, honours-ready, needs-review states, and a new user with 0 progress records having due count 0 and `not-enough-data` readiness. |
| T-205 | P2 | todo | worker | T-202,T-203,T-204,T-208 | Implement TypeScript engine package that passes shared fixtures. |
| T-206 | P2 | todo | worker | T-202,T-203,T-204,T-208 | Implement Swift engine SwiftPM package under `packages/engine-swift/` and test target that passes shared fixtures using `xbuild`. |
| T-207 | P2 | todo | worker | T-205,T-206 | Add cross-platform fixture parity CI job or documented local command that runs both implementations. |
| T-301 | P3 | todo | worker | T-002,T-205 | Scaffold static web app using owner-confirmed stack; default is Vite + React + TypeScript unless changed. |
| T-302 | P3 | todo | worker | T-301,T-105 | Add web content loader for bundled normalized bank, lesson metadata, explanations, and manifest. |
| T-303 | P3 | todo | worker | T-302 | Implement IndexedDB progress store with export/import JSON and reset all data. |
| T-304 | P3 | todo | worker | T-303,T-205 | Implement practice by category/subsection/all with answer shuffling and immediate feedback; progress and Leitner state update through the progress store. |
| T-305 | P3 | todo | worker | T-304 | Implement web review-later practice mode with submit-time feedback and submit-time progress updates. |
| T-306 | P3 | todo | worker | T-304,T-208 | Implement weak-area and due-review practice using local progress, `recentResults`, and Leitner state. |
| T-307 | P3 | todo | worker | T-303,T-302,T-205 | Implement mock exam generation, review, scoring, pass/honours display, category breakdown, optional timer default off, unanswered-as-incorrect scoring, and progress updates. |
| T-308 | P3 | todo | worker | T-307,T-101 | Add reference sheet access in web mock exam mode when licensing permits bundling; label it as exam reference material and keep it available offline when cached. |
| T-309 | P3 | todo | worker | T-302 | Render available platform-neutral lessons on web with metadata, body content, previous/next navigation, and module overview. |
| T-310 | P3 | todo | worker | T-304,T-309 | Implement web built-in lesson quizzes with official-bank and concept-check items, shuffled official answers, local scores, and retry history. |
| T-311 | P3 | todo | worker | T-303,T-307,T-208 | Implement web readiness guidance for weak categories/subsections and due items using the shared readiness fixtures for REQ-LESSON-003. |
| T-312 | P3 | todo | worker | T-305,T-306,T-307,T-308,T-309,T-310,T-311 | Add PWA service worker caching app shell, bundled content, lessons, fixtures needed at runtime, and permitted reference assets; show offline readiness status. |
| T-313 | P3 | todo | worker | T-312 | Add web privacy audit test confirming no third-party requests in normal flows and document host log/CSP configuration. |
| T-401 | P4 | todo | worker | T-105 | Create lesson directory structure and module index for eight categories. |
| T-402 | P4 | todo | worker | T-401 | Add lesson outline front matter mapping all 100 subsections to lesson IDs; no full lesson prose required. |
| T-403 | P4 | todo | worker | T-402 | Implement coverage check script that fails on missing or unknown subsection IDs and reports duplicate coverage. |
| T-404 | P4 | todo | worker | T-402 | Author first `B-001` introductory lesson as original content with built-in quiz references. |
| T-405 | P4 | todo | worker | T-404 | Add original explanations for a small reviewed set of `B-001` questions; cite question IDs and verified sources. |
| T-406 | P4 | todo | worker | T-403,T-405 | Add explanation coverage report showing count covered out of 984 and blocking invalid question IDs. |
| T-407 | P4 | todo | worker | T-404 | Add reference-sheet teaching links in relevant lessons without copying unapproved diagrams. |
| T-501 | P5 | todo | worker | T-206 | Scaffold SwiftUI multiplatform Apple project for iOS, iPadOS, and macOS; verify build with `xbuild`. |
| T-502 | P5 | todo | worker | T-501,T-105,T-402,T-405 | Bundle normalized question bank, lesson metadata, explanations, manifest, and permitted reference assets in Apple app. |
| T-503 | P5 | todo | worker | T-502 | Implement SwiftData local progress models for QuestionProgress, ExamAttempt, lesson progress, and preferences. |
| T-504 | P5 | todo | worker | T-502,T-206,T-503 | Implement Apple practice flow with shuffled answers, immediate feedback, and review-later mode. |
| T-505 | P5 | todo | worker | T-502,T-206,T-503,T-507 | Implement Apple mock exam flow, scoring, review, category breakdown, optional timer default off, unanswered-as-incorrect scoring, progress updates, and mock-exam access to the T-507 reference viewer for REQ-EXAM-004. |
| T-506 | P5 | todo | worker | T-503 | Implement user-initiated progress export/import JSON and reset all data. |
| T-507 | P5 | todo | worker | T-502 | Implement offline reference sheet viewer for permitted bundled assets. |
| T-508 | P5 | todo | worker | T-506,T-507,T-504,T-505 | Add Apple no-network audit: source search, entitlement review, no third-party SDK check, and airplane-mode smoke test plan. |
| T-509 | P5 | todo | worker | T-502 | Render platform-neutral lessons in the Apple app with metadata, body content, previous/next navigation, and module overview. |
| T-510 | P5 | todo | worker | T-503,T-509,T-206 | Implement Apple built-in lesson quizzes with shuffled official-bank answers, local scores, and retry history. |
| T-511 | P5 | todo | worker | T-508,T-509,T-510,T-512 | Run Apple app tests/build through `xbuild`; record command and result in task review notes. |
| T-512 | P5 | todo | worker | T-503,T-206,T-208 | Implement Apple weak-area and due-review practice scopes plus readiness guidance using local SwiftData progress and shared readiness fixtures; exclude unseen questions from due scope/count; show `not-enough-data` for a new user with fewer than two exams. |
| T-601 | P6 | todo | worker | T-313,T-511 | Run accessibility audit for web and Apple; fix labels, keyboard/VoiceOver navigation, dynamic text, contrast, and non-colour indicators. |
| T-602 | P6 | todo | worker | T-302,T-502 | Add French UI infrastructure and translate original UI copy; use official ISED French question text only. |
| T-603 | P6 | todo | worker | T-313,T-508 | Prepare App Store privacy label evidence for Data Not Collected and web privacy summary. |
| T-604 | P6 | todo | worker | T-312 | Add static web deployment configuration and post-deploy offline smoke test checklist. |
| T-605 | P6 | todo | worker | T-101,T-103,T-105 | Document and test content-update process for future ISED bank updates using checksum and validation, not file dates. |
| T-606 | P6 | todo | worker | T-309,T-405,T-603 | Complete release about pages with attribution, disclaimer, source manifest, privacy summary, and active bank version. |
| T-607 | P6 | todo | worker | T-601,T-603,T-604,T-606,T-602,T-605,T-207,T-406,T-107,T-104,T-005 | Release candidate pass: all tests, link checks, privacy checks, accessibility checks, and licensing checklist pass. |
| T-701 | Later | todo | worker | v1 release | Investigate Advanced qualification course as separate scope; do not mix with Basic bank pipeline unless approved. |
| T-702 | Later | todo | worker | v1 release | Investigate Morse 5 wpm trainer as separate module. |
| T-703 | Later | todo | worker | v1 release | Investigate watchOS companion only after Apple v1 privacy posture is stable. |
| T-704 | Later | todo | worker | v1 release | Investigate visionOS only after core apps ship. |
| T-705 | Later | todo | worker | v1 release | Revisit optional iCloud sync as a privacy-review item, not as a default feature. |

## Current branch review checklist for T-000

- [ ] New docs are concrete and cross-linked.
- [ ] Exam facts use only verified facts supplied by coordinator.
- [ ] Requirements include stable IDs and testable acceptance criteria.
- [ ] Architecture includes schemas, engine algorithm, fixtures, and CI outline.
- [ ] Privacy doc supports Apple Data Not Collected rationale.
- [ ] Content licensing doc records granted-permission assumption and remaining record placeholders.
- [ ] AGENTS project notes include 3-6 short bullets.
- [ ] Relative links resolve.
- [ ] Changes are committed on `docs/initial-plan`.

## Open planning questions

- Owner confirmation: Vite + React + TypeScript versus Astro for web.
- Official French category names.
- French 2025 Basic reference material location.
- Official Basic exam time limit.
- ISED permission reference number/date/scope.
- Minimum supported Apple OS and browser versions.
