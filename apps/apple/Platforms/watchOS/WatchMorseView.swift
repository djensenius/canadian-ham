import AVFoundation
import SwiftUI

struct WatchMorseView: View {
    @Binding var settings: WatchMorseSettings
    @Environment(\.locale) private var locale
    @Environment(\.scenePhase) private var scenePhase
    @State private var drill: WatchMorseDrill?
    @State private var playback: WatchMorsePlayback?
    @State private var textRequested = false
    @State private var showingSettings = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Identify the Morse letter")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("watch-morse-prompt")
                        .id("top")
                    if let drill, let playback {
                        if playback.outputFailed {
                            Text("Morse output unavailable. Try haptics or turn both outputs off to use the text pattern.")
                                .accessibilityIdentifier("watch-morse-output-error")
                        }
                        if !settings.hasOutput {
                            Text("Haptics and tone are off. Request the text pattern to practise.")
                                .accessibilityIdentifier("watch-morse-no-output")
                        }
                        if playback.isPlaying {
                            Text("Playing Morse")
                                .accessibilityIdentifier("watch-morse-playing")
                        }
                        Button(playback.hasCompleted ? "Replay" : "Play Morse") { // l10n: localized
                            playback.play(letter: drill.letter, settings: settings)
                        }
                        .disabled(playback.isPlaying || !settings.hasOutput)
                        .accessibilityIdentifier("watch-morse-play")

                        if drill.selected != nil || textRequested {
                            pattern(for: drill)
                        } else if !settings.hasOutput {
                            Button("Show Morse pattern") { textRequested = true }
                                .accessibilityIdentifier("watch-morse-show-pattern")
                        }

                        if drill.selected != nil {
                            Text(drill.isCorrect ? "Correct" : "Incorrect") // l10n: localized
                                .font(.headline)
                                .accessibilityIdentifier("watch-morse-feedback")
                            Text("Your answer")
                                .font(.headline)
                                .accessibilityAddTraits(.isHeader)
                            Text(verbatim: drill.selected ?? "") // l10n: verbatim
                                .accessibilityValue("Selected")
                            Text("Correct answer")
                                .font(.headline)
                                .accessibilityAddTraits(.isHeader)
                            Text(verbatim: drill.letter) // l10n: verbatim
                                .accessibilityIdentifier("watch-morse-correct-answer")
                        } else if playback.hasCompleted || textRequested {
                            ForEach(Array(drill.choices.enumerated()), id: \.offset) { index, letter in
                                Button { submit(letter) } label: {
                                    Text(verbatim: letter) // l10n: verbatim
                                }
                                .accessibilityIdentifier("watch-morse-answer-\(index)")
                            }
                        }
                        Button("Next") {
                            playback.next()
                            self.drill?.next()
                            textRequested = false
                            proxy.scrollTo("top", anchor: .top)
                        }
                        .accessibilityIdentifier("watch-morse-next")
                        Button("Output settings") {
                            playback.cancel()
                            showingSettings = true
                        }
                        .accessibilityIdentifier("watch-morse-settings")
                    }
                }
                .font(.body)
                .padding(.horizontal)
            }
            .onChange(of: drill?.selected) { _, _ in proxy.scrollTo("top", anchor: .top) }
        }
        .navigationTitle("Morse")
        .sheet(isPresented: $showingSettings) { WatchMorseSettingsView(settings: $settings) }
        .task {
            guard drill == nil else { return }
            drill = WatchMorseDrill(seed: morseSeed)
            playback = WatchMorsePlayback(output: WatchMorseOutputDriver())
        }
        .onDisappear { playback?.cancel() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { playback?.cancel() }
        }
        .onChange(of: settings) { _, _ in
            playback?.cancel()
            if settings.hasOutput { textRequested = false }
        }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { playback?.handleAudioInterruption($0) }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.mediaServicesWereResetNotification)) { _ in playback?.cancel() }
    }

    @ViewBuilder
    private func pattern(for drill: WatchMorseDrill) -> some View {
        Text("Morse pattern")
            .font(.headline)
            .accessibilityAddTraits(.isHeader)
        Text(verbatim: drill.pattern.map(String.init).joined(separator: " ")) // l10n: verbatim
            .accessibilityLabel(Text(patternDescription(drill))) // l10n: localized
            .accessibilityIdentifier("watch-morse-pattern")
    }

    private func patternDescription(_ drill: WatchMorseDrill) -> String {
        drill.pattern.map {
            $0 == "." ? String(localized: "Dot", locale: locale) : String(localized: "Dash", locale: locale)
        }.joined(separator: ", ")
    }

    private func submit(_ letter: String) {
        guard drill?.selected == nil else { return }
        playback?.cancel()
        drill?.submit(letter)
        let message = drill?.isCorrect == true ? String(localized: "Correct", locale: locale) : String(localized: "Incorrect", locale: locale)
        AccessibilityNotification.Announcement(message).post()
    }

    private var morseSeed: String {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-watchMorseSeed"), arguments.indices.contains(index + 1) {
            return arguments[index + 1]
        }
        #endif
        return UUID().uuidString
    }
}

private struct WatchMorseSettingsView: View {
    @Binding var settings: WatchMorseSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Toggle("Haptics", isOn: $settings.haptics)
                    .accessibilityIdentifier("watch-morse-haptics")
                Toggle("Tone", isOn: $settings.tone)
                    .accessibilityIdentifier("watch-morse-tone")
                Picker("Haptic style", selection: $settings.hapticStyle) {
                    ForEach(WatchMorseHapticStyle.allCases, id: \.self) { style in
                        Text(style.preset.title).tag(style) // l10n: localized
                    }
                }
                .accessibilityIdentifier("watch-morse-haptic-style")
                Text(settings.hapticStyle.preset.description) // l10n: localized
                Picker("Speed", selection: $settings.wordsPerMinute) {
                    Text("1 WPM").tag(1.0)
                    Text("1.5 WPM").tag(1.5)
                    Text("2 WPM").tag(2.0)
                }
                .accessibilityIdentifier("watch-morse-speed")
                Text("Slow preset cadence; not exam timing.")
                Button("Done") { dismiss() }
                    .accessibilityIdentifier("watch-morse-settings-done")
            }
            .navigationTitle("Output settings")
        }
    }
}
