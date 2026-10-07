import Foundation
import XCTest
@testable import CanadianHamMorseEngine

final class MorseFixtureTests: XCTestCase {
    func testEveryMorseFixtureMatchesSwiftEngine() throws {
        let paths = try morseFixturePaths()
        XCTAssertFalse(paths.isEmpty, "expected at least one fixture JSON file")
        for path in paths {
            let data = try Data(contentsOf: path)
            let header = try JSONDecoder().decode(FixtureHeader.self, from: data)
            XCTAssertEqual(header.schemaVersion, 1, path.path(percentEncoded: false).fixtureRelativePath())
            switch header.kind {
            case "morse-timing":
                try validateTimingFixture(data)
            case "morse-word-weighting":
                try validateWordWeightingFixture(data)
            case "morse-scoring":
                try validateScoringFixture(data)
            case "morse-copy-exam":
                try validateCopyExamFixture(data)
            case "morse-copy-diff":
                try validateCopyDiffFixture(data)
            case "morse-validation":
                try validateValidationFixture(data)
            case "morse-course":
                try validateCourseFixture(data)
            case "morse-course-exercises":
                try validateCourseExercisesFixture(data)
            case "morse-course-streak":
                try validateCourseStreakFixture(data)
            case "morse-sending":
                try validateSendingFixture(data)
            default:
                XCTFail("unsupported fixture kind: \(header.kind)")
            }
        }
    }

    private func validateTimingFixture(_ data: Data) throws {
        let fixture = try JSONDecoder().decode(TimingFixture.self, from: data)
        for testCase in fixture.cases {
            if let expectedError = testCase.expectedError {
                assertExpectedError(expectedError, testCase.id) {
                    let profile = try profile(from: testCase.input.profile)
                    _ = try textToTimedMorse(testCase.input.text, profile: profile)
                }
                continue
            }

            guard let expectedOutput = testCase.expectedOutput else {
                XCTFail("missing expectedOutput for \(testCase.id)")
                continue
            }
            let profile = try profile(from: testCase.input.profile)
            let sequence = try textToTimedMorse(testCase.input.text, profile: profile)
            XCTAssertEqual(sequence.normalizedText, expectedOutput.normalizedText, testCase.id)
            XCTAssertEqual(sequence.totalDurationSeconds, expectedOutput.totalDurationSeconds, accuracy: 1e-9, testCase.id)
            XCTAssertEqual(sequence.profile.effectiveWpm, expectedOutput.effectiveWpm, accuracy: 1e-12, testCase.id)
            XCTAssertEqual(sequence.profile.dotSeconds, expectedOutput.durationsSeconds.dot, accuracy: 1e-12, testCase.id)
            XCTAssertEqual(sequence.profile.dashSeconds, expectedOutput.durationsSeconds.dash, accuracy: 1e-12, testCase.id)
            XCTAssertEqual(sequence.profile.intraCharacterGapSeconds, expectedOutput.durationsSeconds.intraCharacterGap, accuracy: 1e-12, testCase.id)
            XCTAssertEqual(sequence.profile.interCharacterGapSeconds, expectedOutput.durationsSeconds.interCharacterGap, accuracy: 1e-12, testCase.id)
            XCTAssertEqual(sequence.profile.wordGapSeconds, expectedOutput.durationsSeconds.wordGap, accuracy: 1e-12, testCase.id)
            XCTAssertEqual(symbolCounts(sequence.symbols), expectedOutput.symbolCounts, testCase.id)
            XCTAssertEqual(sequence.symbols.last?.kind.rawValue, expectedOutput.lastSymbolKind, testCase.id)
            if let expectedSymbols = expectedOutput.symbols {
                assertSymbols(sequence.symbols, expectedSymbols, testCase.id)
            }
        }
    }

    private func validateWordWeightingFixture(_ data: Data) throws {
        let fixture = try JSONDecoder().decode(WordWeightingFixture.self, from: data)
        for testCase in fixture.cases {
            if let expectedError = testCase.expectedError {
                assertExpectedError(expectedError, testCase.id) {
                    _ = try weightedCharacterCount(testCase.input.text)
                }
                continue
            }

            guard let expectedOutput = testCase.expectedOutput else {
                XCTFail("missing expectedOutput for \(testCase.id)")
                continue
            }
            let output = try weightedCharacterCount(testCase.input.text)
            XCTAssertEqual(output.weightedCharacters, expectedOutput.weightedCharacters, testCase.id)
            XCTAssertEqual(output.unweightedCharacters, expectedOutput.unweightedCharacters, testCase.id)
        }
    }

