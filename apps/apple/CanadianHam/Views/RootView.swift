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
private enum CompactSection: Hashable {
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
    @State private var unfinishedCourseWorkCheckID = UUID()
    @StateObject private var practiceSessionStates = PracticeSessionStateCache()
    @StateObject private var mockExamState = MockExamState()
#if os(iOS)
    @State private var compactNavigationPath = NavigationPath()
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
        .onAppear {
            appSettings.registerUnfinishedCourseWorkCheck(id: unfinishedCourseWorkCheckID) {
                practiceSessionStates.hasUnfinishedCourseWork || mockExamState.hasUnfinishedCourseWork
            }
        }
        .onDisappear {
            appSettings.unregisterUnfinishedCourseWorkCheck(id: unfinishedCourseWorkCheckID)
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
        NavigationStack(path: $compactNavigationPath) {
            compactRootList(progressStore: progressStore)
                .navigationDestination(for: CompactSection.self) { section in
                    compactSectionDestination(section, bank: bank, contentLibrary: contentLibrary, progressStore: progressStore)
                }
                .navigationDestination(for: LearnRoute.self) { route in
                    learnDestination(route, bank: bank, contentLibrary: contentLibrary, progressStore: progressStore)
                }
                .navigationDestination(for: CompactPracticeRoute.self) { route in
                    compactPracticeDestination(route, bank: bank, progressStore: progressStore)
                }
                .navigationDestination(for: CompactSettingsRoute.self) { route in
                    compactSettingsDestination(route, bank: bank)
                }
        }
        .onAppear {
            language = progressStore.preferences.language
            applyLaunchNavigation(bank: bank, contentLibrary: contentLibrary)
        }
        .onChange(of: progressStore.preferences.language) { _, next in
            language = next
        }
        .onChange(of: progressStore.preferences.practiceMode) { _, _ in
            practiceSessionStates.clear()
        }
        .onChange(of: progressStore.preferences.activeBankId) { _, next in
            loadBank(for: next)
            practiceSessionStates.clear()
            mockExamState.resetSession(localDataReplacementRevision: appSettings.localDataReplacementRevision)
        }
        .onChange(of: appSettings.localDataReplacementRevision) { _, next in
            clearCachedSessions(localDataReplacementRevision: next)
        }
    }

    private func compactRootList(progressStore: ProgressStoreService) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                compactRootSection("Study") {
                    compactRootButton("Home", systemImage: "house", destination: .home)
                    compactRootButton("Learn", systemImage: "book.closed", destination: .learn)
                    compactRootButton("Practice", systemImage: "checklist", destination: .practice)
                }

