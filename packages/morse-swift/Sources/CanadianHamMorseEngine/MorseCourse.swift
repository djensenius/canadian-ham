import Foundation

public enum MorseLessonState: String, Sendable, Equatable {
    case locked
    case current
    case completed
}

public struct MorseCourseUnit: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let unitNumber: Int
    public let title: String
    public let lessonIds: [String]
}

public struct MorseCourseLesson: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let unitId: String
    public let lessonNumber: Int
    public let title: String
    public let newCharacters: [String]
    public let learnedCharacters: [String]
}

public struct MorseCourse: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let kind: String
    public let courseId: String
    public let unlockAccuracy: Double
    public let unitSize: Int
    public let characterOrder: [String]
    public let units: [MorseCourseUnit]
    public let lessons: [MorseCourseLesson]
}

public struct MorseLessonProgressRecord: Codable, Equatable, Sendable, Identifiable {
    public let lessonId: String
    public let attempts: Int
    public let bestAccuracy: Double
    public let lastAccuracy: Double
    public let lastAttemptedAt: String
    public let completedAt: String?

    public var id: String { lessonId }

    public init(lessonId: String, attempts: Int, bestAccuracy: Double, lastAccuracy: Double, lastAttemptedAt: String, completedAt: String?) {
        self.lessonId = lessonId
        self.attempts = attempts
        self.bestAccuracy = bestAccuracy
        self.lastAccuracy = lastAccuracy
        self.lastAttemptedAt = lastAttemptedAt
        self.completedAt = completedAt
    }
}

public struct MorseCharacterStatRecord: Codable, Equatable, Sendable, Identifiable {
    public let character: String
    public let attempts: Int
    public let correctAttempts: Int
    public let recentResults: [Bool]
    public let lastPracticedAt: String

    public var id: String { character }

    public init(character: String, attempts: Int, correctAttempts: Int, recentResults: [Bool], lastPracticedAt: String) {
        self.character = character
        self.attempts = attempts
        self.correctAttempts = correctAttempts
        self.recentResults = recentResults
        self.lastPracticedAt = lastPracticedAt
    }
}

public struct MorseDailyActivityRecord: Codable, Equatable, Sendable, Identifiable {
    public let date: String
    public let lessonsCompleted: Int

    public var id: String { date }

    public init(date: String, lessonsCompleted: Int) {
        self.date = date
        self.lessonsCompleted = lessonsCompleted
    }
}

public enum MorseCourseExercise: Equatable, Sendable {
    case meet(String)
    case choose(String, [String])
    case typeCharacter(String)
    case typeGroup(String)
}

public struct MorseCourseProgressExport: Codable, Equatable, Sendable {
    public let courseId: String
    public let lessonProgress: [MorseLessonProgressRecord]
    public let characterStats: [MorseCharacterStatRecord]
    public let dailyActivity: [MorseDailyActivityRecord]

    public init(courseId: String, lessonProgress: [MorseLessonProgressRecord], characterStats: [MorseCharacterStatRecord], dailyActivity: [MorseDailyActivityRecord]) {
        self.courseId = courseId
        self.lessonProgress = lessonProgress
        self.characterStats = characterStats
        self.dailyActivity = dailyActivity
    }
}

public enum MorseCourseError: Error, Equatable, CustomStringConvertible {
    case invalidFixture(String)
    case unknownLesson(String)

    public var description: String {
        switch self {
        case .invalidFixture(let message): return message
        case .unknownLesson(let lessonId): return "Unknown Morse lesson \(lessonId)."
        }
    }
}

public let approvedMorseCourseCharacterOrder: [String] = "K M R S U A P T L O W I . N J E F 0 Y , V G 5 / Q 9 Z H 3 8 B ? 4 2 7 C 1 D 6 X -".split(separator: " ").map(String.init)

public func decodeMorseCourse(data: Data) throws -> MorseCourse {
    let course = try JSONDecoder().decode(MorseCourse.self, from: data)
    try validateMorseCourse(course)
    return course
}

public func emptyMorseCourseProgress(courseId: String) -> MorseCourseProgressExport {
    MorseCourseProgressExport(courseId: courseId, lessonProgress: [], characterStats: [], dailyActivity: [])
}

