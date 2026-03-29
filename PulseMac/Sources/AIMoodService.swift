import Foundation
import NaturalLanguage

// MARK: - MoodSnapshot

/// A mood snapshot used for pattern detection in AIMoodService
struct MoodSnapshot: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let emotionScore: Double // -1.0 to 1.0
    let emotionTags: [EmotionTag]
    let note: String?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        emotionScore: Double,
        emotionTags: [EmotionTag] = [],
        note: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.emotionScore = emotionScore
        self.emotionTags = emotionTags
        self.note = note
    }
}

// MARK: - MoodAnalysis

/// Result of analyzing a single text input for mood
struct MoodAnalysis: Identifiable {
    let id = UUID()
    let primaryEmotion: EmotionCategory
    let valence: Double // -1.0 (negative) to 1.0 (positive)
    let energy: EnergyLevel
    let anxietyFlag: Bool
    let gratitudeFlag: Bool
    let emotionTags: [EmotionTag]

    enum EnergyLevel: String, Codable {
        case low, medium, high

        var displayName: String { rawValue.capitalized }
    }

    var valenceDescription: String {
        if valence > 0.5 { return "Very Positive" }
        if valence > 0.1 { return "Positive" }
        if valence > -0.1 { return "Neutral" }
        if valence > -0.5 { return "Negative" }
        return "Very Negative"
    }
}

// MARK: - MoodPatterns

/// Aggregated patterns detected across a collection of mood entries
struct MoodPatterns: Identifiable {
    let id = UUID()
    let timeOfDayCorrelations: [TimeOfDayCorrelation]
    let dayOfWeekCorrelations: [DayOfWeekCorrelation]
    let triggerCorrelations: [TriggerCorrelation]
    let streakInfo: StreakInfo?
    let overallInsight: String

    struct TimeOfDayCorrelation: Identifiable {
        let id = UUID()
        let period: Period
        let averageValence: Double
        let entryCount: Int
        let dominantEmotion: EmotionCategory

        enum Period: String, Codable, CaseIterable {
            case morning   // 5am–12pm
            case afternoon // 12pm–5pm
            case evening   // 5pm–10pm
            case night     // 10pm–5am

            var displayName: String { rawValue.capitalized }
        }
    }

    struct DayOfWeekCorrelation: Identifiable {
        let id = UUID()
        let weekday: Int // 1=Sun, 7=Sat
        let weekdayName: String
        let averageValence: Double
        let entryCount: Int
        let isStrongestDay: Bool
        let isWeakestDay: Bool
    }

    struct TriggerCorrelation: Identifiable {
        let id = UUID()
        let keyword: String
        let averageValence: Double
        let occurrences: Int
        let emotionalTone: EmotionalTone

        enum EmotionalTone: String, Codable {
            case positive, negative, neutral
        }
    }

    struct StreakInfo: Identifiable {
        let id = UUID()
        let currentStreak: Int // days
        let longestStreak: Int
        let streakStatus: Status

        enum Status: String, Codable {
            case active
            case broken
            case new
        }
    }
}

// MARK: - AIMoodService

final class AIMoodService: @unchecked Sendable {
    static let shared = AIMoodService()

    private let taggerQueue = DispatchQueue(label: "com.pulse.aimood.tagger", qos: .userInitiated)

    private init() {}

    // MARK: - Public API

    /// Analyze a text string and return structured mood analysis
    func analyzeMood(text: String) -> MoodAnalysis {
        let tagger = NLTagger(tagSchemes: [.sentimentScore, .nameType])
        tagger.string = text

        // Sentence-level sentiment
        var totalScore: Double = 0
        var sentenceCount = 0

        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .sentence,
            scheme: .sentimentScore,
            options: []
        ) { tag, _ in
            if let tag = tag, let score = Double(tag.rawValue) {
                totalScore += score
                sentenceCount += 1
            }
            return true
        }

        let valence = sentenceCount > 0 ? totalScore / Double(sentenceCount) : 0

        // Keyword-based emotion detection
        let tags = extractEmotionTags(from: text, baseScore: valence)

        // Energy estimation from punctuation/exclamation
        let energy = estimateEnergy(from: text)

        // Anxiety flag
        let anxietyFlag = detectAnxiety(text: text)

        // Gratitude flag
        let gratitudeFlag = detectGratitude(text: text)

        // Primary emotion from tags
        let primaryEmotion = tags.first?.category ?? emotionFromValence(valence)

