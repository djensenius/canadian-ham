import Foundation

public enum MorseProfileName: String, Codable, Sendable {
    case isedParis
    case ric1Literal
}

public enum MorseOutputMode: String, Codable, CaseIterable, Sendable {
    case audio
    case visualBeacon
    case visualTape
    case haptics
}

public enum MorseSymbolKind: String, Codable, Sendable {
    case dot
    case dash
    case intraCharacterGap
    case interCharacterGap
    case wordGap
}

public struct MorseTimingProfile: Codable, Equatable, Sendable {
    public let name: MorseProfileName?
    public let characterWpm: Double
    public let effectiveWpm: Double
    public let dotSeconds: Double
    public let dashSeconds: Double
    public let intraCharacterGapSeconds: Double
    public let interCharacterGapSeconds: Double
    public let wordGapSeconds: Double

    public init(
        name: MorseProfileName? = nil,
        characterWpm: Double,
        effectiveWpm: Double,
        dotSeconds: Double,
        dashSeconds: Double,
        intraCharacterGapSeconds: Double,
        interCharacterGapSeconds: Double,
        wordGapSeconds: Double
    ) {
        self.name = name
        self.characterWpm = characterWpm
        self.effectiveWpm = effectiveWpm
        self.dotSeconds = dotSeconds
        self.dashSeconds = dashSeconds
        self.intraCharacterGapSeconds = intraCharacterGapSeconds
        self.interCharacterGapSeconds = interCharacterGapSeconds
        self.wordGapSeconds = wordGapSeconds
    }
}

public struct TimedMorseSymbol: Codable, Equatable, Sendable {
    public let kind: MorseSymbolKind
    public let startSeconds: Double
    public let durationSeconds: Double
    public let character: String?

    public init(kind: MorseSymbolKind, startSeconds: Double, durationSeconds: Double, character: String? = nil) {
        self.kind = kind
        self.startSeconds = startSeconds
        self.durationSeconds = durationSeconds
        self.character = character
    }
}

public struct TimedMorseSequence: Codable, Equatable, Sendable {
    public let input: String
    public let normalizedText: String
    public let profile: MorseTimingProfile
    public let symbols: [TimedMorseSymbol]
    public let totalDurationSeconds: Double
}

public struct MorseSignalEvent: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable { case on, off }
    public let kind: Kind
    public let atSeconds: Double
    public let character: String
    public let symbolKind: MorseSymbolKind
}

public struct MorseTapeToken: Codable, Equatable, Sendable {
    public let token: String
    public let revealAtSeconds: Double
    public let character: String
}

public struct MorseHapticEvent: Codable, Equatable, Sendable {
    public let startSeconds: Double
    public let durationSeconds: Double
    public let character: String
    public let symbolKind: MorseSymbolKind
}

public struct MorseRGB: Codable, Equatable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

public struct MorseFlashBeaconPalette: Codable, Equatable, Sendable {
    public let resting: MorseRGB
    public let active: MorseRGB
    public let usesSaturatedRed: Bool

    public init(resting: MorseRGB, active: MorseRGB, usesSaturatedRed: Bool) {
        self.resting = resting
        self.active = active
        self.usesSaturatedRed = usesSaturatedRed
    }
}

public struct MorseFlashSafetyInput: Codable, Equatable, Sendable {
    public let flashAreaCssPixels: Double
    public let flashesPerSecond: Int
    public let darkerRelativeLuminance: Double
    public let lighterRelativeLuminance: Double
    public let usesSaturatedRed: Bool

    public init(flashAreaCssPixels: Double, flashesPerSecond: Int, darkerRelativeLuminance: Double, lighterRelativeLuminance: Double, usesSaturatedRed: Bool) {
        self.flashAreaCssPixels = flashAreaCssPixels
        self.flashesPerSecond = flashesPerSecond
        self.darkerRelativeLuminance = darkerRelativeLuminance
        self.lighterRelativeLuminance = lighterRelativeLuminance
        self.usesSaturatedRed = usesSaturatedRed
    }
}

