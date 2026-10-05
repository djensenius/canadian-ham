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

    var hasUnfinishedCourseWork: @MainActor () -> Bool = { false }

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
