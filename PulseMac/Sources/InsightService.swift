import Foundation
import EventKit

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

    func generateDayInsight(for dayMoments: [Moment]) -> Insight? {
        guard !dayMoments.isEmpty else { return nil }

        let avgScore = dayMoments.map(\.emotionScore).reduce(0, +) / Double(dayMoments.count)

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let dayName = formatter.string(from: dayMoments.first?.timestamp ?? Date())

        let category: InsightCategory
        let title: String

        if avgScore > 0.5 {
            category = .achievement
            title = "Great day on \(dayName)"
        } else if avgScore > 0.1 {
            category = .pattern
            title = "Good day on \(dayName)"
        } else if avgScore < -0.3 {
            category = .concern
            title = "Tough day on \(dayName)"
        } else {
            category = .pattern
            title = "\(dayName) summary"
        }

        return Insight(
            title: title,
            body: "You captured \(dayMoments.count) moment(s) today.",
            category: category,
            supportingDataPointCount: dayMoments.count,
            emotionScore: avgScore
        )
    }

    private func dayName(for weekday: Int) -> String {
        let days = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return weekday >= 1 && weekday <= 7 ? days[weekday] : "that day"
    }
}
