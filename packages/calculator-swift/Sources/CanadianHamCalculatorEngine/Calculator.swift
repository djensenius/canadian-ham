import Foundation

public enum CalculatorLocale: String, Codable, Sendable {
    case en
    case fr
}

public enum CalculatorKey: String, Codable, Sendable {
    case zero = "0"
    case one = "1"
    case two = "2"
    case three = "3"
    case four = "4"
    case five = "5"
    case six = "6"
    case seven = "7"
    case eight = "8"
    case nine = "9"
    case decimalPoint = "."
    case add = "+"
    case subtract = "-"
    case multiply = "×"
    case divide = "÷"
    case equals = "="
    case squareRoot = "√"
    case square = "x²"
    case reciprocal = "1/x"
    case toggleSign = "±"
    case percent = "%"
    case clearEntry = "C/CE"
    case allClear = "AC"
    case backspace = "backspace"

    var digit: String? {
        switch self {
        case .zero: return "0"
        case .one: return "1"
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        default: return nil
        }
    }

    var binaryOperator: CalculatorBinaryOperator? {
        switch self {
        case .add: return .add
        case .subtract: return .subtract
        case .multiply: return .multiply
        case .divide: return .divide
        default: return nil
        }
    }
}

public enum CalculatorBinaryOperator: String, Codable, Sendable {
    case add = "+"
    case subtract = "-"
    case multiply = "×"
    case divide = "÷"
}

public struct CalculatorLastOperation: Codable, Equatable, Sendable {
    public let `operator`: CalculatorBinaryOperator
    public let rightOperand: Double

    public init(operator: CalculatorBinaryOperator, rightOperand: Double) {
        self.operator = `operator`
        self.rightOperand = rightOperand
    }
}

public struct CalculatorState: Codable, Equatable, Sendable {
    public let locale: CalculatorLocale
    public let display: String
    public let error: Bool
    public let accumulator: Double?
    public let pendingOperator: CalculatorBinaryOperator?
    public let currentEntry: String
    public let entering: Bool
    public let displayedValue: Double
    public let awaitingOperand: Bool
    public let lastOperation: CalculatorLastOperation?
    public let justEvaluated: Bool

    public init(
        locale: CalculatorLocale = .en,
        display: String = "0",
        error: Bool = false,
        accumulator: Double? = nil,
        pendingOperator: CalculatorBinaryOperator? = nil,
        currentEntry: String = "0",
        entering: Bool = false,
        displayedValue: Double = 0,
        awaitingOperand: Bool = false,
        lastOperation: CalculatorLastOperation? = nil,
        justEvaluated: Bool = false
    ) {
        self.locale = locale
        self.display = display
        self.error = error
        self.accumulator = accumulator
        self.pendingOperator = pendingOperator
        self.currentEntry = currentEntry
        self.entering = entering
        self.displayedValue = displayedValue
        self.awaitingOperand = awaitingOperand
        self.lastOperation = lastOperation
        self.justEvaluated = justEvaluated
    }
}

private let maxSignificantDigits = 12
private let resultSignificantDigits = 15
private let posixLocale = Locale(identifier: "en_US_POSIX")

public func createCalculatorState(locale: CalculatorLocale = .en) -> CalculatorState {
    withDisplay(CalculatorState(locale: locale))
}

public func runCalculatorKeys(_ keys: [CalculatorKey], locale: CalculatorLocale = .en) -> CalculatorState {
    keys.reduce(createCalculatorState(locale: locale)) { state, key in
        applyCalculatorKey(state, key: key)
    }
}

