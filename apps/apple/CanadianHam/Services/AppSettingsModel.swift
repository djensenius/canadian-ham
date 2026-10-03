import Combine
import Foundation

@MainActor
final class AppSettingsModel: ObservableObject {
    @Published var bank: QuestionBank?
    @Published var progressStore: ProgressStoreService?
    @Published var morseSettings: MorseTrainerSettings

    init(morseSettings: MorseTrainerSettings = .load()) {
        self.morseSettings = morseSettings
    }
}