                compactRootSection("Tools") {
                    compactRootButton("Morse", systemImage: "waveform", destination: .morse)
                    compactRootButton("Settings", systemImage: "gearshape", destination: .settings)
                }
            }
            .pagePadding()
        }
        .background(DesignTokens.Colors.paper)
        .navigationTitle("Canadian Ham")
        .accessibilityIdentifier("compact-root-list")
    }

    private func compactRootSection<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(title) // l10n: localized
                .font(DesignTokens.FontScale.caption.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .textCase(nil)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: DesignTokens.Spacing.sm) {
                content()
            }
        }
    }

    private func compactRootButton(_ title: LocalizedStringKey, systemImage: String, destination: CompactSection) -> some View {
        NavigationLink(value: destination) {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: systemImage)
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .frame(width: 28)
                Text(title) // l10n: localized
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(DesignTokens.FontScale.caption.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
            }
            .padding(DesignTokens.Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title)) // l10n: localized
    }

    @ViewBuilder
    private func compactSectionDestination(_ section: CompactSection, bank: QuestionBank, contentLibrary: ContentLibrary, progressStore: ProgressStoreService) -> some View {
        switch section {
        case .home:
            compactLanguageContainer(progressStore: progressStore) {
                compactHomeView(bank: bank, progressStore: progressStore)
                    .background(DesignTokens.Colors.paper)
            }
        case .learn:
            compactLanguageContainer(progressStore: progressStore) {
                compactLearnView(bank: bank, contentLibrary: contentLibrary, progressStore: progressStore)
                    .background(DesignTokens.Colors.paper)
            }
        case .practice:
            compactLanguageContainer(progressStore: progressStore) {
                compactPracticeView(bank: bank, progressStore: progressStore)
                    .background(DesignTokens.Colors.paper)
            }
        case .morse:
            MorseTrainerView(settings: $morseSettings, progressStore: progressStore) { nextSettings in
                morseSettings = nextSettings
            } onProgressChanged: {
                recordDataChanged()
            }
            .background(DesignTokens.Colors.paper)
        case .settings:
            compactSettingsView(bank: bank, progressStore: progressStore)
                .background(DesignTokens.Colors.paper)
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
            compactNavigationPath.append(CompactSection.morse)
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

    private func compactLanguageContainer<Content: View>(progressStore: ProgressStoreService, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            questionLanguagePicker(progressStore: progressStore)
                .padding(DesignTokens.Spacing.sm)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.top, DesignTokens.Spacing.md)
                .padding(.bottom, DesignTokens.Spacing.sm)
            content()
        }
        .background(DesignTokens.Colors.paper)
    }

    @ViewBuilder
    private func compactPracticeView(bank: QuestionBank, progressStore: ProgressStoreService) -> some View {
        PracticeHubView(bank: bank, progressStore: progressStore, language: language, revision: combinedDataRevision) { scope in
            compactNavigationPath.append(CompactPracticeRoute.practice(scope))
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
                language: $language,
                state: practiceSessionStates.state(for: scope),
                dataRevision: combinedDataRevision,
                localDataReplacementRevision: appSettings.localDataReplacementRevision,
                headerAccessory: AnyView(questionLanguagePicker(progressStore: progressStore))
            ) {
                recordDataChanged()
            }
        case .mockExam:
            compactLanguageContainer(progressStore: progressStore) {
                MockExamView(
                    bank: bank,
                    progressStore: progressStore,
                    language: language,
                    state: mockExamState,
                    localDataReplacementRevision: appSettings.localDataReplacementRevision
                ) {
                    recordDataChanged()
                }
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
                compactNavigationPath.append(CompactSection.morse)
            },
            openAbout: {
                compactNavigationPath.append(CompactSettingsRoute.about)
                selection = .about
            },
            hasUnfinishedCourseWork: { appSettings.hasAnyUnfinishedCourseWork },
            localDataReplacementRevision: appSettings.localDataReplacementRevision
        ) { replacesLocalData in
            recordDataChanged(replacesLocalData: replacesLocalData)
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
        compactNavigationPath.append(CompactPracticeRoute.practice(scope))
    }

    private func openCompactMockExam() {
        selection = .mockExam
        compactNavigationPath.append(CompactPracticeRoute.mockExam)
    }

    private func compactPath(to section: CompactSection) -> NavigationPath {
        var path = NavigationPath()
        path.append(section)
        return path
    }

    private func compactPath(to section: CompactSection, appending route: some Hashable) -> NavigationPath {
        var path = compactPath(to: section)
        path.append(route)
        return path
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
        .onChange(of: progressStore.preferences.practiceMode) { _, _ in
            practiceSessionStates.clear()
        }
        .onChange(of: progressStore.preferences.activeBankId) { _, next in
            loadBank(for: next)
            practiceSessionStates.clear()
            mockExamState.resetSession(localDataReplacementRevision: appSettings.localDataReplacementRevision)
        }
        .onChange(of: appSettings.localDataReplacementRevision) { _, next in
            clearCachedSessions(localDataReplacementRevision: next)
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

    private func clearCachedSessions(localDataReplacementRevision: Int) {
        practiceSessionStates.clear()
        mockExamState.resetSession(localDataReplacementRevision: localDataReplacementRevision)
    }

    private func recordDataChanged(replacesLocalData: Bool = false) {
        dataRevision += 1
        appSettings.recordDataChanged(replacesLocalData: replacesLocalData)
        if replacesLocalData {
            practiceSessionStates.clear()
            mockExamState.resetSession(localDataReplacementRevision: appSettings.localDataReplacementRevision)
        }
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
                language: $language,
                state: practiceSessionStates.state(for: scope),
                dataRevision: combinedDataRevision,
                localDataReplacementRevision: appSettings.localDataReplacementRevision
            ) {
                recordDataChanged()
            }
        case .mockExam:
            MockExamView(
                bank: bank,
                progressStore: progressStore,
                language: language,
                state: mockExamState,
                localDataReplacementRevision: appSettings.localDataReplacementRevision
            ) {
                recordDataChanged()
            }
        case .morse:
            MorseTrainerView(settings: $morseSettings, progressStore: progressStore) { nextSettings in
                morseSettings = nextSettings
            } onProgressChanged: {
                recordDataChanged()
            }
        case .settings:
            SettingsView(
                bank: bank,
                progressStore: progressStore,
                morseSettings: $morseSettings,
                openMorse: { selection = .morse },
                openAbout: { selection = .about },
                hasUnfinishedCourseWork: { appSettings.hasAnyUnfinishedCourseWork },
                localDataReplacementRevision: appSettings.localDataReplacementRevision
            ) { replacesLocalData in
                recordDataChanged(replacesLocalData: replacesLocalData)
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
        loadBank(for: progressStore?.preferences.activeBankId ?? .basic)
    }

    private func loadBank(for bankId: CourseBankID) {
        do {
            let loaded = try QuestionBankStore.load(bankId: bankId)
            if let contentLibrary {
                bank = loaded.withKnownLessonIds(Set(contentLibrary.lessons.map(\.id)))
            } else {
                bank = loaded
            }
            appSettings.bank = bank
            bankLoadError = nil
            if !bankId.hasLessons, selection == .learn {
                selection = .home
            }
        } catch {
            bank = nil
            appSettings.bank = nil
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
            applyPracticeProgressFixtureLaunchArguments()
#endif
            progressStoreError = nil
            language = progressStore?.preferences.language ?? .english
            if let progressStore, bank?.manifest.bankId != progressStore.preferences.activeBankId.rawValue {
                loadBank(for: progressStore.preferences.activeBankId)
            }
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
        if let rawBankId = AppLaunchArguments.value(after: "-CanadianHamCourseBankId"), let bankId = CourseBankID(rawValue: rawBankId) {
            preferences.activeBankId = bankId
            changed = true
        }
        if changed {
            try? progressStore.updatePreferences(preferences)
        }
    }

    private func applyPracticeProgressFixtureLaunchArguments() {
        guard AppLaunchArguments.value(after: "-CanadianHamSeedPracticeProgressFixture") == "weak-due",
              let progressStore,
              let firstQuestion = bank?.question(id: "B-001-002-001"),
              let secondQuestion = bank?.question(id: "B-001-002-002")
        else { return }
        do {
            let now = try AppleStudyEngine.canonicalNow()
            let first = try AppleStudyEngine.applyPracticeAnswer(progress: [], question: firstQuestion, selectedSourceIndex: 1, now: now)
            let seeded = try AppleStudyEngine.applyPracticeAnswer(progress: first, question: secondQuestion, selectedSourceIndex: 1, now: now)
            try progressStore.saveQuestionProgress(seeded)
        } catch {
            assertionFailure("Unable to seed weak/due practice fixture: \(error)")
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
            compactNavigationPath = compactPath(to: .learn, appending: LearnRoute.lesson(quiz.lessonId))
            compactNavigationPath.append(LearnRoute.lessonQuiz(initialQuizID))
#endif
        } else if let initialLessonID = AppLaunchArguments.value(after: "-CanadianHamInitialLessonID") {
            selection = .learn
            navigationPath = [.lesson(initialLessonID)]
#if os(iOS)
            compactNavigationPath = compactPath(to: .learn, appending: LearnRoute.lesson(initialLessonID))
#endif
        }
        if let screen = AppLaunchArguments.value(after: "-CanadianHamInitialScreen") {
            switch screen {
            case "home":
                selection = .home
#if os(iOS)
                compactNavigationPath = compactPath(to: .home)
#endif
            case "learn":
                selection = .learn
#if os(iOS)
                compactNavigationPath = compactPath(to: .learn)
#endif
            case "practice":
                selection = .practiceHub
#if os(iOS)
                compactNavigationPath = compactPath(to: .practice)
#endif
            case "mock":
                selection = .mockExam
#if os(iOS)
                compactNavigationPath = compactPath(to: .practice, appending: CompactPracticeRoute.mockExam)
#endif
            case "morse":
                selection = .morse
#if os(iOS)
                compactNavigationPath = compactPath(to: .morse)
#endif
            case "settings":
#if os(macOS)
                selection = .home
#else
                selection = .settings
#endif
#if os(iOS)
                compactNavigationPath = compactPath(to: .settings)
#endif
            case "about":
                selection = .about
#if os(iOS)
                compactNavigationPath = compactPath(to: .settings, appending: CompactSettingsRoute.about)
#endif
            default: break
            }
        }
#endif
        if ProcessInfo.processInfo.arguments.contains("-CanadianHamShowCategoryList") {
            selection = .practiceHub
#if os(iOS)
            compactNavigationPath = compactPath(to: .practice)
#endif
        } else if let requestedSubsectionID = AppLaunchArguments.value(after: "-CanadianHamInitialSubsectionID"),
                  bank.subsectionsById[requestedSubsectionID] != nil {
            selection = .practice(.subsection(requestedSubsectionID))
#if os(iOS)
            compactNavigationPath = compactPath(to: .practice, appending: CompactPracticeRoute.practice(.subsection(requestedSubsectionID)))
#endif
        } else if let requestedCategoryID = AppLaunchArguments.value(after: "-CanadianHamInitialCategoryID"),
                  bank.categories.contains(where: { $0.id == requestedCategoryID }) {
            selection = .practice(.category(requestedCategoryID))
#if os(iOS)
            compactNavigationPath = compactPath(to: .practice, appending: CompactPracticeRoute.practice(.category(requestedCategoryID)))
#endif
        }
    }

    private func languageToolbarItem(progressStore: ProgressStoreService) -> some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            if selection == .morse {
                EmptyView()
            } else {
                questionLanguagePicker(progressStore: progressStore)
            }
        }
    }

    private func questionLanguagePicker(progressStore: ProgressStoreService) -> some View {
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

    private func categoryAccessibilityLabel(_ category: BankCategory) -> AttributedString {
        var label = localized(category.name.text(for: language), language: category.name.resolvedLanguage(for: language))
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
            Text(localized(category.name.text(for: language), language: category.name.resolvedLanguage(for: language))) // l10n: content(question)
                .font(DesignTokens.FontScale.body.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.ink)
            Text(verbatim: "\(localizedQuestionCount(category.questionCount)) • \(localizedSubsectionCount(category.subsectionCount))") // l10n: verbatim
                .font(DesignTokens.FontScale.caption)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
    }
}