public func morseLessonState(course: MorseCourse, progress: MorseCourseProgressExport, lessonId: String) throws -> MorseLessonState {
    guard let index = course.lessons.firstIndex(where: { $0.id == lessonId }) else {
        throw MorseCourseError.unknownLesson(lessonId)
    }
    if isMorseLessonCompleted(course: course, progress: progress, lessonId: lessonId) { return .completed }
    if index == 0 || isMorseLessonCompleted(course: course, progress: progress, lessonId: course.lessons[index - 1].id) { return .current }
    return .locked
}

public func isMorseLessonCompleted(course: MorseCourse, progress: MorseCourseProgressExport, lessonId: String) -> Bool {
    guard let record = progress.lessonProgress.first(where: { $0.lessonId == lessonId }) else { return false }
    return record.bestAccuracy >= course.unlockAccuracy
}

public func learnedMorseCharacters(course: MorseCourse, progress: MorseCourseProgressExport) -> [String] {
    let unlocked = max(1, course.lessons.filter { (try? morseLessonState(course: course, progress: progress, lessonId: $0.id)) != .locked }.count)
    return course.lessons[min(unlocked - 1, course.lessons.count - 1)].learnedCharacters
}

public func buildMorseLessonExercises(lesson: MorseCourseLesson, progress: MorseCourseProgressExport? = nil, seed: String, scoredCount: Int = 20) -> [MorseCourseExercise] {
    let scoredTotal = min(25, max(15, scoredCount))
    var random = SeededMorseRandom(seed: "\(seed):\(lesson.id)")
    let learned = lesson.learnedCharacters.filter { approvedMorseCourseCharacterOrder.contains($0) }
    let newCharacters = lesson.newCharacters.filter { approvedMorseCourseCharacterOrder.contains($0) }
    let weak = lesson.lessonNumber == 1 ? [] : (progress.map { selectWeakestMorseCharacters(stats: $0.characterStats, learnedCharacters: learned, limit: 6) } ?? [])
    let weighted = weightedPracticeCharacters(learned: learned, newCharacters: newCharacters, weak: weak)
    var exercises = newCharacters.map { MorseCourseExercise.meet($0) }
    for index in 0..<scoredTotal {
        let target = index < newCharacters.count ? newCharacters[index] : drawWeighted(weighted, random: &random)
        if index % 5 == 4 {
            exercises.append(.typeGroup(buildKochGroup(weighted, random: &random)))
        } else if index % 2 == 0 {
            exercises.append(.choose(target, chooseOptions(target: target, learned: learned, weak: weak, random: &random)))
        } else {
            exercises.append(.typeCharacter(target))
        }
    }
    return exercises
}

public func selectWeakestMorseCharacters(stats: [MorseCharacterStatRecord], learnedCharacters: [String], limit: Int = 5) -> [String] {
    let byCharacter = Dictionary(uniqueKeysWithValues: stats.map { ($0.character, $0) })
    let ranked: [(character: String, order: Int, score: Double)] = learnedCharacters.enumerated().map { index, character in
        (character: character, order: index, score: recentAccuracy(byCharacter[character]))
    }
    return ranked
        .sorted { left, right in
            if left.score == right.score { return left.order < right.order }
            return left.score < right.score
        }
        .prefix(max(0, limit))
        .map { $0.character }
}

public func recordMorseLessonAttempt(
    course: MorseCourse,
    progress: MorseCourseProgressExport,
    lessonId: String,
    correct: Int,
    total: Int,
    characterResults: [(character: String, correct: Bool)],
    attemptedAt: String,
    activityDate: String? = nil
) throws -> MorseCourseProgressExport {
    guard total > 0, correct >= 0, correct <= total else {
        throw MorseCourseError.invalidFixture("Invalid Morse lesson score.")
    }
    let accuracy = Double(correct) / Double(total)
    let existing = progress.lessonProgress.first { $0.lessonId == lessonId }
    let completedAt = accuracy >= course.unlockAccuracy ? (existing?.completedAt ?? attemptedAt) : existing?.completedAt
    let record = MorseLessonProgressRecord(
        lessonId: lessonId,
        attempts: (existing?.attempts ?? 0) + 1,
        bestAccuracy: max(existing?.bestAccuracy ?? 0, accuracy),
        lastAccuracy: accuracy,
        lastAttemptedAt: attemptedAt,
        completedAt: completedAt
    )
    let lessonProgress = (progress.lessonProgress.filter { $0.lessonId != lessonId } + [record]).sorted { $0.lessonId < $1.lessonId }
    let characterStats = updatedCharacterStats(stats: progress.characterStats, results: characterResults, attemptedAt: attemptedAt)
    let dailyActivity = accuracy >= course.unlockAccuracy ? updatedDailyActivity(progress.dailyActivity, date: activityDate ?? String(attemptedAt.prefix(10))) : progress.dailyActivity
    return MorseCourseProgressExport(courseId: course.courseId, lessonProgress: lessonProgress, characterStats: characterStats, dailyActivity: dailyActivity)
}

