import Foundation
import NaturalLanguage

// MARK: - Pattern Detection Service

final class PatternDetectionService: @unchecked Sendable {
    static let shared = PatternDetectionService()

    private init() {}

    // MARK: - Detect All Patterns

    func detectPatterns(in entries: [Moment]) -> [String] {
        var patterns: [String] = []

        let timePatterns = detectTimeOfDayPatterns(in: entries)
        let dayPatterns = detectDayOfWeekPatterns(in: entries)
        let streakPatterns = detectStreakPatterns(in: entries)
        let triggerPatterns = detectEmotionalTriggers(in: entries)

        patterns.append(contentsOf: timePatterns)
        patterns.append(contentsOf: dayPatterns)
        patterns.append(contentsOf: streakPatterns)
        patterns.append(contentsOf: triggerPatterns)

        return patterns
    }

    // MARK: - Time of Day Patterns

    func detectTimeOfDayPatterns(in entries: [Moment]) -> [String] {
        var patterns: [String] = []
        let calendar = Calendar.current

        var morningEntries: [Moment] = []
        var afternoonEntries: [Moment] = []
        var eveningEntries: [Moment] = []

        for entry in entries {
            let hour = calendar.component(.hour, from: entry.timestamp)
            switch hour {
            case 5..<12: morningEntries.append(entry)
            case 12..<17: afternoonEntries.append(entry)
            default: eveningEntries.append(entry)
            }
        }

        let morningAvg = averageScore(morningEntries)
        let afternoonAvg = averageScore(afternoonEntries)
        let eveningAvg = averageScore(eveningEntries)

        let allAvgs = [(label: "morning", avg: morningAvg, count: morningEntries.count),
                       (label: "afternoon", avg: afternoonAvg, count: afternoonEntries.count),
                       (label: "evening", avg: eveningAvg, count: eveningEntries.count)]
            .filter { $0.count >= 1 }

        guard let best = allAvgs.max(by: { $0.avg < $1.avg }),
              let worst = allAvgs.min(by: { $0.avg < $1.avg }),
              best.avg - worst.avg > 0.3 else {
            return []
        }

        patterns.append("You tend to feel best in the \(best.label)s (avg score: \(String(format: "%.1f", best.avg)))")
        if worst.avg < 0 {
            patterns.append("\(worst.label.capitalized) time tends to be more reflective or difficult")
        }

        return patterns
    }

    // MARK: - Day of Week Patterns

    func detectDayOfWeekPatterns(in entries: [Moment]) -> [String] {
        var patterns: [String] = []
        let calendar = Calendar.current

        var weekdayScores: [Int: [Double]] = [:]

        for entry in entries {
            let weekday = calendar.component(.weekday, from: entry.timestamp)
            weekdayScores[weekday, default: []].append(entry.emotionScore)
        }

        var dayAvgs: [(weekday: Int, avg: Double, count: Int)] = []
        for (weekday, scores) in weekdayScores where scores.count >= 1 {
            let avg = scores.reduce(0, +) / Double(scores.count)
            dayAvgs.append((weekday, avg, scores.count))
        }

        guard let best = dayAvgs.max(by: { $0.avg < $1.avg }),
              let worst = dayAvgs.min(by: { $0.avg < $1.avg }),
              dayAvgs.count >= 2 else {
            return []
        }

        let bestDayName = shortDayName(for: best.weekday)
        let worstDayName = shortDayName(for: worst.weekday)

        if best.avg - worst.avg > 0.3 {
            patterns.append("\(bestDayName)s are your strongest emotional day (avg: \(String(format: "%.1f", best.avg)))")
        }

        if worst.avg < -0.2 {
            patterns.append("\(worstDayName)s tend to be more challenging (avg: \(String(format: "%.1f", worst.avg)))")
        }

        return patterns
    }

    // MARK: - Streak Patterns

    func detectStreakPatterns(in entries: [Moment]) -> [String] {
        var patterns: [String] = []
        let calendar = Calendar.current

        var currentDate = calendar.startOfDay(for: Date())
        var streak = 0

        while true {
            let hasEntry = entries.contains { entry in
                calendar.isDate(entry.timestamp, inSameDayAs: currentDate)
            }

            if hasEntry {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = previousDay
            } else {
                if calendar.isDateInToday(currentDate) {
                    guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                    currentDate = previousDay
                    continue
                }
                break
            }
        }

        if streak >= 7 {
            patterns.append("You have an active \(streak)-day capture streak — impressive consistency!")
        } else if streak >= 3 {
            patterns.append("You're on a \(streak)-day capture streak. Keep it going!")
        }

        return patterns
    }

    // MARK: - Emotional Triggers (Keyword-based)

    func detectEmotionalTriggers(in entries: [Moment]) -> [String] {
        var patterns: [String] = []

        let journalEntries = entries.filter { $0.type == .journal && !$0.content.isEmpty }

        guard journalEntries.count >= 3 else { return [] }

        var keywordEmotions: [String: (keyword: String, emotion: EmotionCategory, scores: [Double])] = [:]

        let triggerKeywords = [
            "work": EmotionCategory.anger,
            "job": EmotionCategory.anger,
            "exercise": EmotionCategory.joy,
            "gym": EmotionCategory.joy,
            "run": EmotionCategory.joy,
            "walk": EmotionCategory.trust,
            "family": EmotionCategory.joy,
            "friend": EmotionCategory.joy,
            "alone": EmotionCategory.sadness,
            "lonely": EmotionCategory.sadness,
            "tired": EmotionCategory.sadness,
            "sleep": EmotionCategory.neutral,
            "stressed": EmotionCategory.fear,
            "anxious": EmotionCategory.fear,
            "happy": EmotionCategory.joy,
            "grateful": EmotionCategory.joy,
            "excited": EmotionCategory.anticipation,
            "worried": EmotionCategory.fear
        ]

        for entry in journalEntries {
            let lowercaseContent = entry.content.lowercased()

            for (keyword, emotion) in triggerKeywords {
                if lowercaseContent.contains(keyword) {
                    let existing = keywordEmotions[keyword] ?? (keyword, emotion, [])
                    keywordEmotions[keyword] = (keyword, emotion, existing.scores + [entry.emotionScore])
                }
            }
        }

        for (_, data) in keywordEmotions {
            guard data.scores.count >= 2 else { continue }
            let avgScore = data.scores.reduce(0, +) / Double(data.scores.count)
            let sentiment = analyzeSentiment(for: data.keyword)

            if abs(avgScore) > 0.2 || abs(sentiment) > 0.2 {
                let feeling = avgScore > 0.1 || sentiment > 0.1 ? "linked to positive feelings" : "linked to negative feelings"
                patterns.append("'\(data.keyword)' appears \(data.scores.count) times and is \(feeling)")
            }
        }

        return Array(patterns.prefix(4))
    }

    // MARK: - Trigger Word Analysis

    private func analyzeSentiment(for text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        let sentiment = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore).0
        return Double(sentiment?.rawValue ?? "0") ?? 0
    }

    // MARK: - Helpers

    private func averageScore(_ entries: [Moment]) -> Double {
        guard !entries.isEmpty else { return 0 }
        return entries.map(\.emotionScore).reduce(0, +) / Double(entries.count)
    }

    private func shortDayName(for weekday: Int) -> String {
        let days = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return weekday >= 1 && weekday <= 7 ? days[weekday] : "Day"
    }
}
