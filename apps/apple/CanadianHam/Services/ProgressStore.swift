import CanadianHamEngine
import CanadianHamMorseEngine
#if ICLOUD_SYNC
@preconcurrency import CloudKit
#endif
import Foundation
import SwiftData

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
    private static let localDeviceIdentifierKey = "CanadianHam.iCloudSyncLocalDeviceIdentifier"
    private static let pendingProgressZoneDeletionKey = "CanadianHam.iCloudSyncPendingProgressZoneDeletion"

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

    static func localDeviceIdentifier(defaults: UserDefaults = .standard) -> String {
        if let existing = defaults.string(forKey: localDeviceIdentifierKey), !existing.isEmpty {
            return existing
        }
        let created = UUID().uuidString
        defaults.set(created, forKey: localDeviceIdentifierKey)
        return created
    }

    static func pendingProgressZoneDeletion(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: pendingProgressZoneDeletionKey)
    }

    static func setPendingProgressZoneDeletion(_ pending: Bool, defaults: UserDefaults = .standard) {
        if pending { defaults.set(true, forKey: pendingProgressZoneDeletionKey) }
        else { defaults.removeObject(forKey: pendingProgressZoneDeletionKey) }
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
    let lessonIdVersion: Int?
    let exportedAt: String
    let bankId: String
    let questionProgress: [QuestionProgressRecord]
    let examAttempts: [StoredExamAttempt]
    let lessonProgress: [ArchivedJSON]
    let lessonQuizAttempts: [ArchivedJSON]
    let morseCourseProgress: MorseCourseProgressExport?
    let syncDeviceRows: ProgressSyncDeviceRows?
    let preferences: ExportedPreferences

    init(
        schema: String,
        version: Int,
        lessonIdVersion: Int? = nil,
        exportedAt: String,
        bankId: String,
        questionProgress: [QuestionProgressRecord],
        examAttempts: [StoredExamAttempt],
        lessonProgress: [ArchivedJSON],
        lessonQuizAttempts: [ArchivedJSON],
        morseCourseProgress: MorseCourseProgressExport? = nil,
        syncDeviceRows: ProgressSyncDeviceRows? = nil,
        preferences: ExportedPreferences
    ) {
        self.schema = schema
        self.version = version
        self.lessonIdVersion = lessonIdVersion
        self.exportedAt = exportedAt
        self.bankId = bankId
        self.questionProgress = questionProgress
        self.examAttempts = examAttempts
        self.lessonProgress = lessonProgress
        self.lessonQuizAttempts = lessonQuizAttempts
        self.morseCourseProgress = morseCourseProgress
        self.syncDeviceRows = syncDeviceRows
        self.preferences = preferences
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schema = try container.decode(String.self, forKey: .schema)
        version = try container.decode(Int.self, forKey: .version)
        lessonIdVersion = container.contains(.lessonIdVersion) ? try container.decode(Int.self, forKey: .lessonIdVersion) : nil
        exportedAt = try container.decode(String.self, forKey: .exportedAt)
        bankId = try container.decodeIfPresent(String.self, forKey: .bankId) ?? basicBankId
        questionProgress = try container.decode([QuestionProgressRecord].self, forKey: .questionProgress)
        examAttempts = try container.decode([StoredExamAttempt].self, forKey: .examAttempts)
        lessonProgress = try container.decodeIfPresent([ArchivedJSON].self, forKey: .lessonProgress) ?? []
        lessonQuizAttempts = try container.decodeIfPresent([ArchivedJSON].self, forKey: .lessonQuizAttempts) ?? []
        morseCourseProgress = try container.decodeIfPresent(MorseCourseProgressExport.self, forKey: .morseCourseProgress)
        syncDeviceRows = try container.decodeIfPresent(ProgressSyncDeviceRows.self, forKey: .syncDeviceRows)
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
    let answeredWithHelpIds: [String]?
    let reviewQuestionIds: [String]?

    init(
        id: String,
        quizId: String,
        lessonId: String,
        submittedAt: String,
        correct: Int,
        total: Int,
        percent: Double,
        officialQuestionIds: [String],
        incorrectOfficialQuestionIds: [String],
        incorrectConceptCheckIds: [String],
        answeredWithHelpIds: [String]? = nil,
        reviewQuestionIds: [String]? = nil
    ) {
        self.id = id
        self.quizId = quizId
        self.lessonId = lessonId
        self.submittedAt = submittedAt
        self.correct = correct
        self.total = total
        self.percent = percent
        self.officialQuestionIds = officialQuestionIds
        self.incorrectOfficialQuestionIds = incorrectOfficialQuestionIds
        self.incorrectConceptCheckIds = incorrectConceptCheckIds
        self.answeredWithHelpIds = answeredWithHelpIds
        self.reviewQuestionIds = reviewQuestionIds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        quizId = try container.decode(String.self, forKey: .quizId)
        lessonId = try container.decode(String.self, forKey: .lessonId)
        submittedAt = try container.decode(String.self, forKey: .submittedAt)
        correct = try container.decode(Int.self, forKey: .correct)
        total = try container.decode(Int.self, forKey: .total)
        percent = try container.decode(Double.self, forKey: .percent)
        officialQuestionIds = try container.decode([String].self, forKey: .officialQuestionIds)
        incorrectOfficialQuestionIds = try container.decode([String].self, forKey: .incorrectOfficialQuestionIds)
        incorrectConceptCheckIds = try container.decode([String].self, forKey: .incorrectConceptCheckIds)
        if container.contains(.reviewQuestionIds) {
            let ids = try container.decode([String].self, forKey: .reviewQuestionIds)
            guard Self.validReviewQuestionIds(ids, officialQuestionIds: officialQuestionIds) else {
                throw DecodingError.dataCorruptedError(forKey: .reviewQuestionIds, in: container, debugDescription: "Review IDs must be sorted unique official IDs outside the core quiz.")
            }
            reviewQuestionIds = ids
        } else {
            reviewQuestionIds = nil
        }
        if container.contains(.answeredWithHelpIds) {
            let ids = try container.decode([String].self, forKey: .answeredWithHelpIds)
            guard Self.validAnsweredWithHelpIds(ids, officialQuestionIds: officialQuestionIds + (reviewQuestionIds ?? [])) else {
                throw DecodingError.dataCorruptedError(forKey: .answeredWithHelpIds, in: container, debugDescription: "Help IDs must be sorted unique official IDs from this attempt.")
            }
            answeredWithHelpIds = ids
        } else {
            answeredWithHelpIds = nil
        }
    }

    static func validReviewQuestionIds(_ ids: [String], officialQuestionIds: [String]) -> Bool {
        ids == ids.sorted() && Set(ids).count == ids.count && ids.allSatisfy { id in
            id.range(of: #"^[BA]-[0-9]{3}-[0-9]{3}-[0-9]{3}$"#, options: .regularExpression) != nil && !officialQuestionIds.contains(id)
        }
    }

    static func validAnsweredWithHelpIds(_ ids: [String], officialQuestionIds: [String]) -> Bool {
        ids == ids.sorted() && Set(ids).count == ids.count && ids.allSatisfy(officialQuestionIds.contains)
    }
}

struct ExportedPreferences: Codable, Equatable, Sendable {
    static let invalidLanguageValue = "__canadian-ham-invalid-language__"

    let practiceMode: String
    let examTimerEnabled: Bool
    let language: String
    let theme: String
    let morse: ExportedMorseSettings

    init(
        practiceMode: String,
        examTimerEnabled: Bool,
        language: String = ApplePreferences.LanguagePreference.system.rawValue,
        theme: String = ApplePreferences.Theme.system.rawValue,
        morse: ExportedMorseSettings = .default
    ) {
        self.practiceMode = practiceMode
        self.examTimerEnabled = examTimerEnabled
        self.language = language
        self.theme = theme
        self.morse = morse
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        practiceMode = try container.decode(String.self, forKey: .practiceMode)
        examTimerEnabled = try container.decode(Bool.self, forKey: .examTimerEnabled)
        if container.contains(.language) {
            language = (try container.decodeNil(forKey: .language)) ? Self.invalidLanguageValue : try container.decode(String.self, forKey: .language)
        } else {
            language = ApplePreferences.LanguagePreference.system.rawValue
        }
        theme = try container.decodeIfPresent(String.self, forKey: .theme) ?? ApplePreferences.Theme.system.rawValue
        // Older exports omit morse entirely; an explicit null is invalid (the schema requires an object).
        morse = container.contains(.morse) ? try container.decode(ExportedMorseSettings.self, forKey: .morse) : .default
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
    case cloudResetRequiresAsyncDeletion

    var errorDescription: String? {
        switch self {
        case .validationFailed(let errors):
            errors.joined(separator: "\n")
        case .openFailed(let message):
            message
        case .cloudResetRequiresAsyncDeletion:
            String(localized: "Reset iCloud progress through the cloud deletion flow.")
        }
    }
}

#if DEBUG
enum ProgressStoreInjectedFailure: Error, Equatable {
    case importAfterDelete
    case importAfterMorseWrite
    case legacyLanguageMigrationSave
    case lessonQuizSave
    case morseCourseProgressRemoval
    case resetAfterPreferenceDelete
}
#endif

private struct ProgressStoreSnapshot {
    let questionProgress: [QuestionProgressRecord]
    let examAttempts: [StoredExamAttempt]
    let lessonProgress: [LessonProgressRecord]
    let lessonQuizAttempts: [LessonQuizAttempt]
    let preferences: ApplePreferences
    let archivedLessonProgressData: Data
    let archivedLessonQuizAttemptsData: Data
    let morseCourseProgress: MorseCourseProgressExport?
    let syncDeviceRows: ProgressSyncDeviceRows
}

private enum LegacyPreferencesReadResult {
    case skipped
    case failed
    case loaded([PreferencesEntitySnapshot])
}

enum ICloudLocalDataChoice: Equatable, Sendable {
    case keepLocal
    case deleteLocal
}

struct ICloudProgressDeletionClient {
    let deletePrivateDatabaseProgressZones: () async throws -> Void

    init(deletePrivateDatabaseProgressZones: @escaping () async throws -> Void) {
        self.deletePrivateDatabaseProgressZones = deletePrivateDatabaseProgressZones
    }

    static var noop: ICloudProgressDeletionClient { ICloudProgressDeletionClient(deletePrivateDatabaseProgressZones: {}) }
}

#if ICLOUD_SYNC
extension ICloudProgressDeletionClient {
    static func cloudKit(containerIdentifier: String = ICloudSyncSettings.containerIdentifier) -> ICloudProgressDeletionClient {
        ICloudProgressDeletionClient {
            let database = CKContainer(identifier: containerIdentifier).privateCloudDatabase
            let zones = try await Self.fetchRecordZones(database: database)
            let zoneIDs = zones.map(\.zoneID).filter { $0.zoneName != CKRecordZone.default().zoneID.zoneName }
            guard !zoneIDs.isEmpty else { return }
            try await Self.deleteRecordZones(zoneIDs, database: database)
        }
    }

    private static func fetchRecordZones(database: CKDatabase) async throws -> [CKRecordZone] {
        try await withCheckedThrowingContinuation { continuation in
            database.fetchAllRecordZones { zones, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: zones ?? [])
                }
            }
        }
    }

    private static func deleteRecordZones(_ zoneIDs: [CKRecordZone.ID], database: CKDatabase) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let operation = CKModifyRecordZonesOperation(recordZonesToSave: nil, recordZoneIDsToDelete: zoneIDs)
            operation.modifyRecordZonesResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: ())
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            database.add(operation)
        }
    }
}
#endif

@MainActor
final class ProgressStoreService: ObservableObject {
    @Published private(set) var preferences: ApplePreferences = .default
    @Published private(set) var isICloudSyncEnabled: Bool = ICloudSyncSettings.storedOptIn()
    @Published private(set) var iCloudAccountSignalError: String?

    private static let legacyEnglishLanguageMigrationMarkerKey = "CanadianHam.preferences.legacyEnglishLanguageDefaultMigrationComplete"
    static let task4610LessonSplitMigrationMarkerKey = "CanadianHam.progress.task46_10LessonSplitMigrationComplete"
    private static let appleLanguagesLastAppliedPreferenceKey = "CanadianHam.preferences.appleLanguagesLastApplied"
    private static let appleLanguagesPreferenceKey = "AppleLanguages"

    private(set) var container: ModelContainer
    private var context: ModelContext
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let storeURLs: ProgressStoreURLs
    private let morseCourseProgressURL: URL
    private let layout: ProgressStoreConfigurationLayout
    private let localDeviceID: String
    private let defaults: UserDefaults
    private let defaultsDomainName: String?
    private var modelContainerFactory: ((Bool) throws -> ModelContainer)?
    private var pendingICloudProgressDeletionForReset = false
#if DEBUG
    var morseCourseProgressURLForTesting: URL { morseCourseProgressURL }
    static var failNextLegacyLanguageMigrationSaveForTesting = false
    var failNextResetAfterPreferenceDeleteForTesting = false
    var failNextImportAfterDeleteForTesting = false
    var failNextImportAfterMorseWriteForTesting = false
    var failNextLessonQuizSaveForTesting = false
    var failNextMorseCourseProgressRemovalForTesting = false
    private(set) var questionProgressWriteContextBuildCountForTesting = 0
#endif
#if ICLOUD_SYNC
    private var iCloudAccountChangedObserver: NSObjectProtocol?
#endif

