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

`LessonMarkdownRenderer.render(_:)` returns lesson content as ordered `LessonBlock` values. Text-bearing blocks use Foundation `AttributedString(markdown:)` in inline-only mode, while tables, code fences, and illustration briefs stay in their source order for custom UI treatment.

```swift
let rendered = try LessonMarkdownRenderer.render(lesson.bodyMarkdown)

ForEach(Array(rendered.blocks.enumerated()), id: \.offset) { _, block in
    switch block {
    case let .heading(level, text):
        Text(text).font(level == 1 ? .title : .headline)
    case let .paragraph(text):
        Text(text)
    case let .list(ordered, items):
        VStack(alignment: .leading) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                let marker = ordered ? "\(index + 1)." : "•"
                Text(marker + " ") + Text(item)
            }
        }
    case let .code(_, text):
        Text(text).font(.system(.body, design: .monospaced))
    case let .table(table):
        LessonTableView(table: table)
    case let .illustrationBrief(brief):
        IllustrationBriefView(brief: brief)
    case let .blockquote(text):
        Text(text).italic()
    }
}
```

## Bundling content in the Apple app

For app builds, bundle only the runtime content folders as folder resources in the app target (not as network content). Do not ship `content/sources/`, `content/reference/`, READMEs, or authoring allow-list files. The runtime lookup expects the bundle to contain:

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

Loading is synchronous and reads the bundled JSON and Markdown files, so call it away from the main actor and then publish the loaded value to UI state. No networking, analytics, telemetry, or remote update path is involved; the Apple app should ship the content folder inside the application bundle for fully offline use.

## Build and test

Always use `xbuild`, not `xcodebuild`:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -list
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -scheme CanadianHamContent -destination 'platform=macOS' test
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -scheme CanadianHamContent -destination 'generic/platform=iOS Simulator' build
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -scheme CanadianHamContent -destination 'generic/platform=tvOS Simulator' build
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xbuild -scheme CanadianHamContent -destination 'generic/platform=visionOS Simulator' build
```
