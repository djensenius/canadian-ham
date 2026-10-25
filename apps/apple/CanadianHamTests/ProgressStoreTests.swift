@testable import CanadianHam
import CanadianHamContent
import CanadianHamEngine
import CanadianHamMorseEngine
import Combine
import SwiftData
import SwiftUI
import XCTest
#if os(macOS)
import AppKit
#endif

@MainActor
final class ProgressStoreTests: XCTestCase {
    func testReviewItemsUseEarlierTaughtPoolsAndFinalM1Round() throws {
        let library = try ContentLibrary.load(from: Bundle(for: Self.self))
        let ordered = library.orderedLessons()
        for quiz in library.quizzesById.values {
            let items = try buildLessonQuizItems(quiz: quiz, seed: "review-integration", library: library)
            XCTAssertEqual(items, try buildLessonQuizItems(quiz: quiz, seed: "review-integration", library: library))
            let reviews = items.filter { $0.reviewLessonId != nil }
            XCTAssertEqual(reviews.count, quiz.lessonId == ordered.first?.id ? 0 : 2, quiz.id)
            let index = try XCTUnwrap(ordered.firstIndex { $0.id == quiz.lessonId })
            for review in reviews {
                let sourceId = try XCTUnwrap(review.reviewLessonId)
                XCTAssertLessThan(try XCTUnwrap(ordered.firstIndex { $0.id == sourceId }), index)
                let questionId = try XCTUnwrap(review.questionID)
                let question = try XCTUnwrap(library.questions.first { $0.id == questionId })
                XCTAssertTrue(try XCTUnwrap(library.lessonsById[sourceId]).covers.contains(question.subsectionId))
                XCTAssertFalse(try XCTUnwrap(library.lessonsById[quiz.lessonId]).covers.contains(question.subsectionId))
                XCTAssertFalse(quiz.officialQuestionIds.contains(questionId))
            }
            if let rounds = quiz.rounds {
                let round = try XCTUnwrap(lessonQuizRoundProgress(quiz: quiz, items: items, currentIndex: items.count - 1))
                XCTAssertEqual(round.round.title.en, "Review")
                XCTAssertEqual(round.round.title.fr, "Révision")
                XCTAssertEqual(round.questionCount, 2)
                XCTAssertEqual(round.roundCount, rounds.count + 1)
            }
        }
    }

    func testReviewSourceMayDifferFromCanonicalHintLessonWithAuthoredSectionAnchor() throws {
        let library = try ContentLibrary.load(from: Bundle(for: Self.self))
        let questionID = "B-002-007-003"
        // Simulate overlapping taught pools: attribution follows proximity, hints keep authored anchors.
        let reviews = try selectLessonReviewItems(orderedPools: [
            LessonReviewPool(lessonId: "L-002-02", questionIds: [questionID]),
            LessonReviewPool(lessonId: "L-002-03", questionIds: [questionID]),
            LessonReviewPool(lessonId: "L-001-01", questionIds: [])
        ], lessonId: "L-001-01", excludedQuestionIds: [], seed: "shared-hint-target")
        let review = try XCTUnwrap(reviews.first)
        XCTAssertEqual(review.lessonId, "L-002-03")
        let hint = try XCTUnwrap(library.questionHintsByQuestionId[questionID])
        XCTAssertEqual(hint.lessonLink.lessonId, "L-002-02")
        let target = try XCTUnwrap(library.lessonsById[hint.lessonLink.lessonId])
        let source = try XCTUnwrap(library.lessonsById[review.lessonId])
        let anchor = try XCTUnwrap(hint.lessonLink.sectionAnchor)
        XCTAssertTrue(try LessonHeadingAnchors.anchors(for: target.bodyMarkdown, title: target.title.en).contains(anchor))
        XCTAssertFalse(try LessonHeadingAnchors.anchors(for: source.bodyMarkdown, title: source.title.en).contains(anchor))
    }

    func testReviewAttemptPayloadImportSyncAndLegacyVersionRejection() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let store = try ProgressStoreService.inMemoryForTests()
        let attempt = LessonQuizAttempt(
            id: "review-attempt", quizId: "QZ-L-005-02-A", lessonId: "L-005-02",
            submittedAt: "2026-01-02T03:45:00.000Z", correct: 1, total: 2, percent: 50,
            officialQuestionIds: ["B-005-004-001"], incorrectOfficialQuestionIds: ["B-005-001-001"],
            incorrectConceptCheckIds: [], answeredWithHelpIds: ["B-005-001-001"], reviewQuestionIds: ["B-005-001-001"]
        )
        XCTAssertEqual(try JSONDecoder().decode(LessonQuizAttempt.self, from: JSONEncoder().encode(attempt)), attempt)
        try store.saveLessonQuizAttempt(attempt, questionProgress: [])
        XCTAssertEqual(try store.lessonQuizAttempts(), [attempt])
        let exported = try store.exportData(bank: bank, exportedAt: "2026-01-04T00:00:00.000Z")
        let target = try ProgressStoreService.inMemoryForTests()
        try target.importData(exported, bank: bank)
        XCTAssertEqual(try target.lessonQuizAttempts(), [attempt])
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(exported)) as? [String: Any])
        json.removeValue(forKey: "syncDeviceRows")
        for version in [nil, 1, 2] as [Int?] {
            json["lessonIdVersion"] = version
            let imported = try JSONDecoder().decode(ProgressExportV1.self, from: JSONSerialization.data(withJSONObject: json))
            XCTAssertEqual(store.validate(imported, bank: bank).isEmpty, version == 2)
            if version != 2 { XCTAssertThrowsError(try target.importData(imported, bank: bank)) }
        }
        let rowAttempt = try JSONSerialization.jsonObject(with: JSONEncoder().encode(attempt))
        for version in [nil, 1, 2] as [Int?] {
            var row: [String: Any] = ["deviceId": "web", "attempt": rowAttempt]
            row["lessonIdVersion"] = version
            json["lessonIdVersion"] = 2
            json["syncDeviceRows"] = ["questionProgress": [], "examAttempts": [], "lessonProgress": [], "lessonQuizAttempts": [row], "morseCourseProgress": []]
            let imported = try JSONDecoder().decode(ProgressExportV1.self, from: JSONSerialization.data(withJSONObject: json))
            XCTAssertEqual(store.validate(imported, bank: bank).isEmpty, version == 2, "Sync row review version")
            if version != 2 { XCTAssertThrowsError(try target.importData(imported, bank: bank)) }
        }
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(attempt)) as? [String: Any])
        XCTAssertFalse(LessonQuizAttempt.validReviewQuestionIds(["A-001-001-001"], officialQuestionIds: []))
        let invalidIds: [Any] = [["A-001-001-001"], ["B-005-001-001", "B-005-001-001"], ["B-005-004-001"], ["QZ-L-005-01-A-C1"], NSNull()]
        for ids in invalidIds {
            payload["reviewQuestionIds"] = ids
            XCTAssertThrowsError(try JSONDecoder().decode(LessonQuizAttempt.self, from: JSONSerialization.data(withJSONObject: payload)))
        }
        payload.removeValue(forKey: "reviewQuestionIds")
        payload.removeValue(forKey: "answeredWithHelpIds")
        XCTAssertNil(try JSONDecoder().decode(LessonQuizAttempt.self, from: JSONSerialization.data(withJSONObject: payload)).reviewQuestionIds)
    }

    func testLegacyEmptyReviewQuestionIdsImportAtTopLevelAndInSyncRows() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let store = try ProgressStoreService.inMemoryForTests()
        let attempt = LessonQuizAttempt(
            id: "legacy-empty-reviews", quizId: "QZ-L-005-01-A", lessonId: "L-005-01",
            submittedAt: "2026-01-02T03:45:00.000Z", correct: 1, total: 1, percent: 100,
            officialQuestionIds: ["B-005-001-001"], incorrectOfficialQuestionIds: [],
            incorrectConceptCheckIds: [], reviewQuestionIds: []
        )
        try store.saveLessonQuizAttempt(attempt, questionProgress: [])
        let exported = try store.exportData(bank: bank, exportedAt: "2026-01-04T00:00:00.000Z")
        let encoded = try JSONEncoder().encode(exported)
        let rowAttempt = try JSONSerialization.jsonObject(with: JSONEncoder().encode(attempt))
        for version in [nil, 1] as [Int?] {
            for sync in [false, true] {
                var json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
                json["lessonIdVersion"] = version
                json.removeValue(forKey: "syncDeviceRows")
                if sync {
                    var row: [String: Any] = ["deviceId": "web", "attempt": rowAttempt]
                    row["lessonIdVersion"] = version
                    json["syncDeviceRows"] = ["questionProgress": [], "examAttempts": [], "lessonProgress": [], "lessonQuizAttempts": [row], "morseCourseProgress": []]
                }
                let imported = try JSONDecoder().decode(ProgressExportV1.self, from: JSONSerialization.data(withJSONObject: json))
                XCTAssertTrue(store.validate(imported, bank: bank).isEmpty)
                let target = try ProgressStoreService.inMemoryForTests()
                try target.importData(imported, bank: bank)
                XCTAssertEqual(try target.lessonQuizAttempts().first?.reviewQuestionIds, [])
            }
        }
    }

    func testM1QuizRoundsRetainEveryItemAndSeededOrderWithinTeachingSections() throws {
        let library = try ContentLibrary.load(from: Bundle(for: Self.self))
        var total = 0
        for quiz in library.quizzesById.values where quiz.lessonId.hasPrefix("L-001-") {
            let rounds = try XCTUnwrap(quiz.rounds)
            let legacy = LessonQuiz(id: quiz.id, lessonId: quiz.lessonId, officialQuestionIds: quiz.officialQuestionIds, conceptChecks: quiz.conceptChecks)
            let original = try buildLessonQuizItems(quiz: legacy, seed: "m1-rounds")
            let items = try buildLessonQuizItems(quiz: quiz, seed: "m1-rounds")
            XCTAssertEqual(items, try buildLessonQuizItems(quiz: quiz, seed: "m1-rounds"))
            XCTAssertEqual(items.count, quiz.officialQuestionIds.count)
            XCTAssertEqual(Set(items.compactMap(\.questionID)), Set(quiz.officialQuestionIds))
            XCTAssertEqual(items, rounds.flatMap { round in original.filter { item in
                item.questionID.map { round.officialQuestionIds.contains($0) } ?? false
            } })
            for index in items.indices {
                let round = try XCTUnwrap(lessonQuizRoundProgress(quiz: quiz, items: items, currentIndex: index))
                XCTAssertTrue(round.round.officialQuestionIds.contains(try XCTUnwrap(items[index].questionID)))
                XCTAssertEqual(round.questionCount, round.round.officialQuestionIds.count)
                XCTAssertTrue((round.startIndex...round.endIndex).contains(index))
            }
            total += items.count
        }
        XCTAssertEqual(total, 199)
        let nonM1 = try XCTUnwrap(library.quizzesById["QZ-L-005-01-A"])
        XCTAssertNil(nonM1.rounds)
        XCTAssertNil(lessonQuizRoundProgress(quiz: nonM1, items: try buildLessonQuizItems(quiz: nonM1, seed: "unchanged"), currentIndex: 0))
    }

    func testQuizRoundsWithConceptChecksKeepTheCompleteUngroupedOrder() throws {
        let library = try ContentLibrary.load(from: Bundle(for: Self.self))
        let legacy = try XCTUnwrap(library.quizzesById["QZ-L-005-01-A"])
        XCTAssertFalse(legacy.conceptChecks.isEmpty)
        let mixed = LessonQuiz(
            id: legacy.id, lessonId: legacy.lessonId, officialQuestionIds: legacy.officialQuestionIds,
            conceptChecks: legacy.conceptChecks,
            rounds: [LessonQuizRound(sectionAnchor: "invalid-mixed-round", title: LocalizedNullableText(en: "Mixed", fr: nil), officialQuestionIds: legacy.officialQuestionIds)]
        )
        let items = try buildLessonQuizItems(quiz: mixed, seed: "mixed-rounds")
        XCTAssertEqual(items, try buildLessonQuizItems(quiz: legacy, seed: "mixed-rounds"))
        XCTAssertEqual(items.count, legacy.officialQuestionIds.count + legacy.conceptChecks.count)
        for index in items.indices {
            XCTAssertNil(lessonQuizRoundProgress(quiz: mixed, items: items, currentIndex: index))
        }
    }

    func testM1QuizRoundBoundariesPreserveOneSessionAnswersHelpAndDismissedCheckpoint() throws {
        let library = try ContentLibrary.load(from: Bundle(for: Self.self))
        let quiz = try XCTUnwrap(library.quizzesById["QZ-L-001-01-A"])
        let cache = LessonQuizSessionStateCache()
        let state = cache.state(for: quiz.id)
        state.items = try buildLessonQuizItems(quiz: quiz, seed: "m1-rounds")
        func position() -> LessonQuizRoundPosition {
            LessonQuizRoundPosition(
                roundIndex: lessonQuizRoundProgress(quiz: quiz, items: state.items, currentIndex: state.currentIndex)?.roundIndex,
                checkpointVisible: state.checkpointVisible
            )
        }
        let initialPosition = position()
        XCTAssertNil(initialPosition.focusTarget(from: nil), "Opening a quiz must not request round focus")
        XCTAssertNil(initialPosition.focusTarget(from: LessonQuizRoundPosition(roundIndex: nil, checkpointVisible: false)), "Loading items must not request round focus")
        let generation = state.generation
        let first = try XCTUnwrap(state.items.first)
        XCTAssertTrue(state.qualifyHint(for: first))
        state.select(0, for: first)
        let firstRound = try XCTUnwrap(lessonQuizRoundProgress(quiz: quiz, items: state.items, currentIndex: 0))
        for _ in 0..<firstRound.endIndex {
            let previous = position()
            state.next(in: quiz)
            XCTAssertNil(position().focusTarget(from: previous), "Next within a round keeps normal focus")
        }
        let beforePrevious = position()
        state.previous()
        XCTAssertNil(position().focusTarget(from: beforePrevious), "Previous within a round keeps normal focus")
        state.next(in: quiz)
        XCTAssertFalse(state.checkpointVisible)
        let beforeCheckpoint = position()
        state.next(in: quiz)
        XCTAssertEqual(position().focusTarget(from: beforeCheckpoint), .checkpoint)
        XCTAssertTrue(state.checkpointVisible)
        XCTAssertEqual(state.currentIndex, firstRound.endIndex)
        XCTAssertEqual(state.selectedByItemId.count, 1)
        let checkpointPosition = position()
        state.previous()
        XCTAssertNil(position().focusTarget(from: checkpointPosition), "Dismissing a checkpoint stays in the same round")
        XCTAssertFalse(state.checkpointVisible)
        XCTAssertEqual(state.currentIndex, firstRound.endIndex)
        state.next(in: quiz)
        let beforeContinue = position()
        state.continueRound()
        XCTAssertEqual(position().focusTarget(from: beforeContinue), .question, "Continue focuses the new round heading")
        XCTAssertEqual(state.currentIndex, firstRound.endIndex + 1)
        XCTAssertFalse(state.checkpointVisible)
        XCTAssertTrue(cache.state(for: quiz.id) === state)
        XCTAssertEqual(state.generation, generation)
        XCTAssertEqual(state.selectedByItemId[first.id], 0)
        XCTAssertEqual(state.answeredWithHelpIds, [try XCTUnwrap(first.questionID)])
        let beforeCrossingBack = position()
        state.previous()
        XCTAssertEqual(position().focusTarget(from: beforeCrossingBack), .question, "Previous across a round boundary focuses its heading")
        XCTAssertEqual(state.currentIndex, firstRound.endIndex)
        state.currentIndex = state.items.count - 1
        state.next(in: quiz)
        XCTAssertEqual(state.currentIndex, state.items.count - 1)
        XCTAssertFalse(state.checkpointVisible, "The final round keeps final Submit, not an extra checkpoint")
    }

    func testLessonQuizHelpFixtureValidationAndPayloadRoundTrips() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let fixtureURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "fixtures/lesson-quiz-help.json")
        let fixture = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: fixtureURL)) as? [String: Any])
        let base = try XCTUnwrap(fixture["attempt"] as? [String: Any])
        let valid = try XCTUnwrap(fixture["validHelpIds"] as? [[String]])
        let invalid = try XCTUnwrap(fixture["invalidHelpIds"] as? [Any])
        let store = try ProgressStoreService.inMemoryForTests()
        let emptyExport = try store.exportData(bank: bank, exportedAt: "2026-01-04T00:00:00.000Z")
        let emptyJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(emptyExport)) as? [String: Any])
        for value in [nil] + valid.map { Optional<Any>($0) } + invalid.map { Optional<Any>($0) } {
            var attemptJSON = base
            if let value { attemptJSON["answeredWithHelpIds"] = value }
            let attemptData = try JSONSerialization.data(withJSONObject: attemptJSON)
            let expectedValid = value == nil || (value as? [String]).map(valid.contains) == true
            var exportJSON = emptyJSON
            exportJSON.removeValue(forKey: "syncDeviceRows")
            exportJSON["lessonQuizAttempts"] = [attemptJSON]
            let imported = try JSONDecoder().decode(ProgressExportV1.self, from: JSONSerialization.data(withJSONObject: exportJSON))
            XCTAssertEqual(store.validate(imported, bank: bank).isEmpty, expectedValid, "Top-level help IDs: \(String(describing: value))")
            let rowJSON: [String: Any] = ["deviceId": "web", "lessonIdVersion": 2, "attempt": attemptJSON]
            let rowData = try JSONSerialization.data(withJSONObject: rowJSON)
            if expectedValid {
                let attempt = try JSONDecoder().decode(LessonQuizAttempt.self, from: attemptData)
                let row = try JSONDecoder().decode(DeviceLessonQuizAttemptRecord.self, from: rowData)
                XCTAssertEqual(row.attempt, attempt)
                XCTAssertEqual(try JSONDecoder().decode(LessonQuizAttempt.self, from: JSONEncoder().encode(attempt)), attempt)
                try store.saveLessonQuizAttempt(attempt, questionProgress: [])
                XCTAssertEqual(try store.lessonQuizAttempts(), [attempt], "payloadData retains the field")
                let exported = try store.exportData(bank: bank, exportedAt: "2026-01-04T00:00:00.000Z")
                XCTAssertEqual(exported.syncDeviceRows?.lessonQuizAttempts.map(\.attempt), [attempt])
                let target = try ProgressStoreService.inMemoryForTests()
                let wireExport = try JSONDecoder().decode(ProgressExportV1.self, from: JSONEncoder().encode(exported))
                try target.importData(wireExport, bank: bank)
                XCTAssertEqual(try target.lessonQuizAttempts(), [attempt])
                XCTAssertEqual(try target.exportData(bank: bank, exportedAt: exported.exportedAt).lessonQuizAttempts, exported.lessonQuizAttempts)
                // Also exercise web top-level-only import, rather than only Apple device rows.
                try target.importData(imported, bank: bank)
                XCTAssertEqual(try target.lessonQuizAttempts(), [attempt])
            } else {
                XCTAssertThrowsError(try JSONDecoder().decode(LessonQuizAttempt.self, from: attemptData))
                XCTAssertThrowsError(try JSONDecoder().decode(DeviceLessonQuizAttemptRecord.self, from: rowData))
                XCTAssertThrowsError(try store.importData(imported, bank: bank))
            }
        }
    }

    func testLessonQuizHelpValidationUsesOfficialMembershipAndKnownBankIdsNotBasicPrefix() throws {
        let questionID = "A-001-001-001"
        let attempt = LessonQuizAttempt(
            id: "non-basic-help", quizId: "QZ-L-005-01-A", lessonId: "L-005-01",
            submittedAt: "2026-01-02T03:45:00.000Z", correct: 1, total: 1, percent: 100,
            officialQuestionIds: [questionID], incorrectOfficialQuestionIds: [], incorrectConceptCheckIds: [],
            answeredWithHelpIds: [questionID]
        )
        XCTAssertTrue(LessonQuizAttempt.validAnsweredWithHelpIds([questionID], officialQuestionIds: [questionID]))
        XCTAssertFalse(LessonQuizAttempt.validAnsweredWithHelpIds([questionID], officialQuestionIds: ["B-005-001-001"]))
        XCTAssertFalse(LessonQuizAttempt.validAnsweredWithHelpIds(["QZ-L-005-01-A-C1"], officialQuestionIds: [questionID]))
        let data = try JSONEncoder().encode(attempt)
        XCTAssertEqual(try JSONDecoder().decode(LessonQuizAttempt.self, from: data), attempt,
                       "Attempt decoding uses official membership, not a bank-specific prefix")

        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let store = try ProgressStoreService.inMemoryForTests()
        let exported = try store.exportData(bank: bank, exportedAt: "2026-01-04T00:00:00.000Z")
        var exportJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(exported)) as? [String: Any])
        exportJSON.removeValue(forKey: "syncDeviceRows")
        exportJSON["lessonQuizAttempts"] = [try JSONSerialization.jsonObject(with: data)]
        let imported = try JSONDecoder().decode(ProgressExportV1.self, from: JSONSerialization.data(withJSONObject: exportJSON))
        XCTAssertTrue(store.validate(imported, bank: bank).contains { $0.contains(".answeredWithHelpIds") },
                      "Official membership alone must not allow IDs unknown to the active bank")
        XCTAssertThrowsError(try store.importData(imported, bank: bank))
    }

    func testLessonQuizHintVisibilityUsesHalfSecondAndFreezesHelpAtChoice() async throws {
        let state = LessonQuizSessionState()
        let item = LessonQuizRuntimeItem.official(id: "official", questionId: "B-005-001-001", choicePermutation: [0, 1, 2, 3])
        state.items = [item]
        let timer = HintVisibilityQualificationTimer()
        XCTAssertEqual(HintVisibilityQualificationTimer.defaultDelayNanoseconds, 500_000_000)
        let shortPeekStart = ContinuousClock.now
        timer.begin(questionID: "B-005-001-001", canRecordHelp: true, alreadyQualified: false) {
            state.qualifyHint(for: item)
        }
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertLessThan(shortPeekStart.duration(to: .now), .milliseconds(500), "The unqualified check must occur before the half-second threshold")
        XCTAssertTrue(state.hintQualifiedQuestionIds.isEmpty)
        state.select(0, for: item)
        try await Task.sleep(nanoseconds: 1_250_000_000)
        XCTAssertTrue(state.answeredWithHelpIds.isEmpty, "A later timer must not change an already-scored answer")
        XCTAssertFalse(state.qualifyHint(for: item))
        timer.cancel()

        let helped = LessonQuizSessionState()
        helped.items = [item]
        timer.begin(questionID: "B-005-001-001", canRecordHelp: true, alreadyQualified: false) {
            helped.qualifyHint(for: item)
        }
        try await Task.sleep(nanoseconds: 1_250_000_000)
        XCTAssertEqual(helped.hintQualifiedQuestionIds, ["B-005-001-001"])
        XCTAssertTrue(helped.answeredWithHelpIds.isEmpty, "Qualification alone is not an answered record")
        helped.select(0, for: item)
        XCTAssertEqual(helped.answeredWithHelpIds, ["B-005-001-001"])
        helped.select(1, for: item)
        XCTAssertEqual(helped.selectedByItemId[item.id], 0, "Choices are frozen after revealing correctness")
        helped.submittedAttemptID = "saved"
        XCTAssertFalse(helped.qualifyHint(for: item))
        timer.cancel()
    }

    func testLessonQuizSessionCachePreservesAnswersAndFrozenHelpAcrossNavigation() {
        let cache = LessonQuizSessionStateCache()
        let session = cache.state(for: "QZ-L-005-01-A")
        session.items = [.official(id: "item", questionId: "B-005-001-001", choicePermutation: [2, 0, 3, 1])]
        session.currentIndex = 0
        session.hintLevelsByQuestionId["B-005-001-001"] = 2
        session.hintQualifiedQuestionIds.insert("B-005-001-001")
        session.selectedByItemId["item"] = 0
        session.answeredWithHelpIds.insert("B-005-001-001")
        XCTAssertTrue(cache.state(for: "QZ-L-005-01-A") === session)
        XCTAssertEqual(cache.state(for: "QZ-L-005-01-A").items, session.items)
        XCTAssertEqual(cache.state(for: "QZ-L-005-01-A").selectedByItemId["item"], 0)
        XCTAssertEqual(cache.state(for: "QZ-L-005-01-A").hintLevelsByQuestionId["B-005-001-001"], 2)
        XCTAssertEqual(cache.state(for: "QZ-L-005-01-A").answeredWithHelpIds, ["B-005-001-001"])
        XCTAssertFalse(cache.state(for: "QZ-L-005-02-A") === session)
        cache.clear()
        XCTAssertFalse(cache.state(for: "QZ-L-005-01-A") === session)
    }

#if os(macOS)
    func testMountedLessonQuizRepopulatesAfterImportAndResetWithoutReshufflingOnRerender() async throws {
        let bank = try CanadianHam.QuestionBankStore.load(from: Bundle(for: Self.self))
        let library = try ContentLibrary.load(from: Bundle(for: Self.self))
        let quiz = try XCTUnwrap(library.quizzesById["QZ-L-005-01-A"])
        let lesson = try XCTUnwrap(library.lessonsById[quiz.lessonId])
        let store = try CanadianHam.ProgressStoreService.inMemoryForTests()
        let exported = try store.exportData(bank: bank, exportedAt: "2026-01-04T00:00:00.000Z")
        let cache = LessonQuizSessionStateCache()
        let screen = LessonQuizScreen(
            quiz: quiz, lesson: lesson, bank: bank, library: library,
            progressStore: store, language: .english,
            onDataChanged: {}, onOpenHintLesson: { _ in }
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 700),
            styleMask: [.titled], backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: NavigationStack { screen }.environmentObject(cache))
        window.orderFront(nil)
        defer { window.close() }

        func waitForItems(in session: LessonQuizSessionState) async throws {
            for _ in 0..<100 where session.items.isEmpty {
                try await Task.sleep(nanoseconds: 50_000_000)
            }
            XCTAssertFalse(session.items.isEmpty, "The mounted quiz must initialize each replacement session without Retry")
        }

        var session = cache.state(for: quiz.id)
        try await waitForItems(in: session)
        let firstItem = try XCTUnwrap(session.items.first)
        session.select(0, for: firstItem)
        let generation = session.generation
        let seed = session.seed
        let items = session.items
        // Re-evaluating the mounted screen with the same cache entry must retain its quiz.
        cache.objectWillChange.send()
        try await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertEqual(cache.state(for: quiz.id).generation, generation)
        XCTAssertEqual(session.seed, seed)
        XCTAssertEqual(session.items, items)
        XCTAssertEqual(session.selectedByItemId[firstItem.id], 0)

        for replacement in ["import", "reset"] {
            if replacement == "import" {
                try store.importData(exported, bank: bank)
            } else {
                try store.resetAllData()
            }
            // RootView clears the same cache after either Settings operation on iOS and macOS.
            cache.clear()
            let next = cache.state(for: quiz.id)
            XCTAssertNotEqual(next.generation, session.generation, replacement)
            XCTAssertTrue(next.items.isEmpty, replacement)
            XCTAssertTrue(next.selectedByItemId.isEmpty, replacement)
            try await waitForItems(in: next)
            XCTAssertEqual(next.items.count, quiz.officialQuestionIds.count + quiz.conceptChecks.count)
            XCTAssertEqual(cache.state(for: quiz.id).generation, next.generation)
            session = next
        }
    }
