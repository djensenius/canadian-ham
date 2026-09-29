import SwiftUI

private enum SidebarSelection: Hashable {
    case category(String)
    case about
}

struct RootView: View {
#if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
#endif

    @State private var bank: QuestionBank?
    @State private var loadError: String?
    @State private var selection: SidebarSelection?
    @State private var language: BankLanguage = .english

    var body: some View {
        Group {
            if let bank {
                appContent(for: bank)
            } else if let loadError {
                ContentUnavailableView(
                    "Question bank unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text(loadError)
                )
                .foregroundStyle(DesignTokens.Colors.ink)
                .background(DesignTokens.Colors.paper)
            } else {
                ProgressView("Loading question bank…")
                    .controlSize(.large)
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DesignTokens.Colors.paper)
            }
        }
        .task {
            loadBankIfNeeded()
        }
    }

    @ViewBuilder
    private func appContent(for bank: QuestionBank) -> some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section {
                    ForEach(bank.categories) { category in
                        NavigationLink(value: SidebarSelection.category(category.id)) {
                            CategoryRow(category: category, language: language)
                        }
                        .listRowBackground(DesignTokens.Colors.paperElevated)
                        .accessibilityLabel(categoryAccessibilityLabel(category))
                    }
                } header: {
                    Text("Practice categories")
                        .font(DesignTokens.FontScale.title.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .textCase(nil)
                        .accessibilityAddTraits(.isHeader)
                }
                .headerProminence(.increased)

                Section {
                    NavigationLink(value: SidebarSelection.about) {
                        Label("About", systemImage: "info.circle")
                            .font(DesignTokens.FontScale.body.weight(.semibold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                    }
                    .listRowBackground(DesignTokens.Colors.paperElevated)
                    .accessibilityLabel("About Canadian Ham")
                } header: {
                    Text("Information")
                        .font(DesignTokens.FontScale.title.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .textCase(nil)
                        .accessibilityAddTraits(.isHeader)
                }
                .headerProminence(.increased)
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(DesignTokens.Colors.paper)
            .navigationTitle("Canadian Ham")
            .toolbar {
                if showsSidebarLanguagePicker {
                    languageToolbarItem
                }
            }
        } detail: {
            detailView(for: bank)
                .background(DesignTokens.Colors.paper)
        }
        .navigationSplitViewStyle(.balanced)
#if os(macOS)
        .frame(minWidth: 920, minHeight: 640)
#endif
    }

    @ViewBuilder
    private func detailView(for bank: QuestionBank) -> some View {
        switch selection {
        case .category(let categoryId):
            if let category = bank.categories.first(where: { $0.id == categoryId }) {
                PracticeView(
                    bank: bank,
                    category: category,
                    showsLanguagePicker: showsPracticeLanguagePicker,
                    language: $language
                )
                .id(category.id)
            } else {
                ContentUnavailableView("Category not found", systemImage: "questionmark.folder")
                    .foregroundStyle(DesignTokens.Colors.ink)
            }
        case .about:
            AboutView(bank: bank)
        case nil:
            ContentUnavailableView(
                "Choose a practice category",
                systemImage: "list.bullet.rectangle",
                description: Text("Select a category to answer a random question from that part of the Basic bank.")
            )
            .foregroundStyle(DesignTokens.Colors.ink)
        }
    }

    private func loadBankIfNeeded() {
        guard bank == nil, loadError == nil else { return }

        do {
            let loadedBank = try QuestionBankStore.load()
            bank = loadedBank
            selection = loadedBank.categories.first.map { .category($0.id) }
        } catch {
            loadError = error.localizedDescription
        }
    }

#if os(macOS)
    private var showsSidebarLanguagePicker: Bool { false }
    private var showsPracticeLanguagePicker: Bool { true }
#else
    private var showsSidebarLanguagePicker: Bool { horizontalSizeClass == .compact }
    private var showsPracticeLanguagePicker: Bool { true }
#endif

    private var languageToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Picker("Question language", selection: $language) {
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
}

private struct CategoryRow: View {
    let category: BankCategory
    let language: BankLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(category.name.text(for: language))
                .font(DesignTokens.FontScale.body.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(category.questionCount) questions • \(category.subsectionCount) subsections")
                .font(DesignTokens.FontScale.caption)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
    }
}
