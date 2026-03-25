import SwiftUI
import WatchKit

struct MoodCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMood: QuickMood?
    @State private var showingConfirmation = false

    let onComplete: (MoodEntry) -> Void

    var body: some View {
        if showingConfirmation, let mood = selectedMood {
            ConfirmationView(mood: mood) {
                let entry = MoodEntry(emotionScore: mood.emotionScore, emotionLabel: mood.label)
                saveEntry(entry)
                onComplete(entry)
            }
        } else {
            MoodSelectionView(selectedMood: $selectedMood) {
                showingConfirmation = true
            }
        }
    }

    private func saveEntry(_ entry: MoodEntry) {
        if let data = try? JSONEncoder().encode(entry) {
            UserDefaults.standard.set(data, forKey: "lastMoodEntry")

            // Store in shared app group for iOS app to pick up
            if let sharedDefaults = UserDefaults(suiteName: "group.com.pulse.app") {
                let key = "watchMoodEntries"
                var entries = (sharedDefaults.data(forKey: key).flatMap { try? JSONDecoder().decode([MoodEntry].self, from: $0) }) ?? []
                entries.append(entry)
                if entries.count > 50 { entries = Array(entries.suffix(50)) }
                if let data = try? JSONEncoder().encode(entries) {
                    sharedDefaults.set(data, forKey: key)
                }
            }
        }
    }
}

struct MoodSelectionView: View {
    @Binding var selectedMood: QuickMood?
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("How are you?")
                .font(.headline)
                .foregroundColor(.secondary)

            // Mood grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(QuickMood.allCases) { mood in
                    MoodButton(mood: mood, isSelected: selectedMood == mood) {
                        selectedMood = mood
                    }
                }
            }

            Spacer()

            Button {
                onContinue()
            } label: {
                Text("Continue")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
            .disabled(selectedMood == nil)
        }
        .padding()
    }
}

struct MoodButton: View {
    let mood: QuickMood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.system(size: 28))

                Text(mood.label)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.pink.opacity(0.2) : Color.secondary.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ConfirmationView: View {
    let mood: QuickMood
    let onSave: () -> Void

    @State private var animateSuccess = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Text(mood.emoji)
                .font(.system(size: 60))
                .scaleEffect(animateSuccess ? 1.0 : 0.5)
                .opacity(animateSuccess ? 1.0 : 0)

            Text("Feeling \(mood.label)")
                .font(.headline)
                .opacity(animateSuccess ? 1.0 : 0)

            Text("Saved to Pulse")
                .font(.caption)
                .foregroundColor(.secondary)
                .opacity(animateSuccess ? 1.0 : 0)

            Spacer()

            Button {
                onSave()
            } label: {
                Text("Done")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
        }
        .padding()
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                animateSuccess = true
            }
            WKInterfaceDevice.current().play(.success)
        }
    }
}

#Preview {
    MoodCheckInView { _ in }
}
