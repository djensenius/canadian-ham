import XCTest
#if os(iOS)
import UIKit
#endif

@MainActor
final class CanadianHamExamToolsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        XCUIApplication().terminate()
#if os(iOS)
        XCUIDevice.shared.orientation = .portrait
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
#endif
        try super.tearDownWithError()
    }

    func testPracticeCalculatorSheetKeepsAnswersHittableAtMediumDetent() throws {
        let app = launchPracticeQuestion()
        defer { app.terminate() }

        openTool(.calculator, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["calculator-result"].firstMatch.waitForExistence(timeout: 5))
        waitBriefly(0.8)
        assertVisibleAnswerButtonsRemainHittable(in: app, context: "practice calculator sheet")
    }

    func testForcedRegularIPhoneLandscapeCalculatorUsesSheetAndKeepsSelection() throws {
#if os(iOS)
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom == .pad, "Forced-regular iPhone sheet persistence is covered by the targeted iPhone run.")
        XCUIDevice.shared.orientation = .landscapeLeft
        waitBriefly(0.8)
        defer {
            XCUIDevice.shared.orientation = .portrait
            waitBriefly(0.8)
        }

        let app = launchPracticeQuestion(extraArguments: [
            "-CanadianHamForceRegularHorizontalSizeClass",
            "-CanadianHamPracticeMode", "review-later"
        ])
        defer { app.terminate() }

        let question = app.staticTexts["question-stem"].firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 10), "Expected the practice question before opening the calculator")
        let initialQuestionText = question.label

        let answer = app.descendants(matching: .any)["answer-A-button"].firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 5), "Expected answer A before selecting an answer")
        scrollBackgroundUntilHittable(answer, in: app, maxSwipes: 12)
        XCTAssertTrue(answer.isHittable, "Expected answer A to be hittable before selecting it")
        answer.tap()
        waitBriefly()
        XCTAssertTrue(answer.isSelected, "Answer A should be selected before opening the calculator")
        let selectedAnswerLabel = answer.label

        openTool(.calculator, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["calculator-result"].firstMatch.waitForExistence(timeout: 5), "Expected the calculator sheet UI after opening the calculator")
        assertCalculatorPresentedAsSheet(in: app, context: "forced-regular iPhone landscape after open")
        waitBriefly(1.0)
        XCTAssertTrue(app.descendants(matching: .any)["calculator-result"].firstMatch.exists, "The calculator sheet should still be open after SwiftUI settles")
        assertCalculatorPresentedAsSheet(in: app, context: "forced-regular iPhone landscape after settle")
        XCTAssertEqual(question.label, initialQuestionText, "Opening the calculator sheet must not rebuild to a different question")
        XCTAssertEqual(answer.label, selectedAnswerLabel, "Opening the calculator sheet must preserve the selected answer label")
        XCTAssertTrue(answer.isSelected, "Opening the calculator sheet must preserve the selected answer state")
#else
        throw XCTSkip("Forced-regular iPhone sheet persistence is iOS-only.")
#endif
    }

    func testForcedRegularIPhoneLandscapeMediumSheetScrollsEveryCalculatorKey() throws {
#if os(iOS)
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom == .pad, "Forced-regular iPhone landscape sheet scrolling is covered by the targeted iPhone run.")
        XCUIDevice.shared.orientation = .landscapeLeft
        waitBriefly(0.8)
        defer {
            XCUIDevice.shared.orientation = .portrait
            waitBriefly(0.8)
        }

        let app = launchPracticeQuestion(extraArguments: ["-CanadianHamForceRegularHorizontalSizeClass"])
        defer { app.terminate() }

        openTool(.calculator, in: app)
        assertCalculatorPresentedAsSheet(in: app, context: "forced-regular iPhone landscape key reachability")
        let calculatorScrollView = calculatorScrollView(in: app, requiredFor: "landscape medium sheet key reachability", timeout: 5)
        XCTAssertEqual(calculatorScrollView.elementType, .scrollView, "Landscape medium sheets must wrap the calculator in a scroll view so keys scroll instead of shrinking below 44 pt")
        for identifier in calculatorKeyIdentifiers {
            let key = app.buttons[identifier].firstMatch
            scrollCalculatorPanelUntilElementExists(key, in: app, maxSwipes: 10)
            XCTAssertTrue(key.exists, "Expected calculator key \(identifier) to exist in the scrollable landscape sheet")
            scrollExamToolUntilHittable(key, in: app, maxSwipes: 10)
            XCTAssertTrue(key.isHittable, "Calculator key \(identifier) should be hittable after scrolling the landscape medium sheet. Frame: \(frameDescription(key.frame))")
            XCTAssertGreaterThanOrEqual(key.frame.height, 44, "Calculator key \(identifier) must preserve the 44 pt hit target while scrolling. Frame: \(frameDescription(key.frame))")
        }
#else
        throw XCTSkip("Forced-regular iPhone landscape sheet scrolling is iOS-only.")
