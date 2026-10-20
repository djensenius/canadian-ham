import XCTest

@MainActor
final class CanadianHamLessonFiguresUITests: XCTestCase {
    private enum TestAppearance: String {
        case light
        case dark

        var deviceAppearance: XCUIDevice.Appearance {
            switch self {
            case .light: return .light
            case .dark: return .dark
            }
        }

        var launchArguments: [String] {
            switch self {
            case .light: return ["-AppleInterfaceStyle", "Light"]
            case .dark: return ["-AppleInterfaceStyle", "Dark"]
            }
        }
    }

    private struct LessonSpec {
        let moduleID: String
        let lessonID: String
        let figures: [FigureSpec]

        var sampledFirstFigure: Self {
            Self(moduleID: moduleID, lessonID: lessonID, figures: Array(figures.prefix(1)))
        }
    }

    private struct FigureSpec {
        let id: String
        let altText: String
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        XCUIApplication().terminate()
        XCUIDevice.shared.appearance = .light
        try super.tearDownWithError()
    }

    func testModule1LessonFiguresLightPart1() throws {
        try verifyLessonRange(Self.module1Lessons, 0..<2, appearance: .light, evidenceModuleID: "m1", writeEvidence: true)
    }

    func testModule1LessonFiguresLightPart2() throws {
        try verifyLessonRange(Self.module1Lessons, 2..<3, appearance: .light, evidenceModuleID: "m1", writeEvidence: true)
    }

    func testModule1LessonFiguresLightPart3() throws {
        try verifyLessonRange(Self.module1Lessons, 3..<4, appearance: .light, evidenceModuleID: "m1")
    }

    func testModule1LessonFiguresLightPart4() throws {
        try verifyLessonRange(Self.module1Lessons, 4..<6, appearance: .light, evidenceModuleID: "m1")
    }

    func testModule2LessonFiguresLightPart1() throws {
        try verifyLessonRange(Self.module2Lessons, 0..<2, appearance: .light, evidenceModuleID: "m2", writeEvidence: true)
    }

    func testModule2LessonFiguresLightPart2() throws {
        try verifyLessonRange(Self.module2Lessons, 2..<4, appearance: .light, evidenceModuleID: "m2")
    }

    func testModule3LessonFiguresLightPart1() throws {
        try verifyLessonRange(Self.module3Lessons, 0..<2, appearance: .light, evidenceModuleID: "m3", writeEvidence: true)
    }

    func testModule3LessonFiguresLightPart2() throws {
        try verifyLessonRange(Self.module3Lessons, 2..<4, appearance: .light, evidenceModuleID: "m3")
    }

    func testModule3LessonFiguresLightPart3() throws {
        try verifyLessonRange(Self.module3Lessons, 4..<6, appearance: .light, evidenceModuleID: "m3")
    }

    func testModule3LessonFiguresLightPart4() throws {
        try verifyLessonRange(Self.module3Lessons, 6..<8, appearance: .light, evidenceModuleID: "m3")
    }

    func testModule4LessonFiguresLightPart1() throws {
        try verifyLessonRange(Self.module4Lessons, 0..<2, appearance: .light, evidenceModuleID: "m4", writeEvidence: true)
    }

    func testModule4LessonFiguresLightPart2() throws {
        try verifyLessonRange(Self.module4Lessons, 2..<3, appearance: .light, evidenceModuleID: "m4")
    }

    func testModule5LessonFiguresLightPart1() throws {
        try verifyLessonRange(Self.module5Lessons, 0..<1, appearance: .light, evidenceModuleID: "m5", writeEvidence: true)
    }

    func testModule5LessonFiguresLightPart2() throws {
        try verifyLessonRange(Self.module5Lessons, 1..<2, appearance: .light, evidenceModuleID: "m5")
    }

    func testModule5LessonFiguresLightPart3() throws {
        try verifyLessonRange(Self.module5Lessons, 2..<4, appearance: .light, evidenceModuleID: "m5")
    }

