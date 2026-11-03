enum SidebarSelection: Hashable {
    case home
    case learn
    case practiceHub
    case practice(PracticeScope)
    case mockExam
    case morse
    case settings
    case about

    var isExamSessionSelection: Bool {
        switch self {
        case .practice, .mockExam:
            true
        case .home, .learn, .practiceHub, .morse, .settings, .about:
            false
        }
    }
}

enum CompactSection: Hashable {
    case home
    case learn
    case practice
    case morse
    case settings
}

/// The same value type is used by Learn links in both navigation containers.
enum RootNavigationRoute: Hashable {
    case section(CompactSection)
    case learn(LearnRoute)
    case practice(PracticeScope)
    case mockExam
    case about
}

struct SplitNavigationState: Equatable {
    var selection: SidebarSelection
    var path: [LearnRoute]
}

enum RootNavigationMapping {
    static func splitState(for compactPath: [RootNavigationRoute]) -> SplitNavigationState {
        var state = SplitNavigationState(selection: .home, path: [])
        for route in compactPath {
            switch route {
            case .section(let section):
                state.selection = switch section {
                case .home: .home
                case .learn: .learn
                case .practice: .practiceHub
                case .morse: .morse
                case .settings: .settings
                }
                state.path = []
            case .practice(let scope):
                state = SplitNavigationState(selection: .practice(scope), path: [])
            case .mockExam:
                state = SplitNavigationState(selection: .mockExam, path: [])
            case .about:
                state = SplitNavigationState(selection: .about, path: [])
            case .learn(let learnRoute):
                // Hint and explanation links push Learn routes above an exam session.
                // Keep that session as the split detail root so Back still returns to it.
                state.path.append(learnRoute)
            }
        }
        return state
    }

    static func compactPath(for state: SplitNavigationState) -> [RootNavigationRoute] {
        let root: [RootNavigationRoute] = switch state.selection {
        case .home: [.section(.home)]
        case .learn: [.section(.learn)]
        case .practiceHub: [.section(.practice)]
        case .practice(let scope): [.section(.practice), .practice(scope)]
        case .mockExam: [.section(.practice), .mockExam]
        case .morse: [.section(.morse)]
        case .settings: [.section(.settings)]
        case .about: [.section(.settings), .about]
        }
        return root + state.path.map { .learn($0) }
    }
}