#endif

    func testMockExamTimerRefreshPreservesFractionalRemainder() throws {
        let state = MockExamState()
        state.generatedItems = [GeneratedExamItem(
            position: 1,
            questionId: "B-001-002-002",
            subsectionId: "B-001-002",
            categoryId: "B-001",
            choicePermutation: [0, 1, 2, 3]
        )]
        let startedAt = Date(timeIntervalSince1970: 1_000)
        state.secondsElapsed = 4
        state.timerRunning = true
        state.timerRunStartedAt = startedAt

        state.refreshTimer(now: startedAt.addingTimeInterval(1.75), timerEnabled: true)

        XCTAssertEqual(state.secondsElapsed, 5)
        var timerRunStartedAt = try XCTUnwrap(state.timerRunStartedAt)
        XCTAssertEqual(timerRunStartedAt.timeIntervalSince1970, startedAt.addingTimeInterval(1).timeIntervalSince1970, accuracy: 0.000_001)

        state.refreshTimer(now: startedAt.addingTimeInterval(2.25), timerEnabled: true)

        XCTAssertEqual(state.secondsElapsed, 6)
        timerRunStartedAt = try XCTUnwrap(state.timerRunStartedAt)
        XCTAssertEqual(timerRunStartedAt.timeIntervalSince1970, startedAt.addingTimeInterval(2).timeIntervalSince1970, accuracy: 0.000_001)
    }

    func testAppSettingsModelReplacementRevisionAdvancesForLocalDataReplacement() throws {
        let appSettings = CanadianHam.AppSettingsModel()
        let initialDataRevision = appSettings.dataRevision
        let initialReplacementRevision = appSettings.localDataReplacementRevision

        appSettings.recordDataChanged()

        XCTAssertEqual(appSettings.dataRevision, initialDataRevision + 1)
        XCTAssertEqual(appSettings.localDataReplacementRevision, initialReplacementRevision)

        appSettings.recordDataChanged(replacesLocalData: true)

        XCTAssertEqual(appSettings.dataRevision, initialDataRevision + 2)
        XCTAssertEqual(appSettings.localDataReplacementRevision, initialReplacementRevision + 1)
    }

    func testAppSettingsModelTracksUnfinishedCourseWorkAcrossRegisteredWindows() throws {
        let appSettings = CanadianHam.AppSettingsModel()
        let firstWindow = UUID()
        let secondWindow = UUID()
        var firstUnfinished = true
        var secondUnfinished = false

        appSettings.registerUnfinishedCourseWorkCheck(id: firstWindow) { firstUnfinished }
        appSettings.registerUnfinishedCourseWorkCheck(id: secondWindow) { secondUnfinished }

        XCTAssertTrue(appSettings.hasAnyUnfinishedCourseWork)

        firstUnfinished = false
        XCTAssertFalse(appSettings.hasAnyUnfinishedCourseWork)

        secondUnfinished = true
        XCTAssertTrue(appSettings.hasAnyUnfinishedCourseWork)

        appSettings.unregisterUnfinishedCourseWorkCheck(id: secondWindow)
        XCTAssertFalse(appSettings.hasAnyUnfinishedCourseWork)
    }

    func testSharedAppleSettingsModelAppliesLivePreferenceUpdates() throws {
        let store = try CanadianHam.ProgressStoreService.inMemoryForTests()
        let appSettings = CanadianHam.AppSettingsModel()
        appSettings.progressStore = store
        let initialRevision = appSettings.dataRevision
        let publishExpectation = expectation(description: "AppSettingsModel publishes forwarded progress-store changes")
        let revisionExpectation = expectation(description: "AppSettingsModel advances its data revision")
        let objectChangeCancellable = appSettings.objectWillChange.sink { publishExpectation.fulfill() }
        let revisionCancellable = appSettings.$dataRevision.dropFirst().sink { revision in
            if revision > initialRevision {
                revisionExpectation.fulfill()
            }
        }

        var preferences = store.preferences
        preferences.language = .french
        preferences.theme = .dark
        preferences.practiceMode = .reviewLater
        try store.updatePreferences(preferences)

        wait(for: [publishExpectation, revisionExpectation], timeout: 2)
        let observedStore = try XCTUnwrap(appSettings.progressStore)
        XCTAssertEqual(observedStore.preferences.language, .french)
        XCTAssertEqual(observedStore.preferences.theme, .dark)
        XCTAssertEqual(observedStore.preferences.practiceMode, .reviewLater)
        XCTAssertGreaterThan(appSettings.dataRevision, initialRevision)
        objectChangeCancellable.cancel()
        revisionCancellable.cancel()
    }

    func testICloudSyncConfigurationPlanDefaultsOffAndKeepsPreferencesLocal() throws {
        let offPlan = ProgressStoreService.configurationPlan(iCloudSyncEnabled: false, buildEnabled: true)
        XCTAssertEqual(offPlan.progressDatabase, .none)
        XCTAssertEqual(offPlan.preferencesDatabase, .none)

        let onPlan = ProgressStoreService.configurationPlan(iCloudSyncEnabled: true, buildEnabled: true)
        XCTAssertEqual(onPlan.progressDatabase, .privateDatabase(ICloudSyncSettings.containerIdentifier))
        XCTAssertEqual(onPlan.preferencesDatabase, .none)

        let defaultBuildPlan = ProgressStoreService.configurationPlan(iCloudSyncEnabled: true, buildEnabled: false)
        XCTAssertEqual(defaultBuildPlan.progressDatabase, .none)
        XCTAssertEqual(defaultBuildPlan.preferencesDatabase, .none)
    }

    @MainActor
    func testResetAllDataTurnsICloudSyncOptInOff() throws {
        let (defaults, suiteName) = try temporaryDefaultsSuite(prefix: "resetOptIn")
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = try ProgressStoreService.inMemoryForTests(defaults: defaults, defaultsDomainName: suiteName)
        store.updateICloudSyncOptIn(true, defaults: defaults)
        XCTAssertTrue(ICloudSyncSettings.storedOptIn(defaults: defaults))

#if ICLOUD_SYNC
        XCTAssertThrowsError(try store.resetAllData(defaults: defaults)) { error in
            XCTAssertEqual(error as? ProgressStoreError, .cloudResetRequiresAsyncDeletion)
        }
        XCTAssertTrue(ICloudSyncSettings.storedOptIn(defaults: defaults), "Gated builds must use the cloud deletion reset flow before clearing opt-in")
        XCTAssertTrue(store.isICloudSyncEnabled)
#else
        try store.resetAllData(defaults: defaults)

        XCTAssertFalse(ICloudSyncSettings.storedOptIn(defaults: defaults), "Reset all data must turn the iCloud opt-in off")
        XCTAssertFalse(store.isICloudSyncEnabled)
#endif
    }

    func testResetAllDataWithICloudSyncDeletesCloudZoneThenWipesLocalData() async throws {
        let defaultsSuiteName = "ProgressStoreTests.resetICloud.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsSuiteName))
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }
        let store = try ProgressStoreService.inMemoryForTests(iCloudSyncEnabled: true, layout: .split)
        let record = QuestionProgressRecord(
            questionId: "B-001-001-001",
            bankId: basicBankId,
            attempts: 1,
            correctAttempts: 1,
            lastAttemptedAt: "2026-01-02T03:04:05.000Z",
            lastResult: .correct,
            recentResults: [true],
            leitner: LeitnerState(box: 1, dueAt: "2026-01-03T03:04:05.000Z")
        )
        try store.saveQuestionProgress([record])
        ICloudSyncSettings.setStoredOptIn(true, defaults: defaults)
        var zoneDeleteSawLocalOnlyBeforeWipe = false
        let client = ICloudProgressDeletionClient(deletePrivateDatabaseProgressZones: {
            zoneDeleteSawLocalOnlyBeforeWipe = !store.isICloudSyncEnabled && ((try? store.questionProgressRecords()) == [record])
        })

        try await store.resetAllData(client: client, defaults: defaults)

        XCTAssertTrue(zoneDeleteSawLocalOnlyBeforeWipe)
        XCTAssertFalse(ICloudSyncSettings.storedOptIn(defaults: defaults))
        XCTAssertEqual(try store.questionProgressRecords(), [])
    }

    func testResetAllDataWithICloudSyncKeepsLocalDataAndRetriesAfterCloudDeleteFailure() async throws {
        enum Offline: Error, Equatable { case unavailable }
        let defaultsSuiteName = "ProgressStoreTests.resetICloudFailure.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsSuiteName))
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }
        let store = try ProgressStoreService.inMemoryForTests(iCloudSyncEnabled: true, layout: .split)
        let record = QuestionProgressRecord(
            questionId: "B-001-001-001",
            bankId: basicBankId,
            attempts: 1,
            correctAttempts: 1,
            lastAttemptedAt: "2026-01-02T03:04:05.000Z",
            lastResult: .correct,
            recentResults: [true],
            leitner: LeitnerState(box: 1, dueAt: "2026-01-03T03:04:05.000Z")
        )
        try store.saveQuestionProgress([record])
        ICloudSyncSettings.setStoredOptIn(true, defaults: defaults)
        var attempts = 0
        let client = ICloudProgressDeletionClient(deletePrivateDatabaseProgressZones: {
            attempts += 1
            if attempts == 1 { throw Offline.unavailable }
        })

        do {
            try await store.resetAllData(client: client, defaults: defaults)
            XCTFail("Expected the first cloud-zone deletion to fail")
        } catch {
            XCTAssertEqual(error as? Offline, .unavailable)
        }
        XCTAssertEqual(try store.questionProgressRecords(), [record])
        XCTAssertTrue(ICloudSyncSettings.pendingProgressZoneDeletion(defaults: defaults))

        let relaunchedStore = try ProgressStoreService.inMemoryForTests(iCloudSyncEnabled: false, layout: .split)
        try await relaunchedStore.resetAllData(client: client, defaults: defaults)

        XCTAssertEqual(attempts, 2)
        XCTAssertFalse(ICloudSyncSettings.pendingProgressZoneDeletion(defaults: defaults))
    }

    func testSharedICloudMergeFixtureCoversQuestionExamLessonAndMorseRules() throws {
        struct Fixture: Decodable {
            struct QuestionProgress: Decodable {
                let deviceRows: [DeviceQuestionProgressRecord]
                let expected: [QuestionProgressRecord]
            }
            struct ExamAttempts: Decodable {
                let deviceRows: [DeviceExamAttemptRecord]
                let expectedIdsBySubmittedAt: [String: String]
            }
            struct LessonProgress: Decodable {
                let deviceRows: [DeviceLessonProgressRecord]
                let expected: [LessonProgressRecord]
            }
            struct MorseProgress: Decodable {
                let deviceRows: [DeviceMorseCourseProgressRecord]
                let expected: MorseCourseProgressExport
            }
            let questionProgress: QuestionProgress
            let examAttempts: ExamAttempts
            let lessonProgress: LessonProgress
            let morseCourseProgress: MorseProgress
        }
        let fixtureURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "fixtures/progress/icloud-merge.json")
        let fixture = try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: fixtureURL))

        XCTAssertEqual(ProgressSyncMerge.deduplicateDeviceQuestionProgress(fixture.questionProgress.deviceRows), fixture.questionProgress.expected)
        let examAttempts = ProgressSyncMerge.deduplicateDeviceExamAttempts(fixture.examAttempts.deviceRows)
        XCTAssertEqual(Dictionary(uniqueKeysWithValues: examAttempts.map { ("\($0.bankId)|\($0.submittedAt)", $0.id) }), fixture.examAttempts.expectedIdsBySubmittedAt)
        XCTAssertEqual(ProgressSyncMerge.deduplicateDeviceLessonProgress(fixture.lessonProgress.deviceRows), fixture.lessonProgress.expected)
        XCTAssertEqual(ProgressSyncMerge.mergeDeviceMorseCourseProgress(fixture.morseCourseProgress.deviceRows), fixture.morseCourseProgress.expected)
    }

    func testICloudMergeFixtureIsPermutationIndependentAndIdempotent() throws {
        struct Fixture: Decodable {
            struct QuestionProgress: Decodable { let deviceRows: [DeviceQuestionProgressRecord]; let expected: [QuestionProgressRecord] }
            struct LessonProgress: Decodable { let deviceRows: [DeviceLessonProgressRecord]; let expected: [LessonProgressRecord] }
            struct MorseProgress: Decodable { let deviceRows: [DeviceMorseCourseProgressRecord]; let expected: MorseCourseProgressExport }
            let questionProgress: QuestionProgress
            let lessonProgress: LessonProgress
            let morseCourseProgress: MorseProgress
        }
        let fixtureURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "fixtures/progress/icloud-merge.json")
        let fixture = try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: fixtureURL))

        XCTAssertEqual(ProgressSyncMerge.deduplicateDeviceQuestionProgress(Array(fixture.questionProgress.deviceRows.reversed())), fixture.questionProgress.expected)
        XCTAssertEqual(ProgressSyncMerge.deduplicateDeviceQuestionProgress(fixture.questionProgress.deviceRows + fixture.questionProgress.deviceRows), fixture.questionProgress.expected)
        XCTAssertEqual(ProgressSyncMerge.deduplicateDeviceLessonProgress(Array(fixture.lessonProgress.deviceRows.reversed())), fixture.lessonProgress.expected)
        XCTAssertEqual(ProgressSyncMerge.deduplicateDeviceLessonProgress(fixture.lessonProgress.deviceRows + fixture.lessonProgress.deviceRows), fixture.lessonProgress.expected)
        XCTAssertEqual(ProgressSyncMerge.mergeDeviceMorseCourseProgress(Array(fixture.morseCourseProgress.deviceRows.reversed())), fixture.morseCourseProgress.expected)
        XCTAssertEqual(ProgressSyncMerge.mergeDeviceMorseCourseProgress(fixture.morseCourseProgress.deviceRows + fixture.morseCourseProgress.deviceRows), fixture.morseCourseProgress.expected)
    }

    func testSavingLargeQuestionProgressBatchBuildsOneWriteContext() throws {
        let store = try ProgressStoreService.inMemoryForTests(localDeviceID: "device")
        let records = (0..<1_000).map { index in
            QuestionProgressRecord(
                questionId: String(format: "B-001-001-%03d", index + 1),
                bankId: basicBankId,
                attempts: 1,
                correctAttempts: index.isMultiple(of: 2) ? 1 : 0,
                lastAttemptedAt: "2026-01-02T03:04:05.000Z",
                lastResult: index.isMultiple(of: 2) ? .correct : .incorrect,
                recentResults: [index.isMultiple(of: 2)],
                leitner: LeitnerState(box: 1, dueAt: "2026-01-03T03:04:05.000Z")
            )
        }

        try store.saveQuestionProgress(records)

        XCTAssertEqual(store.questionProgressWriteContextBuildCountForTesting, 1)
        XCTAssertEqual(try store.questionProgressRecords().count, 1_000)
    }

    func testLocalQuestionWritesAfterDeviceRowImportAddOnlyOwnContribution() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let importedFirst = QuestionProgressRecord(
            questionId: "B-001-001-001",
            bankId: bank.manifest.bankId,
            attempts: 2,
            correctAttempts: 1,
            lastAttemptedAt: "2026-01-02T03:04:05.000Z",
            lastResult: .correct,
            recentResults: [false, true],
            leitner: LeitnerState(box: 1, dueAt: "2026-01-03T03:04:05.000Z")
        )
        let importedSecond = QuestionProgressRecord(
            questionId: "B-001-001-002",
            bankId: bank.manifest.bankId,
            attempts: 4,
            correctAttempts: 2,
            lastAttemptedAt: "2026-01-02T03:05:05.000Z",
            lastResult: .incorrect,
            recentResults: [true, false, true, false],
            leitner: LeitnerState(box: 2, dueAt: "2026-01-04T03:04:05.000Z")
        )
        let imported = ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: "2026-01-02T05:04:05.000Z",
            bankId: bank.manifest.bankId,
            questionProgress: [importedFirst, importedSecond],
            examAttempts: [],
            lessonProgress: [],
            lessonQuizAttempts: [],
            syncDeviceRows: ProgressSyncDeviceRows(
                questionProgress: [importedFirst, importedSecond].map { DeviceQuestionProgressRecord(deviceId: "iphone", record: $0) },
                examAttempts: [],
                lessonProgress: [],
                lessonQuizAttempts: [],
                morseCourseProgress: []
            ),
            preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
        )
        let store = try ProgressStoreService.inMemoryForTests(localDeviceID: "ipad")
        try store.importData(imported, bank: bank)
        let updatedFirst = QuestionProgressRecord(
            questionId: importedFirst.questionId,
            bankId: importedFirst.bankId,
            attempts: importedFirst.attempts + 1,
            correctAttempts: importedFirst.correctAttempts + 1,
            lastAttemptedAt: "2026-01-02T06:04:05.000Z",
            lastResult: .correct,
            recentResults: [false, true, true],
            leitner: LeitnerState(box: 2, dueAt: "2026-01-05T03:04:05.000Z")
        )

        try store.saveQuestionProgress([updatedFirst, importedSecond])

        let records = try store.questionProgressRecords()
        XCTAssertEqual(records.first { $0.questionId == importedFirst.questionId }, updatedFirst)
        XCTAssertEqual(records.first { $0.questionId == importedSecond.questionId }, importedSecond)
    }

    func testTwoDevicesEachQuestionWriteAddsExactlyOneAfterSync() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let base = QuestionProgressRecord(
            questionId: "B-001-001-001",
            bankId: bank.manifest.bankId,
            attempts: 2,
            correctAttempts: 1,
            lastAttemptedAt: "2026-01-02T03:04:05.000Z",
            lastResult: .correct,
            recentResults: [false, true],
            leitner: LeitnerState(box: 1, dueAt: "2026-01-03T03:04:05.000Z")
        )
        let imported = ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: "2026-01-02T05:04:05.000Z",
            bankId: bank.manifest.bankId,
            questionProgress: [base],
            examAttempts: [],
            lessonProgress: [],
            lessonQuizAttempts: [],
            syncDeviceRows: ProgressSyncDeviceRows(
                questionProgress: [DeviceQuestionProgressRecord(deviceId: "iphone", record: base)],
                examAttempts: [],
                lessonProgress: [],
                lessonQuizAttempts: [],
                morseCourseProgress: []
            ),
            preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
        )
        let ipad = try ProgressStoreService.inMemoryForTests(localDeviceID: "ipad")
        try ipad.importData(imported, bank: bank)
        let ipadWrite = QuestionProgressRecord(
            questionId: base.questionId,
            bankId: base.bankId,
            attempts: 3,
            correctAttempts: 1,
            lastAttemptedAt: "2026-01-02T06:04:05.000Z",
            lastResult: .incorrect,
            recentResults: [false, true, false],
            leitner: LeitnerState(box: 0, dueAt: "2026-01-02T06:04:05.000Z")
        )
        try ipad.saveQuestionProgress([ipadWrite])
        XCTAssertEqual(try ipad.questionProgressRecords(), [ipadWrite])

        let iphone = try ProgressStoreService.inMemoryForTests(localDeviceID: "iphone")
        try iphone.importData(try ipad.exportData(bank: bank, exportedAt: "2026-01-02T07:04:05.000Z"), bank: bank)
        let iphoneWrite = QuestionProgressRecord(
            questionId: base.questionId,
            bankId: base.bankId,
            attempts: 4,
            correctAttempts: 2,
            lastAttemptedAt: "2026-01-02T08:04:05.000Z",
            lastResult: .correct,
            recentResults: [false, true, false, true],
            leitner: LeitnerState(box: 1, dueAt: "2026-01-03T08:04:05.000Z")
        )
        try iphone.saveQuestionProgress([iphoneWrite])
        XCTAssertEqual(try iphone.questionProgressRecords(), [iphoneWrite])

        try iphone.importData(try ipad.exportData(bank: bank, exportedAt: "2026-01-02T09:04:05.000Z"), bank: bank)
        XCTAssertEqual(try iphone.questionProgressRecords(), [ipadWrite])
    }

    func testImportMigratesTask4610LessonSplitProgressAndQuizAttempts() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let legacyProgress = [
            LessonProgressRecord(lessonId: "L-005-04", readAt: "2026-01-02T03:30:00.000Z", readCount: 2),
            LessonProgressRecord(lessonId: "L-001-03", readAt: "2026-01-03T03:30:00.000Z", readCount: 1),
        ]
        let legacyAttempt = LessonQuizAttempt(
            id: "legacy-00103",
            quizId: "QZ-L-001-03-A",
            lessonId: "L-001-03",
            submittedAt: "2026-01-03T03:45:00.000Z",
            correct: 2,
            total: 2,
            percent: 100,
            officialQuestionIds: ["B-001-010-001", "B-001-014-001"],
            incorrectOfficialQuestionIds: [],
            incorrectConceptCheckIds: [],
            answeredWithHelpIds: ["B-001-010-001", "B-001-014-001"]
        )
        let imported = ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: "2026-01-04T03:45:00.000Z",
            bankId: bank.manifest.bankId,
            questionProgress: [],
            examAttempts: [],
            lessonProgress: try archivedArray(legacyProgress),
            lessonQuizAttempts: try archivedArray([legacyAttempt]),
            syncDeviceRows: ProgressSyncDeviceRows(
                questionProgress: [],
                examAttempts: [],
                lessonProgress: legacyProgress.map { DeviceLessonProgressRecord(deviceId: "iphone", record: $0) },
                lessonQuizAttempts: [DeviceLessonQuizAttemptRecord(deviceId: "iphone", attempt: legacyAttempt)],
                morseCourseProgress: []
            ),
            preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
        )
        let store = try ProgressStoreService.inMemoryForTests(localDeviceID: "ipad")

        try store.importData(imported, bank: bank)

        XCTAssertEqual(try store.lessonProgressRecords(), [
            LessonProgressRecord(lessonId: "L-001-03", readAt: "2026-01-03T03:30:00.000Z", readCount: 1),
            LessonProgressRecord(lessonId: "L-005-04", readAt: "2026-01-02T03:30:00.000Z", readCount: 2),
        ])
        XCTAssertEqual(try store.lessonQuizAttempts().map(\.answeredWithHelpIds), [["B-001-010-001"], ["B-001-014-001"]])
        XCTAssertEqual(try store.exportData(bank: bank, exportedAt: imported.exportedAt).syncDeviceRows?.lessonQuizAttempts.map { $0.attempt.answeredWithHelpIds }, [["B-001-010-001"], ["B-001-014-001"]])
        XCTAssertEqual(try store.lessonQuizAttempts().map { attempt in
            [attempt.id, attempt.quizId, attempt.lessonId, attempt.officialQuestionIds.joined(separator: ",")]
        }, [
            ["legacy-00103", "QZ-L-001-03-A", "L-001-03", "B-001-010-001"],
            ["legacy-00103::QZ-L-001-05-A", "QZ-L-001-05-A", "L-001-05", "B-001-014-001"],
        ])
    }

    func testTask4610SharedConceptMappingAndConceptInclusiveScores() throws {
        struct Case: Decodable {
            struct ConceptDestination: Decodable {
                let oldId: String
                let newId: String?
            }
            let name: String
            let attempt: LessonQuizAttempt
            let expected: [LessonQuizAttempt]
            let conceptDestinations: [ConceptDestination]
        }
        let fixtureURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "fixtures/progress/lesson-split-quiz-migration.json")
        let cases = try JSONDecoder().decode([Case].self, from: Data(contentsOf: fixtureURL))
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        for testCase in cases {
            let store = try ProgressStoreService.inMemoryForTests()
            let imported = ProgressExportV1(
                schema: "canadian-ham.progress-export", version: 1, lessonIdVersion: 1,
                exportedAt: "2026-01-04T03:45:00.000Z", bankId: bank.manifest.bankId,
                questionProgress: [], examAttempts: [], lessonProgress: [],
                lessonQuizAttempts: try archivedArray([testCase.attempt]),
                syncDeviceRows: ProgressSyncDeviceRows(
                    questionProgress: [], examAttempts: [], lessonProgress: [],
                    lessonQuizAttempts: [DeviceLessonQuizAttemptRecord(deviceId: "phone", attempt: testCase.attempt)],
                    morseCourseProgress: []
                ),
                preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
            )
            XCTAssertEqual(store.validate(imported, bank: bank), [], testCase.name)
            try store.importData(imported, bank: bank)
            XCTAssertEqual(try store.lessonQuizAttempts(), testCase.expected, testCase.name)
            XCTAssertLessThanOrEqual(try store.lessonQuizAttempts().reduce(0) { $0 + $1.correct }, testCase.attempt.correct, "\(testCase.name): original correct budget")
            let exported = try store.exportData(bank: bank, exportedAt: imported.exportedAt)
            XCTAssertEqual(exported.syncDeviceRows?.lessonQuizAttempts.map(\.attempt), testCase.expected, testCase.name)
            for mapping in testCase.conceptDestinations {
                let old = testCase.attempt
                let attempt = LessonQuizAttempt(
                    id: old.id, quizId: old.quizId, lessonId: old.lessonId, submittedAt: old.submittedAt,
                    correct: old.total - 1, total: old.total, percent: Double(old.total - 1) / Double(old.total) * 100,
                    officialQuestionIds: old.officialQuestionIds, incorrectOfficialQuestionIds: [], incorrectConceptCheckIds: [mapping.oldId]
                )
                let individual = ProgressExportV1(
                    schema: imported.schema, version: 1, lessonIdVersion: 1, exportedAt: imported.exportedAt, bankId: imported.bankId,
                    questionProgress: [], examAttempts: [], lessonProgress: [], lessonQuizAttempts: try archivedArray([attempt]), preferences: imported.preferences
                )
                try store.importData(individual, bank: bank)
                let expected = testCase.expected.map { destination in
                    let wrong = mapping.newId.map { $0.hasPrefix("\(destination.quizId)-C") ? [$0] : [] } ?? []
                    let correct = destination.total - wrong.count
                    return LessonQuizAttempt(
                        id: destination.id, quizId: destination.quizId, lessonId: destination.lessonId, submittedAt: destination.submittedAt,
                        correct: correct, total: destination.total, percent: Double(correct) / Double(destination.total) * 100,
                        officialQuestionIds: destination.officialQuestionIds, incorrectOfficialQuestionIds: [], incorrectConceptCheckIds: wrong
                    )
                }
                XCTAssertEqual(try store.lessonQuizAttempts(), expected, "Individual wrong concept \(mapping.oldId)")
            }
        }
    }

    func testTask4610LaunchMigrationIsAtomicAndStableWithArchivedProgressAndMultipleDevices() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let schema = Schema(versionedSchema: CanadianHamProgressSchemaV4.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, migrationPlan: CanadianHamProgressMigrationPlan.self, configurations: [configuration])
        let context = ModelContext(container)
        let phoneRead = LessonProgressRecord(lessonId: "L-005-04", readAt: "2026-01-02T03:30:00.000Z", readCount: 5)
        let tabletReadOnce = LessonProgressRecord(lessonId: "L-005-04", readAt: "2026-01-04T03:30:00.000Z", readCount: 1)
        let archivedRead = LessonProgressRecord(lessonId: "L-005-05", readAt: "2026-01-03T03:30:00.000Z", readCount: 2)
        let partial = LessonQuizAttempt(
            id: "partial", quizId: "QZ-L-005-04-A", lessonId: "L-005-04",
            submittedAt: "2026-01-03T03:45:00.000Z", correct: 2, total: 3, percent: 200.0 / 3,
            officialQuestionIds: ["B-005-007-001", "B-005-009-001"],
            incorrectOfficialQuestionIds: ["B-005-009-001"],
            incorrectConceptCheckIds: ["QZ-L-005-04-A-C3"]
        )
        let archivedAttempt = LessonQuizAttempt(
            id: "archived", quizId: "QZ-L-005-05-A", lessonId: "L-005-05",
            submittedAt: "2026-01-04T03:45:00.000Z", correct: 2, total: 2, percent: 100,
            officialQuestionIds: ["B-005-011-001"], incorrectOfficialQuestionIds: [], incorrectConceptCheckIds: []
        )
        for (deviceId, record) in [("phone", phoneRead), ("tablet", tabletReadOnce)] {
            context.insert(LessonProgressEntity(lessonId: record.lessonId, readAt: record.readAt, readCount: record.readCount, deviceId: deviceId))
            context.insert(LessonQuizAttemptEntity(id: partial.id, quizId: partial.quizId, lessonId: partial.lessonId, submittedAt: partial.submittedAt, payloadData: try JSONEncoder().encode(partial), deviceId: deviceId))
        }
        context.insert(PreferencesEntity(
            practiceMode: "immediate", examTimerEnabled: false, language: "system", theme: "system",
            archivedLessonProgressData: try JSONEncoder().encode(try archivedArray([archivedRead])),
            archivedLessonQuizAttemptsData: try JSONEncoder().encode(try archivedArray([archivedAttempt]))
        ))
        try context.save()
        XCTAssertFalse(try context.fetch(FetchDescriptor<PreferencesEntity>()).contains { $0.key == ProgressStoreService.task4610LessonSplitMigrationMarkerKey })
        let (defaults, suiteName) = try temporaryDefaultsSuite(prefix: "task4610Launch")
        let morseURL = try temporaryMorseCourseProgressURL()
        let store = try ProgressStoreService(container: container, morseCourseProgressURL: morseURL, localDeviceID: "phone", defaults: defaults, defaultsDomainName: suiteName)
        XCTAssertEqual(try store.lessonProgressRecords(), [
            LessonProgressRecord(lessonId: "L-005-04", readAt: tabletReadOnce.readAt, readCount: 6),
            archivedRead,
            LessonProgressRecord(lessonId: "L-005-06", readAt: archivedRead.readAt, readCount: 2),
        ])
        let exported = try store.exportData(bank: bank, exportedAt: "2026-01-05T03:45:00.000Z")
        let deviceRows = try XCTUnwrap(exported.syncDeviceRows)
        XCTAssertEqual(deviceRows.lessonProgress, [
            DeviceLessonProgressRecord(deviceId: "phone", record: phoneRead, lessonIdVersion: 2),
            DeviceLessonProgressRecord(deviceId: "tablet", record: tabletReadOnce, lessonIdVersion: 2),
            DeviceLessonProgressRecord(deviceId: "phone", record: archivedRead, lessonIdVersion: 2),
            DeviceLessonProgressRecord(deviceId: "phone", record: LessonProgressRecord(lessonId: "L-005-06", readAt: archivedRead.readAt, readCount: 2), lessonIdVersion: 2),
        ])
        let expectedPartial = [
            LessonQuizAttempt(id: "partial", quizId: "QZ-L-005-04-A", lessonId: "L-005-04", submittedAt: partial.submittedAt, correct: 1, total: 1, percent: 100, officialQuestionIds: ["B-005-007-001"], incorrectOfficialQuestionIds: [], incorrectConceptCheckIds: []),
            LessonQuizAttempt(id: "partial::QZ-L-005-05-A", quizId: "QZ-L-005-05-A", lessonId: "L-005-05", submittedAt: partial.submittedAt, correct: 0, total: 2, percent: 0, officialQuestionIds: ["B-005-009-001"], incorrectOfficialQuestionIds: ["B-005-009-001"], incorrectConceptCheckIds: ["QZ-L-005-05-A-C2"]),
        ]
        for deviceId in ["phone", "tablet"] {
            XCTAssertEqual(deviceRows.lessonQuizAttempts.filter { $0.deviceId == deviceId && $0.attempt.id.hasPrefix("partial") }.map(\.attempt), expectedPartial)
        }
        XCTAssertFalse(try store.lessonQuizAttempts().contains { $0.id == archivedAttempt.id })
        XCTAssertFalse(deviceRows.lessonQuizAttempts.contains { $0.attempt.id == archivedAttempt.id })
        XCTAssertEqual(deviceRows.lessonQuizAttempts.filter { $0.attempt.id.hasPrefix("archived") }.map { $0.attempt.quizId }, ["QZ-L-005-06-A"])
        let migratedArchived = try XCTUnwrap(deviceRows.lessonQuizAttempts.first { $0.attempt.quizId == "QZ-L-005-06-A" })
        XCTAssertEqual(migratedArchived.attempt.correct, 2)
        XCTAssertEqual(migratedArchived.attempt.total, 2)
        XCTAssertEqual(migratedArchived.attempt.incorrectConceptCheckIds, [])
        let persisted = try ModelContext(container).fetch(FetchDescriptor<PreferencesEntity>())
        XCTAssertEqual(persisted.filter { $0.key == ProgressStoreService.task4610LessonSplitMigrationMarkerKey }.count, 1)
        XCTAssertEqual(persisted.first { $0.key == PreferencesEntity.defaultKey }?.archivedLessonProgressData, Data("[]".utf8))
        XCTAssertEqual(persisted.first { $0.key == PreferencesEntity.defaultKey }?.archivedLessonQuizAttemptsData, Data("[]".utf8))
        defaults.removePersistentDomain(forName: suiteName)
        let reopened = try ProgressStoreService(container: container, morseCourseProgressURL: morseURL, localDeviceID: "phone", defaults: defaults, defaultsDomainName: suiteName)
        XCTAssertEqual(try reopened.exportData(bank: bank, exportedAt: exported.exportedAt), exported)
        try reopened.resetAllData()
        XCTAssertEqual(try ModelContext(container).fetch(FetchDescriptor<PreferencesEntity>()).filter { $0.key == ProgressStoreService.task4610LessonSplitMigrationMarkerKey }.count, 1)
    }

    func testTask4610RequiresAllReadSourcesAndMergesEachDeviceBeforeAggregating() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let rows = [
            DeviceLessonProgressRecord(deviceId: "phone", record: LessonProgressRecord(lessonId: "L-005-04", readAt: "2026-01-02T03:30:00.000Z", readCount: 5)),
            DeviceLessonProgressRecord(deviceId: "phone", record: LessonProgressRecord(lessonId: "L-005-05", readAt: "2026-01-03T03:30:00.000Z", readCount: 2)),
            DeviceLessonProgressRecord(deviceId: "tablet", record: LessonProgressRecord(lessonId: "L-005-04", readAt: "2026-01-04T03:30:00.000Z", readCount: 1)),
            DeviceLessonProgressRecord(deviceId: "tablet", record: LessonProgressRecord(lessonId: "L-005-05", readAt: "2026-01-05T03:30:00.000Z", readCount: 4)),
        ]
        let raw = ProgressSyncMerge.deduplicateDeviceLessonProgress(rows)
        XCTAssertEqual(raw.map(\.readCount), [6, 6])
        for coherent in [true, false] {
            let sourceProgress = coherent ? raw : raw.map { LessonProgressRecord(lessonId: $0.lessonId, readAt: $0.readAt, readCount: 7) }
            let imported = ProgressExportV1(
                schema: "canadian-ham.progress-export", version: 1, lessonIdVersion: 1,
                exportedAt: "2026-01-06T03:45:00.000Z", bankId: bank.manifest.bankId,
                questionProgress: [], examAttempts: [], lessonProgress: try archivedArray(sourceProgress), lessonQuizAttempts: [],
                syncDeviceRows: ProgressSyncDeviceRows(questionProgress: [], examAttempts: [], lessonProgress: rows, lessonQuizAttempts: [], morseCourseProgress: []),
                preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
            )
            let store = try ProgressStoreService.inMemoryForTests(localDeviceID: "local")
            try store.importData(imported, bank: bank)
            XCTAssertEqual(try store.lessonProgressRecords().first { $0.lessonId == "L-005-05" }?.readCount, coherent ? 3 : 7)
            let exported = try store.exportData(bank: bank, exportedAt: imported.exportedAt)
            let migratedRows = try XCTUnwrap(exported.syncDeviceRows).lessonProgress
            if coherent {
                XCTAssertEqual(migratedRows.count, 6)
                XCTAssertEqual(migratedRows.filter { $0.record.lessonId == "L-005-05" }.map(\.record), [
                    rows[1].record,
                    LessonProgressRecord(lessonId: "L-005-05", readAt: rows[3].record.readAt, readCount: 1),
                ])
                XCTAssertEqual(Set(migratedRows.map(\.deviceId)), ["phone", "tablet"])
            } else {
                XCTAssertEqual(Set(migratedRows.map(\.deviceId)), ["local"])
            }
        }
        for sources in [["L-001-03", "L-001-05"], ["L-008-01", "L-008-02"]] {
            for readsBoth in [false, true] {
                let first = LessonProgressRecord(lessonId: sources[0], readAt: "2026-01-02T03:30:00.000Z", readCount: 5)
                let second = LessonProgressRecord(lessonId: sources[1], readAt: "2026-01-03T03:30:00.000Z", readCount: 2)
                let progress = readsBoth ? [first, second] : [first]
                let imported = ProgressExportV1(
                    schema: "canadian-ham.progress-export", version: 1, lessonIdVersion: 1,
                    exportedAt: "2026-01-06T03:45:00.000Z", bankId: bank.manifest.bankId,
                    questionProgress: [], examAttempts: [], lessonProgress: try archivedArray(progress), lessonQuizAttempts: [],
                    preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
                )
                let store = try ProgressStoreService.inMemoryForTests()
                try store.importData(imported, bank: bank)
                let expected = readsBoth ? [sources[0] == "L-001-03" ? first : LessonProgressRecord(lessonId: sources[0], readAt: second.readAt, readCount: 2), second] : (sources[0] == "L-001-03" ? [first] : [])
                XCTAssertEqual(try store.lessonProgressRecords(), expected)
            }
        }
    }

    func testTask4610RejectsNullLessonIDVersionAtTopLevelAndOnBothDeviceRowKinds() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let store = try ProgressStoreService.inMemoryForTests()
        let exported = try store.exportData(bank: bank, exportedAt: "2026-01-06T03:45:00.000Z")
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(exported)) as? [String: Any])
        json["lessonIdVersion"] = NSNull()
        XCTAssertThrowsError(try JSONDecoder().decode(ProgressExportV1.self, from: JSONSerialization.data(withJSONObject: json)))
        let record = LessonProgressRecord(lessonId: "L-005-01", readAt: "2026-01-02T03:30:00.000Z", readCount: 1)
        let attempt = LessonQuizAttempt(id: "null-version", quizId: "QZ-L-005-01-A", lessonId: record.lessonId, submittedAt: record.readAt, correct: 1, total: 1, percent: 100, officialQuestionIds: ["B-005-001-001"], incorrectOfficialQuestionIds: [], incorrectConceptCheckIds: [])
        for (rowData, isQuiz) in [(try JSONEncoder().encode(DeviceLessonProgressRecord(deviceId: "phone", record: record)), false), (try JSONEncoder().encode(DeviceLessonQuizAttemptRecord(deviceId: "phone", attempt: attempt)), true)] {
            var row = try XCTUnwrap(JSONSerialization.jsonObject(with: rowData) as? [String: Any])
            row["lessonIdVersion"] = NSNull()
            let data = try JSONSerialization.data(withJSONObject: row)
            if isQuiz {
                XCTAssertThrowsError(try JSONDecoder().decode(DeviceLessonQuizAttemptRecord.self, from: data))
            } else {
                XCTAssertThrowsError(try JSONDecoder().decode(DeviceLessonProgressRecord.self, from: data))
            }
        }
    }

    func testTask4610RejectsInvalidLegacyQuizScoresBeforeMigration() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let invalidAttempt = LessonQuizAttempt(
            id: "legacy-invalid-score", quizId: "QZ-L-005-04-A", lessonId: "L-005-04",
            submittedAt: "2026-01-03T03:45:00.000Z", correct: 2, total: 1, percent: 100,
            officialQuestionIds: ["B-005-009-003"], incorrectOfficialQuestionIds: [], incorrectConceptCheckIds: []
        )
        let imported = ProgressExportV1(
            schema: "canadian-ham.progress-export", version: 1, lessonIdVersion: 1,
            exportedAt: "2026-01-04T03:45:00.000Z", bankId: bank.manifest.bankId,
            questionProgress: [], examAttempts: [], lessonProgress: [],
            lessonQuizAttempts: try archivedArray([invalidAttempt]),
            preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
        )
        let store = try ProgressStoreService.inMemoryForTests()
        let errors = store.validate(imported, bank: bank)
        XCTAssertTrue(errors.contains { $0.contains("correct must not exceed total") })
        XCTAssertTrue(errors.contains { $0.contains("percent must match") })
        XCTAssertThrowsError(try store.importData(imported, bank: bank))
        XCTAssertEqual(try store.lessonQuizAttempts(), [])
    }

    func testTask4610ValidatesHistoricalQuizMembershipBeforeMigratingTopLevelAndSyncRows() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let legacyAttempt = LessonQuizAttempt(
            id: "legacy-reactance", quizId: "QZ-L-005-04-A", lessonId: "L-005-04",
            submittedAt: "2026-01-03T03:45:00.000Z", correct: 0, total: 2, percent: 0,
            officialQuestionIds: ["B-005-009-003"], incorrectOfficialQuestionIds: ["B-005-009-003"],
            incorrectConceptCheckIds: ["QZ-L-005-04-A-C3"]
        )
        let historicalExport = ProgressExportV1(
            schema: "canadian-ham.progress-export", version: 1, lessonIdVersion: 1,
            exportedAt: "2026-01-04T03:45:00.000Z", bankId: bank.manifest.bankId,
            questionProgress: [], examAttempts: [], lessonProgress: [],
            lessonQuizAttempts: try archivedArray([legacyAttempt]),
            preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
        )
        let store = try ProgressStoreService.inMemoryForTests()
        XCTAssertEqual(store.validate(historicalExport, bank: bank), [])
        try store.importData(historicalExport, bank: bank)
        let migratedAttempts = try store.lessonQuizAttempts()
        XCTAssertEqual(migratedAttempts, [LessonQuizAttempt(
            id: "legacy-reactance::QZ-L-005-05-A", quizId: "QZ-L-005-05-A", lessonId: "L-005-05",
            submittedAt: legacyAttempt.submittedAt, correct: 0, total: 2, percent: 0,
            officialQuestionIds: ["B-005-009-003"], incorrectOfficialQuestionIds: ["B-005-009-003"],
            incorrectConceptCheckIds: ["QZ-L-005-05-A-C2"]
        )])
        XCTAssertFalse(migratedAttempts.contains { $0.quizId == "QZ-L-005-04-A" })
        XCTAssertEqual(migratedAttempts.reduce(0) { $0 + $1.correct }, legacyAttempt.correct)

        let wrongSourceAttempt = LessonQuizAttempt(
            id: "wrong-source", quizId: "QZ-L-005-05-A", lessonId: "L-005-05",
            submittedAt: legacyAttempt.submittedAt, correct: 0, total: 1, percent: 0,
            officialQuestionIds: legacyAttempt.officialQuestionIds,
            incorrectOfficialQuestionIds: legacyAttempt.incorrectOfficialQuestionIds, incorrectConceptCheckIds: []
        )
        let neverAskedAttempt = LessonQuizAttempt(
            id: "never-asked", quizId: legacyAttempt.quizId, lessonId: legacyAttempt.lessonId,
            submittedAt: legacyAttempt.submittedAt, correct: 0, total: 1, percent: 0,
            officialQuestionIds: ["B-005-009-001"], incorrectOfficialQuestionIds: ["B-005-009-001"], incorrectConceptCheckIds: []
        )
        for invalidAttempt in [wrongSourceAttempt, neverAskedAttempt] {
            for usesSyncRow in [false, true] {
                let invalidExport = ProgressExportV1(
                    schema: "canadian-ham.progress-export", version: 1, lessonIdVersion: usesSyncRow ? 2 : 1,
                    exportedAt: historicalExport.exportedAt, bankId: bank.manifest.bankId,
                    questionProgress: [], examAttempts: [], lessonProgress: [],
                    lessonQuizAttempts: try archivedArray(usesSyncRow ? [] : [invalidAttempt]),
                    syncDeviceRows: usesSyncRow ? ProgressSyncDeviceRows(
                        questionProgress: [], examAttempts: [], lessonProgress: [],
                        lessonQuizAttempts: [DeviceLessonQuizAttemptRecord(deviceId: "legacy-phone", attempt: invalidAttempt)],
                        morseCourseProgress: []
                    ) : nil,
                    preferences: historicalExport.preferences
                )
                XCTAssertTrue(store.validate(invalidExport, bank: bank).contains { $0.contains("officialQuestionIds must belong") })
                XCTAssertThrowsError(try store.importData(invalidExport, bank: bank))
            }
        }
    }

    func testImportLeavesTask4610Version2LessonSplitRowsUnchanged() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let v2Progress = LessonProgressRecord(lessonId: "L-005-05", readAt: "2026-01-03T03:30:00.000Z", readCount: 2)
        let v2Attempt = LessonQuizAttempt(
            id: "v2-reactance",
            quizId: "QZ-L-005-05-A",
            lessonId: "L-005-05",
            submittedAt: "2026-01-03T03:45:00.000Z",
            correct: 1,
            total: 1,
            percent: 100,
            officialQuestionIds: ["B-005-009-003"],
            incorrectOfficialQuestionIds: [],
            incorrectConceptCheckIds: []
        )
        let imported = ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            lessonIdVersion: LessonIDContentVersion.current,
            exportedAt: "2026-01-04T03:45:00.000Z",
            bankId: bank.manifest.bankId,
            questionProgress: [],
            examAttempts: [],
            lessonProgress: try archivedArray([v2Progress]),
            lessonQuizAttempts: try archivedArray([v2Attempt]),
            preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
        )
        let store = try ProgressStoreService.inMemoryForTests(localDeviceID: "ipad")

        try store.importData(imported, bank: bank)

        XCTAssertEqual(try store.lessonProgressRecords(), [v2Progress])
        XCTAssertEqual(try store.lessonQuizAttempts(), [v2Attempt])
        let exported = try store.exportData(bank: bank, exportedAt: "2026-01-04T04:45:00.000Z")
        XCTAssertEqual(exported.lessonIdVersion, LessonIDContentVersion.current)
        XCTAssertEqual(try decodeArchivedArray(exported.lessonProgress, as: LessonProgressRecord.self), [v2Progress])
        XCTAssertEqual(try decodeArchivedArray(exported.lessonQuizAttempts, as: LessonQuizAttempt.self), [v2Attempt])
    }

    func testImportMigratesMixedTask4610SyncRowsByRowVersion() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let legacyProgress = DeviceLessonProgressRecord(
            deviceId: "legacy-phone",
            record: LessonProgressRecord(lessonId: "L-005-05", readAt: "2026-01-03T03:30:00.000Z", readCount: 2)
        )
        let currentProgress = DeviceLessonProgressRecord(
            deviceId: "current-tablet",
            record: LessonProgressRecord(lessonId: "L-005-05", readAt: "2026-01-04T03:30:00.000Z", readCount: 1),
            lessonIdVersion: LessonIDContentVersion.current
        )
        let legacyAttempt = DeviceLessonQuizAttemptRecord(
            deviceId: "legacy-phone",
            attempt: LessonQuizAttempt(
                id: "legacy-00505",
                quizId: "QZ-L-005-05-A",
                lessonId: "L-005-05",
                submittedAt: "2026-01-03T03:45:00.000Z",
                correct: 1,
                total: 2,
                percent: 50,
                officialQuestionIds: ["B-005-012-001", "B-005-011-001"],
                incorrectOfficialQuestionIds: ["B-005-011-001"],
                incorrectConceptCheckIds: []
            )
        )
        let currentAttempt = DeviceLessonQuizAttemptRecord(
            deviceId: "current-tablet",
            attempt: LessonQuizAttempt(
                id: "current-00505",
                quizId: "QZ-L-005-05-A",
                lessonId: "L-005-05",
                submittedAt: "2026-01-04T03:45:00.000Z",
                correct: 1,
                total: 1,
                percent: 100,
                officialQuestionIds: ["B-005-009-003"],
                incorrectOfficialQuestionIds: [],
                incorrectConceptCheckIds: []
            ),
            lessonIdVersion: LessonIDContentVersion.current
        )
        let expectedProgress = [
            LessonProgressRecord(lessonId: "L-005-05", readAt: "2026-01-04T03:30:00.000Z", readCount: 1),
            LessonProgressRecord(lessonId: "L-005-06", readAt: "2026-01-03T03:30:00.000Z", readCount: 2),
        ]
        let expectedAttempts = [
            LessonQuizAttempt(
                id: "legacy-00505",
                quizId: "QZ-L-005-05-A",
                lessonId: "L-005-05",
                submittedAt: "2026-01-03T03:45:00.000Z",
                correct: 1,
                total: 1,
                percent: 100,
                officialQuestionIds: ["B-005-012-001"],
                incorrectOfficialQuestionIds: [],
                incorrectConceptCheckIds: []
            ),
            LessonQuizAttempt(
                id: "legacy-00505::QZ-L-005-06-A",
                quizId: "QZ-L-005-06-A",
                lessonId: "L-005-06",
                submittedAt: "2026-01-03T03:45:00.000Z",
                correct: 0,
                total: 1,
                percent: 0,
                officialQuestionIds: ["B-005-011-001"],
                incorrectOfficialQuestionIds: ["B-005-011-001"],
                incorrectConceptCheckIds: []
            ),
            currentAttempt.attempt,
        ]
        let imported = ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            lessonIdVersion: LessonIDContentVersion.current,
            exportedAt: "2026-01-04T03:45:00.000Z",
            bankId: bank.manifest.bankId,
            questionProgress: [],
            examAttempts: [],
            lessonProgress: try archivedArray(expectedProgress),
            lessonQuizAttempts: try archivedArray(expectedAttempts),
            syncDeviceRows: ProgressSyncDeviceRows(
                questionProgress: [],
                examAttempts: [],
                lessonProgress: [legacyProgress, currentProgress],
                lessonQuizAttempts: [legacyAttempt, currentAttempt],
                morseCourseProgress: []
            ),
            preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
        )
        let store = try ProgressStoreService.inMemoryForTests(localDeviceID: "ipad")

        try store.importData(imported, bank: bank)

        XCTAssertEqual(try store.lessonProgressRecords(), expectedProgress)
        XCTAssertEqual(try store.lessonQuizAttempts(), expectedAttempts)
        let exportedRows = try XCTUnwrap(store.exportData(bank: bank, exportedAt: "2026-01-04T04:45:00.000Z").syncDeviceRows)
        XCTAssertEqual(Set(exportedRows.lessonProgress.map { $0.lessonIdVersion ?? -1 }), [LessonIDContentVersion.current])
        XCTAssertEqual(Set(exportedRows.lessonQuizAttempts.map { $0.lessonIdVersion ?? -1 }), [LessonIDContentVersion.current])
        XCTAssertTrue(exportedRows.lessonProgress.contains(DeviceLessonProgressRecord(deviceId: "legacy-phone", record: LessonProgressRecord(lessonId: "L-005-06", readAt: "2026-01-03T03:30:00.000Z", readCount: 2), lessonIdVersion: LessonIDContentVersion.current)))
        XCTAssertTrue(exportedRows.lessonProgress.contains(currentProgress))
    }

    func testTask4610LessonMigrationIsIdempotentAcrossRepeatedImports() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let legacyProgress = [LessonProgressRecord(lessonId: "L-005-05", readAt: "2026-01-03T03:30:00.000Z", readCount: 2)]
        let imported = ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: "2026-01-04T03:45:00.000Z",
            bankId: bank.manifest.bankId,
            questionProgress: [],
            examAttempts: [],
            lessonProgress: try archivedArray(legacyProgress),
            lessonQuizAttempts: [],
            preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
        )
        let store = try ProgressStoreService.inMemoryForTests(localDeviceID: "ipad")

        try store.importData(imported, bank: bank)
        let once = try store.exportData(bank: bank, exportedAt: "2026-01-04T04:45:00.000Z")
        try store.importData(once, bank: bank)
        let twice = try store.exportData(bank: bank, exportedAt: "2026-01-04T05:45:00.000Z")

        let expectedProgress = [
            LessonProgressRecord(lessonId: "L-005-06", readAt: "2026-01-03T03:30:00.000Z", readCount: 2),
        ]
        XCTAssertEqual(try decodeArchivedArray(once.lessonProgress, as: LessonProgressRecord.self), expectedProgress)
        XCTAssertEqual(try decodeArchivedArray(twice.lessonProgress, as: LessonProgressRecord.self), expectedProgress)
        XCTAssertEqual(try store.lessonProgressRecords(), expectedProgress)
    }

    func testLocalLessonAndMorseWritesAfterDeviceRowImportAddOnlyOwnContribution() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let importedLesson = LessonProgressRecord(lessonId: "L-005-01", readAt: "2026-01-02T03:00:00.000Z", readCount: 2)
        let importedMorse = MorseCourseProgressExport(
            courseId: "ised-koch-g4fon-v1",
            lessonProgress: [MorseLessonProgressRecord(lessonId: "koch-001", attempts: 2, bestAccuracy: 0.9, lastAccuracy: 0.9, lastAttemptedAt: "2026-01-02T04:00:00.000Z", completedAt: nil)],
            characterStats: [MorseCharacterStatRecord(character: "K", attempts: 4, correctAttempts: 3, recentResults: [true, true, false, true], lastPracticedAt: "2026-01-02T04:00:00.000Z")],
            dailyActivity: [MorseDailyActivityRecord(date: "2026-01-02", lessonsCompleted: 1)]
        )
        let imported = ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: "2026-01-02T05:04:05.000Z",
            bankId: bank.manifest.bankId,
            questionProgress: [],
            examAttempts: [],
            lessonProgress: try archivedArray([importedLesson]),
            lessonQuizAttempts: [],
            morseCourseProgress: importedMorse,
            syncDeviceRows: ProgressSyncDeviceRows(
                questionProgress: [],
                examAttempts: [],
                lessonProgress: [DeviceLessonProgressRecord(deviceId: "iphone", record: importedLesson)],
                lessonQuizAttempts: [],
                morseCourseProgress: [DeviceMorseCourseProgressRecord(deviceId: "iphone", progress: importedMorse)]
            ),
            preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
        )
        let store = try ProgressStoreService.inMemoryForTests(localDeviceID: "ipad")
        try store.importData(imported, bank: bank)
        let updatedLesson = LessonProgressRecord(lessonId: importedLesson.lessonId, readAt: "2026-01-02T06:00:00.000Z", readCount: 3)
        let updatedMorse = MorseCourseProgressExport(
            courseId: importedMorse.courseId,
            lessonProgress: [MorseLessonProgressRecord(lessonId: "koch-001", attempts: 3, bestAccuracy: 1, lastAccuracy: 1, lastAttemptedAt: "2026-01-02T06:00:00.000Z", completedAt: "2026-01-02T06:00:00.000Z")],
            characterStats: [MorseCharacterStatRecord(character: "K", attempts: 5, correctAttempts: 4, recentResults: [true, true, false, true, true], lastPracticedAt: "2026-01-02T06:00:00.000Z")],
            dailyActivity: [MorseDailyActivityRecord(date: "2026-01-02", lessonsCompleted: 2)]
        )

        try store.saveLessonProgress(updatedLesson)
        try store.saveMorseCourseProgress(updatedMorse)

        XCTAssertEqual(try store.lessonProgressRecords(), [updatedLesson])
        XCTAssertEqual(try store.morseCourseProgress(), updatedMorse)
        let exportedOnce = try store.exportData(bank: bank, exportedAt: "2026-01-02T07:04:05.000Z")
        XCTAssertEqual(Set(exportedOnce.syncDeviceRows?.lessonProgress.map(\.deviceId) ?? []), ["iphone", "ipad"])
        XCTAssertEqual(Set(exportedOnce.syncDeviceRows?.morseCourseProgress.map(\.deviceId) ?? []), ["iphone", "ipad"])
        try store.importData(exportedOnce, bank: bank)
        try store.importData(exportedOnce, bank: bank)
        let exportedAfterReimport = try store.exportData(bank: bank, exportedAt: "2026-01-02T08:04:05.000Z")
        XCTAssertEqual(Set(exportedAfterReimport.syncDeviceRows?.lessonProgress.map(\.deviceId) ?? []), ["iphone", "ipad"])
        XCTAssertEqual(Set(exportedAfterReimport.syncDeviceRows?.morseCourseProgress.map(\.deviceId) ?? []), ["iphone", "ipad"])
        XCTAssertEqual(try store.lessonProgressRecords(), [updatedLesson])
        XCTAssertEqual(try store.morseCourseProgress(), updatedMorse)
    }

    func testImportingExportWithDeviceRowsThenSyncingOriginalRowsDoesNotDoubleCount() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let iPhone = try ProgressStoreService.inMemoryForTests(localDeviceID: "iphone")
        let iPhoneRecord = QuestionProgressRecord(
            questionId: "B-001-001-001",
            bankId: bank.manifest.bankId,
            attempts: 2,
            correctAttempts: 1,
            lastAttemptedAt: "2026-01-02T03:04:05.000Z",
            lastResult: .correct,
            recentResults: [false, true],
            leitner: LeitnerState(box: 1, dueAt: "2026-01-03T03:04:05.000Z")
        )
        try iPhone.saveQuestionProgress([iPhoneRecord])
        let exported = try iPhone.exportData(bank: bank, exportedAt: "2026-01-02T05:04:05.000Z")
        XCTAssertEqual(exported.syncDeviceRows?.questionProgress.map(\.deviceId), ["iphone"])

        let iPad = try ProgressStoreService.inMemoryForTests(localDeviceID: "ipad")
        try iPad.importData(exported, bank: bank)
        let syncContext = ModelContext(iPad.container)
        syncContext.insert(QuestionProgressEntity(
            questionId: iPhoneRecord.questionId,
            bankId: iPhoneRecord.bankId,
            attempts: iPhoneRecord.attempts,
            correctAttempts: iPhoneRecord.correctAttempts,
            lastAttemptedAt: iPhoneRecord.lastAttemptedAt,
            lastResult: iPhoneRecord.lastResult.rawValue,
            recentResultsData: try JSONEncoder().encode(iPhoneRecord.recentResults),
            leitnerBox: iPhoneRecord.leitner.box,
            dueAt: iPhoneRecord.leitner.dueAt,
            deviceId: "iphone"
        ))
        try syncContext.save()

        XCTAssertEqual(try iPad.questionProgressRecords(), [iPhoneRecord])
        XCTAssertEqual(try iPad.exportData(bank: bank, exportedAt: "2026-01-02T06:04:05.000Z").questionProgress, [iPhoneRecord])
        let afterSyncWrite = QuestionProgressRecord(
            questionId: iPhoneRecord.questionId,
            bankId: iPhoneRecord.bankId,
            attempts: 3,
            correctAttempts: 2,
            lastAttemptedAt: "2026-01-02T07:04:05.000Z",
            lastResult: .correct,
            recentResults: [false, true, true],
            leitner: LeitnerState(box: 2, dueAt: "2026-01-04T03:04:05.000Z")
        )
        try iPad.saveQuestionProgress([afterSyncWrite])
        XCTAssertEqual(try iPad.questionProgressRecords(), [afterSyncWrite])
    }

    func testStaleSameDeviceQuestionRowDoesNotLoseNextLocalWrite() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let store = try ProgressStoreService.inMemoryForTests(localDeviceID: "ipad")
        let fresh = QuestionProgressRecord(questionId: "B-001-001-001", bankId: bank.manifest.bankId, attempts: 2, correctAttempts: 1, lastAttemptedAt: "2026-01-02T03:04:05.000Z", lastResult: .correct, recentResults: [false, true], leitner: LeitnerState(box: 1, dueAt: "2026-01-03T03:04:05.000Z"))
        try store.saveQuestionProgress([fresh])
        let context = ModelContext(store.container)
        context.insert(QuestionProgressEntity(questionId: fresh.questionId, bankId: fresh.bankId, attempts: 1, correctAttempts: 0, lastAttemptedAt: "2026-01-01T03:04:05.000Z", lastResult: AnswerResult.incorrect.rawValue, recentResultsData: try JSONEncoder().encode([false]), leitnerBox: 0, dueAt: "2026-01-01T03:04:05.000Z", deviceId: "ipad"))
        try context.save()
        let next = QuestionProgressRecord(questionId: fresh.questionId, bankId: fresh.bankId, attempts: 3, correctAttempts: 2, lastAttemptedAt: "2026-01-02T04:04:05.000Z", lastResult: .correct, recentResults: [false, true, true], leitner: LeitnerState(box: 2, dueAt: "2026-01-04T03:04:05.000Z"))

        try store.saveQuestionProgress([next])

        XCTAssertEqual(try store.questionProgressRecords(), [next])
    }

    func testLessonWriteAfterImportedAndSyncedDuplicateRowsAddsExactlyOneRead() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let iphone = try ProgressStoreService.inMemoryForTests(localDeviceID: "iphone")
        let iphoneLesson = LessonProgressRecord(lessonId: "L-005-01", readAt: "2026-01-02T03:00:00.000Z", readCount: 2)
        try iphone.saveLessonProgress(iphoneLesson)
        let exported = try iphone.exportData(bank: bank, exportedAt: "2026-01-02T04:00:00.000Z")

        let ipad = try ProgressStoreService.inMemoryForTests(localDeviceID: "ipad")
        try ipad.importData(exported, bank: bank)
        let syncContext = ModelContext(ipad.container)
        syncContext.insert(LessonProgressEntity(lessonId: iphoneLesson.lessonId, readAt: iphoneLesson.readAt, readCount: iphoneLesson.readCount, deviceId: "iphone"))
        try syncContext.save()
        XCTAssertEqual(try ipad.lessonProgressRecords(), [iphoneLesson])

        let ipadRead = LessonProgressRecord(lessonId: iphoneLesson.lessonId, readAt: "2026-01-02T05:00:00.000Z", readCount: iphoneLesson.readCount + 1)
        try ipad.saveLessonProgress(ipadRead)

        XCTAssertEqual(try ipad.lessonProgressRecords(), [ipadRead])
    }

    func testImportValidationRejectsDuplicateMorseDailyActivityDates() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let data = ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: "2026-01-02T05:04:05.000Z",
            bankId: bank.manifest.bankId,
            questionProgress: [],
            examAttempts: [],
            lessonProgress: [],
            lessonQuizAttempts: [],
            morseCourseProgress: MorseCourseProgressExport(
                courseId: "ised-koch-g4fon-v1",
                lessonProgress: [],
                characterStats: [],
                dailyActivity: [
                    MorseDailyActivityRecord(date: "2026-01-02", lessonsCompleted: 1),
                    MorseDailyActivityRecord(date: "2026-01-02", lessonsCompleted: 1),
                ]
            ),
            preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
        )

        let errors = try ProgressStoreService.inMemoryForTests().validate(data, bank: bank)

        XCTAssertTrue(errors.contains { $0.contains("dailyActivity[1].date duplicates") })
        XCTAssertThrowsError(try ProgressStoreService.inMemoryForTests().importData(data, bank: bank))
    }

    func testImportFiltersSyncDeviceRowsFromOtherBanksInsteadOfFailing() throws {
        let basicBank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let advancedRecord = QuestionProgressRecord(
            questionId: "A-001-001-001",
            bankId: syntheticAdvancedBankId,
            attempts: 3,
            correctAttempts: 2,
            lastAttemptedAt: "2026-01-02T06:04:05.000Z",
            lastResult: .correct,
            recentResults: [false, true, true],
            leitner: LeitnerState(box: 2, dueAt: "2026-01-05T03:04:05.000Z")
        )
        let data = ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: "2026-01-02T07:04:05.000Z",
            bankId: basicBank.manifest.bankId,
            questionProgress: [],
            examAttempts: [],
            lessonProgress: [],
            lessonQuizAttempts: [],
            syncDeviceRows: ProgressSyncDeviceRows(
                questionProgress: [DeviceQuestionProgressRecord(deviceId: "advanced-device", record: advancedRecord)],
                examAttempts: [],
                lessonProgress: [],
                lessonQuizAttempts: [],
                morseCourseProgress: []
            ),
            preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
        )
        let store = try ProgressStoreService.inMemoryForTests()

        XCTAssertTrue(store.validate(data, bank: basicBank).isEmpty)
        XCTAssertNoThrow(try store.importData(data, bank: basicBank))
        XCTAssertEqual(try store.questionProgressRecords(), [])
    }

    func testImportRejectsInvalidSyncDeviceRows() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let validRecord = QuestionProgressRecord(
            questionId: "B-001-001-001",
            bankId: bank.manifest.bankId,
            attempts: 1,
            correctAttempts: 1,
            lastAttemptedAt: "2026-01-02T03:04:05.000Z",
            lastResult: .correct,
            recentResults: [true],
            leitner: LeitnerState(box: 1, dueAt: "2026-01-03T03:04:05.000Z")
        )
        let invalidRow = QuestionProgressRecord(
            questionId: "B-999-999-999",
            bankId: bank.manifest.bankId,
            attempts: 1,
            correctAttempts: 2,
            lastAttemptedAt: "bad",
            lastResult: .correct,
            recentResults: [true, true, true, true, true, true],
            leitner: LeitnerState(box: 6, dueAt: "bad")
        )
        let data = ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: "2026-01-02T05:04:05.000Z",
            bankId: bank.manifest.bankId,
            questionProgress: [validRecord],
            examAttempts: [],
            lessonProgress: [],
            lessonQuizAttempts: [],
            syncDeviceRows: ProgressSyncDeviceRows(
                questionProgress: [DeviceQuestionProgressRecord(deviceId: "", record: invalidRow)],
                examAttempts: [],
                lessonProgress: [],
                lessonQuizAttempts: [],
                morseCourseProgress: []
            ),
            preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
        )
        let errors = try ProgressStoreService.inMemoryForTests().validate(data, bank: bank)

        XCTAssertTrue(errors.contains { $0.contains("syncDeviceRows.questionProgress[0].deviceId") })
        XCTAssertTrue(errors.contains { $0.contains("syncDeviceRows.questionProgress[0].record.questionId") })
        XCTAssertTrue(errors.contains { $0.contains("correctAttempts") })
        XCTAssertThrowsError(try ProgressStoreService.inMemoryForTests().importData(data, bank: bank))
    }

    func testImportIgnoresStaleSyncDeviceRowsWhenMergedRowsDoNotMatchTopLevelFields() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let topLevel = QuestionProgressRecord(
            questionId: "B-001-001-001",
            bankId: bank.manifest.bankId,
            attempts: 3,
            correctAttempts: 2,
            lastAttemptedAt: "2026-01-02T06:04:05.000Z",
            lastResult: .correct,
            recentResults: [false, true, true],
            leitner: LeitnerState(box: 2, dueAt: "2026-01-05T03:04:05.000Z")
        )
        let staleRow = QuestionProgressRecord(
            questionId: topLevel.questionId,
            bankId: topLevel.bankId,
            attempts: 2,
            correctAttempts: 1,
            lastAttemptedAt: "2026-01-02T03:04:05.000Z",
            lastResult: .correct,
            recentResults: [false, true],
            leitner: LeitnerState(box: 1, dueAt: "2026-01-03T03:04:05.000Z")
        )
        let data = ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: "2026-01-02T07:04:05.000Z",
            bankId: bank.manifest.bankId,
            questionProgress: [topLevel],
            examAttempts: [],
            lessonProgress: [],
            lessonQuizAttempts: [],
            syncDeviceRows: ProgressSyncDeviceRows(
                questionProgress: [DeviceQuestionProgressRecord(deviceId: "iphone", record: staleRow)],
                examAttempts: [],
                lessonProgress: [],
                lessonQuizAttempts: [],
                morseCourseProgress: []
            ),
            preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
        )
        let store = try ProgressStoreService.inMemoryForTests(localDeviceID: "ipad")

        XCTAssertTrue(store.validate(data, bank: bank).isEmpty)
        try store.importData(data, bank: bank)

        XCTAssertEqual(try store.questionProgressRecords(), [topLevel])
        XCTAssertEqual(try store.exportData(bank: bank, exportedAt: "2026-01-02T08:04:05.000Z").syncDeviceRows?.questionProgress.map(\.deviceId), ["ipad"])
    }

    func testICloudDeleteStopsSyncBeforeDeletingZoneAndKeepsLocalWithoutReupload() async throws {
        let store = try ProgressStoreService.inMemoryForTests(iCloudSyncEnabled: true, layout: .split)
        let record = QuestionProgressRecord(
            questionId: "B-001-001-001",
            bankId: basicBankId,
            attempts: 1,
            correctAttempts: 1,
            lastAttemptedAt: "2026-01-02T03:04:05.000Z",
            lastResult: .correct,
            recentResults: [true],
            leitner: LeitnerState(box: 1, dueAt: "2026-01-03T03:04:05.000Z")
        )
        try store.saveQuestionProgress([record])
        let originalContainer = store.container
        let defaultsSuiteName = "ProgressStoreTests.iCloudDelete.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsSuiteName))
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }
        ICloudSyncSettings.setStoredOptIn(true, defaults: defaults)
        var deletedAfterLocalReopen = false
        let client = ICloudProgressDeletionClient(deletePrivateDatabaseProgressZones: {
            deletedAfterLocalReopen = !store.isICloudSyncEnabled && store.container !== originalContainer
        })

        try await store.deleteICloudProgress(localDataChoice: .keepLocal, client: client, defaults: defaults)

        XCTAssertTrue(deletedAfterLocalReopen)
        XCTAssertFalse(ICloudSyncSettings.storedOptIn(defaults: defaults))
        XCTAssertFalse(store.isICloudSyncEnabled)
        XCTAssertEqual(try store.questionProgressRecords(), [record])
        let restarted = try ProgressStoreService.inMemoryForTests(iCloudSyncEnabled: ICloudSyncSettings.storedOptIn(defaults: defaults), layout: .split)
        XCTAssertFalse(restarted.isICloudSyncEnabled)
    }

    func testICloudAccountTeardownUsesInjectedFactoryAndRestoresLocalSnapshot() throws {
        let store = try ProgressStoreService.inMemoryForTests(iCloudSyncEnabled: true, layout: .split)
        let record = QuestionProgressRecord(
            questionId: "B-001-001-001",
            bankId: basicBankId,
            attempts: 1,
            correctAttempts: 1,
            lastAttemptedAt: "2026-01-02T03:04:05.000Z",
            lastResult: .correct,
            recentResults: [true],
            leitner: LeitnerState(box: 1, dueAt: "2026-01-03T03:04:05.000Z")
        )
        try store.saveQuestionProgress([record])
        var factoryCalls = 0

        try store.reopenLocalOnlyAfterSyncStop { enabled in
            factoryCalls += 1
            XCTAssertFalse(enabled)
            return try ProgressStoreService.inMemoryForTests(iCloudSyncEnabled: enabled, layout: .split).container
        }

        XCTAssertEqual(factoryCalls, 1)
        XCTAssertFalse(store.isICloudSyncEnabled)
        XCTAssertEqual(try store.questionProgressRecords(), [record])
    }

    func testICloudAccountSignalsUseInitInjectedFactory() throws {
        let defaultsSuiteName = "ProgressStoreTests.iCloudSignalsFactory.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsSuiteName))
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }
        let urls = ProgressStoreURLs(progressDirectory: try temporaryProgressStoreDirectory())
        let seed = try ProgressStoreService.inMemoryForTests(iCloudSyncEnabled: true, layout: .split, localDeviceID: "device")
        var factoryCalls: [Bool] = []
        let store = try ProgressStoreService(
            container: seed.container,
            storeURLs: urls,
            iCloudSyncEnabled: true,
            layout: .split,
            modelContainerFactory: { enabled in
                factoryCalls.append(enabled)
                return try ProgressStoreService.inMemoryForTests(iCloudSyncEnabled: enabled, layout: .split, localDeviceID: "device").container
            },
            startICloudMonitoring: false,
            localDeviceID: "device",
            defaults: defaults,
            defaultsDomainName: defaultsSuiteName
        )
        let record = QuestionProgressRecord(
            questionId: "B-001-001-001",
            bankId: basicBankId,
            attempts: 1,
            correctAttempts: 1,
            lastAttemptedAt: "2026-01-02T03:04:05.000Z",
            lastResult: .correct,
            recentResults: [true],
            leitner: LeitnerState(box: 1, dueAt: "2026-01-03T03:04:05.000Z")
        )
        try store.saveQuestionProgress([record])

        for signal in [ICloudAccountSignal.accountChanged, .signedOut, .iCloudDisabled] {
            store.updateICloudSyncOptIn(true, defaults: defaults)
            store.handleICloudAccountSignal(signal, defaults: defaults)
            XCTAssertFalse(store.isICloudSyncEnabled)
            XCTAssertNil(store.iCloudAccountSignalError)
            XCTAssertEqual(try store.questionProgressRecords(), [record])
        }

        XCTAssertEqual(factoryCalls, [false, false, false])
    }

    func testICloudDeleteCanDeleteLocalDataAfterZoneDelete() async throws {
        let store = try ProgressStoreService.inMemoryForTests(iCloudSyncEnabled: true, layout: .split)
        let record = QuestionProgressRecord(
            questionId: "B-001-001-001",
            bankId: basicBankId,
            attempts: 1,
            correctAttempts: 1,
            lastAttemptedAt: "2026-01-02T03:04:05.000Z",
            lastResult: .correct,
            recentResults: [true],
            leitner: LeitnerState(box: 1, dueAt: "2026-01-03T03:04:05.000Z")
        )
        try store.saveQuestionProgress([record])
        var deleteCalled = false

        try await store.deleteICloudProgress(localDataChoice: .deleteLocal, client: ICloudProgressDeletionClient(deletePrivateDatabaseProgressZones: { deleteCalled = true }))

        XCTAssertTrue(deleteCalled)
        XCTAssertFalse(store.isICloudSyncEnabled)
        XCTAssertEqual(try store.questionProgressRecords(), [])
    }

    func testICloudSyncToggleAndAccountSignalsPreserveLocalProgress() throws {
        let defaultsSuiteName = "ProgressStoreTests.iCloudSync.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsSuiteName))
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }
        let store = try ProgressStoreService.inMemoryForTests()
        let record = QuestionProgressRecord(
            questionId: "B-001-001-001",
            bankId: basicBankId,
            attempts: 2,
            correctAttempts: 1,
            lastAttemptedAt: "2026-01-02T03:04:05.000Z",
            lastResult: .correct,
            recentResults: [false, true],
            leitner: LeitnerState(box: 1, dueAt: "2026-01-03T03:04:05.000Z")
        )
        try store.saveQuestionProgress([record])

        store.updateICloudSyncOptIn(true, defaults: defaults)
        store.updateICloudSyncOptIn(false, defaults: defaults)
        XCTAssertEqual(try store.questionProgressRecords(), [record])

        store.updateICloudSyncOptIn(true, defaults: defaults)
        store.handleICloudAccountSignal(.accountChanged, defaults: defaults)
        XCTAssertFalse(ICloudSyncSettings.storedOptIn(defaults: defaults))
        XCTAssertEqual(try store.questionProgressRecords(), [record])

        store.updateICloudSyncOptIn(true, defaults: defaults)
        store.handleICloudAccountSignal(.signedOut, defaults: defaults)
        XCTAssertFalse(ICloudSyncSettings.storedOptIn(defaults: defaults))
        XCTAssertEqual(try store.questionProgressRecords(), [record])

        store.updateICloudSyncOptIn(true, defaults: defaults)
        store.handleICloudAccountSignal(.iCloudDisabled, defaults: defaults)
        XCTAssertFalse(ICloudSyncSettings.storedOptIn(defaults: defaults))
        XCTAssertEqual(try store.questionProgressRecords(), [record])

        store.updateICloudSyncOptIn(true, defaults: defaults)
        store.handleICloudAccountAvailability(.noAccount, defaults: defaults)
        XCTAssertFalse(ICloudSyncSettings.storedOptIn(defaults: defaults))
        XCTAssertEqual(try store.questionProgressRecords(), [record])

        store.updateICloudSyncOptIn(true, defaults: defaults)
        store.handleICloudAccountAvailability(.restricted, defaults: defaults)
        XCTAssertFalse(ICloudSyncSettings.storedOptIn(defaults: defaults))
        XCTAssertEqual(try store.questionProgressRecords(), [record])
    }

    func testDefaultLayoutResetDoesNotWriteGatedLegacyCopyMarker() throws {
        let directory = try temporaryProgressStoreDirectory()
        let urls = ProgressStoreURLs(progressDirectory: directory)
        let store = try openProgressStoreForTests(storeURLs: urls, iCloudSyncEnabled: false, layout: .legacySingleStore)

        try store.resetAllData()

        XCTAssertFalse(FileManager.default.fileExists(atPath: urls.legacyPreferencesCopyMarkerURL.path(percentEncoded: false)))
    }

    func testSplitStoreFailedLegacyPreferencesReadDoesNotCreateMarkerAndRetries() throws {
        let directory = try temporaryProgressStoreDirectory()
        let urls = ProgressStoreURLs(progressDirectory: directory)
        try Data("not a swiftdata store".utf8).write(to: urls.persistentStoreURL)

        _ = try? openProgressStoreForTests(storeURLs: urls, iCloudSyncEnabled: false, layout: .split)

        XCTAssertFalse(FileManager.default.fileExists(atPath: urls.legacyPreferencesCopyMarkerURL.path(percentEncoded: false)))
    }

    func testSplitStoreLegacyPreferencesRetryRunsEvenWhenPreferencesStoreExists() throws {
        let directory = try temporaryProgressStoreDirectory()
        let urls = ProgressStoreURLs(progressDirectory: directory)
        do {
            let legacyStore = try openProgressStoreForTests(storeURLs: urls, iCloudSyncEnabled: false, layout: .legacySingleStore)
            var preferences = legacyStore.preferences
            preferences.practiceMode = .immediate
            preferences.examTimerEnabled = false
            preferences.theme = .system
            try legacyStore.updatePreferences(preferences)
        }
        _ = try openProgressStoreForTests(storeURLs: urls, iCloudSyncEnabled: false, layout: .split)
        XCTAssertTrue(FileManager.default.fileExists(atPath: urls.preferencesStoreURL.path(percentEncoded: false)))
        try FileManager.default.removeItem(at: urls.legacyPreferencesCopyMarkerURL)
        do {
            let legacyStore = try openProgressStoreForTests(storeURLs: urls, iCloudSyncEnabled: false, layout: .legacySingleStore)
            var preferences = legacyStore.preferences
            preferences.practiceMode = .reviewLater
            preferences.examTimerEnabled = true
            preferences.theme = .dark
            try legacyStore.updatePreferences(preferences)
        }

        let retriedStore = try openProgressStoreForTests(storeURLs: urls, iCloudSyncEnabled: false, layout: .split)

        XCTAssertEqual(retriedStore.preferences.practiceMode, .reviewLater)
        XCTAssertTrue(retriedStore.preferences.examTimerEnabled)
        XCTAssertEqual(retriedStore.preferences.theme, .dark)
        XCTAssertTrue(FileManager.default.fileExists(atPath: urls.legacyPreferencesCopyMarkerURL.path(percentEncoded: false)))
    }

    func testSplitStoreFirstOpenCopiesLegacyPreferencesWithoutLosingProgress() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let directory = try temporaryProgressStoreDirectory()
        let urls = ProgressStoreURLs(progressDirectory: directory)
        let (defaults, suiteName) = try temporaryDefaultsSuite(prefix: "splitStore")
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let record = QuestionProgressRecord(
            questionId: "B-001-001-001",
            bankId: bank.manifest.bankId,
            attempts: 3,
            correctAttempts: 2,
            lastAttemptedAt: "2026-01-02T03:04:05.000Z",
            lastResult: .incorrect,
            recentResults: [true, true, false],
            leitner: LeitnerState(box: 2, dueAt: "2026-01-04T03:04:05.000Z"),
            notes: "legacy note"
        )
        let attempt = try mockAttempt(bank: bank, seed: "legacy-split", submittedAt: "2026-01-02T04:04:05.000Z")
        let lessonProgress = LessonProgressRecord(lessonId: "L-005-01", readAt: "2026-01-02T03:10:00.000Z", readCount: 2)
        let lessonQuizAttempt = LessonQuizAttempt(
            id: "legacy-quiz-attempt",
            quizId: "QZ-L-005-01-A",
            lessonId: "L-005-01",
            submittedAt: "2026-01-02T03:20:00.000Z",
            correct: 1,
            total: 1,
            percent: 100,
            officialQuestionIds: ["B-005-001-001"],
            incorrectOfficialQuestionIds: [],
            incorrectConceptCheckIds: []
        )

        do {
            let legacyStore = try openProgressStoreForTests(storeURLs: urls, iCloudSyncEnabled: false, layout: .legacySingleStore, defaults: defaults, defaultsDomainName: suiteName)
            try legacyStore.saveQuestionProgress([record])
            try legacyStore.saveExamAttempt(attempt)
            var preferences = legacyStore.preferences
            preferences.practiceMode = .reviewLater
            preferences.examTimerEnabled = true
            preferences.language = .french
            preferences.theme = .dark
            try legacyStore.updatePreferences(preferences)
            try legacyStore.saveLessonProgress(lessonProgress)
            try legacyStore.saveLessonQuizAttempt(lessonQuizAttempt, questionProgress: [record])
        }

        do {
            let splitStore = try openProgressStoreForTests(storeURLs: urls, iCloudSyncEnabled: false, layout: .split, defaults: defaults, defaultsDomainName: suiteName)
            XCTAssertEqual(try splitStore.questionProgressRecords(), [record])
            XCTAssertEqual(try splitStore.examAttempts(), [attempt])
            XCTAssertEqual(splitStore.preferences.practiceMode, .reviewLater)
            XCTAssertTrue(splitStore.preferences.examTimerEnabled)
            XCTAssertEqual(splitStore.preferences.language, .french)
            XCTAssertEqual(splitStore.preferences.theme, .dark)
            XCTAssertEqual(try splitStore.lessonProgressRecords(), [lessonProgress])
            XCTAssertEqual(try splitStore.lessonQuizAttempts(), [lessonQuizAttempt])
        }

        do {
            let reopenedSplitStore = try openProgressStoreForTests(storeURLs: urls, iCloudSyncEnabled: false, layout: .split, defaults: defaults, defaultsDomainName: suiteName)
            XCTAssertEqual(try reopenedSplitStore.questionProgressRecords(), [record])
            XCTAssertEqual(try reopenedSplitStore.lessonProgressRecords(), [lessonProgress])
            XCTAssertEqual(try reopenedSplitStore.lessonQuizAttempts(), [lessonQuizAttempt])
            try reopenedSplitStore.resetAllData()
        }

        let afterResetReopen = try openProgressStoreForTests(storeURLs: urls, iCloudSyncEnabled: false, layout: .split, defaults: defaults, defaultsDomainName: suiteName)
        XCTAssertEqual(try afterResetReopen.questionProgressRecords(), [])
        XCTAssertEqual(try afterResetReopen.examAttempts(), [])
        XCTAssertEqual(afterResetReopen.preferences, .default)
        XCTAssertEqual(try afterResetReopen.lessonProgressRecords(), [])
        XCTAssertEqual(try afterResetReopen.lessonQuizAttempts(), [])
    }