public func applyCalculatorKey(_ state: CalculatorState, key: CalculatorKey) -> CalculatorState {
    if key == .allClear {
        return createCalculatorState(locale: state.locale)
    }

    if state.error {
        if let digit = key.digit {
            return inputDigit(createCalculatorState(locale: state.locale), digit)
        }
        return state
    }

    if let digit = key.digit {
        return inputDigit(state, digit)
    }

    if key == .decimalPoint {
        return inputDecimalPoint(state)
    }

    if let binaryOperator = key.binaryOperator {
        return inputBinaryOperator(state, binaryOperator)
    }

    switch key {
    case .equals:
        return inputEquals(state)
    case .squareRoot:
        return applyUnaryOperation(state) { value in value < 0 ? nil : Foundation.sqrt(value) }
    case .square:
        return applyUnaryOperation(state) { value in value * value }
    case .reciprocal:
        return applyUnaryOperation(state) { value in value == 0 ? nil : 1 / value }
    case .toggleSign:
        return toggleSign(state)
    case .percent:
        return applyPercent(state)
    case .clearEntry:
        return clearEntry(state)
    case .backspace:
        return backspace(state)
    default:
        return state
    }
}

public func displayCalculatorValue(_ value: Double, locale: CalculatorLocale = .en) -> String {
    guard value.isFinite else { return "Error" }

    let normalizedValue = value == 0 ? 0 : value
    let absoluteValue = abs(normalizedValue)
    if absoluteValue == 0 {
        return "0"
    }

    let scientific = absoluteValue >= 999_999_999_999.5 || absoluteValue < 1e-9
    let raw: String
    if scientific {
        raw = normalizeScientific(String(format: "%.\(maxSignificantDigits - 1)e", locale: posixLocale, normalizedValue))
    } else {
        raw = normalizeFixed(String(format: "%.\(fractionDigits(for: absoluteValue))f", locale: posixLocale, normalizedValue))
    }
    return localizeDecimalSeparator(raw, locale: locale)
}

private func inputDigit(_ state: CalculatorState, _ digit: String) -> CalculatorState {
    let base = state.justEvaluated && state.pendingOperator == nil ? createCalculatorState(locale: state.locale) : state
    let entry: String
    if !base.entering {
        entry = digit
    } else if base.currentEntry == "0" {
        entry = digit
    } else if base.currentEntry == "-0" {
        entry = digit == "0" ? "-0" : "-\(digit)"
    } else {
        entry = "\(base.currentEntry)\(digit)"
    }
    return withDisplay(CalculatorState(
        locale: base.locale,
        error: base.error,
        accumulator: base.accumulator,
        pendingOperator: base.pendingOperator,
        currentEntry: entry,
        entering: true,
        displayedValue: number(fromEntry: entry),
        awaitingOperand: false,
        lastOperation: base.lastOperation,
        justEvaluated: false
    ))
}

private func inputDecimalPoint(_ state: CalculatorState) -> CalculatorState {
    let base = state.justEvaluated && state.pendingOperator == nil ? createCalculatorState(locale: state.locale) : state
    if !base.entering {
        return withDisplay(CalculatorState(
            locale: base.locale,
            error: base.error,
            accumulator: base.accumulator,
            pendingOperator: base.pendingOperator,
            currentEntry: "0.",
            entering: true,
            displayedValue: 0,
            awaitingOperand: false,
            lastOperation: base.lastOperation,
            justEvaluated: false
        ))
    }
    if base.currentEntry.contains(".") {
        return base
    }
    let entry = "\(base.currentEntry)."
    return replacing(base, currentEntry: entry, entering: true, displayedValue: number(fromEntry: entry), awaitingOperand: false, justEvaluated: false)
}

private func inputBinaryOperator(_ state: CalculatorState, _ binaryOperator: CalculatorBinaryOperator) -> CalculatorState {
    let currentValue = currentValue(for: state)
    if let pendingOperator = state.pendingOperator, let accumulator = state.accumulator, !state.awaitingOperand {
        guard let result = evaluateBinaryOperation(pendingOperator, left: accumulator, right: currentValue) else {
            return errorState(state)
        }
        return withDisplay(CalculatorState(
            locale: state.locale,
            error: state.error,
            accumulator: result,
            pendingOperator: binaryOperator,
            currentEntry: "0",
            entering: false,
            displayedValue: result,
            awaitingOperand: true,
            lastOperation: state.lastOperation,
            justEvaluated: false
        ))
    }

    return withDisplay(CalculatorState(
        locale: state.locale,
        error: state.error,
        accumulator: currentValue,
        pendingOperator: binaryOperator,
        currentEntry: "0",
        entering: false,
        displayedValue: currentValue,
        awaitingOperand: true,
        lastOperation: state.lastOperation,
        justEvaluated: false
    ))
}

