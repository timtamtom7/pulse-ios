import SwiftUI

@main
struct PulseMacApp: App {
    @State private var showingPopover = false

    var body: some Scene {
        WindowGroup {
            MacContentView()
                .preferredColorScheme(.light)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }

        // Menu bar extra for quick mood capture
        MenuBarExtra {
            MenuBarExtraContent()
        } label: {
            Image(systemName: "moon.fill")
                .font(.system(size: 14))
                .foregroundColor(MacTheme.Colors.mutedRose)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Menu Bar Extra Content

struct MenuBarExtraContent: View {
    @State private var selectedEmotion: EmotionCategory?
    @State private var note = ""

    private let quickEmotions: [(category: EmotionCategory, icon: String, label: String)] = [
        (.joy, "face.smiling.fill", "Happy"),
        (.trust, "heart.fill", "Content"),
        (.surprise, "sparkles", "Surprised"),
        (.sadness, "cloud.rain.fill", "Sad"),
        (.neutral, "circle.fill", "Neutral")
    ]

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(MacTheme.Colors.mutedRose)
                    .font(.system(size: 14))

                Text("How are you?")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(MacTheme.Colors.charcoal)

                Spacer()

                Text(todayLabel)
                    .font(.system(size: 11))
                    .foregroundColor(MacTheme.Colors.warmGray)
            }

            // Quick emotion buttons
            HStack(spacing: 8) {
                ForEach(quickEmotions, id: \.category) { emotion in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedEmotion = emotion.category
                        }
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(
                                        selectedEmotion == emotion.category
                                        ? emotion.category.color
                                        : emotion.category.color.opacity(0.2)
                                    )
                                    .frame(width: 36, height: 36)

                                Image(systemName: emotion.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(
                                        selectedEmotion == emotion.category
                                        ? .white
                                        : emotion.category.color
                                    )
                            }

                            Text(emotion.label)
                                .font(.system(size: 9))
                                .foregroundColor(MacTheme.Colors.charcoal)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            // Optional note
            if selectedEmotion != nil {
                TextField("Add a note (optional)", text: $note)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(8)
                    .background(MacTheme.Colors.softBlush)
                    .cornerRadius(6)
            }

            Divider()

            // Actions
            HStack(spacing: 12) {
                Button("Open Pulse") {
                    openMainApp()
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(MacTheme.Colors.charcoal)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(MacTheme.Colors.softBlush)
                .cornerRadius(6)

                Spacer()

                if selectedEmotion != nil {
                    Button("Save") {
                        saveQuickCapture()
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(MacTheme.Colors.calmSage)
                    .cornerRadius(6)
                }

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .font(.system(size: 12))
                .foregroundColor(MacTheme.Colors.warmGray)
            }
        }
        .padding(16)
        .frame(width: 280)
        .background(MacTheme.Colors.cream)
    }

    private var todayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: Date())
    }

    private func openMainApp() {
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func saveQuickCapture() {
        guard let emotion = selectedEmotion else { return }

        let tag = EmotionTag(category: emotion, confidence: 0.8)
        let moment = Moment(
            type: .journal,
            content: note.isEmpty ? "Quick mood check-in" : note,
            emotionScore: emotionToScore(emotion),
            emotionTags: [tag],
            note: note.isEmpty ? nil : note
        )

        try? DatabaseService.shared.insertMoment(moment)

        // Reset
        selectedEmotion = nil
        note = ""
    }

    private func emotionToScore(_ emotion: EmotionCategory) -> Double {
        switch emotion {
        case .joy: return 0.9
        case .trust: return 0.7
        case .anticipation: return 0.5
        case .surprise: return 0.3
        case .neutral: return 0.0
        case .sadness: return -0.5
        case .fear: return -0.6
        case .anger: return -0.7
        case .disgust: return -0.8
        }
    }
}