public func recordMorseCharacterResults(progress: MorseCourseProgressExport, results: [(character: String, correct: Bool)], attemptedAt: String) -> MorseCourseProgressExport {
    MorseCourseProgressExport(courseId: progress.courseId, lessonProgress: progress.lessonProgress, characterStats: updatedCharacterStats(stats: progress.characterStats, results: results, attemptedAt: attemptedAt), dailyActivity: progress.dailyActivity)
}

public func morseDailyStreak(activity: [MorseDailyActivityRecord], todayIso: String) -> Int {
    let dates = Set(activity.filter { $0.lessonsCompleted > 0 }.map(\.date))
    let today = String(todayIso.prefix(10))
    var cursor = dates.contains(today) ? today : shiftIsoDate(today, days: -1)
    var streak = 0
    while dates.contains(cursor) {
        streak += 1
        cursor = shiftIsoDate(cursor, days: -1)
    }
    return streak
}

private func validateMorseCourse(_ course: MorseCourse) throws {
    guard course.schemaVersion == 1, course.kind == "morse-course" else { throw MorseCourseError.invalidFixture("Unsupported Morse course fixture.") }
    guard course.unlockAccuracy == 0.9, course.unitSize == 5 else { throw MorseCourseError.invalidFixture("Morse course unlock rule must be 90 percent and units of five lessons.") }
    guard course.characterOrder == approvedMorseCourseCharacterOrder else { throw MorseCourseError.invalidFixture("Morse course character order must match the approved G4FON/ISED order.") }
    guard course.units.count == 8, course.lessons.count == 40 else { throw MorseCourseError.invalidFixture("Morse course must contain 8 units and 40 lessons.") }
    var lessonIds = Set<String>()
    for (index, lesson) in course.lessons.enumerated() {
        guard lessonIds.insert(lesson.id).inserted else { throw MorseCourseError.invalidFixture("Duplicate Morse lesson id \(lesson.id).") }
        let expectedNew = index == 0 ? Array(approvedMorseCourseCharacterOrder.prefix(2)) : [approvedMorseCourseCharacterOrder[index + 1]]
        let expectedLearned = Array(approvedMorseCourseCharacterOrder.prefix(index + 2))
        let expectedUnitId = "unit-\(String(format: "%02d", (index / 5) + 1))"
        guard lesson.lessonNumber == index + 1, lesson.unitId == expectedUnitId, lesson.newCharacters == expectedNew, lesson.learnedCharacters == expectedLearned else {
            throw MorseCourseError.invalidFixture("Morse lesson \(lesson.id) does not match the approved Koch progression.")
        }
    }
    for (index, unit) in course.units.enumerated() {
        let expectedLessonIds = course.lessons.dropFirst(index * 5).prefix(5).map(\.id)
        guard unit.unitNumber == index + 1, unit.id == "unit-\(String(format: "%02d", index + 1))", unit.lessonIds == expectedLessonIds else {
            throw MorseCourseError.invalidFixture("Morse unit \(unit.id) lesson IDs are out of order.")
        }
    }
}

private let confusableMorseCharacters: [String: [String]] = [
    "K": ["R", "M", "A"],
    "M": ["O", "T", "K"],
    "R": ["K", "A", "S"],
    "S": ["U", "R", "I"],
    "U": ["S", "A", "V"],
    "A": ["R", "U", "W"],
    "P": ["T", "L", "J"],
    "T": ["M", "O", "P"],
    "L": ["P", "F", "R"],
    "O": ["M", "T", "0"],
]

private func chooseOptions(target: String, learned: [String], weak: [String], random: inout SeededMorseRandom) -> [String] {
    let learnedSet = Set(learned)
    let candidates = unique(weak + (confusableMorseCharacters[target] ?? []) + Array(learned.suffix(8).reversed()) + learned)
        .filter { $0 != target && learnedSet.contains($0) && approvedMorseCourseCharacterOrder.contains($0) }
    return shuffle([target] + candidates.prefix(3), random: &random)
}