private func inputEquals(_ state: CalculatorState) -> CalculatorState {
    if let pendingOperator = state.pendingOperator, let accumulator = state.accumulator {
        let rightOperand = currentValue(for: state)
        guard let result = evaluateBinaryOperation(pendingOperator, left: accumulator, right: rightOperand) else {
            return errorState(state)
        }
        return withDisplay(CalculatorState(
            locale: state.locale,
            error: state.error,
            accumulator: nil,
            pendingOperator: nil,
            currentEntry: "0",
            entering: false,
            displayedValue: result,
            awaitingOperand: false,
            lastOperation: CalculatorLastOperation(operator: pendingOperator, rightOperand: rightOperand),
            justEvaluated: true
        ))
    }

    if let lastOperation = state.lastOperation {
        guard let result = evaluateBinaryOperation(lastOperation.operator, left: state.displayedValue, right: lastOperation.rightOperand) else {
            return errorState(state)
        }
        return replacing(state, currentEntry: "0", entering: false, displayedValue: result, awaitingOperand: false, justEvaluated: true)
    }

    if state.entering {
        return replacing(state, currentEntry: "0", entering: false, displayedValue: currentValue(for: state), awaitingOperand: false, justEvaluated: true)
    }

    return state
}

private func applyUnaryOperation(_ state: CalculatorState, operation: (Double) -> Double?) -> CalculatorState {
    guard let result = operation(currentValue(for: state)), result.isFinite else {
        return errorState(state)
    }
    return replacing(state, currentEntry: "0", entering: false, displayedValue: normalizeResult(result), awaitingOperand: false, justEvaluated: false)
}

private func toggleSign(_ state: CalculatorState) -> CalculatorState {
    if state.entering {
        let entry = state.currentEntry.hasPrefix("-") ? String(state.currentEntry.dropFirst()) : "-\(state.currentEntry)"
        return replacing(state, currentEntry: entry, entering: true, displayedValue: number(fromEntry: entry), awaitingOperand: false, justEvaluated: false)
    }
    return replacing(state, displayedValue: normalizeResult(-state.displayedValue), awaitingOperand: false, justEvaluated: false)
}

private func applyPercent(_ state: CalculatorState) -> CalculatorState {
    let currentValue = currentValue(for: state)
    let result: Double
    if state.pendingOperator == .add || state.pendingOperator == .subtract {
        result = (state.accumulator ?? 0) * currentValue / 100
    } else {
        result = currentValue / 100
    }
    return replacing(state, currentEntry: "0", entering: false, displayedValue: normalizeResult(result), awaitingOperand: false, justEvaluated: false)
}

private func clearEntry(_ state: CalculatorState) -> CalculatorState {
    replacing(state, currentEntry: "0", entering: false, displayedValue: 0, awaitingOperand: false, justEvaluated: false)
}

private func backspace(_ state: CalculatorState) -> CalculatorState {
    guard state.entering else { return state }
    var entry = String(state.currentEntry.dropLast())
    if entry.isEmpty || entry == "-" {
        entry = state.currentEntry.hasPrefix("-") ? "-0" : "0"
    }
    if entry == "-0", !state.currentEntry.hasPrefix("-") {
        entry = "0"
    }
    return replacing(state, currentEntry: entry, entering: true, displayedValue: number(fromEntry: entry), awaitingOperand: false, justEvaluated: false)
}

