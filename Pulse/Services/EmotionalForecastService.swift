import Foundation
import SwiftUI

// MARK: - Emotional Forecast

struct EmotionalForecast: Identifiable {
    let id = UUID()
    let date: Date
    let predictedEmotions: [EmotionTag]
    let confidence: Double // 0.0 to 1.0
    let stressRisk: StressRisk
    let recommendation: String
}

enum StressRisk: String, CaseIterable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case critical = "Critical"

    var color: Color {
        switch self {
        case .low: return Theme.Colors.calmSage
        case .moderate: return Theme.Colors.gentleGold
        case .high: return Theme.Colors.mutedRose
        case .critical: return Theme.Colors.deepEmber
        }
    }

    var icon: String {
        switch self {
        case .low: return "leaf.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .high: return "flame.fill"
        case .critical: return "bolt.fill"
        }
    }
}

@MainActor
final class EmotionalForecastService: ObservableObject {
    static let shared = EmotionalForecastService()

    @Published var forecast: [EmotionalForecast] = []
    @Published var stressAlerts: [StressAlert] = []

    init() {}

    func generateForecast(from moments: [Moment]) async {
        var forecasts: [EmotionalForecast] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Group moments by day
        let momentsByDay = Dictionary(grouping: moments) { moment in
            calendar.startOfDay(for: moment.timestamp)
        }

        // Analyze patterns from last 30 days
        let patterns = analyzePatterns(from: momentsByDay)

        // Generate forecast for next 30 days
        for dayOffset in 0..<30 {
            guard let forecastDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }

            let predictedEmotions = predictEmotions(for: forecastDate, basedOn: patterns, momentsByDay: momentsByDay)
            let stressRisk = predictStressRisk(for: forecastDate, basedOn: patterns, momentsByDay: momentsByDay)
            let confidence = calculateConfidence(for: forecastDate, momentsByDay: momentsByDay)
            let recommendation = generateRecommendation(stressRisk: stressRisk, predictedEmotions: predictedEmotions, date: forecastDate)

            let forecast = EmotionalForecast(
                date: forecastDate,
                predictedEmotions: predictedEmotions,
                confidence: confidence,
                stressRisk: stressRisk,
                recommendation: recommendation
            )
            forecasts.append(forecast)
        }