#if os(macOS)
    func testNativeSettingsGeneralBindingsUpdatePracticePreferences() throws {
        let (defaults, suiteName) = try temporaryDefaultsSuite(prefix: "nativeSettings")
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = try CanadianHam.ProgressStoreService.inMemoryForTests(defaults: defaults, defaultsDomainName: suiteName)
        var saveCount = 0
        var failedError: Error?
        let bindings = NativeSettingsPreferenceBindings(
            progressStore: store,
            didSave: { saveCount += 1 },
            didFail: { failedError = $0 }
        )

        bindings.practiceMode.wrappedValue = .reviewLater
        bindings.examTimerEnabled.wrappedValue = true
        bindings.language.wrappedValue = .french

        XCTAssertEqual(store.preferences.practiceMode, .reviewLater)
        XCTAssertTrue(store.preferences.examTimerEnabled)
        XCTAssertEqual(store.preferences.language, .french)
        XCTAssertEqual(saveCount, 3)
        XCTAssertNil(failedError)
    }

    func testNativeSettingsAppearanceColorSchemeFollowsLiveThemePreference() throws {
        let store = try CanadianHam.ProgressStoreService.inMemoryForTests()
        let appSettings = CanadianHam.AppSettingsModel()
        appSettings.progressStore = store
        let settingsView = NativeSettingsView(appSettings: appSettings)
        let bindings = NativeSettingsPreferenceBindings(progressStore: store)

        XCTAssertNil(settingsView.preferredColorScheme)

        bindings.theme.wrappedValue = .dark
        XCTAssertEqual(settingsView.preferredColorScheme, .dark)

        bindings.theme.wrappedValue = .light
        XCTAssertEqual(settingsView.preferredColorScheme, .light)

        bindings.theme.wrappedValue = .system
        XCTAssertNil(settingsView.preferredColorScheme)
    }
