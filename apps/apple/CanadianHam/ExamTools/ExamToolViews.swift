import Accessibility
import CanadianHamCalculatorEngine
import CanadianHamContent
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ExamToolButtons: View {
    let availableTools: [ExamTool]
    let openTool: (ExamTool) -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: DesignTokens.Spacing.sm) { buttons }
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) { buttons }
        }
        .padding(DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("exam-tools-controls")
    }

    @ViewBuilder
    private var buttons: some View {
        ForEach(availableTools) { tool in
            Button { openTool(tool) } label: {
                AccessibleSecondaryButtonLabel(title: tool.title)
            }
            .buttonStyle(AccessibleSecondaryButtonStyle())
            .accessibilityIdentifier("exam-tool-\(tool.rawValue)-button")
        }
    }
}

struct ExamToolPresentationModifier: ViewModifier {
    @Binding var selectedTool: ExamTool?
    @ObservedObject var calculator: ExamCalculatorViewModel
    @Binding var calculatorFocused: Bool
    let referenceSheetConfiguration: ReferenceSheetConfiguration
    let hintContext: HintToolContext?
    let onDismiss: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
#if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
#endif
    @State private var selectedSheetDetent = PresentationDetent.medium
    @State private var compactSheetHeight: CGFloat = 0
    @State private var toolPanelFrameInWindow: CGRect?

    private var isPresented: Binding<Bool> {
        Binding(
            get: { selectedTool != nil },
            set: {
                if !$0 {
                    calculatorFocused = false
                    calculator.suspendHardwareKeyboardInput()
                    selectedTool = nil
                    toolPanelFrameInWindow = nil
                }
            }
        )
    }

    func body(content: Content) -> some View {
#if os(iOS)
        let usesInspector = horizontalUsesInspector()
        if usesInspector {
            focusResettingContent(content)
                .background { inspectorKeyboardResponder(usesInspector: usesInspector) }
                .inspector(isPresented: isPresented) {
                    toolPanel(usesInspector: usesInspector)
                        .inspectorColumnWidth(min: 320, ideal: 380, max: 460)
                }
                .onAppear { resetCompactSheetHeight() }
                .onChange(of: usesInspector) { _, _ in resetCompactSheetHeight() }
        } else {
            focusResettingContent(content)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: selectedTool == nil ? 0 : compactSheetHeight)
                }
                .sheet(item: $selectedTool, onDismiss: onDismiss) { tool in
                    toolPanel(for: tool, usesInspector: usesInspector)
                        .background {
                            GeometryReader { proxy in
                                Color.clear
                                    .onAppear { updateCompactSheetHeight(proxy.size.height) }
                                    .onChange(of: proxy.size.height) { _, height in updateCompactSheetHeight(height) }
                            }
                        }
                        .presentationDetents([.medium, .large], selection: $selectedSheetDetent)
                        .presentationContentInteraction(.scrolls)
                        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                        .presentationDragIndicator(.visible)
                        .onAppear { selectedSheetDetent = preferredSheetDetent(for: tool) }
                        .onChange(of: dynamicTypeSize) { _, _ in selectedSheetDetent = preferredSheetDetent(for: tool) }
                }
        }
#elseif os(macOS)
        focusResettingContent(content)
            .inspector(isPresented: isPresented) {
                toolPanel(usesInspector: true)
                    .inspectorColumnWidth(min: 320, ideal: 380, max: 460)
            }
#else
        content
#endif
    }

    private func focusResettingContent(_ content: Content) -> some View {
#if os(iOS)
        content.background {
            ExamContentInteractionFocusResetter(
                shouldIgnoreLocation: { location, windowBounds in
                    if let toolPanelFrameInWindow {
                        let panelFrame = CGRect(
                            x: max(windowBounds.minX, toolPanelFrameInWindow.minX - 24),
                            y: max(windowBounds.minY, toolPanelFrameInWindow.minY - 48),
                            width: windowBounds.maxX - max(windowBounds.minX, toolPanelFrameInWindow.minX - 24),
                            height: windowBounds.maxY - max(windowBounds.minY, toolPanelFrameInWindow.minY - 48)
                        )
                        return panelFrame.insetBy(dx: -8, dy: -8).contains(location)
                    }
                    guard compactSheetHeight > 0, compactSheetHeight < windowBounds.height * 0.9 else { return false }
                    let sheetFrame = CGRect(
                        x: windowBounds.minX,
                        y: max(windowBounds.minY, windowBounds.maxY - compactSheetHeight - 8),
                        width: windowBounds.width,
                        height: compactSheetHeight + 8
                    )
                    return sheetFrame.contains(location)
                },
                onInteraction: {
                    calculatorFocused = false
                    calculator.suspendHardwareKeyboardInput()
                }
            )
        }
#else
        content.simultaneousGesture(
            TapGesture().onEnded {
                calculatorFocused = false
                calculator.suspendHardwareKeyboardInput()
            },
            including: .all
        )
#endif
    }

