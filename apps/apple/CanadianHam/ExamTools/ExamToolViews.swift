import Accessibility
import CanadianHamCalculatorEngine
import CanadianHamContent
import SwiftUI

struct ExamToolButtons: View {
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
        toolButton(.calculator)
        toolButton(.referenceSheet)
    }

    @ViewBuilder
    private func toolButton(_ tool: ExamTool) -> some View {
        switch tool {
        case .calculator:
            Button { openTool(tool) } label: {
                AccessibleSecondaryButtonLabel(title: "Calculator")
            }
            .buttonStyle(AccessibleSecondaryButtonStyle())
            .accessibilityIdentifier("exam-tool-\(tool.rawValue)-button")
        case .referenceSheet:
            Button { openTool(tool) } label: {
                AccessibleSecondaryButtonLabel(title: "Reference sheet")
            }
            .buttonStyle(AccessibleSecondaryButtonStyle())
            .accessibilityIdentifier("exam-tool-\(tool.rawValue)-button")
        }
    }
}

struct ExamToolPresentationModifier: ViewModifier {
    @Binding var selectedTool: ExamTool?
    @ObservedObject var calculator: ExamCalculatorViewModel
    let referenceSheetConfiguration: ReferenceSheetConfiguration
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedSheetDetent = PresentationDetent.medium

    private var isPresented: Binding<Bool> {
        Binding(
            get: { selectedTool != nil },
            set: { if !$0 { selectedTool = nil } }
        )
    }

