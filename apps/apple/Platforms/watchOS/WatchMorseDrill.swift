import CanadianHamEngine
import CanadianHamMorseEngine
import Foundation

struct WatchMorseSettings: Equatable {
    var haptics = true
    var hapticStyle: WatchMorseHapticStyle = .lightRising
    var tone = false
    var wordsPerMinute = 2.0

    // WatchKit presets cannot be shortened. Keep at least 1.2 s between onsets,
    // including across cancellation/restart. Hardware validation is still required.
    static let minimumHapticSpacing = 1.2
    var clampedSpeed: Double { wordsPerMinute.isFinite ? min(2, max(1, wordsPerMinute)) : 2 }
    var hasOutput: Bool { haptics || tone }

    func sequence(for letter: String) throws -> TimedMorseSequence {
        try textToTimedMorse(letter, profile: farnsworthTiming(characterWpm: clampedSpeed, effectiveWpm: clampedSpeed))
    }
}

struct WatchMorseDrill {
    static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map(String.init)
    private var rng: Pcg32
    private(set) var letter = ""
    private(set) var choices: [String] = []
    private(set) var selected: String?

    init(seed: String = UUID().uuidString) {
        rng = Pcg32(seed: seed)
        next()
    }

    var isCorrect: Bool { selected == letter }
    var pattern: String { morseCodeTable[letter] ?? "" }

    mutating func submit(_ choice: String) {
        guard selected == nil, choices.contains(choice) else { return }
        selected = choice
    }

    mutating func next() {
        let candidates = Self.alphabet.filter { $0 != letter }
        // All bounds and shuffle inputs are nonempty and fixed by the A–Z alphabet.
        letter = candidates[try! rng.bounded(candidates.count)]
        let distractors = try! shuffled(Self.alphabet.filter { $0 != letter }, rng: &rng)
        choices = try! shuffled([letter] + Array(distractors.prefix(3)), rng: &rng)
        selected = nil
    }
}

enum WatchMorsePulse: Equatable {
    case dot, dash
}

struct WatchMorseEvent: Equatable {
    let atSeconds: Double
    let pulse: WatchMorsePulse

    static func events(for sequence: TimedMorseSequence) -> [Self] {
        morseHapticEvents(sequence: sequence).map {
            Self(atSeconds: $0.startSeconds, pulse: $0.symbolKind == .dot ? .dot : .dash)
        }
    }
}