#if os(iOS)
    private func horizontalUsesInspector() -> Bool {
        AdaptiveExamLayoutPolicy.usesInspectorPresentation(
            idiom: PlatformUserInterfaceIdiom(UIDevice.current.userInterfaceIdiom),
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )
    }

    private func resetCompactSheetHeight() {
        guard compactSheetHeight != 0 else { return }
        compactSheetHeight = 0
    }

    @ViewBuilder
    private func inspectorKeyboardResponder(usesInspector: Bool) -> some View {
        if usesInspector {
            CalculatorKeyboardResponder(isActive: selectedTool == .calculator && calculatorFocused && calculator.acceptsHardwareKeyboardInput) { key in
                pressCalculatorHardwareKey(key)
            }
            .frame(width: 0, height: 0)
        }
    }

    private func pressCalculatorHardwareKey(_ key: CalculatorKey) {
        let spokenResult = calculator.press(key)
        let announcement = String.localizedStringWithFormat(String(localized: "Calculator result: %@"), spokenResult)
        AccessibilityNotification.Announcement(announcement).post()
    }

    private func preferredSheetDetent(for tool: ExamTool) -> PresentationDetent {
#if DEBUG
        if AppLaunchArguments.value(after: "-CanadianHamExamToolInitialDetent") == "large" {
            return .large
        }
#endif
        return tool == .calculator && dynamicTypeSize.isAccessibilitySize ? .large : .medium
    }
#endif

    @ViewBuilder
    private func toolPanel(usesInspector: Bool) -> some View {
        if let selectedTool {
            toolPanel(for: selectedTool, usesInspector: usesInspector)
        } else {
            EmptyView()
        }
    }

    private func updateCompactSheetHeight(_ height: CGFloat) {
        let compactSheetChromeHeight: CGFloat = 32
        let roundedHeight = (height + compactSheetChromeHeight).rounded(.toNearestOrAwayFromZero)
        Task { @MainActor in
            guard abs(compactSheetHeight - roundedHeight) >= 1 else { return }
            compactSheetHeight = roundedHeight
        }
    }

    private func updateToolPanelFrame(_ frame: CGRect?) {
        Task { @MainActor in
            toolPanelFrameInWindow = frame
        }
    }

    private func toolHeader(for tool: ExamTool) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    toolTitleRow(for: tool)
                    closeToolButton
                }
            } else {
                HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                    toolTitleRow(for: tool)
                    Spacer(minLength: 0)
                    closeToolButton
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { updateToolPanelFrame(proxy.frame(in: .global)) }
                    .onChange(of: proxy.frame(in: .global)) { _, frame in updateToolPanelFrame(frame) }
            }
        }
    }

    private func toolTitleRow(for tool: ExamTool) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            Image(systemName: tool.systemImage)
                .font(DesignTokens.FontScale.body.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)

            Text(tool.title) // l10n: localized
                .font(DesignTokens.FontScale.body.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 2)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(tool.accessibilityIdentifier)
        }
    }

    private var closeToolButton: some View {
        Button("Close tool") { // l10n: localized
            calculatorFocused = false
            calculator.suspendHardwareKeyboardInput()
            selectedTool = nil
        }
        .font(DesignTokens.FontScale.body.weight(.semibold))
        .buttonStyle(.bordered)
        .controlSize(.large)
        .accessibilityIdentifier("exam-tool-close-button")
    }

    private func toolPanel(for tool: ExamTool, usesInspector: Bool) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            toolHeader(for: tool)

            Divider()

            GeometryReader { proxy in
                toolBody(for: tool, availableHeight: proxy.size.height, usesInspector: usesInspector)
                    .frame(maxWidth: .infinity, maxHeight: proxy.size.height, alignment: .topLeading)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignTokens.Colors.paper)
        .onDisappear { updateToolPanelFrame(nil) }
    }

    @ViewBuilder
    private func toolBody(for tool: ExamTool, availableHeight: CGFloat, usesInspector: Bool) -> some View {
        switch tool {
        case .calculator:
#if os(iOS)
            let idiom = PlatformUserInterfaceIdiom(UIDevice.current.userInterfaceIdiom)
            let calculatorPrefersScrolling = !usesInspector || idiom == .phone
            let calculatorShowsHelpWhenScrolling = (idiom == .phone && usesInspector) || (!usesInspector && selectedSheetDetent == .large)
#else
            let calculatorPrefersScrolling = !usesInspector
            let calculatorShowsHelpWhenScrolling = false
#endif
            CalculatorToolView(
                viewModel: calculator,
                calculatorFocused: $calculatorFocused,
                prefersScrolling: calculatorPrefersScrolling,
                showsHelpWhenScrolling: calculatorShowsHelpWhenScrolling
            )
            .frame(height: availableHeight)
        case .hint:
            if let hintContext {
                HintToolView(context: hintContext)
                    .frame(height: availableHeight)
            } else {
                ContentUnavailableView("Hint unavailable", systemImage: "lightbulb.slash")
                    .foregroundStyle(DesignTokens.Colors.ink)
            }
        case .referenceSheet:
#if os(iOS)
            ReferenceSheetToolView(
                configuration: referenceSheetConfiguration,
                showsFullSheetButton: !usesInspector && selectedSheetDetent == .medium,
                onShowFullSheet: { selectedSheetDetent = .large }
            )
            .frame(height: availableHeight)
#else
            ReferenceSheetToolView(configuration: referenceSheetConfiguration)
                .frame(height: availableHeight)
#endif
        }
    }
}