        forecast = forecasts
        generateStressAlerts()
    }

    private func analyzePatterns(from momentsByDay: [Date: [Moment]]) -> EmotionalPatterns {
        var dayOfWeekEmotions: [Int: [EmotionTag]] = [:] // 1=Sunday
        var timePatterns: [TimeOfDay: [EmotionTag]] = [:]

        for (day, moments) in momentsByDay {
            let dow = Calendar.current.component(.weekday, from: day)
            let tod = timeOfDay(for: day)

            dayOfWeekEmotions[dow, default: []].append(contentsOf: moments.flatMap { $0.emotionTags })
            timePatterns[tod, default: []].append(contentsOf: moments.flatMap { $0.emotionTags })
        }

        // Detect stress precursors
        var stressPrecursors: [String] = []
        for (day, moments) in momentsByDay {
            if hasStressPrecursor(in: moments) {
                let dow = Calendar.current.component(.weekday, from: day)
                stressPrecursors.append("Weekday \(dow)")
            }
        }

        return EmotionalPatterns(
            dayOfWeekEmotions: dayOfWeekEmotions,
            timePatterns: timePatterns,
            stressPrecursors: stressPrecursors,
            averageEmotionalBaseline: calculateBaseline(from: momentsByDay)
        )
    }

    private func timeOfDay(for date: Date) -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night
        }
    }

    enum TimeOfDay: String {
        case morning, afternoon, evening, night
    }

    private func hasStressPrecursor(in moments: [Moment]) -> Bool {
        let emotions = moments.flatMap { $0.emotionTags }
        let hasAnxiety = emotions.contains { $0.label.lowercased().contains("anxiety") || $0.label.lowercased().contains("stressed") }
        let hasLowEnergy = emotions.contains { $0.label.lowercased().contains("tired") || $0.label.lowercased().contains("exhausted") }
        return hasAnxiety || hasLowEnergy
    }

    private func predictEmotions(for date: Date, basedOn patterns: EmotionalPatterns, momentsByDay: [Date: [Moment]]) -> [EmotionTag] {
        let dow = Calendar.current.component(.weekday, from: date)

        // Get emotions for this day of week from history
        var predictedEmotions = patterns.dayOfWeekEmotions[dow] ?? []

        // If not enough data, use baseline
        if predictedEmotions.count < 2 {
            predictedEmotions = patterns.averageEmotionalBaseline
        }

        // Cap at 3 emotions
        return Array(predictedEmotions.prefix(3))
    }

    private func predictStressRisk(for date: Date, basedOn patterns: EmotionalPatterns, momentsByDay: [Date: [Moment]]) -> StressRisk {
        let dow = Calendar.current.component(.weekday, from: date)

        // Check if this weekday historically has stress
        let hasStressHistory = patterns.stressPrecursors.contains { $0.contains("Weekday \(dow)") }

        // Check recent trend (last 7 days)
        let calendar = Calendar.current
        let recentDays = (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: date) }
        var recentStressCount = 0
        for day in recentDays {
            if let moments = momentsByDay[day], hasStressPrecursor(in: moments) {
                recentStressCount += 1
            }
        }

        if recentStressCount >= 5 || (hasStressHistory && recentStressCount >= 3) {
            return .critical
        } else if recentStressCount >= 3 {
            return .high
        } else if recentStressCount >= 1 {
            return .moderate
        } else {
            return .low
        }
    }

    private func calculateConfidence(for date: Date, momentsByDay: [Date: [Moment]]) -> Double {
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: date)

        // Calculate how much data we have for this day of week
        let dataPointsForDow = momentsByDay.filter { calendar.component(.weekday, from: $0.key) == dayOfWeek }.count

        if dataPointsForDow >= 4 { return 0.8 }
        else if dataPointsForDow >= 2 { return 0.6 }
        else if dataPointsForDow >= 1 { return 0.4 }
        else { return 0.2 }
    }

    private func calculateBaseline(from momentsByDay: [Date: [Moment]]) -> [EmotionTag] {
        let allMoments = momentsByDay.values.flatMap { $0 }
        var emotionCounts: [String: (count: Int, totalConfidence: Double)] = [:]

        for moment in allMoments {
            for emotion in moment.emotionTags {
                let existing = emotionCounts[emotion.label] ?? (0, 0)
                emotionCounts[emotion.label] = (existing.count + 1, existing.totalConfidence + emotion.confidence)
            }
        }

        let sorted = emotionCounts.sorted { $0.value.count > $1.value.count }
        return sorted.prefix(3).map { EmotionTag(id: UUID(), category: EmotionCategory.neutral, confidence: $0.value.totalConfidence / Double($0.value.count), label: $0.key) }
    }

    private func generateRecommendation(stressRisk: StressRisk, predictedEmotions: [EmotionTag], date: Date) -> String {
        if stressRisk == .critical {
            return "High stress risk detected. Consider taking tomorrow light — short walks, deep breathing, or saying no to extra commitments."
        } else if stressRisk == .high {
            return "Elevated stress possible. Build in some recovery time and avoid scheduling high-pressure activities."
        } else if stressRisk == .moderate {
            return "A balanced day ahead. Good for tackling moderate tasks, but don't overcommit."
        } else {
            let topEmotion = predictedEmotions.first?.label ?? "calm"
            if topEmotion.lowercased().contains("happy") || topEmotion.lowercased().contains("energ") {
                return "Looking like a good day! Great for creative work, social activities, or starting something new."
            } else {
                return "A peaceful day predicted. Perfect for reflection, planning, or gentle activities."
            }
        }
    }

    private func generateStressAlerts() {
        var alerts: [StressAlert] = []

        // Check next 7 days for high/critical stress risk
        let upcomingStress = forecast.prefix(7).filter { $0.stressRisk == .high || $0.stressRisk == .critical }

        for forecast in upcomingStress {
            let alert = StressAlert(
                id: UUID(),
                date: forecast.date,
                risk: forecast.stressRisk,
                message: "Stress risk \(forecast.stressRisk.rawValue.lowercased()) predicted for \(forecast.date.formatted(date: .abbreviated, time: .omitted))",
                insight: forecast.recommendation
            )
            alerts.append(alert)
        }

        stressAlerts = alerts
    }
}

struct EmotionalPatterns {
    let dayOfWeekEmotions: [Int: [EmotionTag]]
    let timePatterns: [EmotionalForecastService.TimeOfDay: [EmotionTag]]
    let stressPrecursors: [String]
    let averageEmotionalBaseline: [EmotionTag]
}

struct StressAlert: Identifiable {
    let id: UUID
    let date: Date
    let risk: StressRisk
    let message: String
    let insight: String
}