        return MoodAnalysis(
            primaryEmotion: primaryEmotion,
            valence: valence,
            energy: energy,
            anxietyFlag: anxietyFlag,
            gratitudeFlag: gratitudeFlag,
            emotionTags: Array(tags.prefix(4))
        )
    }

    /// Detect patterns across a collection of mood entries
    func detectPatterns(entries: [MoodSnapshot]) -> MoodPatterns {
        guard !entries.isEmpty else {
            return MoodPatterns(
                timeOfDayCorrelations: [],
                dayOfWeekCorrelations: [],
                triggerCorrelations: [],
                streakInfo: nil,
                overallInsight: "Not enough data to detect patterns yet. Keep logging your mood!"
            )
        }

        let timeCorrelations = detectTimeOfDayCorrelations(in: entries)
        let dayCorrelations = detectDayOfWeekCorrelations(in: entries)
        let triggerCorrelations = detectTriggerCorrelations(in: entries)
        let streakInfo = computeStreakInfo(from: entries)
        let insight = generateOverallInsight(
            entries: entries,
            timeCorrelations: timeCorrelations,
            dayCorrelations: dayCorrelations
        )

        return MoodPatterns(
            timeOfDayCorrelations: timeCorrelations,
            dayOfWeekCorrelations: dayCorrelations,
            triggerCorrelations: triggerCorrelations,
            streakInfo: streakInfo,
            overallInsight: insight
        )
    }

    // MARK: - Private Helpers

    private func extractEmotionTags(from text: String, baseScore: Double) -> [EmotionTag] {
        var tags: [EmotionTag] = []
        let lower = text.lowercased()

        let emotionKeywords: [(keywords: [String], category: EmotionCategory)] = [
            (["happy", "joy", "excited", "wonderful", "amazing", "great", "love", "fantastic", "beautiful", "blessed", "delighted", "thrilled", "grateful", "pleased"], .joy),
            (["sad", "down", "depressed", "unhappy", "disappointed", "heartbroken", "grief", "sorrow", "miserable", "hopeless", "lonely", "empty", "upset"], .sadness),
            (["angry", "furious", "annoyed", "frustrated", "irritated", "mad", "rage", "bitter", "resentful"], .anger),
            (["scared", "afraid", "anxious", "worried", "nervous", "terrified", "panicked", "stressed", "uneasy", "apprehensive", "overwhelmed"], .fear),
            (["surprised", "amazed", "shocked", "astonished", "stunned", "unexpected"], .surprise),
            (["trust", "believe", "confident", "sure", "certain", "faith", "safe", "secure"], .trust),
            (["excited", "looking forward", "anticipate", "hope", "expect", "eager"], .anticipation),
            (["disgusted", "disgusting", "gross", "revolted", "repulsed"], .disgust),
        ]

        for (keywords, category) in emotionKeywords {
            for keyword in keywords {
                if lower.contains(keyword) {
                    let confidence = min(0.9, baseScore.magnitude + 0.4)
                    let tag = EmotionTag(category: category, confidence: confidence, label: keyword.capitalized)
                    if !tags.contains(where: { $0.category == category }) {
                        tags.append(tag)
                    }
                }
            }
        }

        // Fallback: pure sentiment-based tag
        if tags.isEmpty {
            let category = emotionFromValence(baseScore)
            tags.append(EmotionTag(category: category, confidence: abs(baseScore), label: category.displayName))
        }

        return tags
    }

    private func emotionFromValence(_ valence: Double) -> EmotionCategory {
        if valence > 0.3  { return .joy }
        if valence < -0.3 { return .sadness }
        return .neutral
    }

    private func estimateEnergy(from text: String) -> MoodAnalysis.EnergyLevel {
        let exclamationCount = text.filter { $0 == "!" }.count
        let questionCount = text.filter { $0 == "?" }.count
        let wordCount = text.split(separator: " ").count
        let totalChars = max(1, text.count)
        let uppercaseChars = text.filter { $0.isUppercase && $0.isLetter }.count
        let capsRatio: Double = Double(uppercaseChars) / Double(totalChars)

        let energyScore: Double = (Double(exclamationCount) * 0.15)
            + (Double(questionCount) * -0.05)
            + (capsRatio * 2.0)
            + (Double(wordCount) * 0.01)

        if energyScore > 0.4 { return .high }
        if energyScore > 0.1 { return .medium }
        return .low
    }

    private func detectAnxiety(text: String) -> Bool {
        let lower = text.lowercased()
        let anxietyKeywords = ["worried", "anxious", "nervous", "stressed", "overwhelmed", "scared", "fear", "panic", "uneasy", "apprehensive", "dread"]
        let count = anxietyKeywords.filter { lower.contains($0) }.count
        return count >= 1
    }

    private func detectGratitude(text: String) -> Bool {
        let lower = text.lowercased()
        let gratitudeKeywords = ["grateful", "thankful", "blessed", "appreciate", "fortunate", " grateful "]
        return gratitudeKeywords.contains { lower.contains($0) }
    }

    // MARK: - Pattern Detection

    private func detectTimeOfDayCorrelations(in entries: [MoodSnapshot]) -> [MoodPatterns.TimeOfDayCorrelation] {
        let calendar = Calendar.current

        var buckets: [MoodPatterns.TimeOfDayCorrelation.Period: [MoodSnapshot]] = [
            .morning: [], .afternoon: [], .evening: [], .night: []
        ]

        for entry in entries {
            let hour = calendar.component(.hour, from: entry.timestamp)
            let period: MoodPatterns.TimeOfDayCorrelation.Period
            switch hour {
            case 5..<12:  period = .morning
            case 12..<17: period = .afternoon
            case 17..<22: period = .evening
            default:      period = .night
            }
            buckets[period, default: []].append(entry)
        }

        return MoodPatterns.TimeOfDayCorrelation.Period.allCases.compactMap { period in
            let group = buckets[period, default: []]
            guard !group.isEmpty else { return nil }

            let avgValence = group.map(\.emotionScore).reduce(0, +) / Double(group.count)
            let dominantCategory = dominantEmotion(in: group)

            return MoodPatterns.TimeOfDayCorrelation(
                period: period,
                averageValence: avgValence,
                entryCount: group.count,
                dominantEmotion: dominantCategory
            )
        }
    }

    private func detectDayOfWeekCorrelations(in entries: [MoodSnapshot]) -> [MoodPatterns.DayOfWeekCorrelation] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"

        var weekdayBuckets: [Int: [MoodSnapshot]] = [:]

        for entry in entries {
            let weekday = calendar.component(.weekday, from: entry.timestamp)
            weekdayBuckets[weekday, default: []].append(entry)
        }

        var correlations: [MoodPatterns.DayOfWeekCorrelation] = []
        var dayAvgs: [(weekday: Int, avg: Double)] = []

        for (weekday, group) in weekdayBuckets where !group.isEmpty {
            let avg = group.map(\.emotionScore).reduce(0, +) / Double(group.count)
            dayAvgs.append((weekday, avg))
        }

        guard let maxAvg = dayAvgs.max(by: { $0.avg < $1.avg }),
              let minAvg = dayAvgs.min(by: { $0.avg < $1.avg }) else {
            return []
        }

        for (weekday, group) in weekdayBuckets where !group.isEmpty {
            let avg = group.map(\.emotionScore).reduce(0, +) / Double(group.count)
            var dateComponents = DateComponents()
            dateComponents.weekday = weekday
            let fakeDate = calendar.nextDate(after: Date(), matching: dateComponents, matchingPolicy: .nextTime) ?? Date()
            let dayName = formatter.string(from: fakeDate)

            correlations.append(MoodPatterns.DayOfWeekCorrelation(
                weekday: weekday,
                weekdayName: dayName,
                averageValence: avg,
                entryCount: group.count,
                isStrongestDay: weekday == maxAvg.weekday,
                isWeakestDay: weekday == minAvg.weekday
            ))
        }

        return correlations.sorted { $0.weekday < $1.weekday }
    }

    private func detectTriggerCorrelations(in entries: [MoodSnapshot]) -> [MoodPatterns.TriggerCorrelation] {
        let triggerKeywords: [(keywords: [String], tone: MoodPatterns.TriggerCorrelation.EmotionalTone)] = [
            (["work", "job", "deadline", "meeting", "boss"], .negative),
            (["exercise", "gym", "run", "workout", "yoga", "walk"], .positive),
            (["family", "parents", "mom", "dad", "brother", "sister"], .positive),
            (["friend", "friends", "hangout", "dinner", "party"], .positive),
            (["alone", "lonely", "isolated"], .negative),
            (["sleep", "tired", "exhausted", "nap"], .neutral),
            (["stressed", "anxious", "worried"], .negative),
            (["happy", "joy", "excited", "love"], .positive),
            (["grateful", "thankful", "blessed"], .positive),
            (["sad", "down", "depressed"], .negative),
        ]

        var keywordScores: [String: (tone: MoodPatterns.TriggerCorrelation.EmotionalTone, scores: [Double])] = [:]

        for entry in entries {
            guard let note = entry.note, !note.isEmpty else { continue }
            let lower = note.lowercased()

            for (keywords, tone) in triggerKeywords {
                for keyword in keywords {
                    if lower.contains(keyword) {
                        let existing = keywordScores[keyword] ?? (tone, [])
                        keywordScores[keyword] = (tone, existing.scores + [entry.emotionScore])
                    }
                }
            }
        }

        return keywordScores.compactMap { (keyword, data) in
            guard data.scores.count >= 2 else { return nil }
            let avgValence = data.scores.reduce(0, +) / Double(data.scores.count)
            return MoodPatterns.TriggerCorrelation(
                keyword: keyword,
                averageValence: avgValence,
                occurrences: data.scores.count,
                emotionalTone: avgValence > 0.1 ? .positive : (avgValence < -0.1 ? .negative : .neutral)
            )
        }.sorted { $0.occurrences > $1.occurrences }
         .prefix(5)
         .map { $0 }
    }

    private func computeStreakInfo(from entries: [MoodSnapshot]) -> MoodPatterns.StreakInfo? {
        let calendar = Calendar.current
        var datesWithEntries = Set<Date>()

        for entry in entries {
            datesWithEntries.insert(calendar.startOfDay(for: entry.timestamp))
        }

        let sortedDates = datesWithEntries.sorted(by: >)
        guard !sortedDates.isEmpty else { return nil }

        var currentStreak = 0
        var longestStreak = 0
        var streak = 0
        var previousDate: Date?

        for date in sortedDates {
            if let prev = previousDate {
                let diff = calendar.dateComponents([.day], from: date, to: prev).day ?? 0
                if diff == 1 {
                    streak += 1
                } else {
                    longestStreak = max(longestStreak, streak)
                    streak = 1
                }
            } else {
                streak = 1
            }
            previousDate = date
        }
        longestStreak = max(longestStreak, streak)

        // Check if current streak is still active (includes today or yesterday)
        let today = calendar.startOfDay(for: Date())
        let includesToday = datesWithEntries.contains(today)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let includesYesterday = datesWithEntries.contains(yesterday)

        let status: MoodPatterns.StreakInfo.Status
        if includesToday || includesYesterday {
            // Recompute current streak
            currentStreak = computeCurrentStreak(dates: datesWithEntries, calendar: calendar)
            status = .active
        } else {
            currentStreak = 0
            status = .broken
        }

        return MoodPatterns.StreakInfo(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            streakStatus: status
        )
    }

    private func computeCurrentStreak(dates: Set<Date>, calendar: Calendar) -> Int {
        let sorted = dates.sorted(by: >)
        var streak = 0
        var expectedDate = calendar.startOfDay(for: Date())

        for date in sorted {
            if calendar.isDate(date, inSameDayAs: expectedDate) {
                streak += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
            } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate) {
                // Allow yesterday as start of streak
                expectedDate = date
                streak += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
            } else {
                break
            }
        }

        return streak
    }

    private func dominantEmotion(in entries: [MoodSnapshot]) -> EmotionCategory {
        var categoryScores: [EmotionCategory: Double] = [:]
        for entry in entries {
            for tag in entry.emotionTags {
                categoryScores[tag.category, default: 0] += tag.confidence
            }
        }
        return categoryScores.max(by: { $0.value < $1.value })?.key ?? .neutral
    }

    private func generateOverallInsight(
        entries: [MoodSnapshot],
        timeCorrelations: [MoodPatterns.TimeOfDayCorrelation],
        dayCorrelations: [MoodPatterns.DayOfWeekCorrelation]
    ) -> String {
        guard !entries.isEmpty else {
            return "Start logging your mood to unlock personalized insights."
        }

        var insights: [String] = []

        // Best time of day
        if let best = timeCorrelations.max(by: { $0.averageValence < $1.averageValence }),
           let worst = timeCorrelations.min(by: { $0.averageValence < $1.averageValence }),
           best.averageValence - worst.averageValence > 0.3 {
            insights.append("You're emotionally strongest in the \(best.period.displayName.lowercased()) (avg: \(scoreLabel(best.averageValence))).")
        }

        // Best day of week
        if let strongest = dayCorrelations.first(where: { $0.isStrongestDay }),
           strongest.averageValence > 0.2 {
            insights.append("\(strongest.weekdayName)s are your peak emotional day.")
        }

        if let weakest = dayCorrelations.first(where: { $0.isWeakestDay }),
           weakest.averageValence < -0.2 {
            insights.append("\(weakest.weekdayName)s tend to be more challenging.")
        }

        // Capture frequency
        if entries.count >= 14 {
            let avgPerDay = Double(entries.count) / 14.0
            if avgPerDay > 1 {
                insights.append("You're capturing \(String(format: "%.1f", avgPerDay)) moments per day on average — excellent engagement!")
            }
        }

        if insights.isEmpty {
            let avgValence = entries.map(\.emotionScore).reduce(0, +) / Double(entries.count)
            insights.append("Your overall emotional tone is \(scoreLabel(avgValence)). Keep logging for sharper patterns.")
        }

        return insights.joined(separator: " ")
    }

    private func scoreLabel(_ score: Double) -> String {
        if score > 0.5  { return "very positive" }
        if score > 0.1  { return "positive" }
        if score > -0.1 { return "neutral" }
        if score > -0.5 { return "negative" }
        return "very negative"
    }
}