#if os(iOS)
private struct ExamContentInteractionFocusResetter: UIViewRepresentable {
    let shouldIgnoreLocation: (CGPoint, CGRect) -> Bool
    let onInteraction: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(shouldIgnoreLocation: shouldIgnoreLocation, onInteraction: onInteraction)
    }

    func makeUIView(context: Context) -> UIView {
        let view = WindowGestureAttachmentView()
        view.configure(coordinator: context.coordinator)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.shouldIgnoreLocation = shouldIgnoreLocation
        context.coordinator.onInteraction = onInteraction
        (uiView as? WindowGestureAttachmentView)?.configure(coordinator: context.coordinator)
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.detach()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var shouldIgnoreLocation: (CGPoint, CGRect) -> Bool
        var onInteraction: () -> Void
        private weak var window: UIWindow?
        private weak var tapRecognizer: UITapGestureRecognizer?
        private weak var panRecognizer: UIPanGestureRecognizer?

        init(shouldIgnoreLocation: @escaping (CGPoint, CGRect) -> Bool, onInteraction: @escaping () -> Void) {
            self.shouldIgnoreLocation = shouldIgnoreLocation
            self.onInteraction = onInteraction
        }

        func attach(to window: UIWindow?) {
            guard let window, self.window !== window else { return }
            detach()
            self.window = window

            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleInteraction))
            tapRecognizer.cancelsTouchesInView = false
            tapRecognizer.delegate = self
            window.addGestureRecognizer(tapRecognizer)
            self.tapRecognizer = tapRecognizer

            let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleInteraction))
            panRecognizer.cancelsTouchesInView = false
            panRecognizer.delegate = self
            window.addGestureRecognizer(panRecognizer)
            self.panRecognizer = panRecognizer
        }

        func detach() {
            if let tapRecognizer, let window = tapRecognizer.view {
                window.removeGestureRecognizer(tapRecognizer)
            }
            if let panRecognizer, let window = panRecognizer.view {
                window.removeGestureRecognizer(panRecognizer)
            }
            tapRecognizer = nil
            panRecognizer = nil
            window = nil
        }

        @objc private func handleInteraction(_ recognizer: UIGestureRecognizer) {
            switch recognizer.state {
            case .began, .ended:
                onInteraction()
            default:
                break
            }
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard let window = window ?? gestureRecognizer.view else { return true }
            return !shouldIgnoreLocation(touch.location(in: window), window.bounds)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }

    final class WindowGestureAttachmentView: UIView {
        private weak var coordinator: Coordinator?

        func configure(coordinator: Coordinator) {
            self.coordinator = coordinator
            coordinator.attach(to: window)
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            coordinator?.attach(to: window)
        }
    }
}
#endif

extension View {
    func examToolPresentation(
        selectedTool: Binding<ExamTool?>,
        calculator: ExamCalculatorViewModel,
        calculatorFocused: Binding<Bool>,
        referenceSheetConfiguration: ReferenceSheetConfiguration = .basic,
        hintContext: HintToolContext? = nil,
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        modifier(ExamToolPresentationModifier(selectedTool: selectedTool, calculator: calculator, calculatorFocused: calculatorFocused, referenceSheetConfiguration: referenceSheetConfiguration, hintContext: hintContext, onDismiss: onDismiss))
    }
}

struct HintToolContext {
    let hint: QuestionHint
    let language: BankLanguage
    let visibleLevel: Int
    let answeredWithHelpQualified: Bool
    let canRecordHelp: Bool
    let referenceSheetAvailable: Bool
    let revealLevel: (Int) -> Void
    let hintVisibleLongEnough: () -> Bool
    let openLesson: (QuestionHintLessonLink) -> Void
}

private struct HintToolView: View {
    let context: HintToolContext
    @State private var qualificationTimer = HintVisibilityQualificationTimer()

    private var lastAvailableLevel: Int { context.hint.hints.count }
    private var nextLevel: Int? { context.visibleLevel < lastAvailableLevel ? context.visibleLevel + 1 : nil }
    private var visibleHints: [QuestionHintText] { context.hint.hints.filter { $0.level <= context.visibleLevel } }
    private var showsLessonLink: Bool { context.visibleLevel >= lastAvailableLevel }
    private var referenceSheetSection: String? { context.hint.referenceSheetSection }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text(context.canRecordHelp ? String(localized: "Use hints when you need help. Answers after a shown hint are saved as answered with help.") : String(localized: "This hint is available for review. Your current answer has already been scored.")) // l10n: localized
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("hint-tool-intro")

