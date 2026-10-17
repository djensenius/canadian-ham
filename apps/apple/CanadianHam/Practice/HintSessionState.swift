import Foundation

struct PracticeHintQualificationResult: Equatable {
    var qualifiedQuestionIds: Set<String>
    var answeredWithHelpQuestionIds: Set<String>
}

enum PracticeHintRules {
    static func canRecordHelp(mode: ApplePreferences.PracticeMode, alreadySelected: Bool, reviewSubmitted: Bool) -> Bool {
        guard !reviewSubmitted else { return false }
        return !(mode == .immediate && alreadySelected)
    }

    static func qualifyingHint(
        questionID: String,
        mode: ApplePreferences.PracticeMode,
        alreadySelected: Bool,
        reviewSubmitted: Bool,
        qualifiedQuestionIds: Set<String>,
        answeredWithHelpQuestionIds: Set<String>
    ) -> PracticeHintQualificationResult {
        guard canRecordHelp(mode: mode, alreadySelected: alreadySelected, reviewSubmitted: reviewSubmitted) else {
            return PracticeHintQualificationResult(qualifiedQuestionIds: qualifiedQuestionIds, answeredWithHelpQuestionIds: answeredWithHelpQuestionIds)
        }
        var nextQualified = qualifiedQuestionIds
        var nextAnsweredWithHelp = answeredWithHelpQuestionIds
        nextQualified.insert(questionID)
        if alreadySelected {
            nextAnsweredWithHelp.insert(questionID)
        }
        return PracticeHintQualificationResult(qualifiedQuestionIds: nextQualified, answeredWithHelpQuestionIds: nextAnsweredWithHelp)
    }

    static func answeredWithHelpQuestionIdsAfterSelection(questionID: String, qualifiedQuestionIds: Set<String>, answeredWithHelpQuestionIds: Set<String>) -> Set<String> {
        guard qualifiedQuestionIds.contains(questionID) else { return answeredWithHelpQuestionIds }
        var next = answeredWithHelpQuestionIds
        next.insert(questionID)
        return next
    }

    static func shouldSubmitAnswerWithHelp(questionID: String, qualifiedQuestionIds: Set<String>, answeredWithHelpQuestionIds: Set<String>) -> Bool {
        qualifiedQuestionIds.contains(questionID) || answeredWithHelpQuestionIds.contains(questionID)
    }
}

@MainActor
final class HintVisibilityQualificationTimer {
    static let defaultDelayNanoseconds: UInt64 = 500_000_000

    private var activeQuestionID: String?
    private var task: Task<Void, Never>?

    func begin(
        questionID: String,
        canRecordHelp: Bool,
        alreadyQualified: Bool,
        delayNanoseconds: UInt64 = defaultDelayNanoseconds,
        onQualified: @escaping @MainActor () -> Void
    ) {
        guard canRecordHelp, !alreadyQualified else {
            cancel()
            return
        }
        guard activeQuestionID != questionID else { return }
        cancel()
        activeQuestionID = questionID
        task = Task { @MainActor in
            try? await Task.sleep(nanoseconds: delayNanoseconds)
            guard !Task.isCancelled, activeQuestionID == questionID else { return }
            onQualified()
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        activeQuestionID = nil
    }
}