    private func validateScoringFixture(_ data: Data) throws {
        let fixture = try JSONDecoder().decode(ScoringFixture.self, from: data)
        for testCase in fixture.cases {
            if let expectedError = testCase.expectedError {
                assertExpectedError(expectedError, testCase.id) {
                    _ = try scoreMorseCopy(expected: testCase.input.expected, received: testCase.input.received)
                }
                continue
            }

            guard let expectedOutput = testCase.expectedOutput else {
                XCTFail("missing expectedOutput for \(testCase.id)")
                continue
            }
            let output = try scoreMorseCopy(expected: testCase.input.expected, received: testCase.input.received)
            XCTAssertEqual(output, expectedOutput, testCase.id)
        }
    }

    private func validateCopyExamFixture(_ data: Data) throws {
        let fixture = try JSONDecoder().decode(CopyExamFixture.self, from: data)
        for testCase in fixture.cases {
            let selectedProfile = try profile(from: testCase.input.profile)
            let generated = try generateMorseExamText(
                seed: testCase.input.seed,
                profile: selectedProfile,
                minWeightedCharacters: testCase.input.minWeightedCharacters,
                minDurationSeconds: testCase.input.minDurationSeconds
            )
            XCTAssertTrue(validateMorseText(generated.text).valid, testCase.id)
            XCTAssertGreaterThanOrEqual(generated.weightedCharacters, testCase.expectedOutput.minWeightedCharacters, testCase.id)
            XCTAssertGreaterThanOrEqual(generated.durationSeconds, testCase.expectedOutput.minDurationSeconds, testCase.id)
            let sequence = try textToTimedMorse(generated.text, profile: selectedProfile)
            XCTAssertEqual(generated.normalizedText, sequence.normalizedText, testCase.id)
            XCTAssertEqual(generated.durationSeconds, sequence.totalDurationSeconds, accuracy: 1e-9, testCase.id)
            if let text = testCase.expectedOutput.text {
                XCTAssertEqual(generated.text, text, testCase.id)
            }
            if let normalizedText = testCase.expectedOutput.normalizedText {
                XCTAssertEqual(generated.normalizedText, normalizedText, testCase.id)
            }
            if let weightedCharacters = testCase.expectedOutput.weightedCharacters {
                XCTAssertEqual(generated.weightedCharacters, weightedCharacters, testCase.id)
            }
            if let unweightedCharacters = testCase.expectedOutput.unweightedCharacters {
                XCTAssertEqual(generated.unweightedCharacters, unweightedCharacters, testCase.id)
            }
            if let durationSeconds = testCase.expectedOutput.durationSeconds {
                XCTAssertEqual(generated.durationSeconds, durationSeconds, accuracy: 1e-9, testCase.id)
            }
        }
    }

    func testVisualTapeAndHapticOutputMapping() throws {
        let sequence = try textToTimedMorse("ET", profile: profileForName(.isedParis))
        let signalEvents = morseSignalEvents(sequence: sequence)
        XCTAssertEqual(signalEvents.map(\.kind), [.on, .off, .on, .off])
        XCTAssertEqual(signalEvents.map(\.character), ["E", "E", "T", "T"])
        XCTAssertEqual(signalEvents.map(\.symbolKind), [.dot, .dot, .dash, .dash])
        XCTAssertEqual(signalEvents[1].atSeconds, 0.1, accuracy: 1e-12)
        XCTAssertEqual(signalEvents[2].atSeconds, 1.505263157894737, accuracy: 1e-12)
        let tapeTokens = morseTapeTokens(sequence: sequence)
        XCTAssertEqual(tapeTokens.map(\.token), [".", "-"])
        XCTAssertEqual(tapeTokens[1].revealAtSeconds, 1.505263157894737, accuracy: 1e-12)
        let hapticEvents = morseHapticEvents(sequence: sequence)
        XCTAssertEqual(hapticEvents.map(\.symbolKind), [.dot, .dash])
        XCTAssertEqual(hapticEvents[1].startSeconds, 1.505263157894737, accuracy: 1e-12)
        XCTAssertEqual(hapticEvents[1].durationSeconds, 0.3, accuracy: 1e-12)
    }