                if visibleHints.isEmpty {
                    Text("No hint is shown yet.")
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.inkMuted)
                        .accessibilityIdentifier("hint-tool-empty")
                }

                ForEach(visibleHints, id: \.level) { entry in
                    hintCard(entry)
                }

                if HintToolRules.showsReferencePointer(referenceSheetAvailable: context.referenceSheetAvailable, visibleLevel: context.visibleLevel, referenceSheetSection: referenceSheetSection), let referenceSheetSection {
                    Text(referencePointerText(referenceSheetSection)) // l10n: localized
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("hint-reference-pointer")
                }

                if showsLessonLink {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Button("Review in lesson") { // l10n: localized
                            context.openLesson(context.hint.lessonLink)
                        }
                        .buttonStyle(AccessibleSecondaryButtonStyle())
                        .accessibilityIdentifier("hint-review-in-lesson-button")
                        if canadianHamUsesFrenchUI {
                            Text("Lesson offered in English only.")
                                .font(DesignTokens.FontScale.caption.weight(.semibold))
                                .foregroundStyle(DesignTokens.Colors.inkMuted)
                                .accessibilityIdentifier("hint-english-only-lesson-notice")
                        }
                    }
                }

                if let nextLevel {
                    showHintButton(level: nextLevel)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .accessibilityIdentifier("hint-tool-scroll")
        .onAppear { syncQualificationTimer() }
        .onDisappear { cancelQualificationTimer() }
        .onChange(of: context.hint.questionId) { _, _ in syncQualificationTimer() }
        .onChange(of: context.visibleLevel) { _, _ in syncQualificationTimer() }
        .onChange(of: context.canRecordHelp) { _, _ in syncQualificationTimer() }
        .onChange(of: context.answeredWithHelpQualified) { _, _ in syncQualificationTimer() }
    }

    private func showHintButton(level: Int) -> some View {
        Button(level == 1 ? String(localized: "Show Hint 1") : String(localized: "Show Hint 2")) { // l10n: localized
            reveal(level)
        }
        .buttonStyle(AccessiblePrimaryButtonStyle())
        .accessibilityIdentifier("hint-show-level-\(level)-button")
    }

    private func hintCard(_ entry: QuestionHintText) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(String.localizedStringWithFormat(String(localized: "Hint %d"), entry.level)) // l10n: localized
                .font(DesignTokens.FontScale.body.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("hint-level-\(entry.level)-title")
            Text(localizedHintText(entry)) // l10n: content(question)
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
                .accessibilityIdentifier("hint-level-\(entry.level)-body")
        }
        .padding(DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
    }

    private func localizedHintText(_ entry: QuestionHintText) -> AttributedString {
        localized(context.language == .french ? entry.fr : entry.en, language: context.language)
    }

    private func reveal(_ level: Int) {
        context.revealLevel(level)
        HintAccessibilityAnnouncements.postHintShown(level: level)
    }

    private func syncQualificationTimer() {
        guard context.visibleLevel > 0 else {
            cancelQualificationTimer()
            return
        }
        qualificationTimer.begin(
            questionID: context.hint.questionId,
            canRecordHelp: context.canRecordHelp,
            alreadyQualified: context.answeredWithHelpQualified
        ) {
            guard context.hintVisibleLongEnough() else { return }
            AccessibilityNotification.Announcement(String(localized: "Answers to this question will be saved as answered with help.")).post()
        }
    }

    private func cancelQualificationTimer() {
        qualificationTimer.cancel()
    }

    private func referencePointerText(_ section: String) -> AttributedString {
        let interfaceLanguage: BankLanguage = canadianHamUsesFrenchUI ? .french : .english
        var text = AttributedString(String(localized: "Reference sheet: "))
        text += localized(referenceSheetSectionLabel(section, language: interfaceLanguage), language: interfaceLanguage)
        return text
    }
}

private func localized(_ string: String, language: BankLanguage) -> AttributedString {
    var attributed = AttributedString(string)
    attributed.languageIdentifier = language == .french ? "fr-CA" : "en-CA"
    return attributed
}

private func referenceSheetSectionLabel(_ section: String, language: BankLanguage) -> String {
    switch (section, language) {
    case ("ohms-law", .french): "Loi d'Ohm"
    case ("ohms-law", _): "Ohm's law"
    case ("power", .french): "Puissance"
    case ("power", _): "Power"
    case ("series-parallel-resistance", .french): "Résistance en série et en parallèle"
    case ("series-parallel-resistance", _): "Series and parallel resistance"
    case ("decibel-power-shortcuts", .french): "Repères de puissance en décibels"
    case ("decibel-power-shortcuts", _): "Decibel power shortcuts"
    case ("wavelength-dipole-length", .french): "Longueur d'onde et longueur de dipôle"
    case ("wavelength-dipole-length", _): "Wavelength and dipole length"
    case ("metric-prefixes", .french): "Préfixes métriques"
    case ("metric-prefixes", _): "Metric prefixes"
    case ("resistor-colour-code", .french): "Code de couleurs des résistances à quatre bandes"
    case ("resistor-colour-code", _): "Four-band resistor colour code"
    default: section
    }
}

