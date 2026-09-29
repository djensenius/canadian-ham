# Product requirements: canadian-ham

`canadian-ham` is a learning system for the Canadian Amateur Radio Operator Certificate, Basic Qualification. The target learning outcome is Basic with Honours, meaning at least 80% on the Basic exam. The system includes full lessons with built-in quizzes, question-bank practice, and mock exams.

The product ships as:

1. An interactive static web app.
2. A native offline Apple app built with SwiftUI for iPhone, iPad, and Mac.

The Apple app must work fully offline and collect no data. The web app must also avoid accounts, analytics, third-party requests, and server-side storage.

Authoritative exam and bank facts live in [exam-facts.md](exam-facts.md). Architecture details live in [architecture.md](architecture.md). Privacy rules live in [privacy.md](privacy.md). Licensing rules live in [content-licensing.md](content-licensing.md).

## Goals

- Teach a beginner enough radio, regulations, station practice, and safety to confidently target Basic with Honours.
- Cover the full 2025 Basic question bank effective 2025-07-15, in English and French source text.
- Provide practice by category, subsection, weak area, and whole-bank review.
- Provide realistic mock exams: 100 questions, one question per subsection, shuffled questions and answers, pass and honours scoring.
- Provide short built-in quizzes inside lessons so learning and practice reinforce each other.
- Work without user accounts.
- Keep progress local to the device or browser, with user-controlled export, import, and reset.
- Keep content platform-neutral so the web and Apple apps use the same lesson, question, explanation, schema, and fixture data.
- Make cross-platform behaviour testable through shared JSON fixtures.

## Non-goals for v1

- No Advanced qualification course.
- No Morse trainer.
- No watchOS, visionOS, or tvOS app.
- No social features, leaderboards, comments, or instructor dashboards.
- No paid account system or remote sync.
- No server-rendered dynamic application backend.
- No collection of telemetry, diagnostics, advertising identifiers, or personal data.
- No rewording of official ISED question text.
- No copying RAC, Coax Publications, or other third-party study-guide prose.

## Personas

### P-OWNER: Owner-learner

The primary persona is the owner: a beginner studying for the Canadian Basic Qualification with a target of Basic with Honours. They want plain-language explanations, enough practice to identify weak areas, and confidence before scheduling an exam.

Needs:

- Clear lessons that build from first principles.
- Honest readiness indicators for pass and honours thresholds.
- Offline study on Apple devices.
- No tracking or account setup.
- Ability to reset and re-study.

### P-CANDIDATE: Other Canadian candidates

The secondary persona is any Canadian candidate studying for the same 2025 Basic question bank.

Needs:

- Accessible, bilingual-ready material.
- Practice by official categories and subsections.
- Mock exams that match the verified exam structure.
- Transparent attribution and disclaimer so they know this is not a government service.

## Decisions already made

| ID | Decision | Rationale |
|---|---|---|
| DEC-REPO-001 | Use a single monorepo for now with `content/`, `apps/web/`, `apps/apple/`, `packages/engine-ts/`, `packages/engine-swift/`, `packages/schemas/`, `fixtures/`, `docs/`, and `tasks/`. Split only if real pain appears. | Solo developer, schema churn, atomic cross-platform changes, and the AGENTS.md worktree/review workflow. |
| DEC-CONTENT-001 | Course content is platform-neutral Markdown plus JSON. | Keeps lesson and bank content reusable across web and Apple apps. |
| DEC-ENGINE-001 | Implement the quiz and exam engine natively twice: TypeScript for web and Swift for Apple. Both must pass the same JSON fixtures in `fixtures/`. | Avoids cross-language runtime dependencies while preserving behavioural consistency. |
| DEC-BANK-001 | Use only the 2025 Basic question bank effective 2025-07-15. | Prevents user confusion and fixture ambiguity. |
| DEC-WEB-001 | The web app is fully static: no server, no accounts, no analytics, no third-party requests, and self-hosted fonts/assets. | Supports privacy, low hosting cost, and offline PWA. |
| DEC-WEB-002 | Use Vite + React + TypeScript for the static web app, with pnpm as the package manager. | Owner confirmed this stack on 2026-09-28; it is straightforward for interactive quizzes and the planned offline PWA. |
| DEC-TOOLING-001 | Run importer and content tooling as TypeScript directly in Node using Node >= 23.6 type stripping; use `node:test`; keep the importer at zero runtime dependencies. | Owner confirmed this on 2026-09-28; the development machine has Node 26, and the importer should stay small and reproducible. |
| DEC-APPLE-001 | Apple app is SwiftUI multiplatform for iOS, iPadOS, and macOS first. | Native offline UX, shared SwiftUI code, and no watchOS/visionOS/tvOS scope. |
| DEC-APPLE-002 | Use SwiftData for local progress. | Native local persistence with no remote service. |
| DEC-APPLE-003 | No third-party SDKs, no networking code, and no iCloud sync in v1. | Minimizes privacy risk and supports App Store Data Not Collected. iCloud sync may be reconsidered later only with a privacy review. |
| DEC-APPLE-004 | Minimum Apple OS versions are iOS/iPadOS 18.0 and macOS 15.0. | Matches the first SwiftUI multiplatform Apple slice and keeps the initial offline app focused on currently supported Apple platforms. |
| DEC-BILINGUAL-001 | Schema stores English and French from day one. UI ships English first; French UI comes in P6 using official ISED French question text. | Avoids schema migration later and prevents unofficial translations of ISED questions. |
| DEC-BUILD-001 | Builds and tests use `xbuild`; never call `xcodebuild` directly. | Required by AGENTS.md to serialize builds and clean up simulators. |