    func testModule5LessonFiguresLightPart4() throws {
        try verifyLessonRange(Self.module5Lessons, 4..<5, appearance: .light, evidenceModuleID: "m5", writeEvidence: true)
    }

    func testModule5LessonFiguresLightPart5() throws {
        try verifyLessonRange(Self.module5Lessons, 5..<6, appearance: .light, evidenceModuleID: "m5", writeEvidence: true)
    }

    func testModule6LessonFiguresLightPart1() throws {
        try verifyLessonRange(Self.module6Lessons, 0..<2, appearance: .light, evidenceModuleID: "m6", writeEvidence: true)
    }

    func testModule6LessonFiguresLightPart2() throws {
        try verifyLessonRange(Self.module6Lessons, 2..<4, appearance: .light, evidenceModuleID: "m6")
    }

    func testModule6LessonFiguresLightPart3() throws {
        try verifyLessonRange(Self.module6Lessons, 4..<5, appearance: .light, evidenceModuleID: "m6")
    }

    func testModule7LessonFiguresLightPart1() throws {
        try verifyLessonRange(Self.module7Lessons, 0..<2, appearance: .light, evidenceModuleID: "m7", writeEvidence: true)
    }

    func testModule7LessonFiguresLightPart2() throws {
        try verifyLessonRange(Self.module7Lessons, 2..<3, appearance: .light, evidenceModuleID: "m7")
    }

    func testModule8LessonFiguresLightPart1() throws {
        try verifyLessonRange(Self.module8Lessons, 0..<1, appearance: .light, evidenceModuleID: "m8", writeEvidence: true)
    }

    func testModule8LessonFiguresLightPart2() throws {
        try verifyLessonRange(Self.module8Lessons, 1..<2, appearance: .light, evidenceModuleID: "m8")
    }

    func testModule1LessonFigureDarkSample() throws {
        try verifyLessons([Self.module1Lessons[0].sampledFirstFigure], appearance: .dark, evidenceModuleID: "m1")
    }

    func testModule2LessonFigureDarkSample() throws {
        try verifyLessons([Self.module2Lessons[0].sampledFirstFigure], appearance: .dark, evidenceModuleID: "m2")
    }

    func testModule3LessonFigureDarkSample() throws {
        try verifyLessons([Self.module3Lessons[0].sampledFirstFigure], appearance: .dark, evidenceModuleID: "m3")
    }

    func testModule4LessonFigureDarkSample() throws {
        try verifyLessons([Self.module4Lessons[0].sampledFirstFigure], appearance: .dark, evidenceModuleID: "m4")
    }

    func testModule5LessonFigureDarkSample() throws {
        try verifyLessons([Self.module5Lessons[0].sampledFirstFigure], appearance: .dark, evidenceModuleID: "m5")
    }

    func testModule6LessonFigureDarkSample() throws {
        try verifyLessons([Self.module6Lessons[0].sampledFirstFigure], appearance: .dark, evidenceModuleID: "m6")
    }

    func testModule7LessonFigureDarkSample() throws {
        try verifyLessons([Self.module7Lessons[0].sampledFirstFigure], appearance: .dark, evidenceModuleID: "m7")
    }

    func testModule8LessonFigureDarkSample() throws {
        try verifyLessons([Self.module8Lessons[0].sampledFirstFigure], appearance: .dark, evidenceModuleID: "m8")
    }

    private func verifyLessonRange(
        _ lessons: [LessonSpec],
        _ range: Range<Int>,
        appearance: TestAppearance,
        evidenceModuleID: String,
        writeEvidence: Bool = false
    ) throws {
        try verifyLessons(Array(lessons[range]), appearance: appearance, evidenceModuleID: evidenceModuleID, writeEvidence: writeEvidence)
    }