struct CalculatorToolView: View {
    @ObservedObject var viewModel: ExamCalculatorViewModel
    @Binding var calculatorFocused: Bool
    let prefersScrolling: Bool
    let showsHelpWhenScrolling: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
#if os(iOS)
    @Environment(\.verticalSizeClass) private var verticalSizeClass
#endif
    @FocusState private var hasKeyboardFocus: Bool

    private let rows: [[CalculatorKey]] = [
        [.allClear, .clearEntry, .backspace, .divide],
        [.seven, .eight, .nine, .multiply],
        [.four, .five, .six, .subtract],
        [.one, .two, .three, .add],
        [.toggleSign, .zero, .decimalPoint, .equals],
        [.percent, .squareRoot, .square, .reciprocal],
    ]

    var body: some View {
        Group {
            if shouldPreferScrollableCalculator {
                calculatorScrollContent(layout: CalculatorToolLayout(dynamicTypeSize: dynamicTypeSize, contentMode: .scrolling(showsHelpText: showsHelpWhenScrolling)))
            } else {
                ViewThatFits(in: .vertical) {
                    calculatorFittingCandidate(at: 0)
                    calculatorFittingCandidate(at: 1)
                    calculatorFittingCandidate(at: 2)
                    calculatorFittingCandidate(at: 3)
                    calculatorScrollContent(layout: CalculatorToolLayout(dynamicTypeSize: dynamicTypeSize, contentMode: .scrolling(showsHelpText: false)))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .contentShape(Rectangle())
        .accessibilityIdentifier("calculator-keyboard-focus-target")
        .focusable(true)
        .focused($hasKeyboardFocus)
        .onAppear {
            if calculatorFocused {
                focusKeyboardAfterLayout()
            }
        }
        .simultaneousGesture(TapGesture().onEnded {
            activateKeyboardFocus()
        })
        .onChange(of: calculatorFocused) { _, isFocused in
            if isFocused {
                focusKeyboardAfterLayout()
            } else {
                hasKeyboardFocus = false
                viewModel.suspendHardwareKeyboardInput()
            }
        }
        .onKeyPress { press in
            handleKeyPress(press)
        }
    }

    private var shouldPreferScrollableCalculator: Bool {
        if prefersScrolling || dynamicTypeSize.isAccessibilitySize { return true }
#if os(iOS)
        return verticalSizeClass == .compact
#else
        return false
#endif
    }

    private func calculatorFittingCandidate(at index: Int) -> some View {
        let contentMode = CalculatorToolLayout.fittingCandidateContentModes[index]
        return calculatorFittingContent(layout: CalculatorToolLayout(dynamicTypeSize: dynamicTypeSize, contentMode: contentMode))
    }

    private func calculatorFittingContent(layout: CalculatorToolLayout) -> some View {
        calculatorContent(layout: layout)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .accessibilityElement(children: .contain)
    }

    private func calculatorScrollContent(layout: CalculatorToolLayout) -> some View {
        ScrollView {
            calculatorContent(layout: layout)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("calculator-tool-scroll")
    }

    private func calculatorContent(layout: CalculatorToolLayout) -> some View {
        VStack(alignment: .leading, spacing: layout.sectionSpacing) {
            Text(viewModel.display) // l10n: verbatim
                .font(layout.displayFont)
                .foregroundStyle(DesignTokens.Colors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.45)
                .frame(maxWidth: .infinity, minHeight: layout.displayHeight, alignment: .trailing)
                .padding(.horizontal, layout.displayHorizontalPadding)
                .padding(.vertical, layout.displayVerticalPadding)
                .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
                .accessibilityLabel(Text("Calculator result")) // l10n: localized
                .accessibilityValue(Text(viewModel.spokenResult)) // l10n: localized
                .accessibilityIdentifier("calculator-result")
                .simultaneousGesture(TapGesture().onEnded {
                    activateKeyboardFocus()
                })

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 44), spacing: layout.keySpacing), count: 4), spacing: layout.keySpacing) {
                ForEach(rows.flatMap { $0 }, id: \.rawValue) { key in
                    calculatorButton(key, layout: layout)
                }
            }
            .accessibilityIdentifier("calculator-key-grid")

            if layout.showsHelpText {
                Text("Keyboard input works only while focus is in the calculator: digits, operators, Enter for equals, Backspace, Escape for clear entry, Delete for all clear.")
                    .font(DesignTokens.FontScale.caption)
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("calculator-keyboard-help")
            }
        }
    }