    func body(content: Content) -> some View {
#if os(iOS)
        if horizontalUsesInspector {
            content.inspector(isPresented: isPresented) {
                toolPanel(fillsAvailableHeight: true)
                    .inspectorColumnWidth(min: 320, ideal: 380, max: 460)
            }
        } else {
            content.sheet(item: $selectedTool) { tool in
                toolPanel(for: tool, fillsAvailableHeight: true)
                    .presentationDetents([.medium, .large], selection: $selectedSheetDetent)
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                    .presentationDragIndicator(.visible)
                    .onAppear { selectedSheetDetent = preferredSheetDetent(for: tool) }
                    .onChange(of: dynamicTypeSize) { _, _ in selectedSheetDetent = preferredSheetDetent(for: tool) }
            }
        }
#elseif os(macOS)
        content.inspector(isPresented: isPresented) {
            toolPanel(fillsAvailableHeight: true)
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
        tool == .calculator && dynamicTypeSize.isAccessibilitySize ? .large : .medium
    }
#endif

    @ViewBuilder
    private func toolPanel(fillsAvailableHeight: Bool) -> some View {
        Group {
            if let selectedTool {
                toolPanel(for: selectedTool, fillsAvailableHeight: fillsAvailableHeight)
            } else {
                EmptyView()
            }
        }
    }

    private func toolTitle(for tool: ExamTool) -> LocalizedStringResource {
        switch tool {
        case .calculator: "Calculator"
        case .referenceSheet: "Reference sheet"
        }
    }

    private func toolHeader(for tool: ExamTool) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: tool.systemImage)
                .imageScale(.large)
            Text(toolTitle(for: tool)) // l10n: localized
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
        .font(DesignTokens.FontScale.body.weight(.bold))
        .frame(minHeight: 44, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(toolTitle(for: tool))) // l10n: localized
    }

    private func toolPanel(for tool: ExamTool, fillsAvailableHeight: Bool) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack(alignment: .center) {
                toolHeader(for: tool)
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier(tool.accessibilityIdentifier)
                Spacer(minLength: DesignTokens.Spacing.sm)
                Button {
                    selectedTool = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(DesignTokens.FontScale.body.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .frame(width: 44, height: 44)
                        .background(DesignTokens.Colors.paperInset, in: Circle())
                        .overlay(Circle().strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Close tools")) // l10n: localized
                .accessibilityIdentifier("exam-tool-close-button")
            }

            switch tool {
            case .calculator:
                CalculatorToolView(viewModel: calculator)
                    .layoutPriority(1)
            case .referenceSheet:
                ReferenceSheetToolView(configuration: referenceSheetConfiguration)
                    .layoutPriority(1)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: fillsAvailableHeight ? .infinity : nil, alignment: .topLeading)
        .background(DesignTokens.Colors.paper)
    }
}

extension View {
    func examToolPresentation(
        selectedTool: Binding<ExamTool?>,
        calculator: ExamCalculatorViewModel,
        referenceSheetConfiguration: ReferenceSheetConfiguration = .basic
    ) -> some View {
        modifier(ExamToolPresentationModifier(selectedTool: selectedTool, calculator: calculator, referenceSheetConfiguration: referenceSheetConfiguration))
    }
}

struct CalculatorToolView: View {
    @ObservedObject var viewModel: ExamCalculatorViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 44), spacing: layout.keySpacing), count: 4), spacing: layout.keySpacing) {
                ForEach(rows.flatMap { $0 }, id: \.rawValue) { key in
                    calculatorButton(key, layout: layout)
                }
            }
            .accessibilityIdentifier("calculator-key-grid")

            if layout.showsHelpText {
                Text("No formulas, text, or history saved.")
                    .font(DesignTokens.FontScale.caption)
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
    }

    private func calculatorButton(_ key: CalculatorKey, layout: CalculatorToolLayout) -> some View {
        Button {
            let announcement = viewModel.press(key)
            AccessibilityNotification.Announcement(announcement).post()
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
        .modifier(CalculatorKeyboardShortcut(key: key))
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
    var keyHeight: CGFloat { usesScrolling ? 64 : max(44, compactKeyHeight) }
    var displayFont: Font { (usesScrolling ? DesignTokens.FontScale.display : DesignTokens.FontScale.title).monospacedDigit().weight(.bold) }
    var keyFont: Font { (usesScrolling ? DesignTokens.FontScale.body : DesignTokens.FontScale.caption).weight(.semibold) }
    var showsHelpText: Bool { !usesScrolling && showsCompactHelpText }

    var usesScrolling: Bool {
        dynamicTypeSize.isAccessibilitySize || compactKeyHeight < 44
    }

    private var compactKeyHeight: CGFloat {
        let displayTotal = compactDisplayHeight + (compactDisplayVerticalPadding * 2)
        let helpTotal: CGFloat = showsCompactHelpText ? 18 + compactSectionSpacing : 0
        let gridSpacing = compactKeySpacing * CGFloat(rowCount - 1)
        let gridHeight = max(0, availableHeight - displayTotal - compactSectionSpacing - helpTotal)
        return (gridHeight - gridSpacing) / CGFloat(rowCount)
    }

    private var showsCompactHelpText: Bool {
        !dynamicTypeSize.isAccessibilitySize && availableHeight >= 390
    }

    private var compactSectionSpacing: CGFloat { 6 }
    private var compactKeySpacing: CGFloat { 4 }
    private var compactDisplayHeight: CGFloat { 46 }
    private var compactDisplayVerticalPadding: CGFloat { 4 }
    private var rowCount: Int { 6 }
}

private struct CalculatorKeyboardShortcut: ViewModifier {
    let key: CalculatorKey

    func body(content: Content) -> some View {
        switch key {
        case .zero: content.keyboardShortcut("0", modifiers: [])
        case .one: content.keyboardShortcut("1", modifiers: [])
        case .two: content.keyboardShortcut("2", modifiers: [])
        case .three: content.keyboardShortcut("3", modifiers: [])
        case .four: content.keyboardShortcut("4", modifiers: [])
        case .five: content.keyboardShortcut("5", modifiers: [])
        case .six: content.keyboardShortcut("6", modifiers: [])
        case .seven: content.keyboardShortcut("7", modifiers: [])
        case .eight: content.keyboardShortcut("8", modifiers: [])
        case .nine: content.keyboardShortcut("9", modifiers: [])
        case .decimalPoint: content.keyboardShortcut(".", modifiers: [])
        case .add: content.keyboardShortcut("+", modifiers: [])
        case .subtract: content.keyboardShortcut("-", modifiers: [])
        case .multiply: content.keyboardShortcut("*", modifiers: [])
        case .divide: content.keyboardShortcut("/", modifiers: [])
        case .equals: content.keyboardShortcut(.return, modifiers: [])
        case .squareRoot: content.keyboardShortcut("r", modifiers: [])
        case .square: content.keyboardShortcut("s", modifiers: [])
        case .reciprocal: content.keyboardShortcut("i", modifiers: [])
        case .toggleSign: content.keyboardShortcut("n", modifiers: [])
        case .percent: content.keyboardShortcut("%", modifiers: [])
        case .clearEntry: content.keyboardShortcut("c", modifiers: [])
        case .allClear: content.keyboardShortcut("a", modifiers: [])
        case .backspace: content.keyboardShortcut(.delete, modifiers: [])
        }
    }
}

struct ReferenceSheetToolView: View {
    let configuration: ReferenceSheetConfiguration
    @State private var document: ReferenceSheetDocument?
    @State private var zoom = 1.0

    var body: some View {
        Group {
            if let document {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    zoomControls
                    ScrollView([.vertical, .horizontal]) {
                        ExamToolMarkdownView(markdown: document.markdown, title: String(localized: "Basic reference sheet"))
                            .scaleEffect(zoom, anchor: .topLeading)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(.bottom, DesignTokens.Spacing.xl)
                    }
                    .scrollIndicators(.hidden)
                    .accessibilityLabel(Text("Basic reference sheet")) // l10n: localized
                    .accessibilityIdentifier("reference-sheet-scroll")
                }
            } else {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Label {
                        Text("Reference sheet unavailable")
                            .font(DesignTokens.FontScale.title.weight(.bold))
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "doc.text.magnifyingglass")
                    }
                    Text("The bundled Basic reference sheet is not installed in this build.")
                        .font(DesignTokens.FontScale.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(DesignTokens.Colors.ink)
                .padding(DesignTokens.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("reference-sheet-unavailable")
            }
        }
        .task { loadDocument() }
    }

    private var zoomControls: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Button {
                zoom = max(0.8, zoom - 0.1)
            } label: {
                AccessibleSecondaryButtonLabel(title: "Zoom out")
            }
            .buttonStyle(AccessiblePrimaryButtonStyle())
            .disabled(zoom <= 0.8)
            .accessibilityIdentifier("reference-sheet-zoom-out")

            Button {
                zoom = min(1.8, zoom + 0.1)
            } label: {
                AccessibleSecondaryButtonLabel(title: "Zoom in")
            }
            .buttonStyle(AccessiblePrimaryButtonStyle())
            .disabled(zoom >= 1.8)
            .accessibilityIdentifier("reference-sheet-zoom-in")
        }
    }

    private func loadDocument() {
        guard document == nil else { return }
        document = try? ReferenceSheetLoader.load(configuration: configuration)
    }
}