#endif

    func testAppSettingsModelPublishesMorseSettingsForRootViewSync() throws {
        let appSettings = CanadianHam.AppSettingsModel(morseSettings: .default)
        var publishedSettings: CanadianHam.MorseTrainerSettings?
        let cancellable = appSettings.$morseSettings.dropFirst().sink { publishedSettings = $0 }
        let next = CanadianHam.MorseTrainerSettings(
            toneHz: 700,
            characterWpm: 18,
            effectiveWpm: 8,
            timingProfile: .general,
            volume: 0.4
        )

        appSettings.morseSettings = next

        XCTAssertEqual(publishedSettings, next)
        XCTAssertEqual(appSettings.morseSettings, next)
        cancellable.cancel()
    }

    func testFreshInstallDefaultsLanguageToSystem() throws {
        let (defaults, suiteName) = try temporaryDefaultsSuite(prefix: "freshLanguage")
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = try ProgressStoreService.inMemoryForTests(defaults: defaults, defaultsDomainName: suiteName)

        XCTAssertEqual(store.preferences.language, .system)
        XCTAssertNil(storedAppleLanguages(defaults: defaults, domainName: suiteName))
    }

    func testLegacyStoredEnglishLanguageMigratesToSystemOnceAndDoesNotRerun() throws {
        let (defaults, suiteName) = try temporaryDefaultsSuite(prefix: "legacyEnglish")
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let container = try preferencesContainer(language: ApplePreferences.LanguagePreference.english.rawValue)
        let store = try ProgressStoreService(
            container: container,
            morseCourseProgressURL: try temporaryMorseCourseProgressURL(),
            defaults: defaults,
            defaultsDomainName: suiteName
        )

        XCTAssertEqual(store.preferences.language, .system)
        XCTAssertNil(storedAppleLanguages(defaults: defaults, domainName: suiteName))

        var preferences = store.preferences
        preferences.language = .english
        try store.updatePreferences(preferences)
        let reopened = try ProgressStoreService(
            container: container,
            morseCourseProgressURL: try temporaryMorseCourseProgressURL(),
            defaults: defaults,
            defaultsDomainName: suiteName
        )

        XCTAssertEqual(reopened.preferences.language, .english)
        XCTAssertEqual(storedAppleLanguages(defaults: defaults, domainName: suiteName), ["en"])
    }

    func testLegacyStoredFrenchLanguageStaysFrenchAndAppliesInterfaceLanguageOnce() throws {
        let (defaults, suiteName) = try temporaryDefaultsSuite(prefix: "legacyFrench")
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let container = try preferencesContainer(language: ApplePreferences.LanguagePreference.french.rawValue)
        let store = try ProgressStoreService(
            container: container,
            morseCourseProgressURL: try temporaryMorseCourseProgressURL(),
            defaults: defaults,
            defaultsDomainName: suiteName
        )

        XCTAssertEqual(store.preferences.language, .french)
#if os(iOS) || os(macOS)
        XCTAssertEqual(storedAppleLanguages(defaults: defaults, domainName: suiteName), ["fr"])
#else
        XCTAssertNil(storedAppleLanguages(defaults: defaults, domainName: suiteName))
#endif
    }

    func testLaunchAdoptsExternalAppleLanguagesSelectionIntoStoredPreference() throws {
        let (defaults, suiteName) = try temporaryDefaultsSuite(prefix: "adoptAppleLanguages")
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(["fr-CA"], forKey: "AppleLanguages")
        let store = try ProgressStoreService.inMemoryForTests(defaults: defaults, defaultsDomainName: suiteName)

#if os(iOS) || os(macOS)
        XCTAssertEqual(store.preferences.language, .french)
        XCTAssertEqual(storedAppleLanguages(defaults: defaults, domainName: suiteName), ["fr-CA"])
#else
        XCTAssertEqual(store.preferences.language, .system)
#endif
    }

    func testLaunchKeepsPreferenceWhenAppleLanguagesMatchesLastAppliedValue() throws {
        let (defaults, suiteName) = try temporaryDefaultsSuite(prefix: "unchangedAppleLanguages")
        defer { defaults.removePersistentDomain(forName: suiteName) }
        ProgressStoreService.applyInterfaceLanguagePreference(.french, defaults: defaults)
        let container = try preferencesContainer(language: ApplePreferences.LanguagePreference.french.rawValue)
        let store = try ProgressStoreService(
            container: container,
            morseCourseProgressURL: try temporaryMorseCourseProgressURL(),
            defaults: defaults,
            defaultsDomainName: suiteName
        )

        XCTAssertEqual(store.preferences.language, .french)
#if os(iOS) || os(macOS)
        XCTAssertEqual(storedAppleLanguages(defaults: defaults, domainName: suiteName), ["fr"])
#else
        XCTAssertNil(storedAppleLanguages(defaults: defaults, domainName: suiteName))
#endif
    }

    func testPickerChangeWritesAppleLanguagesButUnchangedPreferencesDoNotRewriteIt() throws {
        let (defaults, suiteName) = try temporaryDefaultsSuite(prefix: "pickerAppleLanguages")
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = try ProgressStoreService.inMemoryForTests(defaults: defaults, defaultsDomainName: suiteName)

        var preferences = store.preferences
        preferences.language = .french
        try store.updatePreferences(preferences)
#if os(iOS) || os(macOS)
        XCTAssertEqual(storedAppleLanguages(defaults: defaults, domainName: suiteName), ["fr"])
#else
        XCTAssertNil(storedAppleLanguages(defaults: defaults, domainName: suiteName))
#endif

        preferences.practiceMode = .reviewLater
        defaults.set(["en"], forKey: "AppleLanguages")
        try store.updatePreferences(preferences)
        XCTAssertEqual(storedAppleLanguages(defaults: defaults, domainName: suiteName), ["en"])
    }

    func testResetClearsAppleLanguagesAndLanguagePreference() throws {
        let (defaults, suiteName) = try temporaryDefaultsSuite(prefix: "resetAppleLanguages")
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = try ProgressStoreService.inMemoryForTests(defaults: defaults, defaultsDomainName: suiteName)
        var preferences = store.preferences
        preferences.language = .french
        try store.updatePreferences(preferences)

        try store.resetAllData(defaults: defaults)

        XCTAssertEqual(store.preferences.language, .system)
        XCTAssertNil(storedAppleLanguages(defaults: defaults, domainName: suiteName))
        XCTAssertEqual(storedAppleLanguageLastApplied(defaults: defaults, domainName: suiteName), ApplePreferences.LanguagePreference.system.rawValue)
    }

    func testResetFailureKeepsPreviousAppleLanguagesAndPreference() throws {
        let (defaults, suiteName) = try temporaryDefaultsSuite(prefix: "resetFailureLanguage")
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = try ProgressStoreService.inMemoryForTests(defaults: defaults, defaultsDomainName: suiteName)
        var preferences = store.preferences
        preferences.language = .french
        try store.updatePreferences(preferences)
        XCTAssertEqual(storedAppleLanguages(defaults: defaults, domainName: suiteName), ["fr"])

        store.failNextResetAfterPreferenceDeleteForTesting = true
        XCTAssertThrowsError(try store.resetAllData(defaults: defaults)) { error in
            XCTAssertEqual(error as? ProgressStoreInjectedFailure, .resetAfterPreferenceDelete)
        }

        XCTAssertEqual(store.preferences.language, .french)
        XCTAssertEqual(storedAppleLanguages(defaults: defaults, domainName: suiteName), ["fr"])
        XCTAssertEqual(storedAppleLanguageLastApplied(defaults: defaults, domainName: suiteName), ApplePreferences.LanguagePreference.french.rawValue)
    }

    func testLaunchAdoptsRemovedAppleLanguagesKeyAsSystemDefault() throws {
        let (defaults, suiteName) = try temporaryDefaultsSuite(prefix: "removedAppleLanguages")
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = try ProgressStoreService.inMemoryForTests(defaults: defaults, defaultsDomainName: suiteName)
        var preferences = store.preferences
        preferences.language = .french
        try store.updatePreferences(preferences)
        defaults.removeObject(forKey: "AppleLanguages")

        let reopened = try ProgressStoreService(
            container: store.container,
            morseCourseProgressURL: try temporaryMorseCourseProgressURL(),
            defaults: defaults,
            defaultsDomainName: suiteName
        )

        XCTAssertEqual(reopened.preferences.language, .system)
        XCTAssertNil(storedAppleLanguages(defaults: defaults, domainName: suiteName))
        XCTAssertEqual(storedAppleLanguageLastApplied(defaults: defaults, domainName: suiteName), ApplePreferences.LanguagePreference.system.rawValue)
    }

    func testLaunchIgnoresRegisteredAppleLanguagesValue() throws {
        let (defaults, suiteName) = try temporaryDefaultsSuite(prefix: "registeredAppleLanguages")
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.register(defaults: ["AppleLanguages": ["fr"]])

        let store = try ProgressStoreService.inMemoryForTests(defaults: defaults, defaultsDomainName: suiteName)

        XCTAssertEqual(store.preferences.language, .system)
        XCTAssertNil(storedAppleLanguages(defaults: defaults, domainName: suiteName))
        XCTAssertEqual(storedAppleLanguageLastApplied(defaults: defaults, domainName: suiteName), ApplePreferences.LanguagePreference.system.rawValue)
    }

    func testLegacyStoredFrenchAdoptsExistingPersistentAppleLanguagesInsteadOfOverwriting() throws {
        let (defaults, suiteName) = try temporaryDefaultsSuite(prefix: "legacyFrenchExistingAppleLanguages")
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(["en-CA"], forKey: "AppleLanguages")
        let container = try preferencesContainer(language: ApplePreferences.LanguagePreference.french.rawValue)

        let store = try ProgressStoreService(
            container: container,
            morseCourseProgressURL: try temporaryMorseCourseProgressURL(),
            defaults: defaults,
            defaultsDomainName: suiteName
        )

        XCTAssertEqual(store.preferences.language, .english)
        XCTAssertEqual(storedAppleLanguages(defaults: defaults, domainName: suiteName), ["en-CA"])
        XCTAssertEqual(storedAppleLanguageLastApplied(defaults: defaults, domainName: suiteName), ApplePreferences.LanguagePreference.english.rawValue)
    }

    func testImportWritesAppleLanguagesToInjectedDefaultsWhenLanguageChanges() throws {
        let (defaults, suiteName) = try temporaryDefaultsSuite(prefix: "importLanguage")
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let store = try ProgressStoreService.inMemoryForTests(defaults: defaults, defaultsDomainName: suiteName)

        try store.importData(emptyProgressExport(bank: bank, language: .french), bank: bank)

        XCTAssertEqual(store.preferences.language, .french)
        XCTAssertEqual(storedAppleLanguages(defaults: defaults, domainName: suiteName), ["fr"])
        XCTAssertEqual(storedAppleLanguageLastApplied(defaults: defaults, domainName: suiteName), ApplePreferences.LanguagePreference.french.rawValue)
    }

    func testImportKeepsPersistedAppleLanguagesWhenLanguageDoesNotChange() throws {
        let (defaults, suiteName) = try temporaryDefaultsSuite(prefix: "importUnchangedLanguage")
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let store = try ProgressStoreService.inMemoryForTests(defaults: defaults, defaultsDomainName: suiteName)
        var preferences = store.preferences
        preferences.language = .french
        try store.updatePreferences(preferences)
        defaults.set(["fr-CA"], forKey: "AppleLanguages")

        try store.importData(emptyProgressExport(bank: bank, language: .french), bank: bank)

        XCTAssertEqual(store.preferences.language, .french)
        XCTAssertEqual(storedAppleLanguages(defaults: defaults, domainName: suiteName), ["fr-CA"])
        XCTAssertEqual(storedAppleLanguageLastApplied(defaults: defaults, domainName: suiteName), ApplePreferences.LanguagePreference.french.rawValue)
    }

    func testInMemoryLanguageOperationsDoNotMutateStandardLanguageDefaults() throws {
        let before = standardLanguageDefaultsSnapshot()
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let store = try ProgressStoreService.inMemoryForTests()

        var preferences = store.preferences
        preferences.language = .french
        try store.updatePreferences(preferences)
        try store.importData(emptyProgressExport(bank: bank, language: .english), bank: bank)
        XCTAssertEqual(standardLanguageDefaultsSnapshot(), before)
        try store.resetAllData()
        XCTAssertEqual(standardLanguageDefaultsSnapshot(), before)
        preferences = store.preferences
        preferences.language = .english
        try store.updatePreferences(preferences)
        XCTAssertEqual(standardLanguageDefaultsSnapshot(), before)
    }

    func testLegacyLanguageMigrationSaveFailureDoesNotBlockStartupAndRetries() throws {
        let (defaults, suiteName) = try temporaryDefaultsSuite(prefix: "legacyLanguageFailure")
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let container = try preferencesContainer(language: ApplePreferences.LanguagePreference.english.rawValue)
        ProgressStoreService.failNextLegacyLanguageMigrationSaveForTesting = true
        defer { ProgressStoreService.failNextLegacyLanguageMigrationSaveForTesting = false }
        let store = try ProgressStoreService(
            container: container,
            morseCourseProgressURL: try temporaryMorseCourseProgressURL(),
            defaults: defaults,
            defaultsDomainName: suiteName
        )
        XCTAssertEqual(store.preferences.language, .english)

        let reopened = try ProgressStoreService(
            container: container,
            morseCourseProgressURL: try temporaryMorseCourseProgressURL(),
            defaults: defaults,
            defaultsDomainName: suiteName
        )
        XCTAssertEqual(reopened.preferences.language, .system)
    }

    func testAppleInterfaceLanguagePreferenceWritesAppleLanguagesForNextLaunch() throws {
        let (defaults, suiteName) = try temporaryDefaultsSuite(prefix: "appleLanguages")
        defer { defaults.removePersistentDomain(forName: suiteName) }

        ProgressStoreService.applyInterfaceLanguagePreference(.english, defaults: defaults)
#if os(iOS) || os(macOS)
        XCTAssertEqual(storedAppleLanguages(defaults: defaults, domainName: suiteName), ["en"])

        ProgressStoreService.applyInterfaceLanguagePreference(.french, defaults: defaults)
        XCTAssertEqual(storedAppleLanguages(defaults: defaults, domainName: suiteName), ["fr"])

        ProgressStoreService.applyInterfaceLanguagePreference(.system, defaults: defaults)
        XCTAssertNil(storedAppleLanguages(defaults: defaults, domainName: suiteName))
#else
        XCTAssertNil(storedAppleLanguages(defaults: defaults, domainName: suiteName))
#endif
    }

    func testProgressStoreRoundTripExportImportReset() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let store = try ProgressStoreService.inMemoryForTests()
        XCTAssertEqual(store.preferences.language, .system)
        XCTAssertNotEqual(store.morseCourseProgressURLForTesting, ProgressStoreService.morseCourseProgressURL)
        let record = try applyAnswer(existing: nil, update: AnswerUpdate(
            questionId: "B-001-001-001",
            bankId: bank.manifest.bankId,
            isCorrect: true,
            now: "2026-01-02T03:04:05.000Z"
        ))
        try store.saveQuestionProgress([record])
        var preferences = store.preferences
        preferences.practiceMode = .reviewLater
        preferences.examTimerEnabled = true
        preferences.language = .french
        preferences.theme = .dark
        try store.updatePreferences(preferences)

        let generated = try AppleStudyEngine.generatedMockExam(bank: bank, seed: "progress-store-round-trip")
        let attempt = try AppleStudyEngine.buildExamAttempt(
            bank: bank,
            seed: "progress-store-round-trip",
            startedAt: "2026-01-02T03:04:05.000Z",
            submittedAt: "2026-01-02T04:04:05.000Z",
            timerEnabled: true,
            secondsElapsed: 3600,
            generatedItems: generated.items,
            selectedByQuestionId: Dictionary(uniqueKeysWithValues: generated.items.enumerated().map { index, item in (item.questionId, index < 80 ? Optional(0) : Optional(1)) }),
            flaggedQuestionIds: [generated.items[0].questionId]
        )
        try store.saveExamAttempt(attempt)
        let morseProgress = MorseCourseProgressExport(
            courseId: "ised-koch-g4fon-v1",
            lessonProgress: [MorseLessonProgressRecord(
                lessonId: "koch-001",
                attempts: 1,
                bestAccuracy: 1,
                lastAccuracy: 1,
                lastAttemptedAt: "2026-01-02T04:30:00.000Z",
                completedAt: "2026-01-02T04:30:00.000Z"
            )],
            characterStats: [MorseCharacterStatRecord(
                character: "K",
                attempts: 1,
                correctAttempts: 1,
                recentResults: [true],
                lastPracticedAt: "2026-01-02T04:30:00.000Z"
            )],
            dailyActivity: [MorseDailyActivityRecord(date: "2026-01-02", lessonsCompleted: 1)]
        )
        try store.saveMorseCourseProgress(morseProgress)
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.morseCourseProgressURLForTesting.path(percentEncoded: false)))
        let entityContext = ModelContext(store.container)
        XCTAssertEqual(try entityContext.fetch(FetchDescriptor<MorseCourseProgressEntity>()).count, 1)

        let exported = try store.exportData(bank: bank, exportedAt: "2026-01-02T05:04:05.000Z")
        XCTAssertEqual(exported.schema, "canadian-ham.progress-export")
        XCTAssertEqual(exported.version, 1)
        XCTAssertEqual(exported.questionProgress.count, 1)
        XCTAssertEqual(exported.examAttempts.count, 1)
        XCTAssertEqual(exported.preferences.practiceMode, "review-later")
        XCTAssertEqual(exported.preferences.language, "fr")
        XCTAssertEqual(exported.morseCourseProgress, morseProgress)

        let importedStore = try ProgressStoreService.inMemoryForTests()
        XCTAssertNotEqual(importedStore.morseCourseProgressURLForTesting, store.morseCourseProgressURLForTesting)
        XCTAssertNil(try importedStore.morseCourseProgress())
        try importedStore.importData(exported, bank: bank)
        XCTAssertEqual(try importedStore.questionProgressRecords(), exported.questionProgress)
        XCTAssertEqual(try importedStore.examAttempts(), exported.examAttempts)
        XCTAssertEqual(importedStore.preferences.practiceMode, .reviewLater)
        XCTAssertTrue(importedStore.preferences.examTimerEnabled)
        XCTAssertEqual(importedStore.preferences.language, .french)
        XCTAssertEqual(importedStore.preferences.theme, .dark)
        XCTAssertEqual(try importedStore.morseCourseProgress(), morseProgress)

        try importedStore.resetAllData()
        XCTAssertEqual(try importedStore.questionProgressRecords().count, 0)
        XCTAssertEqual(try importedStore.examAttempts().count, 0)
        XCTAssertNil(try importedStore.morseCourseProgress())
        XCTAssertEqual(importedStore.preferences, .default)
    }

    func testProgressExportRoundTripsMorseSettingsInWebCompatiblePreferences() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let store = try ProgressStoreService.inMemoryForTests()
        let morseSettings = MorseTrainerSettings(
            toneHz: 700,
            characterWpm: 18,
            effectiveWpm: 6,
            timingProfile: .general,
            volume: 0.4,
            outputMode: .visualTape
        ).normalized()
        let exportedMorseSettings = ExportedMorseSettings(
            toneHz: morseSettings.exportedPreferences.toneHz,
            characterWpm: morseSettings.exportedPreferences.characterWpm,
            effectiveWpm: morseSettings.exportedPreferences.effectiveWpm,
            timingProfile: morseSettings.exportedPreferences.timingProfile,
            volume: morseSettings.exportedPreferences.volume,
            outputMode: morseSettings.exportedPreferences.outputMode
        )

        let serialized = try store.serializedExport(bank: bank, exportedAt: "2026-01-02T05:04:05.000Z", morseSettings: exportedMorseSettings)
        let decoded = try JSONDecoder().decode(ProgressExportV1.self, from: Data(serialized.utf8))
        let decodedMorseForApp = CanadianHam.ExportedMorseSettings(
            toneHz: decoded.preferences.morse.toneHz,
            characterWpm: decoded.preferences.morse.characterWpm,
            effectiveWpm: decoded.preferences.morse.effectiveWpm,
            timingProfile: decoded.preferences.morse.timingProfile,
            volume: decoded.preferences.morse.volume,
            outputMode: decoded.preferences.morse.outputMode
        )
        let importedMorseSettings = CanadianHam.MorseTrainerSettings(exported: decodedMorseForApp).normalized()

        XCTAssertEqual(decoded.preferences.morse, exportedMorseSettings)
        XCTAssertEqual(importedMorseSettings, morseSettings)
        XCTAssertTrue(serialized.contains("\"morse\""), "Apple exports should use the web preferences.morse shape.")
        XCTAssertNoThrow(try ProgressStoreService.inMemoryForTests().importData(decoded, bank: bank))
    }

    func testMorseExportMapsHapticsToWebCompatibleAudio() {
        let exported = MorseTrainerSettings(toneHz: 650, characterWpm: 15, effectiveWpm: 5, timingProfile: .isedParis, volume: 0.6, outputMode: .haptics).exportedPreferences

        XCTAssertEqual(exported.outputMode, "audio")
    }

    func testMorseImportRejectsExplicitNullMorseValues() throws {
        func export(_ morse: String) -> Data {
            Data("""
            {
              "schema": "canadian-ham.progress-export",
              "version": 1,
              "exportedAt": "2026-01-02T05:04:05.000Z",
              "bankId": "basic-2025-07-15",
              "questionProgress": [],
              "examAttempts": [],
              "lessonProgress": [],
              "lessonQuizAttempts": [],
              "preferences": { "practiceMode": "immediate", "examTimerEnabled": false, "theme": "system"\(morse) }
            }
            """.utf8)
        }
        XCTAssertThrowsError(try JSONDecoder().decode(ProgressExportV1.self, from: export(", \"morse\": null")))
        XCTAssertThrowsError(try JSONDecoder().decode(ProgressExportV1.self, from: export(", \"morse\": { \"outputMode\": null }")))
        XCTAssertThrowsError(try JSONDecoder().decode(ProgressExportV1.self, from: export(", \"morse\": { \"toneHz\": null }")))
        let missing = try JSONDecoder().decode(ProgressExportV1.self, from: export(""))
        XCTAssertEqual(missing.preferences.morse, .default)
        let partial = try JSONDecoder().decode(ProgressExportV1.self, from: export(", \"morse\": { \"toneHz\": 700 }"))
        XCTAssertEqual(partial.preferences.morse.toneHz, 700)
        XCTAssertEqual(partial.preferences.morse.outputMode, ExportedMorseSettings.default.outputMode)
    }

    func testMorseImportDecodesMissingAndPartialMorsePreferences() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let missingMorseJSON = """
        {
          "schema": "canadian-ham.progress-export",
          "version": 1,
          "exportedAt": "2026-01-02T05:04:05.000Z",
          "bankId": "\(bank.manifest.bankId)",
          "questionProgress": [],
          "examAttempts": [],
          "lessonProgress": [],
          "lessonQuizAttempts": [],
          "preferences": { "practiceMode": "immediate", "examTimerEnabled": false, "theme": "system" }
        }
        """
        let task123WebJSON = """
        {
          "schema": "canadian-ham.progress-export",
          "version": 1,
          "exportedAt": "2026-01-02T05:04:05.000Z",
          "bankId": "\(bank.manifest.bankId)",
          "questionProgress": [],
          "examAttempts": [],
          "lessonProgress": [],
          "lessonQuizAttempts": [],
          "preferences": {
            "practiceMode": "immediate",
            "examTimerEnabled": false,
            "theme": "system",
            "morse": { "toneHz": 720, "characterWpm": 18, "effectiveWpm": 7, "timingProfile": "general", "volume": 0.45 }
          }
        }
        """
        let partialMorseJSON = """
        {
          "schema": "canadian-ham.progress-export",
          "version": 1,
          "exportedAt": "2026-01-02T05:04:05.000Z",
          "bankId": "\(bank.manifest.bankId)",
          "questionProgress": [],
          "examAttempts": [],
          "lessonProgress": [],
          "lessonQuizAttempts": [],
          "preferences": {
            "practiceMode": "immediate",
            "examTimerEnabled": false,
            "theme": "system",
            "morse": { "outputMode": "visualBeacon" }
          }
        }
        """

        let missingMorse = try JSONDecoder().decode(ProgressExportV1.self, from: Data(missingMorseJSON.utf8))
        let task123Web = try JSONDecoder().decode(ProgressExportV1.self, from: Data(task123WebJSON.utf8))
        let partialMorse = try JSONDecoder().decode(ProgressExportV1.self, from: Data(partialMorseJSON.utf8))

        XCTAssertEqual(missingMorse.preferences.morse, .default)
        XCTAssertEqual(task123Web.preferences.morse.outputMode, "audio")
        let task123MorseForApp = CanadianHam.ExportedMorseSettings(
            toneHz: task123Web.preferences.morse.toneHz,
            characterWpm: task123Web.preferences.morse.characterWpm,
            effectiveWpm: task123Web.preferences.morse.effectiveWpm,
            timingProfile: task123Web.preferences.morse.timingProfile,
            volume: task123Web.preferences.morse.volume,
            outputMode: task123Web.preferences.morse.outputMode
        )
        XCTAssertEqual(CanadianHam.MorseTrainerSettings(exported: task123MorseForApp).normalized().outputMode, .audio)
        XCTAssertEqual(partialMorse.preferences.morse.toneHz, ExportedMorseSettings.default.toneHz)
        XCTAssertEqual(partialMorse.preferences.morse.outputMode, "visualBeacon")
        XCTAssertNoThrow(try ProgressStoreService.inMemoryForTests().importData(missingMorse, bank: bank))
        XCTAssertNoThrow(try ProgressStoreService.inMemoryForTests().importData(task123Web, bank: bank))
        XCTAssertNoThrow(try ProgressStoreService.inMemoryForTests().importData(partialMorse, bank: bank))
    }

    func testProgressImportDecodesOlderAnsweredWithHelpFieldsAsFalse() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let json = """
        {
          "schema": "canadian-ham.progress-export",
          "version": 1,
          "exportedAt": "2026-01-02T05:04:05.000Z",
          "bankId": "\(bank.manifest.bankId)",
          "questionProgress": [
            {
              "questionId": "B-001-001-001",
              "bankId": "\(bank.manifest.bankId)",
              "attempts": 1,
              "correctAttempts": 1,
              "lastAttemptedAt": "2026-01-02T03:04:05.000Z",
              "lastResult": "correct",
              "recentResults": [true],
              "leitner": { "box": 1, "dueAt": "2026-01-03T03:04:05.000Z" },
              "notes": null
            }
          ],
          "examAttempts": [],
          "lessonProgress": [],
          "lessonQuizAttempts": [],
          "syncDeviceRows": {
            "questionProgress": [
              {
                "deviceId": "iphone",
                "record": {
                  "questionId": "B-001-001-001",
                  "bankId": "\(bank.manifest.bankId)",
                  "attempts": 1,
                  "correctAttempts": 1,
                  "lastAttemptedAt": "2026-01-02T03:04:05.000Z",
                  "lastResult": "correct",
                  "recentResults": [true],
                  "leitner": { "box": 1, "dueAt": "2026-01-03T03:04:05.000Z" },
                  "notes": null
                }
              }
            ],
            "examAttempts": [],
            "lessonProgress": [],
            "lessonQuizAttempts": [],
            "morseCourseProgress": []
          },
          "preferences": { "practiceMode": "immediate", "examTimerEnabled": false, "theme": "system" }
        }
        """
        let decoded = try JSONDecoder().decode(ProgressExportV1.self, from: Data(json.utf8))
        let store = try ProgressStoreService.inMemoryForTests(localDeviceID: "ipad")

        XCTAssertTrue(store.validate(decoded, bank: bank).isEmpty)
        try store.importData(decoded, bank: bank)

        let expected = QuestionProgressRecord(
            questionId: "B-001-001-001",
            bankId: bank.manifest.bankId,
            attempts: 1,
            correctAttempts: 1,
            lastAttemptedAt: "2026-01-02T03:04:05.000Z",
            lastResult: .correct,
            lastAnsweredWithHelp: false,
            recentResults: [true],
            recentAnsweredWithHelp: [false],
            leitner: LeitnerState(box: 1, dueAt: "2026-01-03T03:04:05.000Z")
        )
        XCTAssertEqual(try store.questionProgressRecords(), [expected])
        XCTAssertEqual(try store.exportData(bank: bank, exportedAt: "2026-01-02T06:04:05.000Z").syncDeviceRows?.questionProgress, [DeviceQuestionProgressRecord(deviceId: "iphone", record: expected)])
    }

    func testSwiftDataQuestionProgressEntityDefaultsHelpFieldsForLightweightMigration() throws {
        let store = try ProgressStoreService.inMemoryForTests()
        let context = ModelContext(store.container)
        let entity = QuestionProgressEntity(
            questionId: "B-001-001-001",
            bankId: basicBankId,
            attempts: 1,
            correctAttempts: 1,
            lastAttemptedAt: "2026-01-02T03:04:05.000Z",
            lastResult: AnswerResult.correct.rawValue,
            recentResultsData: try JSONEncoder().encode([true]),
            leitnerBox: 1,
            dueAt: "2026-01-03T03:04:05.000Z"
        )
        context.insert(entity)
        try context.save()

        let fetched = try XCTUnwrap(context.fetch(FetchDescriptor<QuestionProgressEntity>()).first)
        XCTAssertFalse(fetched.lastAnsweredWithHelp)
        XCTAssertEqual(try JSONDecoder().decode([Bool].self, from: fetched.recentAnsweredWithHelpData), [])
    }

    func testImportRejectsUnsupportedLanguagePreferenceValues() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let cases = [
            #""de""#,
            #"null"#
        ]

        for languageJSON in cases {
            let json = """
            {
              "schema": "canadian-ham.progress-export",
              "version": 1,
              "exportedAt": "2026-01-02T05:04:05.000Z",
              "bankId": "\(bank.manifest.bankId)",
              "questionProgress": [],
              "examAttempts": [],
              "lessonProgress": [],
              "lessonQuizAttempts": [],
              "preferences": {
                "practiceMode": "immediate",
                "examTimerEnabled": false,
                "language": \(languageJSON),
                "theme": "system"
              }
            }
            """
            let decoded = try JSONDecoder().decode(ProgressExportV1.self, from: Data(json.utf8))
            let store = try ProgressStoreService.inMemoryForTests()
            let errors = store.validate(decoded, bank: bank)

            XCTAssertTrue(errors.contains("Import preferences.language is invalid."), "Expected invalid language error, got: \(errors)")
            XCTAssertThrowsError(try store.importData(decoded, bank: bank)) { error in
                guard case ProgressStoreError.validationFailed(let validationErrors) = error else {
                    return XCTFail("Expected validationFailed, got: \(error)")
                }
                XCTAssertTrue(validationErrors.contains("Import preferences.language is invalid."), "Expected invalid language error, got: \(validationErrors)")
            }
        }
    }

    func testMorseImportRejectsUnsupportedMorsePreferenceEnums() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let cases = [
            (morseJSON: #"{ "outputMode": "haptics" }"#, expectedError: "Import preferences.morse.outputMode is invalid."),
            (morseJSON: #"{ "timingProfile": "fast" }"#, expectedError: "Import preferences.morse.timingProfile is invalid.")
        ]

        for testCase in cases {
            let json = """
            {
              "schema": "canadian-ham.progress-export",
              "version": 1,
              "exportedAt": "2026-01-02T05:04:05.000Z",
              "bankId": "\(bank.manifest.bankId)",
              "questionProgress": [],
              "examAttempts": [],
              "lessonProgress": [],
              "lessonQuizAttempts": [],
              "preferences": {
                "practiceMode": "immediate",
                "examTimerEnabled": false,
                "theme": "system",
                "morse": \(testCase.morseJSON)
              }
            }
            """
            let decoded = try JSONDecoder().decode(ProgressExportV1.self, from: Data(json.utf8))
            let store = try ProgressStoreService.inMemoryForTests()
            let errors = store.validate(decoded, bank: bank)

            XCTAssertTrue(errors.contains(testCase.expectedError), "Expected \(testCase.expectedError), got: \(errors)")
            XCTAssertThrowsError(try store.importData(decoded, bank: bank)) { error in
                guard case ProgressStoreError.validationFailed(let validationErrors) = error else {
                    return XCTFail("Expected validationFailed, got: \(error)")
                }
                XCTAssertTrue(validationErrors.contains(testCase.expectedError), "Expected \(testCase.expectedError), got: \(validationErrors)")
            }
        }
    }

    func testMigratesLegacyMorseCourseProgressJSONIntoSwiftDataEntity() throws {
        let directory = try temporaryProgressStoreDirectory()
        let urls = ProgressStoreURLs(progressDirectory: directory)
        let legacyProgress = sampleMorseCourseProgress()
        try JSONEncoder().encode(legacyProgress).write(to: urls.morseCourseProgressURL, options: [.atomic])

        let store = try openProgressStoreForTests(storeURLs: urls, iCloudSyncEnabled: false, layout: .legacySingleStore)

        XCTAssertEqual(try store.morseCourseProgress(), legacyProgress)
        XCTAssertFalse(FileManager.default.fileExists(atPath: urls.morseCourseProgressURL.path(percentEncoded: false)))
        let entityContext = ModelContext(store.container)
        XCTAssertEqual(try entityContext.fetch(FetchDescriptor<MorseCourseProgressEntity>()).count, 1)
    }

    func testCorruptLegacyMorseCourseProgressJSONDoesNotBlockOpeningStore() throws {
        let directory = try temporaryProgressStoreDirectory()
        let urls = ProgressStoreURLs(progressDirectory: directory)
        try Data("not json".utf8).write(to: urls.morseCourseProgressURL, options: [.atomic])

        let store = try openProgressStoreForTests(storeURLs: urls, iCloudSyncEnabled: false, layout: .legacySingleStore)

        XCTAssertNil(try store.morseCourseProgress())
        XCTAssertTrue(FileManager.default.fileExists(atPath: urls.morseCourseProgressURL.path(percentEncoded: false)))
    }

    func testMorseCourseProgressRoundTripsTwentyRecentCharacterResults() throws {
        let store = try ProgressStoreService.inMemoryForTests()
        let recentResults = (0..<20).map { $0.isMultiple(of: 2) }
        let progress = MorseCourseProgressExport(
            courseId: "ised-koch-g4fon-v1",
            lessonProgress: [],
            characterStats: [MorseCharacterStatRecord(
                character: "K",
                attempts: 20,
                correctAttempts: 10,
                recentResults: recentResults,
                lastPracticedAt: "2026-01-02T04:30:00.000Z"
            )],
            dailyActivity: []
        )

        try store.saveMorseCourseProgress(progress)

        XCTAssertEqual(try store.morseCourseProgress(), progress)
        XCTAssertEqual(try store.exportData(bank: try QuestionBankStore.load(from: Bundle(for: Self.self)), exportedAt: "2026-01-02T05:04:05.000Z").morseCourseProgress, progress)
    }

    func testImportsOlderExportWithoutMorseCourseProgressKeepsExistingMorseProgress() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let store = try ProgressStoreService.inMemoryForTests()
        let originalMorseProgress = MorseCourseProgressExport(
            courseId: "ised-koch-g4fon-v1",
            lessonProgress: [],
            characterStats: [],
            dailyActivity: []
        )
        try store.saveMorseCourseProgress(originalMorseProgress)
        let json = """
        {
          "schema": "canadian-ham.progress-export",
          "version": 1,
          "exportedAt": "2026-01-02T05:04:05.000Z",
          "bankId": "\(bank.manifest.bankId)",
          "questionProgress": [],
          "examAttempts": [],
          "lessonProgress": [],
          "lessonQuizAttempts": [],
          "preferences": { "practiceMode": "immediate", "examTimerEnabled": false, "theme": "system" }
        }
        """
        let decoded = try JSONDecoder().decode(ProgressExportV1.self, from: Data(json.utf8))

        try store.importData(decoded, bank: bank)

        XCTAssertEqual(try store.morseCourseProgress(), originalMorseProgress)
    }

    func testOldFormatImportWithMorseProgressReplacesAllExistingDeviceRows() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let importedMorse = sampleMorseCourseProgress(lessonId: "koch-001")
        let replacementMorse = MorseCourseProgressExport(
            courseId: "ised-koch-g4fon-v1",
            lessonProgress: [MorseLessonProgressRecord(lessonId: "koch-002", attempts: 1, bestAccuracy: 1, lastAccuracy: 1, lastAttemptedAt: "2026-01-03T04:30:00.000Z", completedAt: nil)],
            characterStats: [MorseCharacterStatRecord(character: "M", attempts: 1, correctAttempts: 1, recentResults: [true], lastPracticedAt: "2026-01-03T04:30:00.000Z")],
            dailyActivity: [MorseDailyActivityRecord(date: "2026-01-03", lessonsCompleted: 1)]
        )
        let store = try ProgressStoreService.inMemoryForTests(localDeviceID: "ipad")
        let imported = ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: "2026-01-02T05:04:05.000Z",
            bankId: bank.manifest.bankId,
            questionProgress: [],
            examAttempts: [],
            lessonProgress: [],
            lessonQuizAttempts: [],
            morseCourseProgress: importedMorse,
            syncDeviceRows: ProgressSyncDeviceRows(
                questionProgress: [],
                examAttempts: [],
                lessonProgress: [],
                lessonQuizAttempts: [],
                morseCourseProgress: [DeviceMorseCourseProgressRecord(deviceId: "iphone", progress: importedMorse)]
            ),
            preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
        )
        try store.importData(imported, bank: bank)
        let oldFormat = ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: "2026-01-03T05:04:05.000Z",
            bankId: bank.manifest.bankId,
            questionProgress: [],
            examAttempts: [],
            lessonProgress: [],
            lessonQuizAttempts: [],
            morseCourseProgress: replacementMorse,
            preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
        )

        try store.importData(oldFormat, bank: bank)

        XCTAssertEqual(try store.morseCourseProgress(), replacementMorse)
        XCTAssertEqual(try store.exportData(bank: bank, exportedAt: "2026-01-03T06:04:05.000Z").syncDeviceRows?.morseCourseProgress.map(\.deviceId), ["ipad"])
    }

    func testImportingTheSameExportTwiceRestoresIdenticalProgressAttemptsAndLessons() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let store = try ProgressStoreService.inMemoryForTests()
        let record = try applyAnswer(existing: nil, update: AnswerUpdate(
            questionId: "B-001-001-001",
            bankId: bank.manifest.bankId,
            isCorrect: true,
            now: "2026-01-02T03:04:05.000Z"
        ))
        try store.saveQuestionProgress([record])
        let attempt = try mockAttempt(bank: bank, seed: "same-export", submittedAt: "2026-01-02T04:04:05.000Z")
        try store.saveExamAttempt(attempt)
        let lessonProgress = LessonProgressRecord(lessonId: "L-005-01", readAt: "2026-01-02T03:10:00.000Z", readCount: 2)
        try store.saveLessonProgress(lessonProgress)
        let lessonQuizAttempt = LessonQuizAttempt(
            id: "lesson-quiz-same-export",
            quizId: "QZ-L-005-01-A",
            lessonId: "L-005-01",
            submittedAt: "2026-01-02T03:20:00.000Z",
            correct: 1,
            total: 1,
            percent: 100,
            officialQuestionIds: ["B-005-001-001"],
            incorrectOfficialQuestionIds: [],
            incorrectConceptCheckIds: []
        )
        try store.saveLessonQuizAttempt(lessonQuizAttempt, questionProgress: [record])
        let morseProgress = sampleMorseCourseProgress()
        try store.saveMorseCourseProgress(morseProgress)
        var preferences = store.preferences
        preferences.practiceMode = .reviewLater
        preferences.examTimerEnabled = true
        preferences.theme = .dark
        try store.updatePreferences(preferences)

        let exported = try store.exportData(bank: bank, exportedAt: "2026-01-02T05:04:05.000Z")

        try store.importData(exported, bank: bank)
        let firstRestore = try progressSnapshot(from: store)
        try store.importData(exported, bank: bank)
        let secondRestore = try progressSnapshot(from: store)

        XCTAssertEqual(firstRestore, secondRestore)
        XCTAssertEqual(secondRestore.questionProgress, exported.questionProgress)
        XCTAssertEqual(secondRestore.examAttempts, exported.examAttempts)
        XCTAssertEqual(secondRestore.lessonProgress, [lessonProgress])
        XCTAssertEqual(secondRestore.lessonQuizAttempts, [lessonQuizAttempt])
        XCTAssertEqual(secondRestore.morseCourseProgress, morseProgress)
        XCTAssertEqual(secondRestore.preferences.practiceMode, .reviewLater)
        XCTAssertTrue(secondRestore.preferences.examTimerEnabled)
        XCTAssertEqual(secondRestore.preferences.theme, .dark)
    }

    func testAdvancedImportRejectsHonoursAttempts() throws {
        let advancedBank = try QuestionBankStore.load(bankId: .advanced, from: Bundle(for: Self.self))
        let advancedAttempt = try mockAttempt(bank: advancedBank, seed: "advanced-honours-import", submittedAt: "2026-01-03T04:04:05.000Z")
        let invalidAttempt = StoredExamAttempt(
            id: advancedAttempt.id,
            bankId: advancedAttempt.bankId,
            mode: advancedAttempt.mode,
            seed: advancedAttempt.seed,
            startedAt: advancedAttempt.startedAt,
            submittedAt: advancedAttempt.submittedAt,
            timer: advancedAttempt.timer,
            items: advancedAttempt.items,
            score: StoredExamScore(
                bankId: advancedAttempt.score.bankId,
                correct: advancedAttempt.score.correct,
                total: advancedAttempt.score.total,
                percent: advancedAttempt.score.percent,
                passed: advancedAttempt.score.passed,
                honours: true,
                categoryBreakdown: advancedAttempt.score.categoryBreakdown,
                weakSubsectionIds: advancedAttempt.score.weakSubsectionIds
            )
        )
        let data = ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: "2026-01-03T05:04:05.000Z",
            bankId: advancedBank.manifest.bankId,
            questionProgress: [],
            examAttempts: [invalidAttempt],
            lessonProgress: [],
            lessonQuizAttempts: [],
            preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
        )
        let store = try ProgressStoreService.inMemoryForTests()

        let errors = store.validate(data, bank: advancedBank)

        XCTAssertTrue(errors.contains { $0.contains("examAttempts[0].score.honours must be false") })
        XCTAssertThrowsError(try store.importData(data, bank: advancedBank))
    }

    func testAdvancedImportKeepsBasicProgressExamsAndLessonsThenBasicImportKeepsAdvancedProgress() throws {
        let basicBank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let advancedBank = try QuestionBankStore.load(bankId: .advanced, from: Bundle(for: Self.self))
        let store = try ProgressStoreService.inMemoryForTests()

        let originalBasicRecord = try applyAnswer(existing: nil, update: AnswerUpdate(
            questionId: "B-001-001-001",
            bankId: basicBank.manifest.bankId,
            isCorrect: true,
            now: "2026-01-02T03:04:05.000Z"
        ))
        try store.saveQuestionProgress([originalBasicRecord])
        let originalBasicExam = try mockAttempt(bank: basicBank, seed: "basic-original", submittedAt: "2026-01-02T04:04:05.000Z")
        try store.saveExamAttempt(originalBasicExam)
        let originalLessonProgress = LessonProgressRecord(lessonId: "L-005-01", readAt: "2026-01-02T03:10:00.000Z", readCount: 2)
        try store.saveLessonProgress(originalLessonProgress)
        let originalLessonQuizAttempt = LessonQuizAttempt(
            id: "lesson-quiz-original",
            quizId: "QZ-L-005-01-A",
            lessonId: "L-005-01",
            submittedAt: "2026-01-02T03:20:00.000Z",
            correct: 1,
            total: 1,
            percent: 100,
            officialQuestionIds: ["B-005-001-001"],
            incorrectOfficialQuestionIds: [],
            incorrectConceptCheckIds: []
        )
        try store.saveLessonQuizAttempt(originalLessonQuizAttempt, questionProgress: [originalBasicRecord])

        let advancedRecord = try applyAnswer(existing: nil, update: AnswerUpdate(
            questionId: try XCTUnwrap(advancedBank.questions.first?.id),
            bankId: advancedBank.manifest.bankId,
            isCorrect: false,
            now: "2026-01-03T03:04:05.000Z"
        ))
        let advancedExam = try mockAttempt(bank: advancedBank, seed: "advanced-import", submittedAt: "2026-01-03T04:04:05.000Z")
        let advancedExport = ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: "2026-01-03T05:04:05.000Z",
            bankId: advancedBank.manifest.bankId,
            questionProgress: [advancedRecord],
            examAttempts: [advancedExam],
            lessonProgress: [],
            lessonQuizAttempts: [],
            preferences: ExportedPreferences(practiceMode: "review-later", examTimerEnabled: true, theme: "dark")
        )

        try store.importData(advancedExport, bank: advancedBank)

        var questionProgress = try store.questionProgressRecords()
        XCTAssertTrue(questionProgress.contains(originalBasicRecord), "Advanced import must keep Basic question progress")
        XCTAssertTrue(questionProgress.contains(advancedRecord), "Advanced import must add Advanced question progress")
        var examAttempts = try store.examAttempts()
        XCTAssertTrue(examAttempts.contains(originalBasicExam), "Advanced import must keep Basic mock exam attempts")
        XCTAssertTrue(examAttempts.contains(advancedExam), "Advanced import must add Advanced mock exam attempts")
        XCTAssertEqual(try store.lessonProgressRecords(), [originalLessonProgress], "Advanced import must not clear Basic lesson progress")
        XCTAssertEqual(try store.lessonQuizAttempts(), [originalLessonQuizAttempt], "Advanced import must not clear Basic lesson quiz attempts")

        let replacementBasicRecord = try applyAnswer(existing: nil, update: AnswerUpdate(
            questionId: "B-001-001-002",
            bankId: basicBank.manifest.bankId,
            isCorrect: true,
            now: "2026-01-04T03:04:05.000Z"
        ))
        let replacementBasicExam = try mockAttempt(bank: basicBank, seed: "basic-replacement", submittedAt: "2026-01-04T04:04:05.000Z")
        let replacementLessonProgress = LessonProgressRecord(lessonId: "L-005-01", readAt: "2026-01-04T03:10:00.000Z", readCount: 3)
        let replacementLessonQuizAttempt = LessonQuizAttempt(
            id: "lesson-quiz-replacement",
            quizId: "QZ-L-005-01-A",
            lessonId: "L-005-01",
            submittedAt: "2026-01-04T03:20:00.000Z",
            correct: 0,
            total: 1,
            percent: 0,
            officialQuestionIds: ["B-005-001-001"],
            incorrectOfficialQuestionIds: ["B-005-001-001"],
            incorrectConceptCheckIds: []
        )
        let basicExport = ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: "2026-01-04T05:04:05.000Z",
            bankId: basicBank.manifest.bankId,
            questionProgress: [replacementBasicRecord],
            examAttempts: [replacementBasicExam],
            lessonProgress: try archivedArray([replacementLessonProgress]),
            lessonQuizAttempts: try archivedArray([replacementLessonQuizAttempt]),
            preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "light")
        )

        try store.importData(basicExport, bank: basicBank)

        questionProgress = try store.questionProgressRecords()
        XCTAssertFalse(questionProgress.contains(originalBasicRecord), "Basic import must replace Basic question progress")
        XCTAssertTrue(questionProgress.contains(replacementBasicRecord), "Basic import must add replacement Basic question progress")
        XCTAssertTrue(questionProgress.contains(advancedRecord), "Basic import must keep Advanced question progress")
        examAttempts = try store.examAttempts()
        XCTAssertFalse(examAttempts.contains(originalBasicExam), "Basic import must replace Basic mock exam attempts")
        XCTAssertTrue(examAttempts.contains(replacementBasicExam), "Basic import must add replacement Basic mock exam attempts")
        XCTAssertTrue(examAttempts.contains(advancedExam), "Basic import must keep Advanced mock exam attempts")
        XCTAssertEqual(try store.lessonProgressRecords(), [replacementLessonProgress], "Basic import must replace Basic lesson progress")
        XCTAssertEqual(try store.lessonQuizAttempts(), [replacementLessonQuizAttempt], "Basic import must replace Basic lesson quiz attempts")
    }

    func testImportValidationRejectsInvalidMorseCourseProgress() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let data = ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: "2026-01-02T05:04:05.000Z",
            bankId: bank.manifest.bankId,
            questionProgress: [],
            examAttempts: [],
            lessonProgress: [],
            lessonQuizAttempts: [],
            morseCourseProgress: MorseCourseProgressExport(
                courseId: "ised-koch-g4fon-v1",
                lessonProgress: [
                    MorseLessonProgressRecord(lessonId: "bad", attempts: 0, bestAccuracy: 2, lastAccuracy: -1, lastAttemptedAt: "2026-01-02T05:04:05Z", completedAt: nil),
                    MorseLessonProgressRecord(lessonId: "koch-bad", attempts: 1, bestAccuracy: 1, lastAccuracy: 1, lastAttemptedAt: "2026-01-02T05:04:05.000Z", completedAt: nil),
                ],
                characterStats: [MorseCharacterStatRecord(character: "KM", attempts: -1, correctAttempts: 2, recentResults: Array(repeating: true, count: 21), lastPracticedAt: "not-a-date")],
                dailyActivity: [MorseDailyActivityRecord(date: "2026-1-2", lessonsCompleted: -1)]
            ),
            preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
        )

        let errors = try ProgressStoreService.inMemoryForTests().validate(data, bank: bank)

        XCTAssertTrue(errors.contains { $0.contains("lessonProgress[0].lessonId") })
        XCTAssertTrue(errors.contains { $0.contains("lessonProgress[1].lessonId") })
        XCTAssertTrue(errors.contains { $0.contains("bestAccuracy") })
        XCTAssertTrue(errors.contains { $0.contains("lastAccuracy") })
        XCTAssertTrue(errors.contains { $0.contains("lastAttemptedAt") && $0.contains("canonical UTC") })
        XCTAssertTrue(errors.contains { $0.contains("characterStats[0].character") && $0.contains("single Morse character") })
        XCTAssertTrue(errors.contains { $0.contains("dailyActivity[0].date") })
        XCTAssertThrowsError(try ProgressStoreService.inMemoryForTests().importData(data, bank: bank))
    }

    func testDecodesLegacyBasicExportWithoutBankIdFields() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let json = """
        {
          "schema": "canadian-ham.progress-export",
          "version": 1,
          "exportedAt": "2026-01-02T05:04:05.000Z",
          "questionProgress": [
            { "questionId": "B-001-001-001", "attempts": 1, "correctAttempts": 1, "lastAttemptedAt": "2026-01-02T04:00:00.000Z", "lastResult": "correct", "recentResults": [true], "leitner": { "box": 1, "dueAt": "2026-01-03T04:00:00.000Z" }, "notes": null }
          ],
          "examAttempts": [
            { "id": "legacy-attempt", "mode": "mock-exam", "seed": "legacy", "startedAt": "2026-01-02T03:00:00.000Z", "submittedAt": "2026-01-02T04:00:00.000Z", "timer": { "enabled": false, "secondsAllowed": null, "secondsElapsed": 0 }, "items": [], "score": { "correct": 0, "total": 0, "percent": 0, "passed": false, "honours": false, "categoryBreakdown": [], "weakSubsectionIds": [] } }
          ],
          "preferences": { "practiceMode": "immediate", "examTimerEnabled": false }
        }
        """

        let decoded = try JSONDecoder().decode(ProgressExportV1.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.bankId, bank.manifest.bankId)
        XCTAssertEqual(decoded.questionProgress.first?.bankId, bank.manifest.bankId)
        XCTAssertEqual(decoded.examAttempts.first?.bankId, bank.manifest.bankId)
        XCTAssertEqual(decoded.examAttempts.first?.score.bankId, bank.manifest.bankId)
        XCTAssertTrue(try ProgressStoreService.inMemoryForTests().validate(decoded, bank: bank).isEmpty)
    }

    func testImportValidationRejectsMismatchedScoreBankId() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let data = ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: "2026-01-02T05:04:05.000Z",
            bankId: bank.manifest.bankId,
            questionProgress: [],
            examAttempts: [StoredExamAttempt(
                id: "mismatched-score-bank",
                bankId: bank.manifest.bankId,
                mode: "mock-exam",
                seed: "seed",
                startedAt: "2026-01-02T03:00:00.000Z",
                submittedAt: "2026-01-02T04:00:00.000Z",
                timer: StoredExamTimer(enabled: false, secondsAllowed: nil, secondsElapsed: 0),
                items: [],
                score: StoredExamScore(
                    bankId: syntheticAdvancedBankId,
                    correct: 0,
                    total: 0,
                    percent: 0,
                    passed: false,
                    honours: false,
                    categoryBreakdown: [],
                    weakSubsectionIds: []
                )
            )],
            lessonProgress: [],
            lessonQuizAttempts: [],
            preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
        )

        let errors = try ProgressStoreService.inMemoryForTests().validate(data, bank: bank)

        XCTAssertTrue(errors.contains { $0.contains("examAttempts[0].score.bankId must be \(bank.manifest.bankId)") })
        XCTAssertThrowsError(try ProgressStoreService.inMemoryForTests().importData(data, bank: bank))
    }

    func testDecodesWebLegacyExportWithOptionalLessonStoresAndTheme() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let json = """
        {
          "schema": "canadian-ham.progress-export",
          "version": 1,
          "exportedAt": "2026-01-02T05:04:05.000Z",
          "bankId": "\(bank.manifest.bankId)",
          "questionProgress": [],
          "examAttempts": [],
          "preferences": { "practiceMode": "immediate", "examTimerEnabled": false }
        }
        """

        let decoded = try JSONDecoder().decode(ProgressExportV1.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.lessonProgress, [])
        XCTAssertEqual(decoded.lessonQuizAttempts, [])
        XCTAssertEqual(decoded.preferences.language, "system")
        XCTAssertEqual(decoded.preferences.theme, "system")
        XCTAssertTrue(try ProgressStoreService.inMemoryForTests().validate(decoded, bank: bank).isEmpty)
    }

    func testImportsRealisticWebExportWithKnownLessonProgressAndQuizAttempt() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let json = """
        {
          "schema": "canadian-ham.progress-export",
          "version": 1,
          "exportedAt": "2026-01-02T05:04:05.000Z",
          "bankId": "\(bank.manifest.bankId)",
          "questionProgress": [],
          "examAttempts": [],
          "lessonProgress": [
            { "lessonId": "L-005-01", "readAt": "2026-01-02T03:30:00.000Z", "readCount": 2 }
          ],
          "lessonQuizAttempts": [
            { "id": "lesson-quiz-1", "quizId": "QZ-L-005-01-A", "lessonId": "L-005-01", "submittedAt": "2026-01-02T03:45:00.000Z", "correct": 9, "total": 11, "percent": 81.81818181818183, "officialQuestionIds": ["B-005-001-001"], "incorrectOfficialQuestionIds": [], "incorrectConceptCheckIds": ["QZ-L-005-01-A-C1"] }
          ],
          "preferences": { "practiceMode": "immediate", "examTimerEnabled": false, "theme": "system" }
        }
        """
        let decoded = try JSONDecoder().decode(ProgressExportV1.self, from: Data(json.utf8))
        let store = try ProgressStoreService.inMemoryForTests()

        XCTAssertTrue(store.validate(decoded, bank: bank).isEmpty)
        XCTAssertNoThrow(try store.importData(decoded, bank: bank))
        let exported = try store.exportData(bank: bank, exportedAt: "2026-01-02T06:04:05.000Z")
        XCTAssertEqual(exported.lessonProgress, decoded.lessonProgress)
        XCTAssertEqual(exported.lessonQuizAttempts, decoded.lessonQuizAttempts)
    }

    func testImportValidationChecksLessonRecordShapeKnownIdsAndDuplicates() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        XCTAssertFalse(bank.lessonQuizzes.isEmpty, "Unit-test bundle should include lesson quiz resources for import validation")
        let json = """
        {
          "schema": "canadian-ham.progress-export",
          "version": 1,
          "exportedAt": "2026-01-02T05:04:05.000Z",
          "bankId": "\(bank.manifest.bankId)",
          "questionProgress": [],
          "examAttempts": [],
          "lessonProgress": [
            { "lessonId": "L-005-01", "readAt": "2026-01-02T03:30:00.000Z", "readCount": 1 },
            { "lessonId": "L-005-01", "readAt": "2026-01-02T03:30:00Z", "readCount": 0 },
            { "lessonId": "L-999-99", "readAt": "2026-01-02T03:30:00.000Z", "readCount": 1 }
          ],
          "lessonQuizAttempts": [
            { "id": "quiz-1", "quizId": "QZ-L-005-01-A", "lessonId": "L-005-01", "submittedAt": "2026-01-02T03:45:00.000Z", "correct": 1, "total": 2, "percent": 50, "officialQuestionIds": ["B-005-001-001"], "incorrectOfficialQuestionIds": [], "incorrectConceptCheckIds": [] },
            { "id": "quiz-1", "quizId": "", "lessonId": "", "submittedAt": "2026-01-02T03:45:00Z", "correct": 3, "total": 2, "percent": 10, "officialQuestionIds": [], "incorrectOfficialQuestionIds": [], "incorrectConceptCheckIds": [] },
            { "id": "quiz-unknown", "quizId": "QZ-NOPE", "lessonId": "L-005-02", "submittedAt": "2026-01-02T03:45:00.000Z", "correct": 1, "total": 2, "percent": 50, "officialQuestionIds": ["B-999-999-999"], "incorrectOfficialQuestionIds": ["B-005-001-001"], "incorrectConceptCheckIds": ["missing"] },
            { "id": "quiz-bad-subsets", "quizId": "QZ-L-005-01-A", "lessonId": "L-005-01", "submittedAt": "2026-01-02T03:46:00.000Z", "correct": 1, "total": 2, "percent": 50, "officialQuestionIds": ["B-001-001-001"], "incorrectOfficialQuestionIds": ["B-005-001-001"], "incorrectConceptCheckIds": [] }
          ],
          "preferences": { "practiceMode": "immediate", "examTimerEnabled": false, "theme": "system" }
        }
        """
        let decoded = try JSONDecoder().decode(ProgressExportV1.self, from: Data(json.utf8))

        let errors = try ProgressStoreService.inMemoryForTests().validate(decoded, bank: bank)

        XCTAssertTrue(errors.contains { $0.contains("lessonProgress[1].lessonId duplicates") })
        XCTAssertTrue(errors.contains { $0.contains("lessonProgress[1].readAt") && $0.contains("canonical UTC") })
        XCTAssertTrue(errors.contains { $0.contains("lessonProgress[1].readCount") })
        XCTAssertTrue(errors.contains { $0.contains("lessonProgress[2].lessonId must be a known") })
        XCTAssertTrue(errors.contains { $0.contains("lessonQuizAttempts[1].id duplicates") })
        XCTAssertTrue(errors.contains { $0.contains("lessonQuizAttempts[1].quizId") })
        XCTAssertTrue(errors.contains { $0.contains("lessonQuizAttempts[1].correct must not exceed total") })
        XCTAssertTrue(errors.contains { $0.contains("lessonQuizAttempts[1].percent must match") })
        XCTAssertTrue(errors.contains { $0.contains("lessonQuizAttempts[2].quizId must be a known") })
        XCTAssertTrue(errors.contains { $0.contains("lessonQuizAttempts[2].officialQuestionIds must contain known") })
        XCTAssertTrue(errors.contains { $0.contains("lessonQuizAttempts[3].officialQuestionIds must belong") })
        XCTAssertTrue(errors.contains { $0.contains("lessonQuizAttempts[3].incorrectOfficialQuestionIds must be a subset") })
        XCTAssertThrowsError(try ProgressStoreService.inMemoryForTests().importData(decoded, bank: bank))
    }

    func testImportTimerDecodingRejectsHugeNumbersAndRoundsFractionalWebValues() throws {
        let decoder = JSONDecoder()
        let fractional = try decoder.decode(StoredExamTimer.self, from: Data(#"{"enabled":true,"secondsAllowed":12.2,"secondsElapsed":12.6}"#.utf8))
        XCTAssertEqual(fractional.secondsAllowed, 12)
        XCTAssertEqual(fractional.secondsElapsed, 13)

        XCTAssertThrowsError(try decoder.decode(StoredExamTimer.self, from: Data(#"{"enabled":true,"secondsAllowed":null,"secondsElapsed":1e300}"#.utf8)))
    }

    func testResetRollsBackWhenMorseProgressRemovalFails() throws {
        let store = try ProgressStoreService.inMemoryForTests()
        let originalMorseProgress = sampleMorseCourseProgress()
        try store.saveMorseCourseProgress(originalMorseProgress)
        var preferences = store.preferences
        preferences.theme = .dark
        try store.updatePreferences(preferences)

        store.failNextMorseCourseProgressRemovalForTesting = true
        XCTAssertThrowsError(try store.resetAllData()) { error in
            XCTAssertEqual(error as? ProgressStoreInjectedFailure, .morseCourseProgressRemoval)
        }

        XCTAssertEqual(try store.morseCourseProgress(), originalMorseProgress)
        XCTAssertEqual(store.preferences.theme, .dark)
    }

    func testImportOfOlderExportDoesNotRemoveExistingMorseProgress() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let store = try ProgressStoreService.inMemoryForTests()
        let originalMorseProgress = sampleMorseCourseProgress()
        try store.saveMorseCourseProgress(originalMorseProgress)
        let replacement = ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: "2026-01-02T05:04:05.000Z",
            bankId: bank.manifest.bankId,
            questionProgress: [],
            examAttempts: [],
            lessonProgress: [],
            lessonQuizAttempts: [],
            preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
        )

        store.failNextMorseCourseProgressRemovalForTesting = true
        XCTAssertNoThrow(try store.importData(replacement, bank: bank))

        XCTAssertEqual(try store.morseCourseProgress(), originalMorseProgress)
    }

    func testImportRollbackPropagatesMorseProgressRemovalFailure() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let store = try ProgressStoreService.inMemoryForTests()
        let importedMorseProgress = sampleMorseCourseProgress(lessonId: "koch-002")
        let replacement = ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: "2026-01-02T05:04:05.000Z",
            bankId: bank.manifest.bankId,
            questionProgress: [],
            examAttempts: [],
            lessonProgress: [],
            lessonQuizAttempts: [],
            morseCourseProgress: importedMorseProgress,
            preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
        )

        store.failNextImportAfterMorseWriteForTesting = true
        store.failNextMorseCourseProgressRemovalForTesting = true
        XCTAssertThrowsError(try store.importData(replacement, bank: bank)) { error in
            XCTAssertEqual(error as? ProgressStoreInjectedFailure, .morseCourseProgressRemoval)
        }
        XCTAssertEqual(try store.morseCourseProgress(), importedMorseProgress)
    }

    func testImportRollbackAfterMorseWriteRestoresPopulatedStoreAcrossCourses() throws {
        let basicBank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let advancedBank = try QuestionBankStore.load(bankId: .advanced, from: Bundle(for: Self.self))
        let store = try ProgressStoreService.inMemoryForTests()

        let originalBasicRecord = try applyAnswer(existing: nil, update: AnswerUpdate(
            questionId: "B-001-001-001",
            bankId: basicBank.manifest.bankId,
            isCorrect: true,
            now: "2026-01-02T03:04:05.000Z"
        ))
        let originalAdvancedRecord = try applyAnswer(existing: nil, update: AnswerUpdate(
            questionId: try XCTUnwrap(advancedBank.questions.first?.id),
            bankId: advancedBank.manifest.bankId,
            isCorrect: false,
            now: "2026-01-03T03:04:05.000Z"
        ))
        try store.saveQuestionProgress([originalBasicRecord, originalAdvancedRecord])
        let originalBasicExam = try mockAttempt(bank: basicBank, seed: "rollback-basic-original", submittedAt: "2026-01-02T04:04:05.000Z")
        let originalAdvancedExam = try mockAttempt(bank: advancedBank, seed: "rollback-advanced-original", submittedAt: "2026-01-03T04:04:05.000Z")
        try store.saveExamAttempt(originalBasicExam)
        try store.saveExamAttempt(originalAdvancedExam)
        let originalLessonProgress = LessonProgressRecord(lessonId: "L-005-01", readAt: "2026-01-02T03:10:00.000Z", readCount: 2)
        try store.saveLessonProgress(originalLessonProgress)
        let originalLessonQuizAttempt = LessonQuizAttempt(
            id: "lesson-quiz-populated-rollback",
            quizId: "QZ-L-005-01-A",
            lessonId: "L-005-01",
            submittedAt: "2026-01-02T03:20:00.000Z",
            correct: 1,
            total: 1,
            percent: 100,
            officialQuestionIds: ["B-005-001-001"],
            incorrectOfficialQuestionIds: [],
            incorrectConceptCheckIds: []
        )
        try store.saveLessonQuizAttempt(originalLessonQuizAttempt, questionProgress: [originalBasicRecord])
        let originalMorseProgress = sampleMorseCourseProgress(lessonId: "koch-001")
        try store.saveMorseCourseProgress(originalMorseProgress)
        var preferences = store.preferences
        preferences.practiceMode = .reviewLater
        preferences.examTimerEnabled = true
        preferences.theme = .dark
        preferences.activeBankId = .advanced
        try store.updatePreferences(preferences)
        let originalSnapshot = try progressSnapshot(from: store)

        let replacementBasicRecord = try applyAnswer(existing: nil, update: AnswerUpdate(
            questionId: "B-001-001-002",
            bankId: basicBank.manifest.bankId,
            isCorrect: false,
            now: "2026-01-04T03:04:05.000Z"
        ))
        let replacementBasicExam = try mockAttempt(bank: basicBank, seed: "rollback-basic-replacement", submittedAt: "2026-01-04T04:04:05.000Z")
        let replacement = ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: "2026-01-04T05:04:05.000Z",
            bankId: basicBank.manifest.bankId,
            questionProgress: [replacementBasicRecord],
            examAttempts: [replacementBasicExam],
            lessonProgress: try archivedArray([LessonProgressRecord(lessonId: "L-005-01", readAt: "2026-01-04T03:10:00.000Z", readCount: 5)]),
            lessonQuizAttempts: try archivedArray([LessonQuizAttempt(
                id: "lesson-quiz-populated-rollback-replacement",
                quizId: "QZ-L-005-01-A",
                lessonId: "L-005-01",
                submittedAt: "2026-01-04T03:20:00.000Z",
                correct: 0,
                total: 1,
                percent: 0,
                officialQuestionIds: ["B-005-001-001"],
                incorrectOfficialQuestionIds: ["B-005-001-001"],
                incorrectConceptCheckIds: []
            )]),
            morseCourseProgress: sampleMorseCourseProgress(lessonId: "koch-002"),
            preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "light")
        )

        store.failNextImportAfterMorseWriteForTesting = true
        XCTAssertThrowsError(try store.importData(replacement, bank: basicBank)) { error in
            XCTAssertEqual(error as? ProgressStoreInjectedFailure, .importAfterMorseWrite)
        }
        XCTAssertEqual(try progressSnapshot(from: store), originalSnapshot)
    }

    func testImportRollbackKeepsExistingDataWhenReplacementFails() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let store = try ProgressStoreService.inMemoryForTests()
        let originalRecord = try applyAnswer(existing: nil, update: AnswerUpdate(
            questionId: "B-001-001-001",
            bankId: bank.manifest.bankId,
            isCorrect: true,
            now: "2026-01-02T03:04:05.000Z"
        ))
        try store.saveQuestionProgress([originalRecord])
        let originalLessonProgress = LessonProgressRecord(
            lessonId: "L-005-01",
            readAt: "2026-01-02T03:10:00.000Z",
            readCount: 2
        )
        try store.saveLessonProgress(originalLessonProgress)
        let originalLessonQuizAttempt = LessonQuizAttempt(
            id: "lesson-quiz-import-rollback",
            quizId: "QZ-L-005-01-A",
            lessonId: "L-005-01",
            submittedAt: "2026-01-02T03:20:00.000Z",
            correct: 1,
            total: 1,
            percent: 100,
            officialQuestionIds: ["B-005-001-001"],
            incorrectOfficialQuestionIds: [],
            incorrectConceptCheckIds: []
        )
        try store.saveLessonQuizAttempt(originalLessonQuizAttempt, questionProgress: [originalRecord])
        let generated = try AppleStudyEngine.generatedMockExam(bank: bank, seed: "import-rollback-original")
        let originalExamAttempt = try AppleStudyEngine.buildExamAttempt(
            bank: bank,
            seed: "import-rollback-original",
            startedAt: "2026-01-02T03:30:00.000Z",
            submittedAt: "2026-01-02T04:30:00.000Z",
            timerEnabled: false,
            secondsElapsed: 0,
            generatedItems: generated.items,
            selectedByQuestionId: [:],
            flaggedQuestionIds: []
        )
        try store.saveExamAttempt(originalExamAttempt)
        var preferences = store.preferences
        preferences.theme = .dark
        try store.updatePreferences(preferences)

        let replacement = ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: "2026-01-02T05:04:05.000Z",
            bankId: bank.manifest.bankId,
            questionProgress: [],
            examAttempts: [],
            lessonProgress: [],
            lessonQuizAttempts: [],
            preferences: ExportedPreferences(practiceMode: "immediate", examTimerEnabled: false, theme: "system")
        )

        store.failNextImportAfterDeleteForTesting = true
        XCTAssertThrowsError(try store.importData(replacement, bank: bank))
        XCTAssertEqual(try store.questionProgressRecords(), [originalRecord])
        XCTAssertEqual(try store.lessonProgressRecords(), [originalLessonProgress])
        XCTAssertEqual(try store.lessonQuizAttempts(), [originalLessonQuizAttempt])
        XCTAssertEqual(try store.examAttempts(), [originalExamAttempt])
        XCTAssertEqual(store.preferences.theme, .dark)
    }

    func testLessonQuizAttemptSaveRollsBackAttemptAndProgressOnFailure() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let store = try ProgressStoreService.inMemoryForTests()
        let originalRecord = try applyAnswer(existing: nil, update: AnswerUpdate(
            questionId: "B-005-001-001",
            bankId: bank.manifest.bankId,
            isCorrect: true,
            now: "2026-01-02T03:04:05.000Z"
        ))
        try store.saveQuestionProgress([originalRecord])
        let updatedRecord = try applyAnswer(existing: originalRecord, update: AnswerUpdate(
            questionId: "B-005-001-001",
            bankId: bank.manifest.bankId,
            isCorrect: false,
            now: "2026-01-02T03:05:05.000Z"
        ))
        let attempt = LessonQuizAttempt(
            id: "lesson-quiz-rollback",
            quizId: "QZ-L-005-01-A",
            lessonId: "L-005-01",
            submittedAt: "2026-01-02T03:05:05.000Z",
            correct: 0,
            total: 1,
            percent: 0,
            officialQuestionIds: ["B-005-001-001"],
            incorrectOfficialQuestionIds: ["B-005-001-001"],
            incorrectConceptCheckIds: []
        )

        store.failNextLessonQuizSaveForTesting = true
        XCTAssertThrowsError(try store.saveLessonQuizAttempt(attempt, questionProgress: [updatedRecord]))
        XCTAssertEqual(try store.lessonQuizAttempts(), [])
        XCTAssertEqual(try store.questionProgressRecords(), [originalRecord])
    }

    func testImportValidationRejectsUnknownIdsBadTimestampsBadBoxAndDuplicateSubmittedAt() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let store = try ProgressStoreService.inMemoryForTests()
        let generated = try AppleStudyEngine.generatedMockExam(bank: bank, seed: "validation")
        let attempt = try AppleStudyEngine.buildExamAttempt(
            bank: bank,
            seed: "validation",
            startedAt: "2026-01-02T03:04:05.000Z",
            submittedAt: "2026-01-02T04:04:05.000Z",
            timerEnabled: false,
            secondsElapsed: 0,
            generatedItems: generated.items,
            selectedByQuestionId: [:],
            flaggedQuestionIds: []
        )
        let invalidRecord = QuestionProgressRecord(
            questionId: "B-999-999-999",
            bankId: bank.manifest.bankId,
            attempts: 1,
            correctAttempts: 0,
            lastAttemptedAt: "2026-01-02T03:04:05Z",
            lastResult: .incorrect,
            recentResults: [false, false, false, false, false, false],
            leitner: LeitnerState(box: 6, dueAt: "2026-01-02T03:04:05Z"),
            notes: nil
        )
        let data = ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: "not-a-timestamp",
            bankId: bank.manifest.bankId,
            questionProgress: [invalidRecord],
            examAttempts: [attempt, attempt],
            lessonProgress: [],
            lessonQuizAttempts: [],
            preferences: ExportedPreferences(practiceMode: "bogus", examTimerEnabled: false, theme: "bogus")
        )

        let errors = store.validate(data, bank: bank)
        XCTAssertTrue(errors.contains { $0.contains("questionId must be a known") })
        XCTAssertTrue(errors.contains { $0.contains("canonical UTC") })
        XCTAssertTrue(errors.contains { $0.contains("leitner.box") })
        XCTAssertTrue(errors.contains { $0.contains("duplicates another exam attempt") })
        XCTAssertTrue(errors.contains { $0.contains("preferences.practiceMode") })
        XCTAssertThrowsError(try store.importData(data, bank: bank))
    }

    func testMigratesArchivedLessonQuizAttemptsEvenWhenLearningProgressEntitiesExist() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let schema = Schema(versionedSchema: CanadianHamProgressSchemaV4.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, migrationPlan: CanadianHamProgressMigrationPlan.self, configurations: [configuration])
        let context = ModelContext(container)
        let existingLesson = LessonProgressRecord(lessonId: "L-005-01", readAt: "2026-01-01T03:10:00.000Z", readCount: 1)
        let archivedLesson = LessonProgressRecord(lessonId: "L-005-02", readAt: "2026-01-02T03:10:00.000Z", readCount: 2)
        let existingAttempt = LessonQuizAttempt(
            id: "existing-quiz-attempt",
            quizId: "QZ-L-005-01-A",
            lessonId: "L-005-01",
            submittedAt: "2026-01-01T03:20:00.000Z",
            correct: 1,
            total: 1,
            percent: 100,
            officialQuestionIds: ["B-005-001-001"],
            incorrectOfficialQuestionIds: [],
            incorrectConceptCheckIds: []
        )
        let archivedAttempt = LessonQuizAttempt(
            id: "archived-quiz-attempt",
            quizId: "QZ-L-005-01-A",
            lessonId: "L-005-01",
            submittedAt: "2026-01-02T03:20:00.000Z",
            correct: 1,
            total: 1,
            percent: 100,
            officialQuestionIds: ["B-005-001-001"],
            incorrectOfficialQuestionIds: [],
            incorrectConceptCheckIds: []
        )
        context.insert(LessonProgressEntity(lessonId: existingLesson.lessonId, readAt: existingLesson.readAt, readCount: existingLesson.readCount, deviceId: "device"))
        context.insert(LessonQuizAttemptEntity(id: existingAttempt.id, quizId: existingAttempt.quizId, lessonId: existingAttempt.lessonId, submittedAt: existingAttempt.submittedAt, payloadData: try JSONEncoder().encode(existingAttempt), deviceId: "device"))
        context.insert(PreferencesEntity(
            practiceMode: ApplePreferences.PracticeMode.immediate.rawValue,
            examTimerEnabled: false,
            language: BankLanguage.english.rawValue,
            theme: ApplePreferences.Theme.system.rawValue,
            archivedLessonProgressData: try JSONEncoder().encode(try archivedArray([archivedLesson])),
            archivedLessonQuizAttemptsData: try JSONEncoder().encode(try archivedArray([archivedAttempt]))
        ))
        try context.save()

        let (testDefaults, testDefaultsName) = try temporaryDefaultsSuite(prefix: "directInit")
        let store = try ProgressStoreService(container: container, morseCourseProgressURL: try temporaryMorseCourseProgressURL(), localDeviceID: "device", defaults: testDefaults, defaultsDomainName: testDefaultsName)

        XCTAssertEqual(try store.lessonProgressRecords(), [existingLesson, archivedLesson])
        XCTAssertEqual(try store.lessonQuizAttempts(), [existingAttempt, archivedAttempt])
        let exported = try store.exportData(bank: bank, exportedAt: "2026-01-02T05:04:05.000Z")
        XCTAssertEqual(exported.lessonQuizAttempts, try archivedArray([existingAttempt, archivedAttempt]))
    }

    func testMigratesArchivedLessonProgressKeepsMaxOwnReadCount() throws {
        let schema = Schema(versionedSchema: CanadianHamProgressSchemaV4.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, migrationPlan: CanadianHamProgressMigrationPlan.self, configurations: [configuration])
        let context = ModelContext(container)
        let existingLesson = LessonProgressRecord(lessonId: "L-005-01", readAt: "2026-01-03T03:10:00.000Z", readCount: 5)
        let archivedLesson = LessonProgressRecord(lessonId: existingLesson.lessonId, readAt: "2026-01-02T03:10:00.000Z", readCount: 2)
        context.insert(LessonProgressEntity(lessonId: existingLesson.lessonId, readAt: existingLesson.readAt, readCount: existingLesson.readCount, deviceId: "device"))
        context.insert(PreferencesEntity(
            practiceMode: ApplePreferences.PracticeMode.immediate.rawValue,
            examTimerEnabled: false,
            language: BankLanguage.english.rawValue,
            theme: ApplePreferences.Theme.system.rawValue,
            archivedLessonProgressData: try JSONEncoder().encode(try archivedArray([archivedLesson])),
            archivedLessonQuizAttemptsData: try JSONEncoder().encode([ArchivedJSON]())
        ))
        try context.save()

        let (testDefaults, testDefaultsName) = try temporaryDefaultsSuite(prefix: "directInit")
        let store = try ProgressStoreService(container: container, morseCourseProgressURL: try temporaryMorseCourseProgressURL(), localDeviceID: "device", defaults: testDefaults, defaultsDomainName: testDefaultsName)

        XCTAssertEqual(try store.lessonProgressRecords(), [existingLesson])
    }

    func testMigratesCommittedPreV2StoreFixtureWithAllDataIntact() throws {
        let fixtureURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "fixtures/progress/pre-v2/Progress.store")
        let directory = try temporaryProgressStoreDirectory()
        let urls = ProgressStoreURLs(progressDirectory: directory)
        try FileManager.default.copyItem(at: fixtureURL, to: urls.persistentStoreURL)

        let store = try openProgressStoreForTests(storeURLs: urls, iCloudSyncEnabled: false, layout: .legacySingleStore)

        let progress = try store.questionProgressRecords()
        XCTAssertEqual(progress.count, 1)
        XCTAssertEqual(progress.first?.questionId, "B-001-001-001")
        XCTAssertEqual(progress.first?.attempts, 2)
        XCTAssertEqual(progress.first?.correctAttempts, 1)
        XCTAssertEqual(progress.first?.recentResults, [false, true])
        XCTAssertEqual(progress.first?.leitner, LeitnerState(box: 1, dueAt: "2026-01-03T03:04:05.000Z"))
        XCTAssertEqual(progress.first?.notes, "pre-v2 fixture")
        let attempts = try store.examAttempts()
        XCTAssertEqual(attempts.map(\.id), ["fixture-attempt-1"])
        XCTAssertEqual(attempts.first?.seed, "pre-v2-fixture")
        XCTAssertEqual(attempts.first?.submittedAt, "2026-01-02T04:04:05.000Z")
        XCTAssertEqual(store.preferences.practiceMode, .reviewLater)
        XCTAssertTrue(store.preferences.examTimerEnabled)
        XCTAssertEqual(store.preferences.language, .french)
        XCTAssertEqual(store.preferences.theme, .dark)
        XCTAssertEqual(try store.lessonProgressRecords(), [LessonProgressRecord(lessonId: "L-005-01", readAt: "2026-01-02T03:30:00.000Z", readCount: 2)])
    }

    func testMigratesProgressStoreV1ToV2WithoutUniqueConstraints() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let storeURL = try temporaryProgressStoreURL()
        let record = try applyAnswer(existing: nil, update: AnswerUpdate(
            questionId: "B-001-001-001",
            bankId: bank.manifest.bankId,
            isCorrect: true,
            now: "2026-01-02T03:04:05.000Z"
        ))
        let attempt = try mockAttempt(bank: bank, seed: "v1-migration", submittedAt: "2026-01-02T04:04:05.000Z")
        let encoder = JSONEncoder()

        do {
            let schema = Schema(versionedSchema: CanadianHamProgressSchemaV1.self)
            let configuration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            context.insert(CanadianHamProgressSchemaV1.QuestionProgressEntity(
                questionId: record.questionId,
                bankId: record.bankId,
                attempts: record.attempts,
                correctAttempts: record.correctAttempts,
                lastAttemptedAt: record.lastAttemptedAt,
                lastResult: record.lastResult.rawValue,
                recentResultsData: try encoder.encode(record.recentResults),
                leitnerBox: record.leitner.box,
                dueAt: record.leitner.dueAt,
                notes: record.notes
            ))
            context.insert(CanadianHamProgressSchemaV1.ExamAttemptEntity(
                id: attempt.id,
                bankId: attempt.bankId,
                seed: attempt.seed,
                startedAt: attempt.startedAt,
                submittedAt: attempt.submittedAt,
                payloadData: try encoder.encode(attempt)
            ))
            context.insert(CanadianHamProgressSchemaV1.PreferencesEntity(
                practiceMode: ApplePreferences.PracticeMode.reviewLater.rawValue,
                examTimerEnabled: true,
                language: BankLanguage.french.rawValue,
                theme: ApplePreferences.Theme.dark.rawValue,
                archivedLessonProgressData: try encoder.encode([ArchivedJSON]()),
                archivedLessonQuizAttemptsData: try encoder.encode([ArchivedJSON]())
            ))
            try context.save()
        }

        let schema = Schema(versionedSchema: CanadianHamProgressSchemaV4.self)
        let configuration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, migrationPlan: CanadianHamProgressMigrationPlan.self, configurations: [configuration])
        let (testDefaults, testDefaultsName) = try temporaryDefaultsSuite(prefix: "directInit")
        let store = try ProgressStoreService(container: container, morseCourseProgressURL: try temporaryMorseCourseProgressURL(), defaults: testDefaults, defaultsDomainName: testDefaultsName)

        XCTAssertEqual(try store.questionProgressRecords(), [record])
        XCTAssertEqual(try store.examAttempts(), [attempt])
        XCTAssertEqual(store.preferences.practiceMode, .reviewLater)
        XCTAssertTrue(store.preferences.examTimerEnabled)
        XCTAssertEqual(store.preferences.language, .french)
        XCTAssertEqual(store.preferences.theme, .dark)

        let verificationContext = ModelContext(container)
        verificationContext.insert(QuestionProgressEntity(
            questionId: record.questionId,
            bankId: record.bankId,
            attempts: 1,
            correctAttempts: 0,
            lastAttemptedAt: "2026-01-02T05:04:05.000Z",
            lastResult: AnswerResult.incorrect.rawValue,
            recentResultsData: try encoder.encode([false]),
            leitnerBox: 0,
            dueAt: "2026-01-02T05:04:05.000Z"
        ))
        try verificationContext.save()
        XCTAssertEqual(try verificationContext.fetch(FetchDescriptor<QuestionProgressEntity>(predicate: #Predicate { $0.questionId == record.questionId })).count, 2)
    }

    func testMigratesProgressStoreV3ToV4PadsAndPersistsAnsweredWithHelpFields() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let storeURL = try temporaryProgressStoreURL()
        let encoder = JSONEncoder()
        let recentResults = [true, false]

        do {
            let schema = Schema(versionedSchema: CanadianHamProgressSchemaV3.self)
            let configuration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            context.insert(CanadianHamProgressSchemaV3.QuestionProgressEntity(
                questionId: "B-001-001-001",
                bankId: bank.manifest.bankId,
                attempts: 2,
                correctAttempts: 1,
                lastAttemptedAt: "2026-01-02T03:04:05.000Z",
                lastResult: AnswerResult.incorrect.rawValue,
                recentResultsData: try encoder.encode(recentResults),
                leitnerBox: 2,
                dueAt: "2026-01-05T03:04:05.000Z",
                notes: "v3",
                deviceId: "device"
            ))
            try context.save()
        }

        let hintedRecord: QuestionProgressRecord
        do {
            let schema = Schema(versionedSchema: CanadianHamProgressSchemaV4.self)
            let configuration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, migrationPlan: CanadianHamProgressMigrationPlan.self, configurations: [configuration])
            let (testDefaults, testDefaultsName) = try temporaryDefaultsSuite(prefix: "v3v4Migration")
            let store = try ProgressStoreService(container: container, morseCourseProgressURL: try temporaryMorseCourseProgressURL(), localDeviceID: "device", defaults: testDefaults, defaultsDomainName: testDefaultsName)
            let migrated = try XCTUnwrap(store.questionProgressRecords().first)
            XCTAssertFalse(migrated.lastAnsweredWithHelp)
            XCTAssertEqual(migrated.recentAnsweredWithHelp, [false, false])

            hintedRecord = try applyAnswer(existing: migrated, update: AnswerUpdate(
                questionId: migrated.questionId,
                bankId: migrated.bankId,
                isCorrect: true,
                now: "2026-01-02T04:04:05.000Z",
                answeredWithHelp: true
            ))
            try store.saveQuestionProgress([hintedRecord])
        }

        do {
            let schema = Schema(versionedSchema: CanadianHamProgressSchemaV4.self)
            let configuration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, migrationPlan: CanadianHamProgressMigrationPlan.self, configurations: [configuration])
            let (testDefaults, testDefaultsName) = try temporaryDefaultsSuite(prefix: "v3v4Reload")
            let store = try ProgressStoreService(container: container, morseCourseProgressURL: try temporaryMorseCourseProgressURL(), localDeviceID: "device", defaults: testDefaults, defaultsDomainName: testDefaultsName)
            let reloaded = try XCTUnwrap(store.questionProgressRecords().first)
            XCTAssertEqual(reloaded, hintedRecord)
            XCTAssertTrue(reloaded.lastAnsweredWithHelp)
            XCTAssertEqual(reloaded.recentAnsweredWithHelp.last, true)
        }
    }

    func testProgressStoreDeduplicatesV2EntitiesWithoutUniqueConstraints() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let schema = Schema(versionedSchema: CanadianHamProgressSchemaV4.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, migrationPlan: CanadianHamProgressMigrationPlan.self, configurations: [configuration])
        let context = ModelContext(container)
        let encoder = JSONEncoder()
        let originalRecord = try applyAnswer(existing: nil, update: AnswerUpdate(
            questionId: "B-001-001-001",
            bankId: bank.manifest.bankId,
            isCorrect: true,
            now: "2026-01-02T03:04:05.000Z"
        ))
        let replacementRecord = try applyAnswer(existing: originalRecord, update: AnswerUpdate(
            questionId: "B-001-001-001",
            bankId: bank.manifest.bankId,
            isCorrect: false,
            now: "2026-01-02T03:05:05.000Z"
        ))
        let originalAttempt = try mockAttempt(bank: bank, seed: "dedup-original", submittedAt: "2026-01-02T04:04:05.000Z")
        let replacementAttempt = StoredExamAttempt(
            id: originalAttempt.id,
            bankId: originalAttempt.bankId,
            mode: originalAttempt.mode,
            seed: "dedup-replacement",
            startedAt: originalAttempt.startedAt,
            submittedAt: originalAttempt.submittedAt,
            timer: StoredExamTimer(enabled: true, secondsAllowed: nil, secondsElapsed: 9),
            items: originalAttempt.items,
            score: originalAttempt.score
        )

        for _ in 0..<2 {
            context.insert(QuestionProgressEntity(
                questionId: originalRecord.questionId,
                bankId: originalRecord.bankId,
                attempts: originalRecord.attempts,
                correctAttempts: originalRecord.correctAttempts,
                lastAttemptedAt: originalRecord.lastAttemptedAt,
                lastResult: originalRecord.lastResult.rawValue,
                recentResultsData: try encoder.encode(originalRecord.recentResults),
                leitnerBox: originalRecord.leitner.box,
                dueAt: originalRecord.leitner.dueAt,
                notes: originalRecord.notes
            ))
            context.insert(ExamAttemptEntity(
                id: originalAttempt.id,
                bankId: originalAttempt.bankId,
                seed: originalAttempt.seed,
                startedAt: originalAttempt.startedAt,
                submittedAt: originalAttempt.submittedAt,
                payloadData: try encoder.encode(originalAttempt)
            ))
            context.insert(PreferencesEntity(
                practiceMode: ApplePreferences.PracticeMode.immediate.rawValue,
                examTimerEnabled: false,
                language: BankLanguage.english.rawValue,
                theme: ApplePreferences.Theme.system.rawValue
            ))
        }
        try context.save()
        let (testDefaults, testDefaultsName) = try temporaryDefaultsSuite(prefix: "directInit")
        let store = try ProgressStoreService(container: container, morseCourseProgressURL: try temporaryMorseCourseProgressURL(), defaults: testDefaults, defaultsDomainName: testDefaultsName)

        try store.saveQuestionProgress([replacementRecord])
        try store.saveExamAttempt(replacementAttempt)
        var preferences = store.preferences
        preferences.practiceMode = .reviewLater
        preferences.examTimerEnabled = true
        preferences.theme = .dark
        try store.updatePreferences(preferences)

        XCTAssertEqual(try store.questionProgressRecords(), [replacementRecord])
        let attempts = try store.examAttempts()
        XCTAssertEqual(attempts, [replacementAttempt])
        XCTAssertEqual(attempts.first?.timer.secondsElapsed, 9)
        XCTAssertEqual(store.preferences.practiceMode, .reviewLater)
        let verificationContext = ModelContext(container)
        XCTAssertEqual(try verificationContext.fetch(FetchDescriptor<QuestionProgressEntity>()).count, 1)
        XCTAssertEqual(try verificationContext.fetch(FetchDescriptor<ExamAttemptEntity>()).count, 1)
        let preferenceRows = try verificationContext.fetch(FetchDescriptor<PreferencesEntity>())
        XCTAssertEqual(preferenceRows.count, 2)
        XCTAssertEqual(preferenceRows.filter { $0.key == PreferencesEntity.defaultKey }.count, 1)
        XCTAssertEqual(preferenceRows.filter { $0.key == ProgressStoreService.task4610LessonSplitMigrationMarkerKey }.count, 1)
    }

    func testExportDeduplicatesSyncedDuplicatesAndBankScopedSubmittedAt() throws {
        let basicBank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let advancedBank = try QuestionBankStore.load(bankId: .advanced, from: Bundle(for: Self.self))
        let store = try ProgressStoreService.inMemoryForTests()
        let context = ModelContext(store.container)
        let encoder = JSONEncoder()
        let firstRecord = try applyAnswer(existing: nil, update: AnswerUpdate(
            questionId: "B-001-001-001",
            bankId: basicBank.manifest.bankId,
            isCorrect: true,
            now: "2026-01-02T03:04:05.000Z"
        ))
        let secondRecord = try applyAnswer(existing: firstRecord, update: AnswerUpdate(
            questionId: firstRecord.questionId,
            bankId: firstRecord.bankId,
            isCorrect: false,
            now: "2026-01-02T03:05:05.000Z"
        ))
        for record in [firstRecord, secondRecord] {
            context.insert(QuestionProgressEntity(
                questionId: record.questionId,
                bankId: record.bankId,
                attempts: record.attempts,
                correctAttempts: record.correctAttempts,
                lastAttemptedAt: record.lastAttemptedAt,
                lastResult: record.lastResult.rawValue,
                recentResultsData: try encoder.encode(record.recentResults),
                leitnerBox: record.leitner.box,
                dueAt: record.leitner.dueAt,
                notes: record.notes
            ))
        }
        let basicAttemptA = try mockAttempt(bank: basicBank, seed: "same-submitted-a", submittedAt: "2026-01-02T04:04:05.000Z")
        let basicAttemptB = try mockAttempt(bank: basicBank, seed: "same-submitted-b", submittedAt: "2026-01-02T04:04:05.000Z")
        let basicAttemptBDifferentId = StoredExamAttempt(
            id: "different-id-same-submitted",
            bankId: basicAttemptB.bankId,
            mode: basicAttemptB.mode,
            seed: basicAttemptB.seed,
            startedAt: basicAttemptB.startedAt,
            submittedAt: basicAttemptB.submittedAt,
            timer: basicAttemptB.timer,
            items: basicAttemptB.items,
            score: basicAttemptB.score
        )
        let advancedAttemptSameSubmittedAt = try mockAttempt(bank: advancedBank, seed: "advanced-same-submitted", submittedAt: "2026-01-02T04:04:05.000Z")
        for attempt in [basicAttemptA, basicAttemptBDifferentId, advancedAttemptSameSubmittedAt] {
            context.insert(ExamAttemptEntity(
                id: attempt.id,
                bankId: attempt.bankId,
                seed: attempt.seed,
                startedAt: attempt.startedAt,
                submittedAt: attempt.submittedAt,
                payloadData: try encoder.encode(attempt)
            ))
        }
        try context.save()

        let exported = try store.exportData(bank: basicBank, exportedAt: "2026-01-02T05:04:05.000Z")

        XCTAssertEqual(exported.questionProgress.count, 1)
        XCTAssertEqual(exported.questionProgress[0].attempts, 2)
        XCTAssertEqual(exported.examAttempts.count, 1)
        XCTAssertEqual(Set(exported.examAttempts.map(\.submittedAt)).count, 1)
        XCTAssertTrue(store.validate(exported, bank: basicBank).isEmpty)
        XCTAssertEqual(try store.examAttempts().filter { $0.bankId == advancedBank.manifest.bankId }.map(\.submittedAt), ["2026-01-02T04:04:05.000Z"])
    }

    private struct StoreSnapshot: Equatable {
        let questionProgress: [QuestionProgressRecord]
        let examAttempts: [StoredExamAttempt]
        let lessonProgress: [LessonProgressRecord]
        let lessonQuizAttempts: [LessonQuizAttempt]
        let morseCourseProgress: MorseCourseProgressExport?
        let preferences: ApplePreferences
    }

    private func progressSnapshot(from store: ProgressStoreService) throws -> StoreSnapshot {
        StoreSnapshot(
            questionProgress: try store.questionProgressRecords(),
            examAttempts: try store.examAttempts(),
            lessonProgress: try store.lessonProgressRecords(),
            lessonQuizAttempts: try store.lessonQuizAttempts(),
            morseCourseProgress: try store.morseCourseProgress(),
            preferences: store.preferences
        )
    }

    private func temporaryDefaultsSuite(prefix: String) throws -> (UserDefaults, String) {
        let suiteName = "ProgressStoreTests.\(prefix).\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }

    private func openProgressStoreForTests(
        storeURLs: ProgressStoreURLs,
        iCloudSyncEnabled: Bool = ICloudSyncSettings.storedOptIn(),
        layout: ProgressStoreConfigurationLayout = .automatic,
        defaults: UserDefaults? = nil,
        defaultsDomainName: String? = nil
    ) throws -> ProgressStoreService {
        let resolvedDefaults: UserDefaults
        let resolvedDomainName: String
        if let defaults, let defaultsDomainName {
            resolvedDefaults = defaults
            resolvedDomainName = defaultsDomainName
        } else {
            (resolvedDefaults, resolvedDomainName) = try temporaryDefaultsSuite(prefix: "open")
        }
        return try ProgressStoreService.open(
            storeURLs: storeURLs,
            iCloudSyncEnabled: iCloudSyncEnabled,
            layout: layout,
            defaults: resolvedDefaults,
            defaultsDomainName: resolvedDomainName
        )
    }

    private func storedAppleLanguages(defaults: UserDefaults, domainName: String) -> [String]? {
        defaults.persistentDomain(forName: domainName)?["AppleLanguages"] as? [String]
    }

    private func storedAppleLanguageLastApplied(defaults: UserDefaults, domainName: String) -> String? {
        defaults.persistentDomain(forName: domainName)?["CanadianHam.preferences.appleLanguagesLastApplied"] as? String
    }

    private func standardLanguageDefaultsSnapshot() -> [String: String] {
        let domainName = Bundle.main.bundleIdentifier ?? ""
        let domain = UserDefaults.standard.persistentDomain(forName: domainName) ?? [:]
        return [
            "AppleLanguages": String(describing: domain["AppleLanguages"]),
            "CanadianHam.preferences.appleLanguagesLastApplied": String(describing: domain["CanadianHam.preferences.appleLanguagesLastApplied"]),
            "CanadianHam.preferences.legacyEnglishLanguageDefaultMigrationComplete": String(describing: domain["CanadianHam.preferences.legacyEnglishLanguageDefaultMigrationComplete"])
        ]
    }

    private func emptyProgressExport(bank: QuestionBank, language: ApplePreferences.LanguagePreference) -> ProgressExportV1 {
        ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: "2026-01-02T03:04:05.000Z",
            bankId: bank.manifest.bankId,
            questionProgress: [],
            examAttempts: [],
            lessonProgress: [],
            lessonQuizAttempts: [],
            morseCourseProgress: nil,
            syncDeviceRows: nil,
            preferences: ExportedPreferences(
                practiceMode: ApplePreferences.PracticeMode.immediate.rawValue,
                examTimerEnabled: false,
                language: language.rawValue,
                theme: ApplePreferences.Theme.system.rawValue
            )
        )
    }

    private func preferencesContainer(language: String) throws -> ModelContainer {
        let schema = Schema(versionedSchema: CanadianHamProgressSchemaV4.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, migrationPlan: CanadianHamProgressMigrationPlan.self, configurations: [configuration])
        let context = ModelContext(container)
        context.insert(PreferencesEntity(
            practiceMode: ApplePreferences.PracticeMode.immediate.rawValue,
            examTimerEnabled: false,
            language: language,
            theme: ApplePreferences.Theme.system.rawValue
        ))
        try context.save()
        return container
    }

    private func temporaryProgressStoreURL() throws -> URL {
        try temporaryProgressStoreDirectory().appending(path: "Progress.store")
    }

    private func temporaryProgressStoreDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "CanadianHamProgressStoreMigrationTests", directoryHint: .isDirectory)
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func temporaryMorseCourseProgressURL() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "CanadianHamProgressStoreMigrationTests", directoryHint: .isDirectory)
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "MorseCourseProgress.json")
    }

    private func mockAttempt(bank: QuestionBank, seed: String, submittedAt: String) throws -> StoredExamAttempt {
        let generated = try AppleStudyEngine.generatedMockExam(bank: bank, seed: seed)
        return try AppleStudyEngine.buildExamAttempt(
            bank: bank,
            seed: seed,
            startedAt: "2026-01-02T03:04:05.000Z",
            submittedAt: submittedAt,
            timerEnabled: false,
            secondsElapsed: 0,
            generatedItems: generated.items,
            selectedByQuestionId: [:],
            flaggedQuestionIds: []
        )
    }

    private func archivedArray<T: Encodable>(_ value: [T]) throws -> [ArchivedJSON] {
        try JSONDecoder().decode([ArchivedJSON].self, from: JSONEncoder().encode(value))
    }

    private func decodeArchivedArray<T: Decodable>(_ value: [ArchivedJSON], as type: T.Type) throws -> [T] {
        try JSONDecoder().decode([T].self, from: JSONEncoder().encode(value))
    }

    private func sampleMorseCourseProgress(lessonId: String = "koch-001") -> MorseCourseProgressExport {
        MorseCourseProgressExport(
            courseId: "ised-koch-g4fon-v1",
            lessonProgress: [MorseLessonProgressRecord(
                lessonId: lessonId,
                attempts: 1,
                bestAccuracy: 1,
                lastAccuracy: 1,
                lastAttemptedAt: "2026-01-02T04:30:00.000Z",
                completedAt: "2026-01-02T04:30:00.000Z"
            )],
            characterStats: [MorseCharacterStatRecord(
                character: "K",
                attempts: 1,
                correctAttempts: 1,
                recentResults: [true],
                lastPracticedAt: "2026-01-02T04:30:00.000Z"
            )],
            dailyActivity: [MorseDailyActivityRecord(date: "2026-01-02", lessonsCompleted: 1)]
        )
    }
}

