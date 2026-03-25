import Foundation
import WidgetKit
import SwiftUI

/// Service to manage Apple Watch complications
/// Provides timeline entries for watch face complications
final class WatchComplicationService: @unchecked Sendable {
    static let shared = WatchComplicationService()

    private let userDefaults = UserDefaults(suiteName: "group.com.pulse.app")

    private init() {}

    /// Fetch the latest mood entry for complication display
    func latestMoodEntry() -> MoodEntry? {
        guard let data = userDefaults?.data(forKey: "lastMoodEntry"),
              let entry = try? JSONDecoder().decode(MoodEntry.self, from: data) else {
            return nil
        }
        return entry
    }

    /// Get recent mood entries for trend display
    func recentMoodEntries(days: Int = 7) -> [MoodEntry] {
        guard let data = userDefaults?.data(forKey: "watchMoodEntries"),
              let entries = try? JSONDecoder().decode([MoodEntry].self, from: data) else {
            return []
        }

        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return entries.filter { $0.timestamp >= cutoff }
    }

    /// Calculate weekly average for complication
    func weeklyAverage() -> Double {
        let entries = recentMoodEntries(days: 7)
        guard !entries.isEmpty else { return 0 }
        return entries.map(\.emotionScore).reduce(0, +) / Double(entries.count)
    }

    /// Get dominant emotion for the week
    func weeklyDominantEmotion() -> QuickMood {
        let entries = recentMoodEntries(days: 7)
        guard !entries.isEmpty else { return .okay }

        let avg = entries.map(\.emotionScore).reduce(0, +) / Double(entries.count)

        if avg > 0.6 { return .great }
        if avg > 0.2 { return .good }
        if avg > -0.2 { return .okay }
        if avg > -0.6 { return .low }
        return .rough
    }

    /// Check if user has checked in today
    func hasCheckedInToday() -> Bool {
        let entries = recentMoodEntries(days: 1)
        let today = Calendar.current.startOfDay(for: Date())
        return entries.contains { $0.timestamp >= today }
    }

    /// Current streak of daily check-ins
    func checkInStreak() -> Int {
        let entries = recentMoodEntries(days: 30)
        guard !entries.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        while true {
            let hasEntry = entries.contains { calendar.isDate($0.timestamp, inSameDayAs: currentDate) }
            if hasEntry {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = previousDay
            } else if calendar.isDateInToday(currentDate) {
                // Skip today if no check-in yet
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = previousDay
                continue
            } else {
                break
            }
        }

        return streak
    }
}

// MARK: - Watch Complication Data Models

/// Data structure for watch complications
struct ComplicationData {
    let emoji: String
    let label: String
    let timestamp: Date?
    let color: UIColor

    static var placeholder: ComplicationData {
        ComplicationData(
            emoji: "💗",
            label: "Check in",
            timestamp: nil,
            color: UIColor(red: 0.77, green: 0.44, blue: 0.42, alpha: 1)
        )
    }

    static func from(moodEntry: MoodEntry) -> ComplicationData {
        let mood: QuickMood
        if moodEntry.emotionScore > 0.6 { mood = .great }
        else if moodEntry.emotionScore > 0.2 { mood = .good }
        else if moodEntry.emotionScore > -0.2 { mood = .okay }
        else if moodEntry.emotionScore > -0.6 { mood = .low }
        else { mood = .rough }

        return ComplicationData(
            emoji: mood.emoji,
            label: mood.label,
            timestamp: moodEntry.timestamp,
            color: mood.color
        )
    }

    static func from(quickMood: QuickMood) -> ComplicationData {
        ComplicationData(
            emoji: quickMood.emoji,
            label: quickMood.label,
            timestamp: Date(),
            color: quickMood.color
        )
    }
}
