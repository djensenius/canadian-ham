import Foundation
import XCTest
@testable import CanadianHamContent

final class ContentLibraryTests: XCTestCase {
    func testM1QuizRoundsDecodeAndRoundTripWithoutChangingLegacyQuizzes() throws {
        let library = try ContentLibrary.load(fromDirectory: repoRootURL())
        var total = 0
        for quiz in library.quizzesById.values where quiz.lessonId.hasPrefix("L-001-") {
            let rounds = try XCTUnwrap(quiz.rounds)
            XCTAssertEqual(try JSONDecoder().decode(LessonQuiz.self, from: JSONEncoder().encode(quiz)), quiz)
            let ids = rounds.flatMap(\.officialQuestionIds)
            XCTAssertEqual(ids.count, quiz.officialQuestionIds.count)
            XCTAssertEqual(Set(ids), Set(quiz.officialQuestionIds))
            XCTAssertTrue(rounds.allSatisfy { !$0.sectionAnchor.isEmpty && !($0.title.fr ?? "").isEmpty })
            total += ids.count
        }
        XCTAssertEqual(total, 199)
        XCTAssertNil(try XCTUnwrap(library.quizzesById["QZ-L-005-01-A"]).rounds)
    }

    func testLoadsRealRepositoryContent() throws {
        let library = try ContentLibrary.load(fromDirectory: repoRootURL())

        XCTAssertEqual(library.questions.count, 984)
        XCTAssertEqual(library.subsections.count, 100)
        XCTAssertEqual(library.categories.count, 8)
        XCTAssertEqual(library.subsectionTitles.count, 100)
        XCTAssertEqual(library.modules.count, 8)
        XCTAssertEqual(library.modules.map(\.order), Array(1...8))
        XCTAssertEqual(library.lessons.count, 37)
        XCTAssertEqual(library.orderedLessons().count, 37)
        XCTAssertEqual(library.quizzes.count, 37)
        XCTAssertEqual(library.explanations.count, 984)
        XCTAssertEqual(library.questionHints.count, 984)
        XCTAssertEqual(library.manifest.counts.questions, 984)
        XCTAssertEqual(library.manifest.counts.subsections, 100)
        XCTAssertEqual(library.manifest.counts.categories, 8)

        let emptyConceptCheckQuizzes = library.quizzes.filter { $0.conceptChecks.isEmpty }
        XCTAssertFalse(emptyConceptCheckQuizzes.isEmpty)
        XCTAssertEqual(Set(library.quizzes.map(\.id)), try quizIdsOnDisk())
    }

    func testConceptCheckChoiceDecodesOptionalFeedbackAndRoundTrips() throws {
        let decoder = JSONDecoder()
        let legacy = Data(#"{"text":{"en":"Detection","fr":null},"isCorrect":false}"#.utf8)
        XCTAssertNil(try decoder.decode(ConceptCheckChoice.self, from: legacy).feedback)
        XCTAssertNil(ConceptCheckChoice(text: LocalizedNullableText(en: "Detection", fr: nil), isCorrect: false).feedback)

        for french in ["null", #""La détection récupère l’audio.""#] {
            let json = Data("""
            {"text":{"en":"Detection","fr":null},"isCorrect":false,"feedback":{"en":"Detection recovers audio.","fr":\(french)}}
            """.utf8)
            let choice = try decoder.decode(ConceptCheckChoice.self, from: json)
            XCTAssertEqual(choice.feedback?.en, "Detection recovers audio.")
            XCTAssertEqual(choice.feedback?.fr, french == "null" ? nil : "La détection récupère l’audio.")
            XCTAssertEqual(try decoder.decode(ConceptCheckChoice.self, from: JSONEncoder().encode(choice)), choice)
        }
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

    func testBadHintFileDropsHintsWithoutDroppingLessonContent() throws {
        try withTemporaryContentFixture { root in
            let hintsDirectory = root.appendingPathComponent("content/hints/b-001", isDirectory: true)
            try FileManager.default.createDirectory(at: hintsDirectory, withIntermediateDirectories: true)
            try "{".write(to: hintsDirectory.appendingPathComponent("bad-hint.json"), atomically: true, encoding: .utf8)

            let library = try ContentLibrary.load(fromDirectory: root)

            XCTAssertEqual(library.questionHints.count, 0)
            XCTAssertEqual(library.lessons.count, 8)
            XCTAssertEqual(library.questions.count, 1)
        }
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

func repoRootURL() throws -> URL {
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