    func testMorseBeaconFlashSafetyMath() throws {
        let sequence = try textToTimedMorse("5", profile: profileForName(.isedParis))
        let flashesPerSecond = maxMorseFlashesPerSecond(events: morseSignalEvents(sequence: sequence))
        XCTAssertEqual(flashesPerSecond, 5)
        XCTAssertLessThanOrEqual(morseBeaconAreaCssPixels, morseFlashMaxAreaCssPixels)
        let lightPalette = morseBeaconPalette(accent: morseLightAccentRGB, background: morseLightPaperInsetRGB)
        let darkPalette = morseBeaconPalette(accent: morseDarkAccentRGB, background: morseDarkPaperInsetRGB)
        let lightSafe = evaluateMorseBeaconFlashSafety(palette: lightPalette, flashesPerSecond: flashesPerSecond)
        let darkSafe = evaluateMorseBeaconFlashSafety(palette: darkPalette, flashesPerSecond: flashesPerSecond)
        XCTAssertTrue(lightSafe.safe)
        XCTAssertTrue(darkSafe.safe)
        XCTAssertEqual(lightSafe.reason, .belowAreaThreshold)
        XCTAssertEqual(darkSafe.reason, .belowAreaThreshold)
        XCTAssertGreaterThanOrEqual(morseContrastRatio(lightPalette.resting, lightPalette.active), 3)
        XCTAssertGreaterThanOrEqual(morseContrastRatio(darkPalette.resting, darkPalette.active), 3)
        XCTAssertTrue(evaluateMorseFlashSafety(MorseFlashSafetyInput(
            flashAreaCssPixels: morseFlashMaxAreaCssPixels + 1,
            flashesPerSecond: 2,
            darkerRelativeLuminance: 0.2,
            lighterRelativeLuminance: 0.8,
            usesSaturatedRed: false
        )).safe)
        XCTAssertEqual(evaluateMorseFlashSafety(MorseFlashSafetyInput(
            flashAreaCssPixels: morseFlashMaxAreaCssPixels + 1,
            flashesPerSecond: 5,
            darkerRelativeLuminance: 0.75,
            lighterRelativeLuminance: 0.82,
            usesSaturatedRed: false
        )).reason, .belowGeneralThreshold)
        XCTAssertEqual(evaluateMorseFlashSafety(MorseFlashSafetyInput(
            flashAreaCssPixels: morseFlashMaxAreaCssPixels + 1,
            flashesPerSecond: 5,
            darkerRelativeLuminance: 0.2,
            lighterRelativeLuminance: 0.8,
            usesSaturatedRed: false
        )).reason, .areaTooLarge)
        XCTAssertEqual(evaluateMorseFlashSafety(MorseFlashSafetyInput(
            flashAreaCssPixels: morseBeaconAreaCssPixels,
            flashesPerSecond: 5,
            darkerRelativeLuminance: 0.2,
            lighterRelativeLuminance: 0.8,
            usesSaturatedRed: true
        )).reason, .saturatedRed)
    }

    func testGenerateMorseExamTextReportsUnsatisfiedConstraintsDistinctly() throws {
        do {
            _ = try generateMorseExamText(minWeightedCharacters: Int.max)
            XCTFail("Unsatisfiable Morse exam-text constraints should throw")
        } catch MorseEngineError.examTextConstraintsUnsatisfied(let message) {
            XCTAssertTrue(message.contains("Unable to generate Morse exam text that satisfies RIC-1 section 8.2 constraints."), "message was: \(message)")
        } catch MorseEngineError.invalidSpeed(let message) {
            XCTFail("Unsatisfiable constraints must not be reported as invalid speed: \(message)")
        } catch {
            XCTFail("Unexpected error for unsatisfiable constraints: \(error)")
        }
    }

    private func validateCopyDiffFixture(_ data: Data) throws {
        let fixture = try JSONDecoder().decode(CopyDiffFixture.self, from: data)
        for testCase in fixture.cases {
            if let expectedError = testCase.expectedError {
                assertExpectedError(expectedError, testCase.id) {
                    _ = try diffMorseCopy(expected: testCase.input.expected, received: testCase.input.received)
                }
                continue
            }

            guard let expectedOutput = testCase.expectedOutput else {
                XCTFail("missing expectedOutput for \(testCase.id)")
                continue
            }
            let output = try diffMorseCopy(expected: testCase.input.expected, received: testCase.input.received)
            XCTAssertEqual(output, expectedOutput, testCase.id)
        }
    }