#endif
    }

    func testReferenceSheetToolHiddenUntilTask44Dot4() throws {
        let app = launchPracticeQuestion()
        defer { app.terminate() }

        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons[Tool.calculator.buttonIdentifier].firstMatch.exists)
        XCTAssertTrue(app.buttons[Tool.hint.buttonIdentifier].firstMatch.exists)
        XCTAssertFalse(app.buttons[Tool.referenceSheet.buttonIdentifier].firstMatch.exists, "task-44.3 ships only the calculator on Apple; the reference sheet follows in task-44.4")

        let advancedApp = launchAdvancedPracticeQuestion()
        defer { advancedApp.terminate() }
        XCTAssertTrue(advancedApp.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(advancedApp.buttons[Tool.calculator.buttonIdentifier].firstMatch.exists)
        XCTAssertFalse(advancedApp.buttons[Tool.hint.buttonIdentifier].firstMatch.exists, "Advanced course has no active Apple hints in task-50.12")
        XCTAssertFalse(advancedApp.buttons[Tool.referenceSheet.buttonIdentifier].firstMatch.exists, "Advanced course must not offer the Basic reference sheet")
    }

    func testLargestDynamicTypeKeepsHintToolButtonReachable() throws {
        let app = launchPracticeQuestion(extraArguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        defer { app.terminate() }

        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
        let calculator = app.buttons[Tool.calculator.buttonIdentifier].firstMatch
        let hint = app.buttons[Tool.hint.buttonIdentifier].firstMatch
        XCTAssertTrue(calculator.waitForExistence(timeout: 5), "Expected the calculator button at the largest accessibility text size")
        XCTAssertTrue(hint.waitForExistence(timeout: 5), "Expected the hint button at the largest accessibility text size")
        XCTAssertEqual(hint.label, "Hint", "The hint tool button keeps the visible localized title")
        scrollExamToolUntilHittable(calculator, in: app, maxSwipes: 8)
        XCTAssertTrue(calculator.isHittable, "The calculator button should remain hittable at the largest accessibility text size. Frame: \(frameDescription(calculator.frame))")
        scrollExamToolUntilHittable(hint, in: app, maxSwipes: 8)
        XCTAssertTrue(hint.isHittable, "The hint button should remain hittable at the largest accessibility text size. Frame: \(frameDescription(hint.frame))")
        hint.tap()
        XCTAssertTrue(app.descendants(matching: .any)[Tool.hint.panelIdentifier].firstMatch.waitForExistence(timeout: 5), "Tapping the largest-text Hint button should open the hint tool")
    }

    func testHintToolLadderAndLessonLink() throws {
        let app = launchTwoLevelHintPracticeQuestion()
        defer { app.terminate() }

        openTool(.hint, in: app)
        XCTAssertTrue(app.staticTexts["hint-tool-empty"].firstMatch.waitForExistence(timeout: 5), "Hint panel should start empty before the learner asks for help")
        XCTAssertTrue(app.buttons["hint-show-level-1-button"].firstMatch.waitForExistence(timeout: 5), "Hint 1 should be the first available action")
        XCTAssertFalse(app.buttons["hint-show-level-2-button"].firstMatch.exists, "Hint 2 must not be available before Hint 1")

        app.buttons["hint-show-level-1-button"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["hint-level-1-title"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["hint-show-level-2-button"].firstMatch.waitForExistence(timeout: 5), "Two-level hint files should reveal Hint 2 only after Hint 1")
        XCTAssertFalse(app.descendants(matching: .any)["hint-reference-pointer"].firstMatch.exists, "Reference-sheet pointers stay hidden until the Apple sheet is available")

        app.buttons["hint-show-level-2-button"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["hint-level-2-title"].firstMatch.waitForExistence(timeout: 5))
        let review = app.buttons["hint-review-in-lesson-button"].firstMatch
        XCTAssertTrue(review.waitForExistence(timeout: 5), "The lesson link appears only after the last available hint level")
        XCTAssertEqual(review.label, "Review in lesson", "The link label must stay generic before answering")
        review.tap()
        let heading = app.descendants(matching: .any)["lesson-heading-wavelength-and-frequency"].firstMatch
        XCTAssertTrue(heading.waitForExistence(timeout: 10), "Hint lesson link should open the shared sectionAnchor")
        XCTAssertTrue(heading.isHittable || isFullyVisible(heading, in: app, requiresHittable: false), "Hint lesson link should scroll the target heading into view. Frame: \(frameDescription(heading.frame))")

        tapNavigationBack(in: app, context: "returning from hint lesson link")
        let questionID = app.descendants(matching: .any)["question-identifier"].firstMatch
        XCTAssertTrue(questionID.waitForExistence(timeout: 10), "Back from the hint lesson should return to the practice question")
        XCTAssertEqual(questionID.label, "B-006-008-004", "The practice session should keep the same question after a hint lesson round trip")
        openTool(.hint, in: app)
        XCTAssertTrue(app.staticTexts["hint-level-2-title"].firstMatch.waitForExistence(timeout: 5), "The practice session should keep Hint 2 visible after returning from the lesson")
    }

    func testOneLevelHintHasNoSecondHintAffordance() throws {
        let app = launchOneLevelHintPracticeQuestion()
        defer { app.terminate() }

        openTool(.hint, in: app)
        app.buttons["hint-show-level-1-button"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["hint-level-1-title"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["hint-show-level-2-button"].firstMatch.exists, "One-level hint files must not show an empty Hint 2 action")
        XCTAssertTrue(app.buttons["hint-review-in-lesson-button"].firstMatch.waitForExistence(timeout: 5), "One-level files show the lesson link after Hint 1")
    }

    func testSimulatedHingeStableSlightOpenPeeksHintOneInPractice() throws {
        let app = launchTwoLevelHintPracticeQuestion(extraArguments: [
            "-CanadianHamExamToolInitialDetent", "large",
            "-CanadianHamSimulatedHingeSequence", "closed:0@0,partiallyOpen:25@1.0"
        ])
        defer { app.terminate() }

        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10), "Expected the practice question before the simulated hinge peek")
        XCTAssertTrue(app.descendants(matching: .any)[Tool.hint.panelIdentifier].firstMatch.waitForExistence(timeout: 5), "A stable slight-open simulated hinge posture should open the existing hint panel")
        XCTAssertTrue(app.staticTexts["hint-level-1-title"].firstMatch.waitForExistence(timeout: 5), "The hinge peek should reveal Hint 1 through the existing hint UI")
        XCTAssertTrue(app.buttons["hint-show-level-2-button"].firstMatch.waitForExistence(timeout: 5), "The normal hint ladder remains available after the peek reveals Hint 1")
        waitBriefly(0.8)
        try auditIgnoringOccludedLessonTextContrast(app: app)
    }

    func testSimulatedHingeDismissedPeekReopensOnlyAfterReset() throws {
        let app = launchTwoLevelHintPracticeQuestion(extraArguments: [
            "-CanadianHamExamToolInitialDetent", "large",
            "-CanadianHamSimulatedHingeSequence", "closed:0@0,partiallyOpen:25@1.0,partiallyOpen:26@3.0,unfolded:180@4.0,partiallyOpen:25@4.2"
        ])
        defer { app.terminate() }

        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10), "Expected the practice question before the simulated hinge peek")
        let hintPanel = app.descendants(matching: .any)[Tool.hint.panelIdentifier].firstMatch
        XCTAssertTrue(hintPanel.waitForExistence(timeout: 5), "The initial stable peek should open Hint")
        closeTool(in: app)
        XCTAssertTrue(hintPanel.waitForNonExistence(timeout: 2), "Dismissing the peek-opened Hint panel should close it")
        waitBriefly(1.2)
        XCTAssertFalse(hintPanel.exists, "An in-band sample while the same peek posture is active must not reopen a dismissed panel")
        XCTAssertTrue(hintPanel.waitForExistence(timeout: 5), "After a fully-open reset, a fresh stable dwell may peek again")
    }

    func testSimulatedHingePeekStillWorksAfterHintLessonRoundTrip() throws {
        let app = launchTwoLevelHintPracticeQuestion(extraArguments: [
            "-CanadianHamExamToolInitialDetent", "large",
            "-CanadianHamSimulatedHingeSequence", "closed:0@0,partiallyOpen:25@6.0"
        ])
        defer { app.terminate() }

        openTool(.hint, in: app)
        revealBothHints(in: app)
        let review = app.buttons["hint-review-in-lesson-button"].firstMatch
        XCTAssertTrue(review.waitForExistence(timeout: 5), "The lesson link appears after both hints")
        review.tap()
        let heading = app.descendants(matching: .any)["lesson-heading-wavelength-and-frequency"].firstMatch
        XCTAssertTrue(heading.waitForExistence(timeout: 10), "Hint lesson link should open the shared sectionAnchor")
        tapNavigationBack(in: app, context: "returning from hint lesson before delayed hinge peek")
        XCTAssertTrue(app.descendants(matching: .any)["question-identifier"].firstMatch.waitForExistence(timeout: 10), "Back from the hint lesson should return to the practice question")
        XCTAssertTrue(app.descendants(matching: .any)[Tool.hint.panelIdentifier].firstMatch.waitForExistence(timeout: 10), "The DEBUG hinge provider should reattach after the lesson round trip and peek Hint again")
    }

    func testSimulatedHingeFastUnfoldDoesNotPeekHintOneInPractice() throws {
        let app = launchTwoLevelHintPracticeQuestion(extraArguments: [
            "-CanadianHamSimulatedHingeSequence", "closed:0@0,partiallyOpen:25@0.2,unfolded:180@0.35"
        ])
        defer { app.terminate() }

        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10), "Expected the practice question before the simulated fast unfold")
        waitBriefly(1.2)
        XCTAssertFalse(app.descendants(matching: .any)[Tool.hint.panelIdentifier].firstMatch.exists, "A normal fast unfold through the peek band must not open the hint panel")
        XCTAssertFalse(app.staticTexts["hint-level-1-title"].firstMatch.exists, "A normal fast unfold must not reveal Hint 1")
        XCTAssertTrue(app.buttons[Tool.hint.buttonIdentifier].firstMatch.exists, "The Hint button remains the primary accessible path")
    }

    func testSimulatedHingeNeverPeeksHintOneInMockExam() throws {
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamSeed", "ui-exam-tools-hinge-mock",
            "-CanadianHamMockExamQuestionID", "B-006-008-004",
            "-CanadianHamMockExamLimit", "3",
            "-CanadianHamSimulatedHingeSequence", "closed:0@0,partiallyOpen:25@0.2,partiallyOpen:25@1.0,partiallyOpen:25@2.0"
        ])
        defer { app.terminate() }

        tapStartMockExam(in: app)
        waitBriefly(1.2)
        XCTAssertFalse(app.buttons[Tool.hint.buttonIdentifier].firstMatch.exists, "Mock exams must never expose the Hint button")
        XCTAssertFalse(app.descendants(matching: .any)[Tool.hint.panelIdentifier].firstMatch.exists, "Mock exams must never open the hint panel from hinge posture")
        XCTAssertFalse(app.staticTexts["hint-level-1-title"].firstMatch.exists, "Mock exams must never reveal Hint 1 from hinge posture")
    }

    func testCalculatorAutoFocusesHardwareKeyboardOnOpen() throws {
        let app = launchPracticeQuestion()
        defer { app.terminate() }

        openTool(.calculator, in: app)
        app.typeKey("7", modifierFlags: [])
        waitBriefly()
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "7", "Opening the calculator should focus hardware-keyboard input without tapping inside the panel")
    }

    func testCalculatorKeyboardInputIsFocusScoped() throws {
        let app = launchPracticeQuestion(extraArguments: ["-CanadianHamPracticeMode", "review-later"])
        defer { app.terminate() }

        openTool(.calculator, in: app)
        let keyTwo = app.buttons["calculator-key-2"].firstMatch
        XCTAssertTrue(keyTwo.waitForExistence(timeout: 5), "Expected the calculator 2 key")
        XCTAssertTrue(keyTwo.isHittable, "The calculator 2 key should be hittable before keyboard entry")
        keyTwo.tap()
        let focusedCalculator = focusCalculatorKeyboard(in: app)
        typeCalculatorKeys(["3"], on: focusedCalculator)
        XCTAssertTrue(app.descendants(matching: .any)["calculator-result"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "23", "Tapping a calculator key must not let the background focus resetter disable hardware-keyboard input")

        let answer = app.descendants(matching: .any)["answer-A-button"].firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 5), "Expected an answer to clear calculator keyboard focus")
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            scrollBackgroundUntilHittable(answer, in: app, maxSwipes: 12)
        } else {
            positionElementFullyVisibleAboveToolSheet(answer, in: app, context: "answer A before clearing calculator keyboard focus")
        }
#else
        scrollBackgroundUntilHittable(answer, in: app, maxSwipes: 12)
#endif
        XCTAssertTrue(answer.isHittable, "Answer should be hittable before clearing calculator keyboard focus")
        answer.tap()
        waitBriefly(0.5)
        app.typeKey("1", modifierFlags: [])
        waitBriefly()
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "23", "Typing after answer focus leaves must not change the calculator")

        let allClear = app.buttons["calculator-key-all-clear"].firstMatch
        XCTAssertTrue(allClear.waitForExistence(timeout: 5), "Expected the calculator all-clear key before refocusing")
        scrollExamToolUntilHittable(allClear, in: app, maxSwipes: 8)
        XCTAssertTrue(allClear.isHittable, "All-clear should be hittable before refocusing the calculator")
        allClear.tap()
        keyTwo.tap()
        typeCalculatorKeys(["4"], on: focusedCalculator)
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "24", "Calculator should accept hardware input again after tapping back into the calculator")

        let questionCard = app.descendants(matching: .any)["question-card"].firstMatch
        XCTAssertTrue(questionCard.waitForExistence(timeout: 5), "Expected the question card before tapping non-text exam content")
        scrollBackgroundUntilHittable(questionCard, in: app, maxSwipes: 12)
        questionCard.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.9)).tap()
        waitBriefly(0.5)
        app.typeKey("1", modifierFlags: [])
        waitBriefly()
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "24", "Typing after tapping card padding must not change the calculator")
    }

    func testCalculatorValueSurvivesCloseAndReopenAndResetsForNewSession() throws {
        let app = launchPracticeQuestion(extraArguments: ["-CanadianHamPracticeLimit", "1"])
        defer { app.terminate() }

        openTool(.calculator, in: app)
        XCTAssertTrue(focusCalculatorKeyboard(in: app).exists)
        tapCalculatorKey("calculator-key-2", in: app)
        tapCalculatorKey("calculator-key-add", in: app)
        tapCalculatorKey("calculator-key-2", in: app)
        tapCalculatorKey("calculator-key-equals", in: app)
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "4")
        closeTool(in: app)
        openTool(.calculator, in: app)
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "4")
        closeTool(in: app)

        let answer = app.descendants(matching: .any)["answer-A-button"].firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 5), "Expected an answer to finish the one-question session")
        scrollBackgroundUntilHittable(answer, in: app, maxSwipes: 12)
        XCTAssertTrue(answer.isHittable, "Expected the answer to be hittable before finishing the session")
        answer.tap()
        let finish = app.buttons["next-question-button"].firstMatch
        XCTAssertTrue(finish.waitForExistence(timeout: 5), "Expected the Finish session button")
        scrollExamToolUntilHittable(finish, in: app, maxSwipes: 12)
        XCTAssertTrue(finish.isHittable, "Expected the Finish session button to be hittable")
        finish.tap()

        openTool(.calculator, in: app)
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "0")
    }

    func testMockExamDoesNotExposeHints() throws {
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamSeed", "ui-exam-tools-no-hints",
            "-CanadianHamMockExamQuestionID", "B-006-008-004",
            "-CanadianHamMockExamLimit", "3"
        ])
        defer { app.terminate() }

        tapStartMockExam(in: app)
        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons[Tool.calculator.buttonIdentifier].firstMatch.exists)
        XCTAssertFalse(app.buttons[Tool.hint.buttonIdentifier].firstMatch.exists, "Mock exams must never expose hints")
    }

    func testMockExamCalculatorKeepsAnswersHittableAndTimerRuns() throws {
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamSeed", "ui-exam-tools-timer",
            "-CanadianHamMockExamQuestionID", "B-001-002-002",
            "-CanadianHamMockExamLimit", "3",
            "-CanadianHamExamTimerEnabled", "true"
        ])
        defer { app.terminate() }

        tapStartMockExam(in: app)
        let timerText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Timer running")).firstMatch
        XCTAssertTrue(timerText.waitForExistence(timeout: 10), "Mock exam should start with the optional timer running when enabled")
        let initialTimerLabel = timerText.label
        openTool(.calculator, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["calculator-result"].firstMatch.waitForExistence(timeout: 5))
        RunLoop.current.run(until: Date().addingTimeInterval(2.2))
        let advancedTimer = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ AND label != %@", "Timer running", initialTimerLabel)).firstMatch
        XCTAssertTrue(advancedTimer.waitForExistence(timeout: 5), "The mock-exam timer should continue while a tool is open; initial label was \(initialTimerLabel)")
        assertVisibleAnswerButtonsRemainHittable(in: app, context: "mock calculator sheet")
    }

    func testMockExamQuestionsNavigatorPresentsAfterCalculatorSheet() throws {
#if os(iOS)
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom == .pad, "Compact iPhone navigator-sheet coordination is covered by the targeted iPhone run.")
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamSeed", "ui-exam-tools-navigator",
            "-CanadianHamMockExamQuestionID", "B-001-002-002",
            "-CanadianHamMockExamLimit", "3"
        ])
        defer { app.terminate() }

        tapStartMockExam(in: app)
        openTool(.calculator, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["calculator-result"].firstMatch.waitForExistence(timeout: 5), "Expected the calculator sheet before opening the question navigator")
        let questions = app.buttons["mock-questions-button"].firstMatch
        XCTAssertTrue(questions.waitForExistence(timeout: 5), "Expected compact mock exam Questions control")
        scrollBackgroundUntilHittable(questions, in: app, maxSwipes: 12)
        XCTAssertTrue(questions.isHittable, "Questions should remain tappable while the calculator sheet is open")
        questions.tap()
        XCTAssertTrue(app.staticTexts["Question navigator"].firstMatch.waitForExistence(timeout: 5), "Tapping Questions while the calculator sheet is open should dismiss the tool sheet and then present the navigator")
        XCTAssertTrue(app.descendants(matching: .any)["calculator-result"].firstMatch.waitForNonExistence(timeout: 2), "The calculator sheet should be gone after the question navigator appears")