    private func verifyLessons(_ lessons: [LessonSpec], appearance: TestAppearance, evidenceModuleID: String, writeEvidence: Bool = true) throws {
        var wroteEvidenceForModule = false
        for lesson in lessons {
            let app = launchLesson(lesson.lessonID, appearance: appearance)
            XCTAssertTrue(app.descendants(matching: .any)["lesson-reader-title"].firstMatch.waitForExistence(timeout: 10), "Expected lesson reader for \(lesson.lessonID)")

            for figure in lesson.figures {
                let figureElement = app.descendants(matching: .any)["lesson-figure-\(figure.id)"].firstMatch
                scrollUntilPartiallyVisible(figureElement, in: app, maxSwipes: 80)
                XCTAssertTrue(figureElement.waitForExistence(timeout: 5), "Expected \(figure.id) in \(lesson.lessonID)")
                positionLessonFigureForOpaqueNavigationBarAudit(figureElement, in: app, context: "\(appearance.rawValue) \(lesson.lessonID) \(figure.id)")
                XCTAssertTrue(
                    figureElement.label.localizedCaseInsensitiveContains(figure.altText),
                    "Expected accessibility label for \(figure.id) to contain its alt text. Got: \(figureElement.label)"
                )
                if writeEvidence && !wroteEvidenceForModule {
                    writeEvidenceScreenshot(named: "\(appearance.rawValue)-\(evidenceModuleID)-\(figure.id)", from: app)
                    wroteEvidenceForModule = true
                }
                try auditIgnoringOccludedLessonTextContrast(app: app)
            }
            app.terminate()
        }
    }

    private func launchLesson(_ lessonID: String, appearance: TestAppearance) -> XCUIApplication {
        XCUIDevice.shared.appearance = appearance.deviceAppearance
        let app = XCUIApplication()
        app.launchArguments = ["-CanadianHamResetDataOnLaunch", "-CanadianHamInitialLessonID", lessonID] + appearance.launchArguments
        app.launch()
        return app
    }

    private func writeEvidenceScreenshot(named name: String, from app: XCUIApplication) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "task-38-figures-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)

        guard let outputDirectory = ProcessInfo.processInfo.environment["CANADIAN_HAM_FIGURE_EVIDENCE_DIR"].flatMap({ $0.isEmpty ? nil : $0 }) else {
            return
        }
        do {
            let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            try screenshot.pngRepresentation.write(to: directoryURL.appendingPathComponent("\(name).png"), options: .atomic)
        } catch {
            XCTFail("Failed to write figure evidence screenshot \(name): \(error)")
        }
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

    private func scrollUntilPartiallyVisible(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {
        let scrollView = scrollView(containing: element, in: app)
        guard scrollView.waitForExistence(timeout: 1) else {
            XCTFail("Expected a scroll view while scrolling element into view. Identifier: \(element.identifier); label: \(element.label)")
            return
        }
        for _ in 0..<maxSwipes where !isPartiallyVisibleBelowNavigationBar(element, in: app) {
            let visibleFrame = visibleFrameExcludingNavigationBar(in: app)
            if element.exists, element.frame.maxY <= visibleFrame.minY {
                scrollView.swipeDown()
            } else {
                scrollView.swipeUp()
            }
            waitBriefly()
        }
    }

    private func positionLessonFigureForOpaqueNavigationBarAudit(
        _ element: XCUIElement,
        in app: XCUIApplication,
        context: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let scrollView = scrollView(containing: element, in: app)
        guard scrollView.waitForExistence(timeout: 1) else {
            XCTFail("\(context): expected a scroll view before positioning lesson figure", file: file, line: line)
            return
        }
        var trace: [String] = []
        func record(_ label: String) {
            trace.append("\(label): target=\(frameDescription(element.frame))")
        }
        record("start")
        for attempt in 0..<20 where !isLessonFigureFullyVisibleForAudit(element, in: app) {
            let figureFrame = element.frame
            let visibleFrame = visibleFrameExcludingNavigationBar(in: app)
            if figureFrame.minY < visibleFrame.minY + 8 {
                preciseScroll(scrollView, contentDeltaY: min(80, visibleFrame.minY + 8 - figureFrame.minY))
                record("figure below opaque bar \(attempt + 1)")
            } else if figureFrame.height <= visibleFrame.height, figureFrame.maxY > visibleFrame.maxY {
                preciseScroll(scrollView, contentDeltaY: -min(80, figureFrame.maxY - visibleFrame.maxY + 8))
                record("figure above bottom edge \(attempt + 1)")
            } else if figureFrame.height > visibleFrame.height, figureFrame.minY > visibleFrame.minY + 8 {
                preciseScroll(scrollView, contentDeltaY: -min(80, figureFrame.minY - visibleFrame.minY - 8))
                record("oversized figure top into view \(attempt + 1)")
            } else {
                preciseScroll(scrollView, contentDeltaY: -12)
                record("settle \(attempt + 1)")
            }
            waitBriefly()
        }

        let figureReady = isLessonFigureFullyVisibleForAudit(element, in: app)
        if !figureReady {
            writeEvidenceScreenshot(named: "positioning-failure-\(sanitizedEvidenceName(context))", from: app)
        }
        XCTAssertTrue(
            figureReady,
            "\(context): expected the lesson figure to be fully visible below the opaque navigation/status bar, or top-visible if oversized. Frame: \(frameDescription(element.frame)); trace: \(trace.joined(separator: " -> "))",
            file: file,
            line: line
        )
    }

    private func preciseScroll(_ scrollView: XCUIElement, contentDeltaY: CGFloat) {
        let limitedMagnitude = min(80, max(8, abs(contentDeltaY)))
        let fingerDeltaY = contentDeltaY > 0 ? limitedMagnitude : -limitedMagnitude
        let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = start.withOffset(CGVector(dx: 0, dy: fingerDeltaY))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: XCUIGestureVelocity.slow, thenHoldForDuration: 0.4)
    }