final class ReadinessAndScoringTests: XCTestCase {
    func testExamScoringBoundaries() throws {
        for (correct, passed, honours) in [(69, false, false), (70, true, false), (79, true, false), (80, true, true)] {
            let score = try scoreExam(makeScoreItems(correct: correct, total: 100))
            XCTAssertEqual(score.correct, correct)
            XCTAssertEqual(score.passed, passed, "Boundary \(correct) pass")
            XCTAssertEqual(score.honours, honours, "Boundary \(correct) honours")
        }
    }

    func testAdvancedScoringAndReadinessSuppressHonours() throws {
        let advancedItems = (1...50).map { index in
            ScoreInputItem(
                questionId: "A-001-001-\(String(format: "%03d", index))",
                categoryId: "A-001",
                subsectionId: "A-001-001",
                selectedSourceIndex: index <= 40 ? 0 : 1
            )
        }
        let score = try scoreExam(advancedItems, bankId: syntheticAdvancedBankId)
        XCTAssertEqual(score.bankId, syntheticAdvancedBankId)
        XCTAssertTrue(score.passed)
        XCTAssertFalse(score.honours)

        let fullBreakdown = [CategoryBreakdownEntry(categoryId: "A-001", correct: 40, total: 50, percent: 80)]
        let readiness = try computeReadiness(ReadinessInput(bankId: syntheticAdvancedBankId, completedExams: [
            ReadinessExamAttempt(submittedAt: "2026-01-03T00:00:00.000Z", score: ReadinessScore(correct: 40, total: 50, percent: 80), categoryBreakdown: fullBreakdown),
            ReadinessExamAttempt(submittedAt: "2026-01-02T00:00:00.000Z", score: ReadinessScore(correct: 45, total: 50, percent: 90), categoryBreakdown: fullBreakdown),
        ], dueReviewCount: 0))
        XCTAssertEqual(readiness.state, .passReady)
    }