public struct MorseFlashSafetyResult: Codable, Equatable, Sendable {
    public enum Reason: String, Codable, Sendable {
        case belowAreaThreshold
        case withinThreeFlashes
        case belowGeneralThreshold
        case areaTooLarge
        case saturatedRed
    }
    public let safe: Bool
    public let reason: Reason
    public let luminanceDelta: Double
    public let maxAreaCssPixels: Double
}

public struct InvalidMorseCharacter: Codable, Equatable, Sendable {
    public let character: String
    /// Zero-based Unicode scalar index in the input string.
    public let index: Int
}

public struct ValidationResult: Codable, Equatable, Sendable {
    public let valid: Bool
    public let invalidCharacters: [InvalidMorseCharacter]
}

public struct WeightCount: Codable, Equatable, Sendable {
    public let weightedCharacters: Int
    public let unweightedCharacters: Int
}

public struct MorseExamScore: Codable, Equatable, Sendable {
    public let errors: Int
    public let wrong: Int
    public let missing: Int
    public let inserted: Int
    public let passed: Bool
    public let markPercent: Int
    public let expectedLength: Int
    public let receivedLength: Int
}

public enum MorseCopyDiffKind: String, Codable, Equatable, Sendable {
    case match
    case wrong
    case missing
    case inserted
}

public struct MorseCopyDiffOperation: Codable, Equatable, Sendable {
    public let kind: MorseCopyDiffKind
    public let expected: String?
    public let received: String?

    public init(kind: MorseCopyDiffKind, expected: String? = nil, received: String? = nil) {
        self.kind = kind
        self.expected = expected
        self.received = received
    }
}

public struct MorseCopyDiff: Codable, Equatable, Sendable {
    public let score: MorseExamScore
    public let operations: [MorseCopyDiffOperation]
}

public struct MorseExamText: Codable, Equatable, Sendable {
    public let text: String
    public let normalizedText: String
    public let weightedCharacters: Int
    public let unweightedCharacters: Int
    public let durationSeconds: Double
    public let profile: MorseTimingProfile
}

public enum MorseKeyElement: String, Codable, Equatable, Sendable {
    case dot = "."
    case dash = "-"
}

public enum MorseDecodedKind: String, Codable, Equatable, Sendable {
    case character
    case errorSignal
    case unknown
}

public struct MorseKeyTimingSample: Codable, Equatable, Sendable {
    public let element: MorseKeyElement
    public let durationSeconds: Double
    public let expectedSeconds: Double
    public let ratioToExpected: Double

    public init(element: MorseKeyElement, durationSeconds: Double, expectedSeconds: Double, ratioToExpected: Double) {
        self.element = element
        self.durationSeconds = durationSeconds
        self.expectedSeconds = expectedSeconds
        self.ratioToExpected = ratioToExpected
    }
}

public struct MorseDecodedCharacter: Codable, Equatable, Sendable {
    public let kind: MorseDecodedKind
    public let elements: String
    public let character: String?

    public init(kind: MorseDecodedKind, elements: String, character: String? = nil) {
        self.kind = kind
        self.elements = elements
        self.character = character
    }
}

public struct MorseCharacterTimingFeedback: Codable, Equatable, Sendable {
    public let elements: String
    public let decoded: MorseDecodedCharacter
    public let dotDashRatio: Double?
    public let timingConsistencyPercent: Int
    public let averageRatioToExpected: Double
}

public struct MorseSendingScore: Codable, Equatable, Sendable {
    public let diff: MorseCopyDiff
    public let completedWithinTime: Bool
    public let passed: Bool
    public let markPercent: Int
}

public let morseErrorSignalDots = 8
public let morseFlashReferenceWidthCssPixels = 341.0
public let morseFlashReferenceHeightCssPixels = 256.0
public let morseFlashMaxAreaCssPixels = (morseFlashReferenceWidthCssPixels * morseFlashReferenceHeightCssPixels) / 4
public let morseBeaconAreaCssPixels = 112.0 * 112.0
public let morseBeaconRestingMix = 0.0
public let morseBeaconActiveMix = 1.0
public let morseLightPaperInsetRGB = MorseRGB(red: 0xef / 255, green: 0xe3 / 255, blue: 0xcb / 255)
public let morseDarkPaperInsetRGB = MorseRGB(red: 0x18 / 255, green: 0x14 / 255, blue: 0x10 / 255)
public let morseLightAccentRGB = MorseRGB(red: 0xa5 / 255, green: 0x3a / 255, blue: 0x2a / 255)
public let morseDarkAccentRGB = MorseRGB(red: 0xff / 255, green: 0x8a / 255, blue: 0x70 / 255)

