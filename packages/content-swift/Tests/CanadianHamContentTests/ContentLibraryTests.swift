import Foundation
import XCTest
@testable import CanadianHamContent

final class ContentLibraryTests: XCTestCase {
    func testLoadsRealRepositoryContent() throws {
        let library = try ContentLibrary.load(fromDirectory: repoRootURL())

        XCTAssertEqual(library.questions.count, 984)
        XCTAssertEqual(library.subsections.count, 100)
        XCTAssertEqual(library.categories.count, 8)
        XCTAssertEqual(library.subsectionTitles.count, 100)
        XCTAssertEqual(library.modules.count, 8)
        XCTAssertEqual(library.modules.map(\.order), Array(1...8))
        XCTAssertEqual(library.lessons.count, 36)
        XCTAssertEqual(library.orderedLessons().count, 36)
        XCTAssertEqual(library.quizzes.count, 36)
        XCTAssertEqual(library.explanations.count, 984)
        XCTAssertEqual(library.manifest.counts.questions, 984)
        XCTAssertEqual(library.manifest.counts.subsections, 100)
        XCTAssertEqual(library.manifest.counts.categories, 8)

        let emptyConceptCheckQuizzes = library.quizzes.filter { $0.conceptChecks.isEmpty }
        XCTAssertFalse(emptyConceptCheckQuizzes.isEmpty)
        XCTAssertEqual(Set(library.quizzes.map(\.id)), try quizIdsOnDisk())
    }

    func testExplanationNoteParsingForSampleInEachCategory() throws {
        let library = try ContentLibrary.load(fromDirectory: repoRootURL())

        for category in library.categories {
            let explanation = try XCTUnwrap(library.explanations.first { $0.questionId.hasPrefix(category.id) }, "missing explanation sample for \(category.id)")
            let parsed = try ExplanationBodyParser.parse(explanation)
            XCTAssertFalse(parsed.correctAnswerParagraph.isEmpty, category.id)
            XCTAssertEqual(parsed.distractorNotes.map(\.sourceIndex).sorted(), [1, 2, 3], category.id)
            XCTAssertEqual(parsed.distractorNotes.count, 3, category.id)
            for note in parsed.distractorNotes {
                XCTAssertFalse(note.quotedChoice.isEmpty, category.id)
                XCTAssertFalse(note.note.isEmpty, category.id)
            }
        }
    }

    func testStrictFrontMatterParserRejectsMalformedInput() throws {
        let malformedQuote = """
        ---
        type: lesson
        id: "L-TEST-01
        ---
        # Bad
        """
        XCTAssertThrowsError(try StrictFrontMatterParser.parse(markdown: malformedQuote, path: "malformed.md")) { error in
            XCTAssertTrue(String(describing: error).contains("malformed quoted string"), String(describing: error))
        }

        let unsupportedIndentation = """
        ---
        type: lesson
          - wrong
        ---
        # Bad
        """
        XCTAssertThrowsError(try StrictFrontMatterParser.parse(markdown: unsupportedIndentation, path: "bad-indent.md")) { error in
            XCTAssertTrue(String(describing: error).contains("array item is not under an array key"), String(describing: error))
        }
    }

    func testFrontMatterParserMatchesNumericAndASCIIKeyRules() throws {
        let numeric = """
        ---
        type: lesson
        estimatedMinutes: 030
        ---
        # OK
        """
        let parsed = try StrictFrontMatterParser.parse(markdown: numeric, path: "numeric.md")
        XCTAssertEqual(parsed.frontMatter["estimatedMinutes"], .integer(30))

        let unicodeKey = """
        ---
        typé: lesson
        ---
        # Bad
        """
        XCTAssertThrowsError(try StrictFrontMatterParser.parse(markdown: unicodeKey, path: "unicode-key.md")) { error in
            XCTAssertTrue(String(describing: error).contains("expected key-value front matter line"), String(describing: error))
        }
    }

