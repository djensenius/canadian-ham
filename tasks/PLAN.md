# canadian-ham running plan

Status values: `todo`, `in progress`, `in review`, `done`, `blocked`, `blocked on owner input`, `merged`.

Owner-type is `worker` unless a future task explicitly needs coordinator action. Each implementation task should be small enough for one worker branch and should be reviewed before integration.

## Phase summary

| Phase | Goal | Exit criteria | Status |
|---|---|---|---|
| P0 | Foundations | Monorepo skeleton, decisions, docs baseline, base tooling (T-002), and release checklist (T-006) exist; owner-blocked publication gate T-007 is tracked in P6 and excluded from P0 exit criteria. | in progress |
| P1 | Question bank pipeline | Official 2025 Basic source is vendored; importer emits validated EN+FR JSON; schemas and CI skeleton exist. | in progress |
| P2 | Shared engine spec and fixtures | TypeScript and Swift fixture contracts define exam, quiz, scoring, and spaced repetition. | in progress |
| P3 | Web MVP | Static web app supports lesson rendering, lesson quizzes, practice immediate/review-later modes, mock exam with reference sheet access, readiness guidance, local progress, export/import/reset, and offline PWA. | in progress |
| P4 | Curriculum | Lesson outline covers all 100 subsections; first authored lessons and explanations are tracked by coverage. | in progress |
| P5 | Apple app | SwiftUI iPhone/iPad/Mac/Vision Pro/Apple TV app works fully offline with bundled lessons, quizzes, content, SwiftData progress, practice, mock exams, reference viewer, and no network code. | in progress |
| P6 | Polish and release | Accessibility, French UI, privacy label, web deployment, content-update process, and release checklists are complete. | todo |
| Later | Deferred scope | Advanced, Morse trainer, watchOS, and other deferred ideas are revisited only after v1. | todo |

## Task list