    private func validateValidationFixture(_ data: Data) throws {
        let fixture = try JSONDecoder().decode(ValidationFixture.self, from: data)
        for testCase in fixture.cases {
            let output = validateMorseText(testCase.input.text)
            XCTAssertEqual(output, testCase.expectedOutput, testCase.id)
        }
    }

    private func validateCourseExercisesFixture(_ data: Data) throws {
        let fixture = try JSONDecoder().decode(CourseExercisesFixture.self, from: data)
        let courseData = try Data(contentsOf: try repositoryRoot().appending(path: "fixtures/morse/course.json"))
        let course = try decodeMorseCourse(data: courseData)
        for testCase in fixture.cases {
            let lesson = try XCTUnwrap(course.lessons.first { $0.id == testCase.input.lessonId }, testCase.id)
            XCTAssertEqual(
                buildMorseLessonExercises(lesson: lesson, seed: testCase.input.seed),
                try testCase.expectedOutput.exercises.map { try $0.exercise() },
                testCase.id
            )
        }
    }

    private func validateCourseStreakFixture(_ data: Data) throws {
        let fixture = try JSONDecoder().decode(CourseStreakFixture.self, from: data)
        for testCase in fixture.cases {
            XCTAssertEqual(morseDailyStreak(activity: testCase.input.activity, todayIso: testCase.input.todayIso), testCase.expectedOutput.streak, testCase.id)
        }
    }

    private func validateSendingFixture(_ data: Data) throws {
        let fixture = try JSONDecoder().decode(SendingFixture.self, from: data)
        for testCase in fixture.cases {
            if let expected = testCase.input.expected, let sent = testCase.input.sent, let completedWithinTime = testCase.input.completedWithinTime {
                let score = try scoreMorseSending(expected: expected, sent: sent, completedWithinTime: completedWithinTime)
                XCTAssertEqual(score.diff.score.errors, try XCTUnwrap(testCase.expectedOutput.errors), testCase.id)
                XCTAssertEqual(score.passed, try XCTUnwrap(testCase.expectedOutput.passed), testCase.id)
                XCTAssertEqual(score.markPercent, try XCTUnwrap(testCase.expectedOutput.markPercent), testCase.id)
                continue
            }

            guard let profileInput = testCase.input.profile, let durationsSeconds = testCase.input.durationsSeconds else {
                XCTFail("missing sending timing input for \(testCase.id)")
                continue
            }
            let selectedProfile = try profile(from: profileInput)
            let samples = try durationsSeconds.map { try classifyMorseKeyDown(durationSeconds: $0, profile: selectedProfile) }
            let feedback = morseCharacterTimingFeedback(samples: samples)
            XCTAssertEqual(feedback.elements, try XCTUnwrap(testCase.expectedOutput.elements), testCase.id)
            XCTAssertEqual(feedback.decoded, try XCTUnwrap(testCase.expectedOutput.decoded), testCase.id)
            XCTAssertEqual(feedback.timingConsistencyPercent, try XCTUnwrap(testCase.expectedOutput.timingConsistencyPercent), testCase.id)
            XCTAssertEqual(feedback.averageRatioToExpected, try XCTUnwrap(testCase.expectedOutput.averageRatioToExpected), accuracy: 1e-12, testCase.id)
            if let expectedDotDashRatio = testCase.expectedOutput.dotDashRatio {
                XCTAssertEqual(try XCTUnwrap(feedback.dotDashRatio), expectedDotDashRatio, accuracy: 1e-12, testCase.id)
            } else {
                XCTAssertNil(feedback.dotDashRatio, testCase.id)
            }
            if let appliedText = testCase.expectedOutput.appliedText, let applyToText = testCase.input.applyToText {
                XCTAssertEqual(applyMorseDecodedCharacter(text: applyToText, decoded: feedback.decoded), appliedText, testCase.id)
            }
        }
    }

