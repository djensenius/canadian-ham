import SwiftUI
import UniformTypeIdentifiers

#if os(macOS)
struct NativeSettingsView: View {
    @ObservedObject var appSettings: AppSettingsModel

    var preferredColorScheme: ColorScheme? {
        appSettings.progressStore?.preferences.theme.nativeColorScheme
    }

    var body: some View {
        TabView {
            NativeGeneralSettingsTab(appSettings: appSettings)
                .tabItem { Label("General", systemImage: "gearshape") }
            NativeDataSettingsTab(appSettings: appSettings)
                .tabItem { Label("Data", systemImage: "externaldrive") }
            NativeMorseSettingsTab(appSettings: appSettings)
                .tabItem { Label("Morse", systemImage: "waveform") }
        }
        .frame(width: 560, height: 480)
        .padding(DesignTokens.Spacing.lg)
        .preferredColorScheme(preferredColorScheme)
    }
}

private struct NativeGeneralSettingsTab: View {
    @ObservedObject var appSettings: AppSettingsModel
    @State private var statusMessage = ""
    @State private var errorMessage = ""
    @State private var pendingCourseSwitch: CourseBankID?

    var body: some View {
        Form {
            if let progressStore = appSettings.progressStore {
                let bindings = NativeSettingsPreferenceBindings(
                    progressStore: progressStore,
                    didSave: {
                        appSettings.recordDataChanged()
                        statusMessage = String(localized: "Preferences saved locally.")
                        errorMessage = ""
                    },
                    didFail: { error in
                        errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
                    }
                )

                Picker("Course", selection: Binding(
                    get: { progressStore.preferences.activeBankId },
                    set: { bankId in requestCourseSwitch(to: bankId, progressStore: progressStore) }
                )) {
                    ForEach(CourseBankID.allCases) { bankId in
                        Text(bankId.localizedName).tag(bankId) // l10n: localized
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("native-course-picker")
                .accessibilityLabel(Text("Course")) // l10n: localized

                Picker("Practice mode", selection: bindings.practiceMode) {
                    ForEach(ApplePreferences.PracticeMode.allCases) { mode in
                        Text(mode.nativeLocalizedLabel).tag(mode) // l10n: localized
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("native-practice-mode-picker")
                .accessibilityLabel(Text("Practice mode")) // l10n: localized

                Toggle("Enable optional mock-exam timer", isOn: bindings.examTimerEnabled) // l10n: localized
                    .accessibilityIdentifier("native-mock-exam-timer-toggle")
                    .accessibilityLabel(Text("Enable optional mock-exam timer")) // l10n: localized

                Picker("Question language", selection: bindings.language) {
                    ForEach(BankLanguage.allCases) { language in
                        switch language {
                        case .english:
                            Text(localizedNative(language.displayName, language: .english)).tag(language) // l10n: content(en)
                        case .french:
                            Text(localizedNative(language.displayName, language: .french)).tag(language) // l10n: content(fr)
                        }
                    }
                }
                .accessibilityLabel(Text("Question language")) // l10n: localized

                Picker("Appearance", selection: bindings.theme) {
                    ForEach(ApplePreferences.Theme.allCases) { theme in
                        Text(theme.nativeLocalizedLabel).tag(theme) // l10n: localized
                    }
                }
                .accessibilityLabel(Text("Appearance")) // l10n: localized
                if !statusMessage.isEmpty {
                    Text(statusMessage) // l10n: localized
                        .foregroundStyle(DesignTokens.Colors.correctText)
                }
                if !errorMessage.isEmpty {
                    Text(errorMessage) // l10n: localized
                        .foregroundStyle(DesignTokens.Colors.warningText)
                }
            } else {
                Text("Open a Canadian Ham window to load settings.") // l10n: localized
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
            }
        }
        .formStyle(.grouped)
        .padding()
        .alert("Switch course?", isPresented: Binding(
            get: { pendingCourseSwitch != nil },
            set: { isPresented in if !isPresented { pendingCourseSwitch = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingCourseSwitch = nil }
            Button("Switch course", role: .destructive) { confirmCourseSwitch() }
        } message: {
            Text("Switching courses will discard the unfinished practice or mock exam session. Saved progress remains on this device.")
        }
    }

    private func requestCourseSwitch(to bankId: CourseBankID, progressStore: ProgressStoreService) {
        guard bankId != progressStore.preferences.activeBankId else { return }
        if appSettings.hasUnfinishedCourseWork() {
            pendingCourseSwitch = bankId
        } else {
            saveCourseSwitch(to: bankId, progressStore: progressStore)
        }
    }

    private func confirmCourseSwitch() {
        guard let progressStore = appSettings.progressStore, let pendingCourseSwitch else { return }
        self.pendingCourseSwitch = nil
        saveCourseSwitch(to: pendingCourseSwitch, progressStore: progressStore)
    }

    private func saveCourseSwitch(to bankId: CourseBankID, progressStore: ProgressStoreService) {
        var next = progressStore.preferences
        next.activeBankId = bankId
        do {
            try progressStore.updatePreferences(next)
            appSettings.recordDataChanged()
            statusMessage = String(localized: "Preferences saved locally.")
            errorMessage = ""
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }
}

@MainActor
struct NativeSettingsPreferenceBindings {
    let progressStore: ProgressStoreService
    var didSave: () -> Void = {}
    var didFail: (Error) -> Void = { _ in }

    var activeBankId: Binding<CourseBankID> {
        binding(get: { $0.activeBankId }, set: { $0.activeBankId = $1 })
    }

    var practiceMode: Binding<ApplePreferences.PracticeMode> {
        binding(get: { $0.practiceMode }, set: { $0.practiceMode = $1 })
    }

    var examTimerEnabled: Binding<Bool> {
        binding(get: { $0.examTimerEnabled }, set: { $0.examTimerEnabled = $1 })
    }

    var language: Binding<BankLanguage> {
        binding(get: { $0.language }, set: { $0.language = $1 })
    }

    var theme: Binding<ApplePreferences.Theme> {
        binding(get: { $0.theme }, set: { $0.theme = $1 })
    }

    private func binding<Value>(
        get: @escaping (ApplePreferences) -> Value,
        set: @escaping (inout ApplePreferences, Value) -> Void
    ) -> Binding<Value> {
        Binding(
            get: { get(progressStore.preferences) },
            set: { value in
                var next = progressStore.preferences
                set(&next, value)
                do {
                    try progressStore.updatePreferences(next)
                    didSave()
                } catch {
                    didFail(error)
                }
            }
        )
    }
}

private struct NativeDataSettingsTab: View {
    @ObservedObject var appSettings: AppSettingsModel
    @State private var exportDocument: ProgressExportDocument?
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var pendingImport: ProgressExportV1?
    @State private var confirmingImport = false
    @State private var confirmingReset = false
    @State private var statusMessage = ""
    @State private var errorMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("Progress is stored on this device. Export, import, and reset are user-initiated only.") // l10n: localized
                .font(DesignTokens.FontScale.body)
            HStack {
                Button("Export…") { prepareExport() } // l10n: localized
                    .accessibilityLabel(Text("Export progress JSON")) // l10n: localized
                Button("Import…") { showingImporter = true } // l10n: localized
                    .accessibilityLabel(Text("Import progress JSON")) // l10n: localized
                Button("Reset…", role: .destructive) { confirmingReset = true } // l10n: localized
                    .accessibilityLabel(Text("Reset all data")) // l10n: localized
            }
            .disabled(appSettings.progressStore == nil || appSettings.bank == nil)
            if let bank = appSettings.bank {
                Text("Active bank: \(bank.manifest.bankId), effective \(bank.manifest.effectiveDate).") // l10n: localized
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
            }
            if !statusMessage.isEmpty {
                Text(statusMessage) // l10n: localized
                    .foregroundStyle(DesignTokens.Colors.correctText)
            }
            if !errorMessage.isEmpty {
                Text(errorMessage) // l10n: localized
                    .foregroundStyle(DesignTokens.Colors.warningText)
            }
            Spacer()
        }
        .padding()
        .fileExporter(isPresented: $showingExporter, document: exportDocument, contentType: .json, defaultFilename: "canadian-ham-progress.json") { result in
            switch result {
            case .success: statusMessage = String(localized: "Progress export prepared.")
            case .failure(let error): errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
            }
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
            handleImport(result)
        }
        .alert("Import progress?", isPresented: $confirmingImport) {
            Button("Cancel", role: .cancel) { pendingImport = nil }
            Button("Import", role: .destructive) { confirmImport() }
        } message: {
            Text("Import replaces local progress, mock exams, and preferences with the selected valid JSON file.")
        }
        .alert("Reset all local data?", isPresented: $confirmingReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { resetAllData() }
        } message: {
            Text("Deletes local progress, mock exams, and preferences. Bundled content remains installed.")
        }
    }

    private func prepareExport() {
        guard let progressStore = appSettings.progressStore, let bank = appSettings.bank else {
            errorMessage = String(localized: "Open a Canadian Ham window to load settings.")
            return
        }
        do {
            let text = try progressStore.serializedExport(bank: bank, exportedAt: AppleStudyEngine.canonicalNow())
            exportDocument = ProgressExportDocument(text: text)
            showingExporter = true
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        guard let progressStore = appSettings.progressStore, let bank = appSettings.bank else {
            errorMessage = String(localized: "Open a Canadian Ham window to load settings.")
            return
        }
        do {
            let url = try result.get()
            let didStart = url.startAccessingSecurityScopedResource()
            defer { if didStart { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(ProgressExportV1.self, from: data)
            let errors = progressStore.validate(decoded, bank: bank)
            if errors.isEmpty {
                pendingImport = decoded
                confirmingImport = true
            } else {
                errorMessage = errors.joined(separator: "\n")
            }
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func confirmImport() {
        guard let progressStore = appSettings.progressStore, let bank = appSettings.bank, let pendingImport else {
            errorMessage = String(localized: "Open a Canadian Ham window to load settings.")
            return
        }
        do {
            try progressStore.importData(pendingImport, bank: bank)
            appSettings.recordDataChanged(replacesLocalData: true)
            self.pendingImport = nil
            statusMessage = String(localized: "Progress imported.")
            errorMessage = ""
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func resetAllData() {
        guard let progressStore = appSettings.progressStore else {
            errorMessage = String(localized: "Open a Canadian Ham window to load settings.")
            return
        }
        do {
            try progressStore.resetAllData()
            MorseTrainerSettings.reset()
            appSettings.morseSettings = .default
            appSettings.recordDataChanged(replacesLocalData: true)
            statusMessage = String(localized: "All local progress was reset.")
            errorMessage = ""
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }
}

private struct NativeMorseSettingsTab: View {
    @ObservedObject var appSettings: AppSettingsModel

    var body: some View {
        ScrollView {
            MorseSettingsSection(settings: $appSettings.morseSettings, openMorse: {}) { nextSettings in
                appSettings.morseSettings = nextSettings
            }
            .padding()
        }
    }
}

private extension ApplePreferences.PracticeMode {
    var nativeLocalizedLabel: LocalizedStringResource {
        switch self {
        case .immediate: "Immediate feedback"
        case .reviewLater: "Review later"
        }
    }
}

private extension ApplePreferences.Theme {
    var nativeLocalizedLabel: LocalizedStringResource {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var nativeColorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

private func localizedNative(_ string: String, language: BankLanguage) -> AttributedString {
    var attributed = AttributedString(string)
    attributed.languageIdentifier = language.accessibilityLanguageCode
    return attributed
}
#endif