public enum MorseEngineError: Error, Equatable, Sendable, CustomStringConvertible {
    case invalidCharacters([InvalidMorseCharacter])
    case invalidSpeed(String)
    case examTextConstraintsUnsatisfied(String)
    case unknownProfile(String)

    public var description: String {
        switch self {
        case let .invalidCharacters(characters):
            let names = characters.map(\.character).joined(separator: " ")
            return "Text contains characters outside RIC-1 section 8.2: \(names)"
        case let .invalidSpeed(message):
            return message
        case let .examTextConstraintsUnsatisfied(message):
            return message
        case let .unknownProfile(name):
            return "Unknown Morse timing profile: \(name)"
        }
    }
}

public let morseCodeTable: [String: String] = [
    "A": ".-",
    "B": "-...",
    "C": "-.-.",
    "D": "-..",
    "E": ".",
    "F": "..-.",
    "G": "--.",
    "H": "....",
    "I": "..",
    "J": ".---",
    "K": "-.-",
    "L": ".-..",
    "M": "--",
    "N": "-.",
    "O": "---",
    "P": ".--.",
    "Q": "--.-",
    "R": ".-.",
    "S": "...",
    "T": "-",
    "U": "..-",
    "V": "...-",
    "W": ".--",
    "X": "-..-",
    "Y": "-.--",
    "Z": "--..",
    "0": "-----",
    "1": ".----",
    "2": "..---",
    "3": "...--",
    "4": "....-",
    "5": ".....",
    "6": "-....",
    "7": "--...",
    "8": "---..",
    "9": "----.",
    ".": ".-.-.-",
    ",": "--..--",
    "?": "..--..",
    "-": "-....-",
    "/": "-..-.",
]

public let allowedRIC1Characters: [String] = Array(morseCodeTable.keys).sorted()

