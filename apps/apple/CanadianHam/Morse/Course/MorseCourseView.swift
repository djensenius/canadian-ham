import Accessibility
import CanadianHamMorseEngine
import SwiftUI

struct MorseCourseView: View {
    let progressStore: ProgressStoreService
    @Binding var settings: MorseTrainerSettings
    let onProgressChanged: () -> Void

    @State private var course: MorseCourse?
    @State private var progress: MorseCourseProgressExport?
    @State private var session: MorseCourseSession?
    @State private var typedAnswer = ""
    @State private var statusMessage = ""
    @State private var errorMessage: String?
    @State private var driver = MorseAudioDriver()

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Koch course") // l10n: localized
                    .font(DesignTokens.FontScale.caption.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
                Text("Morse course path") // l10n: localized
                    .font(DesignTokens.FontScale.title.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                Text("Learn the ISED Morse character set by ear with 40 short Koch lessons. Each lesson unlocks the next at 90% accuracy.") // l10n: localized
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.ink)
            }

            if let course, let progress {
                courseStats(course: course, progress: progress)
                Button("Review weakest characters") { startReview(course: course, progress: progress) } // l10n: localized
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("morse-course-review")
                coursePath(course: course, progress: progress)
                if let session {
                    sessionView(session, course: course, progress: progress)
                }
            } else if let errorMessage {
                MessagePanel(title: "Morse course error", message: errorMessage, kind: .warning)
            } else {
                ProgressView("Loading Morse course…") // l10n: localized
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
        .task { loadCourse() }
        .onDisappear { driver.stop() }
    }

    private func courseStats(course: MorseCourse, progress: MorseCourseProgressExport) -> some View {
        let completed = progress.lessonProgress.filter { $0.bestAccuracy >= course.unlockAccuracy }.count
        let streak = morseDailyStreak(activity: progress.dailyActivity, todayIso: Date.now.canonicalUTCString)
        return HStack(spacing: DesignTokens.Spacing.md) {
            statCard(title: "Daily streak", value: String.localizedStringWithFormat(String(localized: "%lld days"), Int64(streak)))
            statCard(title: "Lessons completed", value: String.localizedStringWithFormat(String(localized: "%lld of %lld"), Int64(completed), Int64(course.lessons.count)))
        }
    }