#else
        throw XCTSkip("Compact mock-exam navigator sheet coordination is iOS-only.")
#endif
    }

    func testCalculatorValueResetsForNewMockExam() throws {
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamSeed", "ui-exam-tools-mock-reset",
            "-CanadianHamMockExamQuestionID", "B-001-002-002",
            "-CanadianHamMockExamLimit", "1"
        ])
        defer { app.terminate() }

        tapStartMockExam(in: app)
        openTool(.calculator, in: app)
        let focusedCalculator = focusCalculatorKeyboard(in: app)
        typeCalculatorKeys(["7"], on: focusedCalculator)
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "7")
        closeTool(in: app)

        let endExam = app.buttons["end-mock-exam-button"].firstMatch
        XCTAssertTrue(endExam.waitForExistence(timeout: 5), "Expected End exam button")
        scrollExamToolUntilHittable(endExam, in: app, maxSwipes: 12)
        XCTAssertTrue(endExam.isHittable, "Expected End exam to be hittable")
        endExam.tap()
        let alert = app.alerts["End mock exam?"].firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "Expected end-exam confirmation")
        alert.buttons["End exam"].tap()

        tapStartMockExam(in: app)
        openTool(.calculator, in: app)
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "0", "Starting a new mock exam should reset calculator state")
    }

    func testSimulatedUnfoldedLandscapeWithoutForcedSizeClassUsesInspectorAndKeepsPracticeSelection() throws {
        let app = launchPracticeQuestion(extraArguments: [
            "-CanadianHamSimulatedWindowSize", "951x669",
            "-CanadianHamPracticeMode", "review-later"
        ])
        defer { app.terminate() }

        let question = app.staticTexts["question-stem"].firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 10), "Expected the practice question before opening a simulated unfolded landscape inspector")
        let initialQuestionText = question.label
        let answer = app.descendants(matching: .any)["answer-A-button"].firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 5), "Expected answer A before selecting an answer")
        scrollBackgroundUntilHittable(answer, in: app, maxSwipes: 12)
        XCTAssertTrue(answer.isHittable, "Expected answer A to be hittable before selecting it")
        answer.tap()
        waitBriefly()
        XCTAssertTrue(answer.isSelected, "Answer A should be selected before opening the simulated unfolded inspector")
        let selectedAnswerLabel = answer.label

        openTool(.calculator, in: app)
        let panel = app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch
        XCTAssertTrue(panel.waitForExistence(timeout: 5), "Simulated unfolded iPhone landscape should keep the calculator available while exercising the inspector selection policy")
        XCTAssertEqual(question.label, initialQuestionText, "Opening the simulated unfolded tool panel must not rebuild to a different question")
        XCTAssertEqual(answer.label, selectedAnswerLabel, "Opening the inspector must preserve the selected answer label")
        XCTAssertTrue(answer.isSelected, "Opening the inspector must preserve the selected answer state")
#if os(iOS)
        if app.windows.firstMatch.frame.width >= 800 {
            assertQuestionTitleWithinExamColumn(in: app, context: "simulated unfolded iPhone landscape inspector")
            assertVisibleAnswerButtonsRemainHittable(in: app, context: "simulated unfolded iPhone landscape inspector")
        }
#endif
    }

    func testSimulatedUnfoldedPortraitKeepsCompactSheet() throws {
        let app = launchPracticeQuestion(extraArguments: [
            "-CanadianHamSimulatedWindowSize", "669x951",
            "-CanadianHamPracticeMode", "review-later"
        ])
        defer { app.terminate() }

        openTool(.calculator, in: app)
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            assertCalculatorPresentedAsSheet(in: app, context: "simulated unfolded portrait iPhone")
        }
#endif
        XCTAssertTrue(app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch.waitForExistence(timeout: 5), "Simulated unfolded portrait should keep the calculator available in the compact sheet")
    }

    func testSimulatedFoldedToUnfoldedRequestKeepsPracticeQuestionSelectionAndCalculatorValue() throws {
        let app = launchPracticeQuestion(extraArguments: [
            "-CanadianHamSimulatedWindowSize", "382x644",
            "-CanadianHamShowSimulatedWindowSizeChangeControl",
            "-CanadianHamSimulatedWindowSizeAfterChange", "951x669",
            "-CanadianHamPracticeMode", "review-later"
        ])
        defer { app.terminate() }

        let question = app.staticTexts["question-stem"].firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 10), "Expected the practice question before simulated unfold")
        let initialQuestionText = question.label
        let questionID = app.descendants(matching: .any)["question-identifier"].firstMatch
        XCTAssertTrue(questionID.waitForExistence(timeout: 5), "Expected the practice question identifier before simulated unfold")
        let initialQuestionID = questionID.label

        let answer = app.descendants(matching: .any)["answer-A-button"].firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 5), "Expected answer A before simulated unfold")
        scrollBackgroundUntilHittable(answer, in: app, maxSwipes: 12)
        XCTAssertTrue(answer.isHittable, "Expected answer A to be hittable before simulated unfold")
        answer.tap()
        waitBriefly()
        XCTAssertTrue(answer.isSelected, "Answer A should be selected before simulated unfold")
        let selectedAnswerLabel = answer.label

        openTool(.calculator, in: app)
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            assertCalculatorPresentedAsSheet(in: app, context: "simulated folded iPhone before unfolding")
        }
#endif
        tapCalculatorKey("calculator-key-2", in: app)
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "2", "Expected the calculator value before the simulated unfold request")

        assertSimulatedLayoutMode(in: app, expectedMode: "compact", context: "folded before unfolding")
        applySimulatedWindowSizeChange(in: app, expectedSizeValue: "951x669", context: "folded to unfolded")
        assertSimulatedLayoutMode(in: app, expectedMode: "split", context: "folded to unfolded")
#if os(iOS)
        if app.windows.firstMatch.frame.width >= 800 {
            assertSimulatedLayoutChanged(in: app, to: .inspector, context: "folded to unfolded")
        } else {
            XCTContext.runActivity(named: "Narrow rendered Duo window cannot prove visual inspector transition") { activity in
                activity.add(XCTAttachment(string: "The DEBUG window-size hook applied 951x669, but this simulator renders a \(frameDescription(app.windows.firstMatch.frame)) window; the folded-to-unfolded visual inspector transition remains real-device coverage in TASK-54."))
            }
        }
#else
        assertSimulatedLayoutChanged(in: app, to: .inspector, context: "folded to unfolded")
#endif

        if !app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch.exists {
            openTool(.calculator, in: app)
        }
        XCTAssertTrue(app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch.waitForExistence(timeout: 5), "Expected the calculator after the simulated unfold request")

        XCTAssertTrue(question.waitForExistence(timeout: 5), "Expected to remain in the practice session after the simulated unfold request")
        XCTAssertEqual(question.label, initialQuestionText, "Simulated unfolding must keep the same question")
        XCTAssertEqual(questionID.label, initialQuestionID, "Simulated unfolding must keep the same question identifier")
        XCTAssertEqual(answer.label, selectedAnswerLabel, "Simulated unfolding must preserve the selected answer label")
        XCTAssertTrue(answer.isSelected, "Simulated unfolding must preserve the selected answer state")
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "2", "Simulated unfolding must preserve the calculator value")
    }

    func testSimulatedUnfoldedToFoldedRequestKeepsPracticeQuestionSelectionAndCalculatorValue() throws {
        let app = launchPracticeQuestion(extraArguments: [
            "-CanadianHamSimulatedWindowSize", "951x669",
            "-CanadianHamShowSimulatedWindowSizeChangeControl",
            "-CanadianHamSimulatedWindowSizeAfterChange", "382x644",
            "-CanadianHamPracticeMode", "review-later"
        ])
        defer { app.terminate() }

        let question = app.staticTexts["question-stem"].firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 10), "Expected the practice question before simulated fold")
        let initialQuestionText = question.label
        let questionID = app.descendants(matching: .any)["question-identifier"].firstMatch
        XCTAssertTrue(questionID.waitForExistence(timeout: 5), "Expected the practice question identifier before simulated fold")
        let initialQuestionID = questionID.label

        let answer = app.descendants(matching: .any)["answer-A-button"].firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 5), "Expected answer A before simulated fold")
        scrollBackgroundUntilHittable(answer, in: app, maxSwipes: 12)
        XCTAssertTrue(answer.isHittable, "Expected answer A to be hittable before simulated fold")
        answer.tap()
        waitBriefly()
        XCTAssertTrue(answer.isSelected, "Answer A should be selected before simulated fold")
        let selectedAnswerLabel = answer.label

        openTool(.calculator, in: app)
        tapCalculatorKey("calculator-key-2", in: app)
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "2", "Expected the calculator value before the simulated fold request")

        assertSimulatedLayoutMode(in: app, expectedMode: "split", context: "unfolded before folding")
        applySimulatedWindowSizeChange(in: app, expectedSizeValue: "382x644", context: "unfolded to folded")
        assertSimulatedLayoutMode(in: app, expectedMode: "compact", context: "unfolded to folded")
        if !app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch.exists {
            openTool(.calculator, in: app)
        }
