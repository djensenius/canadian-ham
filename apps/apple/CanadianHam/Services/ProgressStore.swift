import CanadianHamEngine
import CanadianHamMorseEngine
#if ICLOUD_SYNC
@preconcurrency import CloudKit
#endif
import Foundation
import SwiftData

struct ApplePreferences: Codable, Equatable, Sendable {
    enum PracticeMode: String, Codable, CaseIterable, Identifiable, Sendable {
        case immediate
        case reviewLater = "review-later"

        var id: String { rawValue }

        var label: String {
            switch self {
            case .immediate: "Immediate feedback"
            case .reviewLater: "Review later"
            }
        }
    }

    enum Theme: String, Codable, CaseIterable, Identifiable, Sendable {
        case system
        case light
        case dark

        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }

    var practiceMode: PracticeMode
    var examTimerEnabled: Bool
    var language: BankLanguage
    var theme: Theme
    var activeBankId: CourseBankID

    static let `default` = ApplePreferences(
        practiceMode: .immediate,
        examTimerEnabled: false,
        language: .english,
        theme: .system,
        activeBankId: .basic
    )
}

enum ICloudSyncDatabaseSelection: Equatable, Sendable {
    case none
    case privateDatabase(String)
}

enum ICloudAccountSignal: Equatable, Sendable {
    case accountChanged
    case signedOut
    case iCloudDisabled
}

enum ICloudAccountAvailability: Equatable, Sendable {
    case available
    case noAccount
    case restricted
    case temporarilyUnavailable
    case couldNotDetermine
}

struct ICloudSyncSettings: Equatable, Sendable {
    static let containerIdentifier = "iCloud.org.davidjensenius.CanadianHam"

    private static let optInPreferenceKey = "CanadianHam.iCloudSyncOptIn"

    static var isBuildEnabled: Bool {
#if ICLOUD_SYNC
        true
#else
        false
#endif
    }

    static func storedOptIn(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: optInPreferenceKey)
    }

    static func setStoredOptIn(_ enabled: Bool, defaults: UserDefaults = .standard) {
        defaults.set(enabled, forKey: optInPreferenceKey)
    }

    static func clearStoredOptIn(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: optInPreferenceKey)
    }

    static func databaseSelection(storedOptIn: Bool, buildEnabled: Bool = isBuildEnabled) -> ICloudSyncDatabaseSelection {
        guard buildEnabled, storedOptIn else { return .none }
        return .privateDatabase(containerIdentifier)
    }

    static func signal(for availability: ICloudAccountAvailability) -> ICloudAccountSignal? {
        switch availability {
        case .available, .temporarilyUnavailable, .couldNotDetermine:
            nil
        case .noAccount:
            .signedOut
        case .restricted:
            .iCloudDisabled
        }
    }

    static func handleAccountSignal(_ signal: ICloudAccountSignal, defaults: UserDefaults = .standard) {
        switch signal {
        case .accountChanged, .signedOut, .iCloudDisabled:
            setStoredOptIn(false, defaults: defaults)
        }
    }
}

struct ProgressStoreConfigurationPlan: Equatable, Sendable {
    let progressDatabase: ICloudSyncDatabaseSelection
    let preferencesDatabase: ICloudSyncDatabaseSelection
}

struct ProgressStoreURLs: Equatable, Sendable {
    let persistentStoreURL: URL
    let preferencesStoreURL: URL
    let morseCourseProgressURL: URL
    let legacyPreferencesCopyMarkerURL: URL

    init(progressDirectory: URL) {
        self.persistentStoreURL = progressDirectory.appending(path: "Progress.store")
        self.preferencesStoreURL = progressDirectory.appending(path: "Preferences.store")
        self.morseCourseProgressURL = progressDirectory.appending(path: "MorseCourseProgress.json")
        self.legacyPreferencesCopyMarkerURL = progressDirectory.appending(path: "Preferences.store.legacy-copy-complete")
    }

    @MainActor
    static var standard: ProgressStoreURLs {
        ProgressStoreURLs(progressDirectory: ProgressStoreService.progressDirectory)
    }
}

enum ProgressStoreConfigurationLayout: Equatable, Sendable {
    case automatic
    case legacySingleStore
    case split
}

private struct PreferencesEntitySnapshot: Equatable, Sendable {
    let key: String
    let practiceMode: String
    let examTimerEnabled: Bool
    let language: String
    let theme: String
    let archivedLessonProgressData: Data
    let archivedLessonQuizAttemptsData: Data
}

extension BankLanguage: Codable {}

struct ProgressExportV1: Codable, Equatable, Sendable {
    let schema: String
    let version: Int
    let exportedAt: String
    let bankId: String
    let questionProgress: [QuestionProgressRecord]
    let examAttempts: [StoredExamAttempt]
    let lessonProgress: [ArchivedJSON]
    let lessonQuizAttempts: [ArchivedJSON]
    let morseCourseProgress: MorseCourseProgressExport?
    let preferences: ExportedPreferences

    init(
        schema: String,
        version: Int,
        exportedAt: String,
        bankId: String,
        questionProgress: [QuestionProgressRecord],
        examAttempts: [StoredExamAttempt],
        lessonProgress: [ArchivedJSON],
        lessonQuizAttempts: [ArchivedJSON],
        morseCourseProgress: MorseCourseProgressExport? = nil,
        preferences: ExportedPreferences
    ) {
        self.schema = schema
        self.version = version
        self.exportedAt = exportedAt
        self.bankId = bankId
        self.questionProgress = questionProgress
        self.examAttempts = examAttempts
        self.lessonProgress = lessonProgress
        self.lessonQuizAttempts = lessonQuizAttempts
        self.morseCourseProgress = morseCourseProgress
        self.preferences = preferences
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schema = try container.decode(String.self, forKey: .schema)
        version = try container.decode(Int.self, forKey: .version)
        exportedAt = try container.decode(String.self, forKey: .exportedAt)
        bankId = try container.decodeIfPresent(String.self, forKey: .bankId) ?? basicBankId
        questionProgress = try container.decode([QuestionProgressRecord].self, forKey: .questionProgress)
        examAttempts = try container.decode([StoredExamAttempt].self, forKey: .examAttempts)
        lessonProgress = try container.decodeIfPresent([ArchivedJSON].self, forKey: .lessonProgress) ?? []
        lessonQuizAttempts = try container.decodeIfPresent([ArchivedJSON].self, forKey: .lessonQuizAttempts) ?? []
        morseCourseProgress = try container.decodeIfPresent(MorseCourseProgressExport.self, forKey: .morseCourseProgress)
        preferences = try container.decode(ExportedPreferences.self, forKey: .preferences)
    }
}

struct LessonProgressRecord: Codable, Equatable, Sendable, Identifiable {
    let lessonId: String
    let readAt: String
    let readCount: Int

    var id: String { lessonId }
}

struct LessonQuizAttempt: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let quizId: String
    let lessonId: String
    let submittedAt: String
    let correct: Int
    let total: Int
    let percent: Double
    let officialQuestionIds: [String]
    let incorrectOfficialQuestionIds: [String]
    let incorrectConceptCheckIds: [String]
}

struct ExportedPreferences: Codable, Equatable, Sendable {
    let practiceMode: String
    let examTimerEnabled: Bool
    let theme: String
    let morse: ExportedMorseSettings

    init(practiceMode: String, examTimerEnabled: Bool, theme: String = ApplePreferences.Theme.system.rawValue, morse: ExportedMorseSettings = .default) {
        self.practiceMode = practiceMode
        self.examTimerEnabled = examTimerEnabled
        self.theme = theme
        self.morse = morse
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        practiceMode = try container.decode(String.self, forKey: .practiceMode)
        examTimerEnabled = try container.decode(Bool.self, forKey: .examTimerEnabled)
        theme = try container.decodeIfPresent(String.self, forKey: .theme) ?? ApplePreferences.Theme.system.rawValue
        morse = try container.decodeIfPresent(ExportedMorseSettings.self, forKey: .morse) ?? .default
    }
}

struct ArchivedJSON: Codable, Equatable, Sendable {
    let storage: [String: JSONValue]