    init(
        container: ModelContainer,
        storeURLs: ProgressStoreURLs = .standard,
        morseCourseProgressURL: URL? = nil,
        iCloudSyncEnabled: Bool = ICloudSyncSettings.storedOptIn(),
        layout: ProgressStoreConfigurationLayout = .automatic,
        modelContainerFactory: ((Bool) throws -> ModelContainer)? = nil,
        startICloudMonitoring: Bool = true,
        localDeviceID: String = ICloudSyncSettings.localDeviceIdentifier(),
        defaults: UserDefaults = .standard,
        defaultsDomainName: String? = Bundle.main.bundleIdentifier
    ) throws {
        self.container = container
        self.context = ModelContext(container)
        self.storeURLs = storeURLs
        self.morseCourseProgressURL = morseCourseProgressURL ?? storeURLs.morseCourseProgressURL
        self.layout = Self.resolvedLayout(layout)
        self.modelContainerFactory = modelContainerFactory
        self.localDeviceID = localDeviceID
        self.defaults = defaults
        self.defaultsDomainName = defaultsDomainName
        self.isICloudSyncEnabled = iCloudSyncEnabled
        try FileManager.default.createDirectory(at: self.morseCourseProgressURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        self.preferences = try loadPreferences()
        try adoptLegacyDeviceRowsIfNeeded()
        try migrateLearningProgressFromLegacyStorageIfNeeded()
        try migrateTask4610LessonReferencesIfNeeded()
#if ICLOUD_SYNC
        if iCloudSyncEnabled, startICloudMonitoring {
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
        layout: ProgressStoreConfigurationLayout = .automatic,
        defaults: UserDefaults = .standard,
        defaultsDomainName: String? = Bundle.main.bundleIdentifier
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
            switch legacyPreferences {
            case .skipped:
                break
            case .failed:
                break
            case .loaded(let snapshots):
                try copyLegacyPreferencesIfNeeded(snapshots, into: container, layout: resolvedLayout)
                markLegacyPreferencesCopyComplete(storeURLs: storeURLs)
            }
            let factory: (Bool) throws -> ModelContainer = { enabled in
                try makeModelContainer(
                    iCloudSyncEnabled: enabled,
                    isStoredInMemoryOnly: false,
                    storeURLs: storeURLs,
                    layout: resolvedLayout
                )
            }
            return try ProgressStoreService(
                container: container,
                storeURLs: storeURLs,
                iCloudSyncEnabled: iCloudSyncEnabled,
                layout: resolvedLayout,
                modelContainerFactory: factory,
                defaults: defaults,
                defaultsDomainName: defaultsDomainName
            )
        } catch {
            throw ProgressStoreError.openFailed(error.localizedDescription)
        }
    }

    static func inMemoryForTests(
        iCloudSyncEnabled: Bool = false,
        layout: ProgressStoreConfigurationLayout = .automatic,
        localDeviceID: String = "test-device",
        defaults: UserDefaults? = nil,
        defaultsDomainName: String? = nil
    ) throws -> ProgressStoreService {
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
        let urls = ProgressStoreURLs(progressDirectory: directory)
        let resolvedDefaults: UserDefaults
        let resolvedDefaultsDomainName: String?
        if let defaults {
            resolvedDefaults = defaults
            resolvedDefaultsDomainName = defaultsDomainName ?? Bundle.main.bundleIdentifier
        } else {
            let suiteName = "ProgressStoreTests.\(UUID().uuidString)"
            guard let testDefaults = UserDefaults(suiteName: suiteName) else {
                throw ProgressStoreError.openFailed("Unable to create test defaults suite.")
            }
            testDefaults.removePersistentDomain(forName: suiteName)
            resolvedDefaults = testDefaults
            resolvedDefaultsDomainName = suiteName
        }
        return try ProgressStoreService(
            container: container,
            storeURLs: urls,
            iCloudSyncEnabled: iCloudSyncEnabled,
            layout: resolvedLayout(layout),
            modelContainerFactory: { enabled in
                try makeModelContainer(
                    iCloudSyncEnabled: enabled,
                    isStoredInMemoryOnly: true,
                    storeURLs: urls,
                    layout: resolvedLayout(layout)
                )
            },
            startICloudMonitoring: false,
            localDeviceID: localDeviceID,
            defaults: resolvedDefaults,
            defaultsDomainName: resolvedDefaultsDomainName
        )
    }

    static func applyInterfaceLanguagePreference(_ language: ApplePreferences.LanguagePreference, defaults: UserDefaults = .standard) {
#if os(iOS) || os(macOS)
        switch language {
        case .system:
            defaults.removeObject(forKey: appleLanguagesPreferenceKey)
        case .english:
            defaults.set([BankLanguage.english.rawValue], forKey: appleLanguagesPreferenceKey)
        case .french:
            defaults.set([BankLanguage.french.rawValue], forKey: appleLanguagesPreferenceKey)
        }
        recordLastAppliedInterfaceLanguagePreference(language, defaults: defaults)
#else
        _ = language
        _ = defaults
#endif
    }

#if os(iOS) || os(macOS)
    private static func recordLastAppliedInterfaceLanguagePreference(_ language: ApplePreferences.LanguagePreference, defaults: UserDefaults) {
        defaults.set(language.rawValue, forKey: appleLanguagesLastAppliedPreferenceKey)
    }

    private static func lastAppliedInterfaceLanguagePreference(defaults: UserDefaults) -> ApplePreferences.LanguagePreference? {
        guard let rawValue = defaults.string(forKey: appleLanguagesLastAppliedPreferenceKey) else { return nil }
        return ApplePreferences.LanguagePreference(rawValue: rawValue)
    }

    private static func persistentAppleLanguages(defaults: UserDefaults, domainName: String?) -> [String]? {
        guard let domainName,
              let appleLanguages = defaults.persistentDomain(forName: domainName)?[appleLanguagesPreferenceKey] as? [String],
              !appleLanguages.isEmpty
        else { return nil }
        return appleLanguages
    }

    private static func persistentAppleLanguagesPreference(defaults: UserDefaults, domainName: String?) -> ApplePreferences.LanguagePreference {
        guard let appleLanguages = persistentAppleLanguages(defaults: defaults, domainName: domainName) else { return .system }
        return languagePreference(fromAppleLanguages: appleLanguages)
    }

    private static func languagePreference(fromAppleLanguages appleLanguages: [String]) -> ApplePreferences.LanguagePreference {
        let preferredLocalization = Bundle.preferredLocalizations(
            from: BankLanguage.allCases.map(\.rawValue),
            forPreferences: appleLanguages
        ).first?.lowercased()
        if preferredLocalization?.hasPrefix(BankLanguage.french.rawValue) == true { return .french }
        if preferredLocalization?.hasPrefix(BankLanguage.english.rawValue) == true { return .english }
        return .system
    }
#endif

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
        let schema = Schema(versionedSchema: CanadianHamProgressSchemaV4.self)
        let configuration: ModelConfiguration
        if isStoredInMemoryOnly {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        } else {
            configuration = ModelConfiguration(schema: schema, url: storeURLs.persistentStoreURL, cloudKitDatabase: .none)
        }
        return try ModelContainer(for: schema, migrationPlan: CanadianHamProgressMigrationPlan.self, configurations: [configuration])
    }