#if os(iOS)
        let expectedPresentation: SimulatedToolPresentationExpectation = UIDevice.current.userInterfaceIdiom == .phone ? .sheet : .inspector
#else
        let expectedPresentation: SimulatedToolPresentationExpectation = .inspector
#endif
        assertSimulatedLayoutChanged(in: app, to: expectedPresentation, context: "unfolded to folded")
        XCTAssertTrue(app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch.waitForExistence(timeout: 5), "Expected the calculator after the simulated fold request")

        XCTAssertTrue(question.waitForExistence(timeout: 5), "Expected to remain in the practice session after the simulated fold request")
        XCTAssertEqual(question.label, initialQuestionText, "Simulated folding must keep the same question")
        XCTAssertEqual(questionID.label, initialQuestionID, "Simulated folding must keep the same question identifier")
        XCTAssertEqual(answer.label, selectedAnswerLabel, "Simulated folding must preserve the selected answer label")
        XCTAssertTrue(answer.isSelected, "Simulated folding must preserve the selected answer state")
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "2", "Simulated folding must preserve the calculator value")
    }

    func testSimulatedUnfoldedLandscapeMockExamUsesCalculatorInspectorWithoutHints() throws {
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamSimulatedWindowSize", "951x669",
            "-CanadianHamMockExamSeed", "ui-exam-tools-duo-mock",
            "-CanadianHamMockExamQuestionID", "B-006-008-004",
            "-CanadianHamMockExamLimit", "3"
        ])
        defer { app.terminate() }

        tapStartMockExam(in: app)
        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons[Tool.calculator.buttonIdentifier].firstMatch.exists)
        XCTAssertFalse(app.buttons[Tool.hint.buttonIdentifier].firstMatch.exists, "Mock exams must never expose hints, including in simulated unfolded landscape")
        openTool(.calculator, in: app)
        let panel = app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch
        XCTAssertTrue(panel.waitForExistence(timeout: 5), "Simulated unfolded mock exams should keep the calculator available while exercising the inspector selection policy")
#if os(iOS)
        if app.windows.firstMatch.frame.width >= 800 {
            assertQuestionTitleWithinExamColumn(in: app, context: "simulated unfolded mock exam inspector")
            assertVisibleAnswerButtonsRemainHittable(in: app, context: "simulated unfolded mock exam inspector")
        }
#endif
    }

    func testRegularWidthUsesInspectorAndKeepsAnswersHittable() throws {
#if os(iOS)
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom != .pad, "Inspector layout is covered by the targeted iPad run.")
        try runRegularWidthInspectorScenario(orientation: .portrait, expectedInitialSidebarVisibility: .collapsed, expectedOpenSidebarVisibility: .collapsed, context: "iPad portrait")
        try runRegularWidthInspectorScenario(orientation: .portrait, expectedInitialSidebarVisibility: .visible, expectedOpenSidebarVisibility: .collapsed, extraArguments: ["-CanadianHamInitialSplitColumnVisibility", "all"], context: "iPad portrait visible sidebar")
        try runRegularWidthInspectorScenario(orientation: .landscapeLeft, expectedInitialSidebarVisibility: .visible, expectedOpenSidebarVisibility: .visible, context: "iPad landscape")
        XCUIDevice.shared.orientation = .portrait
#else
        throw XCTSkip("Inspector layout is covered by the targeted iPad run.")
#endif
    }

    func testAccessibilityAuditExamToolsLight() throws {
#if os(iOS)
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom == .pad, "The medium-detent audit exception is approved only for compact sheet presentation; iPad uses the inspector audit.")
#endif
        let app = launchAuditPracticeQuestion(appearance: "light")
        defer { app.terminate() }

        openTool(.calculator, in: app)
        waitForStableToolHeaderFrame(.calculator, in: app)
        try performMediumDetentExamToolAudit(on: app, context: "light calculator medium")
    }

    func testAccessibilityAuditExamToolsDark() throws {
#if os(iOS)
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom == .pad, "The medium-detent audit exception is approved only for compact sheet presentation; iPad uses the inspector audit.")
#endif
        let app = launchAuditPracticeQuestion(appearance: "dark")
        defer { app.terminate() }

        openTool(.calculator, in: app)
        waitForStableToolHeaderFrame(.calculator, in: app)
        try performMediumDetentExamToolAudit(on: app, context: "dark calculator medium")
    }

    func testLargeDetentCalculatorRunsFullAccessibilityAuditLightAndDark() throws {
        for appearance in ["light", "dark"] {
            let app = launchAuditPracticeQuestion(appearance: appearance, extraArguments: ["-CanadianHamExamToolInitialDetent", "large"])
            defer { app.terminate() }

            openTool(.calculator, in: app)
            expandCompactSheetToLarge(in: app)
            XCTAssertTrue(app.descendants(matching: .any)["calculator-keyboard-help"].firstMatch.waitForExistence(timeout: 5), "The calculator should show keyboard help when the large detent has room")
            waitBriefly(0.8)
            try auditIgnoringOccludedLessonTextContrast(app: app)
            app.terminate()
        }
    }

    func testAccessibilityAuditHintToolLightAndDark() throws {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            for appearance in ["light", "dark"] {
                let app = launchTwoLevelHintPracticeQuestion(appearance: appearance, extraArguments: ["-CanadianHamForceRegularHorizontalSizeClass"])
                defer { app.terminate() }

                openTool(.hint, in: app)
                XCTAssertTrue(app.descendants(matching: .any)[Tool.hint.panelIdentifier].firstMatch.waitForExistence(timeout: 5), "Expected iPad inspector hint panel")
                revealBothHints(in: app)
                waitBriefly(0.8)
                try auditIgnoringOccludedLessonTextContrast(app: app)
                app.terminate()
            }
        } else {
            for appearance in ["light", "dark"] {
                let app = launchTwoLevelHintPracticeQuestion(appearance: appearance, extraArguments: ["-CanadianHamExamToolInitialDetent", "large"])
                defer { app.terminate() }

                openTool(.hint, in: app)
                revealBothHints(in: app)
                waitBriefly(0.8)
                try auditIgnoringOccludedLessonTextContrast(app: app)
                app.terminate()
            }
        }
#else
        for appearance in ["light", "dark"] {
            let app = launchTwoLevelHintPracticeQuestion(appearance: appearance)
            defer { app.terminate() }

            openTool(.hint, in: app)
            revealBothHints(in: app)
            waitBriefly(0.8)
            try auditIgnoringOccludedLessonTextContrast(app: app)
            app.terminate()
        }
#endif
    }

    func testAccessibilityAuditHintedAnswerResultLightAndDark() throws {
        for appearance in ["light", "dark"] {
            let app = launchTwoLevelHintPracticeQuestion(appearance: appearance)
            openTool(.hint, in: app)
            let first = app.buttons["hint-show-level-1-button"].firstMatch
            XCTAssertTrue(first.waitForExistence(timeout: 5), "Expected Hint 1 before qualifying a hinted answer")
            scrollExamToolUntilHittable(first, in: app, maxSwipes: 8)
            first.tap()
            waitBriefly(0.7)
            closeTool(in: app)
            waitBriefly(0.3)

            let answer = app.descendants(matching: .any)["answer-A-button"].firstMatch
            XCTAssertTrue(answer.waitForExistence(timeout: 5), "Expected answer A after closing the hint tool")
            scrollBackgroundUntilHittable(answer, in: app, maxSwipes: 12)
            XCTAssertTrue(answer.isHittable, "Expected answer A to be hittable before completing the hinted-answer flow")
            answer.tap()
            let feedback = app.descendants(matching: .any)["answer-feedback-title"].firstMatch
            XCTAssertTrue(feedback.waitForExistence(timeout: 5), "Expected immediate feedback after a hinted answer")
            scrollBackgroundUntilHittable(feedback, in: app, maxSwipes: 12)
            scrollBackgroundPastElement(app.descendants(matching: .any)["exam-tool-calculator-button"].firstMatch, preserving: feedback, in: app, maxSwipes: 8)
            XCTAssertTrue(feedback.isHittable || isFullyVisible(feedback, in: app, requiresHittable: false), "Expected hinted-answer feedback to be visible before auditing the result. Frame: \(frameDescription(feedback.frame))")
            waitBriefly(0.8)
            try auditIgnoringOccludedLessonTextContrast(app: app)
            app.terminate()
        }
    }

    func testRegularWidthInspectorAccessibilityAuditLightAndDark() throws {
#if os(iOS)
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom != .pad, "Inspector audit is covered by the targeted iPad run.")
        for appearance in ["light", "dark"] {
            try runRegularWidthInspectorAuditScenario(orientation: .portrait, appearance: appearance, context: "iPad portrait inspector audit \(appearance)")
            try runRegularWidthInspectorAuditScenario(orientation: .landscapeLeft, appearance: appearance, context: "iPad landscape inspector audit \(appearance)")
        }
        XCUIDevice.shared.orientation = .portrait
#else
        throw XCTSkip("Inspector audit is covered by the targeted iPad run.")