private let reverseMorseCodeTable = Dictionary(uniqueKeysWithValues: morseCodeTable.map { ($0.value, $0.key) })
private let allowedCharacters = Set(morseCodeTable.keys)
private let punctuationAndFigures = Set(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", ",", "?", "-", "/"])
private let morseWhitespaceScalarValues = Set<UInt32>([
    0x0009,
    0x000a,
    0x000b,
    0x000c,
    0x000d,
    0x0020,
    0x0085,
    0x00a0,
    0x1680,
    0x2000,
    0x2001,
    0x2002,
    0x2003,
    0x2004,
    0x2005,
    0x2006,
    0x2007,
    0x2008,
    0x2009,
    0x200a,
    0x2028,
    0x2029,
    0x202f,
    0x205f,
    0x3000,
    0xfeff,
])
private let examSentenceCorpus = [
    "THE RADIO OPERATOR CHECKS THE NORTH ANTENNA.",
    "WEATHER REPORTS WILL BE SHORT AND CLEAR.",
    "STATION VE3ABC COPIES YOUR SIGNAL 599.",
    "QTH IS OTTAWA AND POWER IS 25 WATTS.",
    "PORTABLE STATION VE7XYZ CALLS CQ AGAIN.",
    "THE MESSAGE NUMBER IS 42 FOR FIELD DAY.",
    "QSJ 1962 WAS LOGGED AFTER THE CONTACT.",
    "PLEASE SEND NAME, QTH, AND RST AGAIN.",
    "MOBILE UNIT CHECKS IN FROM ROAD 17.",
    "FORECAST PERIODS WILL BE SHORTENED TODAY.",
    "CALL VE2HAM/PORTABLE AFTER THE NET.",
    "QSL THE TEST MESSAGE BEFORE NOON.",
]

public func farnsworthTiming(characterWpm: Double, effectiveWpm requestedEffectiveWpm: Double) throws -> MorseTimingProfile {
    guard characterWpm.isFinite, characterWpm > 0 else {
        throw MorseEngineError.invalidSpeed("characterWpm must be a positive finite number")
    }
    guard requestedEffectiveWpm.isFinite, requestedEffectiveWpm > 0 else {
        throw MorseEngineError.invalidSpeed("effectiveWpm must be a positive finite number")
    }

    let effectiveWpm = min(requestedEffectiveWpm, characterWpm)
    let dotSeconds = 1.2 / characterWpm
    let farnsworthAggregateGapSeconds = (60 * characterWpm - 37.2 * effectiveWpm) / (effectiveWpm * characterWpm)
    return MorseTimingProfile(
        characterWpm: characterWpm,
        effectiveWpm: effectiveWpm,
        dotSeconds: dotSeconds,
        dashSeconds: 3 * dotSeconds,
        intraCharacterGapSeconds: dotSeconds,
        interCharacterGapSeconds: (3 * farnsworthAggregateGapSeconds) / 19,
        wordGapSeconds: (7 * farnsworthAggregateGapSeconds) / 19
    )
}

public func profileForName(_ name: MorseProfileName) -> MorseTimingProfile {
    switch name {
    case .isedParis:
        // Safe by construction: positive speeds.
        return try! MorseTimingProfile(
            name: .isedParis,
            base: farnsworthTiming(characterWpm: 12, effectiveWpm: 5)
        )
    case .ric1Literal:
        return MorseTimingProfile(
            name: .ric1Literal,
            characterWpm: 12,
            effectiveWpm: 60 / 7.6,
            dotSeconds: 0.1,
            dashSeconds: 0.3,
            intraCharacterGapSeconds: 0.1,
            interCharacterGapSeconds: 0.7,
            wordGapSeconds: 1.7
        )
    }
}

public func validateMorseText(_ text: String) -> ValidationResult {
    var invalidCharacters: [InvalidMorseCharacter] = []
    for (index, scalar) in text.unicodeScalars.enumerated() {
        if scalar.isMorseWhitespace {
            continue
        }
        guard let normalized = normalizeMorseScalar(scalar), allowedCharacters.contains(normalized) else {
            invalidCharacters.append(InvalidMorseCharacter(character: String(scalar), index: index))
            continue
        }
    }
    return ValidationResult(valid: invalidCharacters.isEmpty, invalidCharacters: invalidCharacters)
}

public func canonicalMorseCharacters(_ text: String) throws -> [String] {
    let validation = validateMorseText(text)
    guard validation.valid else {
        throw MorseEngineError.invalidCharacters(validation.invalidCharacters)
    }
    return text.unicodeScalars.compactMap { scalar in
        scalar.isMorseWhitespace ? nil : normalizeMorseScalar(scalar)
    }
}

public func weightedCharacterCount(_ text: String) throws -> WeightCount {
    let characters = try canonicalMorseCharacters(text)
    return WeightCount(
        weightedCharacters: characters.reduce(0) { total, character in
            total + (punctuationAndFigures.contains(character) ? 2 : 1)
        },
        unweightedCharacters: characters.count
    )
}

public func textToTimedMorse(_ text: String, profile: MorseTimingProfile = profileForName(.isedParis)) throws -> TimedMorseSequence {
    let words = try canonicalMorseWords(text)
    var symbols: [TimedMorseSymbol] = []
    var cursor = 0.0

    for word in words {
        for (characterIndex, character) in word.enumerated() {
            guard let code = morseCodeTable[character] else {
                throw MorseEngineError.invalidCharacters([InvalidMorseCharacter(character: character, index: characterIndex)])
            }
            let elements = Array(code)
            for (elementIndex, element) in elements.enumerated() {
                let kind: MorseSymbolKind = element == "." ? .dot : .dash
                let duration = kind == .dot ? profile.dotSeconds : profile.dashSeconds
                symbols.append(TimedMorseSymbol(kind: kind, startSeconds: cursor, durationSeconds: duration, character: character))
                cursor += duration

                if elementIndex < elements.count - 1 {
                    symbols.append(TimedMorseSymbol(
                        kind: .intraCharacterGap,
                        startSeconds: cursor,
                        durationSeconds: profile.intraCharacterGapSeconds,
                        character: character
                    ))
                    cursor += profile.intraCharacterGapSeconds
                }
            }

            let gapKind: MorseSymbolKind = characterIndex == word.count - 1 ? .wordGap : .interCharacterGap
            let gapDuration = gapKind == .wordGap ? profile.wordGapSeconds : profile.interCharacterGapSeconds
            symbols.append(TimedMorseSymbol(kind: gapKind, startSeconds: cursor, durationSeconds: gapDuration))
            cursor += gapDuration
        }
    }

    return TimedMorseSequence(
        input: text,
        normalizedText: words.map { $0.joined() }.joined(separator: " "),
        profile: profile,
        symbols: symbols,
        totalDurationSeconds: cursor
    )
}

public func morseSignalEvents(sequence: TimedMorseSequence) -> [MorseSignalEvent] {
    sequence.symbols.flatMap { symbol -> [MorseSignalEvent] in
        guard (symbol.kind == .dot || symbol.kind == .dash), let character = symbol.character else { return [] }
        return [
            MorseSignalEvent(kind: .on, atSeconds: symbol.startSeconds, character: character, symbolKind: symbol.kind),
            MorseSignalEvent(kind: .off, atSeconds: symbol.startSeconds + symbol.durationSeconds, character: character, symbolKind: symbol.kind),
        ]
    }
}

public func morseTapeTokens(sequence: TimedMorseSequence) -> [MorseTapeToken] {
    sequence.symbols.compactMap { symbol in
        guard (symbol.kind == .dot || symbol.kind == .dash), let character = symbol.character else { return nil }
        return MorseTapeToken(token: symbol.kind == .dot ? "." : "-", revealAtSeconds: symbol.startSeconds, character: character)
    }
}

public func morseHapticEvents(sequence: TimedMorseSequence) -> [MorseHapticEvent] {
    sequence.symbols.compactMap { symbol in
        guard (symbol.kind == .dot || symbol.kind == .dash), let character = symbol.character else { return nil }
        return MorseHapticEvent(startSeconds: symbol.startSeconds, durationSeconds: symbol.durationSeconds, character: character, symbolKind: symbol.kind)
    }
}

public func maxMorseFlashesPerSecond(events: [MorseSignalEvent]) -> Int {
    let onTimes = events.filter { $0.kind == .on }.map(\.atSeconds).sorted()
    var maxFlashes = 0
    var windowStart = 0
    for windowEnd in onTimes.indices {
        while onTimes[windowEnd] - onTimes[windowStart] >= 1 {
            windowStart += 1
        }
        maxFlashes = max(maxFlashes, windowEnd - windowStart + 1)
    }
    return maxFlashes
}

public func morseRelativeLuminance(_ color: MorseRGB) -> Double {
    let linearRed = linearizeMorseSRGB(color.red)
    let linearGreen = linearizeMorseSRGB(color.green)
    let linearBlue = linearizeMorseSRGB(color.blue)
    return (0.2126 * linearRed) + (0.7152 * linearGreen) + (0.0722 * linearBlue)
}

public func mixMorseRGB(foreground: MorseRGB, background: MorseRGB, foregroundRatio: Double) -> MorseRGB {
    let ratio = min(1, max(0, foregroundRatio))
    return MorseRGB(
        red: foreground.red * ratio + background.red * (1 - ratio),
        green: foreground.green * ratio + background.green * (1 - ratio),
        blue: foreground.blue * ratio + background.blue * (1 - ratio)
    )
}

public func morseBeaconPalette(accent: MorseRGB, background: MorseRGB) -> MorseFlashBeaconPalette {
    MorseFlashBeaconPalette(
        resting: mixMorseRGB(foreground: accent, background: background, foregroundRatio: morseBeaconRestingMix),
        active: mixMorseRGB(foreground: accent, background: background, foregroundRatio: morseBeaconActiveMix),
        usesSaturatedRed: isSaturatedMorseRed(accent)
    )
}

public func evaluateMorseBeaconFlashSafety(palette: MorseFlashBeaconPalette, flashesPerSecond: Int, flashAreaCssPixels: Double = morseBeaconAreaCssPixels) -> MorseFlashSafetyResult {
    evaluateMorseFlashSafety(MorseFlashSafetyInput(
        flashAreaCssPixels: flashAreaCssPixels,
        flashesPerSecond: flashesPerSecond,
        darkerRelativeLuminance: morseRelativeLuminance(palette.resting),
        lighterRelativeLuminance: morseRelativeLuminance(palette.active),
        usesSaturatedRed: palette.usesSaturatedRed
    ))
}

public func evaluateMorseFlashSafety(_ input: MorseFlashSafetyInput) -> MorseFlashSafetyResult {
    let darker = min(input.darkerRelativeLuminance, input.lighterRelativeLuminance)
    let lighter = max(input.darkerRelativeLuminance, input.lighterRelativeLuminance)
    let luminanceDelta = lighter - darker
    if input.usesSaturatedRed {
        return MorseFlashSafetyResult(safe: false, reason: .saturatedRed, luminanceDelta: luminanceDelta, maxAreaCssPixels: morseFlashMaxAreaCssPixels)
    }
    if input.flashAreaCssPixels <= morseFlashMaxAreaCssPixels {
        return MorseFlashSafetyResult(safe: true, reason: .belowAreaThreshold, luminanceDelta: luminanceDelta, maxAreaCssPixels: morseFlashMaxAreaCssPixels)
    }
    if input.flashesPerSecond <= 3 {
        return MorseFlashSafetyResult(safe: true, reason: .withinThreeFlashes, luminanceDelta: luminanceDelta, maxAreaCssPixels: morseFlashMaxAreaCssPixels)
    }
    if luminanceDelta < 0.1 || darker >= 0.8 {
        return MorseFlashSafetyResult(safe: true, reason: .belowGeneralThreshold, luminanceDelta: luminanceDelta, maxAreaCssPixels: morseFlashMaxAreaCssPixels)
    }
    return MorseFlashSafetyResult(safe: false, reason: .areaTooLarge, luminanceDelta: luminanceDelta, maxAreaCssPixels: morseFlashMaxAreaCssPixels)
}

private func linearizeMorseSRGB(_ component: Double) -> Double {
    component <= 0.03928 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
}

private func isSaturatedMorseRed(_ color: MorseRGB) -> Bool {
    let total = color.red + color.green + color.blue
    return total > 0 && color.red / total >= 0.8
}

public func classifyMorseKeyDown(durationSeconds: Double, profile: MorseTimingProfile) throws -> MorseKeyTimingSample {
    guard durationSeconds.isFinite, durationSeconds > 0 else {
        throw MorseEngineError.invalidSpeed("durationSeconds must be a positive finite number")
    }
    let element: MorseKeyElement = durationSeconds <= 2 * profile.dotSeconds ? .dot : .dash
    let expectedSeconds = element == .dot ? profile.dotSeconds : profile.dashSeconds
    return MorseKeyTimingSample(
        element: element,
        durationSeconds: durationSeconds,
        expectedSeconds: expectedSeconds,
        ratioToExpected: durationSeconds / expectedSeconds
    )
}

public func decodeMorseElements(_ elements: [MorseKeyElement]) -> MorseDecodedCharacter {
    decodeMorseElements(elements.map(\.rawValue).joined())
}

public func decodeMorseElements(_ elements: String) -> MorseDecodedCharacter {
    guard elements.range(of: #"^[.-]+$"#, options: .regularExpression) != nil else {
        return MorseDecodedCharacter(kind: .unknown, elements: elements)
    }
    if elements == String(repeating: ".", count: morseErrorSignalDots) {
        return MorseDecodedCharacter(kind: .errorSignal, elements: elements)
    }
    guard let character = reverseMorseCodeTable[elements] else {
        return MorseDecodedCharacter(kind: .unknown, elements: elements)
    }
    return MorseDecodedCharacter(kind: .character, elements: elements, character: character)
}

public func applyMorseDecodedCharacter(text: String, decoded: MorseDecodedCharacter) -> String {
    switch decoded.kind {
    case .errorSignal:
        return String(text.dropLast())
    case .character:
        if let character = decoded.character {
            return text + character
        }
        return text
    case .unknown:
        return text
    }
}

public func morseCharacterTimingFeedback(samples: [MorseKeyTimingSample]) -> MorseCharacterTimingFeedback {
    let elements = samples.map(\.element.rawValue).joined()
    let ratios = samples.map(\.ratioToExpected)
    let averageRatio = ratios.isEmpty ? 1 : ratios.reduce(0, +) / Double(ratios.count)
    let meanAbsoluteError = ratios.isEmpty ? 0 : ratios.reduce(0) { $0 + abs($1 - 1) } / Double(ratios.count)
    let dotDurations = samples.filter { $0.element == .dot }.map(\.durationSeconds)
    let dashDurations = samples.filter { $0.element == .dash }.map(\.durationSeconds)
    let dotDashRatio: Double? = dotDurations.isEmpty || dashDurations.isEmpty ? nil : average(dashDurations) / average(dotDurations)
    return MorseCharacterTimingFeedback(
        elements: elements,
        decoded: decodeMorseElements(elements),
        dotDashRatio: dotDashRatio,
        timingConsistencyPercent: Int(max(0, min(100, ((1 - meanAbsoluteError) * 100).rounded()))),
        averageRatioToExpected: averageRatio
    )
}

public func scoreMorseSending(expected: String, sent: String, completedWithinTime: Bool = true) throws -> MorseSendingScore {
    let diff = try diffMorseCopy(expected: expected, received: sent)
    return MorseSendingScore(
        diff: diff,
        completedWithinTime: completedWithinTime,
        passed: diff.score.passed,
        markPercent: diff.score.markPercent
    )
}

public func generateMorseExamText(
    seed: String = "morse-copy-exam",
    profile: MorseTimingProfile = profileForName(.isedParis),
    minWeightedCharacters: Int = 75,
    minDurationSeconds: Double = 180
) throws -> MorseExamText {
    var random = SeededMorseRandom(seed: seed)
    let startIndex = Int(floor(random.next() * Double(examSentenceCorpus.count)))
    var selectedSentences: [String] = []
    var sentenceIndex = startIndex

    for _ in 0 ..< 200 {
        selectedSentences.append(examSentenceCorpus[sentenceIndex % examSentenceCorpus.count])
        sentenceIndex += 1 + Int(floor(random.next() * 3))
        let candidate = selectedSentences.joined(separator: " ")
        let weight = try weightedCharacterCount(candidate)
        let sequence = try textToTimedMorse(candidate, profile: profile)
        if weight.weightedCharacters >= minWeightedCharacters, sequence.totalDurationSeconds >= minDurationSeconds {
            return MorseExamText(
                text: candidate,
                normalizedText: sequence.normalizedText,
                weightedCharacters: weight.weightedCharacters,
                unweightedCharacters: weight.unweightedCharacters,
                durationSeconds: sequence.totalDurationSeconds,
                profile: profile
            )
        }
    }

    throw MorseEngineError.examTextConstraintsUnsatisfied("Unable to generate Morse exam text that satisfies RIC-1 section 8.2 constraints.")
}

public func scoreMorseCopy(expected: String, received: String) throws -> MorseExamScore {
    try alignMorseCopy(expected: expected, received: received).score
}

public func diffMorseCopy(expected: String, received: String) throws -> MorseCopyDiff {
    try alignMorseCopy(expected: expected, received: received)
}

private func alignMorseCopy(expected: String, received: String) throws -> MorseCopyDiff {
    let expectedCharacters = try canonicalMorseCharacters(expected)
    let receivedCharacters = receivedMorseCopyCharacters(received)
    let rows = expectedCharacters.count + 1
    let columns = receivedCharacters.count + 1
    var dp = Array(repeating: Array(repeating: 0, count: columns), count: rows)

    if rows > 1 {
        for row in 1 ..< rows {
            dp[row][0] = row
        }
    }
    if columns > 1 {
        for column in 1 ..< columns {
            dp[0][column] = column
        }
    }

    if rows > 1, columns > 1 {
        for row in 1 ..< rows {
            for column in 1 ..< columns {
                let substitutionCost = expectedCharacters[row - 1] == receivedCharacters[column - 1] ? 0 : 1
                dp[row][column] = min(
                    dp[row - 1][column] + 1,
                    dp[row][column - 1] + 1,
                    dp[row - 1][column - 1] + substitutionCost
                )
            }
        }
    }

    var row = expectedCharacters.count
    var column = receivedCharacters.count
    var wrong = 0
    var missing = 0
    var inserted = 0
    var operations: [MorseCopyDiffOperation] = []

    while row > 0 || column > 0 {
        if row > 0,
           column > 0,
           expectedCharacters[row - 1] == receivedCharacters[column - 1],
           dp[row][column] == dp[row - 1][column - 1]
        {
            operations.append(MorseCopyDiffOperation(kind: .match, expected: expectedCharacters[row - 1], received: receivedCharacters[column - 1]))
            row -= 1
            column -= 1
            continue
        }

        if row > 0,
           column > 0,
           dp[row][column] == dp[row - 1][column - 1] + 1
        {
            operations.append(MorseCopyDiffOperation(kind: .wrong, expected: expectedCharacters[row - 1], received: receivedCharacters[column - 1]))
            wrong += 1
            row -= 1
            column -= 1
            continue
        }

        if row > 0,
           dp[row][column] == dp[row - 1][column] + 1
        {
            operations.append(MorseCopyDiffOperation(kind: .missing, expected: expectedCharacters[row - 1]))
            missing += 1
            row -= 1
            continue
        }

        operations.append(MorseCopyDiffOperation(kind: .inserted, received: receivedCharacters[column - 1]))
        inserted += 1
        column -= 1
    }

    let errors = dp[expectedCharacters.count][receivedCharacters.count]
    return MorseCopyDiff(
        score: MorseExamScore(
            errors: errors,
            wrong: wrong,
            missing: missing,
            inserted: inserted,
            passed: errors <= 5,
            markPercent: errors <= 5 ? 100 : max(0, 105 - errors),
            expectedLength: expectedCharacters.count,
            receivedLength: receivedCharacters.count
        ),
        operations: Array(operations.reversed())
    )
}

private func canonicalMorseWords(_ text: String) throws -> [[String]] {
    let validation = validateMorseText(text)
    guard validation.valid else {
        throw MorseEngineError.invalidCharacters(validation.invalidCharacters)
    }

    var words: [[String]] = []
    var currentWord: [String] = []
    for scalar in text.unicodeScalars {
        if scalar.isMorseWhitespace {
            if !currentWord.isEmpty {
                words.append(currentWord)
                currentWord = []
            }
            continue
        }
        if let normalized = normalizeMorseScalar(scalar) {
            currentWord.append(normalized)
        }
    }
    if !currentWord.isEmpty {
        words.append(currentWord)
    }
    return words
}

private func receivedMorseCopyCharacters(_ text: String) -> [String] {
    text.precomposedStringWithCanonicalMapping.unicodeScalars.compactMap { scalar in
        if scalar.isMorseWhitespace {
            return nil
        }
        if let normalized = normalizeMorseScalar(scalar), allowedCharacters.contains(normalized) {
            return normalized
        }
        return String(scalar)
    }
}

private func normalizeMorseScalar(_ scalar: Unicode.Scalar) -> String? {
    guard scalar.value <= 0x7f else {
        return nil
    }
    return String(scalar).uppercased()
}

private func average(_ values: [Double]) -> Double {
    values.reduce(0, +) / Double(values.count)
}

private struct SeededMorseRandom {
    private var state: UInt32 = 2_166_136_261

    init(seed: String) {
        for scalar in seed.unicodeScalars {
            state ^= UInt32(truncatingIfNeeded: scalar.value)
            state = state &* 16_777_619
        }
        if state == 0 {
            state = 0x9e37_79b9
        }
    }

    mutating func next() -> Double {
        state = ((state ^ (state >> 15)) &* 2_246_822_507)
        state = ((state ^ (state >> 13)) &* 3_266_489_909)
        state = state ^ (state >> 16)
        return Double(state) / 4_294_967_296.0
    }
}

private extension Unicode.Scalar {
    var isMorseWhitespace: Bool {
        morseWhitespaceScalarValues.contains(value)
    }
}

private extension MorseTimingProfile {
    init(name: MorseProfileName, base: MorseTimingProfile) {
        self.init(
            name: name,
            characterWpm: base.characterWpm,
            effectiveWpm: base.effectiveWpm,
            dotSeconds: base.dotSeconds,
            dashSeconds: base.dashSeconds,
            intraCharacterGapSeconds: base.intraCharacterGapSeconds,
            interCharacterGapSeconds: base.interCharacterGapSeconds,
            wordGapSeconds: base.wordGapSeconds
        )
    }
}