    func testTableIllustrationBriefAndBlockOrderForL00501() throws {
        let library = try ContentLibrary.load(fromDirectory: repoRootURL())
        let lesson = try XCTUnwrap(library.lessonsById["L-005-01"])
        let rendered = try LessonMarkdownRenderer.render(lesson.bodyMarkdown)

        XCTAssertGreaterThan(rendered.blocks.count, 40)
        XCTAssertBlock(rendered.blocks[0], isHeadingLevel: 1, text: "Units, conductors, and current")
        XCTAssertBlock(rendered.blocks[1], isParagraphContaining: "Radio starts with a few simple measurements")
        XCTAssertBlock(rendered.blocks[2], isParagraphContaining: "Do not try to memorize")
        XCTAssertBlock(rendered.blocks[3], isHeadingLevel: 2, text: "Learning objectives")
        XCTAssertBlock(rendered.blocks[4], isParagraphContaining: "By the end of this lesson")
        XCTAssertBlock(rendered.blocks[5], isListOrdered: false, itemCount: 5)
        XCTAssertBlock(rendered.blocks[6], isHeadingLevel: 2, text: "The metric prefix ladder")
        XCTAssertBlock(rendered.blocks[7], isParagraphContaining: "A prefix tells you")

        guard case let .table(firstTable) = rendered.blocks[8] else {
            return XCTFail("expected first table at block 8, got \(rendered.blocks[8])")
        }
        XCTAssertEqual(firstTable.headers.map(stringValue), ["Prefix", "Symbol", "Meaning", "Example"])
        XCTAssertEqual(firstTable.alignment, [.none, .right, .right, .none])
        XCTAssertEqual(firstTable.rows.first?.map(stringValue), ["giga", "G", "1 000 000 000 times the base unit", "4 GHz = 4 000 MHz"])

        let illustration = try XCTUnwrap(rendered.illustrationBriefs.first)
        XCTAssertTrue(illustration.altText.contains("metric-prefix ladder"))
        XCTAssertTrue(illustration.description.contains("Draw a simple ink-brush ladder"))
    }

    func testMarkdownRendererParsesEveryRealLesson() throws {
        let library = try ContentLibrary.load(fromDirectory: repoRootURL())
        for lesson in library.lessons {
            let rendered = try LessonMarkdownRenderer.render(lesson.bodyMarkdown)
            XCTAssertFalse(rendered.blocks.isEmpty, lesson.id)
            XCTAssertTrue(rendered.blocks.contains { block in
                if case .illustrationBrief = block { return true }
                return false
            }, lesson.id)
        }
    }

    func testSharedFigureDirectiveFixtures() throws {
        let fixtureURL = try repoRootURL().appendingPathComponent("fixtures/markdown-figure-directives.json")
        let fixtures = try JSONDecoder().decode([FigureDirectiveFixture].self, from: Data(contentsOf: fixtureURL))
        for fixture in fixtures {
            let rendered = try LessonMarkdownRenderer.render(fixture.markdown)
            XCTAssertEqual(simplifiedBlocks(rendered.blocks), fixture.expected, fixture.name)
        }
    }

    func testFigureDirectivesForOhmsLawLesson() throws {
        let library = try ContentLibrary.load(fromDirectory: repoRootURL())
        let lesson = try XCTUnwrap(library.lessonsById["L-005-02"])
        let rendered = try LessonMarkdownRenderer.render(lesson.bodyMarkdown)

        XCTAssertEqual(rendered.figures.map(\.id), ["power-triangle", "ohms-law-triangle", "ohms-law-power-wheel"])
        let wheel = try XCTUnwrap(rendered.figures.last)
        XCTAssertTrue(wheel.altText.contains("quadrants for P, E, I, and R"))
        XCTAssertEqual(wheel.textEquivalent, [
            "To find P: I x E; I² x R; E² / R.",
            "To find E: I x R; P / I; √(P x R).",
            "To find I: E / R; P / E; √(P / R).",
            "To find R: E / I; E² / P; P / I²."
        ])
    }

