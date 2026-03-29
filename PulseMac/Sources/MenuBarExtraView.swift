import SwiftUI

struct MenuBarExtraView: View {
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
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(Color(hex: "C4706A"))
                    .font(.system(size: 14))

                Text("How are you?")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "3D3531"))

                Spacer()

                Text(todayLabel)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "8B7B74"))
            }

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
                                .foregroundColor(Color(hex: "3D3531"))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            if selectedEmotion != nil {
                TextField("Add a note (optional)", text: $note)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(8)
                    .background(Color(hex: "F5E6E0"))
                    .cornerRadius(6)
            }

            Divider()

            HStack(spacing: 12) {
                Button("Open Pulse") {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "3D3531"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: "F5E6E0"))
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
                    .background(Color(hex: "9CAF88"))
                    .cornerRadius(6)
                }

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "8B7B74"))
            }
        }
        .padding(16)
        .frame(width: 280)
        .background(Color(hex: "FDF8F3"))
    }

    private var todayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: Date())
    }

    private func saveQuickCapture() {
        guard let emotion = selectedEmotion else { return }

        let tag = EmotionTag(category: emotion, confidence: 0.8)
        let score: Double
        switch emotion {
        case .joy: score = 0.9
        case .trust: score = 0.7
        case .anticipation: score = 0.5
        case .surprise: score = 0.3
        case .neutral: score = 0.0
        case .sadness: score = -0.5
        case .fear: score = -0.6
        case .anger: score = -0.7
        case .disgust: score = -0.8
        }

        let moment = Moment(
            type: .journal,
            content: note.isEmpty ? "Quick mood check-in" : note,
            emotionScore: score,
            emotionTags: [tag],
            note: note.isEmpty ? nil : note
        )

        try? DatabaseService.shared.insertMoment(moment)
        selectedEmotion = nil
        note = ""
    }
}
