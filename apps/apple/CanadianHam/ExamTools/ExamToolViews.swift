import Accessibility
import CanadianHamCalculatorEngine
import CanadianHamContent
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ExamToolButtons: View {
    var availableTools: [ExamTool] = ExamTool.allCases
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
        if horizontalUsesInspector {
            focusResettingContent(content)
                .inspector(isPresented: isPresented) {
                    toolPanel
                        .inspectorColumnWidth(min: 320, ideal: 380, max: 460)
                }
        } else {
            focusResettingContent(content)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: selectedTool == nil ? 0 : compactSheetHeight)
                }
                .sheet(item: $selectedTool) { tool in
                    toolPanel(for: tool)
                        .background {
                            GeometryReader { proxy in
                                Color.clear
                                    .onAppear { updateCompactSheetHeight(proxy.size.height) }
                                    .onChange(of: proxy.size.height) { _, height in updateCompactSheetHeight(height) }
                            }
                        }
                        .presentationDetents([.medium, .large], selection: $selectedSheetDetent)
                        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                        .presentationDragIndicator(.visible)
                        .onAppear { selectedSheetDetent = preferredSheetDetent(for: tool) }
                        .onChange(of: dynamicTypeSize) { _, _ in selectedSheetDetent = preferredSheetDetent(for: tool) }
                }
        }
