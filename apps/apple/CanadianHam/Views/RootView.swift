import SwiftUI

private enum SidebarSelection: Hashable {
    case home
    case learn
    case practiceHub
    case practice(PracticeScope)
    case mockExam
    case settings
    case about
}

struct RootView: View {
#if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
#endif

    @State private var bank: QuestionBank?
    @State private var bankLoadError: String?
    @State private var progressStore: ProgressStoreService?
    @State private var progressStoreError: String?
    @State private var selection: SidebarSelection = .home
    @State private var language: BankLanguage = .english
    @State private var dataRevision = 0

    var body: some View {
        Group {
            if let bank, let progressStore {
                appContent(bank: bank, progressStore: progressStore)
                    .preferredColorScheme(colorScheme(for: progressStore.preferences.theme))
            } else if let progressStoreError {
                StoreRecoveryView(message: progressStoreError) {
                    ProgressStoreService.resetPersistentStoreFiles()
                    reloadStore()
                }
            } else if let bankLoadError {
                ContentUnavailableView(
                    "Question bank unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text(bankLoadError)
                )
                .foregroundStyle(DesignTokens.Colors.ink)
                .background(DesignTokens.Colors.paper)
            } else {
                ProgressView("Loading Canadian Ham…")
                    .controlSize(.large)
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DesignTokens.Colors.paper)
            }
        }
        .task {
            loadBankIfNeeded()
            reloadStoreIfNeeded()
        }
    }

    @ViewBuilder
    private func appContent(bank: QuestionBank, progressStore: ProgressStoreService) -> some View {
#if os(iOS)
        if effectiveHorizontalSizeClass == .compact {
            NavigationStack {
                detailView(bank: bank, progressStore: progressStore)
                    .background(DesignTokens.Colors.paper)
                    .toolbar { languageToolbarItem(progressStore: progressStore) }
            }
            .toolbarBackground(DesignTokens.Colors.paper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                language = progressStore.preferences.language
                applyLaunchNavigation(bank: bank)
            }
            .onChange(of: progressStore.preferences.language) { _, next in
                language = next
            }
        } else {
            splitContent(bank: bank, progressStore: progressStore)
        }
#else
        splitContent(bank: bank, progressStore: progressStore)
#endif
    }

    @ViewBuilder
    private func splitContent(bank: QuestionBank, progressStore: ProgressStoreService) -> some View {
        NavigationSplitView {
            List {
                Section {
                    SidebarButton(selection: .home, current: selection) {
                        Label("Home", systemImage: "house")
                    } action: { selection = .home }
                    SidebarButton(selection: .learn, current: selection) {
                        Label("Learn", systemImage: "book.closed")
                    } action: { selection = .learn }
                } header: {
                    Text("Study")
                        .textCase(nil)
                        .accessibilityAddTraits(.isHeader)
                }

                Section {
                    SidebarButton(selection: .practiceHub, current: selection) {
                        Label("Practice", systemImage: "checklist")
                    } action: { selection = .practiceHub }
                    SidebarButton(selection: .practice(.all), current: selection) {
                        Label("All questions", systemImage: "tray.full")
                    } action: { selection = .practice(.all) }
                    SidebarButton(selection: .practice(.weak), current: selection) {
                        Label("Weak areas", systemImage: "exclamationmark.triangle")
                    } action: { selection = .practice(.weak) }
                    SidebarButton(selection: .practice(.due), current: selection) {
                        Label("Due review", systemImage: "calendar.badge.clock")
                    } action: { selection = .practice(.due) }
                    ForEach(bank.categories) { category in
                        SidebarButton(selection: .practice(.category(category.id)), current: selection) {
                            CategoryRow(category: category, language: language)
                        } action: { selection = .practice(.category(category.id)) }
                        .accessibilityLabel(categoryAccessibilityLabel(category))
                    }
                } header: {
                    Text("Practice categories")
                        .font(DesignTokens.FontScale.title.weight(.bold))
                        .textCase(nil)
                        .accessibilityAddTraits(.isHeader)
                }
                .headerProminence(.increased)

                Section {
                    SidebarButton(selection: .mockExam, current: selection) {
                        Label("Mock exam", systemImage: "doc.text.magnifyingglass")
                    } action: { selection = .mockExam }
                    SidebarButton(selection: .settings, current: selection) {
                        Label("Settings", systemImage: "gearshape")
                    } action: { selection = .settings }
                    SidebarButton(selection: .about, current: selection) {
                        Label("About", systemImage: "info.circle")
                    } action: { selection = .about }
                } header: {
                    Text("Tools")
                        .textCase(nil)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(DesignTokens.Colors.paper)
            .accessibilityIdentifier("root-sidebar")
            .navigationTitle("Canadian Ham")
            .toolbar { languageToolbarItem(progressStore: progressStore) }
        } detail: {
            detailView(bank: bank, progressStore: progressStore)
                .background(DesignTokens.Colors.paper)
        }
        .navigationSplitViewStyle(.balanced)
#if os(iOS)
        .toolbarBackground(DesignTokens.Colors.paper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
#endif
#if os(macOS)
        .frame(minWidth: 980, minHeight: 680)
#endif
        .onAppear {
            language = progressStore.preferences.language
            applyLaunchNavigation(bank: bank)
        }
        .onChange(of: progressStore.preferences.language) { _, next in
            language = next
        }
    }

    @ViewBuilder
    private func detailView(bank: QuestionBank, progressStore: ProgressStoreService) -> some View {
        switch selection {
        case .home:
            HomeView(bank: bank, progressStore: progressStore, language: language, revision: dataRevision) { scope in
                selection = .practice(scope)
            } openMockExam: {
                selection = .mockExam
            }
        case .learn:
            LearnPlaceholderView()
        case .practiceHub:
            PracticeHubView(bank: bank, progressStore: progressStore, language: language, revision: dataRevision) { scope in
                selection = .practice(scope)
            }
        case .practice(let scope):
            PracticeSessionView(
                bank: bank,
                progressStore: progressStore,
                scope: scope,
                language: $language
            ) {
                dataRevision += 1
            }
        case .mockExam:
            MockExamView(bank: bank, progressStore: progressStore, language: language) {
                dataRevision += 1
            }
        case .settings:
            SettingsView(bank: bank, progressStore: progressStore) {
                dataRevision += 1
            }
        case .about:
            AboutView(bank: bank)
        }
    }

#if os(iOS)
    private var effectiveHorizontalSizeClass: UserInterfaceSizeClass? {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-CanadianHamForceRegularHorizontalSizeClass") {
            return .regular
        }
#endif
        return horizontalSizeClass
    }
#endif

    private func loadBankIfNeeded() {
        guard bank == nil, bankLoadError == nil else { return }
        do {
            bank = try QuestionBankStore.load()
        } catch {
            bankLoadError = error.localizedDescription
        }
    }

    private func reloadStoreIfNeeded() {
        guard progressStore == nil, progressStoreError == nil else { return }
        reloadStore()
    }

    private func reloadStore() {
        do {
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-CanadianHamForceStoreOpenError") {
                throw ProgressStoreError.openFailed("Forced store open failure for UI testing.")
            }
            if ProcessInfo.processInfo.arguments.contains("-CanadianHamResetDataOnLaunch") {
                ProgressStoreService.resetPersistentStoreFiles()
            }
#endif
            progressStore = try ProgressStoreService.open()
#if DEBUG
            applyPreferenceLaunchArguments()
#endif
            progressStoreError = nil
            language = progressStore?.preferences.language ?? .english
        } catch {
            progressStore = nil
            progressStoreError = error.localizedDescription
        }
    }

#if DEBUG
    private func applyPreferenceLaunchArguments() {
        guard let progressStore else { return }
        var preferences = progressStore.preferences
        var changed = false
        if let rawMode = AppLaunchArguments.value(after: "-CanadianHamPracticeMode"), let mode = ApplePreferences.PracticeMode(rawValue: rawMode) {
            preferences.practiceMode = mode
            changed = true
        }
        if let rawTimer = AppLaunchArguments.value(after: "-CanadianHamExamTimerEnabled") {
            preferences.examTimerEnabled = rawTimer == "true" || rawTimer == "1"
            changed = true
        }
        if let rawTheme = AppLaunchArguments.value(after: "-CanadianHamTheme"), let theme = ApplePreferences.Theme(rawValue: rawTheme) {
            preferences.theme = theme
            changed = true
        }
        if changed {
            try? progressStore.updatePreferences(preferences)
        }
    }
#endif

    private func applyLaunchNavigation(bank: QuestionBank) {
        if let screen = AppLaunchArguments.value(after: "-CanadianHamInitialScreen") {
            switch screen {
            case "home": selection = .home
            case "learn": selection = .learn
            case "practice": selection = .practiceHub
            case "mock": selection = .mockExam
            case "settings": selection = .settings
            case "about": selection = .about
            default: break
            }
        }
        if ProcessInfo.processInfo.arguments.contains("-CanadianHamShowCategoryList") {
            selection = .practiceHub
        } else if let requestedSubsectionID = AppLaunchArguments.value(after: "-CanadianHamInitialSubsectionID"),
                  bank.subsectionsById[requestedSubsectionID] != nil {
            selection = .practice(.subsection(requestedSubsectionID))
        } else if let requestedCategoryID = AppLaunchArguments.value(after: "-CanadianHamInitialCategoryID"),
                  bank.categories.contains(where: { $0.id == requestedCategoryID }) {
            selection = .practice(.category(requestedCategoryID))
        }
    }

    private func languageToolbarItem(progressStore: ProgressStoreService) -> some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Picker("Question language", selection: Binding(
                get: { language },
                set: { next in
                    language = next
                    var preferences = progressStore.preferences
                    preferences.language = next
                    try? progressStore.updatePreferences(preferences)
                }
            )) {
                ForEach(BankLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Question language")
            .accessibilityIdentifier("question-language-picker")
        }
    }

    private func categoryAccessibilityLabel(_ category: BankCategory) -> String {
        "\(category.name.text(for: language)), \(category.questionCount) questions, \(category.subsectionCount) subsections"
    }

    private func colorScheme(for theme: ApplePreferences.Theme) -> ColorScheme? {
        switch theme {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

private struct StoreRecoveryView: View {
    let message: String
    let reset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Label("Local progress store unavailable", systemImage: "externaldrive.badge.exclamationmark")
                .font(DesignTokens.FontScale.headline.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.warningText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Reset remains available so damaged local SwiftData files can be cleared. Bundled questions are not deleted.")
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Button(role: .destructive) {
                reset()
            } label: {
                Text("Reset local data and retry")
                    .font(DesignTokens.FontScale.body.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .padding(.vertical, DesignTokens.Spacing.md)
                    .frame(minHeight: 56)
                    .background(DesignTokens.Colors.paperElevated, in: Capsule())
                    .overlay(Capsule().strokeBorder(DesignTokens.Colors.ink, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityHint("Deletes local progress and preferences, then attempts to reopen the store")
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(maxWidth: 720, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.Colors.paper)
    }
}

private struct SidebarButton<LabelContent: View>: View {
    let selection: SidebarSelection
    let current: SidebarSelection
    @ViewBuilder let label: () -> LabelContent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            label()
                .font(DesignTokens.FontScale.body.weight(current == selection ? .bold : .regular))
                .foregroundStyle(DesignTokens.Colors.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .listRowBackground(current == selection ? DesignTokens.Colors.paperInset : DesignTokens.Colors.paperElevated)
        .accessibilityAddTraits(current == selection ? .isSelected : [])
    }
}

private struct CategoryRow: View {
    let category: BankCategory
    let language: BankLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(category.name.text(for: language))
                .font(DesignTokens.FontScale.body.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.ink)
            Text("\(category.questionCount) questions • \(category.subsectionCount) subsections")
                .font(DesignTokens.FontScale.caption)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
    }
}
