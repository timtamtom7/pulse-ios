import SwiftUI

@main
struct PulseWatchWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchComplicationView()
        }
    }
}

struct WatchComplicationView: View {
    @State private var lastEntry: MoodEntry?

    var body: some View {
        VStack(spacing: 8) {
            if let entry = lastEntry {
                Text(entry.emoji)
                    .font(.system(size: 44))

                Text(entry.emotionLabel)
                    .font(.caption)
                    .fontWeight(.medium)
            } else {
                Image(systemName: "heart")
                    .font(.system(size: 36))
                    .foregroundColor(.pink.opacity(0.5))

                Text("No check-in yet")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            loadLastEntry()
        }
    }

    private func loadLastEntry() {
        if let data = UserDefaults.standard.data(forKey: "lastMoodEntry"),
           let entry = try? JSONDecoder().decode(MoodEntry.self, from: data) {
            lastEntry = entry
        }
    }
}

extension MoodEntry {
    var emoji: String {
        if emotionScore > 0.6 { return "😄" }
        if emotionScore > 0.2 { return "🙂" }
        if emotionScore > -0.2 { return "😐" }
        if emotionScore > -0.6 { return "😔" }
        return "😢"
    }
}

#Preview {
    WatchComplicationView()
}
