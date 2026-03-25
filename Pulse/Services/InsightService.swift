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

    // MARK: - R2: Deep AI Insights

    func generateCorrelationInsights(correlations: [Correlation]) -> [Insight] {
        return correlations.map { correlation in
            Insight(
                title: correlation.title,
                body: correlation.description,
                category: .correlation,
                supportingDataPointCount: correlation.dataPointCount,
                emotionScore: correlation.strength
            )
        }
    }

    func generateTriggerInsights(triggers: [TriggerInsight]) -> [Insight] {
        return triggers.map { trigger in
            Insight(
                title: "Pattern: \(trigger.trigger)",
                body: trigger.description,
                category: .pattern,
                supportingDataPointCount: trigger.frequency,
                emotionScore: trigger.confidence
            )
        }
    }

    func generatePredictionInsights(prediction: MoodPrediction) -> Insight {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        let dayName = dayFormatter.string(from: prediction.predictedDate)

        return Insight(
            title: "Tomorrow looks like \(prediction.similarDay ?? "a typical day")",
            body: "\(prediction.reason). Confidence: \(Int(prediction.confidence * 100))%",
            category: .general,
            supportingDataPointCount: 1,
            emotionScore: prediction.predictedScore
        )
    }

    func generateWeeklyNarrativeReport(report: WeeklyReport) -> Insight {
        return Insight(
            title: "Your Week in Review",
            body: report.narrative,
            category: .general,
            supportingDataPointCount: report.momentCount,
            emotionScore: report.averageScore
        )
    }

    // MARK: - R2: Health Correlation Insights

    func generateHealthCorrelationInsight(
        healthCorrelation: Correlation,
        moments: [Moment],
        healthData: [Date: HealthData]
    ) -> Insight? {
        guard healthCorrelation.correlationType == .health else { return nil }

        let calendar = Calendar.current

        var goodHealthGoodMood = 0
        var goodHealthBadMood = 0
        var poorHealthGoodMood = 0
        var poorHealthBadMood = 0

        for moment in moments {
            let dayStart = calendar.startOfDay(for: moment.timestamp)
            guard let health = healthData[dayStart] else { continue }

            let healthScore = health.normalizedScore
            let emotionScore = (moment.emotionScore + 1) / 2 // normalize to 0-1

            if healthScore > 0.6 {
                if emotionScore > 0.5 {
                    goodHealthGoodMood += 1
                } else {
                    goodHealthBadMood += 1
                }
            } else if healthScore < 0.4 {
                if emotionScore > 0.5 {
                    poorHealthGoodMood += 1
                } else {
                    poorHealthBadMood += 1
                }
            }
        }

        let total = goodHealthGoodMood + goodHealthBadMood + poorHealthGoodMood + poorHealthBadMood
        guard total >= 4 else { return nil }

        let goodDaysCorrelation = Double(goodHealthGoodMood + poorHealthBadMood) / Double(total)

        let body: String
        if goodDaysCorrelation > 0.6 {
            body = "There's a \(Int(goodDaysCorrelation * 100))% alignment between your physical health and emotional wellbeing. When your body feels good, your mood follows."
        } else if goodDaysCorrelation > 0.4 {
            body = "Your emotional state doesn't always track with physical health. \(Int((1-goodDaysCorrelation)*100))% of the time they diverge — you're more complex than a health metric."
        } else {
            body = "Interestingly, your emotional wellbeing sometimes moves opposite to your physical health metrics. Rest days can be emotionally valuable too."
        }

        return Insight(
            title: "Body & Mind Connection",
            body: body,
            category: .correlation,
            supportingDataPointCount: total,
            emotionScore: (goodDaysCorrelation * 2) - 1
        )
    }
}