    private func validateCourseFixture(_ data: Data) throws {
        let course = try decodeMorseCourse(data: data)
        XCTAssertEqual(course.characterOrder, approvedMorseCourseCharacterOrder)
        XCTAssertEqual(course.units.count, 8)
        XCTAssertEqual(course.lessons.count, 40)
        XCTAssertEqual(course.lessons.first?.newCharacters, ["K", "M"])
        XCTAssertEqual(course.lessons.last?.newCharacters, ["-"])

        var progress = emptyMorseCourseProgress(courseId: course.courseId)
        XCTAssertEqual(try morseLessonState(course: course, progress: progress, lessonId: "koch-001"), .current)
        XCTAssertEqual(try morseLessonState(course: course, progress: progress, lessonId: "koch-002"), .locked)
        progress = try recordMorseLessonAttempt(
            course: course,
            progress: progress,
            lessonId: "koch-001",
            correct: 9,
            total: 10,
            characterResults: [],
            attemptedAt: "2026-10-03T12:00:00.000Z"
        )
        XCTAssertEqual(try morseLessonState(course: course, progress: progress, lessonId: "koch-001"), .completed)
        XCTAssertEqual(try morseLessonState(course: course, progress: progress, lessonId: "koch-002"), .current)
        XCTAssertEqual(morseDailyStreak(activity: progress.dailyActivity, todayIso: "2026-10-03T12:05:00.000Z"), 1)
        XCTAssertEqual(morseDailyStreak(activity: progress.dailyActivity, todayIso: "2026-10-04T00:05:00.000Z"), 1)
        XCTAssertEqual(morseDailyStreak(activity: progress.dailyActivity, todayIso: "2026-10-05T00:05:00.000Z"), 0)

        let firstLesson = try XCTUnwrap(course.lessons.first)
        let exercises = buildMorseLessonExercises(lesson: firstLesson, seed: "lesson-one")
        let scored = exercises.filter { exercise in
            if case .meet = exercise { return false }
            return true
        }
        XCTAssertEqual(Array(exercises.prefix(2)), [.meet("K"), .meet("M")])
        XCTAssertGreaterThanOrEqual(scored.count, 15)
        XCTAssertLessThanOrEqual(scored.count, 25)
        XCTAssertTrue(exercises.contains { exercise in
            if case .typeGroup(let text) = exercise {
                return text.count == 5 && text.allSatisfy { firstLesson.learnedCharacters.contains(String($0)) }
            }
            return false
        })
        XCTAssertEqual(buildMorseLessonExercises(lesson: firstLesson, seed: "lesson-one"), exercises)
        XCTAssertNotEqual(buildMorseLessonExercises(lesson: firstLesson, seed: "lesson-one-other"), exercises)
    }

    private func assertExpectedError(_ expectedError: ExpectedError, _ testCaseId: String, action: () throws -> Void) {
        do {
            try action()
            XCTFail("\(testCaseId) should have thrown \(expectedError.type)")
        } catch MorseEngineError.invalidCharacters(let characters) {
            XCTAssertEqual(expectedError.type, "invalidCharacters", testCaseId)
            if let expectedCharacters = expectedError.invalidCharacters {
                XCTAssertEqual(characters, expectedCharacters, testCaseId)
            }
        } catch MorseEngineError.invalidSpeed(let message) {
            XCTAssertEqual(expectedError.type, "invalidSpeed", testCaseId)
            if let messageContains = expectedError.messageContains {
                XCTAssertTrue(message.contains(messageContains), "\(testCaseId) message was: \(message)")
            }
        } catch {
            XCTFail("\(testCaseId) threw unsupported error: \(error)")
        }
    }

    private func assertSymbols(_ actual: [TimedMorseSymbol], _ expected: [ExpectedSymbol], _ testCaseId: String) {
        XCTAssertEqual(actual.count, expected.count, testCaseId)
        for (index, pair) in zip(actual, expected).enumerated() {
            XCTAssertEqual(pair.0.kind.rawValue, pair.1.kind, "\(testCaseId) symbol \(index) kind")
            XCTAssertEqual(pair.0.character, pair.1.character, "\(testCaseId) symbol \(index) character")
            XCTAssertEqual(pair.0.startSeconds, pair.1.startSeconds, accuracy: 1e-12, "\(testCaseId) symbol \(index) startSeconds")
        }
    }