| ID | Phase | Status | Owner-type | Dependencies | Acceptance criteria |
|---|---|---|---|---|---|
| T-000 | P0 | done | worker | none | Initial docs exist: `docs/requirements.md`, `docs/exam-facts.md`, `docs/architecture.md`, `docs/privacy.md`, `docs/content-licensing.md`, `tasks/PLAN.md`; AGENTS project notes filled; markdown links checked; branch committed. |
| T-001 | P0 | done | worker | T-000 | Create monorepo directories from `docs/architecture.md`; add placeholder READMEs explaining ownership and exclusions; add root README, `.gitignore`, `.editorconfig`, and `.gitattributes`; do not add app code. |
| T-011 | P0 | done | worker | T-001 | Design system: docs/design.md (ink-brush-on-cream identity matching the owner's app family; light/dark; web, iOS, macOS, visionOS, tvOS guidance; component specs; wireframes), packages/design-tokens with generated CSS + Swift tokens and an automated WCAG contrast test for every declared pair; layered app-icon artwork and exports for iOS/macOS, visionOS (3 layers), tvOS (image stack + Top Shelf), and web. |
| T-012 | P0 | done | worker | T-001 | Accessibility spec (docs/accessibility.md): WCAG 2.2 AA + Apple HIG Definition of Done for every UI task; automated checks (axe-core in web tests; XCUITest performAccessibilityAudit + largest Dynamic Type run on Apple). |
| T-102c | P1 | done | worker | T-102 | Integration fix: lesson checker typecheck, content-tools tsconfig, lang placement on FR text only, bare-fence rule, Vitest 4.1.11 (Dependabot). |
| T-011b | P0 | blocked on owner input | owner/coordinator | T-011 | Final app-icon artwork approval: owner reviews the generated ink-brush icon (reviewer score 5/10: too clean vs the family style) or supplies hand-drawn SVG; render.swift regenerates all layers/sizes. |
| T-101 | P1 | done | worker | T-001 | Commit the official 2025-07-15 Basic question-bank TXT, question-bank PDF, and English reference PDFs verbatim under `content/sources/ised/basic-2025-07-15/` under the private-repo policy; include a checksum manifest using SHA-256 values recorded in `docs/exam-facts.md`. |
| T-102 | P1 | done | worker | T-001,T-101 | Importer: parse, validate, lint, categories, emit normalized JSON. Implement the TypeScript importer using Node type stripping, `node:test`, and zero runtime dependencies; parse semicolon-delimited UTF-8 CRLF TXT; trim header names only and preserve field values verbatim; assert the current source has no quoting and no embedded newlines; checksum mismatch against the committed `content/sources/ised/basic-2025-07-15/manifest.json` fails. Tests assert 984 questions, 100 subsections, 11 fields, first/last IDs, 0 duplicate IDs, 0 missing French, category counts, and the privilege question-ID citations in `docs/exam-facts.md` checked against imported correct answers. The lint fails on phrases requiring fixed answer letters/positions; reviewed exceptions are documented. Add hand-maintained `content/categories.json` with eight English names, verified counts, and pending French names. Emit committed questions, subsections, categories, and the source manifest to `content/generated/basic-2025-07-15/`. |
| T-102b | P1 | done | worker | T-102 | Importer hardening from T-102 review: make the CLI independent of caller cwd, reject CSV quote wrappers and doubled-quote escapes while preserving literal wording quotes, tighten EN/FR answer-position lint false positives, add failure-path tests for parsing/checksum/check-mode/import validation, update source manifest encoding/line-ending metadata, and pin generated JSON LF line endings. |
| T-103 | P1 | merged | worker | T-102 | Merged into T-102; row retained for stable ID. |
| T-104 | P1 | merged | worker | T-102 | Merged into T-102; row retained for stable ID. |
| T-105 | P1 | merged | worker | T-102 | Merged into T-102; row retained for stable ID. |
| T-106 | P1 | merged | worker | T-102 | Merged into T-102; row retained for stable ID. |
| T-002 | P0 | done | worker | T-001 | Add pnpm workspace and base tooling files for documentation/content scripts; include markdown/link check command; no web or Apple app implementation. |
| T-003 | P1 | todo | worker | T-102 | Define initial JSON Schemas for Question, Category, Subsection, Lesson front matter, Explanation, ExamAttempt, QuestionProgress, and EngineFixture from the reviewed generated output shape. |
| T-004 | P1 | todo | worker | T-003 | Add schema validation tests using small synthetic fixtures; tests pass locally and in CI skeleton. |
| T-005 | P1 | todo | worker | T-002,T-004 | Add CI skeleton for markdown links, schema validation, content validation placeholder, and web/package tests placeholder. |
| T-006 | P0 | todo | worker | T-000 | Add documentation release checklist issue template or task checklist covering licensing, privacy, and source verification. |
| T-007 | P6 | blocked on owner input | owner/coordinator | none | Record the ISED permission reference number/date/scope in `docs/content-licensing.md`; confirm the scope covers bundling verbatim question text as app data and bundling the reference PDFs; publication and distribution remain blocked until this is complete; do not commit private correspondence unless explicitly approved. |
| T-008 | P0 | done | worker | T-000 | Document the private-repository interim licensing policy, public-release gate, and leftover review dependency corrections; commit documentation-only changes on `docs/t008-private-repo-policy`. |
| T-107 | P1 | todo | worker | T-102 | Add import reproducibility test comparing normalized output from source to committed/generated expected output. |
| T-201 | P2 | done | worker | T-003 | Create shared fixture format for seeded RNG, question selection, answer shuffling, scoring, category breakdown, weak subsections, readiness aggregation, and Leitner updates. |
| T-202 | P2 | done | worker | T-201 | Add deterministic exam-generation fixtures requiring exactly one question per subsection, category counts 25/9/21/6/13/13/8/5, specified RNG vector outputs, final question order, and choice permutations. |
| T-203 | P2 | done | worker | T-201 | Add scoring fixtures for boundary scores 0, 69, 70, 79, 80, and 100, per-category breakdown, and unanswered mock questions counted incorrect with `selectedSourceIndex: null`. |
| T-204 | P2 | done | worker | T-201 | Add Leitner fixtures for correct promotions, correct-before-due promotion, incorrect reset to box 0, fixed 86,400-second UTC due intervals, unseen virtual state for first answer only, explicit `now`, repeated session answers applied in order, and a new user with 0 progress records having due count 0. |
| T-208 | P2 | done | worker | T-201 | Add readiness guidance fixtures for fewer than two exams, last-three aggregation, category-precedence checks, due-review precedence, pass-ready, honours-ready, needs-review states, and a new user with 0 progress records having due count 0 and `not-enough-data` readiness. |
| T-205 | P2 | done | worker | T-202,T-203,T-204,T-208 | Implement TypeScript engine package that passes shared fixtures. |
| T-206 | P2 | done | worker | T-202,T-203,T-204,T-208 | Implement Swift engine SwiftPM package under `packages/engine-swift/` and test target that passes shared fixtures using `xbuild`. |
| T-206b | P2 | done | worker | T-206 | Swift engine hardening: no crash on bad saved box, strict JSON deep-equality fixture runner, timestamp edge tests, UTF-8 ordinal parity in TS and Swift, engine-ts typecheck. Follow-up: align TS applyAnswer box-range validation with Swift; fix the non-ASCII-digit test to reach the digit check. |
| T-207 | P2 | todo | worker | T-205,T-206 | Add cross-platform fixture parity CI job or documented local command that runs both implementations. |
| T-301 | P3 | done | worker | T-002,T-205 | Scaffold static web app using Vite + React + TypeScript. |
| T-301b | P3 | done | worker | T-301 | Web slice polish from review: check-links anchors/code fences/footnotes/slugs, focus management, lang attribute, stronger render test, pnpm settings, dist URL audit script. |
| T-314 | P3 | done | worker | T-301b,T-011,T-012,T-205 | Apply design tokens and design.md components to the web app; switch web practice to @canadian-ham/engine-ts; add axe-core checks to component tests; bump vitest to >= 4.1.11 (Dependabot); wire favicon/touch icons. |
| T-302 | P3 | todo | worker | T-301,T-102 | Add web content loader for bundled generated bank, lesson metadata, explanations, and manifest. |
| T-303 | P3 | done | worker | T-302 | Implement IndexedDB progress store with export/import JSON and reset all data. |
| T-304 | P3 | done | worker | T-303,T-205 | Implement practice by category/subsection/all with answer shuffling and immediate feedback; progress and Leitner state update through the progress store. |
| T-305 | P3 | done | worker | T-304 | Implement web review-later practice mode with submit-time feedback and submit-time progress updates. |
| T-306 | P3 | done | worker | T-304,T-208 | Implement weak-area and due-review practice using local progress, `recentResults`, and Leitner state. |
| T-307 | P3 | done | worker | T-303,T-302,T-205 | Implement mock exam generation, review, scoring, pass/honours display, category breakdown, optional timer default off, unanswered-as-incorrect scoring, and progress updates. |
| T-308 | P3 | done | worker | T-307,T-101 | Add reference sheet access in web mock exam mode with reference assets bundled for private development; label it as exam reference material, keep it available offline when cached, and keep public release gated by T-007. |
| T-309 | P3 | done | worker | T-302 | Render available platform-neutral lessons on web with metadata, body content, previous/next navigation, and module overview. |
| T-310 | P3 | done | worker | T-304,T-309 | Implement web built-in lesson quizzes with official-bank and concept-check items, shuffled official answers, local scores, and retry history. |
| T-311 | P3 | done | worker | T-303,T-307,T-208 | Implement web readiness guidance for weak categories/subsections and due items using the shared readiness fixtures for REQ-LESSON-003. |
| T-312 | P3 | done | worker | T-305,T-306,T-307,T-308,T-309,T-310,T-311 | Add PWA service worker caching app shell, bundled content, lessons, fixtures needed at runtime, and reference assets allowed for the current private-development or release stage; show offline readiness status. |
| T-313 | P3 | todo | worker | T-312 | Add web privacy audit test confirming no third-party requests in normal flows and document host log/CSP configuration. |
| T-401 | P4 | done | worker | T-102 | Create lesson directory structure and module index for eight categories. |
| T-402 | P4 | done | worker | T-401 | Add lesson outline front matter mapping all 100 subsections to lesson IDs; no full lesson prose required. |
| T-403 | P4 | done | worker | T-402 | Implement coverage check script that fails on missing or unknown subsection IDs and reports duplicate coverage. |
| T-404 | P4 | done | worker | T-402 | Author first `B-001` introductory lesson as original content with built-in quiz references. |
| T-405 | P4 | done | worker | T-404 | Add original explanations for a small reviewed set of `B-001` questions; cite question IDs and verified sources. |
| T-406 | P4 | todo | worker | T-403,T-405 | Add explanation coverage report showing count covered out of 984 and blocking invalid question IDs. |
| T-407 | P4 | todo | worker | T-404 | Add reference-sheet teaching links in relevant lessons without copying unapproved diagrams. |
| T-408 | P4 | done | worker | T-404 | Module 4 (Circuit Components, B-004) full lessons, quiz files, and explanations for every B-004 question, following the M5 conventions and checks. |
| T-409 | P4 | done | worker | T-404 | Module 6 (Feedlines and Antenna Systems, B-006) full lessons, quiz files, and explanations for every B-006 question, following the M5 conventions and checks. |
| T-410 | P4 | done | worker | T-404 | Content lints: module-scoped check:quizzes and check-explanations (quoted choice text, no filler, no 3+ file duplicate notes, lesson citation covers subsection). |
| T-411 | P4 | done | worker | T-410 | Template and concept-check overlap lints; stricter explanation format. |
| T-501 | P5 | done | worker | T-206 | Scaffold SwiftUI multiplatform Apple project for iOS, iPadOS, and macOS; verify build with `xbuild`. |
| T-501b | P5 | in progress | worker | T-501 | Apple slice polish from review: EN/FR picker on compact iPhone, UI test, strong shuffle test, VoiceOver announcement, scaled answer letter, no visionOS availability, deterministic project generation, minimum-OS decision recorded. |
| T-513 | P5 | todo | worker | T-501b,T-206 | Native visionOS app target (visionOS 2.0+): window-based practice flow, glass materials, hover effects, ornaments for EN/FR; shared SwiftUI code where sensible; builds/tests via xbuild on the visionOS simulator. |
| T-514 | P5 | todo | worker | T-501b,T-206 | Native tvOS app target (tvOS 18.0+): focus-engine practice flow with 10-foot typography and overscan-safe layout; builds/tests via xbuild on an Apple TV simulator. |
| T-515 | P5 | todo | worker | T-011,T-513,T-514 | Wire app icons into all targets: iOS/macOS icon (Icon Composer bundle if validated), visionOS 3-layer solid image stack, tvOS layered App Icon + Top Shelf/Top Shelf Wide brand assets. |
| T-516 | P5 | in progress | worker | T-011,T-012,T-206,T-501b | Apply design tokens to Apple UI; replace TempShuffle with CanadianHamEngine; performAccessibilityAudit on every screen for each platform. |
| T-502 | P5 | todo | worker | T-501,T-102,T-402,T-405 | Bundle generated question bank, lesson metadata, explanations, manifest, and reference assets for private development in the Apple app; public release remains gated by T-007. |
| T-503 | P5 | todo | worker | T-502 | Implement SwiftData local progress models for QuestionProgress, ExamAttempt, lesson progress, and preferences. |
| T-504 | P5 | todo | worker | T-502,T-206,T-503 | Implement Apple practice flow with shuffled answers, immediate feedback, and review-later mode. |
| T-505 | P5 | todo | worker | T-502,T-206,T-503,T-507 | Implement Apple mock exam flow, scoring, review, category breakdown, optional timer default off, unanswered-as-incorrect scoring, progress updates, and mock-exam access to the T-507 reference viewer for REQ-EXAM-004. |
| T-506 | P5 | todo | worker | T-503 | Implement user-initiated progress export/import JSON and reset all data. |
| T-507 | P5 | todo | worker | T-502 | Implement offline reference sheet viewer for reference assets bundled for private development; public release remains gated by T-007. |
| T-508 | P5 | todo | worker | T-506,T-507,T-504,T-505,T-509,T-510,T-512 | Add Apple no-network audit: source search, entitlement review, no third-party SDK check, and airplane-mode smoke test plan. |
| T-509 | P5 | todo | worker | T-502 | Render platform-neutral lessons in the Apple app with metadata, body content, previous/next navigation, and module overview. |
| T-510 | P5 | todo | worker | T-503,T-509,T-206 | Implement Apple built-in lesson quizzes with shuffled official-bank answers, local scores, and retry history. |
| T-511 | P5 | todo | worker | T-508,T-509,T-510,T-512 | Run Apple app tests/build through `xbuild`; record command and result in task review notes. |
| T-512 | P5 | todo | worker | T-503,T-206,T-208,T-504,T-505 | Implement Apple weak-area and due-review practice scopes plus readiness guidance using local SwiftData progress and shared readiness fixtures; exclude unseen questions from due scope/count; show `not-enough-data` for a new user with fewer than two exams. |
| T-601 | P6 | todo | worker | T-313,T-511 | Run accessibility audit for web and Apple; fix labels, keyboard/VoiceOver navigation, dynamic text, contrast, and non-colour indicators. |
| T-602 | P6 | todo | worker | T-302,T-502 | Add French UI infrastructure and translate original UI copy; use official ISED French question text only. |
| T-603 | P6 | todo | worker | T-313,T-508,T-007 | Prepare App Store privacy label evidence for Data Not Collected and web privacy summary. |
| T-604 | P6 | todo | worker | T-312,T-007 | Add static web deployment configuration and post-deploy offline smoke test checklist. |
| T-605 | P6 | todo | worker | T-101,T-102 | Document and test content-update process for future ISED bank updates using checksum and validation, not file dates. |
| T-606 | P6 | todo | worker | T-309,T-405,T-603 | Complete release about pages with attribution, disclaimer, source manifest, privacy summary, and active bank version. |
| T-607 | P6 | todo | worker | T-601,T-603,T-604,T-606,T-602,T-605,T-207,T-406,T-107,T-102,T-005,T-006,T-007 | Release candidate pass: all tests, link checks, privacy checks, accessibility checks, and licensing checklist pass. |
| T-009 | P6 | todo | owner/coordinator | T-007,T-607 | Make repository public only after permission is recorded, the public-release gate checklist is complete, and history contains no ISED artifacts outside the recorded scope. |
| T-701 | Later | todo | worker | v1 release | Investigate Advanced qualification course as separate scope; do not mix with Basic bank pipeline unless approved. |
| T-702 | Later | todo | worker | v1 release | Investigate Morse 5 wpm trainer as separate module. |
| T-703 | Later | todo | worker | v1 release | Investigate watchOS companion only after Apple v1 privacy posture is stable. |
| T-705 | Later | todo | worker | v1 release | Revisit optional iCloud sync as a privacy-review item, not as a default feature. |

## Current branch review checklist for T-001

- [ ] Skeleton directories and READMEs follow `docs/architecture.md`.
- [ ] Root README includes project summary, private-repository notice, layout map, doc links, and `xbuild` rule.
- [ ] `.gitignore`, `.editorconfig`, and `.gitattributes` are present; versioned source artifacts remain binary/no text normalization while source READMEs remain text/readable.
- [ ] Owner-confirmed web/importer/tooling decisions are recorded in requirements and architecture docs.
- [ ] T-008 review notes are reflected in licensing, privacy, exam facts, architecture, and AGENTS docs.
- [ ] PLAN statuses and dependencies are acyclic, and no task depends on a merged task.
- [ ] Relative links resolve.
- [ ] Changes are committed on `chore/t001-monorepo-skeleton`.

## Open planning questions

- Official French category names.
- French 2025 Basic reference material location.
- Official Basic exam time limit.
- ISED permission status: requested scope drafted, pending; not yet sent or granted as of the 2026-09-28 owner decision. T-007 must record reference number/date/scope and app-data/reference-PDF bundling coverage before public release.
- Minimum supported Apple OS and browser versions.