    private func scrollView(containing element: XCUIElement?, in app: XCUIApplication) -> XCUIElement {
        guard let element, element.exists else { return app.scrollViews.firstMatch }
        let scrollViews = app.scrollViews.allElementsBoundByIndex
        if !element.identifier.isEmpty {
            for scrollView in scrollViews where scrollView.descendants(matching: .any)[element.identifier].firstMatch.exists && scrollView.frame.intersects(element.frame) {
                return scrollView
            }
            for scrollView in scrollViews where scrollView.descendants(matching: .any)[element.identifier].firstMatch.exists {
                return scrollView
            }
        }
        if !element.label.isEmpty {
            let sameLabel = NSPredicate(format: "label == %@", element.label)
            for scrollView in scrollViews where scrollView.frame.intersects(element.frame) {
                if scrollView.staticTexts.matching(sameLabel).firstMatch.exists || scrollView.buttons.matching(sameLabel).firstMatch.exists {
                    return scrollView
                }
            }
            for scrollView in scrollViews {
                if scrollView.staticTexts.matching(sameLabel).firstMatch.exists || scrollView.buttons.matching(sameLabel).firstMatch.exists {
                    return scrollView
                }
            }
        }
        for scrollView in scrollViews where scrollView.frame.intersects(element.frame) {
            return scrollView
        }
        return app.scrollViews.firstMatch
    }

    private func isPartiallyVisibleBelowNavigationBar(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        guard element.exists else { return false }
        return element.frame.intersects(visibleFrameExcludingNavigationBar(in: app))
    }

    private func isLessonFigureFullyVisibleForAudit(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        guard element.exists else { return false }
        let frame = element.frame
        let windowFrame = app.windows.firstMatch.frame
        let protectedMaxY = protectedNavigationFrame(in: app).maxY
        let topMargin = protectedMaxY + 8
        let bottomMargin = windowFrame.maxY - 8
        let availableHeight = max(0, bottomMargin - topMargin)
        let horizontallyVisible = frame.minX >= windowFrame.minX && frame.maxX <= windowFrame.maxX
        if frame.height > availableHeight {
            return horizontallyVisible && frame.minY >= topMargin && frame.minY <= bottomMargin
        }
        return horizontallyVisible && frame.minY >= topMargin && frame.maxY <= bottomMargin
    }