    func testTableParserHandlesAlignmentEscapedPipesAndFencedCode() throws {
        let markdown = """
        ```text
        | Not | A table |
        |---|---|
        ```

        | Left | Centre | Right | Escaped |
        |:-----|:------:|------:|-|
        | a | b | c | d\\|e |
        """
        let rendered = try LessonMarkdownRenderer.render(markdown)
        XCTAssertEqual(rendered.tables.count, 1)
        let table = try XCTUnwrap(rendered.tables.first)
        XCTAssertEqual(table.alignment, [.left, .center, .right, .none])
        XCTAssertEqual(table.rows.first?.map(stringValue), ["a", "b", "c", "d|e"])
    }

    func testMarkdownInlineHandlingKeepsRawHTMLLiteralButPreservesCodeAndAutolinks() throws {
        let rendered = try LessonMarkdownRenderer.render("Before <strong>raw HTML</strong> and `<em>code</em>` and <https://example.com/path> after")
        let characters = String(rendered.attributedString.characters)
        XCTAssertTrue(characters.contains("<strong>raw HTML</strong>"), characters)
        XCTAssertTrue(characters.contains("<em>code</em>"), characters)
        XCTAssertTrue(characters.contains("https://example.com/path"), characters)

        let linkRanges = rendered.attributedString.runs.compactMap { run -> URL? in
            if case let .some(link) = run.link {
                return link
            }
            return nil
        }
        XCTAssertTrue(linkRanges.contains(URL(string: "https://example.com/path")!))
    }

    func testExplanationParserRejectsDuplicateAndCorrectSourceIndexNotes() throws {
        let duplicate = """
        Why the correct answer is right: Correct.

        Why the distractors are wrong:
        - sourceIndex 1: "Wrong": note one.
        - sourceIndex 1: "Wrong again": note two.
        """
        XCTAssertThrowsError(try ExplanationBodyParser.parse(duplicate)) { error in
            XCTAssertTrue(String(describing: error).contains("duplicate per-choice note"), String(describing: error))
        }

        let sourceIndexZero = """
        Why the correct answer is right: Correct.

        Why the distractors are wrong:
        - sourceIndex 0: "Correct": no correct-answer note here.
        """
        XCTAssertThrowsError(try ExplanationBodyParser.parse(sourceIndexZero)) { error in
            XCTAssertTrue(String(describing: error).contains("sourceIndex 0"), String(describing: error))
        }
    }

    func testLoadFromBundleFindsBundledContentDirectory() throws {
        try withTemporaryContentFixture { root in
            let bundleURL = root.appendingPathComponent("Fixture.bundle", isDirectory: true)
            try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
            try FileManager.default.moveItem(at: root.appendingPathComponent("content", isDirectory: true), to: bundleURL.appendingPathComponent("content", isDirectory: true))
            let bundle = try XCTUnwrap(Bundle(url: bundleURL))
            let library = try ContentLibrary.load(from: bundle)
            XCTAssertEqual(library.modules.count, 8)
            XCTAssertEqual(library.questions.count, 1)
        }
    }

    func testContentLibraryRejectsEmptyModuleListWithoutCrashing() throws {
        try withTemporaryContentFixture(includeLessons: false) { root in
            XCTAssertThrowsError(try ContentLibrary.load(fromDirectory: root)) { error in
                XCTAssertTrue(String(describing: error).contains("module order values"), String(describing: error))
            }
        }
    }

    func testContentLibraryRejectsUnknownPrerequisite() throws {
        try withTemporaryContentFixture { root in
            let lessonURL = lessonURL(root: root, moduleNumber: 1)
            try replace(in: lessonURL, "prerequisites: []", with: "prerequisites:\n  - L-001-99")
            XCTAssertThrowsError(try ContentLibrary.load(fromDirectory: root)) { error in
                XCTAssertTrue(String(describing: error).contains("prerequisites references unknown lesson L-001-99"), String(describing: error))
            }
        }
    }

