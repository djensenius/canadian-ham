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

    func testTableAndIllustrationBriefParsing() throws {
        let library = try ContentLibrary.load(fromDirectory: repoRootURL())
        let lesson = try XCTUnwrap(library.lessonsById["L-005-01"])
        let rendered = try LessonMarkdownRenderer.render(lesson.bodyMarkdown)

        let firstTable = try XCTUnwrap(rendered.tables.first)
        XCTAssertEqual(firstTable.headers, ["Prefix", "Symbol", "Meaning", "Example"])
        XCTAssertEqual(firstTable.rows.first, ["giga", "G", "1 000 000 000 times the base unit", "4 GHz = 4 000 MHz"])

        let illustration = try XCTUnwrap(rendered.illustrationBriefs.first)
        XCTAssertTrue(illustration.altText.contains("metric-prefix ladder"))
        XCTAssertTrue(illustration.description.contains("Draw a simple ink-brush ladder"))
    }

    func testMarkdownAttributedStringDoesNotInterpretRawHTML() throws {
        let rendered = try LessonMarkdownRenderer.render("Before <strong>raw HTML</strong> after")
        let characters = String(rendered.attributedString.characters)
        XCTAssertTrue(characters.contains("<strong>raw HTML</strong>"), characters)
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
