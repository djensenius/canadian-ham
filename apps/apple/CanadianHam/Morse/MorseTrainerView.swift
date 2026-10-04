import Accessibility
import CanadianHamMorseEngine
import SwiftUI

private let morsePracticeText = "KMRSU PARIS"

struct MorseTrainerView: View {
    @Binding var settings: MorseTrainerSettings
    let progressStore: ProgressStoreService
    let onSettingsChanged: (MorseTrainerSettings) -> Void
    let onProgressChanged: () -> Void

    @State private var driver = MorseAudioDriver()
    @State private var isPlaying = false
    @State private var isRevealed = false
    @State private var statusMessage = ""
    @State private var errorMessage: String?
    @State private var stopTask: Task<Void, Never>?

    private var normalizedSettings: MorseTrainerSettings { settings.normalized() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.sm) {
                        Text("Morse") // l10n: localized
                            .font(DesignTokens.FontScale.headline.weight(.bold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                            .accessibilityAddTraits(.isHeader)
                        Text("Preview") // l10n: localized
                            .font(DesignTokens.FontScale.caption.weight(.bold))
                            .foregroundStyle(DesignTokens.Colors.inkMuted)
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                            .padding(.vertical, DesignTokens.Spacing.xs)
                            .background(DesignTokens.Colors.paperInset, in: Capsule())
                    }
                    Text("Learn and practise Morse code offline. Start the Koch course now; copy practice and exam drills are coming soon.") // l10n: localized
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        MorseHomePlaceholder(title: "Learn (course)", message: "Koch lessons available now.")
                        MorseHomePlaceholder(title: "Copy practice", message: "Coming soon with copy-practice drills.")
                        MorseHomePlaceholder(title: "Exam", message: "Coming soon with the simulated 5 wpm exam.")
                    }
                }
                .paperCard()

                MorseCourseView(progressStore: progressStore, settings: $settings, onProgressChanged: onProgressChanged)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("Quick listen") // l10n: localized
                        .font(DesignTokens.FontScale.title.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("Preview the current player with a short practice group. The text is revealed only after playback so you can copy by ear first.") // l10n: localized
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                    HStack {
                        morseTokenButton("Play") { play() }
                            .disabled(isPlaying)
                            .accessibilityLabel(Text("Play Morse practice audio")) // l10n: localized
                        morseTokenButton("Stop") { stopPlayback(reveal: false, message: String(localized: "Morse playback stopped.")) }
                            .disabled(!isPlaying)
                            .accessibilityLabel(Text("Stop Morse practice audio")) // l10n: localized
                    }
                    if !statusMessage.isEmpty {
                        Text(statusMessage) // l10n: localized
                            .font(DesignTokens.FontScale.body)
                            .foregroundStyle(DesignTokens.Colors.ink)
                    }
                }
                .paperCard()

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("Practice text") // l10n: localized
                        .font(DesignTokens.FontScale.title.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    if isRevealed {
                        Text(verbatim: morsePracticeText) // l10n: verbatim
                            .font(.title.weight(.bold).monospaced())
                            .foregroundStyle(DesignTokens.Colors.ink)
                            .textSelection(.enabled)
                    } else {
                        Text("Hidden until playback finishes.") // l10n: localized
                            .font(DesignTokens.FontScale.body)
                            .foregroundStyle(DesignTokens.Colors.ink)
                    }
                }
                .paperCard()

#if os(macOS)
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("Morse settings") // l10n: localized
                        .font(DesignTokens.FontScale.title.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("Use Settings to change Morse tone, timing, and playback volume.") // l10n: localized
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                    SettingsLink {
                        Text("Open Morse settings") // l10n: localized
                    }
                }
                .paperCard()
#else
                MorseSettingsSection(settings: $settings, openMorse: {}) { nextSettings in
                    onSettingsChanged(nextSettings)
                }
                .paperCard()
#endif

                if let errorMessage {
                    MessagePanel(title: "Morse error", message: errorMessage, kind: .warning)
                }
            }
            .pagePadding()
        }
        .background(DesignTokens.Colors.paper)
        .navigationTitle("Morse")
        .onDisappear { stopPlayback(reveal: false, message: "") }
    }

    private func play() {
        do {
            isRevealed = false
            let duration = try driver.play(text: morsePracticeText, settings: normalizedSettings)
            isPlaying = true
            statusMessage = String(localized: "Morse playback started.")
            errorMessage = nil
            stopTask?.cancel()
            stopTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(Int((duration * 1000).rounded(.up)) + 60))
                guard !Task.isCancelled else { return }
                stopPlayback(reveal: true, message: String(localized: "Morse playback finished."))
            }
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func stopPlayback(reveal: Bool, message: String) {
        stopTask?.cancel()
        stopTask = nil
        driver.stop()
        isPlaying = false
        if reveal { isRevealed = true }
        statusMessage = message
        if !message.isEmpty {
            AccessibilityNotification.Announcement(message).post()
        }
    }
}

