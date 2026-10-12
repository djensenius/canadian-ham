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

public struct CalculatorSpokenDisplay: Codable, Equatable, Sendable {
    public let en: String
    public let fr: String

    public init(en: String, fr: String) {
        self.en = en
        self.fr = fr
    }
}

public struct CalculatorDisplayValue: Codable, Equatable, Sendable {
    public let mantissa: String?
    public let exponent: Int?
    public let isNegative: Bool
    public let isError: Bool
    public let visual: String
    public let spoken: CalculatorSpokenDisplay

    public init(mantissa: String?, exponent: Int?, isNegative: Bool, isError: Bool, visual: String, spoken: CalculatorSpokenDisplay) {
        self.mantissa = mantissa
        self.exponent = exponent
        self.isNegative = isNegative
        self.isError = isError
        self.visual = visual
        self.spoken = spoken
    }
}

public struct CalculatorState: Codable, Equatable, Sendable {
    public let locale: CalculatorLocale
    public let display: String
    public let displayValue: CalculatorDisplayValue
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
        displayValue: CalculatorDisplayValue = CalculatorDisplayValue(mantissa: "0", exponent: 0, isNegative: false, isError: false, visual: "0", spoken: CalculatorSpokenDisplay(en: "0", fr: "0")),
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
        self.displayValue = displayValue
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

private struct DecimalParts {
    let mantissa: String
    let exponent: Int
    let isNegative: Bool
    let scientific: Bool
}

private struct RoundedDecimal {
    let digits: String
    let decimalExponent: Int
    let isNegative: Bool
}

private let maxSignificantDigits = 12
private let maxEntryLength = 15
private let resultSignificantDigits = 15
private let cancellationTolerance = 1e-14
private let minNonzeroAbsoluteValue = 1e-99
private let maxAbsoluteValue = 1e100
private let typographicMinus = "−"
private let scientificMantissaDigits = 10
private let powersOfTen: [Double] = (0...120).map { Double("1e\($0)")! }

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
        if key == .clearEntry {
            return createCalculatorState(locale: state.locale)
        }
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
    displayCalculatorValueDetails(value, locale: locale).visual
}

