import SwiftUI

private enum SidebarSelection: Hashable {
    case category(String)
    case about
}

struct RootView: View {
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
            } else {
                ProgressView("Loading question bank…")
                    .controlSize(.large)
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
                Section("Practice categories") {
                    ForEach(bank.categories) { category in
                        NavigationLink(value: SidebarSelection.category(category.id)) {
                            CategoryRow(category: category, language: language)
                        }
                        .accessibilityLabel(categoryAccessibilityLabel(category))
                    }
                }

                Section("Information") {
                    NavigationLink(value: SidebarSelection.about) {
                        Label("About", systemImage: "info.circle")
                    }
                    .accessibilityLabel("About canadian-ham")
                }
            }
            .navigationTitle("Canadian Ham")
            .toolbar {
                languageToolbarItem
            }
        } detail: {
            detailView(for: bank)
        }
    }

    @ViewBuilder
    private func detailView(for bank: QuestionBank) -> some View {
        switch selection {
        case .category(let categoryId):
            if let category = bank.categories.first(where: { $0.id == categoryId }) {
                PracticeView(bank: bank, category: category, language: $language)
                    .id(category.id)
            } else {
                ContentUnavailableView("Category not found", systemImage: "questionmark.folder")
            }
        case .about:
            AboutView(bank: bank)
        case nil:
            ContentUnavailableView(
                "Choose a practice category",
                systemImage: "list.bullet.rectangle",
                description: Text("Select a category to answer a random question from that part of the Basic bank.")
            )
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
        "\(category.name.text(for: language)), \(category.questionCount) questions"
    }
}

private struct CategoryRow: View {
    let category: BankCategory
    let language: BankLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(category.name.text(for: language))
                .font(.headline)
            Text("\(category.questionCount) questions • \(category.subsectionCount) subsections")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