private struct ExamToolMarkdownView: View {
    let markdown: String
    let title: String?

    var body: some View {
        let rendered = (try? LessonMarkdownRenderer.render(markdown)) ?? RenderedLessonMarkdown(blocks: [.paragraph(AttributedString(markdown))])
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            ForEach(Array(rendered.blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func blockView(_ block: LessonBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            if !(level == 1 && title != nil && plainString(text) == title) {
                Text(strippingLinks(from: text)) // l10n: content(en)
                    .font(level <= 2 ? DesignTokens.FontScale.title.weight(.bold) : DesignTokens.FontScale.bodyLarge.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
            }
        case .paragraph(let text):
            Text(strippingLinks(from: text)) // l10n: content(en)
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
        case .list(let ordered, let items):
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                        Text(ordered ? "\(index + 1)." : "•") // l10n: verbatim
                            .font(DesignTokens.FontScale.body.weight(.semibold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                        Text(strippingLinks(from: item)) // l10n: content(en)
                            .font(DesignTokens.FontScale.body)
                            .foregroundStyle(DesignTokens.Colors.ink)
                    }
                }
            }
        case .code(_, let text):
            ScrollView(.horizontal) {
                Text(AttributedString(text)) // l10n: content(en)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .padding(DesignTokens.Spacing.sm)
            }
            .scrollIndicators(.hidden)
            .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous))
        case .table(let table):
            ExamToolMarkdownTableView(table: table)
        case .illustrationBrief(let brief):
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Illustration brief")
                    .font(DesignTokens.FontScale.body.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                Text(AttributedString(brief.description)) // l10n: content(en)
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.ink)
                Text(AttributedString(brief.altText)) // l10n: content(en)
                    .font(DesignTokens.FontScale.caption)
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        case .blockquote(let text):
            Text(strippingLinks(from: text)) // l10n: content(en)
                .font(DesignTokens.FontScale.body.italic())
                .foregroundStyle(DesignTokens.Colors.ink)
                .padding(.leading, DesignTokens.Spacing.md)
        }
    }

    private func strippingLinks(from value: AttributedString) -> AttributedString {
        var copy = value
        let ranges = copy.runs.map(\.range)
        for range in ranges {
            copy[range].link = nil
        }
        return copy
    }

    private func plainString(_ value: AttributedString) -> String {
        String(value.characters)
    }
}

private struct ExamToolMarkdownTableView: View {
    let table: MarkdownTable

    var body: some View {
        ScrollView(.horizontal) {
            Grid(alignment: .leading, horizontalSpacing: DesignTokens.Spacing.md, verticalSpacing: DesignTokens.Spacing.sm) {
                GridRow {
                    ForEach(Array(table.headers.enumerated()), id: \.offset) { _, header in
                        Text(header) // l10n: content(en)
                            .font(DesignTokens.FontScale.body.weight(.bold))
                            .foregroundColor(DesignTokens.Colors.ink)
                    }
                }
                ForEach(Array(table.rows.enumerated()), id: \.offset) { _, row in
                    GridRow {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                            Text(cell) // l10n: content(en)
                                .font(DesignTokens.FontScale.body)
                                .foregroundColor(DesignTokens.Colors.ink)
                        }
                    }
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
        .scrollIndicators(.hidden)
        .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Reference sheet table")) // l10n: localized
    }
}