#endif
    }

    func testSimulatedUnfoldedInspectorAccessibilityAuditLightAndDark() throws {
        for appearance in ["light", "dark"] {
            let app = launchAuditPracticeQuestion(appearance: appearance, extraArguments: ["-CanadianHamSimulatedWindowSize", "951x669"])
            defer { app.terminate() }

            openTool(.calculator, in: app)
            XCTAssertTrue(app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch.waitForExistence(timeout: 5), "Simulated unfolded inspector should present the calculator before auditing")
            waitBriefly(0.8)
            guard app.windows.firstMatch.frame.width >= 800 else {
                XCTContext.runActivity(named: "Narrow rendered window cannot produce meaningful unfolded landscape inspector audit geometry") { activity in
                    activity.add(XCTAttachment(string: "The simulated unfolded landscape policy is active, but this simulator renders a \(frameDescription(app.windows.firstMatch.frame)) window; the full unfolded inspector audit runs on iPad or real unfolded Duo landscape width."))
                }
                app.terminate()
                continue
            }
            try auditIgnoringOccludedLessonTextContrast(app: app)
            app.terminate()
        }
    }

    func testLargestDynamicTypeKeepsCalculatorGridReachableLightAndDark() throws {
        for appearance in ["light", "dark"] {
            let app = launchPracticeQuestion(appearance: appearance, extraArguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
            defer { app.terminate() }

            openTool(.calculator, in: app)
            XCTAssertTrue(app.descendants(matching: .any)["calculator-result"].firstMatch.waitForExistence(timeout: 5), "Expected the calculator panel before checking largest Dynamic Type reachability")
            let reciprocal = app.buttons["calculator-key-reciprocal"].firstMatch
            scrollCalculatorPanelUntilElementExists(reciprocal, in: app, maxSwipes: 10)
            XCTAssertTrue(reciprocal.exists, "The lower calculator keys should exist at the largest accessibility text size")
            scrollExamToolUntilHittable(reciprocal, in: app, maxSwipes: 10)
            XCTAssertTrue(reciprocal.isHittable, "The calculator grid should remain usable by scrolling at the largest accessibility text size")
            try auditIgnoringOccludedLessonTextContrast(app: app)
            app.terminate()
        }
    }

    func testPreciseScrollPositionsAnswerAboveToolSheet() throws {
        let app = launchPracticeQuestion(categoryID: "B-004", questionID: "B-004-001-001")
        defer { app.terminate() }

        openTool(.calculator, in: app)
        let answer = app.descendants(matching: .any)["answer-D-button"].firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 5))
        positionElementFullyVisibleAboveToolSheet(answer, in: app, context: "answer D with calculator open")
        XCTAssertTrue(answer.isHittable, "The positioned answer should be hittable with the calculator sheet open")
    }

    func testCaptureCalculatorEvidenceScreenshots() throws {
#if os(iOS)
        try XCTSkipUnless(evidenceDirectory() != nil, "Set CANADIAN_HAM_EXAM_TOOLS_EVIDENCE_DIR to write calculator evidence screenshots.")
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .portrait
            waitBriefly(0.8)
            for appearance in ["light", "dark"] {
                let app = launchPracticeQuestion(appearance: appearance, extraArguments: ["-CanadianHamForceRegularHorizontalSizeClass"])
                openTool(.calculator, in: app)
                XCTAssertTrue(app.descendants(matching: .any)["exam-tool-calculator-panel"].firstMatch.waitForExistence(timeout: 5))
                waitBriefly(0.8)
                try saveScreenshot(named: "calculator-ipad-inspector-\(appearance).png")
                app.terminate()
            }
            XCUIDevice.shared.orientation = .landscapeLeft
            waitBriefly(0.8)
            let landscapeApp = launchPracticeQuestion(appearance: "light", extraArguments: ["-CanadianHamForceRegularHorizontalSizeClass"])
            openTool(.calculator, in: landscapeApp)
            XCTAssertTrue(landscapeApp.descendants(matching: .any)["exam-tool-calculator-panel"].firstMatch.waitForExistence(timeout: 5))
            waitBriefly(0.8)
            try saveScreenshot(named: "calculator-ipad-inspector-landscape-light.png")
            landscapeApp.terminate()
            XCUIDevice.shared.orientation = .portrait
        } else {
            for appearance in ["light", "dark"] {
                let mediumApp = launchPracticeQuestion(appearance: appearance)
                openTool(.calculator, in: mediumApp)
                XCTAssertTrue(mediumApp.descendants(matching: .any)["calculator-result"].firstMatch.waitForExistence(timeout: 5))
                waitBriefly(0.8)
                try saveScreenshot(named: "calculator-iphone-medium-\(appearance).png")
                mediumApp.terminate()

                let largeApp = launchPracticeQuestion(appearance: appearance, extraArguments: ["-CanadianHamExamToolInitialDetent", "large"])
                openTool(.calculator, in: largeApp)
                XCTAssertTrue(largeApp.descendants(matching: .any)["calculator-keyboard-help"].firstMatch.waitForExistence(timeout: 5))
                waitBriefly(0.8)
                try saveScreenshot(named: "calculator-iphone-large-\(appearance).png")
                largeApp.terminate()
            }
        }
#else
        throw XCTSkip("Calculator evidence screenshots are captured from iPhone and iPad UI-test runs.")
#endif
    }

    private enum Tool {
        case calculator
        case hint
        case referenceSheet

        var buttonIdentifier: String {
            switch self {
            case .calculator: "exam-tool-calculator-button"
            case .hint: "exam-tool-hint-button"
            case .referenceSheet: "exam-tool-referenceSheet-button"
            }
        }

        var panelIdentifier: String {
            switch self {
            case .calculator: "exam-tool-calculator-panel"
            case .hint: "exam-tool-hint-panel"
            case .referenceSheet: "exam-tool-reference-sheet-panel"
            }
        }
    }

    private enum SimulatedToolPresentationExpectation {
        case inspector
        case sheet
    }

    private func applySimulatedWindowSizeChange(in app: XCUIApplication, expectedSizeValue: String, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons["debug-simulated-window-size-change-button"].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5), "\(context): expected the DEBUG simulated window-size change control", file: file, line: line)
        XCTAssertTrue(button.isHittable, "\(context): expected the DEBUG simulated window-size change control to be hittable", file: file, line: line)
        button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        assertSimulatedWindowSizeApplied(in: app, expectedSizeValue: expectedSizeValue, context: context, file: file, line: line)
    }

    private func assertSimulatedWindowSizeApplied(in app: XCUIApplication, expectedSizeValue: String, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let deadline = Date().addingTimeInterval(5)
        var observedValue: String?
        var observedLabel: String?
        while Date() < deadline {
            let button = app.buttons["debug-simulated-window-size-change-button"].firstMatch
            observedValue = button.value as? String
            observedLabel = button.label
            if observedValue?.hasPrefix(expectedSizeValue + " ") == true || observedLabel?.contains(expectedSizeValue) == true {
                return
            }
            waitBriefly(0.2)
        }
        XCTFail("\(context): expected the DEBUG simulated window-size hook to apply \(expectedSizeValue); button value is \(String(describing: observedValue)), label is \(String(describing: observedLabel))", file: file, line: line)
    }

    /// Asserts the root layout decision (DEBUG control value suffix) independently of the rendered window width.
    private func assertSimulatedLayoutMode(in app: XCUIApplication, expectedMode: String, context: String, file: StaticString = #filePath, line: UInt = #line) {
#if os(iOS)
        // iPad always uses split navigation; the compact/split decision under test is the phone-idiom path.
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
#endif
        let deadline = Date().addingTimeInterval(5)
        var observedValue: String?
        while Date() < deadline {
            observedValue = app.buttons["debug-simulated-window-size-change-button"].firstMatch.value as? String
            if observedValue?.hasSuffix(" " + expectedMode) == true {
                return
            }
            waitBriefly(0.2)
        }
        XCTFail("\(context): expected the root layout decision to be \(expectedMode); DEBUG control value is \(String(describing: observedValue))", file: file, line: line)
    }

    private func assertSimulatedLayoutChanged(in app: XCUIApplication, to expected: SimulatedToolPresentationExpectation, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            let panel = app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch
            guard panel.exists else {
                waitBriefly(0.2)
                continue
            }
            let hasSheet = activeToolPanelTop(in: app) != nil
            switch expected {
            case .inspector where !hasSheet:
                return
            case .sheet where hasSheet:
                return
            default:
                waitBriefly(0.2)
            }
        }

        let panel = app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch
        let panelDescription = panel.exists ? frameDescription(panel.frame) : "missing"
        switch expected {
        case .inspector:
            XCTFail("\(context): expected the simulated layout change to replace the bottom sheet with the inspector. Window: \(frameDescription(app.windows.firstMatch.frame)); panel: \(panelDescription)", file: file, line: line)
        case .sheet:
            XCTFail("\(context): expected the simulated layout change to replace the inspector with the bottom sheet. Window: \(frameDescription(app.windows.firstMatch.frame)); panel: \(panelDescription)", file: file, line: line)
        }
    }

#if os(iOS)
    private enum SidebarVisibilityExpectation {
        case collapsed
        case visible
    }

    private func runRegularWidthInspectorScenario(
        orientation: UIDeviceOrientation,
        expectedInitialSidebarVisibility: SidebarVisibilityExpectation,
        expectedOpenSidebarVisibility: SidebarVisibilityExpectation,
        extraArguments: [String] = [],
        context: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        XCUIDevice.shared.orientation = orientation
        waitBriefly(0.8)
        let app = launchPracticeQuestion(extraArguments: extraArguments + ["-CanadianHamForceRegularHorizontalSizeClass"])
        defer { app.terminate() }

        let initialSidebarVisible = isSidebarVisible(app.descendants(matching: .any)["root-sidebar"].firstMatch, in: app)
        assertSidebarVisibility(expectedInitialSidebarVisibility, in: app, context: "\(context) before opening calculator", file: file, line: line)
        openTool(.calculator, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["exam-tool-calculator-panel"].firstMatch.waitForExistence(timeout: 5), "\(context): regular width should present exam tools in an inspector side panel", file: file, line: line)
        waitBriefly(0.8)
        assertSidebarVisibility(expectedOpenSidebarVisibility, in: app, context: "\(context) with calculator open", file: file, line: line)
        assertQuestionTitleWithinExamColumn(in: app, context: context, file: file, line: line)
        assertVisibleAnswerButtonsRemainHittable(in: app, context: "\(context) calculator inspector", file: file, line: line)
        closeTool(in: app)
        waitBriefly(0.8)
        XCTAssertEqual(isSidebarVisible(app.descendants(matching: .any)["root-sidebar"].firstMatch, in: app), initialSidebarVisible, "\(context): closing the inspector should restore the sidebar visibility that existed before opening it", file: file, line: line)
    }

    private func runRegularWidthInspectorAuditScenario(orientation: UIDeviceOrientation, appearance: String, context: String, file: StaticString = #filePath, line: UInt = #line) throws {
        XCUIDevice.shared.orientation = orientation
        waitBriefly(0.8)
        let app = launchPracticeQuestion(appearance: appearance, extraArguments: ["-CanadianHamForceRegularHorizontalSizeClass"])
        defer { app.terminate() }

        openTool(.calculator, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["exam-tool-calculator-panel"].firstMatch.waitForExistence(timeout: 5), "\(context): regular width should present calculator in an inspector side panel", file: file, line: line)
        XCTAssertTrue(app.descendants(matching: .any)["calculator-keyboard-help"].firstMatch.waitForExistence(timeout: 5), "\(context): the inspector should show calculator keyboard help when it has room", file: file, line: line)
        waitBriefly(0.8)
        try auditIgnoringOccludedLessonTextContrast(app: app)
    }

    private func assertSidebarVisibility(_ expected: SidebarVisibilityExpectation, in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let sidebar = app.descendants(matching: .any)["root-sidebar"].firstMatch
        let visible = isSidebarVisible(sidebar, in: app)
        switch expected {
        case .collapsed:
            XCTAssertFalse(visible, "\(context): expected the sidebar collapsed so the exam column is not dimmed or covered. Sidebar frame: \(frameDescription(sidebar.frame))", file: file, line: line)
        case .visible:
            XCTAssertTrue(visible, "\(context): expected the sidebar visible. Sidebar frame: \(frameDescription(sidebar.frame))", file: file, line: line)
        }
    }

    private func assertQuestionTitleWithinExamColumn(in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let questionTitle = app.staticTexts["question-stem"].firstMatch
        XCTAssertTrue(questionTitle.waitForExistence(timeout: 5), "\(context): expected the question title", file: file, line: line)
        let inspectorHeader = app.descendants(matching: .any)["exam-tool-calculator-panel"].firstMatch
        XCTAssertTrue(inspectorHeader.waitForExistence(timeout: 5), "\(context): expected the calculator inspector header", file: file, line: line)

        let windowFrame = app.windows.firstMatch.frame
        let sidebar = app.descendants(matching: .any)["root-sidebar"].firstMatch
        let examColumnMinX = isSidebarVisible(sidebar, in: app) ? sidebar.frame.maxX : windowFrame.minX
        let examColumnMaxX = min(windowFrame.maxX, inspectorHeader.frame.minX)
        let examColumn = CGRect(x: examColumnMinX, y: windowFrame.minY, width: max(0, examColumnMaxX - examColumnMinX), height: windowFrame.height)
        XCTAssertGreaterThanOrEqual(examColumn.width, 420, "\(context): expected an exam column of at least about 420 pt beside the inspector. Exam column: \(frameDescription(examColumn)); window: \(frameDescription(windowFrame)); inspector header: \(frameDescription(inspectorHeader.frame))", file: file, line: line)
        XCTAssertTrue(examColumn.insetBy(dx: -1, dy: -1).contains(questionTitle.frame), "\(context): question title should be fully within the exam column, not truncated under the inspector. Title: \(frameDescription(questionTitle.frame)); exam column: \(frameDescription(examColumn))", file: file, line: line)
    }

    private func isSidebarVisible(_ sidebar: XCUIElement, in app: XCUIApplication) -> Bool {
        guard sidebar.exists else { return false }
        let windowFrame = app.windows.firstMatch.frame
        return sidebar.frame.width > 80 && sidebar.frame.height > 80 && sidebar.frame.intersects(windowFrame) && sidebar.frame.minX < windowFrame.midX
    }
