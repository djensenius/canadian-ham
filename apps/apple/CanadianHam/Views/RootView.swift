import CanadianHamContent
import SwiftUI

private enum SidebarSelection: Hashable {
    case home
    case learn
    case practiceHub
    case practice(PracticeScope)
    case mockExam
    case morse
    case settings
    case about
}

#if os(iOS)
private enum CompactTab: Hashable {
    case home
    case learn
    case practice
    case morse
    case settings
}

private enum CompactPracticeRoute: Hashable {
    case practice(PracticeScope)
    case mockExam
}

private enum CompactSettingsRoute: Hashable {
    case about
}
#endif

struct RootView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var appSettings: AppSettingsModel
#if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
#endif

    @State private var bank: QuestionBank?
    @State private var bankLoadError: String?
    @State private var contentLibrary: ContentLibrary?
    @State private var contentLoadError: String?
    @State private var progressStore: ProgressStoreService?
    @State private var progressStoreError: String?
    @State private var selection: SidebarSelection = .home
    @State private var language: BankLanguage = .english
    @State private var morseSettings = MorseTrainerSettings.load()
    @State private var dataRevision = 0
    @State private var navigationPath: [LearnRoute] = []
#if os(iOS)
    @State private var compactSelection: CompactTab = .home
    @State private var compactLearnNavigationPath: [LearnRoute] = []
    @State private var compactPracticeNavigationPath: [CompactPracticeRoute] = []
    @State private var compactSettingsNavigationPath: [CompactSettingsRoute] = []
