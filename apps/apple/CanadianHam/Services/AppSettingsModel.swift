import Combine
import Foundation

@MainActor
final class AppSettingsModel: ObservableObject {
    @Published var bank: QuestionBank?
    @Published var progressStore: ProgressStoreService? {
        didSet { bindProgressStore() }
    }
    @Published var morseSettings: MorseTrainerSettings
    @Published private(set) var dataRevision = 0
    @Published private(set) var localDataReplacementRevision = 0

    private var unfinishedCourseWorkChecks: [UUID: @MainActor () -> Bool] = [:]
    private var progressStoreCancellable: AnyCancellable?

    init(morseSettings: MorseTrainerSettings = .load()) {
        self.morseSettings = morseSettings
    }

    func recordDataChanged(replacesLocalData: Bool = false) {
        dataRevision += 1
        if replacesLocalData {
            localDataReplacementRevision += 1
        }
    }

    func registerUnfinishedCourseWorkCheck(id: UUID, _ check: @escaping @MainActor () -> Bool) {
        unfinishedCourseWorkChecks[id] = check
    }

    func unregisterUnfinishedCourseWorkCheck(id: UUID) {
        unfinishedCourseWorkChecks.removeValue(forKey: id)
    }

    var hasAnyUnfinishedCourseWork: Bool {
        unfinishedCourseWorkChecks.values.contains { $0() }
    }

    private func bindProgressStore() {
        progressStoreCancellable = progressStore?.objectWillChange.sink { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.dataRevision += 1
            }
        }
        dataRevision += 1
    }
}