#endif

    private func launchPracticeQuestion(appearance: String = "light", categoryID: String = "B-001", questionID: String = "B-001-002-002", extraArguments: [String] = []) -> XCUIApplication {
        launchApp(appearance: appearance, arguments: extraArguments + [
            "-CanadianHamInitialCategoryID", categoryID,
            "-CanadianHamPracticeQuestionID", questionID
        ])
    }

    private func launchTwoLevelHintPracticeQuestion(appearance: String = "light", extraArguments: [String] = []) -> XCUIApplication {
        launchPracticeQuestion(appearance: appearance, categoryID: "B-006", questionID: "B-006-008-004", extraArguments: extraArguments)
    }

    private func launchOneLevelHintPracticeQuestion(appearance: String = "light", extraArguments: [String] = []) -> XCUIApplication {
        launchPracticeQuestion(appearance: appearance, categoryID: "B-006", questionID: "B-006-003-008", extraArguments: extraArguments)
    }

    private func launchAuditPracticeQuestion(appearance: String = "light", extraArguments: [String] = []) -> XCUIApplication {
        launchPracticeQuestion(appearance: appearance, categoryID: "B-001", questionID: "B-001-002-002", extraArguments: extraArguments)
    }

    private func launchAdvancedPracticeQuestion() -> XCUIApplication {
        launchApp(arguments: [
            "-CanadianHamCourseBankId", "advanced-2025-02-04",
            "-CanadianHamInitialCategoryID", "A-001",
            "-CanadianHamPracticeQuestionID", "A-001-001-001"
        ])
    }

    private func launchApp(appearance: String = "light", arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-CanadianHamResetDataOnLaunch", "-CanadianHamAppearance", appearance] + arguments
        app.launch()
        return app
    }

    private func openTool(_ tool: Tool, in app: XCUIApplication) {
        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10), "Expected an exam question before opening tools")
        let button = app.buttons[tool.buttonIdentifier].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Expected tool button \(tool.buttonIdentifier)")
        scrollExamToolUntilHittable(button, in: app, maxSwipes: 8)
        XCTAssertTrue(button.isHittable, "Tool button \(tool.buttonIdentifier) should be hittable")
        button.tap()
    }

    private func closeTool(in app: XCUIApplication) {
        let close = app.buttons["exam-tool-close-button"].firstMatch
        XCTAssertTrue(close.waitForExistence(timeout: 5), "Expected a close tools button")
        close.tap()
    }

    private func tapNavigationBack(in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let navigationBar = app.navigationBars.firstMatch
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5), "\(context): expected a navigation bar before tapping Back", file: file, line: line)
        let labels = ["Back", "All questions", "Practice"]
        let preferredBack = navigationBar.buttons.matching(NSPredicate(format: "label IN %@", labels)).firstMatch
        if preferredBack.waitForExistence(timeout: 2) {
            preferredBack.tap()
            return
        }
        let anyBack = navigationBar.buttons.element(boundBy: 0)
        XCTAssertTrue(anyBack.waitForExistence(timeout: 5), "\(context): expected a navigation back button", file: file, line: line)
        anyBack.tap()
    }

    private func revealBothHints(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let first = app.buttons["hint-show-level-1-button"].firstMatch
        XCTAssertTrue(first.waitForExistence(timeout: 5), "Expected Hint 1 button", file: file, line: line)
        scrollExamToolUntilHittable(first, in: app, maxSwipes: 8, file: file, line: line)
        first.tap()
        let second = app.buttons["hint-show-level-2-button"].firstMatch
        XCTAssertTrue(second.waitForExistence(timeout: 5), "Expected Hint 2 button", file: file, line: line)
        scrollExamToolUntilHittable(second, in: app, maxSwipes: 8, file: file, line: line)
        second.tap()
        XCTAssertTrue(app.staticTexts["hint-level-2-title"].firstMatch.waitForExistence(timeout: 5), "Expected both hints to be visible", file: file, line: line)
    }

    private func assertCalculatorPresentedAsSheet(in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let windowFrame = app.windows.firstMatch.frame
        let header = app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 5), "\(context): expected the calculator panel header", file: file, line: line)
        XCTAssertNotNil(activeToolPanelTop(in: app), "\(context): expected a bottom sheet, not a trailing inspector", file: file, line: line)
        XCTAssertLessThan(header.frame.minX, windowFrame.midX, "\(context): iPhone regular-width landscape should keep tools in the bottom sheet rather than a trailing inspector. Header: \(frameDescription(header.frame)); window: \(frameDescription(windowFrame))", file: file, line: line)
    }

    private func performMediumDetentExamToolAudit(on app: XCUIApplication, context: String) throws {
        let mediumHeaderFrame = currentCalculatorHeaderFrame(in: app, context: "\(context) before medium-detent precheck")
        assertMediumDetentHeaderFrame(mediumHeaderFrame, in: app, context: "\(context) before medium-detent precheck")
        assertMediumDetentToolPanelVisibleElements(in: app, context: context)
        scrollCalculatorPanelToTop(in: app, context: context)
        assertMediumDetentHeaderFrame(mediumHeaderFrame, in: app, context: "\(context) immediately before medium-detent audit")
        assertCalculatorDisplayAndCloseHittable(in: app, context: "\(context) immediately before medium-detent audit")

        var ignoredTextClippedIssues = 0
        try app.performAccessibilityAudit { issue in
            if self.isApprovedMediumDetentToolScrollTextClip(issue, in: app) {
                ignoredTextClippedIssues += 1
                XCTContext.runActivity(named: "Ignored approved task-44.3 medium-detent textClipped issue") { _ in
                    NSLog("Ignoring approved task-44.3 medium-detent exam-tool textClipped audit issue [\(context)]: type=\(issue.auditType) element=\(String(describing: issue.element)) issue=\(issue)")
                }
                return ignoredTextClippedIssues <= 5
            }
            return false
        }
        XCTAssertLessThanOrEqual(ignoredTextClippedIssues, 5, "\(context): medium-detent audit ignored too many nil-element textClipped issues")
    }

    private func auditIgnoringOccludedLessonTextContrast(app: XCUIApplication) throws {
        let auditGeometry = lessonAuditGeometryBelowOpaqueNavigationBar(in: app)
        try app.performAccessibilityAudit { issue in
            guard issue.auditType == .contrast else { return false }
            guard let element = issue.element else { return false }
            let frame = element.frame
            guard frame.width > 0, frame.height > 0 else { return false }
            guard !self.frame(frame, matchesAny: auditGeometry.navigationBarElementFrames) else { return false }
            guard auditGeometry.scrollFrame.intersects(frame) else { return false }
            guard self.element(element, withFrame: frame, isDescendantOf: auditGeometry.scrollView) else { return false }
            guard !auditGeometry.visibleScrollArea.contains(frame) else { return false }

            XCTContext.runActivity(named: "Ignored occluded lesson scroll-content contrast false positive") { activity in
                let note = "label=\(element.label) frame=\(self.frameDescription(frame)) visibleScrollArea=\(self.frameDescription(auditGeometry.visibleScrollArea)) scrollFrame=\(self.frameDescription(auditGeometry.scrollFrame)) matchedScrollDescendant=true"
                let attachment = XCTAttachment(string: note)
                attachment.lifetime = .keepAlways
                activity.add(attachment)
            }
            return true
        }
    }

    private func isApprovedMediumDetentToolScrollTextClip(_ issue: XCUIAccessibilityAuditIssue, in app: XCUIApplication) -> Bool {
#if os(iOS)
        issue.auditType == .textClipped && issue.element == nil
#else
        false
#endif
    }

    private func assertMediumDetentToolPanelVisibleElements(in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let windowFrame = app.windows.firstMatch.frame
        let header = app.descendants(matching: .any)["exam-tool-calculator-panel"].firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 5), "\(context): expected a visible calculator panel header before auditing", file: file, line: line)
        XCTAssertTrue(windowFrame.contains(header.frame), "\(context): sheet visible frame should contain the panel header. Header: \(frameDescription(header.frame)); window: \(frameDescription(windowFrame))", file: file, line: line)

        assertCalculatorDisplayAndCloseHittable(in: app, context: "\(context) before medium-detent precheck", file: file, line: line)

        for identifier in calculatorKeyIdentifiers {
            let key = app.buttons[identifier].firstMatch
            scrollCalculatorPanelUntilElementExists(key, in: app, maxSwipes: 10, file: file, line: line)
            XCTAssertTrue(key.waitForExistence(timeout: 5), "\(context): expected \(identifier) before auditing", file: file, line: line)
            scrollExamToolUntilHittable(key, in: app, maxSwipes: 10, file: file, line: line)
            XCTAssertTrue(key.isHittable, "\(context): \(identifier) should be hittable before using the medium-detent text-clipped audit exception. Frame: \(frameDescription(key.frame))", file: file, line: line)
            XCTAssertGreaterThanOrEqual(key.frame.height, 44, "\(context): \(identifier) must preserve the 44 pt hit target before using the medium-detent text-clipped audit exception. Frame: \(frameDescription(key.frame))", file: file, line: line)
        }
    }

    private func assertCalculatorDisplayAndCloseHittable(in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let display = app.descendants(matching: .any)["calculator-result"].firstMatch
        XCTAssertTrue(display.waitForExistence(timeout: 5), "\(context): expected the calculator display", file: file, line: line)
        XCTAssertTrue(display.isHittable, "\(context): calculator display should be hittable before using the medium-detent text-clipped audit exception. Frame: \(frameDescription(display.frame))", file: file, line: line)

        let close = app.buttons["exam-tool-close-button"].firstMatch
        XCTAssertTrue(close.waitForExistence(timeout: 5), "\(context): expected Close tool", file: file, line: line)
        XCTAssertTrue(close.isHittable, "\(context): Close tool should be hittable before using the medium-detent text-clipped audit exception. Frame: \(frameDescription(close.frame))", file: file, line: line)
    }

    private func currentCalculatorHeaderFrame(in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) -> CGRect {
        let header = app.descendants(matching: .any)["exam-tool-calculator-panel"].firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 5), "\(context): expected a calculator panel header", file: file, line: line)
        return header.frame
    }

    private func assertMediumDetentHeaderFrame(_ expectedFrame: CGRect, in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let windowFrame = app.windows.firstMatch.frame
        let currentFrame = currentCalculatorHeaderFrame(in: app, context: context, file: file, line: line)
        XCTAssertTrue(windowFrame.contains(currentFrame), "\(context): medium sheet header should stay in the window. Header: \(frameDescription(currentFrame)); window: \(frameDescription(windowFrame))", file: file, line: line)
        XCTAssertGreaterThan(currentFrame.minY, windowFrame.height * 0.25, "\(context): sheet appears to have left the medium detent. Header: \(frameDescription(currentFrame)); window: \(frameDescription(windowFrame))", file: file, line: line)
        XCTAssertLessThan(abs(currentFrame.minY - expectedFrame.minY), 6, "\(context): sheet header moved after the medium-detent precheck, so the medium-detent audit exception would be applied outside the approved detent. Expected: \(frameDescription(expectedFrame)); current: \(frameDescription(currentFrame))", file: file, line: line)
        XCTAssertLessThan(abs(currentFrame.height - expectedFrame.height), 2, "\(context): sheet header height changed before audit. Expected: \(frameDescription(expectedFrame)); current: \(frameDescription(currentFrame))", file: file, line: line)
    }

    private func scrollCalculatorPanelToTop(in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let display = app.descendants(matching: .any)["calculator-result"].firstMatch
        XCTAssertTrue(display.waitForExistence(timeout: 5), "\(context): expected calculator display before restoring scroll position", file: file, line: line)
        guard !display.isHittable else { return }
        let scrollView = calculatorScrollView(in: app, requiredFor: "restoring calculator medium-detent audit scroll position", file: file, line: line)
        for _ in 0..<10 where !display.isHittable {
            scrollView.swipeDown()
            waitBriefly()
        }
        XCTAssertTrue(display.isHittable, "\(context): calculator display should be hittable after restoring the calculator scroll view to the top. Frame: \(frameDescription(display.frame))", file: file, line: line)
    }

    private var calculatorKeyIdentifiers: [String] {
        [
            "calculator-key-all-clear", "calculator-key-clear-entry", "calculator-key-backspace", "calculator-key-divide",
            "calculator-key-7", "calculator-key-8", "calculator-key-9", "calculator-key-multiply",
            "calculator-key-4", "calculator-key-5", "calculator-key-6", "calculator-key-subtract",
            "calculator-key-1", "calculator-key-2", "calculator-key-3", "calculator-key-add",
            "calculator-key-toggle-sign", "calculator-key-0", "calculator-key-decimal", "calculator-key-equals",
            "calculator-key-percent", "calculator-key-square-root", "calculator-key-square", "calculator-key-reciprocal"
        ]
    }

    private func waitForStableToolHeaderFrame(_ tool: Tool, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let header = app.descendants(matching: .any)[tool.panelIdentifier].firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 5), "Expected tool header \(tool.panelIdentifier)", file: file, line: line)

        let deadline = Date().addingTimeInterval(5)
        var previousFrame = header.frame
        var consecutiveStableSamples = 0
        while Date() < deadline, consecutiveStableSamples < 3 {
            waitBriefly(0.1)
            let currentFrame = header.frame
            if currentFrame == previousFrame {
                consecutiveStableSamples += 1
            } else {
                consecutiveStableSamples = 0
                previousFrame = currentFrame
            }
        }
        XCTAssertEqual(consecutiveStableSamples, 3, "Expected tool header \(tool.panelIdentifier) frame to settle before auditing. Last frame: \(frameDescription(previousFrame))", file: file, line: line)
    }

    private func expandCompactSheetToLarge(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let header = app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 5), "Expected calculator header before expanding the sheet", file: file, line: line)
        let windowFrame = app.windows.firstMatch.frame
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).withOffset(CGVector(dx: header.frame.midX, dy: header.frame.midY))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).withOffset(CGVector(dx: header.frame.midX, dy: windowFrame.minY + 96))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: XCUIGestureVelocity.slow, thenHoldForDuration: 0.2)
        waitForStableToolHeaderFrame(.calculator, in: app, file: file, line: line)
    }

    private func tapStartMockExam(in app: XCUIApplication) {
        let start = app.buttons["start-mock-exam-button"].firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 10), "Expected mock exam start button")
        scrollExamToolUntilHittable(start, in: app, maxSwipes: 8)
        start.tap()
        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10), "Expected mock exam answer choices")
    }

    private func assertVisibleAnswerButtonsRemainHittable(in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let answerIdentifiers = ["answer-A-button", "answer-B-button", "answer-C-button", "answer-D-button"]
        for identifier in answerIdentifiers {
            let answer = app.descendants(matching: .any)[identifier].firstMatch
            XCTAssertTrue(answer.waitForExistence(timeout: 5), "\(context): expected \(identifier)", file: file, line: line)
            scrollBackgroundUntilHittable(answer, in: app, maxSwipes: 12)
            XCTAssertTrue(answer.isHittable, "\(context): \(identifier) should remain hittable with the non-modal tool open. Frame: \(frameDescription(answer.frame))", file: file, line: line)
        }
    }

    private func scrollExamToolUntilHittable(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int, file: StaticString = #filePath, line: UInt = #line) {
        for _ in 0..<maxSwipes where !isFullyVisible(element, in: app, requiresHittable: true) {
            let scrollView = element.identifier.hasPrefix("calculator-key-")
                ? calculatorScrollView(in: app, requiredFor: "scrolling calculator key \(element.identifier)", file: file, line: line)
                : scrollView(containing: element, in: app)
            if element.exists && element.frame.maxY <= visibleFrameExcludingNavigationBar(in: app).minY {
                scrollView.swipeDown()
            } else {
                scrollView.swipeUp()
            }
            waitBriefly()
        }
    }

    private func scrollBackgroundUntilHittable(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {
        let scrollView = scrollView(containing: element, in: app)
        for _ in 0..<maxSwipes where !element.isHittable {
            if element.exists && element.frame.maxY <= visibleFrameExcludingNavigationBar(in: app).minY {
                preciseExamToolScroll(scrollView, in: app, fingerDeltaY: 72)
            } else {
                preciseExamToolScroll(scrollView, in: app, fingerDeltaY: -72)
            }
            waitBriefly()
        }
    }

    private func scrollBackgroundPastElement(_ element: XCUIElement, preserving preservedElement: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {
        let scrollView = scrollView(containing: preservedElement, in: app)
        for _ in 0..<maxSwipes where element.exists && visibleFrameExcludingNavigationBar(in: app).intersects(element.frame) {
            preciseExamToolScroll(scrollView, in: app, fingerDeltaY: -72)
            waitBriefly()
            if preservedElement.exists && preservedElement.frame.maxY <= visibleFrameExcludingNavigationBar(in: app).minY {
                preciseExamToolScroll(scrollView, in: app, fingerDeltaY: 72)
                waitBriefly()
                break
            }
        }
    }

    private func scrollCalculatorPanelUntilElementExists(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int, file: StaticString = #filePath, line: UInt = #line) {
        for _ in 0..<maxSwipes where !element.exists {
            let scrollView = calculatorScrollView(in: app, requiredFor: "revealing calculator element \(element.identifier)", file: file, line: line)
            scrollView.swipeUp()
            waitBriefly()
        }
    }

    /// The calculator's ScrollView is the root of `CalculatorToolView`, so XCTest exposes it with the
    /// outer `calculator-keyboard-focus-target` identifier rather than the inner `calculator-tool-scroll`.
    /// Accept only a scroll view carrying one of those two calculator identifiers that also contains the
    /// calculator result display; never fall back to the background question scroll view.
    private func calculatorScrollView(in app: XCUIApplication, requiredFor context: String, timeout: TimeInterval = 1, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let calculatorIdentifiers = NSPredicate(format: "identifier IN %@", ["calculator-tool-scroll", "calculator-keyboard-focus-target"])
        let scrollView = app.scrollViews
            .matching(calculatorIdentifiers)
            .containing(.any, identifier: "calculator-result")
            .firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: timeout), "Expected the calculator scroll view (containing calculator-result) for \(context); refusing to fall back to the background scroll view", file: file, line: line)
        return scrollView
    }

    private func focusCalculatorKeyboard(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let result = app.descendants(matching: .any)["calculator-result"].firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 5), "Expected a calculator result display before focusing keyboard input", file: file, line: line)
        let focusedTarget = app.descendants(matching: .any)["calculator-keyboard-focus-target"].firstMatch
        XCTAssertTrue(focusedTarget.waitForExistence(timeout: 5), "Expected the calculator keyboard handler after opening the calculator", file: file, line: line)
        return focusedTarget
    }

    private func tapCalculatorKey(_ identifier: String, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let key = app.buttons[identifier].firstMatch
        XCTAssertTrue(key.waitForExistence(timeout: 5), "Expected calculator key \(identifier)", file: file, line: line)
        scrollExamToolUntilHittable(key, in: app, maxSwipes: 8)
        XCTAssertTrue(key.isHittable, "Expected calculator key \(identifier) to be hittable", file: file, line: line)
        key.tap()
    }

    private func typeCalculatorKeys(_ keys: [String], on calculator: XCUIElement) {
        for key in keys {
            calculator.typeKey(key, modifierFlags: [])
            waitBriefly()
        }
    }

    private func positionElementFullyVisibleAboveToolSheet(_ element: XCUIElement, in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let scrollView = scrollView(containing: element, in: app)
        XCTAssertTrue(scrollView.waitForExistence(timeout: 1), "\(context): expected a scroll view", file: file, line: line)
        var trace: [String] = ["start: target=\(frameDescription(element.frame)) visible=\(frameDescription(visibleFrameAboveToolSheet(in: app)))"]
        for step in 1...16 where !isFullyVisibleAboveToolSheet(element, in: app) {
            if element.exists && element.frame.maxY <= visibleFrameAboveToolSheet(in: app).minY {
                preciseExamToolScroll(scrollView, in: app, fingerDeltaY: 72)
            } else {
                preciseExamToolScroll(scrollView, in: app, fingerDeltaY: -72)
            }
            waitBriefly()
            trace.append("step \(step): target=\(frameDescription(element.frame)) visible=\(frameDescription(visibleFrameAboveToolSheet(in: app)))")
        }
        XCTAssertTrue(isFullyVisibleAboveToolSheet(element, in: app), "\(context): expected the element fully visible above the tool sheet. Frame: \(frameDescription(element.frame)); trace: \(trace.joined(separator: " -> "))", file: file, line: line)
    }

    private func preciseExamToolScroll(_ scrollView: XCUIElement, in app: XCUIApplication, fingerDeltaY: CGFloat) {
        let limitedDelta = fingerDeltaY > 0 ? min(80, max(8, fingerDeltaY)) : -min(80, max(8, abs(fingerDeltaY)))
        let visibleFrame = visibleFrameExcludingNavigationBar(in: app)
        let protectedBottom = activeToolPanelTop(in: app).map { $0 - 80 } ?? (visibleFrame.maxY - 24)
        let usableMinY = visibleFrame.minY + 24
        let usableMaxY = max(usableMinY, min(visibleFrame.maxY - 24, protectedBottom))
        let startY = min(max(visibleFrame.midY, usableMinY), usableMaxY)
        let startX = min(max(scrollView.frame.midX, visibleFrame.minX + 24), visibleFrame.maxX - 24)
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).withOffset(CGVector(dx: startX, dy: startY))
        let end = start.withOffset(CGVector(dx: 0, dy: limitedDelta))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: XCUIGestureVelocity.slow, thenHoldForDuration: 0.4)
    }

    private func activeToolPanelTop(in app: XCUIApplication) -> CGFloat? {
        let windowFrame = app.windows.firstMatch.frame
        for identifier in ["exam-tool-calculator-panel"] {
            let panel = app.descendants(matching: .any)[identifier].firstMatch
            if panel.exists, panel.frame.minX > windowFrame.midX, panel.frame.width < windowFrame.width * 0.7 {
                return nil
            }
        }
        let close = app.buttons["exam-tool-close-button"].firstMatch
        if close.exists, close.frame.minY > 0 {
            return max(0, close.frame.minY - 24)
        }
        for identifier in ["exam-tool-calculator-panel"] {
            let panel = app.descendants(matching: .any)[identifier].firstMatch
            if panel.exists, panel.frame.minY > 0 {
                return max(0, panel.frame.minY - 32)
            }
        }
        return nil
    }

    private func scrollView(containing element: XCUIElement, in app: XCUIApplication) -> XCUIElement {
        let scrollViews = app.scrollViews.allElementsBoundByIndex
        let backgroundScrollViews = scrollViews.filter { scrollView in
            !["calculator-keyboard-focus-target", "calculator-tool-scroll"].contains(scrollView.identifier)
        }
        if !element.identifier.isEmpty {
            for scrollView in backgroundScrollViews where scrollView.descendants(matching: .any)[element.identifier].firstMatch.exists {
                return scrollView
            }
        }
        return backgroundScrollViews.first ?? app.scrollViews.firstMatch
    }

    private func isFullyVisible(_ element: XCUIElement, in app: XCUIApplication, requiresHittable: Bool) -> Bool {
        guard element.exists else { return false }
        if requiresHittable && !element.isHittable { return false }
        return visibleFrameExcludingNavigationBar(in: app).contains(element.frame)
    }

    private func isFullyVisibleAboveToolSheet(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        guard element.exists else { return false }
        return visibleFrameAboveToolSheet(in: app).contains(element.frame)
    }

    private func visibleFrameAboveToolSheet(in app: XCUIApplication) -> CGRect {
        let visibleFrame = visibleFrameExcludingNavigationBar(in: app)
        let sheetTop = activeToolPanelTop(in: app).map { $0 - 8 } ?? visibleFrame.maxY
        let maxY = min(visibleFrame.maxY, sheetTop)
        return CGRect(x: visibleFrame.minX, y: visibleFrame.minY + 8, width: visibleFrame.width, height: max(0, maxY - visibleFrame.minY - 8))
    }

    private struct LessonAuditGeometry {
        let scrollFrame: CGRect
        let visibleScrollArea: CGRect
        let navigationBarElementFrames: [CGRect]
        let scrollView: XCUIElement?
    }

    private func lessonAuditGeometryBelowOpaqueNavigationBar(in app: XCUIApplication) -> LessonAuditGeometry {
        let windowFrame = app.windows.firstMatch.frame
        let protectedMaxY = protectedNavigationFrame(in: app).maxY
        let visibleScrollView = app.scrollViews.allElementsBoundByIndex.first { scrollView in
            scrollView.exists && scrollView.frame.width > 0 && scrollView.frame.height > 0 && scrollView.frame.intersects(windowFrame)
        }
        let scrollFrame = (visibleScrollView?.frame ?? windowFrame).intersection(windowFrame)
        let minY = max(scrollFrame.minY, protectedMaxY)
        let visibleScrollArea = CGRect(
            x: scrollFrame.minX,
            y: minY,
            width: max(0, scrollFrame.width),
            height: max(0, scrollFrame.maxY - minY)
        )
        return LessonAuditGeometry(
            scrollFrame: scrollFrame,
            visibleScrollArea: visibleScrollArea,
            navigationBarElementFrames: navigationBarElementFrames(in: app),
            scrollView: visibleScrollView
        )
    }

    private func navigationBarElementFrames(in app: XCUIApplication) -> [CGRect] {
        let navigationBar = app.navigationBars.firstMatch
        guard navigationBar.exists else { return [] }
        return ([navigationBar] + navigationBar.descendants(matching: .any).allElementsBoundByIndex)
            .compactMap { element in
                guard element.exists else { return nil }
                let frame = element.frame
                guard frame.width > 0, frame.height > 0 else { return nil }
                return frame
            }
    }

    private func element(_ element: XCUIElement, withFrame frame: CGRect, isDescendantOf scrollView: XCUIElement?) -> Bool {
        guard let scrollView, scrollView.exists else { return false }
        let query: XCUIElementQuery
        switch element.elementType {
        case .staticText:
            query = scrollView.staticTexts
        case .button:
            query = scrollView.buttons
        default:
            query = scrollView.descendants(matching: element.elementType)
        }
        let candidates: [XCUIElement]
        if !element.identifier.isEmpty {
            candidates = query.matching(identifier: element.identifier).allElementsBoundByIndex
        } else if !element.label.isEmpty {
            candidates = query.matching(NSPredicate(format: "label == %@", element.label)).allElementsBoundByIndex
        } else {
            candidates = query.allElementsBoundByIndex
        }
        return candidates.contains { candidate in
            guard candidate.exists else { return false }
            return self.frame(frame, matches: candidate.frame)
        }
    }

    private func frame(_ frame: CGRect, matchesAny candidates: [CGRect]) -> Bool {
        candidates.contains { candidate in
            self.frame(frame, matches: candidate)
        }
    }

    private func frame(_ frame: CGRect, matches candidate: CGRect) -> Bool {
        abs(frame.minX - candidate.minX) <= 1
            && abs(frame.minY - candidate.minY) <= 1
            && abs(frame.width - candidate.width) <= 1
            && abs(frame.height - candidate.height) <= 1
    }

    private func visibleFrameExcludingNavigationBar(in app: XCUIApplication) -> CGRect {
        let windowFrame = app.windows.firstMatch.frame
        let protectedFrame = protectedNavigationFrame(in: app)
        let protectedMaxY = protectedFrame.maxY
        return CGRect(x: windowFrame.minX + 16, y: protectedMaxY + 1, width: max(0, windowFrame.width - 32), height: max(0, windowFrame.maxY - protectedMaxY - 17))
    }

    private func protectedNavigationFrame(in app: XCUIApplication) -> CGRect {
        let windowFrame = app.windows.firstMatch.frame
        let navBar = app.navigationBars.firstMatch
        let statusBar = app.statusBars.firstMatch
        let protectedMaxY = max(navBar.exists ? navBar.frame.maxY : windowFrame.minY, statusBar.exists ? statusBar.frame.maxY : windowFrame.minY)
        return CGRect(x: windowFrame.minX, y: windowFrame.minY, width: windowFrame.width, height: max(0, protectedMaxY - windowFrame.minY))
    }

    private func saveScreenshot(named fileName: String, file: StaticString = #filePath, line: UInt = #line) throws {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = fileName
        attachment.lifetime = .keepAlways
        add(attachment)

        let directory = try XCTUnwrap(evidenceDirectory(), "Set CANADIAN_HAM_EXAM_TOOLS_EVIDENCE_DIR before saving calculator evidence screenshots.", file: file, line: line)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(fileName)
        try screenshot.pngRepresentation.write(to: url, options: .atomic)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "Expected screenshot at \(url.path)", file: file, line: line)
    }

    private func evidenceDirectory() -> URL? {
        ProcessInfo.processInfo.environment["CANADIAN_HAM_EXAM_TOOLS_EVIDENCE_DIR"]
            .flatMap { $0.isEmpty ? nil : URL(fileURLWithPath: $0, isDirectory: true) }
    }

    private func frameDescription(_ frame: CGRect) -> String {
        "x: \(frame.origin.x), y: \(frame.origin.y), width: \(frame.size.width), height: \(frame.size.height)"
    }

    private func waitBriefly(_ seconds: TimeInterval = 0.2) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }
}