    func testContentLibraryRejectsCoversOutsideLessonCategoryIds() throws {
        try withTemporaryContentFixture { root in
            let lessonURL = lessonURL(root: root, moduleNumber: 1)
            try replace(in: lessonURL, "covers:\n  - B-001-001", with: "covers:\n  - B-002-001")
            XCTAssertThrowsError(try ContentLibrary.load(fromDirectory: root)) { error in
                XCTAssertTrue(String(describing: error).contains("does not match categoryIds B-001"), String(describing: error))
            }
        }
    }

    func testContentLibraryRejectsMissingSubsectionCoverage() throws {
        try withTemporaryContentFixture { root in
            let subsectionsURL = root.appendingPathComponent("content/generated/basic-2025-07-15/subsections.json")
            let manifestURL = root.appendingPathComponent("content/generated/basic-2025-07-15/manifest.json")
            let titlesURL = root.appendingPathComponent("content/subsection-titles.json")
            let decoder = JSONDecoder()
            var subsections = try decoder.decode([Subsection].self, from: Data(contentsOf: subsectionsURL))
            subsections.append(Subsection(id: "B-008-002", bankId: canadianHamDefaultBankId, categoryId: "B-008", questionIds: [], questionCount: 0, lessonIds: [], title: LocalizedOptionalText(en: "Uncovered", fr: nil)))
            try writeJSON(subsections, to: subsectionsURL)
            var titles = try decoder.decode([SubsectionTitle].self, from: Data(contentsOf: titlesURL))
            titles.append(SubsectionTitle(id: "B-008-002", title: LocalizedNullableText(en: "Uncovered", fr: nil), status: "draft"))
            try writeJSON(titles, to: titlesURL)
            let manifest = try decoder.decode(BankManifest.self, from: Data(contentsOf: manifestURL))
            try writeJSON(
                BankManifest(
                    bankId: manifest.bankId,
                    certificate: manifest.certificate,
                    effectiveDate: manifest.effectiveDate,
                    source: manifest.source,
                    importer: manifest.importer,
                    counts: BankManifestCounts(questions: manifest.counts.questions, categories: manifest.counts.categories, subsections: 9)
                ),
                to: manifestURL
            )
            XCTAssertThrowsError(try ContentLibrary.load(fromDirectory: root)) { error in
                XCTAssertTrue(String(describing: error).contains("missing lesson coverage for subsectionIds B-008-002"), String(describing: error))
            }
        }
    }

    func testContentLibraryRejectsMissingExplanationForQuestion() throws {
        try withTemporaryContentFixture { root in
            try FileManager.default.removeItem(at: root.appendingPathComponent("content/explanations/b-001/b-001-001-001.json"))
            XCTAssertThrowsError(try ContentLibrary.load(fromDirectory: root)) { error in
                XCTAssertTrue(String(describing: error).contains("missing explanations for questionIds B-001-001-001"), String(describing: error))
            }
        }
    }

    func testContentLibraryRejectsExplanationIdMismatch() throws {
        try withTemporaryContentFixture { root in
            let explanationURL = root.appendingPathComponent("content/explanations/b-001/b-001-001-001.json")
            try replace(in: explanationURL, "EXP-B-001-001-001", with: "EXP-WRONG")
            XCTAssertThrowsError(try ContentLibrary.load(fromDirectory: root)) { error in
                XCTAssertTrue(String(describing: error).contains("id must be EXP-B-001-001-001"), String(describing: error))
            }
        }
    }

    func testContentLibraryRejectsUnknownOfficialQuestionInQuiz() throws {
        try withTemporaryContentFixture { root in
            let quizURL = root.appendingPathComponent("content/quizzes/QZ-L-001-01-A.json")
            try replace(in: quizURL, "B-001-001-001", with: "B-001-001-999")
            XCTAssertThrowsError(try ContentLibrary.load(fromDirectory: root)) { error in
                XCTAssertTrue(String(describing: error).contains("references unknown official questionId B-001-001-999"), String(describing: error))
            }
        }
    }