    private func visibleFrameExcludingNavigationBar(in app: XCUIApplication) -> CGRect {
        let windowFrame = app.windows.firstMatch.frame
        let protectedFrame = protectedNavigationFrame(in: app)
        let protectedMaxY = protectedFrame.maxY
        return CGRect(x: windowFrame.minX + 16, y: protectedMaxY + 1, width: max(0, windowFrame.width - 32), height: max(0, windowFrame.maxY - protectedMaxY - 17))
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

    private func protectedNavigationFrame(in app: XCUIApplication) -> CGRect {
        let windowFrame = app.windows.firstMatch.frame
        let navBar = app.navigationBars.firstMatch
        let statusBar = app.statusBars.firstMatch
        let protectedMaxY = max(navBar.exists ? navBar.frame.maxY : windowFrame.minY, statusBar.exists ? statusBar.frame.maxY : windowFrame.minY)
        return CGRect(x: windowFrame.minX, y: windowFrame.minY, width: windowFrame.width, height: max(0, protectedMaxY - windowFrame.minY))
    }

    private func waitBriefly(_ seconds: TimeInterval = 0.2) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    private func frameDescription(_ frame: CGRect) -> String {
        "x: \(frame.origin.x), y: \(frame.origin.y), width: \(frame.size.width), height: \(frame.size.height)"
    }

    private func sanitizedEvidenceName(_ name: String) -> String {
        name.map { character in
            character.isLetter || character.isNumber || character == "-" ? character : "-"
        }.reduce(into: "") { result, character in
            if character == "-", result.last == "-" { return }
            result.append(character)
        }
    }

    private static let module1Lessons: [LessonSpec] = [
        LessonSpec(moduleID: "M1", lessonID: "L-001-01", figures: [FigureSpec(id: "authority-records-exams", altText: "A stacked diagram of Canadian amateur radio authority, records, and exam pathways.")]),
        LessonSpec(moduleID: "M1", lessonID: "L-001-02", figures: [FigureSpec(id: "station-control-decision-tree", altText: "A station-control decision tree showing authorization, service boundary, message purpose, and supervision.")]),
        LessonSpec(moduleID: "M1", lessonID: "L-001-03", figures: [FigureSpec(id: "communications-flowchart", altText: "Flowchart for an amateur operator deciding whether to transmit, identify, or stand by during interference and emergency situations.")]),
        LessonSpec(moduleID: "M1", lessonID: "L-001-04", figures: [FigureSpec(id: "privileges-station-checklist", altText: "Station checklist with operator qualification, band, bandwidth, power, repeater, and modulation-quality boxes.")]),
        LessonSpec(moduleID: "M1", lessonID: "L-001-05", figures: [FigureSpec(id: "international-location-checklist", altText: "A travel-operating checklist beside a simplified world map divided into three ITU regions.")]),
        LessonSpec(moduleID: "M1", lessonID: "L-001-06", figures: [FigureSpec(id: "antenna-rf-emc-checklists", altText: "A station owner reviewing antenna, RF exposure, and interference checklists before transmitting.")])
    ]

    private static let module2Lessons: [LessonSpec] = [
        LessonSpec(moduleID: "M2", lessonID: "L-002-01", figures: [FigureSpec(id: "voice-repeater-simplex", altText: "A portable radio reaches another portable through a hilltop repeater, then both move to a direct simplex path.")]),
        LessonSpec(moduleID: "M2", lessonID: "L-002-02", figures: [FigureSpec(id: "morse-rst-contact-flow", altText: "A Morse contact flow showing a busy-frequency check, CQ, DE, call signs, a signal report, and sign-off.")]),
        LessonSpec(moduleID: "M2", lessonID: "L-002-03", figures: [FigureSpec(id: "distress-urgency-safety-board", altText: "A priority note board showing distress facts and station-readiness items.")]),
        LessonSpec(moduleID: "M2", lessonID: "L-002-04", figures: [FigureSpec(id: "records-maps-locators", altText: "A station log beside an azimuthal map centred on the operator, with a grid locator label.")])
    ]

    private static let module3Lessons: [LessonSpec] = [
        LessonSpec(moduleID: "M3", lessonID: "L-003-01", figures: [FigureSpec(id: "station-filtering-radio-blocks", altText: "Two block diagrams show an HF station accessory chain and an FM superheterodyne receiver chain, with arrows marking signal flow.")]),
        LessonSpec(moduleID: "M3", lessonID: "L-003-02", figures: [FigureSpec(id: "cw-ssb-signal-paths", altText: "Three labelled block diagrams show a CW transmitter, an SSB/CW receiver, and an SSB transmitter with signal-flow arrows.")]),
        LessonSpec(moduleID: "M3", lessonID: "L-003-03", figures: [FigureSpec(id: "digital-interface-linear-supply", altText: "A split diagram shows a computer audio interface between a transceiver and laptop, plus a linear power supply chain from AC mains to DC output.")]),
        LessonSpec(moduleID: "M3", lessonID: "L-003-04", figures: [FigureSpec(id: "yagi-receiver-specs", altText: "A labelled Yagi antenna appears beside a receiver display with wide, medium, and narrow passband choices, plus an image-frequency marker.")]),
        LessonSpec(moduleID: "M3", lessonID: "L-003-05", figures: [FigureSpec(id: "signal-quality-cw-ssb-fm", altText: "Three small panels compare a clean CW carrier, an overdriven SSB voice envelope, and an FM carrier swinging too far from centre.")]),
        LessonSpec(moduleID: "M3", lessonID: "L-003-06", figures: [FigureSpec(id: "controls-digital-voice-packet", altText: "A station control map links keyer timing, microphone gain, VOX, receiver noise tools, and a packet digipeater block.")]),
        LessonSpec(moduleID: "M3", lessonID: "L-003-07", figures: [FigureSpec(id: "batteries-dc-supplies-ripple", altText: "A battery, fuse, heavy DC leads, regulated supply, and ripple waveform show how station power reaches a transceiver.")]),
        LessonSpec(moduleID: "M3", lessonID: "L-003-08", figures: [FigureSpec(id: "grounding-lightning-rf-safety", altText: "A left-to-right station safety layout shows indoor equipment bonded to a bar, a single-point entry, a surge arrestor, a ground rod bonded to the building grounding electrode system, and an outside antenna mast.")])
    ]

    private static let module4Lessons: [LessonSpec] = [
        LessonSpec(moduleID: "M4", lessonID: "L-004-03", figures: [FigureSpec(id: "resistor-colour-code", altText: "Four-band resistor example with every band labelled by position, colour name, value, multiplier, or tolerance, plus a tolerance range line.")]),
        LessonSpec(moduleID: "M4", lessonID: "L-004-01", figures: [FigureSpec(id: "amplifiers-diodes", altText: "A clean block diagram showing a weak signal entering an amplifier, a larger matching signal leaving it, and a diode symbol labelled anode and cathode.")]),
        LessonSpec(moduleID: "M4", lessonID: "L-004-02", figures: [FigureSpec(id: "control-terminals", altText: "Three side-by-side simplified symbols for an NPN transistor, an N-channel FET, and a triode tube, with their control terminals highlighted.")])
    ]

    private static let module5Lessons: [LessonSpec] = [
        LessonSpec(moduleID: "M5", lessonID: "L-005-01", figures: [FigureSpec(id: "metric-prefix-ladder", altText: "Metric prefix ladder from giga to pico showing multiply or divide direction arrows and a skipped nano marker between micro and pico.")]),
        LessonSpec(moduleID: "M5", lessonID: "L-005-02", figures: [
            FigureSpec(id: "power-triangle", altText: "Power triangle with P above I and E, showing that P = I x E and the rearranged forms come from covering the unknown."),
            FigureSpec(id: "ohms-law-triangle", altText: "Ohm’s law triangle with E above I and R, showing E = I x R, I = E / R, and R = E / I."),
            FigureSpec(id: "ohms-law-power-wheel", altText: "Ohm’s law and power wheel with quadrants for P, E, I, and R and three formulas in each quadrant.")
        ]),
        LessonSpec(moduleID: "M5", lessonID: "L-005-03", figures: [FigureSpec(id: "series-parallel-current-paths", altText: "Cell feeding resistors in series, and the same cell feeding parallel resistor branches with total and branch current arrows.")]),
        LessonSpec(moduleID: "M5", lessonID: "L-005-04", figures: [FigureSpec(id: "db-power-ratio-table", altText: "Decibel power-ratio shortcut table for 3, 6, 10, and 20 dB changes, with increase and decrease columns.")]),
        LessonSpec(moduleID: "M5", lessonID: "L-005-05", figures: [FigureSpec(id: "parallel-lc-resonance", altText: "Parallel LC tuned circuit with an inductor and capacitor between shared rails, labelled high Z at resonance.")]),
        LessonSpec(moduleID: "M5", lessonID: "L-005-06", figures: [FigureSpec(id: "transformer-resonance-meters", altText: "Two-panel figure showing transformer windings on a core and ammeter and voltmeter placement around a load.")])
    ]

    private static let module6Lessons: [LessonSpec] = [
        LessonSpec(moduleID: "M6", lessonID: "L-006-01", figures: [FigureSpec(id: "feedline-types-balun", altText: "A radio feeding a centre-fed dipole through a balun, with coax, window-line, and open-wire cross-sections below.")]),
        LessonSpec(moduleID: "M6", lessonID: "L-006-02", figures: [FigureSpec(id: "swr-loss-matching", altText: "A station chain showing forward and reflected waves, plus a second sketch with the tuner at the antenna feed point.")]),
        LessonSpec(moduleID: "M6", lessonID: "L-006-03", figures: [FigureSpec(id: "wavelength-dipole-example", altText: "Wavelength formula λ in metres equals 300 divided by frequency in MHz, with free-space and practical first-cut half-wave dipole examples.")]),
        LessonSpec(moduleID: "M6", lessonID: "L-006-04", figures: [FigureSpec(id: "yagi-vertical-length", altText: "Top view of a three-element Yagi with a longer reflector, driven element, shorter director, main-lobe arrow, and a quarter-wave vertical with radials.")]),
        LessonSpec(moduleID: "M6", lessonID: "L-006-05", figures: [FigureSpec(id: "loop-antenna-patterns", altText: "A dipole broadside pattern beside paired square quad loops and a triangular delta loop with H and V feed points marked.")])
    ]

    private static let module7Lessons: [LessonSpec] = [
        LessonSpec(moduleID: "M7", lessonID: "L-007-01", figures: [FigureSpec(id: "propagation-paths-skip-zone", altText: "Side-view Earth diagram showing VHF direct, ground wave, NVIS, and low-angle sky-wave paths through labelled D, E, F1, and F2 regions.")]),
        LessonSpec(moduleID: "M7", lessonID: "L-007-02", figures: [FigureSpec(id: "daytime-absorption-frequency-window", altText: "Daytime HF path diagram with D-region absorption, F-region return, and a frequency window labelled LUF, OWF, and MUF.")]),
        LessonSpec(moduleID: "M7", lessonID: "L-007-03", figures: [FigureSpec(id: "vhf-unusual-propagation-modes", altText: "Four mini-panels showing sporadic E, tropospheric ducting, auroral scatter, and meteor scatter paths.")])
    ]

    private static let module8Lessons: [LessonSpec] = [
        LessonSpec(moduleID: "M8", lessonID: "L-008-01", figures: [FigureSpec(id: "filter-response-sketches", altText: "Frequency-response sketches for low-pass, high-pass, band-pass, band-reject, and notch filters.")]),
        LessonSpec(moduleID: "M8", lessonID: "L-008-02", figures: [FigureSpec(id: "interference-troubleshooting-map", altText: "A troubleshooting map that separates receiver overload, audio rectification, and transmitter spurious emissions.")])
    ]
}
