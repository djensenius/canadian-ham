import SwiftUI
import UniformTypeIdentifiers

#if os(macOS)
struct NativeSettingsView: View {
    @ObservedObject var appSettings: AppSettingsModel

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
    }
}

private struct NativeGeneralSettingsTab: View {
    @ObservedObject var appSettings: AppSettingsModel
    @State private var statusMessage = ""
    @State private var errorMessage = ""

    var body: some View {
        Form {
            if let progressStore = appSettings.progressStore {
                Picker("Question language", selection: Binding(
                    get: { progressStore.preferences.language },
                    set: { language in save(progressStore) { $0.language = language } }
                )) {
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

                Picker("Appearance", selection: Binding(
                    get: { progressStore.preferences.theme },
                    set: { theme in save(progressStore) { $0.theme = theme } }
                )) {
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
    }

    private func save(_ progressStore: ProgressStoreService, mutate: (inout ApplePreferences) -> Void) {
        var next = progressStore.preferences
        mutate(&next)
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
            appSettings.recordDataChanged()
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
            appSettings.recordDataChanged()
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

private extension ApplePreferences.Theme {
    var nativeLocalizedLabel: LocalizedStringResource {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

private func localizedNative(_ string: String, language: BankLanguage) -> AttributedString {
    var attributed = AttributedString(string)
    attributed.languageIdentifier = language.accessibilityLanguageCode
    return attributed
}
#endif