private struct MorseHomePlaceholder: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(title) // l10n: localized
                .font(DesignTokens.FontScale.body.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
            Text(message) // l10n: localized
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
        }
        .padding(DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
    }
}

private func formattedWpm(_ wpm: Double) -> String {
    if wpm.rounded() == wpm {
        return String.localizedStringWithFormat(String(localized: "%lld wpm"), Int64(wpm))
    }
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 1
    formatter.minimumFractionDigits = 1
    let value = formatter.string(from: NSNumber(value: wpm)) ?? String(format: "%.1f", wpm)
    return String.localizedStringWithFormat(String(localized: "%@ wpm"), value)
}

@MainActor
private func morseTokenButton(_ title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(title) // l10n: localized
            .font(DesignTokens.FontScale.body.weight(.semibold))
            .foregroundStyle(DesignTokens.Colors.ink)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.md)
            .frame(minHeight: 48)
            .background(DesignTokens.Colors.paperElevated, in: Capsule())
            .overlay(Capsule().strokeBorder(DesignTokens.Colors.ink, lineWidth: 1))
    }
    .buttonStyle(.plain)
}

struct MorseSettingsSection: View {
    @Binding var settings: MorseTrainerSettings
    let openMorse: () -> Void
    let onChange: (MorseTrainerSettings) -> Void

    private var displayedCharacterWpm: Double {
        let normalized = settings.normalized()
        guard normalized.timingProfile != .general,
              let profile = try? normalized.timingProfileValue() else { return Double(normalized.characterWpm) }
        return profile.characterWpm
    }

    private var displayedEffectiveWpm: Double {
        let normalized = settings.normalized()
        guard normalized.timingProfile != .general,
              let profile = try? normalized.timingProfileValue() else { return Double(normalized.effectiveWpm) }
        return profile.effectiveWpm
    }

    private var fixedTimingDescription: String? {
        let normalized = settings.normalized()
        guard normalized.timingProfile != .general,
              let profile = try? normalized.timingProfileValue() else { return nil }
        return String.localizedStringWithFormat(
            String(localized: "This exam timing profile fixes speed controls at %@ character speed and %@ effective speed. Choose General Farnsworth to edit speed settings."),
            formattedWpm(profile.characterWpm),
            formattedWpm(profile.effectiveWpm)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Morse settings") // l10n: localized
                .font(DesignTokens.FontScale.title.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            Text("These local settings control Morse tone, timing, and playback volume without network access.") // l10n: localized
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
            Stepper(value: binding(\.toneHz), in: 400...900, step: 10) {
                HStack {
                    Text("Tone") // l10n: localized
                    Text(verbatim: "\(settings.normalized().toneHz) Hz") // l10n: verbatim
                }
            }
            Stepper(value: binding(\.characterWpm), in: 12...25, step: 1) {
                HStack {
                    Text("Character speed") // l10n: localized
                    Text(formattedWpm(displayedCharacterWpm)) // l10n: localized
                }
            }
            .disabled(settings.normalized().timingProfile != .general)
            Stepper(value: binding(\.effectiveWpm), in: 5...settings.normalized().characterWpm, step: 1) {
                HStack {
                    Text("Effective speed") // l10n: localized
                    Text(formattedWpm(displayedEffectiveWpm)) // l10n: localized
                }
            }
            .disabled(settings.normalized().timingProfile != .general)
            Picker("Timing profile", selection: binding(\.timingProfile)) { // l10n: localized
                ForEach(MorseTrainerSettings.TimingProfile.allCases) { profile in
                    Text(profile.localizedLabel).tag(profile) // l10n: localized
                }
            }
            if let fixedTimingDescription {
                Text(fixedTimingDescription) // l10n: localized
                    .font(DesignTokens.FontScale.caption)
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
            }
            Slider(value: binding(\.volume), in: 0...1, step: 0.05) {
                Text("Trainer volume") // l10n: localized
            }
            morseTokenButton("ISED exam preset") {
                update(settings.applyingISEDExamPreset())
            }
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<MorseTrainerSettings, Value>) -> Binding<Value> {
        Binding(
            get: { settings.normalized()[keyPath: keyPath] },
            set: { value in
                var next = settings
                next[keyPath: keyPath] = value
                update(next)
            }
        )
    }

    private func update(_ next: MorseTrainerSettings) {
        let normalized = next.normalized()
        if normalized == settings.normalized() {
            return
        }
        settings = normalized
        normalized.save()
        onChange(normalized)
    }
}