## Functional requirements

Each requirement has acceptance criteria that can be tested manually, with unit tests, or with fixture tests.

### Content and curriculum

#### REQ-CONTENT-001: Official bank ingestion

The system shall ingest only the 2025 Basic delimited question bank described in [exam-facts.md](exam-facts.md).

Acceptance criteria:

- Importer accepts UTF-8 without BOM, CRLF line endings, semicolon separator, one header row, and 11 fields.
- Importer trims header names, including the trailing space in `question_id `, but does not trim field values.
- Importer asserts the current source format has no quoted fields and no embedded newlines.
- Validation asserts 984 questions, 100 subsections, no duplicate IDs, no missing French, first ID `B-001-001-001`, and last ID `B-008-005-011`.
- Validation asserts the eight category totals from [exam-facts.md](exam-facts.md).
- Any source checksum mismatch fails the import. New bank versions must follow the re-verification procedure in [exam-facts.md](exam-facts.md) before being accepted.

#### REQ-CONTENT-002: Verbatim ISED question text

The system shall preserve ISED question and answer text verbatim in English and French.

Acceptance criteria:

- Normalized JSON stores source field values exactly as imported; header names may be trimmed, but question and answer field values are not trimmed or rewritten.
- Review tooling can compare normalized text back to imported source records.
- No lesson or UI pipeline rewrites ISED question or answer text.
- The app can display the official French question text even before French UI is complete.

#### REQ-CONTENT-003: Category and subsection metadata

The system shall store hand-maintained category metadata and derived subsection metadata.

Acceptance criteria:

- Category metadata includes the eight English names and counts from [exam-facts.md](exam-facts.md).
- French category names are empty or marked pending until verified.
- Subsections are derived from question IDs and linked to lesson coverage.
- Build validation fails if any expected subsection is missing from content coverage or if lesson coverage names an unknown subsection ID.

#### REQ-CONTENT-004: Lesson curriculum coverage

The system shall define a lesson outline that maps all 100 subsections to at least one lesson.

Acceptance criteria:

- Lesson front matter declares covered subsection IDs.
- A coverage script fails if any of the 100 subsections has zero lesson mappings or if a lesson references an unknown subsection ID.
- A coverage report lists subsections covered by more than one lesson for review.
- Curriculum modules map to the eight official categories.

#### REQ-CONTENT-005: Original explanations

The system shall support original explanations for questions and lesson quiz answers.

Acceptance criteria:

- Explanations are stored separately from ISED question-bank records.
- Explanation records cite the relevant question IDs and, where needed, RBR-4 or reference-sheet context.
- Coverage tooling reports how many of 984 questions have explanations.
- No explanation copies RAC, Coax, or other third-party study-guide text.

#### REQ-CONTENT-006: Reference sheet support

The system shall include the official English reference material as study material and exam-context material subject to licensing rules.

Acceptance criteria:

- Content metadata distinguishes the labelled training version from the unlabelled exam version.
- Lessons can link to relevant formulas or block diagrams without requiring figure-based questions.
- French reference material remains an open-question placeholder until located.
- Private-development bundling follows the [interim private-development policy](content-licensing.md#interim-private-development-policy); public release follows the [public-release gate](content-licensing.md#public-release-gate).

### Lesson experience

#### REQ-LESSON-001: Structured lessons

The system shall render lessons from platform-neutral Markdown and JSON front matter.

Acceptance criteria:

- A lesson has stable ID, title, language, module, covered subsections, prerequisites, estimated minutes, and quiz references.
- Web and Apple apps can render the same lesson body and metadata.
- Lesson navigation supports previous, next, and module overview.

#### REQ-LESSON-002: Built-in lesson quizzes

Lessons shall include short quizzes tied to lesson concepts and official subsections.

Acceptance criteria:

- A lesson quiz can include official bank questions and original concept-check questions.
- Official bank questions in quizzes use shuffled answer order.
- Quiz completion records local score and incorrect concepts.
- Users can retry a lesson quiz without erasing historical attempts unless they choose reset.

#### REQ-LESSON-003: Readiness guidance

Lessons shall show practice recommendations based on weak categories, weak subsections, and spaced-repetition due items.

Acceptance criteria:

- After practice or mock exams, the app can list the weakest subsections by recent correctness.
- Recommendations are local-only and deterministic from stored progress.
- Readiness aggregation uses the fixture-testable precedence in [architecture.md](architecture.md): fewer than two completed mock exams returns `not-enough-data`; category weakness or due reviews from stored progress records returns `needs-review`; otherwise two of the last three exams determine `honours-ready` or `pass-ready`.
- Readiness copy distinguishes passing readiness from Basic with Honours readiness.

### Practice and quiz engine

#### REQ-QUIZ-001: Practice by category and subsection

The system shall allow practice sessions scoped to category, subsection, weak area, due review, or all questions.

Acceptance criteria:

- Category practice draws only from selected category IDs.
- Subsection practice draws only from selected subsection IDs.
- Weak-area practice draws from locally computed weak subsections.
- Due-review practice draws only from stored progress records whose Leitner `dueAt <= now`; unseen questions with no stored progress record are not due.

#### REQ-QUIZ-002: Answer shuffling

All official bank question presentations shall shuffle answer choices.

Acceptance criteria:

- Correct answer is not always displayed first.
- The engine records the displayed answer permutation for review screens.
- Shared fixtures prove deterministic shuffling with seeded RNG.
- Import lints fail on newly found position-dependent answer phrases until reviewed.

#### REQ-QUIZ-003: Immediate feedback mode

Practice sessions shall support immediate feedback after each answer.

Acceptance criteria:

- Feedback identifies correct and selected answers.
- Feedback can show original explanation content when available.
- Feedback updates local progress and spaced-repetition state.
- Users can continue without network access.

#### REQ-QUIZ-004: Review later mode

Practice sessions shall support answering all questions before feedback.

Acceptance criteria:

- User can complete a session without seeing correctness until review.
- Review screen shows each question, selected answer, correct answer, explanation, category, and subsection.
- Progress is committed once the session is submitted.

#### REQ-QUIZ-005: Progress model

The system shall store per-question and per-subsection progress locally.

Acceptance criteria:

- Progress includes attempts, correct attempts, last attempted timestamp, last result, Leitner box, due date, and `recentResults`; `recentResults` keeps at most five booleans, ordered oldest to newest.
- Progress can be exported to JSON and imported on another device/browser by user action.
- Reset all data deletes local progress and preferences.

### Mock exams

#### REQ-EXAM-001: Exam generation

The system shall generate a 100-question mock exam matching verified Basic rules.

Acceptance criteria:

- Each mock exam contains exactly one question from each of 100 subsections.
- Per-category counts are 25, 9, 21, 6, 13, 13, 8, and 5.
- Question order is shuffled.
- Answer choices are shuffled.
- A seeded fixture produces identical exam output in TypeScript and Swift.

#### REQ-EXAM-002: Exam scoring

Mock exam scoring shall report raw score, pass status, honours status, category breakdown, and weak subsections.

Acceptance criteria:

- `score >= 70` is pass.
- `score >= 80` is Basic with Honours.
- Category breakdown shows correct/total and percent for each category.
- Weak subsections include wrong and unanswered answers; unanswered mock-exam questions are stored with `selectedSourceIndex: null` and count as incorrect.

#### REQ-EXAM-003: Exam timer

Mock exams shall have an optional timer that defaults off until the real exam time limit is verified.

Acceptance criteria:

- New mock exam starts with timer disabled by default.
- If enabled, timer state is local to the attempt.
- Documentation explains that the official time limit is unverified.

#### REQ-EXAM-004: Reference sheet access

Mock exam mode shall allow opening the unlabelled formula/block-diagram reference sheet.

Acceptance criteria:

- The app labels the sheet as exam reference material.
- The app does not imply affiliation with ISED.
- The reference sheet is available offline in private-development Apple app bundles and PWA offline caches; public availability is blocked until the [public-release gate](content-licensing.md#public-release-gate) is complete.

### Web app

#### REQ-WEB-001: Static deployment

The web app shall build to static assets requiring no application server.

Acceptance criteria:

- Build output can be served from a static file host.
- The app has no server runtime dependency.
- No account, analytics, ad, or third-party network request is present.

#### REQ-WEB-002: Offline PWA

The web app shall support offline study after assets and content are cached.

Acceptance criteria:

- Core app shell and bundled content load offline after first successful visit.
- Mock exam and practice work offline.
- Reference material availability offline is tested if bundled for private development or public release.
- A visible status indicates whether content is ready for offline use.

#### REQ-WEB-003: Browser-local progress

Web progress shall live only in browser storage.

Acceptance criteria:

- Progress uses IndexedDB or localStorage, with IndexedDB preferred for larger records.
- Export/import JSON and reset all data are visible in settings.
- Clearing browser storage removes progress.

### Apple app

#### REQ-APPLE-001: SwiftUI multiplatform app

The Apple app shall target iOS, iPadOS, and macOS first using SwiftUI.

Acceptance criteria:

- Shared SwiftUI views cover lessons, practice, mock exams, progress, settings, and reference sheet viewer.
- Platform-specific adaptations are limited to navigation, file import/export, and window layout.
- watchOS, visionOS, and tvOS targets are absent in v1.

#### REQ-APPLE-002: Fully offline bundle

The Apple app shall work fully offline after installation.

Acceptance criteria:

- All questions, lessons, explanations, fixtures needed at runtime, and reference assets allowed for the current private-development or release stage are included in the app bundle.
- First launch succeeds in airplane mode.
- Lessons, practice, mock exams, progress, import/export, reset, and reference viewing do not require networking.

#### REQ-APPLE-003: Local progress with SwiftData

The Apple app shall store progress locally using SwiftData.

Acceptance criteria:

- Progress schema stores the fields in REQ-QUIZ-005.
- On iOS and iPadOS, deleting the app deletes app-local progress. On macOS, deleting the app does not reliably delete the app container, so Reset all data must be available and documented.
- No iCloud sync is enabled in v1.
- Import/export JSON is user-initiated only.

#### REQ-APPLE-004: No data collection

The Apple app shall collect no data.

Acceptance criteria:

- No networking code, analytics SDK, ad SDK, crash-reporting SDK, remote config SDK, or third-party tracking SDK exists.
- App Store privacy label can truthfully state Data Not Collected.
- Verification follows [privacy.md](privacy.md).

### Privacy, offline, accessibility, and language

#### REQ-PRIV-001: No accounts or telemetry

The system shall not create accounts, collect telemetry, or transmit progress.

Acceptance criteria:

- No signup, login, account identifier, or remote profile exists.
- No analytics endpoint is configured.
- No automatic diagnostic upload exists.
- Network audit verifies no third-party requests.

#### REQ-OFFLINE-001: Offline-first behaviour

Core learning, practice, and mock exam flows shall be available offline.

Acceptance criteria:

- Apple works offline immediately after installation.
- Web works offline after cache readiness.
- Offline mode has no degraded scoring or progress features.
- Import/export works through local files or clipboard, not a remote service.

#### REQ-A11Y-001: Accessibility baseline

The apps shall be usable with common accessibility technologies.

Acceptance criteria:

- Interactive controls have accessible labels.
- Question and answer review is reachable by keyboard on web and by VoiceOver on Apple platforms.
- Text supports dynamic sizing where platform allows.
- Colour is not the only indicator of correctness.
- Mock exam timers, if enabled, have non-visual announcements.

#### REQ-I18N-001: Bilingual-ready data model

The content model shall store English and French text from day one.

Acceptance criteria:

- Question, answer, category, lesson metadata, and explanation schemas support language-keyed fields.
- Official French question text is used from ISED, not translated by the project.
- French UI is planned in P6 and does not block English-first MVP.
- Missing official French category or reference material names are tracked as open questions.

## Non-functional requirements

### Privacy

- Apple app: no data collection, no networking code, no third-party SDKs, no iCloud sync in v1.
- Web app: no accounts, no analytics, no third-party requests, no server-side progress storage.
- Export/import is explicit user action.
- See [privacy.md](privacy.md) for forbidden dependencies and verification.

### Offline

- Apple app must be fully functional offline immediately after installation.
- Web app must be able to function as an offline PWA after initial load and cache.
- Bank, lessons, explanations, and reference sheets must have deterministic bundled versions for private development; release bundles must pass the [public-release gate](content-licensing.md#public-release-gate).

### Accessibility

- Design for screen readers, keyboard navigation, dynamic type, sufficient contrast, and non-colour correctness cues.
- Accessibility checks are a release gate in P6.

### Performance

- Practice question presentation should feel instant on supported devices.
- Mock exam generation should complete in under one second for the bundled 984-question bank on typical supported devices.
- Web static assets should avoid unnecessary dependencies and self-host fonts.
- Apple app should keep bundled content in efficient JSON or compiled resource form and avoid startup parsing work that blocks first paint.

### Bilingual readiness

- Store English and French source text in the same normalized bank record.
- Avoid schema designs that assume English-only slugs or text.
- UI copy can ship English first, with French UI in P6.
- Use official ISED French question text, not project translations.

## Explicit out of scope or later

- Advanced qualification course: later.
- Morse 5 wpm trainer: later.
- watchOS companion: later.
- visionOS: later.
- tvOS: out of scope unless later explicitly approved.
- iCloud sync: not in v1; possible later only after privacy review.
- Remote progress sync, instructor dashboards, accounts, leaderboards, analytics, ads: out of scope.
- Legacy question banks: out of scope.

## Curriculum outline

Every one of the 100 subsections must map to at least one lesson. The first outline uses subsection ranges until official subsection names are imported or authored.

| Module | Category | Planned lessons | Required subsection coverage |
|---|---|---|---|
| M1 | `B-001` Regulations and Policies | L-001-01 Licence basics; L-001-02 Callsigns and operating authority; L-001-03 Bands, privileges, and power; L-001-04 Compliance scenarios | `B-001-001` through `B-001-025` |
| M2 | `B-002` Operating and Procedures | L-002-01 On-air operating; L-002-02 Contacts and message handling; L-002-03 Emergency and repeater procedures | `B-002-001` through `B-002-009` |
| M3 | `B-003` Station Assembly, Practice and Safety | L-003-01 Station blocks and controls; L-003-02 Safe installation; L-003-03 RF safety and grounding; L-003-04 Practical station troubleshooting | `B-003-001` through `B-003-021` |
| M4 | `B-004` Circuit Components | L-004-01 Passive components; L-004-02 Active components and diagrams | `B-004-001` through `B-004-006` |
| M5 | `B-005` Basic Electronics and Theory | L-005-01 DC and AC basics; L-005-02 Ohm's law and power; L-005-03 Resonance, filters, modulation, and measurements | `B-005-001` through `B-005-013` |
| M6 | `B-006` Feedlines and Antenna Systems | L-006-01 Feedlines and matching; L-006-02 Antenna patterns and polarization; L-006-03 Practical antenna setup | `B-006-001` through `B-006-013` |
| M7 | `B-007` Radio Wave Propagation | L-007-01 Propagation modes; L-007-02 Ionosphere, VHF/UHF, and planning | `B-007-001` through `B-007-008` |
| M8 | `B-008` Interference and Suppression | L-008-01 Interference causes; L-008-02 Suppression, filtering, and neighbour-friendly operations | `B-008-001` through `B-008-005` |

Coverage check requirement:

- Generate the expected subsection set from normalized question IDs.
- Read lesson front matter `covers` arrays.
- Fail if expected minus covered is non-empty.
- Fail if a lesson references an unknown subsection.
- Report duplicate coverage as informational.

## Open questions

- Verify official French category names.
- Locate or confirm absence of French 2025 Basic reference material.
- Verify the official Basic exam time limit, if any.
- ISED permission status: requested scope drafted, pending; not yet sent or granted as of the 2026-09-28 owner decision. Fill in the reference number, date, scope, and explicit app-data/reference-PDF bundling coverage in T-007 before public release.
- Decide minimum supported browser versions during implementation planning.
