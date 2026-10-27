#if canImport(Darwin)
// Linux Foundation does not provide AttributedString Markdown parsing.
import Foundation
import XCTest
@testable import CanadianHamContent

final class MarkdownLessonContentTests: XCTestCase {
    func testTryItAnswersAreSeparateBlocksAndDoNotLeakIntoFlattenedLessonText() throws {
        let markdown = """
        ## Try it

        1. Find the current.

        :::answer
        The current is 3 A.
        :::

        2. Name the path.

        :::answer
        The audio path.
        :::

        ## Radio connection

        Keep listening.
        """
        let rendered = try LessonMarkdownRenderer.render(markdown)
        XCTAssertEqual(rendered.blocks[1], .tryIt(number: 1, prompt: AttributedString("Find the current."), answer: AttributedString("The current is 3 A.")))
        XCTAssertEqual(rendered.blocks[2], .tryIt(number: 2, prompt: AttributedString("Name the path."), answer: AttributedString("The audio path.")))
        let flattened = String(rendered.attributedString.characters)
        XCTAssertTrue(flattened.contains("Find the current."))
        XCTAssertFalse(flattened.contains("The current is 3 A."))
        XCTAssertFalse(flattened.contains("The audio path."))
        XCTAssertEqual(try LessonHeadingAnchors.anchors(for: markdown), ["try-it", "radio-connection"])
    }

    func testAllAuthoredTryItAnswersParseWithoutExposingDirectiveText() throws {
        let library = try ContentLibrary.load(fromDirectory: repoRootURL())
        var lessonCount = 0
        var answerCount = 0
        for lesson in library.lessons where lesson.bodyMarkdown.contains("## Try it\n") {
            lessonCount += 1
            let rendered = try LessonMarkdownRenderer.render(lesson.bodyMarkdown)
            let items = rendered.blocks.filter { if case .tryIt = $0 { return true }; return false }
            let directiveCount = lesson.bodyMarkdown.components(separatedBy: ":::answer\n").count - 1
            XCTAssertEqual(items.count, directiveCount, lesson.id)
            XCTAssertFalse(String(rendered.attributedString.characters).contains(":::"), lesson.id)
            answerCount += items.count
        }
        XCTAssertEqual(lessonCount, 31)
        XCTAssertEqual(answerCount, 141)
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

    func testSharedLessonHeadingAnchorFixtures() throws {
        let fixtureURL = try repoRootURL().appendingPathComponent("fixtures/lesson-heading-anchors.json")
        let fixtures = try JSONDecoder().decode(LessonHeadingAnchorFixtures.self, from: Data(contentsOf: fixtureURL))

        for fixture in fixtures.slugCases {
            XCTAssertEqual(LessonHeadingAnchors.slug(for: fixture.headingText), fixture.expectedSlug, fixture.name)
        }
        for fixture in fixtures.anchorCases {
            let anchors = try LessonHeadingAnchors.anchors(for: fixture.markdown, title: fixture.title)
            XCTAssertEqual(anchors, fixture.expectedAnchors, fixture.name)
            for rejectedAnchor in fixture.rejectedAnchors {
                XCTAssertFalse(anchors.contains(rejectedAnchor), "\(fixture.name) should not expose \(rejectedAnchor)")
            }
        }
    }

    func testBundledQuestionHintSectionAnchorsResolveInLessons() throws {
        let library = try ContentLibrary.load(fromDirectory: repoRootURL())

        for hint in library.questionHints {
            guard let sectionAnchor = hint.lessonLink.sectionAnchor else { continue }
            let lesson = try XCTUnwrap(library.lessonsById[hint.lessonLink.lessonId], "\(hint.id) should reference an existing lesson")
            let anchors = try LessonHeadingAnchors.anchors(for: lesson.bodyMarkdown, title: lesson.title.en)
            XCTAssertTrue(anchors.contains(sectionAnchor), "\(hint.id) sectionAnchor \(sectionAnchor) should resolve in \(lesson.id)")
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
            "To find P: I x E.",
            "To find P: I² x R.",
            "To find P: E² / R.",
            "To find E: I x R.",
            "To find E: P / I.",
            "To find E: √(P x R).",
            "To find I: E / R.",
            "To find I: P / E.",
            "To find I: √(P / R).",
            "To find R: E / I.",
            "To find R: E² / P.",
            "To find R: P / I²."
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

private struct LessonHeadingAnchorFixtures: Decodable {
    let slugCases: [LessonHeadingAnchorSlugFixture]
    let anchorCases: [LessonHeadingAnchorCaseFixture]
}

private struct LessonHeadingAnchorSlugFixture: Decodable {
    let name: String
    let headingText: String
    let expectedSlug: String
}

private struct LessonHeadingAnchorCaseFixture: Decodable {
    let name: String
    let title: String?
    let markdown: String
    let expectedAnchors: [String]
    let rejectedAnchors: [String]
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
        case .list, .table, .illustrationBrief, .blockquote, .tryIt:
            SimplifiedMarkdownBlock(type: "other", id: nil, altText: nil, textEquivalent: nil, text: nil, language: nil)
        }
    }
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
#endif