    private func calculatorButton(_ key: CalculatorKey, layout: CalculatorToolLayout) -> some View {
        Button {
            activateKeyboardFocus()
            pressKey(key)
        } label: {
            Text(displayTitle(for: key)) // l10n: verbatim
                .font(layout.keyFont)
                .foregroundStyle(DesignTokens.Colors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(height: layout.keyHeight)
                .background(buttonBackground(for: key), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .frame(height: layout.keyHeight)
        .contentShape(Rectangle())
        .accessibilityLabel(Text(accessibilityLabel(for: key))) // l10n: localized
        .accessibilityIdentifier("calculator-key-\(accessibilityIdentifierSuffix(for: key))")
    }

    private func activateKeyboardFocus() {
        viewModel.acceptHardwareKeyboardInput()
        calculatorFocused = true
        hasKeyboardFocus = true
    }

    private func focusKeyboardAfterLayout() {
        Task { @MainActor in
            await Task.yield()
            guard calculatorFocused else { return }
            viewModel.acceptHardwareKeyboardInput()
            hasKeyboardFocus = true
        }
    }

    private func pressKey(_ key: CalculatorKey) {
        let spokenResult = viewModel.press(key)
        let announcement = String.localizedStringWithFormat(String(localized: "Calculator result: %@"), spokenResult)
        AccessibilityNotification.Announcement(announcement).post()
    }

    private func handleKeyPress(_ press: KeyPress) -> KeyPress.Result {
        guard calculatorFocused, viewModel.acceptsHardwareKeyboardInput, let key = calculatorKey(for: press) else { return .ignored }
        Task { @MainActor in
            pressKey(key)
        }
        return .handled
    }

    private func calculatorKey(for press: KeyPress) -> CalculatorKey? {
        guard press.modifiers.intersection([.command, .control, .option]).isEmpty else { return nil }
        switch press.key {
        case .return:
            return .equals
        case .delete:
            return .backspace
        case .deleteForward:
            return .allClear
        case .escape:
            return .clearEntry
        default:
            break
        }
        switch press.characters {
        case "\r", "\n", "\u{3}": return .equals
        case "0": return .zero
        case "1": return .one
        case "2": return .two
        case "3": return .three
        case "4": return .four
        case "5": return .five
        case "6": return .six
        case "7": return .seven
        case "8": return .eight
        case "9": return .nine
        case ".", ",": return .decimalPoint
        case "+": return .add
        case "-": return .subtract
        case "*", "x", "X": return .multiply
        case "/": return .divide
        case "=": return .equals
        default:
            return nil
        }
    }

    private func buttonBackground(for key: CalculatorKey) -> Color {
        switch key {
        case .add, .subtract, .multiply, .divide, .equals:
            DesignTokens.Colors.paperInset
        default:
            DesignTokens.Colors.paperElevated
        }
    }

    private func displayTitle(for key: CalculatorKey) -> String {
        switch key {
        case .decimalPoint: viewModel.locale == .fr ? "," : "."
        case .subtract: "−"
        case .backspace: "⌫"
        default: key.rawValue
        }
    }

    private func accessibilityIdentifierSuffix(for key: CalculatorKey) -> String {
        switch key {
        case .zero: "0"
        case .one: "1"
        case .two: "2"
        case .three: "3"
        case .four: "4"
        case .five: "5"
        case .six: "6"
        case .seven: "7"
        case .eight: "8"
        case .nine: "9"
        case .decimalPoint: "decimal"
        case .add: "add"
        case .subtract: "subtract"
        case .multiply: "multiply"
        case .divide: "divide"
        case .equals: "equals"
        case .squareRoot: "square-root"
        case .square: "square"
        case .reciprocal: "reciprocal"
        case .toggleSign: "toggle-sign"
        case .percent: "percent"
        case .clearEntry: "clear-entry"
        case .allClear: "all-clear"
        case .backspace: "backspace"
        }
    }

    private func accessibilityLabel(for key: CalculatorKey) -> String {
        switch key {
        case .zero: String(localized: "Digit 0")
        case .one: String(localized: "Digit 1")
        case .two: String(localized: "Digit 2")
        case .three: String(localized: "Digit 3")
        case .four: String(localized: "Digit 4")
        case .five: String(localized: "Digit 5")
        case .six: String(localized: "Digit 6")
        case .seven: String(localized: "Digit 7")
        case .eight: String(localized: "Digit 8")
        case .nine: String(localized: "Digit 9")
        case .decimalPoint: String(localized: "Decimal point")
        case .add: String(localized: "Add")
        case .subtract: String(localized: "Subtract")
        case .multiply: String(localized: "Multiply")
        case .divide: String(localized: "Divide")
        case .equals: String(localized: "Equals")
        case .squareRoot: String(localized: "Square root")
        case .square: String(localized: "Square")
        case .reciprocal: String(localized: "Reciprocal")
        case .toggleSign: String(localized: "Toggle sign", defaultValue: "Change sign")
        case .percent: String(localized: "Percent")
        case .clearEntry: String(localized: "Clear entry")
        case .allClear: String(localized: "All clear")
        case .backspace: String(localized: "Backspace")
        }
    }
}

#if os(iOS)
private struct CalculatorKeyboardResponder: UIViewRepresentable {
    let isActive: Bool
    let onKey: (CalculatorKey) -> Void

    func makeUIView(context: Context) -> KeyInputView {
        let view = KeyInputView()
        view.update(isActive: isActive, onKey: onKey)
        return view
    }

    func updateUIView(_ uiView: KeyInputView, context: Context) {
        uiView.update(isActive: isActive, onKey: onKey)
    }

    final class KeyInputView: UIView {
        private var isActive = false
        private var onKey: (CalculatorKey) -> Void = { _ in }
        private var swallowedPresses: Set<UIPress> = []

        override var canBecomeFirstResponder: Bool { true }

        func update(isActive: Bool, onKey: @escaping (CalculatorKey) -> Void) {
            let becameActive = !self.isActive && isActive
            if self.isActive && !isActive {
                swallowedPresses.removeAll()
            }
            self.isActive = isActive
            self.onKey = onKey
            // Claim first responder only when calculator input is activated (or the view joins a
            // window), never on unrelated view updates, so keyboard focus that moved to another
            // control is not stolen back.
            if becameActive || !isActive {
                syncFirstResponder()
            }
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            syncFirstResponder()
        }

        override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            let handledPresses = handledCalculatorPresses(in: presses)
            swallowedPresses.formUnion(handledPresses)
            for press in handledPresses {
                guard let key = calculatorKey(for: press) else { continue }
                onKey(key)
            }
            let unhandledPresses = presses.subtracting(handledPresses)
            if !unhandledPresses.isEmpty {
                super.pressesBegan(unhandledPresses, with: event)
            }
        }

        override func pressesChanged(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            let handledPresses = presses.intersection(swallowedPresses)
            let unhandledPresses = presses.subtracting(handledPresses)
            if !unhandledPresses.isEmpty {
                super.pressesChanged(unhandledPresses, with: event)
            }
        }

        override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            let handledPresses = presses.intersection(swallowedPresses)
            swallowedPresses.subtract(handledPresses)
            let unhandledPresses = presses.subtracting(handledPresses)
            if !unhandledPresses.isEmpty {
                super.pressesEnded(unhandledPresses, with: event)
            }
        }

        override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            let handledPresses = presses.intersection(swallowedPresses)
            swallowedPresses.subtract(handledPresses)
            let unhandledPresses = presses.subtracting(handledPresses)
            if !unhandledPresses.isEmpty {
                super.pressesCancelled(unhandledPresses, with: event)
            }
        }

        override func resignFirstResponder() -> Bool {
            let didResign = super.resignFirstResponder()
            if didResign {
                swallowedPresses.removeAll()
            }
            return didResign
        }

        private func handledCalculatorPresses(in presses: Set<UIPress>) -> Set<UIPress> {
            guard isActive else { return [] }
            return Set(presses.filter { calculatorKey(for: $0) != nil })
        }

        private func syncFirstResponder() {
            guard window != nil else { return }
            if isActive {
                DispatchQueue.main.async { [weak self] in
                    guard let self, self.isActive, self.window != nil, !self.isFirstResponder else { return }
                    self.becomeFirstResponder()
                }
            } else if isFirstResponder {
                resignFirstResponder()
            }
        }

        private func calculatorKey(for press: UIPress) -> CalculatorKey? {
            guard let key = press.key,
                  key.modifierFlags.intersection([.command, .control, .alternate]).isEmpty else { return nil }
            switch key.keyCode {
            case .keyboardReturnOrEnter, .keypadEnter:
                return .equals
            case .keyboardDeleteOrBackspace:
                return .backspace
            case .keyboardDeleteForward:
                return .allClear
            case .keyboardEscape:
                return .clearEntry
            default:
                break
            }
            switch key.characters {
            case "0": return .zero
            case "1": return .one
            case "2": return .two
            case "3": return .three
            case "4": return .four
            case "5": return .five
            case "6": return .six
            case "7": return .seven
            case "8": return .eight
            case "9": return .nine
            case ".", ",": return .decimalPoint
            case "+": return .add
            case "-": return .subtract
            case "*", "x", "X": return .multiply
            case "/": return .divide
            case "=": return .equals
            default:
                return nil
            }
        }
    }
}
#endif