    private func morseContrastRatio(_ left: MorseRGB, _ right: MorseRGB) -> Double {
        let leftLuminance = morseRelativeLuminance(left)
        let rightLuminance = morseRelativeLuminance(right)
        let lighter = max(leftLuminance, rightLuminance)
        let darker = min(leftLuminance, rightLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private func profile(from input: TimingProfileInput) throws -> MorseTimingProfile {
        if let name = input.name {
            guard let profileName = MorseProfileName(rawValue: name) else {
                throw MorseEngineError.unknownProfile(name)
            }
            return profileForName(profileName)
        }
        guard let characterWpm = input.characterWpm?.value, let effectiveWpm = input.effectiveWpm?.value else {
            throw MorseEngineError.invalidSpeed("fixture profile must name a profile or provide characterWpm/effectiveWpm")
        }
        return try farnsworthTiming(characterWpm: characterWpm, effectiveWpm: effectiveWpm)
    }
}

private struct FixtureHeader: Decodable {
    let schemaVersion: Int
    let kind: String
}

private struct TimingFixture: Decodable {
    let cases: [TimingCase]
}

private struct TimingCase: Decodable {
    let id: String
    let input: TimingInput
    let expectedOutput: TimingOutput?
    let expectedError: ExpectedError?
}

private struct TimingInput: Decodable {
    let text: String
    let profile: TimingProfileInput
}

private struct TimingProfileInput: Decodable {
    let name: String?
    let characterWpm: FixtureNumber?
    let effectiveWpm: FixtureNumber?
}

private struct TimingOutput: Decodable {
    let normalizedText: String
    let totalDurationSeconds: Double
    let durationsSeconds: TimingDurations
    let effectiveWpm: Double
    let symbolCounts: SymbolCounts
    let lastSymbolKind: String?
    let symbols: [ExpectedSymbol]?
}

private struct ExpectedSymbol: Decodable {
    let kind: String
    let startSeconds: Double
    let character: String?
}

private struct TimingDurations: Decodable {
    let dot: Double
    let dash: Double
    let intraCharacterGap: Double
    let interCharacterGap: Double
    let wordGap: Double
}

private struct SymbolCounts: Decodable, Equatable {
    let dot: Int
    let dash: Int
    let intraCharacterGap: Int
    let interCharacterGap: Int
    let wordGap: Int
}

private struct WordWeightingFixture: Decodable {
    let cases: [WordWeightingCase]
}

private struct WordWeightingCase: Decodable {
    let id: String
    let input: TextInput
    let expectedOutput: WordWeightingOutput?
    let expectedError: ExpectedError?
}

private struct TextInput: Decodable {
    let text: String
}

private struct WordWeightingOutput: Decodable {
    let weightedCharacters: Int
    let unweightedCharacters: Int
    let needsOfficialRic1Section83Sample: Bool
}

private struct ScoringFixture: Decodable {
    let cases: [ScoringCase]
}

private struct ScoringCase: Decodable {
    let id: String
    let input: ScoringInput
    let expectedOutput: MorseExamScore?
    let expectedError: ExpectedError?
}

private struct ScoringInput: Decodable {
    let expected: String
    let received: String
}

private struct CopyExamFixture: Decodable {
    let cases: [CopyExamCase]
}

private struct CopyExamCase: Decodable {
    let id: String
    let input: CopyExamInput
    let expectedOutput: CopyExamOutput
}

private struct CopyExamInput: Decodable {
    let seed: String
    let profile: TimingProfileInput
    let minWeightedCharacters: Int
    let minDurationSeconds: Double
}

private struct CopyExamOutput: Decodable {
    let minWeightedCharacters: Int
    let minDurationSeconds: Double
    let text: String?
    let normalizedText: String?
    let weightedCharacters: Int?
    let unweightedCharacters: Int?
    let durationSeconds: Double?
}

private struct CopyDiffFixture: Decodable {
    let cases: [CopyDiffCase]
}

private struct CopyDiffCase: Decodable {
    let id: String
    let input: ScoringInput
    let expectedOutput: MorseCopyDiff?
    let expectedError: ExpectedError?
}

private struct ValidationFixture: Decodable {
    let cases: [ValidationCase]
}

private struct ValidationCase: Decodable {
    let id: String
    let input: TextInput
    let expectedOutput: ValidationResult
}

private struct CourseExercisesFixture: Decodable {
    let cases: [CourseExercisesCase]
}

private struct CourseExercisesCase: Decodable {
    let id: String
    let input: CourseExercisesInput
    let expectedOutput: CourseExercisesOutput
}

private struct CourseExercisesInput: Decodable {
    let lessonId: String
    let seed: String
}

private struct CourseExercisesOutput: Decodable {
    let exercises: [ExpectedCourseExercise]
}

private struct CourseStreakFixture: Decodable {
    let cases: [CourseStreakCase]
}

private struct CourseStreakCase: Decodable {
    let id: String
    let input: CourseStreakInput
    let expectedOutput: CourseStreakOutput
}

private struct CourseStreakInput: Decodable {
    let todayIso: String
    let activity: [MorseDailyActivityRecord]
}

private struct CourseStreakOutput: Decodable {
    let streak: Int
}

private struct SendingFixture: Decodable {
    let cases: [SendingCase]
}

private struct SendingCase: Decodable {
    let id: String
    let input: SendingInput
    let expectedOutput: SendingOutput
}

private struct SendingInput: Decodable {
    let profile: TimingProfileInput?
    let durationsSeconds: [Double]?
    let applyToText: String?
    let expected: String?
    let sent: String?
    let completedWithinTime: Bool?
}

private struct SendingOutput: Decodable {
    let elements: String?
    let decoded: MorseDecodedCharacter?
    let appliedText: String?
    let timingConsistencyPercent: Int?
    let averageRatioToExpected: Double?
    let dotDashRatio: Double?
    let errors: Int?
    let passed: Bool?
    let markPercent: Int?
}

private struct ExpectedCourseExercise: Decodable {
    let kind: String
    let character: String?
    let options: [String]?
    let text: String?

    func exercise() throws -> MorseCourseExercise {
        switch kind {
        case "meet":
            return .meet(try required(character, "character"))
        case "choose":
            return .choose(try required(character, "character"), try required(options, "options"))
        case "type-character":
            return .typeCharacter(try required(character, "character"))
        case "type-group":
            return .typeGroup(try required(text, "text"))
        default:
            throw MorseEngineError.invalidSpeed("unsupported Morse course exercise kind: \(kind)")
        }
    }

    private func required<T>(_ value: T?, _ field: String) throws -> T {
        guard let value else {
            throw MorseEngineError.invalidSpeed("missing \(field) for Morse course exercise")
        }
        return value
    }
}

private struct ExpectedError: Decodable {
    let type: String
    let messageContains: String?
    let invalidCharacters: [InvalidMorseCharacter]?
}

private enum FixtureNumber: Decodable {
    case number(Double)
    case nan

    var value: Double {
        switch self {
        case let .number(value):
            return value
        case .nan:
            return .nan
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Double.self) {
            self = .number(value)
            return
        }
        let value = try container.decode(String.self)
        guard value == "NaN" else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "unsupported fixture number: \(value)")
        }
        self = .nan
    }
}

