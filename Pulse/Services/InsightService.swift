import Foundation

final class InsightService: @unchecked Sendable {
    static let shared = InsightService()

    private init() {}

    func generateWeeklyInsight(moments: [Moment]) -> Insight? {
        guard moments.count >= 3 else { return nil }

        let calendar = Calendar.current
        var dayOfWeekCounts: [Int: [Moment]] = [:]

        for moment in moments {
            let weekday = calendar.component(.weekday, from: moment.timestamp)
            dayOfWeekCounts[weekday, default: []].append(moment)
        }

        var dayScores: [(weekday: Int, score: Double)] = []
        for (weekday, dayMoments) in dayOfWeekCounts {
            let avgScore = dayMoments.map(\.emotionScore).reduce(0, +) / Double(dayMoments.count)
            dayScores.append((weekday, avgScore))
        }

        guard let happiestDay = dayScores.max(by: { $0.score < $1.score }) else { return nil }

        let dayName = dayName(for: happiestDay.weekday)

        let category: InsightCategory
        let body: String

        if happiestDay.score > 0.5 {
            category = .achievement
            body = "Your emotional wellbeing peaks on \(dayName)s. Consider scheduling important activities on this day to take advantage of your natural positivity."
        } else if happiestDay.score > 0.1 {
            category = .pattern
            body = "You tend to feel better on \(dayName)s. This could be due to social activities, work patterns, or personal routines."
        } else if happiestDay.score < -0.3 {
            category = .concern
            body = "You often feel more stressed or negative on \(dayName)s. It might be worth examining what happens on these days."
        } else {
            category = .pattern
            body = "Your emotional state is relatively consistent on \(dayName)s. Keep doing what works!"
        }

        return Insight(
            title: "You feel best on \(dayName)s",
            body: body,
            category: category,
            supportingDataPointCount: dayOfWeekCounts[happiestDay.weekday]?.count ?? 0,
            emotionScore: happiestDay.score
        )
    }

    func generateStreakInsight(currentStreak: Int) -> Insight {
        Insight(
            title: "\(currentStreak)-day reflection streak!",
            body: "You've been capturing moments for \(currentStreak) days in a row. This consistency helps Pulse understand your emotional patterns better.",
            category: .achievement,
            emotionScore: 0.8
        )
    }

    private func dayName(for weekday: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let symbols = formatter.shortWeekdaySymbols ?? []
        guard weekday >= 1 && weekday <= symbols.count else { return "this day" }
        return symbols[weekday - 1]
    }

    func generateTimeBasedInsights(moments: [Moment]) -> [Insight] {
        var insights: [Insight] = []

        let calendar = Calendar.current
        var hourBuckets: [Int: [Moment]] = [:]

        for moment in moments {
            let hour = calendar.component(.hour, from: moment.timestamp)
            let bucket = hour / 6
            hourBuckets[bucket, default: []].append(moment)
        }

        for (bucket, bucketMoments) in hourBuckets {
            guard bucketMoments.count >= 2 else { continue }
            let avgScore = bucketMoments.map(\.emotionScore).reduce(0, +) / Double(bucketMoments.count)

            if avgScore > 0.4 {
                let timeLabel = bucketLabel(for: bucket)
                insights.append(Insight(
                    title: "Your \(timeLabel) energy is high",
                    body: "You consistently feel positive during your \(timeLabel). This is a great time for creative work or social connections.",
                    category: .pattern,
                    supportingDataPointCount: bucketMoments.count,
                    emotionScore: avgScore
                ))
            }
        }

        return insights
    }

    private func bucketLabel(for bucket: Int) -> String {
        switch bucket {
        case 0: return "early morning"
        case 1: return "late morning"
        case 2: return "afternoon"
        case 3: return "evening"
        default: return "daily"
        }
    }
}