#elseif os(macOS)
        focusResettingContent(content)
            .inspector(isPresented: isPresented) {
                toolPanel
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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var horizontalUsesInspector: Bool {
        horizontalSizeClass == .regular
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
    private var toolPanel: some View {
        if let selectedTool {
            toolPanel(for: selectedTool)
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

    private func toolPanel(for tool: ExamTool) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            toolHeader(for: tool)

            Divider()

            GeometryReader { proxy in
                toolBody(for: tool, availableHeight: proxy.size.height)
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
    private func toolBody(for tool: ExamTool, availableHeight: CGFloat) -> some View {
        switch tool {
        case .calculator:
            CalculatorToolView(viewModel: calculator, calculatorFocused: $calculatorFocused)
                .frame(height: availableHeight)
        case .referenceSheet:
#if os(iOS)
            ReferenceSheetToolView(
                configuration: referenceSheetConfiguration,
                showsFullSheetButton: !horizontalUsesInspector && selectedSheetDetent == .medium,
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
        referenceSheetConfiguration: ReferenceSheetConfiguration = .basic
    ) -> some View {
        modifier(ExamToolPresentationModifier(selectedTool: selectedTool, calculator: calculator, calculatorFocused: calculatorFocused, referenceSheetConfiguration: referenceSheetConfiguration))
    }
}

struct CalculatorToolView: View {
    @ObservedObject var viewModel: ExamCalculatorViewModel
    @Binding var calculatorFocused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @FocusState private var hasKeyboardFocus: Bool

    private let rows: [[CalculatorKey]] = [
        [.allClear, .clearEntry, .backspace, .divide],
        [.seven, .eight, .nine, .multiply],
        [.four, .five, .six, .subtract],
        [.one, .two, .three, .add],
        [.toggleSign, .zero, .decimalPoint, .equals],
        [.squareRoot, .square, .reciprocal, .percent],
    ]

    var body: some View {
        GeometryReader { proxy in
            let layout = CalculatorToolLayout(availableHeight: proxy.size.height, dynamicTypeSize: dynamicTypeSize)
            Group {
                if layout.usesScrolling {
                    ScrollView {
                        calculatorContent(layout: layout)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityIdentifier("calculator-tool-scroll")
                } else {
                    calculatorContent(layout: layout)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("calculator-keyboard-focus-target")
        .focusable(true)
        .focused($hasKeyboardFocus)
        .onAppear {
            if calculatorFocused {
                hasKeyboardFocus = true
            }
        }
        .simultaneousGesture(TapGesture().onEnded {
            activateKeyboardFocus()
        })
        .onChange(of: calculatorFocused) { _, isFocused in
            if isFocused {
                hasKeyboardFocus = true
            } else {
                hasKeyboardFocus = false
                viewModel.suspendHardwareKeyboardInput()
            }
        }
        .onKeyPress { press in
            handleKeyPress(press)
        }
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
                .frame(maxWidth: .infinity, minHeight: layout.keyHeight)
                .background(buttonBackground(for: key), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accessibilityLabel(for: key))) // l10n: localized
        .accessibilityIdentifier("calculator-key-\(accessibilityIdentifierSuffix(for: key))")
    }

    private func activateKeyboardFocus() {
        viewModel.acceptHardwareKeyboardInput()
        calculatorFocused = true
        hasKeyboardFocus = true
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

private struct CalculatorToolLayout {
    let availableHeight: CGFloat
    let dynamicTypeSize: DynamicTypeSize

    var sectionSpacing: CGFloat { usesScrolling ? DesignTokens.Spacing.md : compactSectionSpacing }
    var keySpacing: CGFloat { usesScrolling ? DesignTokens.Spacing.sm : compactKeySpacing }
    var displayHeight: CGFloat { usesScrolling ? 72 : compactDisplayHeight }
    var displayHorizontalPadding: CGFloat { usesScrolling ? DesignTokens.Spacing.lg : DesignTokens.Spacing.md }
    var displayVerticalPadding: CGFloat { usesScrolling ? DesignTokens.Spacing.lg : compactDisplayVerticalPadding }
    var keyHeight: CGFloat { usesScrolling ? 64 : min(64, max(44, compactKeyHeight)) }
    var displayFont: Font { (usesScrolling ? DesignTokens.FontScale.display : DesignTokens.FontScale.title).monospacedDigit().weight(.bold) }
    var keyFont: Font { (usesScrolling ? DesignTokens.FontScale.body : DesignTokens.FontScale.caption).weight(.semibold) }
    var showsHelpText: Bool { !usesScrolling && showsCompactHelpText }

    var usesScrolling: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    private var compactKeyHeight: CGFloat {
        let displayTotal = compactDisplayHeight + (compactDisplayVerticalPadding * 2)
        let helpTotal: CGFloat = showsCompactHelpText ? 48 + compactSectionSpacing : 0
        let gridSpacing = compactKeySpacing * CGFloat(rowCount - 1)
        let gridHeight = max(0, availableHeight - displayTotal - compactSectionSpacing - helpTotal)
        return (gridHeight - gridSpacing) / CGFloat(rowCount)
    }

    private var showsCompactHelpText: Bool {
        !dynamicTypeSize.isAccessibilitySize && availableHeight >= 440
    }

    private var compactSectionSpacing: CGFloat { 6 }
    private var compactKeySpacing: CGFloat { 6 }
    private var compactDisplayHeight: CGFloat { 48 }
    private var compactDisplayVerticalPadding: CGFloat { 4 }
    private var rowCount: Int { 6 }
}

struct ReferenceSheetToolView: View {
    let configuration: ReferenceSheetConfiguration
    var showsFullSheetButton = false
    var onShowFullSheet: () -> Void = {}
    @State private var document: ReferenceSheetDocument?
    @State private var zoom = 1.0

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
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                if showsFullSheetButton {
                    Button("Show full sheet") { onShowFullSheet() } // l10n: localized
                        .font(DesignTokens.FontScale.body.weight(.semibold))
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                        .accessibilityIdentifier("reference-sheet-show-full-sheet")
                } else {
                    zoomControls
                }

                LessonMarkdownView(markdown: document.markdown, title: "Original Basic formula and reference study aid")
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(DesignTokens.Spacing.md)
                    .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
            }
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .accessibilityIdentifier("reference-sheet-scroll")
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
            Button("Zoom out") { zoom = max(0.8, zoom - 0.1) } // l10n: localized
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
                .disabled(zoom <= 0.8)
                .accessibilityIdentifier("reference-sheet-zoom-out")
            Text("\(Int((zoom * 100).rounded()))%") // l10n: verbatim
                .font(DesignTokens.FontScale.caption.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.inkMuted)
                .monospacedDigit()
            Button("Zoom in") { zoom = min(1.8, zoom + 0.1) } // l10n: localized
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
                .disabled(zoom >= 1.8)
                .accessibilityIdentifier("reference-sheet-zoom-in")
    }

    private func loadDocument() {
        guard document == nil else { return }
        document = try? ReferenceSheetLoader.load(configuration: configuration)
    }
}
