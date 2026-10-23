import CanadianHamCalculatorEngine
import Foundation
#if os(iOS)
import UIKit
#endif
import SwiftUI

enum ExamTool: String, CaseIterable, Identifiable {
    case calculator
    case hint
    case referenceSheet

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .calculator: "Calculator"
        case .hint: "Hint"
        case .referenceSheet: "Reference sheet"
        }
    }

    var systemImage: String {
        switch self {
        case .calculator: "plus.forwardslash.minus"
        case .hint: "lightbulb"
        case .referenceSheet: "doc.text.magnifyingglass"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .calculator: "exam-tool-calculator-panel"
        case .hint: "exam-tool-hint-panel"
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

struct AdaptiveExamLayoutPolicy {
    static func usesRegularWidthIPhoneLayout(
        idiom: PlatformUserInterfaceIdiom,
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?
    ) -> Bool {
        guard idiom == .phone else { return false }
        return horizontalSizeClass == .regular && verticalSizeClass != .compact
    }

    static func usesInspectorPresentation(
        idiom: PlatformUserInterfaceIdiom,
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?
    ) -> Bool {
        switch idiom {
        case .pad:
            return horizontalSizeClass == .regular
        case .phone:
            return usesRegularWidthIPhoneLayout(
                idiom: idiom,
                horizontalSizeClass: horizontalSizeClass,
                verticalSizeClass: verticalSizeClass
            )
        case .mac, .other:
            return false
        }
    }
}

enum PlatformUserInterfaceIdiom: Equatable {
    case phone
    case pad
    case mac
    case other

#if os(iOS)
    init(_ idiom: UIUserInterfaceIdiom) {
        switch idiom {
        case .phone:
            self = .phone
        case .pad:
            self = .pad
        case .mac:
            self = .mac
        default:
            self = .other
        }
    }
#endif
}

struct CalculatorToolLayout {
    enum ContentMode: Equatable {
        case fitting(showsHelpText: Bool, keyHeight: CGFloat)
        case scrolling(showsHelpText: Bool)
    }

    static let expandedKeyHeight: CGFloat = 64
    // SwiftUI reports the button accessibility frame slightly smaller than the requested label frame;
    // a 46 pt layout floor preserves the user-facing 44 pt minimum in UI tests.
    static let minimumKeyHeight: CGFloat = 46
    static let fittingCandidateContentModes: [ContentMode] = [
        .fitting(showsHelpText: true, keyHeight: expandedKeyHeight),
        .fitting(showsHelpText: false, keyHeight: expandedKeyHeight),
        .fitting(showsHelpText: true, keyHeight: minimumKeyHeight),
        .fitting(showsHelpText: false, keyHeight: minimumKeyHeight),
    ]

    let dynamicTypeSize: DynamicTypeSize
    let contentMode: ContentMode

    init(dynamicTypeSize: DynamicTypeSize, contentMode: ContentMode = .fitting(showsHelpText: false, keyHeight: Self.minimumKeyHeight)) {
        self.dynamicTypeSize = dynamicTypeSize
        self.contentMode = contentMode
    }

    var sectionSpacing: CGFloat { usesAccessibilityMetrics ? accessibilitySectionSpacing : compactSectionSpacing }
    var keySpacing: CGFloat { usesAccessibilityMetrics ? accessibilityKeySpacing : compactKeySpacing }
    var displayHeight: CGFloat { usesAccessibilityMetrics ? accessibilityDisplayHeight : compactDisplayHeight }
    var displayHorizontalPadding: CGFloat { usesAccessibilityMetrics ? accessibilityDisplayHorizontalPadding : compactDisplayHorizontalPadding }
    var displayVerticalPadding: CGFloat { usesAccessibilityMetrics ? accessibilityDisplayVerticalPadding : compactDisplayVerticalPadding }
    var keyHeight: CGFloat {
        if usesAccessibilityMetrics { return accessibilityKeyHeight }
        switch contentMode {
        case .fitting(_, let keyHeight):
            return max(Self.minimumKeyHeight, keyHeight)
        case .scrolling:
            return Self.scrollingKeyHeight
        }
    }
    var showsHelpText: Bool {
        guard !usesAccessibilityMetrics else { return false }
        switch contentMode {
        case .fitting(let showsHelpText, _), .scrolling(let showsHelpText):
            return showsHelpText
        }
    }

    var usesScrolling: Bool {
        if usesAccessibilityMetrics { return true }
        switch contentMode {
        case .fitting:
            return false
        case .scrolling:
            return true
        }
    }

    var usesAccessibilityMetrics: Bool {
        dynamicTypeSize.isAccessibilitySize
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
    private static var scrollingKeyHeight: CGFloat { minimumKeyHeight }
}

struct ReferenceSheetConfiguration: Equatable, Sendable {
    let resourceName: String
    let resourceExtension: String
    let subdirectory: String?
    let availableOnApple: Bool

    static let defaultAvailableOnApple = true

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

struct OfficialReferenceSheetDocument: Sendable {
    let markdown: String
    let pages: [URL]
}

enum OfficialReferenceSheetLoader {
    static var isEnabled: Bool {
#if OFFICIAL_REFERENCE_SHEET
        true
#else
        false
#endif
    }

    static func load(bundle: Bundle = .main) throws -> OfficialReferenceSheetDocument? {
#if OFFICIAL_REFERENCE_SHEET
        guard let transcript = bundle.url(forResource: "text-equivalent", withExtension: "md", subdirectory: "official-basic-exam") else { return nil }
        let pages = (1...5).compactMap { bundle.url(forResource: "page-\($0)", withExtension: "png", subdirectory: "official-basic-exam") }
        guard pages.count == 5 else { return nil }
        return OfficialReferenceSheetDocument(markdown: try String(contentsOf: transcript, encoding: .utf8), pages: pages)
#else
        return nil
#endif
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