public func displayCalculatorValueDetails(_ value: Double, locale: CalculatorLocale = .en) -> CalculatorDisplayValue {
    displayValue(forNumber: value, locale: locale)
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
    if entryExceedsLimits(entry) {
        return base
    }
    let displayedValue = number(fromEntry: entry)
    if !displayedValue.isFinite {
        return errorState(base)
    }
    return withDisplay(CalculatorState(
        locale: base.locale,
        error: base.error,
        accumulator: base.accumulator,
        pendingOperator: base.pendingOperator,
        currentEntry: entry,
        entering: true,
        displayedValue: displayedValue,
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
    if entryExceedsLimits(entry) {
        return base
    }
    return replacing(base, currentEntry: entry, entering: true, displayedValue: number(fromEntry: entry), awaitingOperand: false, justEvaluated: false)
}

private func inputBinaryOperator(_ state: CalculatorState, _ binaryOperator: CalculatorBinaryOperator) -> CalculatorState {
    let currentValue = currentValue(for: state)
    if !currentValue.isFinite {
        return errorState(state)
    }
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
    guard let result = operation(currentValue(for: state)), let normalizedResult = normalizeResult(result) else {
        return errorState(state)
    }
    return replacing(state, currentEntry: "0", entering: false, displayedValue: normalizedResult, awaitingOperand: false, clearLastOperation: true, justEvaluated: false)
}

private func toggleSign(_ state: CalculatorState) -> CalculatorState {
    if state.entering {
        let entry = state.currentEntry.hasPrefix("-") ? String(state.currentEntry.dropFirst()) : "-\(state.currentEntry)"
        return replacing(state, currentEntry: entry, entering: true, displayedValue: number(fromEntry: entry), awaitingOperand: false, clearLastOperation: true, justEvaluated: false)
    }
    guard let displayedValue = normalizeResult(-state.displayedValue) else {
        return errorState(state)
    }
    return replacing(state, displayedValue: displayedValue, awaitingOperand: false, clearLastOperation: true, justEvaluated: false)
}

private func applyPercent(_ state: CalculatorState) -> CalculatorState {
    let currentValue = currentValue(for: state)
    let result: Double
    if state.pendingOperator == .add || state.pendingOperator == .subtract {
        result = (state.accumulator ?? 0) * currentValue / 100
    } else {
        result = currentValue / 100
    }
    guard let normalizedResult = normalizeResult(result) else {
        return errorState(state)
    }
    return replacing(state, currentEntry: "0", entering: false, displayedValue: normalizedResult, awaitingOperand: false, clearLastOperation: true, justEvaluated: false)
}

private func clearEntry(_ state: CalculatorState) -> CalculatorState {
    replacing(state, currentEntry: "0", entering: false, displayedValue: 0, awaitingOperand: false, clearLastOperation: true, justEvaluated: false)
}

private func backspace(_ state: CalculatorState) -> CalculatorState {
    guard state.entering else { return state }
    var entry = String(state.currentEntry.dropLast())
    if entry.isEmpty || entry == "-" {
        entry = state.currentEntry.hasPrefix("-") ? "-0" : "0"
    }
    return replacing(state, currentEntry: entry, entering: true, displayedValue: number(fromEntry: entry), awaitingOperand: false, justEvaluated: false)
}

private func evaluateBinaryOperation(_ binaryOperator: CalculatorBinaryOperator, left: Double, right: Double) -> Double? {
    let result: Double
    switch binaryOperator {
    case .add:
        result = cancelIfSubtractiveNoise(left + right, left: left, right: right)
    case .subtract:
        result = cancelIfSubtractiveNoise(left - right, left: left, right: right)
    case .multiply:
        result = left * right
    case .divide:
        guard right != 0 else { return nil }
        result = left / right
    }
    return normalizeResult(result)
}

private func cancelIfSubtractiveNoise(_ result: Double, left: Double, right: Double) -> Double {
    let tolerance = max(abs(left), abs(right)) * cancellationTolerance
    return abs(result) <= tolerance ? 0 : result
}

private func currentValue(for state: CalculatorState) -> Double {
    state.entering ? number(fromEntry: state.currentEntry) : state.displayedValue
}

private func number(fromEntry entry: String) -> Double {
    if entry == "-" || entry.isEmpty || entry == "." || entry == "-." {
        return 0
    }
    guard let parsed = Double(entry), parsed.isFinite else {
        return Double.infinity
    }
    if abs(parsed) >= maxAbsoluteValue {
        return Double.infinity
    }
    if parsed != 0, abs(parsed) < minNonzeroAbsoluteValue {
        return 0
    }
    return parsed
}

private func withDisplay(_ state: CalculatorState) -> CalculatorState {
    let display: String
    let displayDetails: CalculatorDisplayValue
    if state.error {
        display = "Error"
        displayDetails = errorDisplayValue(visual: display)
    } else if state.entering {
        display = visualEntry(state.currentEntry, locale: state.locale)
        displayDetails = displayValue(forEntry: state.currentEntry, locale: state.locale, visual: display)
    } else {
        displayDetails = displayValue(forNumber: state.displayedValue, locale: state.locale)
        display = displayDetails.visual
    }
    return CalculatorState(
        locale: state.locale,
        display: display,
        displayValue: displayDetails,
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
    clearLastOperation: Bool = false,
    justEvaluated: Bool? = nil
) -> CalculatorState {
    let resolvedLastOperation = clearLastOperation ? nil : state.lastOperation
    return withDisplay(CalculatorState(
        locale: state.locale,
        error: state.error,
        accumulator: state.accumulator,
        pendingOperator: state.pendingOperator,
        currentEntry: currentEntry ?? state.currentEntry,
        entering: entering ?? state.entering,
        displayedValue: displayedValue ?? state.displayedValue,
        awaitingOperand: awaitingOperand ?? state.awaitingOperand,
        lastOperation: resolvedLastOperation,
        justEvaluated: justEvaluated ?? state.justEvaluated
    ))
}

private func normalizeResult(_ value: Double) -> Double? {
    if !value.isFinite {
        return nil
    }
    if value == 0 {
        return 0
    }
    if abs(value) >= maxAbsoluteValue {
        return nil
    }
    if abs(value) < minNonzeroAbsoluteValue {
        return 0
    }
    let rounded = roundToSignificantDigits(value, significantDigits: resultSignificantDigits)
    if !rounded.isFinite || abs(rounded) >= maxAbsoluteValue {
        return nil
    }
    if rounded != 0, abs(rounded) < minNonzeroAbsoluteValue {
        return 0
    }
    return rounded == 0 ? 0 : rounded
}

private func roundToSignificantDigits(_ value: Double, significantDigits: Int) -> Double {
    let absoluteValue = abs(value)
    if !absoluteValue.isFinite || absoluteValue == 0 {
        return value
    }
    let exponent = floor(log10(absoluteValue))
    let shift = significantDigits - Int(exponent) - 1
    let scaled = shift >= 0
        ? absoluteValue * powerOfTen(shift)
        : absoluteValue / powerOfTen(-shift)
    if !scaled.isFinite {
        return value
    }
    let roundedCoefficient = floor(scaled + 0.5)
    let sign = value.sign == .minus ? -1.0 : 1.0
    return sign * (shift >= 0
        ? roundedCoefficient / powerOfTen(shift)
        : roundedCoefficient * powerOfTen(-shift))
}

private func displayValue(forNumber value: Double, locale: CalculatorLocale) -> CalculatorDisplayValue {
    guard let normalizedValue = normalizeDisplayValue(value) else { return errorDisplayValue(visual: "Error") }
    let parts = decimalParts(for: normalizedValue)
    let visual = localizeDecimalSeparator(visual(from: parts), locale: locale)
    return displayValue(from: parts, visual: visual)
}

private func displayValue(forEntry entry: String, locale _: CalculatorLocale, visual: String) -> CalculatorDisplayValue {
    let isNegative = entry.hasPrefix("-")
    let unsignedEntry = isNegative ? String(entry.dropFirst()) : entry
    let mantissa = unsignedEntry.isEmpty || unsignedEntry == "." ? "0" : unsignedEntry
    return CalculatorDisplayValue(
        mantissa: mantissa,
        exponent: 0,
        isNegative: isNegative,
        isError: false,
        visual: visual,
        spoken: spokenEntry(entry)
    )
}

private func errorDisplayValue(visual: String) -> CalculatorDisplayValue {
    CalculatorDisplayValue(
        mantissa: nil,
        exponent: nil,
        isNegative: false,
        isError: true,
        visual: visual,
        spoken: CalculatorSpokenDisplay(en: "Error", fr: "Erreur")
    )
}

private func normalizeDisplayValue(_ value: Double) -> Double? {
    if !value.isFinite || abs(value) >= maxAbsoluteValue {
        return nil
    }
    if value == 0 || abs(value) < minNonzeroAbsoluteValue {
        return 0
    }
    return value
}

private func decimalParts(for value: Double) -> DecimalParts {
    guard let normalizedValue = normalizeDisplayValue(value), normalizedValue != 0 else {
        return DecimalParts(mantissa: "0", exponent: 0, isNegative: false, scientific: false)
    }

    let roundedForClassification = roundedDecimal(normalizedValue, significantDigits: maxSignificantDigits)
    let exponent = scientificExponent(roundedForClassification)
    if exponent >= 12 || exponent < -9 {
        return scientificDecimalParts(normalizedValue)
    }

    if exponent >= -3 {
        let zerosBeforeFirstSignificantDigit = exponent < 0 ? -exponent - 1 : 0
        let fixedSignificantDigits = min(maxSignificantDigits, maxSignificantDigits - zerosBeforeFirstSignificantDigit)
        return fixedDecimalParts(normalizedValue, significantDigits: fixedSignificantDigits)
    }

    let zerosBeforeFirstSignificantDigit = -exponent - 1
    if zerosBeforeFirstSignificantDigit + roundedForClassification.digits.count <= maxSignificantDigits {
        return fixedDecimalParts(normalizedValue, significantDigits: maxSignificantDigits)
    }

    return scientificDecimalParts(normalizedValue)
}

private func fixedDecimalParts(_ value: Double, significantDigits: Int) -> DecimalParts {
    let rounded = roundedDecimal(value, significantDigits: significantDigits)
    return DecimalParts(
        mantissa: fixed(fromDigits: rounded.digits, decimalExponent: rounded.decimalExponent),
        exponent: 0,
        isNegative: rounded.isNegative,
        scientific: false
    )
}

private func scientificDecimalParts(_ value: Double) -> DecimalParts {
    let rounded = roundedDecimal(value, significantDigits: scientificMantissaDigits)
    return DecimalParts(
        mantissa: mantissa(fromDigits: rounded.digits),
        exponent: scientificExponent(rounded),
        isNegative: rounded.isNegative,
        scientific: true
    )
}

private func roundedDecimal(_ value: Double, significantDigits: Int) -> RoundedDecimal {
    let isNegative = value < 0
    let absoluteValue = abs(value)
    if !absoluteValue.isFinite || absoluteValue == 0 {
        return RoundedDecimal(digits: "0", decimalExponent: 0, isNegative: false)
    }

    let exponent = floor(log10(absoluteValue))
    let shift = significantDigits - Int(exponent) - 1
    let scaled = shift >= 0
        ? absoluteValue * powerOfTen(shift)
        : absoluteValue / powerOfTen(-shift)
    if !scaled.isFinite {
        return RoundedDecimal(digits: "0", decimalExponent: 0, isNegative: false)
    }

    var coefficient = Int64(floor(scaled + 0.5))
    var decimalExponent = -shift
    let overflow = Int64(powerOfTen(significantDigits))
    if coefficient == 0 {
        return RoundedDecimal(digits: "0", decimalExponent: 0, isNegative: false)
    }
    if coefficient >= overflow {
        coefficient /= 10
        decimalExponent += 1
    }

    let coefficientDigits = String(coefficient)
    let digits = trimTrailingZeros(coefficientDigits, decimalExponent: decimalExponent)
    decimalExponent += coefficientDigits.count - digits.count
    return RoundedDecimal(digits: digits, decimalExponent: decimalExponent, isNegative: isNegative)
}

private func scientificExponent(_ rounded: RoundedDecimal) -> Int {
    rounded.digits.count + rounded.decimalExponent - 1
}

private func trimTrailingZeros(_ digits: String, decimalExponent: Int) -> String {
    var result = digits
    var exponent = decimalExponent
    while exponent < 0, result.count > 1, result.last == "0" {
        result.removeLast()
        exponent += 1
    }
    return result
}

private func mantissa(fromDigits digits: String) -> String {
    guard digits.count > 1 else { return digits }
    let first = digits.prefix(1)
    let rest = digits.dropFirst()
    return normalizeDecimalString("\(first).\(rest)")
}

private func fixed(fromDigits digits: String, decimalExponent: Int) -> String {
    if decimalExponent >= 0 {
        return digits + String(repeating: "0", count: decimalExponent)
    }
    let pointIndex = digits.count + decimalExponent
    if pointIndex > 0 {
        let index = digits.index(digits.startIndex, offsetBy: pointIndex)
        return normalizeDecimalString("\(digits[..<index]).\(digits[index...])")
    }
    return normalizeDecimalString("0." + String(repeating: "0", count: -pointIndex) + digits)
}

private func normalizeDecimalString(_ value: String) -> String {
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

private func visual(from parts: DecimalParts) -> String {
    if parts.mantissa == "0" {
        return "0"
    }
    let sign = parts.isNegative ? typographicMinus : ""
    if parts.scientific {
        let exponent = parts.exponent < 0 ? "\(typographicMinus)\(abs(parts.exponent))" : String(parts.exponent)
        return "\(sign)\(parts.mantissa)e\(exponent)"
    }
    return "\(sign)\(parts.mantissa)"
}

private func displayValue(from parts: DecimalParts, visual: String) -> CalculatorDisplayValue {
    CalculatorDisplayValue(
        mantissa: parts.mantissa,
        exponent: parts.exponent,
        isNegative: parts.isNegative,
        isError: false,
        visual: visual,
        spoken: spokenDisplay(from: parts)
    )
}

private func spokenDisplay(from parts: DecimalParts) -> CalculatorSpokenDisplay {
    let englishSign = parts.isNegative ? "minus " : ""
    let frenchSign = parts.isNegative ? "moins " : ""
    if parts.scientific {
        let englishExponentSign = parts.exponent < 0 ? "minus " : ""
        let frenchExponentSign = parts.exponent < 0 ? "moins " : ""
        return CalculatorSpokenDisplay(
            en: "\(englishSign)\(parts.mantissa) times ten to the \(englishExponentSign)\(abs(parts.exponent))",
            fr: "\(frenchSign)\(parts.mantissa.replacingOccurrences(of: ".", with: ",")) fois dix puissance \(frenchExponentSign)\(abs(parts.exponent))"
        )
    }
    return CalculatorSpokenDisplay(
        en: "\(englishSign)\(parts.mantissa)",
        fr: "\(frenchSign)\(parts.mantissa.replacingOccurrences(of: ".", with: ","))"
    )
}

private func spokenEntry(_ entry: String) -> CalculatorSpokenDisplay {
    let isNegative = entry.hasPrefix("-")
    let unsignedEntry = isNegative ? String(entry.dropFirst()) : entry
    let spokenValue = unsignedEntry.isEmpty || unsignedEntry == "." ? "0" : unsignedEntry
    return CalculatorSpokenDisplay(
        en: "\(isNegative ? "minus " : "")\(spokenValue)",
        fr: "\(isNegative ? "moins " : "")\(spokenValue.replacingOccurrences(of: ".", with: ","))"
    )
}

private func visualEntry(_ entry: String, locale: CalculatorLocale) -> String {
    let visual = entry.hasPrefix("-") ? typographicMinus + String(entry.dropFirst()) : entry
    return localizeDecimalSeparator(visual, locale: locale)
}

private func localizeDecimalSeparator(_ value: String, locale: CalculatorLocale) -> String {
    locale == .fr ? value.replacingOccurrences(of: ".", with: ",") : value
}

private func entryExceedsLimits(_ entry: String) -> Bool {
    let unsignedEntry = entry.hasPrefix("-") ? String(entry.dropFirst()) : entry
    return unsignedEntry.count > maxEntryLength || significantDigitCount(entry) > maxSignificantDigits
}

private func powerOfTen(_ exponent: Int) -> Double {
    guard powersOfTen.indices.contains(exponent) else { return Double.infinity }
    return powersOfTen[exponent]
}

private func significantDigitCount(_ entry: String) -> Int {
    var count = 0
    var foundNonZero = false
    for character in entry {
        guard character >= "0", character <= "9" else { continue }
        if !foundNonZero {
            if character == "0" {
                continue
            }
            foundNonZero = true
        }
        count += 1
    }
    return count
}