    func testLessonIdRegexRejectsMalformedIds() throws {
        try withTemporaryContentFixture { root in
            let lessonURL = lessonURL(root: root, moduleNumber: 1)
            try replace(in: lessonURL, "id: L-001-01", with: "id: L-905-xy")
            XCTAssertThrowsError(try ContentLibrary.load(fromDirectory: root)) { error in
                XCTAssertTrue(String(describing: error).contains("lesson id must match"), String(describing: error))
            }
        }
    }
}

private struct FigureDirectiveFixture: Decodable {
    let name: String
    let markdown: String
    let expected: [SimplifiedMarkdownBlock]
}

private struct SimplifiedMarkdownBlock: Decodable, Equatable {
    let type: String
    let id: String?
    let altText: String?
    let textEquivalent: [String]?
    let text: String?
    let language: String?
}

private func simplifiedBlocks(_ blocks: [LessonBlock]) -> [SimplifiedMarkdownBlock] {
    blocks.map { block in
        switch block {
        case .figure(let figure):
            SimplifiedMarkdownBlock(type: "figure", id: figure.id, altText: figure.altText, textEquivalent: figure.textEquivalent, text: nil, language: nil)
        case .paragraph(let text):
            SimplifiedMarkdownBlock(type: "paragraph", id: nil, altText: nil, textEquivalent: nil, text: String(text.characters), language: nil)
        case .code(let language, let text):
            SimplifiedMarkdownBlock(type: "code", id: nil, altText: nil, textEquivalent: nil, text: text, language: language)
        case .heading(_, let text):
            SimplifiedMarkdownBlock(type: "heading", id: nil, altText: nil, textEquivalent: nil, text: String(text.characters), language: nil)
        case .list, .table, .illustrationBrief, .blockquote:
            SimplifiedMarkdownBlock(type: "other", id: nil, altText: nil, textEquivalent: nil, text: nil, language: nil)
        }
    }
}

