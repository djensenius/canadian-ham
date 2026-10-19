import CanadianHamContent
import CanadianHamEngine
import Foundation

struct PlatformHintPanelState {
    let hint: QuestionHint
    let language: BankLanguage
    let visibleLevel: Int

    var lastAvailableLevel: Int { hint.hints.count }
    var nextLevel: Int? { visibleLevel < lastAvailableLevel ? visibleLevel + 1 : nil }
    var visibleHints: [QuestionHintText] { hint.hints.filter { $0.level <= visibleLevel } }
    var showsLessonLink: Bool { visibleLevel >= lastAvailableLevel }

    func localizedHintText(_ entry: QuestionHintText) -> AttributedString {
        var text = AttributedString(language == .french ? entry.fr : entry.en)
        text.languageIdentifier = language.accessibilityLanguageCode
        return text
    }
}

enum PlatformReferenceSheetAvailability {
    static let isAvailable = false
}

struct PlatformPracticeSelectionResult: Equatable {
    let answeredWithHelpQuestionIds: Set<String>
    let answeredWithHelp: Bool
}

enum PlatformPracticeSelectionLogic {
    static func selectAnswer(
        questionID: String,
        qualifiedQuestionIds: Set<String>,
        answeredWithHelpQuestionIds: Set<String>
    ) -> PlatformPracticeSelectionResult {
        let nextAnsweredWithHelpQuestionIds = PracticeHintRules.answeredWithHelpQuestionIdsAfterSelection(
            questionID: questionID,
            qualifiedQuestionIds: qualifiedQuestionIds,
            answeredWithHelpQuestionIds: answeredWithHelpQuestionIds
        )
        let answeredWithHelp = PracticeHintRules.shouldCommitAnswerWithHelp(
            questionID: questionID,
            qualifiedQuestionIds: qualifiedQuestionIds,
            answeredWithHelpQuestionIds: nextAnsweredWithHelpQuestionIds
        )
        return PlatformPracticeSelectionResult(
            answeredWithHelpQuestionIds: nextAnsweredWithHelpQuestionIds,
            answeredWithHelp: answeredWithHelp
        )
    }
}
