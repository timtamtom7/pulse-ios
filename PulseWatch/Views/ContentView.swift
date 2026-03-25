import SwiftUI
import WatchKit

struct ContentView: View {
    @State private var showingCheckIn = false
    @State private var lastEntry: MoodEntry?
    @State private var recentEntries: [MoodEntry] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Greeting
                Text(greeting)
                    .font(.headline)
                    .foregroundColor(.secondary)

                // Quick mood check-in button
                Button {
                    showingCheckIn = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.pink)

                        Text("Check In")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(Color.pink.opacity(0.1))
                .cornerRadius(16)

                // Last entry summary
                if let last = lastEntry {
                    HStack {
                        Text(lastEntry?.emoji ?? "")
                            .font(.title2)

                        VStack(alignment: .leading) {
                            Text(last.emotionLabel)
                                .font(.caption)
                                .fontWeight(.medium)

                            Text(last.timestamp, style: .relative)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Pulse")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingCheckIn) {
            MoodCheckInView { entry in
                lastEntry = entry
                recentEntries.append(entry)
                showingCheckIn = false
            }
        }
        .onAppear {
            loadLastEntry()
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    private func loadLastEntry() {
        if let data = UserDefaults.standard.data(forKey: "lastMoodEntry"),
           let entry = try? JSONDecoder().decode(MoodEntry.self, from: data) {
            lastEntry = entry
        }
    }
}

// Extension for emoji on MoodEntry when stored
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
    ContentView()
}
