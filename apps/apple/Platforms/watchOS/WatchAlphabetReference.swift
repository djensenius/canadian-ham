import CanadianHamMorseEngine

struct WatchAlphabetEntry: Identifiable {
    let character: String
    let phoneticWord: String?

    var id: String { character }
    // The fixed A–Z / 0–9 reference is a subset of the shared Morse table.
    var pattern: String { morseCodeTable[character]! }
    var visualPattern: String {
        pattern.map { $0 == "." ? "•" : "—" }.joined(separator: " ")
    }

    func accessibilityLabel(dot: String, dash: String) -> String {
        let spokenPattern = pattern.map { $0 == "." ? dot : dash }.joined(separator: " ")
        return [character, phoneticWord, spokenPattern].compactMap { $0 }.joined(separator: ", ")
    }
}

enum WatchAlphabetReference {
    // ITU spellings from L-002-01; international words stay unchanged in French.
    static let letters: [WatchAlphabetEntry] = [
        ("A", "Alfa"),
        ("B", "Bravo"),
        ("C", "Charlie"),
        ("D", "Delta"),
        ("E", "Echo"),
        ("F", "Foxtrot"),
        ("G", "Golf"),
        ("H", "Hotel"),
        ("I", "India"),
        ("J", "Juliett"),
        ("K", "Kilo"),
        ("L", "Lima"),
        ("M", "Mike"),
        ("N", "November"),
        ("O", "Oscar"),
        ("P", "Papa"),
        ("Q", "Quebec"),
        ("R", "Romeo"),
        ("S", "Sierra"),
        ("T", "Tango"),
        ("U", "Uniform"),
        ("V", "Victor"),
        ("W", "Whiskey"),
        ("X", "X-ray"),
        ("Y", "Yankee"),
        ("Z", "Zulu"),
    ].map { WatchAlphabetEntry(character: $0.0, phoneticWord: $0.1) }

    static let digits = (0...9).map { WatchAlphabetEntry(character: String($0), phoneticWord: nil) }
}
