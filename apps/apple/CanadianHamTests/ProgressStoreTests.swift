@testable import CanadianHam
import CanadianHamEngine
import CanadianHamMorseEngine
import Combine
import SwiftData
import SwiftUI
import XCTest

@MainActor
final class ProgressStoreTests: XCTestCase {
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

#if os(macOS)
    func testNativeSettingsGeneralBindingsUpdatePracticePreferences() throws {
        let store = try CanadianHam.ProgressStoreService.inMemoryForTests()
        var saveCount = 0
        var failedError: Error?
        let bindings = NativeSettingsPreferenceBindings(
            progressStore: store,
            didSave: { saveCount += 1 },
            didFail: { failedError = $0 }
        )

        bindings.practiceMode.wrappedValue = .reviewLater
        bindings.examTimerEnabled.wrappedValue = true

        XCTAssertEqual(store.preferences.practiceMode, .reviewLater)
        XCTAssertTrue(store.preferences.examTimerEnabled)
        XCTAssertEqual(saveCount, 2)
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

    func testProgressStoreRoundTripExportImportReset() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let store = try ProgressStoreService.inMemoryForTests()
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
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.morseCourseProgressURLForTesting.path(percentEncoded: false)))

        let exported = try store.exportData(bank: bank, exportedAt: "2026-01-02T05:04:05.000Z")
        XCTAssertEqual(exported.schema, "canadian-ham.progress-export")
        XCTAssertEqual(exported.version, 1)
        XCTAssertEqual(exported.questionProgress.count, 1)
        XCTAssertEqual(exported.examAttempts.count, 1)
        XCTAssertEqual(exported.preferences.practiceMode, "review-later")
        XCTAssertEqual(exported.morseCourseProgress, morseProgress)

        let importedStore = try ProgressStoreService.inMemoryForTests()
        XCTAssertNotEqual(importedStore.morseCourseProgressURLForTesting, store.morseCourseProgressURLForTesting)
        XCTAssertNil(try importedStore.morseCourseProgress())
        try importedStore.importData(exported, bank: bank)
        XCTAssertEqual(try importedStore.questionProgressRecords(), exported.questionProgress)
        XCTAssertEqual(try importedStore.examAttempts(), exported.examAttempts)
        XCTAssertEqual(importedStore.preferences.practiceMode, .reviewLater)
        XCTAssertTrue(importedStore.preferences.examTimerEnabled)
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
            toneHz: morseSettings.toneHz,
            characterWpm: morseSettings.characterWpm,
            effectiveWpm: morseSettings.effectiveWpm,
            timingProfile: morseSettings.timingProfile.rawValue,
            volume: morseSettings.volume,
            outputMode: morseSettings.outputMode.rawValue
        )

        let serialized = try store.serializedExport(bank: bank, exportedAt: "2026-01-02T05:04:05.000Z", morseSettings: exportedMorseSettings)
        let decoded = try JSONDecoder().decode(ProgressExportV1.self, from: Data(serialized.utf8))

        XCTAssertEqual(decoded.preferences.morse, exportedMorseSettings)
        XCTAssertEqual(decoded.preferences.morse.outputMode, "visualTape")
        XCTAssertTrue(serialized.contains("\"morse\""), "Apple exports should use the web preferences.morse shape.")
        XCTAssertNoThrow(try ProgressStoreService.inMemoryForTests().importData(decoded, bank: bank))
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