    init(storage: [String: JSONValue]) {
        self.storage = storage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        storage = try container.decode([String: JSONValue].self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(storage)
    }
}

enum JSONValue: Codable, Equatable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            self = .array(try container.decode([JSONValue].self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}

struct StoredExamAttemptItem: Codable, Equatable, Sendable, Identifiable {
    let position: Int
    let questionId: String
    let subsectionId: String
    let categoryId: String
    let choicePermutation: [Int]
    let selectedSourceIndex: Int?
    let isCorrect: Bool
    let flagged: Bool

    var id: String { questionId }
}

struct StoredExamTimer: Codable, Equatable, Sendable {
    let enabled: Bool
    let secondsAllowed: Int?
    let secondsElapsed: Int

    private enum CodingKeys: String, CodingKey {
        case enabled
        case secondsAllowed
        case secondsElapsed
    }

    init(enabled: Bool, secondsAllowed: Int?, secondsElapsed: Int) {
        self.enabled = enabled
        self.secondsAllowed = secondsAllowed
        self.secondsElapsed = secondsElapsed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try container.decode(Bool.self, forKey: .enabled)
        secondsAllowed = try Self.decodeOptionalNonNegativeIntegerCompatibleNumber(from: container, forKey: .secondsAllowed)
        secondsElapsed = try Self.decodeNonNegativeIntegerCompatibleNumber(from: container, forKey: .secondsElapsed)
    }

    private static func decodeOptionalNonNegativeIntegerCompatibleNumber(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Int? {
        if !container.contains(key) { return nil }
        if try container.decodeNil(forKey: key) { return nil }
        return try decodeNonNegativeIntegerCompatibleNumber(from: container, forKey: key)
    }

    private static func decodeNonNegativeIntegerCompatibleNumber(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Int {
        if let intValue = try? container.decode(Int.self, forKey: key) {
            return intValue
        }
        let doubleValue = try container.decode(Double.self, forKey: key)
        guard doubleValue.isFinite, doubleValue >= 0 else {
            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Expected a non-negative finite number.")
        }
        let roundedValue = doubleValue.rounded()
        guard let intValue = Int(exactly: roundedValue) else {
            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Expected a number within the supported integer range.")
        }
        return intValue
    }
}

struct StoredExamScore: Codable, Equatable, Sendable {
    let bankId: String
    let correct: Int
    let total: Int
    let percent: Double
    let passed: Bool
    let honours: Bool
    let categoryBreakdown: [CategoryBreakdownEntry]
    let weakSubsectionIds: [String]

    private enum CodingKeys: String, CodingKey {
        case bankId
        case correct
        case total
        case percent
        case passed
        case honours
        case categoryBreakdown
        case weakSubsectionIds
    }

    init(
        bankId: String,
        correct: Int,
        total: Int,
        percent: Double,
        passed: Bool,
        honours: Bool,
        categoryBreakdown: [CategoryBreakdownEntry],
        weakSubsectionIds: [String]
    ) {
        self.bankId = bankId
        self.correct = correct
        self.total = total
        self.percent = percent
        self.passed = passed
        self.honours = honours
        self.categoryBreakdown = categoryBreakdown
        self.weakSubsectionIds = weakSubsectionIds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bankId = try container.decodeIfPresent(String.self, forKey: .bankId) ?? basicBankId
        correct = try container.decode(Int.self, forKey: .correct)
        total = try container.decode(Int.self, forKey: .total)
        percent = try container.decode(Double.self, forKey: .percent)
        passed = try container.decode(Bool.self, forKey: .passed)
        honours = try container.decode(Bool.self, forKey: .honours)
        categoryBreakdown = try container.decode([CategoryBreakdownEntry].self, forKey: .categoryBreakdown)
        weakSubsectionIds = try container.decode([String].self, forKey: .weakSubsectionIds)
    }
}

struct StoredExamAttempt: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let bankId: String
    let mode: String
    let seed: String
    let startedAt: String
    let submittedAt: String
    let timer: StoredExamTimer
    let items: [StoredExamAttemptItem]
    let score: StoredExamScore

    private enum CodingKeys: String, CodingKey {
        case id
        case bankId
        case mode
        case seed
        case startedAt
        case submittedAt
        case timer
        case items
        case score
    }

    init(
        id: String,
        bankId: String,
        mode: String,
        seed: String,
        startedAt: String,
        submittedAt: String,
        timer: StoredExamTimer,
        items: [StoredExamAttemptItem],
        score: StoredExamScore
    ) {
        self.id = id
        self.bankId = bankId
        self.mode = mode
        self.seed = seed
        self.startedAt = startedAt
        self.submittedAt = submittedAt
        self.timer = timer
        self.items = items
        self.score = score
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        bankId = try container.decodeIfPresent(String.self, forKey: .bankId) ?? basicBankId
        mode = try container.decode(String.self, forKey: .mode)
        seed = try container.decode(String.self, forKey: .seed)
        startedAt = try container.decode(String.self, forKey: .startedAt)
        submittedAt = try container.decode(String.self, forKey: .submittedAt)
        timer = try container.decode(StoredExamTimer.self, forKey: .timer)
        items = try container.decode([StoredExamAttemptItem].self, forKey: .items)
        score = try container.decode(StoredExamScore.self, forKey: .score)
    }
}

enum ProgressStoreError: LocalizedError, Equatable {
    case validationFailed([String])
    case openFailed(String)

    var errorDescription: String? {
        switch self {
        case .validationFailed(let errors):
            errors.joined(separator: "\n")
        case .openFailed(let message):
            message
        }
    }
}

#if DEBUG
enum ProgressStoreInjectedFailure: Error, Equatable {
    case importAfterDelete
    case importAfterMorseWrite
    case lessonQuizSave
    case morseCourseProgressRemoval
}
#endif

private struct ProgressStoreSnapshot {
    let questionProgress: [QuestionProgressRecord]
    let examAttempts: [StoredExamAttempt]
    let preferences: ApplePreferences
    let archivedLessonProgressData: Data
    let archivedLessonQuizAttemptsData: Data
    let morseCourseProgressData: Data?
}

@MainActor
final class ProgressStoreService: ObservableObject {
    @Published private(set) var preferences: ApplePreferences = .default
    @Published private(set) var isICloudSyncEnabled: Bool = ICloudSyncSettings.storedOptIn()

    let container: ModelContainer
    private let context: ModelContext
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let storeURLs: ProgressStoreURLs
    private let morseCourseProgressURL: URL
#if DEBUG
    var morseCourseProgressURLForTesting: URL { morseCourseProgressURL }
    var failNextImportAfterDeleteForTesting = false
    var failNextImportAfterMorseWriteForTesting = false
    var failNextLessonQuizSaveForTesting = false
    var failNextMorseCourseProgressRemovalForTesting = false
#endif
#if ICLOUD_SYNC
    private var iCloudAccountChangedObserver: NSObjectProtocol?
#endif

    init(
        container: ModelContainer,
        storeURLs: ProgressStoreURLs = .standard,
        morseCourseProgressURL: URL? = nil,
        iCloudSyncEnabled: Bool = ICloudSyncSettings.storedOptIn()
    ) throws {
        self.container = container
        self.context = ModelContext(container)
        self.storeURLs = storeURLs
        self.morseCourseProgressURL = morseCourseProgressURL ?? storeURLs.morseCourseProgressURL
        self.isICloudSyncEnabled = iCloudSyncEnabled
        try FileManager.default.createDirectory(at: self.morseCourseProgressURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        self.preferences = try loadPreferences()
#if ICLOUD_SYNC
        if iCloudSyncEnabled {
            startICloudAccountMonitoring()
        }
#endif
    }

    static func open() throws -> ProgressStoreService {
        try open(storeURLs: .standard)
    }

    static func open(
        storeURLs: ProgressStoreURLs,
        iCloudSyncEnabled: Bool = ICloudSyncSettings.storedOptIn(),
        layout: ProgressStoreConfigurationLayout = .automatic
    ) throws -> ProgressStoreService {
        do {
            let resolvedLayout = resolvedLayout(layout)
            let shouldAttemptLegacyCopy = shouldAttemptLegacyPreferencesCopy(storeURLs: storeURLs, layout: resolvedLayout)
            let legacyPreferences = legacyPreferencesSnapshotsIfNeeded(storeURLs: storeURLs, shouldAttemptCopy: shouldAttemptLegacyCopy)
            let container = try makeModelContainer(
                iCloudSyncEnabled: iCloudSyncEnabled,
                isStoredInMemoryOnly: false,
                storeURLs: storeURLs,
                layout: resolvedLayout
            )
            try copyLegacyPreferencesIfNeeded(legacyPreferences, into: container, layout: resolvedLayout)
            if shouldAttemptLegacyCopy {
                markLegacyPreferencesCopyComplete(storeURLs: storeURLs)
            }
            return try ProgressStoreService(
                container: container,
                storeURLs: storeURLs,
                iCloudSyncEnabled: iCloudSyncEnabled
            )
        } catch {
            throw ProgressStoreError.openFailed(error.localizedDescription)
        }
    }

    static func inMemoryForTests(iCloudSyncEnabled: Bool = false, layout: ProgressStoreConfigurationLayout = .automatic) throws -> ProgressStoreService {
        let container = try makeModelContainer(
            iCloudSyncEnabled: iCloudSyncEnabled,
            isStoredInMemoryOnly: true,
            storeURLs: .standard,
            layout: resolvedLayout(layout)
        )
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "CanadianHamProgressStoreTests", directoryHint: .isDirectory)
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return try ProgressStoreService(
            container: container,
            storeURLs: ProgressStoreURLs(progressDirectory: directory),
            iCloudSyncEnabled: iCloudSyncEnabled
        )
    }

    static func configurationPlan(
        iCloudSyncEnabled: Bool,
        buildEnabled: Bool = ICloudSyncSettings.isBuildEnabled
    ) -> ProgressStoreConfigurationPlan {
        ProgressStoreConfigurationPlan(
            progressDatabase: ICloudSyncSettings.databaseSelection(storedOptIn: iCloudSyncEnabled, buildEnabled: buildEnabled),
            preferencesDatabase: .none
        )
    }

    private static func resolvedLayout(_ layout: ProgressStoreConfigurationLayout) -> ProgressStoreConfigurationLayout {
        switch layout {
        case .legacySingleStore, .split:
            layout
        case .automatic:
#if ICLOUD_SYNC
            .split
#else
            .legacySingleStore
#endif
        }
    }

    private static func makeModelContainer(
        iCloudSyncEnabled: Bool,
        isStoredInMemoryOnly: Bool = false,
        storeURLs: ProgressStoreURLs,
        layout: ProgressStoreConfigurationLayout
    ) throws -> ModelContainer {
        switch layout {
        case .automatic:
            return try makeModelContainer(
                iCloudSyncEnabled: iCloudSyncEnabled,
                isStoredInMemoryOnly: isStoredInMemoryOnly,
                storeURLs: storeURLs,
                layout: resolvedLayout(layout)
            )
        case .legacySingleStore:
            return try makeLegacySingleStoreModelContainer(isStoredInMemoryOnly: isStoredInMemoryOnly, storeURLs: storeURLs)
        case .split:
            return try makeSplitModelContainer(iCloudSyncEnabled: iCloudSyncEnabled, isStoredInMemoryOnly: isStoredInMemoryOnly, storeURLs: storeURLs)
        }
    }

    private static func makeLegacySingleStoreModelContainer(isStoredInMemoryOnly: Bool, storeURLs: ProgressStoreURLs) throws -> ModelContainer {
        let schema = Schema(versionedSchema: CanadianHamProgressSchemaV2.self)
        let configuration: ModelConfiguration
        if isStoredInMemoryOnly {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        } else {
            configuration = ModelConfiguration(schema: schema, url: storeURLs.persistentStoreURL, cloudKitDatabase: .none)
        }
        return try ModelContainer(for: schema, migrationPlan: CanadianHamProgressMigrationPlan.self, configurations: [configuration])
    }

    private static func makeSplitModelContainer(iCloudSyncEnabled: Bool, isStoredInMemoryOnly: Bool, storeURLs: ProgressStoreURLs) throws -> ModelContainer {
        let schema = Schema(versionedSchema: CanadianHamProgressSchemaV2.self)
        let plan = configurationPlan(iCloudSyncEnabled: iCloudSyncEnabled)
        let progressSchema = Schema([QuestionProgressEntity.self, ExamAttemptEntity.self])
        let preferencesSchema = Schema([PreferencesEntity.self])
        let progressConfiguration: ModelConfiguration
        let preferencesConfiguration: ModelConfiguration
        if isStoredInMemoryOnly {
#if ICLOUD_SYNC
            progressConfiguration = ModelConfiguration(
                "LearningProgress",
                schema: progressSchema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: cloudKitDatabase(for: plan.progressDatabase)
            )
#else
            progressConfiguration = ModelConfiguration(
                "LearningProgress",
                schema: progressSchema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
#endif
            preferencesConfiguration = ModelConfiguration(
                "LocalPreferences",
                schema: preferencesSchema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
        } else {
#if ICLOUD_SYNC
            progressConfiguration = ModelConfiguration(
                "LearningProgress",
                schema: progressSchema,
                url: storeURLs.persistentStoreURL,
                cloudKitDatabase: cloudKitDatabase(for: plan.progressDatabase)
            )
#else
            progressConfiguration = ModelConfiguration(
                "LearningProgress",
                schema: progressSchema,
                url: storeURLs.persistentStoreURL,
                cloudKitDatabase: .none
            )
#endif
            preferencesConfiguration = ModelConfiguration(
                "LocalPreferences",
                schema: preferencesSchema,
                url: storeURLs.preferencesStoreURL,
                cloudKitDatabase: .none
            )
        }
        return try ModelContainer(
            for: schema,
            migrationPlan: CanadianHamProgressMigrationPlan.self,
            configurations: [progressConfiguration, preferencesConfiguration]
        )
    }

    private static func shouldAttemptLegacyPreferencesCopy(
        storeURLs: ProgressStoreURLs,
        layout: ProgressStoreConfigurationLayout
    ) -> Bool {
        guard layout == .split else { return false }
        guard !FileManager.default.fileExists(atPath: storeURLs.legacyPreferencesCopyMarkerURL.path(percentEncoded: false)) else { return false }
        guard !FileManager.default.fileExists(atPath: storeURLs.preferencesStoreURL.path(percentEncoded: false)) else { return false }
        return FileManager.default.fileExists(atPath: storeURLs.persistentStoreURL.path(percentEncoded: false))
    }

    private static func legacyPreferencesSnapshotsIfNeeded(
        storeURLs: ProgressStoreURLs,
        shouldAttemptCopy: Bool
    ) -> [PreferencesEntitySnapshot] {
        guard shouldAttemptCopy else { return [] }
        do {
            let legacyContainer = try makeLegacySingleStoreModelContainer(isStoredInMemoryOnly: false, storeURLs: storeURLs)
            let legacyContext = ModelContext(legacyContainer)
            let descriptor = FetchDescriptor<PreferencesEntity>(sortBy: [SortDescriptor(\.key)])
            return try legacyContext.fetch(descriptor).map { entity in
                PreferencesEntitySnapshot(
                    key: entity.key,
                    practiceMode: entity.practiceMode,
                    examTimerEnabled: entity.examTimerEnabled,
                    language: entity.language,
                    theme: entity.theme,
                    archivedLessonProgressData: entity.archivedLessonProgressData,
                    archivedLessonQuizAttemptsData: entity.archivedLessonQuizAttemptsData
                )
            }
        } catch {
            NSLog("CanadianHam: unable to copy legacy preferences into split store: %@", String(describing: error))
            return []
        }
    }

    private static func copyLegacyPreferencesIfNeeded(
        _ snapshots: [PreferencesEntitySnapshot],
        into container: ModelContainer,
        layout: ProgressStoreConfigurationLayout
    ) throws {
        guard layout == .split, !snapshots.isEmpty else { return }
        let context = ModelContext(container)
        let existing = try context.fetch(FetchDescriptor<PreferencesEntity>())
        guard existing.isEmpty else { return }
        for snapshot in snapshots {
            let entity = PreferencesEntity(
                key: snapshot.key,
                practiceMode: snapshot.practiceMode,
                examTimerEnabled: snapshot.examTimerEnabled,
                language: snapshot.language,
                theme: snapshot.theme,
                archivedLessonProgressData: snapshot.archivedLessonProgressData,
                archivedLessonQuizAttemptsData: snapshot.archivedLessonQuizAttemptsData
            )
            context.insert(entity)
        }
        try context.save()
    }

    private static func markLegacyPreferencesCopyComplete(storeURLs: ProgressStoreURLs) {
        try? FileManager.default.createDirectory(at: storeURLs.legacyPreferencesCopyMarkerURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: storeURLs.legacyPreferencesCopyMarkerURL.path(percentEncoded: false)) {
            FileManager.default.createFile(atPath: storeURLs.legacyPreferencesCopyMarkerURL.path(percentEncoded: false), contents: Data(), attributes: nil)
        }
    }

#if ICLOUD_SYNC
    private static func cloudKitDatabase(for selection: ICloudSyncDatabaseSelection) -> ModelConfiguration.CloudKitDatabase {
        switch selection {
        case .none:
            .none
        case .privateDatabase(let identifier):
            .private(identifier)
        }
    }
#endif

    static var persistentStoreURL: URL {
        ProgressStoreURLs.standard.persistentStoreURL
    }

    static var preferencesStoreURL: URL {
        ProgressStoreURLs.standard.preferencesStoreURL
    }

    static var progressDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = base.appending(path: "CanadianHam", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static var morseCourseProgressURL: URL {
        ProgressStoreURLs.standard.morseCourseProgressURL
    }

    private static let activeBankPreferenceKey = "CanadianHam.activeBankId"

    static func resetPersistentStoreFiles() {
        UserDefaults.standard.removeObject(forKey: activeBankPreferenceKey)
        ICloudSyncSettings.clearStoredOptIn()
        let urls = ProgressStoreURLs.standard
        for url in [urls.persistentStoreURL, urls.preferencesStoreURL] {
            for suffix in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + suffix))
            }
        }
        try? FileManager.default.removeItem(at: urls.legacyPreferencesCopyMarkerURL)
        try? FileManager.default.removeItem(at: urls.morseCourseProgressURL)
    }

    func updateICloudSyncOptIn(_ enabled: Bool, defaults: UserDefaults = .standard) {
        ICloudSyncSettings.setStoredOptIn(enabled, defaults: defaults)
        isICloudSyncEnabled = ICloudSyncSettings.storedOptIn(defaults: defaults)
    }

    func handleICloudAccountSignal(_ signal: ICloudAccountSignal, defaults: UserDefaults = .standard) {
        ICloudSyncSettings.handleAccountSignal(signal, defaults: defaults)
        isICloudSyncEnabled = ICloudSyncSettings.storedOptIn(defaults: defaults)
    }

    func handleICloudAccountAvailability(_ availability: ICloudAccountAvailability, defaults: UserDefaults = .standard) {
        guard let signal = ICloudSyncSettings.signal(for: availability) else { return }
        handleICloudAccountSignal(signal, defaults: defaults)
    }

#if ICLOUD_SYNC
    private func startICloudAccountMonitoring() {
        iCloudAccountChangedObserver = NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleICloudAccountSignal(.accountChanged)
            }
        }
        checkICloudAccountStatusAtLaunch()
    }

    private func checkICloudAccountStatusAtLaunch() {
        CKContainer(identifier: ICloudSyncSettings.containerIdentifier).accountStatus { [weak self] status, error in
            guard error == nil else { return }
            Task { @MainActor in
                self?.handleICloudAccountAvailability(Self.availability(for: status))
            }
        }
    }

    private static func availability(for status: CKAccountStatus) -> ICloudAccountAvailability {
        switch status {
        case .available:
            .available
        case .noAccount:
            .noAccount
        case .restricted:
            .restricted
        case .temporarilyUnavailable:
            .temporarilyUnavailable
        case .couldNotDetermine:
            .couldNotDetermine
        @unknown default:
            .couldNotDetermine
        }
    }
#endif

    func questionProgressRecords() throws -> [QuestionProgressRecord] {
        let descriptor = FetchDescriptor<QuestionProgressEntity>(sortBy: [SortDescriptor(\.questionId)])
        return try context.fetch(descriptor).map { try questionProgressRecord(from: $0) }
    }

    func examAttempts() throws -> [StoredExamAttempt] {
        let descriptor = FetchDescriptor<ExamAttemptEntity>(sortBy: [SortDescriptor(\.submittedAt)])
        return try context.fetch(descriptor).map { try decoder.decode(StoredExamAttempt.self, from: $0.payloadData) }
    }

    func latestExamAttempt() throws -> StoredExamAttempt? {
        try examAttempts().sorted { $0.submittedAt > $1.submittedAt }.first
    }

    func lessonProgressRecords() throws -> [LessonProgressRecord] {
        let entity = try preferencesEntity(createIfMissing: true)
        return try decoder.decode([LessonProgressRecord].self, from: entity.archivedLessonProgressData)
            .sorted { $0.lessonId < $1.lessonId }
    }

    func lessonQuizAttempts() throws -> [LessonQuizAttempt] {
        let entity = try preferencesEntity(createIfMissing: true)
        return try decoder.decode([LessonQuizAttempt].self, from: entity.archivedLessonQuizAttemptsData)
            .sorted { $0.submittedAt < $1.submittedAt }
    }

    func saveLessonProgress(_ record: LessonProgressRecord) throws {
        let entity = try preferencesEntity(createIfMissing: true)
        let current = try lessonProgressRecords().filter { $0.lessonId != record.lessonId }
        entity.archivedLessonProgressData = try encoder.encode((current + [record]).sorted { $0.lessonId < $1.lessonId })
        try context.save()
        objectWillChange.send()
    }

    func morseCourseProgress() throws -> MorseCourseProgressExport? {
        guard FileManager.default.fileExists(atPath: morseCourseProgressURL.path(percentEncoded: false)) else { return nil }
        let data = try Data(contentsOf: morseCourseProgressURL)
        return try decoder.decode(MorseCourseProgressExport.self, from: data)
    }

    func saveMorseCourseProgress(_ progress: MorseCourseProgressExport) throws {
        let data = try encoder.encode(progress)
        try FileManager.default.createDirectory(at: morseCourseProgressURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: morseCourseProgressURL, options: [.atomic])
        objectWillChange.send()
    }

    func saveLessonQuizAttempt(_ attempt: LessonQuizAttempt, questionProgress: [QuestionProgressRecord]) throws {
        do {
            let entity = try preferencesEntity(createIfMissing: true, saveIfCreated: false)
            let attempts = try decoder.decode([LessonQuizAttempt].self, from: entity.archivedLessonQuizAttemptsData)
            entity.archivedLessonQuizAttemptsData = try encoder.encode((attempts + [attempt]).sorted { $0.submittedAt < $1.submittedAt })
            for record in questionProgress {
                try upsertQuestionProgress(record)
            }
#if DEBUG
            if failNextLessonQuizSaveForTesting {
                failNextLessonQuizSaveForTesting = false
                throw ProgressStoreInjectedFailure.lessonQuizSave
            }
#endif
            try context.save()
            objectWillChange.send()
        } catch {
            context.rollback()
            throw error
        }
    }

    func saveQuestionProgress(_ records: [QuestionProgressRecord]) throws {
        for record in records {
            try upsertQuestionProgress(record)
        }
        try context.save()
        objectWillChange.send()
    }

    func saveExamAttempt(_ attempt: StoredExamAttempt) throws {
        let data = try encoder.encode(attempt)
        // Web exports may regenerate local IDs; submittedAt is canonical and import validation forbids duplicates.
        if let existing = try examAttemptEntity(id: attempt.id, submittedAt: attempt.submittedAt) {
            existing.id = attempt.id
            existing.bankId = attempt.bankId
            existing.seed = attempt.seed
            existing.startedAt = attempt.startedAt
            existing.submittedAt = attempt.submittedAt
            existing.payloadData = data
        } else {
            context.insert(ExamAttemptEntity(
                id: attempt.id,
                bankId: attempt.bankId,
                seed: attempt.seed,
                startedAt: attempt.startedAt,
                submittedAt: attempt.submittedAt,
                payloadData: data
            ))
        }
        try context.save()
        objectWillChange.send()
    }

    func updatePreferences(_ preferences: ApplePreferences) throws {
        let entity = try preferencesEntity(createIfMissing: true)
        entity.practiceMode = preferences.practiceMode.rawValue
        entity.examTimerEnabled = preferences.examTimerEnabled
        entity.language = preferences.language.rawValue
        entity.theme = preferences.theme.rawValue
        do {
            try context.save()
        } catch {
            // Keep the stored and published preferences unchanged when the save fails.
            context.rollback()
            throw error
        }
        UserDefaults.standard.set(preferences.activeBankId.rawValue, forKey: Self.activeBankPreferenceKey)
        self.preferences = preferences
    }

    func resetAllData() throws {
        let previousSnapshot = try snapshotForRollback()
        do {
            try context.delete(model: QuestionProgressEntity.self)
            try context.delete(model: ExamAttemptEntity.self)
            try context.delete(model: PreferencesEntity.self)
            try removeMorseCourseProgressIfPresent()
            UserDefaults.standard.removeObject(forKey: Self.activeBankPreferenceKey)
            preferences = .default
            Self.markLegacyPreferencesCopyComplete(storeURLs: storeURLs)
            try context.save()
            // Reset all data also turns iCloud sync back off, but only once the reset has been saved.
            ICloudSyncSettings.clearStoredOptIn()
            isICloudSyncEnabled = false
            objectWillChange.send()
        } catch {
            context.rollback()
            try restore(previousSnapshot)
            throw error
        }
    }

    func exportData(bank: QuestionBank, exportedAt: String, morseSettings: ExportedMorseSettings = .default) throws -> ProgressExportV1 {
        try CanonicalTimestamp.require(exportedAt, fieldName: "exportedAt")
        let entity = try preferencesEntity(createIfMissing: true)
        let lessonProgress = try decoder.decode([ArchivedJSON].self, from: entity.archivedLessonProgressData)
        let lessonQuizAttempts = try decoder.decode([ArchivedJSON].self, from: entity.archivedLessonQuizAttemptsData)
        return ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: exportedAt,
            bankId: bank.manifest.bankId,
            questionProgress: try questionProgressRecords().filter { $0.bankId == bank.manifest.bankId },
            examAttempts: try examAttempts().filter { $0.bankId == bank.manifest.bankId },
            lessonProgress: bank.courseBankID.hasLessons ? lessonProgress : [],
            lessonQuizAttempts: bank.courseBankID.hasLessons ? lessonQuizAttempts : [],
            morseCourseProgress: try morseCourseProgress(),
            preferences: ExportedPreferences(
                practiceMode: preferences.practiceMode.rawValue,
                examTimerEnabled: preferences.examTimerEnabled,
                theme: preferences.theme.rawValue,
                morse: morseSettings
            )
        )
    }