private func symbolCounts(_ symbols: [TimedMorseSymbol]) -> SymbolCounts {
    SymbolCounts(
        dot: symbols.filter { $0.kind == .dot }.count,
        dash: symbols.filter { $0.kind == .dash }.count,
        intraCharacterGap: symbols.filter { $0.kind == .intraCharacterGap }.count,
        interCharacterGap: symbols.filter { $0.kind == .interCharacterGap }.count,
        wordGap: symbols.filter { $0.kind == .wordGap }.count
    )
}

private func morseFixturePaths() throws -> [URL] {
    let root = try repositoryRoot()
    return try jsonFiles(in: root.appending(path: "fixtures/morse")).sorted { lhs, rhs in
        lhs.path(percentEncoded: false) < rhs.path(percentEncoded: false)
    }
}

private func repositoryRoot() throws -> URL {
    var cursor = URL(fileURLWithPath: #filePath)
    while cursor.path(percentEncoded: false) != "/" {
        let candidate = cursor.appending(path: "fixtures/morse")
        if FileManager.default.fileExists(atPath: candidate.path(percentEncoded: false)) {
            return cursor
        }
        cursor.deleteLastPathComponent()
    }
    throw MorseEngineError.invalidSpeed("could not locate repository root from #filePath")
}

private func jsonFiles(in directory: URL) throws -> [URL] {
    let entries = try FileManager.default.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey]
    )
    var paths: [URL] = []
    for entry in entries {
        let values = try entry.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey])
        if values.isDirectory == true {
            paths.append(contentsOf: try jsonFiles(in: entry))
        } else if values.isRegularFile == true, entry.pathExtension == "json" {
            paths.append(entry)
        }
    }
    return paths
}

private extension String {
    func fixtureRelativePath() -> String {
        guard let range = range(of: "fixtures/") else { return self }
        return String(self[range.lowerBound...])
    }
}