    private func statCard(title: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(title) // l10n: localized
                .font(DesignTokens.FontScale.caption.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.inkMuted)
            Text(value) // l10n: localized
                .font(DesignTokens.FontScale.title.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
    }

    private func coursePath(course: MorseCourse, progress: MorseCourseProgressExport) -> some View {
        LazyVStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            ForEach(course.units) { unit in
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text(String.localizedStringWithFormat(String(localized: "Unit %lld"), Int64(unit.unitNumber))) // l10n: localized
                        .font(DesignTokens.FontScale.body.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.sm), count: 5), spacing: DesignTokens.Spacing.sm) {
                        ForEach(unit.lessonIds, id: \.self) { lessonId in
                            if let lesson = course.lessons.first(where: { $0.id == lessonId }) {
                                lessonButton(lesson: lesson, state: (try? morseLessonState(course: course, progress: progress, lessonId: lesson.id)) ?? .locked)
                            }
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Morse course units and lessons")) // l10n: localized
    }

    private func lessonButton(lesson: MorseCourseLesson, state: MorseLessonState) -> some View {
        Button {
            guard let course, let progress, state != .locked else { return }
            startLesson(lesson, course: course, progress: progress)
        } label: {
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text(String.localizedStringWithFormat(String(localized: "Lesson %lld"), Int64(lesson.lessonNumber))) // l10n: localized
                    .font(DesignTokens.FontScale.caption)
                Text(lesson.newCharacters.joined(separator: " ")) // l10n: verbatim
                    .font(DesignTokens.FontScale.body.weight(.bold).monospaced())
                Text(label(for: state)) // l10n: localized
                    .font(DesignTokens.FontScale.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 84)
        }
        .disabled(state == .locked)
        .buttonStyle(.bordered)
        .accessibilityLabel(Text(String.localizedStringWithFormat(String(localized: "Lesson %lld, %@, %@"), Int64(lesson.lessonNumber), lesson.newCharacters.joined(separator: " "), labelText(for: state)))) // l10n: localized
        .accessibilityIdentifier("morse-course-lesson-\(lesson.lessonNumber)")
    }

    private func sessionView(_ session: MorseCourseSession, course: MorseCourse, progress: MorseCourseProgressExport) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text(session.title) // l10n: localized
                .font(DesignTokens.FontScale.title.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            Text(String.localizedStringWithFormat(String(localized: "Exercise %lld of %lld"), Int64(session.index + 1), Int64(session.exercises.count))) // l10n: localized
            exerciseView(session.currentExercise)
            if !statusMessage.isEmpty {
                Text(statusMessage) // l10n: localized
                    .foregroundStyle(DesignTokens.Colors.ink)
            }
            if session.done {
                let percent = session.total == 0 ? 100 : Int((Double(session.correct) / Double(session.total) * 100).rounded())
                Text("Lesson summary") // l10n: localized
                    .font(DesignTokens.FontScale.body.weight(.bold))
                Text(String.localizedStringWithFormat(String(localized: "Accuracy: %lld%%"), Int64(percent))) // l10n: localized
                Text(percent >= 90 ? "Great work. The next lesson is unlocked." : "Reach 90% accuracy to unlock the next lesson.") // l10n: localized
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .accessibilityIdentifier("morse-course-session")
    }

    @ViewBuilder
    private func exerciseView(_ exercise: MorseCourseExercise) -> some View {
        switch exercise {
        case .meet(let character):
            Text(String.localizedStringWithFormat(String(localized: "Meet %@. Listen, then notice its dits and dahs."), character)) // l10n: localized
            Text(morseCodeTable[character] ?? "") // l10n: verbatim
                .font(.largeTitle.weight(.bold).monospaced())
            HStack {
                Button("Play character") { play(character) } // l10n: localized
                Button("Next") { answer(correct: true, results: []) } // l10n: localized
                    .buttonStyle(.borderedProminent)
            }
        case .choose(let character, let options):
            Text("Listen and choose the character you heard.") // l10n: localized
            Button("Play") { play(character) } // l10n: localized
            HStack {
                ForEach(options, id: \.self) { option in
                    Button(option) { answer(correct: option == character, results: [(character, option == character)]) } // l10n: verbatim
                }
            }
        case .typeCharacter(let character):
            typedCopyForm(prompt: "Listen and type the single character.", expected: character) // l10n: localized
        case .typeGroup(let text):
            typedCopyForm(prompt: "Listen and type the five-character Koch group.", expected: text) // l10n: localized
        }
    }

    private func typedCopyForm(prompt: LocalizedStringKey, expected: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(prompt) // l10n: localized
            Button("Play") { play(expected) } // l10n: localized
            TextField("Your copy", text: $typedAnswer) // l10n: localized
                .accessibilityIdentifier("morse-course-copy-field")
            Button("Check") {
                let normalized = typedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                answer(correct: normalized == expected, results: expected.enumerated().map { index, character in (String(character), normalized.dropFirst(index).first.map(String.init) == String(character)) })
            } // l10n: localized
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("morse-course-check")
        }
    }

    private func loadCourse() {
        do {
            guard let url = Bundle.main.url(forResource: "course", withExtension: "json") else {
                throw MorseCourseError.invalidFixture("Missing bundled Morse course fixture.")
            }
            let loadedCourse = try decodeMorseCourse(data: Data(contentsOf: url))
            course = loadedCourse
            progress = try progressStore.morseCourseProgress() ?? emptyMorseCourseProgress(courseId: loadedCourse.courseId)
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func startLesson(_ lesson: MorseCourseLesson, course: MorseCourse, progress: MorseCourseProgressExport) {
        let focus = lesson.newCharacters.last ?? "K"
        let group = String((lesson.learnedCharacters.suffix(5).joined() + String(repeating: focus, count: 5)).prefix(5))
        typedAnswer = ""
        session = MorseCourseSession(
            mode: .lesson(lesson),
            exercises: [.meet(focus), .choose(focus, Array(lesson.learnedCharacters.prefix(4)).contains(focus) ? Array(lesson.learnedCharacters.prefix(4)) : Array(lesson.learnedCharacters.prefix(3)) + [focus]), .typeCharacter(focus), .typeGroup(group)]
        )
    }

    private func startReview(course: MorseCourse, progress: MorseCourseProgressExport) {
        let learned = learnedMorseCharacters(course: course, progress: progress)
        let weakest = selectWeakestMorseCharacters(stats: progress.characterStats, learnedCharacters: learned, limit: 5)
        session = MorseCourseSession(mode: .review, exercises: (weakest.isEmpty ? Array(learned.prefix(5)) : weakest).map { .typeCharacter($0) })
    }

    private func play(_ text: String) {
        do {
            _ = try driver.play(text: text, settings: settings.normalized())
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func answer(correct: Bool, results: [(String, Bool)]) {
        guard var currentSession = session else { return }
        let scored = currentSession.currentExercise.isScored
        if scored { currentSession.total += 1 }
        if scored, correct { currentSession.correct += 1 }
        currentSession.characterResults.append(contentsOf: results.map { (character: $0.0, correct: $0.1) })
        statusMessage = correct ? String(localized: "Correct.") : String(localized: "Try again next time.")
        let isLast = currentSession.index >= currentSession.exercises.count - 1
        if isLast {
            currentSession.done = true
            save(currentSession)
        } else {
            currentSession.index += 1
        }
        typedAnswer = ""
        session = currentSession
        AccessibilityNotification.Announcement(statusMessage).post()
    }

    private func save(_ session: MorseCourseSession) {
        guard let course, let progress else { return }
        do {
            let nextProgress: MorseCourseProgressExport
            switch session.mode {
            case .lesson(let lesson):
                nextProgress = try recordMorseLessonAttempt(course: course, progress: progress, lessonId: lesson.id, correct: session.correct, total: max(1, session.total), characterResults: session.characterResults, attemptedAt: Date.now.canonicalUTCString)
            case .review:
                nextProgress = recordMorseCharacterResults(progress: progress, results: session.characterResults, attemptedAt: Date.now.canonicalUTCString)
            }
            try progressStore.saveMorseCourseProgress(nextProgress)
            self.progress = nextProgress
            onProgressChanged()
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func label(for state: MorseLessonState) -> LocalizedStringKey {
        switch state {
        case .locked: "Locked"
        case .current: "Current"
        case .completed: "Completed"
        }
    }

    private func labelText(for state: MorseLessonState) -> String {
        switch state {
        case .locked: String(localized: "Locked")
        case .current: String(localized: "Current")
        case .completed: String(localized: "Completed")
        }
    }
}

private struct MorseCourseSession {
    enum Mode {
        case lesson(MorseCourseLesson)
        case review
    }

    var mode: Mode
    var exercises: [MorseCourseExercise]
    var index = 0
    var correct = 0
    var total = 0
    var characterResults: [(character: String, correct: Bool)] = []
    var done = false

    var currentExercise: MorseCourseExercise { exercises[index] }
    var title: LocalizedStringKey {
        switch mode {
        case .lesson(let lesson): return LocalizedStringKey("Lesson \(lesson.lessonNumber) session")
        case .review: return "Weak-character review"
        }
    }
}

private enum MorseCourseExercise {
    case meet(String)
    case choose(String, [String])
    case typeCharacter(String)
    case typeGroup(String)

    var isScored: Bool {
        switch self {
        case .meet: false
        case .choose, .typeCharacter, .typeGroup: true
        }
    }
}

private extension Date {
    var canonicalUTCString: String {
        ISO8601Format(.iso8601(timeZone: .gmt, includingFractionalSeconds: true))
    }
}