#endif
    @State private var didApplyLaunchNavigation = false

    init(appSettings: AppSettingsModel) {
        _appSettings = StateObject(wrappedValue: appSettings)
    }

    var body: some View {
        Group {
            if let bank, let contentLibrary, let progressStore {
                appContent(bank: bank, contentLibrary: contentLibrary, progressStore: progressStore)
                    .environment(\.canadianHamContentLibrary, contentLibrary)
                    .preferredColorScheme(colorScheme(for: progressStore.preferences.theme))
            } else if let progressStoreError {
                StoreRecoveryView(message: progressStoreError) {
                    ProgressStoreService.resetPersistentStoreFiles()
                    reloadStore()
                }
            } else if let bankLoadError {
                ContentUnavailableView {
                    Label("Question bank unavailable", systemImage: "exclamationmark.triangle")
                } description: {
                    LocalizedErrorMessageText(message: bankLoadError)
                }
                .foregroundStyle(DesignTokens.Colors.ink)
                .background(DesignTokens.Colors.paper)
            } else if let contentLoadError {
                ContentUnavailableView {
                    Label("Lesson content unavailable", systemImage: "exclamationmark.triangle")
                } description: {
                    LocalizedErrorMessageText(message: contentLoadError)
                }
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
            loadContentIfNeeded()
            reloadStoreIfNeeded()
        }
        .onReceive(appSettings.$morseSettings) { next in
            guard next != morseSettings else { return }
            morseSettings = next
        }
        .onChange(of: morseSettings) { _, next in
            guard appSettings.morseSettings != next else { return }
            appSettings.morseSettings = next
        }
    }

    @ViewBuilder
    private func appContent(bank: QuestionBank, contentLibrary: ContentLibrary, progressStore: ProgressStoreService) -> some View {
#if os(iOS)
        if effectiveHorizontalSizeClass == .compact {
            compactTabContent(bank: bank, contentLibrary: contentLibrary, progressStore: progressStore)
        } else {
            splitContent(bank: bank, contentLibrary: contentLibrary, progressStore: progressStore)
        }
#else
        splitContent(bank: bank, contentLibrary: contentLibrary, progressStore: progressStore)
#endif
    }

#if os(iOS)
    @ViewBuilder
    private func compactTabContent(bank: QuestionBank, contentLibrary: ContentLibrary, progressStore: ProgressStoreService) -> some View {
        TabView(selection: $compactSelection) {
            NavigationStack {
                compactTabUnderlay {
                    compactHomeView(bank: bank, progressStore: progressStore)
                        .background(DesignTokens.Colors.paper)
                }
                .toolbar { languageToolbarItem(progressStore: progressStore) }
            }
            .compactTabBarChrome(background: compactTabBarBackground)
            .tabItem { Label("Home", systemImage: "house") }
            .tag(CompactTab.home)

            NavigationStack(path: $compactLearnNavigationPath) {
                compactTabUnderlay {
                    compactLearnView(bank: bank, contentLibrary: contentLibrary, progressStore: progressStore)
                        .background(DesignTokens.Colors.paper)
                }
                .toolbar { languageToolbarItem(progressStore: progressStore) }
                .navigationDestination(for: LearnRoute.self) { route in
                    learnDestination(route, bank: bank, contentLibrary: contentLibrary, progressStore: progressStore)
                }
            }
            .compactTabBarChrome(background: compactTabBarBackground)
            .tabItem { Label("Learn", systemImage: "book.closed") }
            .tag(CompactTab.learn)

            NavigationStack(path: $compactPracticeNavigationPath) {
                compactTabUnderlay {
                    compactPracticeView(bank: bank, progressStore: progressStore)
                        .background(DesignTokens.Colors.paper)
                }
                .toolbar { languageToolbarItem(progressStore: progressStore) }
                .navigationDestination(for: CompactPracticeRoute.self) { route in
                    compactPracticeDestination(route, bank: bank, progressStore: progressStore)
                }
            }
            .compactTabBarChrome(background: compactTabBarBackground)
            .tabItem { Label("Practice", systemImage: "checklist") }
            .tag(CompactTab.practice)

            NavigationStack {
                compactTabUnderlay {
                    MorseTrainerView(settings: $morseSettings) { nextSettings in
                        morseSettings = nextSettings
                    }
                    .background(DesignTokens.Colors.paper)
                }
                .toolbar { languageToolbarItem(progressStore: progressStore) }
            }
            .compactTabBarChrome(background: compactTabBarBackground)
            .tabItem {
                Label("Morse", systemImage: "waveform")
                    .accessibilityIdentifier("compact-top-level-morse-tab")
            }
            .tag(CompactTab.morse)

            NavigationStack(path: $compactSettingsNavigationPath) {
                compactTabUnderlay {
                    compactSettingsView(bank: bank, progressStore: progressStore)
                        .background(DesignTokens.Colors.paper)
                }
                .toolbar { languageToolbarItem(progressStore: progressStore) }
                .navigationDestination(for: CompactSettingsRoute.self) { route in
                    compactSettingsDestination(route, bank: bank)
                }
            }
            .compactTabBarChrome(background: compactTabBarBackground)
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(CompactTab.settings)
        }
        .tint(DesignTokens.Colors.ink)
        .onAppear {
            language = progressStore.preferences.language
            applyLaunchNavigation(bank: bank, contentLibrary: contentLibrary)
        }
        .onChange(of: progressStore.preferences.language) { _, next in
            language = next
        }
    }

    @ViewBuilder
    private func compactTabUnderlay<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack(alignment: .bottom) {
            content()
            compactTabBarBackground
                .frame(height: 96)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func compactHomeView(bank: QuestionBank, progressStore: ProgressStoreService) -> some View {
        HomeView(bank: bank, progressStore: progressStore, language: language, revision: combinedDataRevision, morseEnabled: true) { scope in
            openCompactPractice(scope)
        } openMockExam: {
            openCompactMockExam()
        } openMorse: {
            selection = .morse
            compactSelection = .morse
        }
    }

    @ViewBuilder
    private func compactLearnView(bank: QuestionBank, contentLibrary: ContentLibrary, progressStore: ProgressStoreService) -> some View {
        LearnView(
            library: contentLibrary,
            bank: bank,
            progressStore: progressStore,
            language: language,
            revision: combinedDataRevision
        ) {
            recordDataChanged()
        }
    }

    @ViewBuilder
    private func compactPracticeView(bank: QuestionBank, progressStore: ProgressStoreService) -> some View {
        PracticeHubView(bank: bank, progressStore: progressStore, language: language, revision: combinedDataRevision) { scope in
            compactPracticeNavigationPath.append(.practice(scope))
            selection = .practice(scope)
        }
    }

    @ViewBuilder
    private func compactPracticeDestination(_ route: CompactPracticeRoute, bank: QuestionBank, progressStore: ProgressStoreService) -> some View {
        switch route {
        case .practice(let scope):
            PracticeSessionView(
                bank: bank,
                progressStore: progressStore,
                scope: scope,
                language: $language
            ) {
                recordDataChanged()
            }
        case .mockExam:
            MockExamView(bank: bank, progressStore: progressStore, language: language) {
                recordDataChanged()
            }
        }
    }

    @ViewBuilder
    private func compactSettingsView(bank: QuestionBank, progressStore: ProgressStoreService) -> some View {
        SettingsView(
            bank: bank,
            progressStore: progressStore,
            morseSettings: $morseSettings,
            openMorse: {
                selection = .morse
                compactSelection = .morse
            },
            openAbout: {
                compactSettingsNavigationPath.append(.about)
                selection = .about
            }
        ) {
            recordDataChanged()
        }
    }

    @ViewBuilder
    private func compactSettingsDestination(_ route: CompactSettingsRoute, bank: QuestionBank) -> some View {
        switch route {
        case .about:
            AboutView(bank: bank)
        }
    }

    private func openCompactPractice(_ scope: PracticeScope) {
        selection = .practice(scope)
        compactSelection = .practice
        compactPracticeNavigationPath = [.practice(scope)]
    }

    private func openCompactMockExam() {
        selection = .mockExam
        compactSelection = .practice
        compactPracticeNavigationPath = [.mockExam]
    }

    private var compactTabBarBackground: Color {
        colorScheme == .dark ? DesignTokens.Colors.paperInset : DesignTokens.Colors.ink
    }
#endif

    @ViewBuilder
    private func splitContent(bank: QuestionBank, contentLibrary: ContentLibrary, progressStore: ProgressStoreService) -> some View {
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
                        .accessibilityLabel(Text(categoryAccessibilityLabel(category))) // l10n: content(question)
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
                    SidebarButton(selection: .morse, current: selection) {
                        Label("Morse", systemImage: "waveform")
                    } action: { selection = .morse }
#if !os(macOS)
                    SidebarButton(selection: .settings, current: selection) {
                        Label("Settings", systemImage: "gearshape")
                    } action: { selection = .settings }
#endif
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
            NavigationStack(path: $navigationPath) {
                detailView(bank: bank, contentLibrary: contentLibrary, progressStore: progressStore)
                    .background(DesignTokens.Colors.paper)
                    .navigationDestination(for: LearnRoute.self) { route in
                        learnDestination(route, bank: bank, contentLibrary: contentLibrary, progressStore: progressStore)
                    }
            }
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
            applyLaunchNavigation(bank: bank, contentLibrary: contentLibrary)
        }
        .onChange(of: progressStore.preferences.language) { _, next in
            language = next
        }
        .onChange(of: selection) { _, next in
            if next != .learn {
                navigationPath.removeAll()
            }
        }
    }

    private var combinedDataRevision: Int {
        dataRevision + appSettings.dataRevision
    }

    private func recordDataChanged() {
        dataRevision += 1
        appSettings.recordDataChanged()
    }

    @ViewBuilder
    private func learnDestination(_ route: LearnRoute, bank: QuestionBank, contentLibrary: ContentLibrary, progressStore: ProgressStoreService) -> some View {
        LearnRouteDestinationView(
            route: route,
            library: contentLibrary,
            bank: bank,
            progressStore: progressStore,
            language: language
        ) {
            recordDataChanged()
        }
    }

    @ViewBuilder
    private func detailView(bank: QuestionBank, contentLibrary: ContentLibrary, progressStore: ProgressStoreService) -> some View {
        switch selection {
        case .home:
            HomeView(bank: bank, progressStore: progressStore, language: language, revision: combinedDataRevision, morseEnabled: true) { scope in
                selection = .practice(scope)
            } openMockExam: {
                selection = .mockExam
            } openMorse: {
                selection = .morse
            }
        case .learn:
            LearnView(
                library: contentLibrary,
                bank: bank,
                progressStore: progressStore,
                language: language,
                revision: combinedDataRevision
            ) {
                recordDataChanged()
            }
        case .practiceHub:
            PracticeHubView(bank: bank, progressStore: progressStore, language: language, revision: combinedDataRevision) { scope in
                selection = .practice(scope)
            }
        case .practice(let scope):
            PracticeSessionView(
                bank: bank,
                progressStore: progressStore,
                scope: scope,
                language: $language
            ) {
                recordDataChanged()
            }
        case .mockExam:
            MockExamView(bank: bank, progressStore: progressStore, language: language) {
                recordDataChanged()
            }
        case .morse:
            MorseTrainerView(settings: $morseSettings) { nextSettings in
                morseSettings = nextSettings
            }
        case .settings:
            SettingsView(bank: bank, progressStore: progressStore, morseSettings: $morseSettings, openMorse: { selection = .morse }, openAbout: { selection = .about }) {
                recordDataChanged()
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
            let loaded = try QuestionBankStore.load()
            if let contentLibrary {
                bank = loaded.withKnownLessonIds(Set(contentLibrary.lessons.map(\.id)))
            } else {
                bank = loaded
            }
            appSettings.bank = bank
        } catch {
            bankLoadError = localizedErrorMessage(String(localized: "Unable to load question bank: \("")"), detail: error)
        }
    }

    private func loadContentIfNeeded() {
        guard contentLibrary == nil, contentLoadError == nil else { return }
        do {
            let loaded = try ContentLibrary.load(from: .main)
            contentLibrary = loaded
            if let bank {
                self.bank = bank.withKnownLessonIds(Set(loaded.lessons.map(\.id)))
                appSettings.bank = self.bank
            }
        } catch {
            contentLoadError = localizedErrorMessage(String(localized: "Unable to load lesson content: \("")"), detail: error)
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
                throw ProgressStoreError.openFailed(forcedStoreOpenFailureForUITesting())
            }
            if ProcessInfo.processInfo.arguments.contains("-CanadianHamResetDataOnLaunch") {
                ProgressStoreService.resetPersistentStoreFiles()
                MorseTrainerSettings.reset()
                morseSettings = .default
            }
#endif
            if let sharedStore = appSettings.progressStore {
                progressStore = sharedStore
            } else {
                progressStore = try ProgressStoreService.open()
                appSettings.progressStore = progressStore
            }
#if DEBUG
            applyPreferenceLaunchArguments()
#endif
            progressStoreError = nil
            language = progressStore?.preferences.language ?? .english
        } catch {
            progressStore = nil
            appSettings.progressStore = nil
            progressStoreError = localizedErrorMessage(String(localized: "Unable to open the local progress store: \("")"), detail: error)
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

    private func applyLaunchNavigation(bank: QuestionBank, contentLibrary: ContentLibrary) {
        guard !didApplyLaunchNavigation else { return }
        didApplyLaunchNavigation = true
#if DEBUG
        if let initialQuizID = AppLaunchArguments.value(after: "-CanadianHamInitialLessonQuizID"),
           let quiz = contentLibrary.quizzesById[initialQuizID] {
            selection = .learn
            navigationPath = [.lesson(quiz.lessonId), .lessonQuiz(initialQuizID)]
#if os(iOS)
            compactSelection = .learn
            compactLearnNavigationPath = [.lesson(quiz.lessonId), .lessonQuiz(initialQuizID)]
#endif
        } else if let initialLessonID = AppLaunchArguments.value(after: "-CanadianHamInitialLessonID") {
            selection = .learn
            navigationPath = [.lesson(initialLessonID)]
#if os(iOS)
            compactSelection = .learn
            compactLearnNavigationPath = [.lesson(initialLessonID)]
#endif
        }
        if let screen = AppLaunchArguments.value(after: "-CanadianHamInitialScreen") {
            switch screen {
            case "home":
                selection = .home
#if os(iOS)
                compactSelection = .home
#endif
            case "learn":
                selection = .learn
#if os(iOS)
                compactSelection = .learn
#endif
            case "practice":
                selection = .practiceHub
#if os(iOS)
                compactSelection = .practice
                compactPracticeNavigationPath = []
#endif
            case "mock":
                selection = .mockExam
#if os(iOS)
                compactSelection = .practice
                compactPracticeNavigationPath = [.mockExam]
#endif
            case "morse":
                selection = .morse
#if os(iOS)
                compactSelection = .morse
#endif
            case "settings":
#if os(macOS)
                selection = .home
#else
                selection = .settings
#endif
#if os(iOS)
                compactSelection = .settings
                compactSettingsNavigationPath = []
#endif
            case "about":
                selection = .about
#if os(iOS)
                compactSelection = .settings
                compactSettingsNavigationPath = [.about]
#endif
            default: break
            }
        }
#endif
        if ProcessInfo.processInfo.arguments.contains("-CanadianHamShowCategoryList") {
            selection = .practiceHub
#if os(iOS)
            compactSelection = .practice
            compactPracticeNavigationPath = []
#endif
        } else if let requestedSubsectionID = AppLaunchArguments.value(after: "-CanadianHamInitialSubsectionID"),
                  bank.subsectionsById[requestedSubsectionID] != nil {
            selection = .practice(.subsection(requestedSubsectionID))
#if os(iOS)
            compactSelection = .practice
            compactPracticeNavigationPath = [.practice(.subsection(requestedSubsectionID))]
#endif
        } else if let requestedCategoryID = AppLaunchArguments.value(after: "-CanadianHamInitialCategoryID"),
                  bank.categories.contains(where: { $0.id == requestedCategoryID }) {
            selection = .practice(.category(requestedCategoryID))
#if os(iOS)
            compactSelection = .practice
            compactPracticeNavigationPath = [.practice(.category(requestedCategoryID))]
#endif
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
                    switch language {
                    case .english:
                        Text(localized(language.displayName, language: .english)).tag(language) // l10n: content(en)
                    case .french:
                        Text(localized(language.displayName, language: .french)).tag(language) // l10n: content(fr)
                    }
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Question language")
            .accessibilityIdentifier("question-language-picker")
        }
    }

    private func categoryAccessibilityLabel(_ category: BankCategory) -> AttributedString {
        var label = localized(category.name.text(for: language), language: language)
        label += AttributedString(", \(localizedQuestionCount(category.questionCount)), \(localizedSubsectionCount(category.subsectionCount))")
        return label
    }

    private func colorScheme(for theme: ApplePreferences.Theme) -> ColorScheme? {
        switch theme {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

#if os(iOS)
private extension View {
    func compactTabBarChrome(background: Color) -> some View {
        toolbarBackground(background, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarColorScheme(.dark, for: .tabBar)
    }
}
#endif

private func localized(_ string: String, language: BankLanguage) -> AttributedString {
    var attributed = AttributedString(string)
    attributed.languageIdentifier = language.accessibilityLanguageCode
    return attributed
}

private func localizedQuestionCount(_ count: Int) -> String {
    String.localizedStringWithFormat(String(localized: "%lld questions"), count)
}

private func localizedSubsectionCount(_ count: Int) -> String {
    String.localizedStringWithFormat(String(localized: "%lld subsections"), count)
}

#if DEBUG
private func forcedStoreOpenFailureForUITesting() -> String {
    "Forced store open failure for UI testing."
}

#endif
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
            LocalizedErrorMessageText(message: message)
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Reset remains available so damaged local progress files can be cleared. Bundled questions are not deleted.")
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
            Text(localized(category.name.text(for: language), language: language)) // l10n: content(question)
                .font(DesignTokens.FontScale.body.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.ink)
            Text(verbatim: "\(localizedQuestionCount(category.questionCount)) • \(localizedSubsectionCount(category.subsectionCount))") // l10n: verbatim
                .font(DesignTokens.FontScale.caption)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
    }
}
