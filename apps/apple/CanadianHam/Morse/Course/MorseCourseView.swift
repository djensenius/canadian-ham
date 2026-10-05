import Accessibility
import CanadianHamMorseEngine
import SwiftUI

struct MorseCourseView: View {
    let progressStore: ProgressStoreService
    @Binding var settings: MorseTrainerSettings
    let onProgressChanged: () -> Void
    let playbackCoordinator: MorsePlaybackCoordinator

    @State private var course: MorseCourse?
    @State private var progress: MorseCourseProgressExport?
    @State private var session: MorseCourseSession?
    @State private var typedAnswer = ""
    @State private var statusMessage = ""
    @State private var statusMessageIsCorrective = false
    @State private var errorMessage: String?
    @State private var progressSaveFailed = false
    @State private var driver = MorseAudioDriver()
    @AccessibilityFocusState private var sessionIsFocused: Bool

    private var isCourseAuditOnly: Bool {
#if DEBUG
        ProcessInfo.processInfo.arguments.contains("-CanadianHamMorseCourseAuditOnly")
#else
        false
#endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            if !(isCourseAuditOnly && session != nil) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Koch course") // l10n: localized
                        .font(DesignTokens.FontScale.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Morse course path") // l10n: localized
                        .font(DesignTokens.FontScale.title.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("Learn the ISED Morse character set by ear with 40 short Koch lessons. Each lesson unlocks the next at 90% accuracy.") // l10n: localized
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                }
            }

            if let errorMessage {
                MessagePanel(title: "Morse course error", message: errorMessage, kind: .warning)
            }
            if let course, let progress {
                if let session {
                    sessionView(session, course: course, progress: progress)
                }
                if !isCourseAuditOnly || session == nil {
                    courseStats(course: course, progress: progress)
                    Button { startReview(course: course, progress: progress) } label: {
                        AccessibleSecondaryButtonLabel(title: "Review weakest characters")
                    } // l10n: localized
                    .buttonStyle(AccessibleSecondaryButtonStyle())
                    .accessibilityIdentifier("morse-course-review")
                    coursePath(course: course, progress: progress)
                }
            } else if errorMessage == nil {
                ProgressView("Loading Morse course…") // l10n: localized
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
        .task { loadCourse() }
        .onReceive(progressStore.objectWillChange) { _ in loadCourse() }
        .onAppear {
            playbackCoordinator.register("course") {
                stopCoursePlayback()
            }
        }
        .onDisappear {
            playbackCoordinator.unregister("course")
            stopCoursePlayback()
        }
    }

    private func courseStats(course: MorseCourse, progress: MorseCourseProgressExport) -> some View {
        let completed = progress.lessonProgress.filter { $0.bestAccuracy >= course.unlockAccuracy }.count
        let streak = morseDailyStreak(activity: progress.dailyActivity, todayIso: Date.now.localDateString)
        return HStack(spacing: DesignTokens.Spacing.md) {
            statCard(title: "Daily streak", value: String.localizedStringWithFormat(String(localized: "%lld days"), Int64(streak)))
            statCard(title: "Lessons completed", value: String.localizedStringWithFormat(String(localized: "%lld of %lld"), Int64(completed), Int64(course.lessons.count)))
        }
    }

    private func statCard(title: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(title) // l10n: localized
                .font(DesignTokens.FontScale.caption.weight(.semibold))
                .foregroundStyle(.primary)
            Text(value) // l10n: localized
                .font(DesignTokens.FontScale.title.weight(.bold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
    }

    private func coursePath(course: MorseCourse, progress: MorseCourseProgressExport) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            ForEach(course.units) { unit in
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Unit \(unit.unitNumber)") // l10n: localized
                        .font(.body.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
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
            Text(lessonButtonTitle(lesson: lesson, state: state)) // l10n: localized with verbatim characters
                .font(.body.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineSpacing(DesignTokens.Spacing.xs)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .foregroundStyle(DesignTokens.Colors.ink)
                .padding(DesignTokens.Spacing.sm)
                .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                        .strokeBorder(DesignTokens.Colors.border, style: StrokeStyle(lineWidth: 1, dash: state == .locked ? [5, 4] : []))
                }
        }
        .allowsHitTesting(state != .locked)
        .buttonStyle(.plain)
        .accessibilityRespondsToUserInteraction(state != .locked)
        .accessibilityLabel(Text(String.localizedStringWithFormat(String(localized: "Lesson %lld, %@, %@"), Int64(lesson.lessonNumber), lesson.newCharacters.joined(separator: " "), labelText(for: state)))) // l10n: localized
        .accessibilityHint(Text(accessibilityHintText(for: state))) // l10n: localized
        .accessibilityIdentifier("morse-course-lesson-\(lesson.lessonNumber)")
    }

    private func sessionView(_ session: MorseCourseSession, course: MorseCourse, progress: MorseCourseProgressExport) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text(session.title) // l10n: localized
                .font(DesignTokens.FontScale.title.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            Text(String.localizedStringWithFormat(String(localized: "Exercise %lld of %lld"), Int64(session.index + 1), Int64(session.exercises.count))) // l10n: localized
            if !session.done {
                exerciseView(session.currentExercise)
            }
            if !statusMessage.isEmpty && (!session.done || statusMessageIsCorrective) {
                Text(statusMessage) // l10n: localized
                    .foregroundStyle(DesignTokens.Colors.ink)
            }
            if session.done {
                let percent = session.total == 0 ? 100 : Int((Double(session.correct) / Double(session.total) * 100).rounded())
                Text("Lesson summary") // l10n: localized
                    .font(DesignTokens.FontScale.body.weight(.bold))
                Text(String.localizedStringWithFormat(String(localized: "Accuracy: %lld%%"), Int64(percent))) // l10n: localized
                Text(morseCourseSummaryMessage(for: session, percent: percent, course: course, progressSaved: !progressSaveFailed)) // l10n: localized
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .accessibilityFocused($sessionIsFocused)
    }

    @ViewBuilder
    private func exerciseView(_ exercise: MorseCourseExercise) -> some View {
        switch exercise {
        case .meet(let character):
            Text(String.localizedStringWithFormat(String(localized: "Meet %@. Listen, then notice its dits and dahs."), character)) // l10n: localized
            Text(morseCodeTable[character] ?? "") // l10n: verbatim
                .font(.largeTitle.weight(.bold).monospaced())
            HStack {
                Button { play(character) } label: {
                    AccessibleSecondaryButtonLabel(title: "Play character")
                } // l10n: localized
                .buttonStyle(AccessibleSecondaryButtonStyle())
                Button("Next") { answer(correct: true, results: []) } // l10n: localized
                    .buttonStyle(AccessiblePrimaryButtonStyle())
                    .accessibilityIdentifier("morse-course-next")
            }
        case .choose(let character, let options):
            Text("Listen and choose the character you heard.") // l10n: localized
            Button { play(character) } label: {
                AccessibleSecondaryButtonLabel(title: "Play")
            } // l10n: localized
            .buttonStyle(AccessibleSecondaryButtonStyle())
            HStack {
                ForEach(options, id: \.self) { option in
                    Button(option) { answer(correct: option == character, results: [(character, option == character)]) } // l10n: verbatim
                        .accessibilityIdentifier("morse-choice-\(option)")
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
            Button { play(expected) } label: {
                AccessibleSecondaryButtonLabel(title: "Play")
            } // l10n: localized
            .buttonStyle(AccessibleSecondaryButtonStyle())
            TextField("Your copy", text: $typedAnswer) // l10n: localized
#if os(iOS)
                .textInputAutocapitalization(.characters)
#endif
                .autocorrectionDisabled()
                .accessibilityIdentifier("morse-course-copy-field")
            Button("Check") {
                let normalized = typedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                answer(correct: normalized == expected, results: expected.enumerated().map { index, character in (String(character), normalized.dropFirst(index).first.map(String.init) == String(character)) })
            } // l10n: localized
            .buttonStyle(AccessiblePrimaryButtonStyle())
            .accessibilityIdentifier("morse-course-check")
        }
    }

    private func loadCourse() {
        do {
            guard let url = Bundle.main.url(forResource: "course", withExtension: "json") else {
                throw MorseCourseError.invalidFixture("Missing bundled Morse course fixture.")
            }
            let loadedCourse = try decodeMorseCourse(data: Data(contentsOf: url))
            let storedProgress = try progressStore.morseCourseProgress()
            course = loadedCourse
            progress = morseCourseProgressForBundledCourse(storedProgress, courseId: loadedCourse.courseId)
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func startLesson(_ lesson: MorseCourseLesson, course: MorseCourse, progress: MorseCourseProgressExport) {
        let exercises = buildMorseLessonExercises(lesson: lesson, progress: progress, seed: lessonSeed())
        resetSessionFeedback()
        session = MorseCourseSession(
            mode: .lesson(lesson),
            exercises: exercises
        )
        refocusSession()
    }

    private func startReview(course: MorseCourse, progress: MorseCourseProgressExport) {
        let learned = learnedMorseCharacters(course: course, progress: progress)
        let weakest = selectWeakestMorseCharacters(stats: progress.characterStats, learnedCharacters: learned, limit: 5)
        resetSessionFeedback()
        session = MorseCourseSession(mode: .review, exercises: (weakest.isEmpty ? Array(learned.prefix(5)) : weakest).map { .typeCharacter($0) })
        refocusSession()
    }

    private func play(_ text: String) {
        do {
            playbackCoordinator.claim("course")
            _ = try driver.play(text: text, settings: settings.normalized())
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func stopCoursePlayback() {
        driver.stop()
    }

    private func lessonSeed() -> String {
#if DEBUG
        AppLaunchArguments.value(after: "-CanadianHamMorseCourseSeed") ?? Date.now.canonicalUTCString
#else
        Date.now.canonicalUTCString
#endif
    }

    private func resetSessionFeedback() {
        typedAnswer = ""
        statusMessage = ""
        statusMessageIsCorrective = false
        progressSaveFailed = false
    }

    private func refocusSession() {
        sessionIsFocused = false
        DispatchQueue.main.async {
            sessionIsFocused = true
        }
    }

    private func answer(correct: Bool, results: [(String, Bool)]) {
        guard var currentSession = session else { return }
        let exercise = currentSession.currentExercise
        let scored = exercise.isScored
        guard currentSession.applyAnswer(correct: correct, results: results) else { return }
        if scored {
            statusMessage = correct ? String(localized: "Correct.") : String(localized: "Try again next time.") + " " + String(localized: "Correct answer: \(expectedAnswer(exercise)).")
            statusMessageIsCorrective = !correct
        } else {
            statusMessage = ""
            statusMessageIsCorrective = false
        }
        if currentSession.done {
            progressSaveFailed = !save(currentSession)
        }
        typedAnswer = ""
        session = currentSession
        if !statusMessage.isEmpty {
            AccessibilityNotification.Announcement(statusMessage).post()
        }
    }

    /// Returns true only when the progress was written; the summary must not claim success otherwise.
    @discardableResult
    private func save(_ session: MorseCourseSession) -> Bool {
        guard let course, let progress else { return false }
        do {
            let nextProgress: MorseCourseProgressExport
            switch session.mode {
            case .lesson(let lesson):
                nextProgress = try recordMorseLessonAttempt(course: course, progress: progress, lessonId: lesson.id, correct: session.correct, total: max(1, session.total), characterResults: session.characterResults, attemptedAt: Date.now.canonicalUTCString, activityDate: Date.now.localDateString)
            case .review:
                nextProgress = recordMorseCharacterResults(progress: progress, results: session.characterResults, attemptedAt: Date.now.canonicalUTCString)
            }
            try progressStore.saveMorseCourseProgress(nextProgress)
            self.progress = nextProgress
            onProgressChanged()
            return true
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
            return false
        }
    }

    private func lessonButtonTitle(lesson: MorseCourseLesson, state: MorseLessonState) -> String {
        String.localizedStringWithFormat(String(localized: "Lesson %lld\n%@\n%@"), Int64(lesson.lessonNumber), lesson.newCharacters.joined(separator: " "), labelText(for: state))
    }

    private func labelText(for state: MorseLessonState) -> String {
        switch state {
        case .locked: String(localized: "Locked")
        case .current: String(localized: "Current")
        case .completed: String(localized: "Completed")
        }
    }

    private func accessibilityHintText(for state: MorseLessonState) -> String {
        state == .locked ? String(localized: "Complete the previous lesson to unlock this lesson.") : ""
    }
}

struct MorseCourseSession {
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

    mutating func applyAnswer(correct isCorrect: Bool, results: [(String, Bool)]) -> Bool {
        guard !done else { return false }
        let scored = currentExercise.isScored
        if scored { total += 1 }
        if scored, isCorrect { correct += 1 }
        characterResults.append(contentsOf: results.map { (character: $0.0, correct: $0.1) })
        if index >= exercises.count - 1 {
            done = true
        } else {
            index += 1
        }
        return true
    }
}

private func expectedAnswer(_ exercise: MorseCourseExercise) -> String {
    switch exercise {
    case .meet(let character): character
    case .choose(let character, _): character
    case .typeCharacter(let character): character
    case .typeGroup(let text): text
    }
}

func morseCourseProgressForBundledCourse(_ storedProgress: MorseCourseProgressExport?, courseId: String) -> MorseCourseProgressExport {
    guard let storedProgress, storedProgress.courseId == courseId else {
        return emptyMorseCourseProgress(courseId: courseId)
    }
    return storedProgress
}

private extension MorseCourseExercise {
    var isScored: Bool {
        switch self {
        case .meet: false
        case .choose, .typeCharacter, .typeGroup: true
        }
    }
}

func morseCourseSummaryMessage(for session: MorseCourseSession, percent: Int, course: MorseCourse, progressSaved: Bool = true) -> String {
    guard progressSaved else {
        return String(localized: "Progress was not saved. Try again before relying on this result.")
    }
    switch session.mode {
    case .review:
        return String(localized: "Review complete. Practice progress was saved.")
    case .lesson(let lesson):
        let isFinalLesson = lesson.lessonNumber >= course.lessons.count
        if percent >= 90 {
            return isFinalLesson ? String(localized: "Great work. All Morse lessons are complete.") : String(localized: "Great work. The next lesson is unlocked.")
        }
        return isFinalLesson ? String(localized: "Reach 90% accuracy to complete this lesson.") : String(localized: "Reach 90% accuracy to unlock the next lesson.")
    }
}

func morseCourseLocalDateString(_ date: Date, timeZone: TimeZone = .current) -> String {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let components = calendar.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", components.year ?? 1970, components.month ?? 1, components.day ?? 1)
}

private extension Date {
    var canonicalUTCString: String {
        ISO8601Format(.iso8601(timeZone: .gmt, includingFractionalSeconds: true))
    }

    var localDateString: String {
        morseCourseLocalDateString(self)
    }
}
