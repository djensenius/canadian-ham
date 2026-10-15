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