    private static func makeSplitModelContainer(iCloudSyncEnabled: Bool, isStoredInMemoryOnly: Bool, storeURLs: ProgressStoreURLs) throws -> ModelContainer {
        let schema = Schema(versionedSchema: CanadianHamProgressSchemaV4.self)
        let plan = configurationPlan(iCloudSyncEnabled: iCloudSyncEnabled)
        let progressSchema = Schema([QuestionProgressEntity.self, ExamAttemptEntity.self, LessonProgressEntity.self, LessonQuizAttemptEntity.self, MorseCourseProgressEntity.self])
        let preferencesSchema = Schema([PreferencesEntity.self])
        let progressConfiguration: ModelConfiguration
        let preferencesConfiguration: ModelConfiguration
        if isStoredInMemoryOnly {
            progressConfiguration = ModelConfiguration(
                "LearningProgress",
                schema: progressSchema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
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
        return FileManager.default.fileExists(atPath: storeURLs.persistentStoreURL.path(percentEncoded: false))
    }

    private static func legacyPreferencesSnapshotsIfNeeded(
        storeURLs: ProgressStoreURLs,
        shouldAttemptCopy: Bool
    ) -> LegacyPreferencesReadResult {
        guard shouldAttemptCopy else { return .skipped }
        do {
            let legacyContainer = try makeLegacySingleStoreModelContainer(isStoredInMemoryOnly: false, storeURLs: storeURLs)
            let legacyContext = ModelContext(legacyContainer)
            let descriptor = FetchDescriptor<PreferencesEntity>(sortBy: [SortDescriptor(\.key)])
            let snapshots = try legacyContext.fetch(descriptor).map { entity in
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
            return .loaded(snapshots)
        } catch {
            NSLog("CanadianHam: unable to copy legacy preferences into split store: %@", String(describing: error))
            return .failed
        }
    }

    private static func copyLegacyPreferencesIfNeeded(
        _ snapshots: [PreferencesEntitySnapshot],
        into container: ModelContainer,
        layout: ProgressStoreConfigurationLayout
    ) throws {
        guard layout == .split, !snapshots.isEmpty else { return }
        let context = ModelContext(container)
        let existing = Dictionary(try context.fetch(FetchDescriptor<PreferencesEntity>()).map { ($0.key, $0) }, uniquingKeysWith: { first, duplicate in context.delete(duplicate); return first })
        for snapshot in snapshots {
            if let entity = existing[snapshot.key] {
                if entity.practiceMode == ApplePreferences.default.practiceMode.rawValue,
                   !entity.examTimerEnabled,
                   entity.language == ApplePreferences.default.language.rawValue,
                   entity.theme == ApplePreferences.default.theme.rawValue {
                    entity.practiceMode = snapshot.practiceMode
                    entity.examTimerEnabled = snapshot.examTimerEnabled
                    entity.language = snapshot.language
                    entity.theme = snapshot.theme
                }
                if entity.archivedLessonProgressData == Data("[]".utf8) {
                    entity.archivedLessonProgressData = snapshot.archivedLessonProgressData
                }
                if entity.archivedLessonQuizAttemptsData == Data("[]".utf8) {
                    entity.archivedLessonQuizAttemptsData = snapshot.archivedLessonQuizAttemptsData
                }
            } else {
                context.insert(PreferencesEntity(
                    key: snapshot.key,
                    practiceMode: snapshot.practiceMode,
                    examTimerEnabled: snapshot.examTimerEnabled,
                    language: snapshot.language,
                    theme: snapshot.theme,
                    archivedLessonProgressData: snapshot.archivedLessonProgressData,
                    archivedLessonQuizAttemptsData: snapshot.archivedLessonQuizAttemptsData
                ))
            }
        }
        try context.save()
    }

    private static func markLegacyPreferencesCopyComplete(storeURLs: ProgressStoreURLs) {
        // The original PreferencesEntity rows can remain in Progress.store after a split-store copy;
        // this gated marker records that their learning-progress archives were copied into syncable rows.
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
        applyInterfaceLanguagePreference(.system)
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
        do {
            try reopenLocalOnlyAfterSyncStop()
            iCloudAccountSignalError = nil
        } catch {
            iCloudAccountSignalError = error.localizedDescription
            NSLog("CanadianHam: unable to reopen the progress store local-only after iCloud account signal: %@", String(describing: error))
        }
    }

    func reopenLocalOnlyAfterSyncStop(factory: ((Bool) throws -> ModelContainer)? = nil) throws {
        let snapshot = try snapshotForRollback()
        let makeContainer = factory ?? modelContainerFactory ?? { [storeURLs, layout] enabled in
            try Self.makeModelContainer(
                iCloudSyncEnabled: enabled,
                isStoredInMemoryOnly: false,
                storeURLs: storeURLs,
                layout: layout
            )
        }
        let localOnlyContainer = try makeContainer(false)
        let localOnlyContext = ModelContext(localOnlyContainer)
        container = localOnlyContainer
        context = localOnlyContext
        isICloudSyncEnabled = false
        if try isProgressStoreEmpty(in: localOnlyContext) {
            try restore(snapshot)
        } else {
            preferences = try loadPreferences()
        }
        objectWillChange.send()
    }

    func deleteICloudProgress(localDataChoice: ICloudLocalDataChoice, client: ICloudProgressDeletionClient, defaults: UserDefaults = .standard) async throws {
        ICloudSyncSettings.clearStoredOptIn(defaults: defaults)
        try reopenLocalOnlyAfterSyncStop()
        try await client.deletePrivateDatabaseProgressZones()
        // The zone is gone, so any reset that was waiting on this deletion is satisfied.
        pendingICloudProgressDeletionForReset = false
        ICloudSyncSettings.setPendingProgressZoneDeletion(false, defaults: defaults)
        if localDataChoice == .deleteLocal {
            try resetAllData(defaults: defaults)
        }
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
        ProgressSyncMerge.deduplicateDeviceQuestionProgress(try deviceQuestionProgressRows())
    }

    func examAttempts() throws -> [StoredExamAttempt] {
        ProgressSyncMerge.deduplicateDeviceExamAttempts(try deviceExamAttemptRows())
    }

    func latestExamAttempt() throws -> StoredExamAttempt? {
        try examAttempts().sorted { $0.submittedAt > $1.submittedAt }.first
    }

    func lessonProgressRecords() throws -> [LessonProgressRecord] {
        ProgressSyncMerge.deduplicateDeviceLessonProgress(try deviceLessonProgressRows())
    }

    func lessonQuizAttempts() throws -> [LessonQuizAttempt] {
        ProgressSyncMerge.deduplicateDeviceLessonQuizAttempts(try deviceLessonQuizAttemptRows())
    }

    func saveLessonProgress(_ record: LessonProgressRecord) throws {
        try upsertLessonProgress(record)
        try context.save()
        objectWillChange.send()
    }

    func morseCourseProgress() throws -> MorseCourseProgressExport? {
        let key = MorseCourseProgressEntity.defaultKey
        let descriptor = FetchDescriptor<MorseCourseProgressEntity>(predicate: #Predicate { $0.key == key })
        let rows = try context.fetch(descriptor).map { entity in
            DeviceMorseCourseProgressRecord(deviceId: entity.deviceId.isEmpty ? localDeviceID : entity.deviceId, progress: try decoder.decode(MorseCourseProgressExport.self, from: entity.payloadData))
        }
        return ProgressSyncMerge.mergeDeviceMorseCourseProgress(rows)
    }

    func saveMorseCourseProgress(_ progress: MorseCourseProgressExport) throws {
        try upsertMorseCourseProgress(progress)
        try context.save()
        objectWillChange.send()
    }

    func saveLessonQuizAttempt(_ attempt: LessonQuizAttempt, questionProgress: [QuestionProgressRecord]) throws {
        do {
            try upsertLessonQuizAttempt(attempt)
            let writeContext = try questionProgressWriteContext(forDeviceId: localDeviceID)
            for record in questionProgress {
                try upsertQuestionProgress(record, writeContext: writeContext)
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
        let writeContext = try questionProgressWriteContext(forDeviceId: localDeviceID)
        for record in records {
            try upsertQuestionProgress(record, writeContext: writeContext)
        }
        try context.save()
        objectWillChange.send()
    }

    func saveExamAttempt(_ attempt: StoredExamAttempt) throws {
        try saveExamAttemptWithoutSave(attempt)
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
        defaults.set(preferences.activeBankId.rawValue, forKey: Self.activeBankPreferenceKey)
        if self.preferences.language != preferences.language {
            Self.applyInterfaceLanguagePreference(preferences.language, defaults: defaults)
        }
        self.preferences = preferences
    }

    func resetAllData(client: ICloudProgressDeletionClient, defaults passedDefaults: UserDefaults? = nil) async throws {
        let defaults = passedDefaults ?? self.defaults
        if isICloudSyncEnabled || ICloudSyncSettings.storedOptIn(defaults: defaults) || pendingICloudProgressDeletionForReset || ICloudSyncSettings.pendingProgressZoneDeletion(defaults: defaults) {
            pendingICloudProgressDeletionForReset = true
            ICloudSyncSettings.setPendingProgressZoneDeletion(true, defaults: defaults)
            ICloudSyncSettings.clearStoredOptIn(defaults: defaults)
            try reopenLocalOnlyAfterSyncStop()
            try await client.deletePrivateDatabaseProgressZones()
            pendingICloudProgressDeletionForReset = false
            ICloudSyncSettings.setPendingProgressZoneDeletion(false, defaults: defaults)
        }
        try resetAllData(defaults: defaults)
    }

    func resetAllData(defaults passedDefaults: UserDefaults? = nil) throws {
        let defaults = passedDefaults ?? self.defaults
#if ICLOUD_SYNC
        if isICloudSyncEnabled || ICloudSyncSettings.storedOptIn(defaults: defaults) || pendingICloudProgressDeletionForReset || ICloudSyncSettings.pendingProgressZoneDeletion(defaults: defaults) {
            throw ProgressStoreError.cloudResetRequiresAsyncDeletion
        }
#endif
        let previousSnapshot = try snapshotForRollback()
        do {
            try context.delete(model: QuestionProgressEntity.self)
            try context.delete(model: ExamAttemptEntity.self)
            try context.delete(model: LessonProgressEntity.self)
            try context.delete(model: LessonQuizAttemptEntity.self)
            try removeMorseCourseProgressIfPresent()
            if let entity = try existingPreferencesEntity() { context.delete(entity) }
            defaults.removeObject(forKey: Self.activeBankPreferenceKey)
            preferences = .default
            if layout == .split {
                Self.markLegacyPreferencesCopyComplete(storeURLs: storeURLs)
            }
#if DEBUG
            if failNextResetAfterPreferenceDeleteForTesting {
                failNextResetAfterPreferenceDeleteForTesting = false
                throw ProgressStoreInjectedFailure.resetAfterPreferenceDelete
            }
#endif
            try context.save()
            Self.applyInterfaceLanguagePreference(.system, defaults: defaults)
            // Reset all data also turns iCloud sync back off, but only once the reset has been saved.
            ICloudSyncSettings.clearStoredOptIn(defaults: defaults)
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
        _ = try preferencesEntity(createIfMissing: true)
        let questionProgress = try questionProgressRecords().filter { $0.bankId == bank.manifest.bankId }
        let examAttempts = try examAttempts().filter { $0.bankId == bank.manifest.bankId }
        let lessonRecords = bank.courseBankID.hasLessons ? try lessonProgressRecords() : []
        let lessonQuizRecords = bank.courseBankID.hasLessons ? try lessonQuizAttempts() : []
        let morseProgress = try morseCourseProgress()
        return ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            lessonIdVersion: LessonIDContentVersion.current,
            exportedAt: exportedAt,
            bankId: bank.manifest.bankId,
            questionProgress: questionProgress,
            examAttempts: examAttempts,
            lessonProgress: try archivedArray(lessonRecords),
            lessonQuizAttempts: try archivedArray(lessonQuizRecords),
            morseCourseProgress: morseProgress,
            syncDeviceRows: try syncDeviceRowsSnapshot(
                bank: bank,
                questionProgress: questionProgress,
                examAttempts: examAttempts,
                lessonProgress: lessonRecords,
                lessonQuizAttempts: lessonQuizRecords,
                includesMorse: morseProgress != nil
            ),
            preferences: ExportedPreferences(
                practiceMode: preferences.practiceMode.rawValue,
                examTimerEnabled: preferences.examTimerEnabled,
                language: preferences.language.rawValue,
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
        let data = try migratedProgressExportForTask4610(data)

        let usableSyncDeviceRows = try usableSyncDeviceRows(from: data, bank: bank)
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
            if let syncDeviceRows = usableSyncDeviceRows {
                for row in syncDeviceRows.questionProgress where row.record.bankId == bank.manifest.bankId {
                    try upsertQuestionProgress(row.record, deviceId: row.deviceId)
                }
                for row in syncDeviceRows.examAttempts where row.attempt.bankId == bank.manifest.bankId {
                    try saveExamAttemptWithoutSave(row.attempt, deviceId: row.deviceId)
                }
            } else {
                for record in data.questionProgress {
                    try upsertQuestionProgress(record)
                }
                for attempt in data.examAttempts {
                    try saveExamAttemptWithoutSave(attempt)
                }
            }
            var nextPreferences = preferences
            if let mode = ApplePreferences.PracticeMode(rawValue: data.preferences.practiceMode) {
                nextPreferences.practiceMode = mode
            }
            nextPreferences.examTimerEnabled = data.preferences.examTimerEnabled
            if let language = ApplePreferences.LanguagePreference(rawValue: data.preferences.language) {
                nextPreferences.language = language
            }
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
                if let syncDeviceRows = usableSyncDeviceRows {
                    try replaceDeviceLessonProgress(syncDeviceRows.lessonProgress)
                    try replaceDeviceLessonQuizAttempts(syncDeviceRows.lessonQuizAttempts)
                } else {
                    try replaceLessonProgress(try decodeArchivedArray(data.lessonProgress, as: LessonProgressRecord.self))
                    try replaceLessonQuizAttempts(try decodeArchivedArray(data.lessonQuizAttempts, as: LessonQuizAttempt.self))
                }
                entity.archivedLessonProgressData = Data("[]".utf8)
                entity.archivedLessonQuizAttemptsData = Data("[]".utf8)
            }
            if let syncDeviceRows = usableSyncDeviceRows, !syncDeviceRows.morseCourseProgress.isEmpty {
                try replaceDeviceMorseCourseProgress(syncDeviceRows.morseCourseProgress)
            } else if let morseCourseProgress = data.morseCourseProgress {
                try replaceDeviceMorseCourseProgress([DeviceMorseCourseProgressRecord(deviceId: localDeviceID, progress: morseCourseProgress)])
            }
#if DEBUG
            if failNextImportAfterMorseWriteForTesting {
                failNextImportAfterMorseWriteForTesting = false
                try context.save()
                throw ProgressStoreInjectedFailure.importAfterMorseWrite
            }
#endif
            try context.save()
            defaults.set(nextPreferences.activeBankId.rawValue, forKey: Self.activeBankPreferenceKey)
            if preferences.language != nextPreferences.language {
                Self.applyInterfaceLanguagePreference(nextPreferences.language, defaults: defaults)
            }
            preferences = nextPreferences
            objectWillChange.send()
        } catch {
            context.rollback()
            try restore(previousSnapshot)
            throw error
        }
    }

    private func migratedProgressExportForTask4610(_ data: ProgressExportV1) throws -> ProgressExportV1 {
        let migratesTopLevelRows = (data.lessonIdVersion ?? LessonIDContentVersion.legacy) == LessonIDContentVersion.legacy
        let decodedLessonProgress = try decodeArchivedArray(data.lessonProgress, as: LessonProgressRecord.self)
        let decodedLessonQuizAttempts = try decodeArchivedArray(data.lessonQuizAttempts, as: LessonQuizAttempt.self)
        var lessonProgress = migratesTopLevelRows ? migrateTask4610LessonProgress(decodedLessonProgress) : decodedLessonProgress
        let lessonQuizAttempts = migratesTopLevelRows ? migrateTask4610LessonQuizAttempts(decodedLessonQuizAttempts) : decodedLessonQuizAttempts
        let syncDeviceRows = data.syncDeviceRows.map(migrateTask4610SyncDeviceRows)
        if migratesTopLevelRows, let rawRows = data.syncDeviceRows, let migratedRows = syncDeviceRows,
           ProgressSyncMerge.deduplicateDeviceLessonProgress(rawRows.lessonProgress) == decodedLessonProgress.sorted(by: { $0.lessonId < $1.lessonId }) {
            lessonProgress = ProgressSyncMerge.deduplicateDeviceLessonProgress(migratedRows.lessonProgress)
        }
        return ProgressExportV1(
            schema: data.schema,
            version: data.version,
            lessonIdVersion: LessonIDContentVersion.isSupported(data.lessonIdVersion) ? LessonIDContentVersion.current : data.lessonIdVersion,
            exportedAt: data.exportedAt,
            bankId: data.bankId,
            questionProgress: data.questionProgress,
            examAttempts: data.examAttempts,
            lessonProgress: try archivedArray(lessonProgress),
            lessonQuizAttempts: try archivedArray(lessonQuizAttempts),
            morseCourseProgress: data.morseCourseProgress,
            syncDeviceRows: syncDeviceRows,
            preferences: data.preferences
        )
    }

    private func migrateTask4610SyncDeviceRows(_ rows: ProgressSyncDeviceRows) -> ProgressSyncDeviceRows {
        ProgressSyncDeviceRows(
            questionProgress: rows.questionProgress,
            examAttempts: rows.examAttempts,
            lessonProgress: migrateTask4610DeviceLessonProgress(rows.lessonProgress),
            lessonQuizAttempts: rows.lessonQuizAttempts.flatMap { row in
                guard LessonIDContentVersion.isSupported(row.lessonIdVersion) else { return [row] }
                guard row.lessonIdVersion != LessonIDContentVersion.current else { return [row] }
                return migrateTask4610LessonQuizAttempts([row.attempt]).map { DeviceLessonQuizAttemptRecord(deviceId: row.deviceId, attempt: $0, lessonIdVersion: LessonIDContentVersion.current) }
            },
            morseCourseProgress: rows.morseCourseProgress
        )
    }

    private func migrateTask4610LessonProgress(_ records: [LessonProgressRecord]) -> [LessonProgressRecord] {
        let sourcesByDestination: [String: [String]] = [
            "L-001-03": ["L-001-03"],
            "L-001-05": ["L-001-03", "L-001-05"],
            "L-005-04": ["L-005-04"],
            "L-005-05": ["L-005-04", "L-005-05"],
            "L-005-06": ["L-005-05"],
            "L-008-01": ["L-008-01", "L-008-02"],
            "L-008-02": ["L-008-01", "L-008-02"],
        ]
        let byId = Dictionary(records.map { ($0.lessonId, $0) }, uniquingKeysWith: { _, last in last })
        let destinations = Set(records.map(\.lessonId)).union(sourcesByDestination.keys)
        return destinations.sorted().compactMap { lessonId in
            let sourceIds = sourcesByDestination[lessonId] ?? [lessonId]
            let sources = sourceIds.compactMap { byId[$0] }
            guard sources.count == sourceIds.count else { return nil }
            return LessonProgressRecord(
                lessonId: lessonId,
                readAt: sources.map(\.readAt).max()!,
                readCount: sources.map(\.readCount).min()!
            )
        }
    }

    private func migrateTask4610DeviceLessonProgress(_ rows: [DeviceLessonProgressRecord]) -> [DeviceLessonProgressRecord] {
        let preserved = rows.filter { !LessonIDContentVersion.isSupported($0.lessonIdVersion) || $0.lessonIdVersion == LessonIDContentVersion.current }
        let legacy = rows.filter { LessonIDContentVersion.isSupported($0.lessonIdVersion) && $0.lessonIdVersion != LessonIDContentVersion.current }
        return preserved + Dictionary(grouping: legacy, by: \.deviceId).values.flatMap { deviceRows in
            migrateTask4610LessonProgress(ProgressSyncMerge.deduplicateDeviceLessonProgress(deviceRows)).map {
                DeviceLessonProgressRecord(deviceId: deviceRows[0].deviceId, record: $0, lessonIdVersion: LessonIDContentVersion.current)
            }
        }
    }

    private func migrateTask4610LessonQuizAttempts(_ attempts: [LessonQuizAttempt]) -> [LessonQuizAttempt] {
        let targetsByQuizId: [String: [(quizId: String, lessonId: String, prefixes: [String])]] = [
            "QZ-L-005-04-A": [
                ("QZ-L-005-04-A", "L-005-04", ["B-005-007-", "B-005-008-"]),
                ("QZ-L-005-05-A", "L-005-05", ["B-005-009-", "B-005-010-", "B-005-012-"]),
            ],
            "QZ-L-005-05-A": [
                ("QZ-L-005-05-A", "L-005-05", ["B-005-009-", "B-005-010-", "B-005-012-"]),
                ("QZ-L-005-06-A", "L-005-06", ["B-005-011-", "B-005-013-"]),
            ],
            "QZ-L-008-01-A": [
                ("QZ-L-008-01-A", "L-008-01", ["B-008-001-", "B-008-002-", "B-008-005-"]),
                ("QZ-L-008-02-A", "L-008-02", ["B-008-003-", "B-008-004-"]),
            ],
            "QZ-L-008-02-A": [
                ("QZ-L-008-01-A", "L-008-01", ["B-008-001-", "B-008-002-", "B-008-005-"]),
                ("QZ-L-008-02-A", "L-008-02", ["B-008-003-", "B-008-004-"]),
            ],
            "QZ-L-001-03-A": [
                ("QZ-L-001-03-A", "L-001-03", ["B-001-010-", "B-001-011-", "B-001-012-", "B-001-013-"]),
                ("QZ-L-001-05-A", "L-001-05", ["B-001-014-", "B-001-020-", "B-001-021-"]),
            ],
        ]
        // Ordered as in 350a3b53. Nil explicitly drops the old filter checks:
        // their text has no current equivalent, despite reuse of their IDs.
        let conceptMapping: [(old: String, new: String?)] = [
            ("QZ-L-005-04-A-C1", "QZ-L-005-04-A-C1"),
            ("QZ-L-005-04-A-C2", "QZ-L-005-05-A-C1"),
            ("QZ-L-005-04-A-C3", "QZ-L-005-05-A-C2"),
            ("QZ-L-005-05-A-C1", "QZ-L-005-06-A-C1"),
            ("QZ-L-005-05-A-C2", "QZ-L-005-05-A-C3"),
            ("QZ-L-005-05-A-C3", "QZ-L-005-06-A-C2"),
            ("QZ-L-008-01-A-C1", "QZ-L-008-01-A-C1"),
            ("QZ-L-008-01-A-C2", "QZ-L-008-01-A-C2"),
            ("QZ-L-008-01-A-C3", "QZ-L-008-01-A-C3"),
            ("QZ-L-008-02-A-C1", "QZ-L-008-02-A-C1"),
            ("QZ-L-008-02-A-C2", nil),
            ("QZ-L-008-02-A-C3", nil),
        ]
        var migrated: [String: LessonQuizAttempt] = [:]
        for attempt in attempts {
            guard let targets = targetsByQuizId[attempt.quizId] else {
                migrated[attempt.id] = attempt
                continue
            }
            // Partial attempts record a concept count, not correct concept IDs. Include
            // explicit wrong IDs first, then fill only the remaining slots in UI order.
            let oldConcepts = conceptMapping.filter { $0.old.hasPrefix("\(attempt.quizId)-C") }
            let wrongConceptIDs = Set(attempt.incorrectConceptCheckIds)
            let remainingConceptCount = max(0, attempt.total - attempt.officialQuestionIds.count - wrongConceptIDs.count)
            let answered = wrongConceptIDs.union(oldConcepts.filter { !wrongConceptIDs.contains($0.old) }.prefix(remainingConceptCount).map(\.old))
            let assignedConcepts = oldConcepts.filter { answered.contains($0.old) }.compactMap(\.new)
            let wrongConcepts = oldConcepts.filter { attempt.incorrectConceptCheckIds.contains($0.old) }.compactMap(\.new)
            // Inconsistent historical scores must not gain correct answers. Allocate the
            // recorded budget to the original destination first, then sorted quiz IDs.
            var remainingCorrect = max(0, attempt.correct)
            let orderedTargets = targets.sorted {
                if ($0.quizId == attempt.quizId) != ($1.quizId == attempt.quizId) { return $0.quizId == attempt.quizId }
                return $0.quizId < $1.quizId
            }
            for target in orderedTargets {
                let officialQuestionIds = attempt.officialQuestionIds.filter { questionId in target.prefixes.contains { questionId.hasPrefix($0) } }
                let incorrectOfficialQuestionIds = attempt.incorrectOfficialQuestionIds.filter { officialQuestionIds.contains($0) }
                let concepts = assignedConcepts.filter { $0.hasPrefix("\(target.quizId)-C") }
                let incorrectConceptCheckIds = wrongConcepts.filter { concepts.contains($0) }
                let total = officialQuestionIds.count + concepts.count
                if total == 0 { continue }
                let correct = min(remainingCorrect, officialQuestionIds.count - incorrectOfficialQuestionIds.count + concepts.count - incorrectConceptCheckIds.count)
                remainingCorrect -= correct
                let id = target.quizId == attempt.quizId ? attempt.id : "\(attempt.id)::\(target.quizId)"
                migrated[id] = LessonQuizAttempt(
                    id: id,
                    quizId: target.quizId,
                    lessonId: target.lessonId,
                    submittedAt: attempt.submittedAt,
                    correct: correct,
                    total: total,
                    percent: Double(correct) / Double(total) * 100,
                    officialQuestionIds: officialQuestionIds,
                    incorrectOfficialQuestionIds: incorrectOfficialQuestionIds,
                    incorrectConceptCheckIds: incorrectConceptCheckIds,
                    answeredWithHelpIds: attempt.answeredWithHelpIds.map { $0.filter(officialQuestionIds.contains) }
                )
            }
        }
        return migrated.values.sorted { lhs, rhs in
            lhs.submittedAt == rhs.submittedAt ? lhs.id < rhs.id : lhs.submittedAt < rhs.submittedAt
        }
    }

    func validate(_ data: ProgressExportV1, bank: QuestionBank) -> [String] {
        let errors = validateProgressExport(data, bank: bank)
        guard errors.isEmpty else { return errors }
        guard let migrated = try? migratedProgressExportForTask4610(data) else { return errors }
        return validateProgressExport(migrated, bank: bank)
    }

    private func validateProgressExport(_ data: ProgressExportV1, bank: QuestionBank) -> [String] {
        var errors: [String] = []
        let knownQuestionIds = Set(bank.questions.map(\.id))
        let knownCategoryIds = Set(bank.categories.map(\.id))
        let knownSubsectionIds = Set(bank.subsections.map(\.id))

        if data.schema != "canadian-ham.progress-export" { errors.append(String(localized: "Import file schema is not canadian-ham.progress-export.")) }
        if data.version != 1 { errors.append(String(localized: "Import file version must be 1.")) }
        if !LessonIDContentVersion.isSupported(data.lessonIdVersion) { errors.append(String(localized: "Import lessonIdVersion must be 1 or 2 when present.")) }
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
            if record.recentAnsweredWithHelp.count > 5 { errors.append(String(localized: "\(prefix).recentAnsweredWithHelp must contain at most five booleans.")) }
            if record.recentAnsweredWithHelp.count != record.recentResults.count { errors.append(String(localized: "\(prefix).recentAnsweredWithHelp must have the same length as recentResults.")) }
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
            lessonIdVersion: data.lessonIdVersion,
            errors: &errors
        )
        if let morseCourseProgress = data.morseCourseProgress {
            validateMorseCourseProgress(morseCourseProgress, errors: &errors)
        }
        if let syncDeviceRows = data.syncDeviceRows {
            validateSyncDeviceRows(syncDeviceRows, bank: bank, errors: &errors)
        }

        if ApplePreferences.PracticeMode(rawValue: data.preferences.practiceMode) == nil {
            errors.append(String(localized: "Import preferences.practiceMode is invalid."))
        }
        if ApplePreferences.LanguagePreference(rawValue: data.preferences.language) == nil {
            errors.append(String(localized: "Import preferences.language is invalid."))
        }
        if !ExportedMorseSettings.validTimingProfiles.contains(data.preferences.morse.timingProfile) {
            errors.append(String(localized: "Import preferences.morse.timingProfile is invalid."))
        }
        if !ExportedMorseSettings.validOutputModes.contains(data.preferences.morse.outputMode) {
            errors.append(String(localized: "Import preferences.morse.outputMode is invalid."))
        }
        if ApplePreferences.Theme(rawValue: data.preferences.theme) == nil {
            errors.append(String(localized: "Import preferences.theme is invalid."))
        }
        return errors
    }

    private func validateSyncDeviceRows(_ rows: ProgressSyncDeviceRows, bank: QuestionBank, errors: inout [String]) {
        let knownQuestionIds = Set(bank.questions.map(\.id))
        let knownCategoryIds = Set(bank.categories.map(\.id))
        let knownSubsectionIds = Set(bank.subsections.map(\.id))
        for (index, row) in rows.questionProgress.enumerated() {
            let prefix = "Import syncDeviceRows.questionProgress[\(index)]"
            if row.deviceId.isEmpty { errors.append(String(localized: "\(prefix).deviceId must be non-empty.")) }
            let record = row.record
            if record.bankId == bank.manifest.bankId && !knownQuestionIds.contains(record.questionId) { errors.append(String(localized: "\(prefix).record.questionId must be a known question ID.")) }
            if record.attempts < 0 { errors.append(String(localized: "\(prefix).record.attempts must be a non-negative integer.")) }
            if record.correctAttempts < 0 || record.correctAttempts > record.attempts { errors.append(String(localized: "\(prefix).record.correctAttempts must be between 0 and attempts.")) }
            appendTimestampError(&errors, value: record.lastAttemptedAt, field: "\(prefix).record.lastAttemptedAt")
            if record.recentResults.count > 5 { errors.append(String(localized: "\(prefix).record.recentResults must contain at most five booleans.")) }
            if record.recentAnsweredWithHelp.count > 5 { errors.append(String(localized: "\(prefix).record.recentAnsweredWithHelp must contain at most five booleans.")) }
            if record.recentAnsweredWithHelp.count != record.recentResults.count { errors.append(String(localized: "\(prefix).record.recentAnsweredWithHelp must have the same length as recentResults.")) }
            if !(0...5).contains(record.leitner.box) { errors.append(String(localized: "\(prefix).record.leitner.box must be an integer between 0 and 5.")) }
            appendTimestampError(&errors, value: record.leitner.dueAt, field: "\(prefix).record.leitner.dueAt")
        }
        for (index, row) in rows.examAttempts.enumerated() {
            let prefix = "Import syncDeviceRows.examAttempts[\(index)]"
            if row.deviceId.isEmpty { errors.append(String(localized: "\(prefix).deviceId must be non-empty.")) }
            let attempt = row.attempt
            if attempt.id.isEmpty { errors.append(String(localized: "\(prefix).attempt.id must be a non-empty string.")) }
            if attempt.mode != "mock-exam" { errors.append(String(localized: "\(prefix).attempt.mode must be mock-exam.")) }
            appendTimestampError(&errors, value: attempt.startedAt, field: "\(prefix).attempt.startedAt")
            appendTimestampError(&errors, value: attempt.submittedAt, field: "\(prefix).attempt.submittedAt")
            if attempt.timer.secondsAllowed != nil && attempt.timer.secondsAllowed! < 0 { errors.append(String(localized: "\(prefix).attempt.timer.secondsAllowed must be null or non-negative.")) }
            if attempt.timer.secondsElapsed < 0 { errors.append(String(localized: "\(prefix).attempt.timer.secondsElapsed must be non-negative.")) }
            if attempt.bankId == bank.manifest.bankId {
                validateScore(attempt.score, prefix: "\(prefix).attempt.score", bankId: bank.manifest.bankId, hasHonours: bank.courseBankID.hasHonours, knownCategoryIds: knownCategoryIds, knownSubsectionIds: knownSubsectionIds, errors: &errors)
                for (itemIndex, item) in attempt.items.enumerated() {
                    validateAttemptItem(item, prefix: "\(prefix).attempt.items[\(itemIndex)]", knownQuestionIds: knownQuestionIds, knownCategoryIds: knownCategoryIds, knownSubsectionIds: knownSubsectionIds, errors: &errors)
                }
            }
        }
        for (index, row) in rows.lessonProgress.enumerated() {
            let prefix = "Import syncDeviceRows.lessonProgress[\(index)]"
            if row.deviceId.isEmpty { errors.append(String(localized: "\(prefix).deviceId must be non-empty.")) }
            if !LessonIDContentVersion.isSupported(row.lessonIdVersion) { errors.append(String(localized: "\(prefix).lessonIdVersion must be 1 or 2 when present.")) }
            if let archived = try? archivedArray([row.record]) {
                if bank.courseBankID.hasLessons { validateLessonProgress(archived, knownLessonIds: bank.knownLessonIds, errors: &errors) }
            } else {
                errors.append(String.localizedStringWithFormat(String(localized: "%@.record must be a valid lesson progress record."), "Import syncDeviceRows.lessonProgress[\(index)]"))
            }
        }
        for (index, row) in rows.lessonQuizAttempts.enumerated() {
            let prefix = "Import syncDeviceRows.lessonQuizAttempts[\(index)]"
            if row.deviceId.isEmpty { errors.append(String(localized: "\(prefix).deviceId must be non-empty.")) }
            if !LessonIDContentVersion.isSupported(row.lessonIdVersion) { errors.append(String(localized: "\(prefix).lessonIdVersion must be 1 or 2 when present.")) }
            if let archived = try? archivedArray([row.attempt]) {
                if bank.courseBankID.hasLessons { validateLessonQuizAttempts(archived, knownQuestionIds: knownQuestionIds, knownLessonIds: bank.knownLessonIds, lessonQuizzesById: bank.lessonQuizzesById, lessonIdVersion: row.lessonIdVersion, errors: &errors) }
            } else {
                errors.append(String.localizedStringWithFormat(String(localized: "%@.attempt must be a valid lesson quiz attempt."), "Import syncDeviceRows.lessonQuizAttempts[\(index)]"))
            }
        }
        for (index, row) in rows.morseCourseProgress.enumerated() {
            let prefix = "Import syncDeviceRows.morseCourseProgress[\(index)]"
            if row.deviceId.isEmpty { errors.append(String(localized: "\(prefix).deviceId must be non-empty.")) }
            validateMorseCourseProgress(row.progress, errors: &errors)
        }
    }

    private func usableSyncDeviceRows(from data: ProgressExportV1, bank: QuestionBank) throws -> ProgressSyncDeviceRows? {
        guard let rows = data.syncDeviceRows else { return nil }
        let questionIds = Set(data.questionProgress.map(\.questionId))
        let examSubmittedAt = Set(data.examAttempts.map { "\($0.bankId)\u{0}\($0.submittedAt)" })
        let lessonProgress = try decodeArchivedArray(data.lessonProgress, as: LessonProgressRecord.self)
        let lessonIds = Set(lessonProgress.map(\.lessonId))
        let lessonQuizAttempts = try decodeArchivedArray(data.lessonQuizAttempts, as: LessonQuizAttempt.self)
        let lessonQuizIds = Set(lessonQuizAttempts.map(\.id))
        let filtered = ProgressSyncDeviceRows(
            questionProgress: rows.questionProgress.filter { $0.record.bankId == bank.manifest.bankId && questionIds.contains($0.record.questionId) },
            examAttempts: rows.examAttempts.filter { $0.attempt.bankId == bank.manifest.bankId && examSubmittedAt.contains("\($0.attempt.bankId)\u{0}\($0.attempt.submittedAt)") },
            lessonProgress: bank.courseBankID.hasLessons ? rows.lessonProgress.filter { lessonIds.contains($0.record.lessonId) } : [],
            lessonQuizAttempts: bank.courseBankID.hasLessons ? rows.lessonQuizAttempts.filter { lessonQuizIds.contains($0.attempt.id) } : [],
            morseCourseProgress: data.morseCourseProgress == nil ? [] : rows.morseCourseProgress
        )
        let mergedQuestions = ProgressSyncMerge.deduplicateDeviceQuestionProgress(filtered.questionProgress)
        guard sortedQuestions(mergedQuestions) == sortedQuestions(data.questionProgress) else { return nil }
        let mergedAttempts = ProgressSyncMerge.deduplicateDeviceExamAttempts(filtered.examAttempts)
        guard sortedAttempts(mergedAttempts) == sortedAttempts(data.examAttempts) else { return nil }
        guard ProgressSyncMerge.deduplicateDeviceLessonProgress(filtered.lessonProgress) == lessonProgress.sorted(by: { $0.lessonId < $1.lessonId }) else { return nil }
        guard ProgressSyncMerge.deduplicateDeviceLessonQuizAttempts(filtered.lessonQuizAttempts) == lessonQuizAttempts.sorted(by: { $0.submittedAt == $1.submittedAt ? $0.id < $1.id : $0.submittedAt < $1.submittedAt }) else { return nil }
        guard ProgressSyncMerge.mergeDeviceMorseCourseProgress(filtered.morseCourseProgress) == data.morseCourseProgress else { return nil }
        return filtered
    }

    private func sortedQuestions(_ records: [QuestionProgressRecord]) -> [QuestionProgressRecord] {
        records.sorted { lhs, rhs in
            if lhs.bankId != rhs.bankId { return lhs.bankId < rhs.bankId }
            return lhs.questionId < rhs.questionId
        }
    }

    private func sortedAttempts(_ attempts: [StoredExamAttempt]) -> [StoredExamAttempt] {
        attempts.sorted { lhs, rhs in
            if lhs.bankId != rhs.bankId { return lhs.bankId < rhs.bankId }
            if lhs.submittedAt != rhs.submittedAt { return lhs.submittedAt < rhs.submittedAt }
            return lhs.id < rhs.id
        }
    }

    private struct CounterSums {
        var attempts: Int
        var correctAttempts: Int
    }

    private struct QuestionProgressWriteContext {
        var mergedByKey: [String: QuestionProgressRecord]
        var otherDeviceSumsByKey: [String: CounterSums]
    }

    private func questionProgressKey(bankId: String, questionId: String) -> String {
        "\(bankId)\u{0}\(questionId)"
    }

    private func questionProgressWriteContext(forDeviceId deviceId: String) throws -> QuestionProgressWriteContext {
#if DEBUG
        questionProgressWriteContextBuildCountForTesting += 1
#endif
        let rows = try deviceQuestionProgressRows()
        let mergedByKey = Dictionary(uniqueKeysWithValues: ProgressSyncMerge.deduplicateDeviceQuestionProgress(rows).map {
            (questionProgressKey(bankId: $0.bankId, questionId: $0.questionId), $0)
        })
        let otherRowsByDevice = Dictionary(grouping: rows.filter { $0.deviceId != deviceId }) {
            "\(questionProgressKey(bankId: $0.record.bankId, questionId: $0.record.questionId))\u{0}\($0.deviceId)"
        }
        var otherDeviceSumsByKey: [String: CounterSums] = [:]
        for group in otherRowsByDevice.values {
            guard let first = group.first else { continue }
            let key = questionProgressKey(bankId: first.record.bankId, questionId: first.record.questionId)
            let maxAttempts = group.map(\.record.attempts).max() ?? 0
            let maxCorrectAttempts = group.map(\.record.correctAttempts).max() ?? 0
            let existing = otherDeviceSumsByKey[key, default: CounterSums(attempts: 0, correctAttempts: 0)]
            otherDeviceSumsByKey[key] = CounterSums(
                attempts: existing.attempts + maxAttempts,
                correctAttempts: existing.correctAttempts + maxCorrectAttempts
            )
        }
        return QuestionProgressWriteContext(mergedByKey: mergedByKey, otherDeviceSumsByKey: otherDeviceSumsByKey)
    }

    private func upsertQuestionProgress(_ record: QuestionProgressRecord, deviceId: String? = nil, writeContext: QuestionProgressWriteContext? = nil) throws {
        let rowDeviceId = deviceId ?? localDeviceID
        let key = questionProgressKey(bankId: record.bankId, questionId: record.questionId)
        if deviceId == nil, let currentMerged = writeContext?.mergedByKey[key], currentMerged == record {
            return
        }
        let existing = try questionProgressEntity(questionId: record.questionId, bankId: record.bankId, deviceId: rowDeviceId)
        let ownOldAttempts = existing?.attempts ?? 0
        let ownOldCorrectAttempts = existing?.correctAttempts ?? 0
        let writeRecord: QuestionProgressRecord
        if deviceId == nil {
            let otherSums: CounterSums
            if let writeContext {
                otherSums = writeContext.otherDeviceSumsByKey[key, default: CounterSums(attempts: 0, correctAttempts: 0)]
            } else {
                otherSums = try otherDeviceQuestionProgressSums(questionId: record.questionId, bankId: record.bankId, excludingDeviceId: rowDeviceId)
            }
            let ownAttempts = max(ownOldAttempts, record.attempts - otherSums.attempts)
            let ownCorrectAttempts = min(ownAttempts, max(ownOldCorrectAttempts, record.correctAttempts - otherSums.correctAttempts))
            writeRecord = QuestionProgressRecord(
                questionId: record.questionId,
                bankId: record.bankId,
                attempts: ownAttempts,
                correctAttempts: ownCorrectAttempts,
                lastAttemptedAt: record.lastAttemptedAt,
                lastResult: record.lastResult,
                lastAnsweredWithHelp: record.lastAnsweredWithHelp,
                recentResults: record.recentResults,
                recentAnsweredWithHelp: record.recentAnsweredWithHelp,
                leitner: record.leitner,
                notes: record.notes
            )
        } else {
            writeRecord = record
        }
        let data = try encoder.encode(writeRecord.recentResults)
        let recentAnsweredWithHelpData = try encoder.encode(writeRecord.recentAnsweredWithHelp)
        if let entity = existing {
            entity.bankId = writeRecord.bankId
            entity.attempts = writeRecord.attempts
            entity.correctAttempts = writeRecord.correctAttempts
            entity.lastAttemptedAt = writeRecord.lastAttemptedAt
            entity.lastResult = writeRecord.lastResult.rawValue
            entity.lastAnsweredWithHelp = writeRecord.lastAnsweredWithHelp
            entity.recentResultsData = data
            entity.recentAnsweredWithHelpData = recentAnsweredWithHelpData
            entity.leitnerBox = writeRecord.leitner.box
            entity.dueAt = writeRecord.leitner.dueAt
            entity.notes = writeRecord.notes
            entity.deviceId = rowDeviceId
        } else {
            context.insert(QuestionProgressEntity(
                questionId: writeRecord.questionId,
                bankId: writeRecord.bankId,
                attempts: writeRecord.attempts,
                correctAttempts: writeRecord.correctAttempts,
                lastAttemptedAt: writeRecord.lastAttemptedAt,
                lastResult: writeRecord.lastResult.rawValue,
                lastAnsweredWithHelp: writeRecord.lastAnsweredWithHelp,
                recentResultsData: data,
                recentAnsweredWithHelpData: recentAnsweredWithHelpData,
                leitnerBox: writeRecord.leitner.box,
                dueAt: writeRecord.leitner.dueAt,
                notes: writeRecord.notes,
                deviceId: rowDeviceId
            ))
        }
    }

    private func otherDeviceQuestionProgressSums(questionId: String, bankId: String, excludingDeviceId deviceId: String) throws -> CounterSums {
        let otherRowsByDevice = Dictionary(grouping: try questionProgressEntities(questionId: questionId, bankId: bankId).filter { ($0.deviceId.isEmpty ? localDeviceID : $0.deviceId) != deviceId }) { entity in
            entity.deviceId.isEmpty ? localDeviceID : entity.deviceId
        }
        var sums = CounterSums(attempts: 0, correctAttempts: 0)
        for rows in otherRowsByDevice.values {
            sums.attempts += rows.map(\.attempts).max() ?? 0
            sums.correctAttempts += rows.map(\.correctAttempts).max() ?? 0
        }
        return sums
    }

    private func questionProgressEntity(questionId: String, bankId: String, deviceId: String) throws -> QuestionProgressEntity? {
        let entities = try questionProgressEntities(questionId: questionId, bankId: bankId, deviceId: deviceId)
        guard let survivor = entities.first else { return nil }
        for duplicate in entities.dropFirst() {
            context.delete(duplicate)
        }
        return survivor
    }

    private func questionProgressEntities(questionId: String, bankId: String, deviceId: String) throws -> [QuestionProgressEntity] {
        let targetQuestionId = questionId
        let targetBankId = bankId
        let targetDeviceId = deviceId
        let descriptor = FetchDescriptor<QuestionProgressEntity>(predicate: #Predicate { $0.questionId == targetQuestionId && $0.bankId == targetBankId && $0.deviceId == targetDeviceId })
        return try context.fetch(descriptor)
    }

    private func questionProgressEntities(questionId: String, bankId: String) throws -> [QuestionProgressEntity] {
        let targetQuestionId = questionId
        let targetBankId = bankId
        let descriptor = FetchDescriptor<QuestionProgressEntity>(predicate: #Predicate { $0.questionId == targetQuestionId && $0.bankId == targetBankId })
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

    private func examAttemptEntity(bankId: String, submittedAt: String, deviceId: String) throws -> ExamAttemptEntity? {
        let entities = try examAttemptEntities(submittedAt: submittedAt, bankId: bankId, deviceId: deviceId)
        guard let survivor = entities.first else { return nil }
        for duplicate in entities.dropFirst() {
            context.delete(duplicate)
        }
        return survivor
    }

    private func examAttemptEntities(submittedAt: String, bankId: String, deviceId: String) throws -> [ExamAttemptEntity] {
        let targetSubmittedAt = submittedAt
        let targetBankId = bankId
        let targetDeviceId = deviceId
        let descriptor = FetchDescriptor<ExamAttemptEntity>(predicate: #Predicate { $0.submittedAt == targetSubmittedAt && $0.bankId == targetBankId && $0.deviceId == targetDeviceId })
        return try context.fetch(descriptor)
    }

    private func upsertLessonProgress(_ record: LessonProgressRecord, deviceId: String? = nil, mergesExistingReadCount: Bool = false) throws {
        let rowDeviceId = deviceId ?? localDeviceID
        if deviceId == nil,
           let currentMerged = try lessonProgressRecords().first(where: { $0.lessonId == record.lessonId }),
           currentMerged == record {
            return
        }
        let targetLessonId = record.lessonId
        let targetDeviceId = rowDeviceId
        let descriptor = FetchDescriptor<LessonProgressEntity>(predicate: #Predicate { $0.lessonId == targetLessonId && $0.deviceId == targetDeviceId })
        let entities = try context.fetch(descriptor)
        let existing = entities.first
        let ownOldReadCount = entities.map(\.readCount).max() ?? 0
        let writeRecord: LessonProgressRecord
        if deviceId == nil {
            let otherReadCount = try otherDeviceLessonReadCount(lessonId: targetLessonId, excludingDeviceId: rowDeviceId)
            writeRecord = LessonProgressRecord(
                lessonId: record.lessonId,
                readAt: record.readAt,
                readCount: max(ownOldReadCount, record.readCount - otherReadCount)
            )
        } else if mergesExistingReadCount {
            writeRecord = LessonProgressRecord(
                lessonId: record.lessonId,
                readAt: max(entities.map(\.readAt).max() ?? record.readAt, record.readAt),
                readCount: max(ownOldReadCount, record.readCount)
            )
        } else {
            writeRecord = record
        }
        let survivor = existing ?? LessonProgressEntity(lessonId: writeRecord.lessonId, readAt: writeRecord.readAt, readCount: writeRecord.readCount, deviceId: rowDeviceId)
        if entities.isEmpty {
            context.insert(survivor)
        }
        survivor.lessonId = writeRecord.lessonId
        survivor.readAt = writeRecord.readAt
        survivor.readCount = writeRecord.readCount
        survivor.deviceId = rowDeviceId
        for duplicate in entities.dropFirst() {
            context.delete(duplicate)
        }
    }

    private func otherDeviceLessonReadCount(lessonId: String, excludingDeviceId deviceId: String) throws -> Int {
        let targetLessonId = lessonId
        let descriptor = FetchDescriptor<LessonProgressEntity>(predicate: #Predicate { $0.lessonId == targetLessonId })
        let otherRowsByDevice = Dictionary(grouping: try context.fetch(descriptor).filter { ($0.deviceId.isEmpty ? localDeviceID : $0.deviceId) != deviceId }) { entity in
            entity.deviceId.isEmpty ? localDeviceID : entity.deviceId
        }
        return otherRowsByDevice.values.map { rows in rows.map(\.readCount).max() ?? 0 }.reduce(0, +)
    }

    private func upsertLessonQuizAttempt(_ attempt: LessonQuizAttempt, deviceId: String? = nil) throws {
        let rowDeviceId = deviceId ?? localDeviceID
        let targetId = attempt.id
        let targetDeviceId = rowDeviceId
        let descriptor = FetchDescriptor<LessonQuizAttemptEntity>(predicate: #Predicate { $0.id == targetId && $0.deviceId == targetDeviceId })
        let entities = try context.fetch(descriptor)
        let payload = try encoder.encode(attempt)
        let survivor = entities.first ?? LessonQuizAttemptEntity(id: attempt.id, quizId: attempt.quizId, lessonId: attempt.lessonId, submittedAt: attempt.submittedAt, payloadData: payload, deviceId: rowDeviceId)
        if entities.isEmpty {
            context.insert(survivor)
        }
        survivor.id = attempt.id
        survivor.quizId = attempt.quizId
        survivor.lessonId = attempt.lessonId
        survivor.submittedAt = attempt.submittedAt
        survivor.payloadData = payload
        survivor.deviceId = rowDeviceId
        for duplicate in entities.dropFirst() {
            context.delete(duplicate)
        }
    }

    private func upsertMorseCourseProgress(_ progress: MorseCourseProgressExport, deviceId: String? = nil) throws {
        let rowDeviceId = deviceId ?? localDeviceID
        if deviceId == nil, let currentMerged = try morseCourseProgress(), currentMerged == progress {
            return
        }
        let key = MorseCourseProgressEntity.defaultKey
        let targetDeviceId = rowDeviceId
        let descriptor = FetchDescriptor<MorseCourseProgressEntity>(predicate: #Predicate { $0.key == key && $0.deviceId == targetDeviceId })
        let entities = try context.fetch(descriptor)
        let existing = entities.first
        let writeProgress: MorseCourseProgressExport
        if deviceId == nil {
            let ownProgress = try existing.map { try decoder.decode(MorseCourseProgressExport.self, from: $0.payloadData) } ?? MorseCourseProgressExport(courseId: progress.courseId, lessonProgress: [], characterStats: [], dailyActivity: [])
            let allDescriptor = FetchDescriptor<MorseCourseProgressEntity>(predicate: #Predicate { $0.key == key })
            let otherRows = try context.fetch(allDescriptor)
                .filter { $0.deviceId != rowDeviceId }
                .map { DeviceMorseCourseProgressRecord(deviceId: $0.deviceId, progress: try decoder.decode(MorseCourseProgressExport.self, from: $0.payloadData)) }
            let otherProgress = ProgressSyncMerge.mergeDeviceMorseCourseProgress(otherRows)
            let currentMerged = try morseCourseProgress()
            var ownLessons = Dictionary(ownProgress.lessonProgress.map { ($0.lessonId, $0) }, uniquingKeysWith: { _, new in new })
            let otherLessons = Dictionary((otherProgress?.lessonProgress ?? []).map { ($0.lessonId, $0) }, uniquingKeysWith: { _, new in new })
            let currentLessons = Dictionary((currentMerged?.lessonProgress ?? []).map { ($0.lessonId, $0) }, uniquingKeysWith: { _, new in new })
            for record in progress.lessonProgress where currentLessons[record.lessonId] != record && record.attempts > (currentLessons[record.lessonId]?.attempts ?? 0) {
                let ownOldAttempts = ownLessons[record.lessonId]?.attempts ?? 0
                let otherAttempts = otherLessons[record.lessonId]?.attempts ?? 0
                ownLessons[record.lessonId] = MorseLessonProgressRecord(
                    lessonId: record.lessonId,
                    attempts: max(ownOldAttempts, record.attempts - otherAttempts),
                    bestAccuracy: record.bestAccuracy,
                    lastAccuracy: record.lastAccuracy,
                    lastAttemptedAt: record.lastAttemptedAt,
                    completedAt: record.completedAt
                )
            }
            var ownCharacters = Dictionary(ownProgress.characterStats.map { ($0.character, $0) }, uniquingKeysWith: { _, new in new })
            let otherCharacters = Dictionary((otherProgress?.characterStats ?? []).map { ($0.character, $0) }, uniquingKeysWith: { _, new in new })
            let currentCharacters = Dictionary((currentMerged?.characterStats ?? []).map { ($0.character, $0) }, uniquingKeysWith: { _, new in new })
            for record in progress.characterStats where currentCharacters[record.character] != record && record.attempts > (currentCharacters[record.character]?.attempts ?? 0) {
                let ownOldAttempts = ownCharacters[record.character]?.attempts ?? 0
                let ownOldCorrectAttempts = ownCharacters[record.character]?.correctAttempts ?? 0
                let other = otherCharacters[record.character]
                let ownAttempts = max(ownOldAttempts, record.attempts - (other?.attempts ?? 0))
                let ownCorrectAttempts = min(ownAttempts, max(ownOldCorrectAttempts, record.correctAttempts - (other?.correctAttempts ?? 0)))
                ownCharacters[record.character] = MorseCharacterStatRecord(
                    character: record.character,
                    attempts: ownAttempts,
                    correctAttempts: ownCorrectAttempts,
                    recentResults: record.recentResults,
                    lastPracticedAt: record.lastPracticedAt
                )
            }
            var ownDailyActivity = Dictionary(ownProgress.dailyActivity.map { ($0.date, $0) }, uniquingKeysWith: { old, new in old.lessonsCompleted >= new.lessonsCompleted ? old : new })
            let otherDailyActivity = Dictionary((otherProgress?.dailyActivity ?? []).map { ($0.date, $0) }, uniquingKeysWith: { old, new in old.lessonsCompleted >= new.lessonsCompleted ? old : new })
            let currentDailyActivity = Dictionary((currentMerged?.dailyActivity ?? []).map { ($0.date, $0) }, uniquingKeysWith: { old, new in old.lessonsCompleted >= new.lessonsCompleted ? old : new })
            for record in progress.dailyActivity where currentDailyActivity[record.date] != record && record.lessonsCompleted > (currentDailyActivity[record.date]?.lessonsCompleted ?? 0) {
                let ownOldLessonsCompleted = ownDailyActivity[record.date]?.lessonsCompleted ?? 0
                let otherLessonsCompleted = otherDailyActivity[record.date]?.lessonsCompleted ?? 0
                ownDailyActivity[record.date] = MorseDailyActivityRecord(
                    date: record.date,
                    lessonsCompleted: max(ownOldLessonsCompleted, record.lessonsCompleted - otherLessonsCompleted)
                )
            }
            writeProgress = MorseCourseProgressExport(
                courseId: progress.courseId,
                lessonProgress: ownLessons.values.sorted { $0.lessonId < $1.lessonId },
                characterStats: ownCharacters.values.sorted { $0.character < $1.character },
                dailyActivity: ownDailyActivity.values.sorted { $0.date < $1.date }
            )
        } else {
            writeProgress = progress
        }
        let payload = try encoder.encode(writeProgress)
        let survivor = existing ?? MorseCourseProgressEntity(payloadData: payload, deviceId: rowDeviceId)
        if entities.isEmpty {
            context.insert(survivor)
        }
        survivor.key = key
        survivor.payloadData = payload
        survivor.deviceId = rowDeviceId
        for duplicate in entities.dropFirst() {
            context.delete(duplicate)
        }
    }

    private func replaceLessonProgress(_ records: [LessonProgressRecord]) throws {
        try context.delete(model: LessonProgressEntity.self)
        for record in records {
            try upsertLessonProgress(record)
        }
    }

    private func replaceLessonQuizAttempts(_ attempts: [LessonQuizAttempt]) throws {
        try context.delete(model: LessonQuizAttemptEntity.self)
        for attempt in attempts {
            try upsertLessonQuizAttempt(attempt)
        }
    }

    private func replaceDeviceLessonProgress(_ rows: [DeviceLessonProgressRecord]) throws {
        try context.delete(model: LessonProgressEntity.self)
        for row in rows {
            try upsertLessonProgress(row.record, deviceId: row.deviceId)
        }
    }

    private func replaceDeviceLessonQuizAttempts(_ rows: [DeviceLessonQuizAttemptRecord]) throws {
        try context.delete(model: LessonQuizAttemptEntity.self)
        for row in rows {
            try upsertLessonQuizAttempt(row.attempt, deviceId: row.deviceId)
        }
    }

    private func replaceDeviceMorseCourseProgress(_ rows: [DeviceMorseCourseProgressRecord]) throws {
        try context.delete(model: MorseCourseProgressEntity.self)
        for row in rows {
            try upsertMorseCourseProgress(row.progress, deviceId: row.deviceId)
        }
    }

    private func archivedArray<T: Encodable>(_ values: [T]) throws -> [ArchivedJSON] {
        try decoder.decode([ArchivedJSON].self, from: encoder.encode(values))
    }

    private func decodeArchivedArray<T: Decodable>(_ archived: [ArchivedJSON], as type: T.Type) throws -> [T] {
        try decoder.decode([T].self, from: encoder.encode(archived))
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
        if migrateLegacyEnglishLanguageDefaultIfNeeded(entity) {
            adoptExternalInterfaceLanguageSelectionIfNeeded(entity)
        }
        return ApplePreferences(
            practiceMode: ApplePreferences.PracticeMode(rawValue: entity.practiceMode) ?? .immediate,
            examTimerEnabled: entity.examTimerEnabled,
            language: ApplePreferences.LanguagePreference(rawValue: entity.language) ?? .system,
            theme: ApplePreferences.Theme(rawValue: entity.theme) ?? .system,
            activeBankId: CourseBankID(rawValue: defaults.string(forKey: Self.activeBankPreferenceKey) ?? "") ?? .basic
        )
    }

    private func migrateLegacyEnglishLanguageDefaultIfNeeded(_ entity: PreferencesEntity) -> Bool {
        guard !defaults.bool(forKey: Self.legacyEnglishLanguageMigrationMarkerKey) else { return true }
        switch ApplePreferences.LanguagePreference(rawValue: entity.language) ?? .system {
        case .english:
            do {
                entity.language = ApplePreferences.LanguagePreference.system.rawValue
#if DEBUG
                if Self.failNextLegacyLanguageMigrationSaveForTesting {
                    Self.failNextLegacyLanguageMigrationSaveForTesting = false
                    throw ProgressStoreInjectedFailure.legacyLanguageMigrationSave
                }
#endif
                try context.save()
                defaults.set(true, forKey: Self.legacyEnglishLanguageMigrationMarkerKey)
            } catch {
                context.rollback()
                NSLog("CanadianHam: unable to migrate legacy English language default; will retry on next launch: %@", String(describing: error))
                return false
            }
        case .french:
            if Self.persistentAppleLanguages(defaults: defaults, domainName: defaultsDomainName) == nil {
                Self.applyInterfaceLanguagePreference(.french, defaults: defaults)
            }
            defaults.set(true, forKey: Self.legacyEnglishLanguageMigrationMarkerKey)
        case .system:
            defaults.set(true, forKey: Self.legacyEnglishLanguageMigrationMarkerKey)
        }
        return true
    }

    private func adoptExternalInterfaceLanguageSelectionIfNeeded(_ entity: PreferencesEntity) {
#if os(iOS) || os(macOS)
        let persistentPreference = Self.persistentAppleLanguagesPreference(defaults: defaults, domainName: defaultsDomainName)
        guard Self.lastAppliedInterfaceLanguagePreference(defaults: defaults) != persistentPreference else { return }
        do {
            entity.language = persistentPreference.rawValue
            try context.save()
            Self.recordLastAppliedInterfaceLanguagePreference(persistentPreference, defaults: defaults)
        } catch {
            context.rollback()
            NSLog("CanadianHam: unable to adopt app-level AppleLanguages preference; will retry on next launch: %@", String(describing: error))
        }
#else
        _ = entity
#endif
    }

    private func adoptLegacyDeviceRowsIfNeeded() throws {
        var changed = false
        for entity in try context.fetch(FetchDescriptor<QuestionProgressEntity>()) where entity.deviceId.isEmpty {
            entity.deviceId = localDeviceID
            changed = true
        }
        for entity in try context.fetch(FetchDescriptor<ExamAttemptEntity>()) where entity.deviceId.isEmpty {
            entity.deviceId = localDeviceID
            changed = true
        }
        for entity in try context.fetch(FetchDescriptor<LessonProgressEntity>()) where entity.deviceId.isEmpty {
            entity.deviceId = localDeviceID
            changed = true
        }
        for entity in try context.fetch(FetchDescriptor<LessonQuizAttemptEntity>()) where entity.deviceId.isEmpty {
            entity.deviceId = localDeviceID
            changed = true
        }
        for entity in try context.fetch(FetchDescriptor<MorseCourseProgressEntity>()) where entity.deviceId.isEmpty {
            entity.deviceId = localDeviceID
            changed = true
        }
        if changed {
            try context.save()
        }
    }

    private func migrateLearningProgressFromLegacyStorageIfNeeded() throws {
        let entity = try preferencesEntity(createIfMissing: true, saveIfCreated: false)
        if let lessonProgress = try? decoder.decode([LessonProgressRecord].self, from: entity.archivedLessonProgressData), !lessonProgress.isEmpty {
            for record in lessonProgress {
                try upsertLessonProgress(record, deviceId: localDeviceID, mergesExistingReadCount: true)
            }
            entity.archivedLessonProgressData = Data("[]".utf8)
        }
        if let attempts = try? decoder.decode([LessonQuizAttempt].self, from: entity.archivedLessonQuizAttemptsData), !attempts.isEmpty {
            for attempt in attempts {
                try upsertLessonQuizAttempt(attempt)
            }
            entity.archivedLessonQuizAttemptsData = Data("[]".utf8)
        }
        let key = MorseCourseProgressEntity.defaultKey
        let morseDescriptor = FetchDescriptor<MorseCourseProgressEntity>(predicate: #Predicate { $0.key == key })
        var migratedMorseLegacyFile = false
        if try context.fetch(morseDescriptor).isEmpty,
           FileManager.default.fileExists(atPath: morseCourseProgressURL.path(percentEncoded: false)) {
            do {
                let data = try Data(contentsOf: morseCourseProgressURL)
                let progress = try decoder.decode(MorseCourseProgressExport.self, from: data)
                try upsertMorseCourseProgress(progress)
                migratedMorseLegacyFile = true
            } catch {
                NSLog("CanadianHam: unable to migrate legacy Morse course progress JSON; leaving file in place: %@", String(describing: error))
            }
        }
        try context.save()
        if migratedMorseLegacyFile {
            do {
                try FileManager.default.removeItem(at: morseCourseProgressURL)
            } catch {
                NSLog("CanadianHam: unable to remove migrated legacy Morse course progress JSON; leaving file in place: %@", String(describing: error))
            }
        }
    }

    private func migrateTask4610LessonReferencesIfNeeded() throws {
        let markerKey = Self.task4610LessonSplitMigrationMarkerKey
        let markerDescriptor = FetchDescriptor<PreferencesEntity>(predicate: #Predicate { $0.key == markerKey })
        guard try context.fetch(markerDescriptor).isEmpty else { return }
        let lessonRows = try deviceLessonProgressRows().map {
            DeviceLessonProgressRecord(deviceId: $0.deviceId, record: $0.record, lessonIdVersion: LessonIDContentVersion.legacy)
        }
        let quizRows = try deviceLessonQuizAttemptRows()
        try context.delete(model: LessonProgressEntity.self)
        try context.delete(model: LessonQuizAttemptEntity.self)
        for row in migrateTask4610DeviceLessonProgress(lessonRows) {
            try upsertLessonProgress(row.record, deviceId: row.deviceId)
        }
        for row in quizRows {
            for attempt in migrateTask4610LessonQuizAttempts([row.attempt]) {
                try upsertLessonQuizAttempt(attempt, deviceId: row.deviceId)
            }
        }
        // A keyed local preferences row is the durable marker. It participates in
        // the same SwiftData transaction as the rewritten lesson/quiz rows, without
        // changing a released versioned schema or relying on UserDefaults flushing.
        context.insert(PreferencesEntity(
            key: markerKey, practiceMode: "immediate", examTimerEnabled: false,
            language: "system", theme: "system"
        ))
        try context.save()
        objectWillChange.send()
    }

    private func saveExamAttemptWithoutSave(_ attempt: StoredExamAttempt, deviceId: String? = nil) throws {
        let rowDeviceId = deviceId ?? localDeviceID
        let data = try encoder.encode(attempt)
        if let existing = try examAttemptEntity(bankId: attempt.bankId, submittedAt: attempt.submittedAt, deviceId: rowDeviceId) {
            existing.id = attempt.id
            existing.bankId = attempt.bankId
            existing.seed = attempt.seed
            existing.startedAt = attempt.startedAt
            existing.submittedAt = attempt.submittedAt
            existing.payloadData = data
            existing.deviceId = rowDeviceId
        } else {
            context.insert(ExamAttemptEntity(
                id: attempt.id,
                bankId: attempt.bankId,
                seed: attempt.seed,
                startedAt: attempt.startedAt,
                submittedAt: attempt.submittedAt,
                payloadData: data,
                deviceId: rowDeviceId
            ))
        }
    }

    private func snapshotForRollback() throws -> ProgressStoreSnapshot {
        let entity = try existingPreferencesEntity()
        return ProgressStoreSnapshot(
            questionProgress: try questionProgressRecords(),
            examAttempts: try examAttempts(),
            lessonProgress: try lessonProgressRecords(),
            lessonQuizAttempts: try lessonQuizAttempts(),
            preferences: preferences,
            archivedLessonProgressData: entity?.archivedLessonProgressData ?? Data("[]".utf8),
            archivedLessonQuizAttemptsData: entity?.archivedLessonQuizAttemptsData ?? Data("[]".utf8),
            morseCourseProgress: try morseCourseProgress(),
            syncDeviceRows: try syncDeviceRowsSnapshot()
        )
    }

    private func removeMorseCourseProgressIfPresent() throws {
        let key = MorseCourseProgressEntity.defaultKey
        let descriptor = FetchDescriptor<MorseCourseProgressEntity>(predicate: #Predicate { $0.key == key })
        let entities = try context.fetch(descriptor)
        let hasLegacyFile = FileManager.default.fileExists(atPath: morseCourseProgressURL.path(percentEncoded: false))
        if !entities.isEmpty || hasLegacyFile {
#if DEBUG
            if failNextMorseCourseProgressRemovalForTesting {
                failNextMorseCourseProgressRemovalForTesting = false
                throw ProgressStoreInjectedFailure.morseCourseProgressRemoval
            }
#endif
            for entity in entities {
                context.delete(entity)
            }
            if hasLegacyFile {
                try FileManager.default.removeItem(at: morseCourseProgressURL)
            }
        }
    }

    private func isProgressStoreEmpty(in context: ModelContext) throws -> Bool {
        try context.fetch(FetchDescriptor<QuestionProgressEntity>()).isEmpty
            && context.fetch(FetchDescriptor<ExamAttemptEntity>()).isEmpty
            && context.fetch(FetchDescriptor<LessonProgressEntity>()).isEmpty
            && context.fetch(FetchDescriptor<LessonQuizAttemptEntity>()).isEmpty
            && context.fetch(FetchDescriptor<MorseCourseProgressEntity>()).isEmpty
    }

    private func restore(_ snapshot: ProgressStoreSnapshot) throws {
        try context.delete(model: QuestionProgressEntity.self)
        try context.delete(model: ExamAttemptEntity.self)
        try context.delete(model: LessonProgressEntity.self)
        try context.delete(model: LessonQuizAttemptEntity.self)
        if let entity = try existingPreferencesEntity() { context.delete(entity) }
        let entity = PreferencesEntity(
            practiceMode: snapshot.preferences.practiceMode.rawValue,
            examTimerEnabled: snapshot.preferences.examTimerEnabled,
            language: snapshot.preferences.language.rawValue,
            theme: snapshot.preferences.theme.rawValue
        )
        entity.archivedLessonProgressData = snapshot.archivedLessonProgressData
        entity.archivedLessonQuizAttemptsData = snapshot.archivedLessonQuizAttemptsData
        context.insert(entity)
        try removeMorseCourseProgressIfPresent()
        for row in snapshot.syncDeviceRows.questionProgress {
            try upsertQuestionProgress(row.record, deviceId: row.deviceId)
        }
        for row in snapshot.syncDeviceRows.examAttempts {
            try saveExamAttemptWithoutSave(row.attempt, deviceId: row.deviceId)
        }
        for row in snapshot.syncDeviceRows.lessonProgress {
            try upsertLessonProgress(row.record, deviceId: row.deviceId)
        }
        for row in snapshot.syncDeviceRows.lessonQuizAttempts {
            try upsertLessonQuizAttempt(row.attempt, deviceId: row.deviceId)
        }
        for row in snapshot.syncDeviceRows.morseCourseProgress {
            try upsertMorseCourseProgress(row.progress, deviceId: row.deviceId)
        }
        try context.save()
        defaults.set(snapshot.preferences.activeBankId.rawValue, forKey: Self.activeBankPreferenceKey)
        preferences = snapshot.preferences
    }

    private func deviceQuestionProgressRows() throws -> [DeviceQuestionProgressRecord] {
        let descriptor = FetchDescriptor<QuestionProgressEntity>(sortBy: [SortDescriptor(\.bankId), SortDescriptor(\.questionId), SortDescriptor(\.deviceId), SortDescriptor(\.lastAttemptedAt)])
        return try context.fetch(descriptor).map { entity in
            DeviceQuestionProgressRecord(deviceId: entity.deviceId.isEmpty ? localDeviceID : entity.deviceId, record: try questionProgressRecord(from: entity))
        }
    }

    private func deviceExamAttemptRows() throws -> [DeviceExamAttemptRecord] {
        let descriptor = FetchDescriptor<ExamAttemptEntity>(sortBy: [SortDescriptor(\.bankId), SortDescriptor(\.submittedAt), SortDescriptor(\.deviceId), SortDescriptor(\.id)])
        return try context.fetch(descriptor).map { entity in
            DeviceExamAttemptRecord(deviceId: entity.deviceId.isEmpty ? localDeviceID : entity.deviceId, attempt: try decoder.decode(StoredExamAttempt.self, from: entity.payloadData))
        }
    }

    private func deviceLessonProgressRows() throws -> [DeviceLessonProgressRecord] {
        let descriptor = FetchDescriptor<LessonProgressEntity>(sortBy: [SortDescriptor(\.lessonId), SortDescriptor(\.deviceId), SortDescriptor(\.readAt)])
        return try context.fetch(descriptor).map { entity in
            DeviceLessonProgressRecord(
                deviceId: entity.deviceId.isEmpty ? localDeviceID : entity.deviceId,
                record: LessonProgressRecord(lessonId: entity.lessonId, readAt: entity.readAt, readCount: entity.readCount),
                lessonIdVersion: LessonIDContentVersion.current
            )
        }
    }

    private func deviceLessonQuizAttemptRows() throws -> [DeviceLessonQuizAttemptRecord] {
        let descriptor = FetchDescriptor<LessonQuizAttemptEntity>(sortBy: [SortDescriptor(\.submittedAt), SortDescriptor(\.deviceId), SortDescriptor(\.id)])
        return try context.fetch(descriptor).map { entity in
            DeviceLessonQuizAttemptRecord(
                deviceId: entity.deviceId.isEmpty ? localDeviceID : entity.deviceId,
                attempt: try decoder.decode(LessonQuizAttempt.self, from: entity.payloadData),
                lessonIdVersion: LessonIDContentVersion.current
            )
        }
    }

    private func syncDeviceRowsSnapshot() throws -> ProgressSyncDeviceRows {
        let morseKey = MorseCourseProgressEntity.defaultKey
        let morseDescriptor = FetchDescriptor<MorseCourseProgressEntity>(predicate: #Predicate { $0.key == morseKey })
        let morseRows = try context.fetch(morseDescriptor).map { entity in
            DeviceMorseCourseProgressRecord(deviceId: entity.deviceId.isEmpty ? localDeviceID : entity.deviceId, progress: try decoder.decode(MorseCourseProgressExport.self, from: entity.payloadData))
        }
        return ProgressSyncDeviceRows(
            questionProgress: try deviceQuestionProgressRows(),
            examAttempts: try deviceExamAttemptRows(),
            lessonProgress: try deviceLessonProgressRows(),
            lessonQuizAttempts: try deviceLessonQuizAttemptRows(),
            morseCourseProgress: morseRows
        )
    }

    private func syncDeviceRowsSnapshot(
        bank: QuestionBank,
        questionProgress: [QuestionProgressRecord],
        examAttempts: [StoredExamAttempt],
        lessonProgress: [LessonProgressRecord],
        lessonQuizAttempts: [LessonQuizAttempt],
        includesMorse: Bool
    ) throws -> ProgressSyncDeviceRows {
        let snapshot = try syncDeviceRowsSnapshot()
        let questionIds = Set(questionProgress.map(\.questionId))
        let examSubmittedAt = Set(examAttempts.map { "\($0.bankId)\u{0}\($0.submittedAt)" })
        let lessonIds = Set(lessonProgress.map(\.lessonId))
        let lessonQuizIds = Set(lessonQuizAttempts.map(\.id))
        return ProgressSyncDeviceRows(
            questionProgress: snapshot.questionProgress.filter { $0.record.bankId == bank.manifest.bankId && questionIds.contains($0.record.questionId) },
            examAttempts: snapshot.examAttempts.filter { $0.attempt.bankId == bank.manifest.bankId && examSubmittedAt.contains("\($0.attempt.bankId)\u{0}\($0.attempt.submittedAt)") },
            lessonProgress: bank.courseBankID.hasLessons ? snapshot.lessonProgress.filter { lessonIds.contains($0.record.lessonId) } : [],
            lessonQuizAttempts: bank.courseBankID.hasLessons ? snapshot.lessonQuizAttempts.filter { lessonQuizIds.contains($0.attempt.id) } : [],
            morseCourseProgress: includesMorse ? snapshot.morseCourseProgress : []
        )
    }

    private func questionProgressRecord(from entity: QuestionProgressEntity) throws -> QuestionProgressRecord {
        let recentResults = try decoder.decode([Bool].self, from: entity.recentResultsData)
        let decodedRecentAnsweredWithHelp = (try? decoder.decode([Bool].self, from: entity.recentAnsweredWithHelpData)) ?? []
        let recentAnsweredWithHelp = decodedRecentAnsweredWithHelp.count == recentResults.count ? decodedRecentAnsweredWithHelp : Array(repeating: false, count: recentResults.count)
        return QuestionProgressRecord(
            questionId: entity.questionId,
            bankId: entity.bankId,
            attempts: entity.attempts,
            correctAttempts: entity.correctAttempts,
            lastAttemptedAt: entity.lastAttemptedAt,
            lastResult: AnswerResult(rawValue: entity.lastResult) ?? .incorrect,
            lastAnsweredWithHelp: entity.lastAnsweredWithHelp,
            recentResults: recentResults,
            recentAnsweredWithHelp: recentAnsweredWithHelp,
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
    var activityDates = Set<String>()
    for (index, record) in progress.dailyActivity.enumerated() {
        let prefix = "Import morseCourseProgress.dailyActivity[\(index)]"
        if record.date.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) == nil { errors.append(String(localized: "\(prefix).date must be YYYY-MM-DD.")) }
        if !activityDates.insert(record.date).inserted { errors.append(String(localized: "\(prefix).date duplicates another daily activity record.")) }
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

// Version-1 membership before TASK-46.10, from content/quizzes at 350a3b53658c64f12e89c0b48d6b97c7c3040e88.
private let legacyLessonQuizMembership: [String: (officialQuestionIds: Set<String>, conceptCheckIds: Set<String>)] = [
    "QZ-L-005-04-A": (["B-005-007-001", "B-005-007-005", "B-005-007-009", "B-005-008-003", "B-005-008-004", "B-005-008-005", "B-005-008-009", "B-005-008-011", "B-005-009-003", "B-005-009-011", "B-005-010-001", "B-005-010-009"], ["QZ-L-005-04-A-C1", "QZ-L-005-04-A-C2", "QZ-L-005-04-A-C3"]),
    "QZ-L-005-05-A": (["B-005-011-001", "B-005-011-002", "B-005-011-004", "B-005-011-008", "B-005-012-001", "B-005-012-006", "B-005-012-008", "B-005-012-011", "B-005-013-001", "B-005-013-005", "B-005-013-006", "B-005-013-007", "B-005-013-010"], ["QZ-L-005-05-A-C1", "QZ-L-005-05-A-C2", "QZ-L-005-05-A-C3"]),
    "QZ-L-008-01-A": (["B-008-001-001", "B-008-001-004", "B-008-001-006", "B-008-001-011", "B-008-002-001", "B-008-002-005", "B-008-002-011", "B-008-003-005"], ["QZ-L-008-01-A-C1", "QZ-L-008-01-A-C2", "QZ-L-008-01-A-C3"]),
    "QZ-L-008-02-A": (["B-008-004-002", "B-008-004-005", "B-008-004-006", "B-008-004-008", "B-008-004-010", "B-008-005-002", "B-008-005-007", "B-008-005-009"], ["QZ-L-008-02-A-C1", "QZ-L-008-02-A-C2", "QZ-L-008-02-A-C3"]),
    "QZ-L-001-03-A": (["B-001-010-001", "B-001-010-002", "B-001-010-003", "B-001-010-004", "B-001-010-005", "B-001-010-006", "B-001-010-007", "B-001-010-008", "B-001-010-009", "B-001-010-010", "B-001-011-001", "B-001-011-002", "B-001-011-003", "B-001-011-004", "B-001-011-005", "B-001-011-006", "B-001-011-007", "B-001-011-008", "B-001-011-009", "B-001-011-010", "B-001-012-001", "B-001-012-002", "B-001-012-003", "B-001-012-004", "B-001-013-001", "B-001-013-002", "B-001-013-003", "B-001-013-004", "B-001-013-005", "B-001-013-006", "B-001-013-007", "B-001-013-008", "B-001-013-009", "B-001-013-010", "B-001-013-011", "B-001-014-001", "B-001-014-002", "B-001-014-003", "B-001-014-004", "B-001-014-005", "B-001-014-006", "B-001-014-007", "B-001-014-008", "B-001-014-009", "B-001-014-010", "B-001-014-011"], []),
]

private func validateLessonQuizAttempts(
    _ attempts: [ArchivedJSON],
    knownQuestionIds: Set<String>,
    knownLessonIds: Set<String>,
    lessonQuizzesById: [String: BankLessonQuiz],
    lessonIdVersion: Int? = LessonIDContentVersion.current,
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

        let legacyMembership = (lessonIdVersion ?? LessonIDContentVersion.legacy) == LessonIDContentVersion.legacy
            ? attempt.storage["quizId"]?.stringValue.flatMap { legacyLessonQuizMembership[$0] }
            : nil

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
            let belongsToQuiz = officialQuestionIds.allSatisfy { questionId in
                if let legacyMembership {
                    return legacyMembership.officialQuestionIds.contains(questionId)
                }
                return quizQuestionIds.contains(questionId)
            }
            if !officialQuestionIds.allSatisfy(knownQuestionIds.contains) {
                errors.append(String(localized: "\(prefix).officialQuestionIds must contain known question IDs."))
            } else if quiz != nil && !belongsToQuiz {
                errors.append(String(localized: "\(prefix).officialQuestionIds must belong to the lesson quiz."))
            }

            if let incorrectOfficialQuestionIds = stringArray(attempt.storage["incorrectOfficialQuestionIds"]) {
                if !incorrectOfficialQuestionIds.allSatisfy(knownQuestionIds.contains) {
                    errors.append(String(localized: "\(prefix).incorrectOfficialQuestionIds must contain known question IDs."))
                } else {
                    let officialSet = Set(officialQuestionIds + (stringArray(attempt.storage["reviewQuestionIds"]) ?? []))
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

        if let value = attempt.storage["reviewQuestionIds"] {
            let valid = stringArray(value).map { reviewIds in
                LessonQuizAttempt.validReviewQuestionIds(reviewIds, officialQuestionIds: stringArray(attempt.storage["officialQuestionIds"]) ?? [])
                    && reviewIds.allSatisfy(knownQuestionIds.contains)
                    && (reviewIds.isEmpty || lessonIdVersion == LessonIDContentVersion.current)
            } ?? false
            if !valid {
                errors.append(String(localized: "\(prefix).reviewQuestionIds must be sorted unique official IDs outside the core quiz and require lessonIdVersion 2."))
            }
        }

        if let value = attempt.storage["answeredWithHelpIds"] {
            let official = (stringArray(attempt.storage["officialQuestionIds"]) ?? []) + (stringArray(attempt.storage["reviewQuestionIds"]) ?? [])
            let valid = stringArray(value).map { ids in
                LessonQuizAttempt.validAnsweredWithHelpIds(ids, officialQuestionIds: official) && ids.allSatisfy(knownQuestionIds.contains)
            } ?? false
            if !valid {
                errors.append(String(localized: "\(prefix).answeredWithHelpIds must be sorted unique official question IDs from this attempt."))
            }
        }

        if let incorrectConceptCheckIds = stringArray(attempt.storage["incorrectConceptCheckIds"]) {
            let conceptCheckIds = legacyMembership?.conceptCheckIds ?? quiz?.conceptCheckIds ?? []
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
