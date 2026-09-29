# packages/content-swift

SwiftPM content loader for the Canadian Ham Apple apps. The package exposes the library product `CanadianHamContent` for iOS 18, macOS 15, visionOS 2, and tvOS 18. It has no third-party dependencies and uses Foundation only.

## API overview

`ContentLibrary` is the main entry point:

```swift
import CanadianHamContent

let library = try ContentLibrary.load(from: .main)
```

The loaded library contains public `Sendable` value types for:

- generated Basic 2025-07-15 question-bank data: `Question`, `Answer`, `Subsection`, `Category`, and `BankManifest`;
- hand-maintained subsection titles: `SubsectionTitle`;
- Markdown lesson modules and lessons parsed from strict front matter: `LessonModule` and `Lesson`;
- lesson quiz files, including official-question-only quizzes with `conceptChecks: []`: `LessonQuiz`, `ConceptCheck`, and `ConceptCheckChoice`;
- explanations: `Explanation`, `ExplanationCitation`, `ParsedExplanationBody`, and `ParsedDistractorNote`.

`ContentLibrary.load(fromDirectory:)` accepts either the repository root or the `content/` directory directly. Loading cross-validates references between generated bank data, subsection titles, lesson coverage, lesson/module ordering, lesson quizzes, and explanations. Failures throw `ContentError` with a descriptive message.

```swift
let repoRoot = URL(fileURLWithPath: "/path/to/canadian-ham")
let library = try ContentLibrary.load(fromDirectory: repoRoot)
let lesson = library.lessonsById["L-005-01"]
let question = library.questionsById["B-005-001-001"]
```

`ExplanationBodyParser.parse(_:)` splits explanation Markdown into the correct-answer paragraph and per-distractor notes keyed by official answer `sourceIndex`, so a shuffled UI can show each note beside the displayed choice.

```swift
let parsed = try ExplanationBodyParser.parse(explanation)
let noteForDisplayedChoice = parsed.distractorNotesBySourceIndex[sourceIndex]
```

`LessonMarkdownRenderer.render(_:)` uses Foundation `AttributedString(markdown:)` with raw-HTML tag escaping, and also exposes structured `MarkdownTable` and `MarkdownIllustrationBrief` values because those blocks need custom UI treatment.

```swift
let rendered = try LessonMarkdownRenderer.render(lesson.bodyMarkdown)
Text(rendered.attributedString)
// Render rendered.tables and rendered.illustrationBriefs with app-specific views.
```

## Bundling content in the Apple app

For app builds, bundle the repository `content/` folder as a folder resource in the app target (not as network content). The runtime lookup expects the bundle to contain:

```text
content/
  generated/basic-2025-07-15/{manifest,categories,subsections,questions}.json
  subsection-titles.json
  lessons/**/*.md
  quizzes/*.json
  explanations/**/*.json
```

Then call:

```swift
let library = try ContentLibrary.load(from: Bundle.main)
```

No networking, analytics, telemetry, or remote update path is involved; the Apple app should ship the content folder inside the application bundle for fully offline use.

## Build and test

Always use `xbuild`, not `xcodebuild`:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -list
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -scheme CanadianHamContent -destination 'platform=macOS' test
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -scheme CanadianHamContent -destination 'generic/platform=iOS Simulator' build
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -scheme CanadianHamContent -destination 'generic/platform=tvOS Simulator' build
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -scheme CanadianHamContent -destination 'generic/platform=visionOS Simulator' build
```
