import CanadianHamCalculatorEngine
import Foundation
#if os(iOS)
import UIKit
#endif
import SwiftUI

enum ExamTool: String, CaseIterable, Identifiable {
    case calculator
    case referenceSheet

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .calculator: "Calculator"
        case .referenceSheet: "Reference sheet"
        }
    }

    var systemImage: String {
        switch self {
        case .calculator: "plus.forwardslash.minus"
        case .referenceSheet: "doc.text.magnifyingglass"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .calculator: "exam-tool-calculator-panel"
        case .referenceSheet: "exam-tool-reference-sheet-panel"
        }
    }
}

@MainActor
final class ExamCalculatorViewModel: ObservableObject {
    @Published private(set) var state: CalculatorState
    @Published private(set) var acceptsHardwareKeyboardInput = false

    init(locale: CalculatorLocale = .en) {
        state = createCalculatorState(locale: locale)
    }

    var display: String { state.display }
    var displayValue: CalculatorDisplayValue { state.displayValue }
    var locale: CalculatorLocale { state.locale }

    var spokenResult: String {
        spokenResult(for: state.locale)
    }

    func spokenResult(for locale: CalculatorLocale) -> String {
        switch locale {
        case .en: state.displayValue.spoken.en
        case .fr: state.displayValue.spoken.fr
        }
    }

    @discardableResult
    func press(_ key: CalculatorKey) -> String {
        state = applyCalculatorKey(state, key: key)
        return spokenResult
    }

    func clearForNewExam(locale: CalculatorLocale? = nil) {
        suspendHardwareKeyboardInput()
        state = createCalculatorState(locale: locale ?? state.locale)
    }

    func acceptHardwareKeyboardInput() {
        guard !acceptsHardwareKeyboardInput else { return }
        acceptsHardwareKeyboardInput = true
    }

    func suspendHardwareKeyboardInput() {
        if acceptsHardwareKeyboardInput {
            acceptsHardwareKeyboardInput = false
        }
#if os(iOS)
        resignPlatformKeyboardFocus()
#endif
    }

#if os(iOS)
    private func resignPlatformKeyboardFocus() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
#endif

    func updateLocale(_ locale: CalculatorLocale) {
        state = updateCalculatorLocale(state, locale: locale)
    }
}

func canadianHamInterfaceCalculatorLocale(bundle: Bundle = .main) -> CalculatorLocale {
    bundle.preferredLocalizations.first?.lowercased().hasPrefix("fr") == true ? .fr : .en
}


struct CalculatorToolLayout {
    let availableHeight: CGFloat
    let dynamicTypeSize: DynamicTypeSize
    var forceScrolling = false

    var sectionSpacing: CGFloat { usesAccessibilityMetrics ? accessibilitySectionSpacing : compactSectionSpacing }
    var keySpacing: CGFloat { usesAccessibilityMetrics ? accessibilityKeySpacing : compactKeySpacing }
    var displayHeight: CGFloat { usesAccessibilityMetrics ? accessibilityDisplayHeight : compactDisplayHeight }
    var displayHorizontalPadding: CGFloat { usesAccessibilityMetrics ? accessibilityDisplayHorizontalPadding : compactDisplayHorizontalPadding }
    var displayVerticalPadding: CGFloat { usesAccessibilityMetrics ? accessibilityDisplayVerticalPadding : compactDisplayVerticalPadding }
    var keyHeight: CGFloat { usesAccessibilityMetrics ? accessibilityKeyHeight : min(accessibilityKeyHeight, max(minimumKeyHeight, compactKeyHeight)) }
    var showsHelpText: Bool { !usesScrolling && showsCompactHelpText }

    var usesScrolling: Bool {
        forceScrolling || usesAccessibilityMetrics || compactContentHeightAtMinimumTargets + compactMinimumFitAllowance > availableHeight
    }

    var usesAccessibilityMetrics: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    private var compactKeyHeight: CGFloat {
        let gridHeight = max(0, availableHeight - compactNonGridContentHeight)
        return (gridHeight - compactGridSpacing) / CGFloat(rowCount)
    }

    private var compactContentHeightAtMinimumTargets: CGFloat {
        compactNonGridContentHeight + (minimumKeyHeight * CGFloat(rowCount)) + compactGridSpacing
    }