    func testReadinessStates() throws {
        let fullBreakdown = [CategoryBreakdownEntry(categoryId: "B-001", correct: 70, total: 100, percent: 70)]
        let weakBreakdown = [CategoryBreakdownEntry(categoryId: "B-001", correct: 69, total: 100, percent: 69)]
        let notEnough = try computeReadiness(ReadinessInput(completedExams: [], dueReviewCount: 0))
        XCTAssertEqual(notEnough.state, .notEnoughData)

        let needsReview = try computeReadiness(ReadinessInput(completedExams: [
            ReadinessExamAttempt(submittedAt: "2026-01-03T00:00:00.000Z", score: ReadinessScore(correct: 90, total: 100, percent: 90), categoryBreakdown: weakBreakdown),
            ReadinessExamAttempt(submittedAt: "2026-01-02T00:00:00.000Z", score: ReadinessScore(correct: 90, total: 100, percent: 90), categoryBreakdown: weakBreakdown),
        ], dueReviewCount: 0))
        XCTAssertEqual(needsReview.state, .needsReview)

        let passReady = try computeReadiness(ReadinessInput(completedExams: [
            ReadinessExamAttempt(submittedAt: "2026-01-03T00:00:00.000Z", score: ReadinessScore(correct: 70, total: 100, percent: 70), categoryBreakdown: fullBreakdown),
            ReadinessExamAttempt(submittedAt: "2026-01-02T00:00:00.000Z", score: ReadinessScore(correct: 79, total: 100, percent: 79), categoryBreakdown: fullBreakdown),
        ], dueReviewCount: 0))
        XCTAssertEqual(passReady.state, .passReady)

        let honoursReady = try computeReadiness(ReadinessInput(completedExams: [
            ReadinessExamAttempt(submittedAt: "2026-01-03T00:00:00.000Z", score: ReadinessScore(correct: 80, total: 100, percent: 80), categoryBreakdown: fullBreakdown),
            ReadinessExamAttempt(submittedAt: "2026-01-02T00:00:00.000Z", score: ReadinessScore(correct: 90, total: 100, percent: 90), categoryBreakdown: fullBreakdown),
        ], dueReviewCount: 0))
        XCTAssertEqual(honoursReady.state, .honoursReady)

        let dueBlocks = try computeReadiness(ReadinessInput(completedExams: [
            ReadinessExamAttempt(submittedAt: "2026-01-03T00:00:00.000Z", score: ReadinessScore(correct: 90, total: 100, percent: 90), categoryBreakdown: fullBreakdown),
            ReadinessExamAttempt(submittedAt: "2026-01-02T00:00:00.000Z", score: ReadinessScore(correct: 90, total: 100, percent: 90), categoryBreakdown: fullBreakdown),
        ], dueReviewCount: 5))
        XCTAssertEqual(dueBlocks.state, .needsReview)
    }