private func repoRootURL() throws -> URL {
    var url = URL(fileURLWithPath: #filePath)
    while url.pathComponents.count > 1 {
        let candidate = url.appendingPathComponent("content", isDirectory: true)
        if FileManager.default.fileExists(atPath: candidate.path(percentEncoded: false)) {
            return url
        }
        url.deleteLastPathComponent()
    }
    throw ContentError("Unable to resolve repository root from #filePath")
}

private func quizIdsOnDisk() throws -> Set<String> {
    let quizzesURL = try repoRootURL().appendingPathComponent("content/quizzes", isDirectory: true)
    let urls = try FileManager.default.contentsOfDirectory(at: quizzesURL, includingPropertiesForKeys: nil)
        .filter { $0.pathExtension == "json" }
    return Set(try urls.map { url in
        let data = try Data(contentsOf: url)
        let quiz = try JSONDecoder().decode(LessonQuiz.self, from: data)
        return quiz.id
    })
}

private func XCTAssertBlock(_ block: LessonBlock, isHeadingLevel expectedLevel: Int, text expectedText: String, file: StaticString = #filePath, line: UInt = #line) {
    guard case let .heading(level, text) = block else {
        return XCTFail("expected heading", file: file, line: line)
    }
    XCTAssertEqual(level, expectedLevel, file: file, line: line)
    XCTAssertEqual(stringValue(text), expectedText, file: file, line: line)
}

private func XCTAssertBlock(_ block: LessonBlock, isParagraphContaining expectedText: String, file: StaticString = #filePath, line: UInt = #line) {
    guard case let .paragraph(text) = block else {
        return XCTFail("expected paragraph", file: file, line: line)
    }
    XCTAssertTrue(stringValue(text).contains(expectedText), stringValue(text), file: file, line: line)
}

private func XCTAssertBlock(_ block: LessonBlock, isListOrdered expectedOrdered: Bool, itemCount expectedCount: Int, file: StaticString = #filePath, line: UInt = #line) {
    guard case let .list(ordered, items) = block else {
        return XCTFail("expected list", file: file, line: line)
    }
    XCTAssertEqual(ordered, expectedOrdered, file: file, line: line)
    XCTAssertEqual(items.count, expectedCount, file: file, line: line)
}

private func stringValue(_ value: AttributedString) -> String {
    String(value.characters)
}

private func withTemporaryContentFixture(includeLessons: Bool = true, run: (URL) throws -> Void) throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("CanadianHamContentTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    try writeContentFixture(at: root, includeLessons: includeLessons)
    try run(root)
}

private func writeContentFixture(at root: URL, includeLessons: Bool) throws {
    let content = root.appendingPathComponent("content", isDirectory: true)
    try FileManager.default.createDirectory(at: content.appendingPathComponent("generated/basic-2025-07-15", isDirectory: true), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: content.appendingPathComponent("lessons", isDirectory: true), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: content.appendingPathComponent("quizzes", isDirectory: true), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: content.appendingPathComponent("explanations/b-001", isDirectory: true), withIntermediateDirectories: true)

    let categories = (1...8).map { number in
        Category(
            id: categoryId(number),
            bankId: canadianHamDefaultBankId,
            name: LocalizedNullableText(en: "Category \(number)", fr: nil),
            frenchNameStatus: "missing",
            questionCount: number == 1 ? 1 : 0,
            subsectionCount: 1,
            examQuestionCount: 1,
            nameSource: "fixture"
        )
    }
    let subsections = (1...8).map { number in
        Subsection(
            id: subsectionId(number),
            bankId: canadianHamDefaultBankId,
            categoryId: categoryId(number),
            questionIds: number == 1 ? ["B-001-001-001"] : [],
            questionCount: number == 1 ? 1 : 0,
            lessonIds: [lessonId(number)],
            title: LocalizedOptionalText(en: "Subsection \(number)", fr: nil)
        )
    }
    let question = Question(
        id: "B-001-001-001",
        bankId: canadianHamDefaultBankId,
        categoryId: "B-001",
        subsectionId: "B-001-001",
        sourceOrder: 1,
        text: LocalizedText(en: "Fixture question?", fr: "Question exemple?"),
        answers: [
            Answer(sourceIndex: 0, isCorrect: true, text: LocalizedText(en: "Correct answer", fr: "Bonne réponse")),
            Answer(sourceIndex: 1, isCorrect: false, text: LocalizedText(en: "Wrong one", fr: "Mauvaise un")),
            Answer(sourceIndex: 2, isCorrect: false, text: LocalizedText(en: "Wrong two", fr: "Mauvaise deux")),
            Answer(sourceIndex: 3, isCorrect: false, text: LocalizedText(en: "Wrong three", fr: "Mauvaise trois")),
        ]
    )
    let manifest = BankManifest(
        bankId: canadianHamDefaultBankId,
        certificate: "Basic",
        effectiveDate: "2025-07-15",
        source: BankManifestSource(path: "fixture", sha256: "fixture", url: "https://ised-isde.canada.ca/fixture", encoding: "utf8", lineEndings: "lf"),
        importer: BankManifestImporter(name: "fixture", version: "1"),
        counts: BankManifestCounts(questions: 1, categories: 8, subsections: 8)
    )
    try writeJSON(manifest, to: content.appendingPathComponent("generated/basic-2025-07-15/manifest.json"))
    try writeJSON([question], to: content.appendingPathComponent("generated/basic-2025-07-15/questions.json"))
    try writeJSON(categories, to: content.appendingPathComponent("generated/basic-2025-07-15/categories.json"))
    try writeJSON(subsections, to: content.appendingPathComponent("generated/basic-2025-07-15/subsections.json"))
    try writeJSON(subsections.map { SubsectionTitle(id: $0.id, title: LocalizedNullableText(en: $0.title.en ?? $0.id, fr: nil), status: "draft") }, to: content.appendingPathComponent("subsection-titles.json"))

    if includeLessons {
        for number in 1...8 {
            let moduleDirectory = content.appendingPathComponent("lessons/m\(number)", isDirectory: true)
            try FileManager.default.createDirectory(at: moduleDirectory, withIntermediateDirectories: true)
            try moduleMarkdown(moduleNumber: number).write(to: moduleDirectory.appendingPathComponent("index.md"), atomically: true, encoding: .utf8)
            try lessonMarkdown(moduleNumber: number).write(to: moduleDirectory.appendingPathComponent("\(lessonId(number).lowercased()).md"), atomically: true, encoding: .utf8)
            let quiz = LessonQuiz(id: quizId(number), lessonId: lessonId(number), officialQuestionIds: number == 1 ? ["B-001-001-001"] : [], conceptChecks: [])
            try writeJSON(quiz, to: content.appendingPathComponent("quizzes/\(quiz.id).json"))
        }
    }

    let explanation = Explanation(
        id: "EXP-B-001-001-001",
        questionId: "B-001-001-001",
        bankId: canadianHamDefaultBankId,
        status: "draft",
        body: LocalizedNullableText(
            en: "Why the correct answer is right: Fixture reason.\n\nWhy the distractors are wrong:\n- sourceIndex 1: \"Wrong one\": This confuses the first fixture distractor.\n- sourceIndex 2: \"Wrong two\": This confuses the second fixture distractor.\n- sourceIndex 3: \"Wrong three\": This confuses the third fixture distractor.",
            fr: nil
        ),
        citations: [ExplanationCitation(type: "question", id: "B-001-001-001"), ExplanationCitation(type: "lesson", id: "L-001-01")],
        licenseClass: "original"
    )
    try writeJSON(explanation, to: content.appendingPathComponent("explanations/b-001/b-001-001-001.json"))
}

private func writeJSON<T: Encodable>(_ value: T, to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(value)
    try data.write(to: url)
}

private func moduleMarkdown(moduleNumber: Int) -> String {
    """
    ---
    type: module
    id: M\(moduleNumber)
    categoryId: \(categoryId(moduleNumber))
    order: \(moduleNumber)
    title:
      en: "Module \(moduleNumber)"
      fr: null
    lessonIds:
      - \(lessonId(moduleNumber))
    status: draft
    ---
    # Module \(moduleNumber)
    """
}

private func lessonMarkdown(moduleNumber: Int) -> String {
    """
    ---
    type: lesson
    id: \(lessonId(moduleNumber))
    moduleId: M\(moduleNumber)
    categoryIds:
      - \(categoryId(moduleNumber))
    title:
      en: "Lesson \(moduleNumber)"
      fr: null
    covers:
      - \(subsectionId(moduleNumber))
    objectives:
      - "Use fixture content."
    prerequisites: []
    estimatedMinutes: 10
    quizIds:
      - \(quizId(moduleNumber))
    status: draft
    ---
    # Lesson \(moduleNumber)

    Fixture body.
    """
}

private func categoryId(_ number: Int) -> String {
    "B-00\(number)"
}

private func subsectionId(_ number: Int) -> String {
    "\(categoryId(number))-001"
}

private func lessonId(_ number: Int) -> String {
    "L-00\(number)-01"
}

private func quizId(_ number: Int) -> String {
    "QZ-\(lessonId(number))-A"
}

private func lessonURL(root: URL, moduleNumber: Int) -> URL {
    root.appendingPathComponent("content/lessons/m\(moduleNumber)/\(lessonId(moduleNumber).lowercased()).md")
}

private func replace(in url: URL, _ oldValue: String, with newValue: String) throws {
    let text = try String(contentsOf: url, encoding: .utf8)
    guard text.contains(oldValue) else {
        throw ContentError("fixture replacement did not find \(oldValue) in \(url.path(percentEncoded: false))")
    }
    try text.replacingOccurrences(of: oldValue, with: newValue).write(to: url, atomically: true, encoding: .utf8)
}