    private var compactNonGridContentHeight: CGFloat {
        let displayTotal = compactDisplayHeight + (compactDisplayVerticalPadding * 2)
        let helpTotal = showsCompactHelpText ? compactEstimatedHelpHeight + compactSectionSpacing : 0
        return displayTotal + compactSectionSpacing + helpTotal
    }

    private var compactGridSpacing: CGFloat {
        compactKeySpacing * CGFloat(rowCount - 1)
    }

    private var showsCompactHelpText: Bool {
        guard !usesAccessibilityMetrics, availableHeight >= compactHelpVisibilityHeight else { return false }
        return compactContentHeightWithEstimatedHelp <= availableHeight
    }

    private var compactContentHeightWithEstimatedHelp: CGFloat {
        let displayTotal = compactDisplayHeight + (compactDisplayVerticalPadding * 2)
        let helpTotal = compactEstimatedHelpHeight + compactSectionSpacing
        return displayTotal + compactSectionSpacing + helpTotal + (minimumKeyHeight * CGFloat(rowCount)) + compactGridSpacing
    }

    private var compactEstimatedHelpHeight: CGFloat {
        // The keyboard-help caption wraps at xxxLarge in the medium sheet; reserve measured line counts
        // instead of the old fixed 48 pt so showing it never forces keys below their 44 pt target.
        compactEstimatedHelpLineHeight * compactEstimatedHelpLineCount
    }

    private var compactEstimatedHelpLineHeight: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium:
            return 16
        case .large, .xLarge:
            return 18
        case .xxLarge:
            return 20
        case .xxxLarge:
            return 22
        default:
            return 22
        }
    }

    private var compactEstimatedHelpLineCount: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium, .large, .xLarge:
            return 3
        case .xxLarge:
            return 4
        default:
            return 5
        }
    }

    private var accessibilitySectionSpacing: CGFloat { 12 }
    private var accessibilityKeySpacing: CGFloat { 8 }
    private var accessibilityDisplayHeight: CGFloat { 72 }
    private var accessibilityDisplayHorizontalPadding: CGFloat { 16 }
    private var accessibilityDisplayVerticalPadding: CGFloat { 16 }
    private var accessibilityKeyHeight: CGFloat { 64 }
    private var compactSectionSpacing: CGFloat { 6 }
    private var compactKeySpacing: CGFloat { 6 }
    private var compactDisplayHeight: CGFloat { 48 }
    private var compactDisplayHorizontalPadding: CGFloat { 12 }
    private var compactDisplayVerticalPadding: CGFloat { 4 }
    private var compactHelpVisibilityHeight: CGFloat { 440 }
    // Measured allowance for LazyVGrid/VStack compression and sheet-height rounding at the iPhone medium detent.
    // Without this headroom, XCTest observed 42.25 pt key frames even though the pure minimums sum to 356 pt.
    private var compactMinimumFitAllowance: CGFloat { 24 }
    private var minimumKeyHeight: CGFloat { 44 }
    private var rowCount: Int { 6 }
}

struct ReferenceSheetConfiguration: Equatable, Sendable {
    let resourceName: String
    let resourceExtension: String
    let subdirectory: String?
    let availableOnApple: Bool

    static let defaultAvailableOnApple = false

    init(resourceName: String, resourceExtension: String, subdirectory: String?, availableOnApple: Bool = Self.defaultAvailableOnApple) {
        self.resourceName = resourceName
        self.resourceExtension = resourceExtension
        self.subdirectory = subdirectory
        self.availableOnApple = availableOnApple
    }

    static let basic = ReferenceSheetConfiguration(
        resourceName: "basic",
        resourceExtension: "md",
        subdirectory: "reference-sheet"
    )
}

struct ReferenceSheetDocument: Equatable, Sendable {
    let markdown: String
    let sourceURL: URL
}

enum ReferenceSheetLoader {
    static func load(configuration: ReferenceSheetConfiguration = .basic, bundle: Bundle = .main) throws -> ReferenceSheetDocument? {
        guard let url = bundle.url(
            forResource: configuration.resourceName,
            withExtension: configuration.resourceExtension,
            subdirectory: configuration.subdirectory
        ) else {
            return nil
        }
        return ReferenceSheetDocument(markdown: try String(contentsOf: url, encoding: .utf8), sourceURL: url)
    }
}

extension BankLanguage {
    var calculatorLocale: CalculatorLocale {
        switch self {
        case .english: .en
        case .french: .fr
        }
    }
}
