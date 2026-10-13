import Accessibility
import CanadianHamCalculatorEngine
import CanadianHamContent
import SwiftUI

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

    private var isPresented: Binding<Bool> {
        Binding(
            get: { selectedTool != nil },
            set: {
                if !$0 {
                    calculatorFocused = false
                    calculator.suspendHardwareKeyboardInput()
                    selectedTool = nil
                }
            }
        )
    }

    func body(content: Content) -> some View {
#if os(iOS)
        if horizontalUsesInspector {
            content.inspector(isPresented: isPresented) {
                toolPanel
                    .inspectorColumnWidth(min: 320, ideal: 380, max: 460)
            }
        } else {
            content
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
        content.inspector(isPresented: isPresented) {
            toolPanel
                .inspectorColumnWidth(min: 320, ideal: 380, max: 460)
        }
#else
        content
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
        let roundedHeight = height.rounded(.toNearestOrAwayFromZero)
        Task { @MainActor in
            guard abs(compactSheetHeight - roundedHeight) >= 1 else { return }
            compactSheetHeight = roundedHeight
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
    }

    private func toolTitleRow(for tool: ExamTool) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            Image(systemName: tool.systemImage)
                .font(DesignTokens.FontScale.body.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .frame(width: 44, height: 44)
                .accessibilityLabel(Text(tool.title)) // l10n: localized

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
        GeometryReader { proxy in
            let bodyHeight = availableToolBodyHeight(panelHeight: proxy.size.height)
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                toolHeader(for: tool)

                Divider()

                toolBody(for: tool, availableHeight: bodyHeight)
                    .frame(maxWidth: .infinity, maxHeight: bodyHeight, alignment: .topLeading)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.md)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(DesignTokens.Colors.paper)
    }

    private func availableToolBodyHeight(panelHeight: CGFloat) -> CGFloat {
        max(220, panelHeight - (dynamicTypeSize.isAccessibilitySize ? 184 : 128))
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

private extension View {
    @ViewBuilder
    func calculatorKeyPressHandler(enabled: Bool, perform action: @escaping (KeyPress) -> KeyPress.Result) -> some View {
        if enabled {
            onKeyPress(action: action)
        } else {
            self
        }
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
        .accessibilityIdentifier(calculatorFocused && hasKeyboardFocus ? "calculator-keyboard-focus-target-focused" : "calculator-keyboard-focus-target")
        .focusable(true)
        .focused($hasKeyboardFocus)
        .onAppear {
            Task { @MainActor in
                activateKeyboardFocus()
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
        .onChange(of: hasKeyboardFocus) { _, isFocused in
            if !isFocused {
                if calculatorFocused {
                    calculatorFocused = false
                }
                viewModel.suspendHardwareKeyboardInput()
            }
        }
        .calculatorKeyPressHandler(enabled: calculatorFocused && hasKeyboardFocus) { press in
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
        let announcement = viewModel.press(key)
        AccessibilityNotification.Announcement(announcement).post()
    }

    private func handleKeyPress(_ press: KeyPress) -> KeyPress.Result {
        guard calculatorFocused, hasKeyboardFocus, viewModel.acceptsHardwareKeyboardInput, let key = calculatorKey(for: press) else { return .ignored }
        Task { @MainActor in
            pressKey(key)
        }
        return .handled
    }

    private func calculatorKey(for press: KeyPress) -> CalculatorKey? {
        guard press.modifiers.subtracting(.shift).isEmpty else { return nil }
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
        if press.modifiers.contains(.shift) {
            switch press.characters {
            case "=": return .add
            case "8": return .multiply
            case "5": return .percent
            default: break
            }
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
        case "-", "−": return .subtract
        case "*", "×", "x", "X": return .multiply
        case "/", "÷": return .divide
        case "=": return .equals
        case "%": return .percent
        case "r", "R", "√": return .squareRoot
        case "s", "S": return .square
        case "i", "I": return .reciprocal
        case "n", "N": return .toggleSign
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
        case .toggleSign: String(localized: "Toggle sign")
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
        dynamicTypeSize.isAccessibilitySize || compactKeyHeight < 44
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
    private var compactKeySpacing: CGFloat { 4 }
    private var compactDisplayHeight: CGFloat { 46 }
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

                LessonMarkdownView(markdown: document.markdown, title: "Original Basic formula and reference study aid", textScale: zoom)
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
