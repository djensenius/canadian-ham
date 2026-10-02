import Foundation

public enum MorseProfileName: String, Codable, Sendable {
    case isedParis
    case ric1Literal
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

public struct InvalidMorseCharacter: Codable, Equatable, Sendable {
    public let character: String
    /// Zero-based Swift `Character` index in the input string.
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

public enum MorseEngineError: Error, Equatable, Sendable, CustomStringConvertible {
    case invalidCharacters([InvalidMorseCharacter])
    case invalidSpeed(String)
    case unknownProfile(String)

    public var description: String {
        switch self {
        case let .invalidCharacters(characters):
            let names = characters.map(\.character).joined(separator: " ")
            return "Text contains characters outside RIC-1 section 8.2: \(names)"
        case let .invalidSpeed(message):
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

private let allowedCharacters = Set(morseCodeTable.keys)
private let punctuationAndFigures = Set(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", ",", "?", "-", "/"])

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
    for (index, character) in text.enumerated() {
        if character.isMorseWhitespace {
            continue
        }
        guard let normalized = normalizeMorseCharacter(character), allowedCharacters.contains(normalized) else {
            invalidCharacters.append(InvalidMorseCharacter(character: String(character), index: index))
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
    return text.compactMap { character in
        character.isMorseWhitespace ? nil : normalizeMorseCharacter(character)
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

public func scoreMorseCopy(expected: String, received: String) throws -> MorseExamScore {
    let expectedCharacters = try canonicalMorseCharacters(expected)
    let receivedCharacters = try canonicalMorseCharacters(received)
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

    while row > 0 || column > 0 {
        if row > 0,
           column > 0,
           expectedCharacters[row - 1] == receivedCharacters[column - 1],
           dp[row][column] == dp[row - 1][column - 1]
        {
            row -= 1
            column -= 1
            continue
        }

        if row > 0,
           column > 0,
           dp[row][column] == dp[row - 1][column - 1] + 1
        {
            wrong += 1
            row -= 1
            column -= 1
            continue
        }

        if row > 0,
           dp[row][column] == dp[row - 1][column] + 1
        {
            missing += 1
            row -= 1
            continue
        }

        inserted += 1
        column -= 1
    }

    let errors = dp[expectedCharacters.count][receivedCharacters.count]
    return MorseExamScore(
        errors: errors,
        wrong: wrong,
        missing: missing,
        inserted: inserted,
        passed: errors <= 5,
        markPercent: errors <= 5 ? 100 : max(0, 105 - errors),
        expectedLength: expectedCharacters.count,
        receivedLength: receivedCharacters.count
    )
}

private func canonicalMorseWords(_ text: String) throws -> [[String]] {
    let validation = validateMorseText(text)
    guard validation.valid else {
        throw MorseEngineError.invalidCharacters(validation.invalidCharacters)
    }

    var words: [[String]] = []
    var currentWord: [String] = []
    for character in text {
        if character.isMorseWhitespace {
            if !currentWord.isEmpty {
                words.append(currentWord)
                currentWord = []
            }
            continue
        }
        if let normalized = normalizeMorseCharacter(character) {
            currentWord.append(normalized)
        }
    }
    if !currentWord.isEmpty {
        words.append(currentWord)
    }
    return words
}

private func normalizeMorseCharacter(_ character: Character) -> String? {
    let normalized = String(character).uppercased()
    return normalized.count == 1 ? normalized : nil
}

private extension Character {
    var isMorseWhitespace: Bool {
        unicodeScalars.allSatisfy { CharacterSet.whitespacesAndNewlines.contains($0) }
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