private extension CalculatorToolLayout {
    var displayFont: Font { (usesAccessibilityMetrics ? DesignTokens.FontScale.display : DesignTokens.FontScale.title).monospacedDigit().weight(.bold) }
    var keyFont: Font { (usesAccessibilityMetrics ? DesignTokens.FontScale.body : DesignTokens.FontScale.caption).weight(.semibold) }
}

struct ReferenceSheetToolView: View {
    let configuration: ReferenceSheetConfiguration
    var showsFullSheetButton = false
    var onShowFullSheet: () -> Void = {}
    @State private var document: ReferenceSheetDocument?
    @State private var zoom = 1.0
    @State private var officialDocument: OfficialReferenceSheetDocument?
    @State private var showsOfficial = true
    @State private var showsTextEquivalent = false
    @State private var page = 0

    var body: some View {
        Group {
            if let document {
                referenceSheet(document)
            } else {
                unavailableSheet
            }
        }
        .task { loadDocument() }
    }

    private func referenceSheet(_ document: ReferenceSheetDocument) -> some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    if showsFullSheetButton {
                        Button("Show full sheet") { onShowFullSheet() } // l10n: localized
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .frame(minHeight: 44)
                            .accessibilityIdentifier("reference-sheet-show-full-sheet")
                    }
                    if officialDocument != nil {
                        Picker("Sheet version", selection: $showsOfficial) { // l10n: localized
                            Text("Official sheet").tag(true) // l10n: localized
                            Text("Study sheet").tag(false) // l10n: localized
                        }
                        .pickerStyle(.menu)
                        .accessibilityIdentifier("reference-sheet-version")
                    }
                    if Bundle.main.preferredLocalizations.first?.hasPrefix("fr") == true {
                        Text("This content is currently available in English only.") // l10n: localized
                            .font(DesignTokens.FontScale.body)
                    }
                    if showsOfficial, let officialDocument {
                        officialSheet(officialDocument, width: geometry.size.width)
                    } else {
                        LessonMarkdownView(markdown: document.markdown, title: "Original Basic formula and reference study aid")
                            .accessibilityIdentifier("reference-sheet-study-text")
                    }
                }
                .foregroundStyle(DesignTokens.Colors.ink)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.bottom, DesignTokens.Spacing.xl)
            }
            .accessibilityIdentifier("reference-sheet-scroll")
        }
    }

    @ViewBuilder
    private func officialSheet(_ document: OfficialReferenceSheetDocument, width: CGFloat) -> some View {
        Toggle("Text equivalent", isOn: $showsTextEquivalent) // l10n: localized
            .accessibilityIdentifier("reference-sheet-text-equivalent")
        if showsTextEquivalent {
            LessonMarkdownView(markdown: document.markdown, title: "")
                .accessibilityIdentifier("reference-sheet-official-text")
        } else {
            Picker("Page", selection: $page) { // l10n: localized
                ForEach(0..<document.pages.count, id: \.self) { index in
                    Text("\(index + 1) / 5").tag(index) // l10n: verbatim
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("reference-sheet-page")
            zoomControls
            ScrollView(.horizontal) {
                if let image = officialPageImage(document.pages[page]) {
                    image.resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: max(1, width) * zoom)
                    .accessibilityLabel(Text("Official sheet, page \(page + 1) of 5. Use Text equivalent for accessible content.")) // l10n: localized
                    .accessibilityIdentifier("reference-sheet-official-page")
                } else {
                    unavailableSheet
                }
            }
        }
        Text(officialSheetAttribution) // l10n: content(en)
            .font(DesignTokens.FontScale.body)
    }

    private var officialSheetAttribution: AttributedString {
        var text = AttributedString("Source: Innovation, Science and Economic Development Canada (ISED), Reference Material for Amateur Radio Exam – Basic Qualification, Version 1 (May 2025). Reproduced for internal use; this reproduction is not an official version. Canadian Ham is not affiliated with or endorsed by the Government of Canada.")
        text.languageIdentifier = BankLanguage.english.accessibilityLanguageCode
        return text
    }

    private func officialPageImage(_ url: URL) -> Image? {
#if os(iOS)
        UIImage(contentsOfFile: url.path).map { Image(uiImage: $0) }
#else
        NSImage(contentsOf: url).map { Image(nsImage: $0) }
#endif
    }

    private var unavailableSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.warningText)
                        .frame(width: 44, height: 44)
                        .accessibilityLabel(Text("Reference sheet unavailable")) // l10n: localized
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Reference sheet unavailable") // l10n: localized
                            .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                            .foregroundStyle(DesignTokens.Colors.warningText)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("reference-sheet-unavailable")
                        Text("The bundled Basic reference sheet is not installed in this build.") // l10n: localized
                            .font(DesignTokens.FontScale.body)
                            .foregroundStyle(DesignTokens.Colors.ink)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(DesignTokens.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignTokens.Colors.warningBg, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.warningBorder, lineWidth: 1))
        }
        .accessibilityIdentifier("reference-sheet-scroll")
    }

    private var zoomControls: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                zoomButtons
            }
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                zoomButtons
            }
        }
    }

    @ViewBuilder
    private var zoomButtons: some View {
            Button("Zoom out") { zoom = max(1, zoom - 0.5) } // l10n: localized
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
                .disabled(zoom <= 1)
                .accessibilityIdentifier("reference-sheet-zoom-out")
            Text("\(Int((zoom * 100).rounded()))%") // l10n: verbatim
                .font(DesignTokens.FontScale.body.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
                .monospacedDigit()
            Button("Zoom in") { zoom = min(3, zoom + 0.5) } // l10n: localized
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
                .disabled(zoom >= 3)
                .accessibilityIdentifier("reference-sheet-zoom-in")
    }

    private func loadDocument() {
        guard document == nil else { return }
        document = try? ReferenceSheetLoader.load(configuration: configuration)
        officialDocument = try? OfficialReferenceSheetLoader.load()
    }
}