private func evaluateBinaryOperation(_ binaryOperator: CalculatorBinaryOperator, left: Double, right: Double) -> Double? {
    let result: Double
    switch binaryOperator {
    case .add:
        result = left + right
    case .subtract:
        result = left - right
    case .multiply:
        result = left * right
    case .divide:
        guard right != 0 else { return nil }
        result = left / right
    }
    return result.isFinite ? normalizeResult(result) : nil
}

private func currentValue(for state: CalculatorState) -> Double {
    state.entering ? number(fromEntry: state.currentEntry) : state.displayedValue
}

private func number(fromEntry entry: String) -> Double {
    if entry == "-" || entry.isEmpty || entry == "." || entry == "-." {
        return 0
    }
    return Double(entry) ?? 0
}

private func withDisplay(_ state: CalculatorState) -> CalculatorState {
    let display: String
    if state.error {
        display = "Error"
    } else if state.entering {
        display = localizeDecimalSeparator(state.currentEntry, locale: state.locale)
    } else {
        display = displayCalculatorValue(state.displayedValue, locale: state.locale)
    }
    return CalculatorState(
        locale: state.locale,
        display: display,
        error: state.error,
        accumulator: state.accumulator,
        pendingOperator: state.pendingOperator,
        currentEntry: state.currentEntry,
        entering: state.entering,
        displayedValue: state.displayedValue,
        awaitingOperand: state.awaitingOperand,
        lastOperation: state.lastOperation,
        justEvaluated: state.justEvaluated
    )
}

private func errorState(_ state: CalculatorState) -> CalculatorState {
    withDisplay(CalculatorState(
        locale: state.locale,
        error: true,
        accumulator: nil,
        pendingOperator: nil,
        currentEntry: "0",
        entering: false,
        displayedValue: 0,
        awaitingOperand: false,
        lastOperation: nil,
        justEvaluated: false
    ))
}

private func replacing(
    _ state: CalculatorState,
    currentEntry: String? = nil,
    entering: Bool? = nil,
    displayedValue: Double? = nil,
    awaitingOperand: Bool? = nil,
    justEvaluated: Bool? = nil
) -> CalculatorState {
    withDisplay(CalculatorState(
        locale: state.locale,
        error: state.error,
        accumulator: state.accumulator,
        pendingOperator: state.pendingOperator,
        currentEntry: currentEntry ?? state.currentEntry,
        entering: entering ?? state.entering,
        displayedValue: displayedValue ?? state.displayedValue,
        awaitingOperand: awaitingOperand ?? state.awaitingOperand,
        lastOperation: state.lastOperation,
        justEvaluated: justEvaluated ?? state.justEvaluated
    ))
}

private func normalizeResult(_ value: Double) -> Double {
    if value == 0 || abs(value) < 5e-15 {
        return 0
    }
    let exponent = floor(log10(abs(value)))
    let factor = pow(10, Double(resultSignificantDigits) - exponent - 1)
    if !factor.isFinite || factor == 0 {
        return value
    }
    return (value * factor).rounded() / factor
}

private func fractionDigits(for absoluteValue: Double) -> Int {
    let exponent = floor(log10(absoluteValue))
    return max(0, maxSignificantDigits - Int(exponent) - 1)
}

private func normalizeFixed(_ value: String) -> String {
    var result = value
    guard result.contains(".") else { return result }
    while result.last == "0" {
        result.removeLast()
    }
    if result.last == "." {
        result.removeLast()
    }
    return result
}

private func normalizeScientific(_ value: String) -> String {
    let parts = value.lowercased().split(separator: "e", omittingEmptySubsequences: false)
    let mantissa = normalizeFixed(String(parts.first ?? "0"))
    let exponent = parts.count > 1 ? Int(parts[1]) ?? 0 : 0
    return "\(mantissa)e\(exponent)"
}

private func localizeDecimalSeparator(_ value: String, locale: CalculatorLocale) -> String {
    locale == .fr ? value.replacingOccurrences(of: ".", with: ",") : value
}