    func serializedExport(bank: QuestionBank, exportedAt: String, morseSettings: ExportedMorseSettings = .default) throws -> String {
        let data = try exportData(bank: bank, exportedAt: exportedAt, morseSettings: morseSettings)
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return String(decoding: try encoder.encode(data), as: UTF8.self) + "\n"
    }

    func importData(_ data: ProgressExportV1, bank: QuestionBank) throws {
        let errors = validate(data, bank: bank)
        if !errors.isEmpty {
            throw ProgressStoreError.validationFailed(errors)
        }

        let previousSnapshot = try snapshotForRollback()
        do {
            try deleteQuestionProgress(bankId: bank.manifest.bankId)
            try deleteExamAttempts(bankId: bank.manifest.bankId)
#if DEBUG
            if failNextImportAfterDeleteForTesting {
                failNextImportAfterDeleteForTesting = false
                throw ProgressStoreInjectedFailure.importAfterDelete
            }
#endif
            // Commit deletions before reinserting replacement records so the bank-scoped
            // replace-all import has a clean rollback boundary.
            try context.save()
            for record in data.questionProgress {
                try upsertQuestionProgress(record)
            }
            for attempt in data.examAttempts {
                try saveExamAttemptWithoutSave(attempt)
            }
            var nextPreferences = preferences
            if let mode = ApplePreferences.PracticeMode(rawValue: data.preferences.practiceMode) {
                nextPreferences.practiceMode = mode
            }
            nextPreferences.examTimerEnabled = data.preferences.examTimerEnabled
            if let theme = ApplePreferences.Theme(rawValue: data.preferences.theme) {
                nextPreferences.theme = theme
            }
            nextPreferences.activeBankId = bank.courseBankID
            let entity = try preferencesEntity(createIfMissing: true, saveIfCreated: false)
            entity.practiceMode = nextPreferences.practiceMode.rawValue
            entity.examTimerEnabled = nextPreferences.examTimerEnabled
            entity.language = nextPreferences.language.rawValue
            entity.theme = nextPreferences.theme.rawValue
            if bank.courseBankID.hasLessons {
                entity.archivedLessonProgressData = try encoder.encode(data.lessonProgress)
                entity.archivedLessonQuizAttemptsData = try encoder.encode(data.lessonQuizAttempts)
            }
            if let morseCourseProgress = data.morseCourseProgress {
                try FileManager.default.createDirectory(at: morseCourseProgressURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try encoder.encode(morseCourseProgress).write(to: morseCourseProgressURL, options: [.atomic])
            }
#if DEBUG
            if failNextImportAfterMorseWriteForTesting {
                failNextImportAfterMorseWriteForTesting = false
                throw ProgressStoreInjectedFailure.importAfterMorseWrite
            }
#endif
            try context.save()
            UserDefaults.standard.set(nextPreferences.activeBankId.rawValue, forKey: Self.activeBankPreferenceKey)
            preferences = nextPreferences
            objectWillChange.send()
        } catch {
            context.rollback()
            try restore(previousSnapshot)
            throw error
        }
    }

    func validate(_ data: ProgressExportV1, bank: QuestionBank) -> [String] {
        var errors: [String] = []
        let knownQuestionIds = Set(bank.questions.map(\.id))
        let knownCategoryIds = Set(bank.categories.map(\.id))
        let knownSubsectionIds = Set(bank.subsections.map(\.id))

        if data.schema != "canadian-ham.progress-export" { errors.append(String(localized: "Import file schema is not canadian-ham.progress-export.")) }
        if data.version != 1 { errors.append(String(localized: "Import file version must be 1.")) }
        if data.bankId != bank.manifest.bankId { errors.append(String(localized: "Import bankId must be \(bank.manifest.bankId).")) }
        appendTimestampError(&errors, value: data.exportedAt, field: String(localized: "Import exportedAt"))

        var questionProgressIds = Set<String>()
        for (index, record) in data.questionProgress.enumerated() {
            let prefix = String.localizedStringWithFormat(String(localized: "Import questionProgress[%lld]"), Int64(index))
            if !knownQuestionIds.contains(record.questionId) { errors.append(String(localized: "\(prefix).questionId must be a known question ID.")) }
            if !questionProgressIds.insert(record.questionId).inserted { errors.append(String(localized: "\(prefix).questionId duplicates another question progress record.")) }
            if record.bankId != bank.manifest.bankId { errors.append(String(localized: "\(prefix).bankId must be \(bank.manifest.bankId).")) }
            if record.attempts < 0 { errors.append(String(localized: "\(prefix).attempts must be a non-negative integer.")) }
            if record.correctAttempts < 0 || record.correctAttempts > record.attempts { errors.append(String(localized: "\(prefix).correctAttempts must be between 0 and attempts.")) }
            appendTimestampError(&errors, value: record.lastAttemptedAt, field: "\(prefix).lastAttemptedAt")
            if record.recentResults.count > 5 { errors.append(String(localized: "\(prefix).recentResults must contain at most five booleans.")) }
            if !(0...5).contains(record.leitner.box) { errors.append(String(localized: "\(prefix).leitner.box must be an integer between 0 and 5.")) }
            appendTimestampError(&errors, value: record.leitner.dueAt, field: "\(prefix).leitner.dueAt")
        }

        var submittedAt = Set<String>()
        for (index, attempt) in data.examAttempts.enumerated() {
            let prefix = String.localizedStringWithFormat(String(localized: "Import examAttempts[%lld]"), Int64(index))
            if attempt.id.isEmpty { errors.append(String(localized: "\(prefix).id must be a non-empty string.")) }
            if attempt.bankId != bank.manifest.bankId { errors.append(String(localized: "\(prefix).bankId must be \(bank.manifest.bankId).")) }
            if attempt.mode != "mock-exam" { errors.append(String(localized: "\(prefix).mode must be mock-exam.")) }
            appendTimestampError(&errors, value: attempt.startedAt, field: "\(prefix).startedAt")
            appendTimestampError(&errors, value: attempt.submittedAt, field: "\(prefix).submittedAt")
            if !submittedAt.insert(attempt.submittedAt).inserted { errors.append(String(localized: "\(prefix).submittedAt duplicates another exam attempt.")) }
            if attempt.timer.secondsAllowed != nil && attempt.timer.secondsAllowed! < 0 { errors.append(String(localized: "\(prefix).timer.secondsAllowed must be null or non-negative.")) }
            if attempt.timer.secondsElapsed < 0 { errors.append(String(localized: "\(prefix).timer.secondsElapsed must be non-negative.")) }
            validateScore(attempt.score, prefix: "\(prefix).score", bankId: bank.manifest.bankId, hasHonours: bank.courseBankID.hasHonours, knownCategoryIds: knownCategoryIds, knownSubsectionIds: knownSubsectionIds, errors: &errors)
            for (itemIndex, item) in attempt.items.enumerated() {
                validateAttemptItem(item, prefix: "\(prefix).items[\(itemIndex)]", knownQuestionIds: knownQuestionIds, knownCategoryIds: knownCategoryIds, knownSubsectionIds: knownSubsectionIds, errors: &errors)
            }
        }

        validateLessonProgress(data.lessonProgress, knownLessonIds: bank.knownLessonIds, errors: &errors)
        validateLessonQuizAttempts(
            data.lessonQuizAttempts,
            knownQuestionIds: knownQuestionIds,
            knownLessonIds: bank.knownLessonIds,
            lessonQuizzesById: bank.lessonQuizzesById,
            errors: &errors
        )
        if let morseCourseProgress = data.morseCourseProgress {
            validateMorseCourseProgress(morseCourseProgress, errors: &errors)
        }

        if ApplePreferences.PracticeMode(rawValue: data.preferences.practiceMode) == nil {
            errors.append(String(localized: "Import preferences.practiceMode is invalid."))
        }
        if ApplePreferences.Theme(rawValue: data.preferences.theme) == nil {
            errors.append(String(localized: "Import preferences.theme is invalid."))
        }
        return errors
    }

    private func upsertQuestionProgress(_ record: QuestionProgressRecord) throws {
        let data = try encoder.encode(record.recentResults)
        if let entity = try questionProgressEntity(questionId: record.questionId) {
            entity.bankId = record.bankId
            entity.attempts = record.attempts
            entity.correctAttempts = record.correctAttempts
            entity.lastAttemptedAt = record.lastAttemptedAt
            entity.lastResult = record.lastResult.rawValue
            entity.recentResultsData = data
            entity.leitnerBox = record.leitner.box
            entity.dueAt = record.leitner.dueAt
            entity.notes = record.notes
        } else {
            context.insert(QuestionProgressEntity(
                questionId: record.questionId,
                bankId: record.bankId,
                attempts: record.attempts,
                correctAttempts: record.correctAttempts,
                lastAttemptedAt: record.lastAttemptedAt,
                lastResult: record.lastResult.rawValue,
                recentResultsData: data,
                leitnerBox: record.leitner.box,
                dueAt: record.leitner.dueAt,
                notes: record.notes
            ))
        }
    }

    private func questionProgressEntity(questionId: String) throws -> QuestionProgressEntity? {
        let entities = try questionProgressEntities(questionId: questionId)
        guard let survivor = entities.first else { return nil }
        for duplicate in entities.dropFirst() {
            context.delete(duplicate)
        }
        return survivor
    }

    private func questionProgressEntities(questionId: String) throws -> [QuestionProgressEntity] {
        let targetQuestionId = questionId
        let descriptor = FetchDescriptor<QuestionProgressEntity>(predicate: #Predicate { $0.questionId == targetQuestionId })
        return try context.fetch(descriptor)
    }

    private func deleteQuestionProgress(bankId: String) throws {
        let targetBankId = bankId
        let descriptor = FetchDescriptor<QuestionProgressEntity>(predicate: #Predicate { $0.bankId == targetBankId })
        for entity in try context.fetch(descriptor) {
            context.delete(entity)
        }
    }

    private func deleteExamAttempts(bankId: String) throws {
        let targetBankId = bankId
        let descriptor = FetchDescriptor<ExamAttemptEntity>(predicate: #Predicate { $0.bankId == targetBankId })
        for entity in try context.fetch(descriptor) {
            context.delete(entity)
        }
    }

    private func examAttemptEntity(id: String, submittedAt: String? = nil) throws -> ExamAttemptEntity? {
        let idMatches = try examAttemptEntities(id: id)
        let submittedAtMatches = try submittedAt.map { try examAttemptEntities(submittedAt: $0) } ?? []
        let matches = uniqueExamAttemptEntities(idMatches + submittedAtMatches)
        guard let survivor = matches.first else { return nil }
        for duplicate in matches.dropFirst() {
            context.delete(duplicate)
        }
        return survivor
    }

    private func examAttemptEntity(submittedAt: String) throws -> ExamAttemptEntity? {
        let entities = try examAttemptEntities(submittedAt: submittedAt)
        guard let survivor = entities.first else { return nil }
        for duplicate in entities.dropFirst() {
            context.delete(duplicate)
        }
        return survivor
    }

    private func examAttemptEntities(id: String) throws -> [ExamAttemptEntity] {
        let targetId = id
        let descriptor = FetchDescriptor<ExamAttemptEntity>(predicate: #Predicate { $0.id == targetId })
        return try context.fetch(descriptor)
    }

    private func examAttemptEntities(submittedAt: String) throws -> [ExamAttemptEntity] {
        let targetSubmittedAt = submittedAt
        let descriptor = FetchDescriptor<ExamAttemptEntity>(predicate: #Predicate { $0.submittedAt == targetSubmittedAt })
        return try context.fetch(descriptor)
    }

    private func uniqueExamAttemptEntities(_ entities: [ExamAttemptEntity]) -> [ExamAttemptEntity] {
        var seen = Set<PersistentIdentifier>()
        return entities.filter { entity in
            seen.insert(entity.persistentModelID).inserted
        }
    }

    private func existingPreferencesEntity() throws -> PreferencesEntity? {
        let defaultKey = PreferencesEntity.defaultKey
        let descriptor = FetchDescriptor<PreferencesEntity>(predicate: #Predicate { $0.key == defaultKey })
        let entities = try context.fetch(descriptor)
        guard let survivor = entities.first else { return nil }
        for duplicate in entities.dropFirst() {
            context.delete(duplicate)
        }
        return survivor
    }

    private func preferencesEntity(createIfMissing: Bool, saveIfCreated: Bool = true) throws -> PreferencesEntity {
        if let existing = try existingPreferencesEntity() {
            return existing
        }
        let entity = PreferencesEntity(
            practiceMode: ApplePreferences.default.practiceMode.rawValue,
            examTimerEnabled: ApplePreferences.default.examTimerEnabled,
            language: ApplePreferences.default.language.rawValue,
            theme: ApplePreferences.default.theme.rawValue
        )
        if createIfMissing {
            context.insert(entity)
            if saveIfCreated {
                try context.save()
            }
        }
        return entity
    }

    private func loadPreferences() throws -> ApplePreferences {
        let entity = try preferencesEntity(createIfMissing: true)
        return ApplePreferences(
            practiceMode: ApplePreferences.PracticeMode(rawValue: entity.practiceMode) ?? .immediate,
            examTimerEnabled: entity.examTimerEnabled,
            language: BankLanguage(rawValue: entity.language) ?? .english,
            theme: ApplePreferences.Theme(rawValue: entity.theme) ?? .system,
            activeBankId: CourseBankID(rawValue: UserDefaults.standard.string(forKey: Self.activeBankPreferenceKey) ?? "") ?? .basic
        )
    }

    private func saveExamAttemptWithoutSave(_ attempt: StoredExamAttempt) throws {
        let data = try encoder.encode(attempt)
        if let existing = try examAttemptEntity(id: attempt.id, submittedAt: attempt.submittedAt) {
            existing.id = attempt.id
            existing.bankId = attempt.bankId
            existing.seed = attempt.seed
            existing.startedAt = attempt.startedAt
            existing.submittedAt = attempt.submittedAt
            existing.payloadData = data
        } else {
            context.insert(ExamAttemptEntity(
                id: attempt.id,
                bankId: attempt.bankId,
                seed: attempt.seed,
                startedAt: attempt.startedAt,
                submittedAt: attempt.submittedAt,
                payloadData: data
            ))
        }
    }

    private func snapshotForRollback() throws -> ProgressStoreSnapshot {
        let entity = try existingPreferencesEntity()
        return ProgressStoreSnapshot(
            questionProgress: try questionProgressRecords(),
            examAttempts: try examAttempts(),
            preferences: preferences,
            archivedLessonProgressData: entity?.archivedLessonProgressData ?? Data("[]".utf8),
            archivedLessonQuizAttemptsData: entity?.archivedLessonQuizAttemptsData ?? Data("[]".utf8),
            morseCourseProgressData: try existingMorseCourseProgressDataForRollback()
        )
    }

    /// Returns nil only when there is no Morse progress file. Any other read error aborts the
    /// operation before anything is changed, so a later rollback can always restore the prior bytes.
    private func existingMorseCourseProgressDataForRollback() throws -> Data? {
        guard FileManager.default.fileExists(atPath: morseCourseProgressURL.path(percentEncoded: false)) else {
            return nil
        }
        return try Data(contentsOf: morseCourseProgressURL)
    }

    private func removeMorseCourseProgressIfPresent() throws {
        if FileManager.default.fileExists(atPath: morseCourseProgressURL.path(percentEncoded: false)) {
#if DEBUG
            if failNextMorseCourseProgressRemovalForTesting {
                failNextMorseCourseProgressRemovalForTesting = false
                throw ProgressStoreInjectedFailure.morseCourseProgressRemoval
            }
#endif
            try FileManager.default.removeItem(at: morseCourseProgressURL)
        }
    }

    private func restore(_ snapshot: ProgressStoreSnapshot) throws {
        try context.delete(model: QuestionProgressEntity.self)
        try context.delete(model: ExamAttemptEntity.self)
        try context.delete(model: PreferencesEntity.self)
        let entity = PreferencesEntity(
            practiceMode: snapshot.preferences.practiceMode.rawValue,
            examTimerEnabled: snapshot.preferences.examTimerEnabled,
            language: snapshot.preferences.language.rawValue,
            theme: snapshot.preferences.theme.rawValue
        )
        entity.archivedLessonProgressData = snapshot.archivedLessonProgressData
        entity.archivedLessonQuizAttemptsData = snapshot.archivedLessonQuizAttemptsData
        context.insert(entity)
        if let morseCourseProgressData = snapshot.morseCourseProgressData {
            try FileManager.default.createDirectory(at: morseCourseProgressURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try morseCourseProgressData.write(to: morseCourseProgressURL, options: [.atomic])
        } else {
            try removeMorseCourseProgressIfPresent()
        }
        for record in snapshot.questionProgress {
            try upsertQuestionProgress(record)
        }
        for attempt in snapshot.examAttempts {
            try saveExamAttemptWithoutSave(attempt)
        }
        try context.save()
        UserDefaults.standard.set(snapshot.preferences.activeBankId.rawValue, forKey: Self.activeBankPreferenceKey)
        preferences = snapshot.preferences
    }

    private func questionProgressRecord(from entity: QuestionProgressEntity) throws -> QuestionProgressRecord {
        let recentResults = try decoder.decode([Bool].self, from: entity.recentResultsData)
        return QuestionProgressRecord(
            questionId: entity.questionId,
            bankId: entity.bankId,
            attempts: entity.attempts,
            correctAttempts: entity.correctAttempts,
            lastAttemptedAt: entity.lastAttemptedAt,
            lastResult: AnswerResult(rawValue: entity.lastResult) ?? .incorrect,
            recentResults: recentResults,
            leitner: LeitnerState(box: entity.leitnerBox, dueAt: entity.dueAt),
            notes: entity.notes
        )
    }
}

private func appendTimestampError(_ errors: inout [String], value: String, field: String) {
    do {
        try CanonicalTimestamp.require(value, fieldName: field)
    } catch {
        errors.append(String(localized: "\(field) must use canonical UTC timestamp format YYYY-MM-DDTHH:MM:SS.sssZ."))
    }
}

private func validateScore(
    _ score: StoredExamScore,
    prefix: String,
    bankId: String,
    hasHonours: Bool,
    knownCategoryIds: Set<String>,
    knownSubsectionIds: Set<String>,
    errors: inout [String]
) {
    if score.bankId != bankId { errors.append(String(localized: "\(prefix).bankId must be \(bankId).")) }
    if score.correct < 0 { errors.append(String(localized: "\(prefix).correct must be non-negative.")) }
    if score.total < 0 { errors.append(String(localized: "\(prefix).total must be non-negative.")) }
    if score.correct > score.total { errors.append(String(localized: "\(prefix).correct must not exceed total.")) }
    if score.percent < 0 { errors.append(String(localized: "\(prefix).percent must be non-negative.")) }
    if !hasHonours && score.honours { errors.append(String(localized: "\(prefix).honours must be false for this course.")) }
    for (index, entry) in score.categoryBreakdown.enumerated() {
        let entryPrefix = "\(prefix).categoryBreakdown[\(index)]"
        if !knownCategoryIds.contains(entry.categoryId) { errors.append(String(localized: "\(entryPrefix).categoryId must be a known category ID.")) }
        if entry.correct < 0 || entry.total < 0 || entry.correct > entry.total { errors.append(String(localized: "\(entryPrefix) counts are invalid.")) }
    }
    for id in score.weakSubsectionIds where !knownSubsectionIds.contains(id) {
        errors.append(String(localized: "\(prefix).weakSubsectionIds contains unknown subsection ID \(id)."))
    }
}


private func validateMorseCourseProgress(_ progress: MorseCourseProgressExport, errors: inout [String]) {
    if progress.courseId.isEmpty {
        errors.append(String(localized: "Import morseCourseProgress.courseId must be non-empty."))
    }
    var lessonIds = Set<String>()
    for (index, record) in progress.lessonProgress.enumerated() {
        let prefix = "Import morseCourseProgress.lessonProgress[\(index)]"
        if record.lessonId.range(of: #"^koch-\d{3}$"#, options: .regularExpression) == nil { errors.append(String(localized: "\(prefix).lessonId must be a Morse lesson ID.")) }
        if !lessonIds.insert(record.lessonId).inserted { errors.append(String(localized: "\(prefix).lessonId duplicates another Morse lesson record.")) }
        if record.attempts < 1 { errors.append(String(localized: "\(prefix).attempts must be positive.")) }
        if !(0...1).contains(record.bestAccuracy) { errors.append(String(localized: "\(prefix).bestAccuracy must be between 0 and 1.")) }
        if !(0...1).contains(record.lastAccuracy) { errors.append(String(localized: "\(prefix).lastAccuracy must be between 0 and 1.")) }
        appendTimestampError(&errors, value: record.lastAttemptedAt, field: "\(prefix).lastAttemptedAt")
        if let completedAt = record.completedAt { appendTimestampError(&errors, value: completedAt, field: "\(prefix).completedAt") }
    }
    var characters = Set<String>()
    for (index, record) in progress.characterStats.enumerated() {
        let prefix = "Import morseCourseProgress.characterStats[\(index)]"
        if record.character.count != 1 { errors.append(String(localized: "\(prefix).character must be a single Morse character.")) }
        if !characters.insert(record.character).inserted { errors.append(String(localized: "\(prefix).character duplicates another character stat.")) }
        if record.attempts < 0 { errors.append(String(localized: "\(prefix).attempts must be non-negative.")) }
        if record.correctAttempts < 0 || record.correctAttempts > record.attempts { errors.append(String(localized: "\(prefix).correctAttempts must be between 0 and attempts.")) }
        if record.recentResults.count > 20 { errors.append(String(localized: "\(prefix).recentResults must contain at most 20 booleans.")) }
        appendTimestampError(&errors, value: record.lastPracticedAt, field: "\(prefix).lastPracticedAt")
    }
    for (index, record) in progress.dailyActivity.enumerated() {
        let prefix = "Import morseCourseProgress.dailyActivity[\(index)]"
        if record.date.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) == nil { errors.append(String(localized: "\(prefix).date must be YYYY-MM-DD.")) }
        if record.lessonsCompleted < 0 { errors.append(String(localized: "\(prefix).lessonsCompleted must be non-negative.")) }
    }
}

private func validateLessonProgress(_ records: [ArchivedJSON], knownLessonIds: Set<String>, errors: inout [String]) {
    var lessonIds = Set<String>()
    for (index, record) in records.enumerated() {
        let prefix = String.localizedStringWithFormat(String(localized: "Import lessonProgress[%lld]"), Int64(index))
        guard let lessonId = record.storage["lessonId"]?.stringValue, !lessonId.isEmpty else {
            errors.append(String(localized: "\(prefix).lessonId must be a non-empty string."))
            continue
        }
        if !knownLessonIds.contains(lessonId) {
            errors.append(String(localized: "\(prefix).lessonId must be a known lesson ID."))
        }
        if !lessonIds.insert(lessonId).inserted {
            errors.append(String(localized: "\(prefix).lessonId duplicates another lesson progress record."))
        }
        if let readAt = record.storage["readAt"]?.stringValue {
            appendTimestampError(&errors, value: readAt, field: "\(prefix).readAt")
        } else {
            errors.append(String(localized: "\(prefix).readAt must be a canonical UTC timestamp string."))
        }
        if let readCount = record.storage["readCount"]?.numberValue, readCount.rounded() == readCount, readCount > 0 {
            continue
        }
        errors.append(String(localized: "\(prefix).readCount must be a positive integer."))
    }
}

private func validateLessonQuizAttempts(
    _ attempts: [ArchivedJSON],
    knownQuestionIds: Set<String>,
    knownLessonIds: Set<String>,
    lessonQuizzesById: [String: BankLessonQuiz],
    errors: inout [String]
) {
    var ids = Set<String>()
    for (index, attempt) in attempts.enumerated() {
        let prefix = String.localizedStringWithFormat(String(localized: "Import lessonQuizAttempts[%lld]"), Int64(index))
        guard let id = attempt.storage["id"]?.stringValue, !id.isEmpty else {
            errors.append(String(localized: "\(prefix).id must be a non-empty string."))
            continue
        }
        if !ids.insert(id).inserted {
            errors.append(String(localized: "\(prefix).id duplicates another lesson quiz attempt."))
        }

        let quiz: BankLessonQuiz?
        if let quizId = attempt.storage["quizId"]?.nonEmptyStringValue {
            quiz = lessonQuizzesById[quizId]
            if quiz == nil {
                errors.append(String(localized: "\(prefix).quizId must be a known lesson quiz ID."))
            }
        } else {
            quiz = nil
            errors.append(String(localized: "\(prefix).quizId must be a non-empty string."))
        }

        if let lessonId = attempt.storage["lessonId"]?.nonEmptyStringValue {
            if !knownLessonIds.contains(lessonId) || (quiz != nil && lessonId != quiz?.lessonId) {
                errors.append(String(localized: "\(prefix).lessonId must match the known lesson quiz."))
            }
        } else {
            errors.append(String(localized: "\(prefix).lessonId must be a non-empty string."))
        }

        if let submittedAt = attempt.storage["submittedAt"]?.stringValue {
            appendTimestampError(&errors, value: submittedAt, field: "\(prefix).submittedAt")
        } else {
            errors.append(String(localized: "\(prefix).submittedAt must be a canonical UTC timestamp string."))
        }
        guard let correct = attempt.storage["correct"]?.numberValue, correct.rounded() == correct, correct >= 0 else {
            errors.append(String(localized: "\(prefix).correct must be a non-negative integer."))
            continue
        }
        guard let total = attempt.storage["total"]?.numberValue, total.rounded() == total, total > 0 else {
            errors.append(String(localized: "\(prefix).total must be a positive integer."))
            continue
        }
        if correct > total { errors.append(String(localized: "\(prefix).correct must not exceed total.")) }
        if let percent = attempt.storage["percent"]?.numberValue, percent.isFinite, percent >= 0, percent <= 100 {
            let expectedPercent = (correct / total) * 100
            if abs(percent - expectedPercent) > 1e-9 {
                errors.append(String(localized: "\(prefix).percent must match correct divided by total."))
            }
        } else {
            errors.append(String(localized: "\(prefix).percent must be a number between 0 and 100."))
        }

        if let officialQuestionIds = stringArray(attempt.storage["officialQuestionIds"]) {
            let quizQuestionIds = Set(quiz?.officialQuestionIds ?? [])
            if !officialQuestionIds.allSatisfy(knownQuestionIds.contains) {
                errors.append(String(localized: "\(prefix).officialQuestionIds must contain known question IDs."))
            } else if quiz != nil && !officialQuestionIds.allSatisfy(quizQuestionIds.contains) {
                errors.append(String(localized: "\(prefix).officialQuestionIds must belong to the lesson quiz."))
            }

            if let incorrectOfficialQuestionIds = stringArray(attempt.storage["incorrectOfficialQuestionIds"]) {
                if !incorrectOfficialQuestionIds.allSatisfy(knownQuestionIds.contains) {
                    errors.append(String(localized: "\(prefix).incorrectOfficialQuestionIds must contain known question IDs."))
                } else {
                    let officialSet = Set(officialQuestionIds)
                    if !incorrectOfficialQuestionIds.allSatisfy(officialSet.contains) {
                        errors.append(String(localized: "\(prefix).incorrectOfficialQuestionIds must be a subset of officialQuestionIds."))
                    }
                }
            } else {
                errors.append(String(localized: "\(prefix).incorrectOfficialQuestionIds must be an array of strings."))
            }
        } else {
            errors.append(String(localized: "\(prefix).officialQuestionIds must be an array of strings."))
            if stringArray(attempt.storage["incorrectOfficialQuestionIds"]) == nil {
                errors.append(String(localized: "\(prefix).incorrectOfficialQuestionIds must be an array of strings."))
            }
        }

        if let incorrectConceptCheckIds = stringArray(attempt.storage["incorrectConceptCheckIds"]) {
            let conceptCheckIds = quiz?.conceptCheckIds ?? []
            if quiz != nil && !incorrectConceptCheckIds.allSatisfy(conceptCheckIds.contains) {
                errors.append(String(localized: "\(prefix).incorrectConceptCheckIds must contain known concept check IDs for the quiz."))
            }
        } else {
            errors.append(String(localized: "\(prefix).incorrectConceptCheckIds must be an array of strings."))
        }
    }
}

private func stringArray(_ value: JSONValue?) -> [String]? {
    guard case .array(let values) = value else { return nil }
    return values.allSatisfy { $0.stringValue != nil } ? values.compactMap(\.stringValue) : nil
}

private extension JSONValue {
    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var nonEmptyStringValue: String? {
        guard let value = stringValue, !value.isEmpty else { return nil }
        return value
    }

    var numberValue: Double? {
        if case .number(let value) = self { return value }
        return nil
    }
}

private func validateAttemptItem(
    _ item: StoredExamAttemptItem,
    prefix: String,
    knownQuestionIds: Set<String>,
    knownCategoryIds: Set<String>,
    knownSubsectionIds: Set<String>,
    errors: inout [String]
) {
    if item.position < 1 { errors.append(String(localized: "\(prefix).position must be positive.")) }
    if !knownQuestionIds.contains(item.questionId) { errors.append(String(localized: "\(prefix).questionId must be a known question ID.")) }
    if !knownSubsectionIds.contains(item.subsectionId) || item.subsectionId != String(item.questionId.prefix(9)) {
        errors.append(String(localized: "\(prefix).subsectionId must match the known question subsection."))
    }
    if !knownCategoryIds.contains(item.categoryId) || item.categoryId != String(item.questionId.prefix(5)) {
        errors.append(String(localized: "\(prefix).categoryId must match the known question category."))
    }
    if Set(item.choicePermutation) != Set([0, 1, 2, 3]) || item.choicePermutation.count != 4 {
        errors.append(String(localized: "\(prefix).choicePermutation must be a permutation of 0, 1, 2, 3."))
    }
    if let selected = item.selectedSourceIndex, !(0...3).contains(selected) {
        errors.append(String(localized: "\(prefix).selectedSourceIndex must be null or an answer source index between 0 and 3."))
    }
}