    @MainActor
    func testSavingSameAttemptTwiceDoesNotCreateDoubleSubmitDuplicate() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: ProgressStoreTests.self))
        let store = try ProgressStoreService.inMemoryForTests()
        let generated = try AppleStudyEngine.generatedMockExam(bank: bank, seed: "double-submit")
        let attempt = try AppleStudyEngine.buildExamAttempt(
            bank: bank,
            seed: "double-submit",
            startedAt: "2026-01-02T03:04:05.000Z",
            submittedAt: "2026-01-02T04:04:05.000Z",
            timerEnabled: false,
            secondsElapsed: 0,
            generatedItems: generated.items,
            selectedByQuestionId: [:],
            flaggedQuestionIds: []
        )
        let duplicateSubmitAttempt = try AppleStudyEngine.buildExamAttempt(
            bank: bank,
            seed: "double-submit-second-tap",
            startedAt: "2026-01-02T03:04:05.000Z",
            submittedAt: "2026-01-02T04:04:05.000Z",
            timerEnabled: false,
            secondsElapsed: 1,
            generatedItems: generated.items,
            selectedByQuestionId: [:],
            flaggedQuestionIds: []
        )

        try store.saveExamAttempt(attempt)
        try store.saveExamAttempt(attempt)
        try store.saveExamAttempt(duplicateSubmitAttempt)
        let attempts = try store.examAttempts()
        XCTAssertEqual(attempts.count, 1)
        XCTAssertEqual(attempts.first?.id, duplicateSubmitAttempt.id)
        XCTAssertEqual(attempts.first?.timer.secondsElapsed, 1)
    }

    private func makeScoreItems(correct: Int, total: Int) -> [ScoreInputItem] {
        (0..<total).map { index in
            ScoreInputItem(
                questionId: "B-001-001-001",
                categoryId: "B-001",
                subsectionId: "B-001-001",
                selectedSourceIndex: index < correct ? 0 : 1
            )
        }
    }
}