private func weightedPracticeCharacters(learned: [String], newCharacters: [String], weak: [String]) -> [String] {
    var weighted: [String] = []
    func append(_ characters: [String], weight: Int) {
        for character in characters where approvedMorseCourseCharacterOrder.contains(character) {
            weighted.append(contentsOf: Array(repeating: character, count: weight))
        }
    }
    append(learned, weight: 1)
    append(Array(learned.suffix(6)), weight: 1)
    append(weak, weight: 2)
    append(newCharacters, weight: 4)
    return weighted.isEmpty ? ["K"] : weighted
}

private func buildKochGroup(_ weighted: [String], random: inout SeededMorseRandom) -> String {
    (0..<5).map { _ in drawWeighted(weighted, random: &random) }.joined()
}

private func drawWeighted(_ characters: [String], random: inout SeededMorseRandom) -> String {
    characters[min(characters.count - 1, Int(random.next() * Double(characters.count)))]
}

private func unique(_ values: [String]) -> [String] {
    var seen = Set<String>()
    return values.filter { seen.insert($0).inserted }
}

private func shuffle(_ values: [String], random: inout SeededMorseRandom) -> [String] {
    var shuffled = values
    guard shuffled.count > 1 else { return shuffled }
    for index in stride(from: shuffled.count - 1, through: 1, by: -1) {
        let swapIndex = min(index, Int(random.next() * Double(index + 1)))
        shuffled.swapAt(index, swapIndex)
    }
    return shuffled
}

private struct SeededMorseRandom {
    private var state: UInt32 = 2_166_136_261

    init(seed: String) {
        for scalar in seed.unicodeScalars {
            state ^= UInt32(scalar.value)
            state = state &* 16_777_619
        }
    }

    mutating func next() -> Double {
        state = state &+ 0x6D2B79F5
        var value = state
        value = (value ^ (value >> 15)) &* (value | 1)
        value ^= value &+ ((value ^ (value >> 7)) &* (value | 61))
        return Double(value ^ (value >> 14)) / 4_294_967_296
    }
}

private func updatedCharacterStats(stats: [MorseCharacterStatRecord], results: [(character: String, correct: Bool)], attemptedAt: String) -> [MorseCharacterStatRecord] {
    var byCharacter = Dictionary(uniqueKeysWithValues: stats.map { ($0.character, $0) })
    for result in results where approvedMorseCourseCharacterOrder.contains(result.character) {
        let current = byCharacter[result.character]
        byCharacter[result.character] = MorseCharacterStatRecord(
            character: result.character,
            attempts: (current?.attempts ?? 0) + 1,
            correctAttempts: (current?.correctAttempts ?? 0) + (result.correct ? 1 : 0),
            recentResults: Array(((current?.recentResults ?? []) + [result.correct]).suffix(20)),
            lastPracticedAt: attemptedAt
        )
    }
    return byCharacter.values.sorted { (approvedMorseCourseCharacterOrder.firstIndex(of: $0.character) ?? 0) < (approvedMorseCourseCharacterOrder.firstIndex(of: $1.character) ?? 0) }
}

private func updatedDailyActivity(_ activity: [MorseDailyActivityRecord], date: String) -> [MorseDailyActivityRecord] {
    let current = activity.first { $0.date == date }
    return (activity.filter { $0.date != date } + [MorseDailyActivityRecord(date: date, lessonsCompleted: (current?.lessonsCompleted ?? 0) + 1)]).sorted { $0.date < $1.date }
}

private func recentAccuracy(_ stat: MorseCharacterStatRecord?) -> Double {
    guard let stat, !stat.recentResults.isEmpty else { return -1 }
    return Double(stat.recentResults.filter { $0 }.count) / Double(stat.recentResults.count)
}

private func shiftIsoDate(_ value: String, days: Int) -> String {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
    var components = DateComponents()
    components.calendar = calendar
    components.timeZone = calendar.timeZone
    components.year = Int(value.prefix(4))
    components.month = Int(value.dropFirst(5).prefix(2))
    components.day = Int(value.dropFirst(8).prefix(2))
    components.day = (components.day ?? 1) + days
    let date = calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter.string(from: date)
}
