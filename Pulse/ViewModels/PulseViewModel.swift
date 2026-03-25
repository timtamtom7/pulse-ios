import Foundation
import SwiftUI

@Observable
final class PulseViewModel: @unchecked Sendable {
    var weeklyInsight: Insight?
    var recentMoments: [Moment] = []
    var weeklyMoodRing: [EmotionTag] = []
    var currentStreak: Int = 0
    var isLoading = false
    var errorMessage: String?

    private let database = DatabaseService.shared

    init() {
        loadData()
    }

    func loadData() {
        isLoading = true
        errorMessage = nil

        let allMoments = database.fetchAllMoments()
        recentMoments = Array(allMoments.prefix(3))
        currentStreak = calculateStreak(from: allMoments)
        generateWeeklyInsightFromMoments(allMoments)
        isLoading = false
    }

    private func generateWeeklyInsightFromMoments(_ moments: [Moment]) {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentMoments = moments.filter { $0.timestamp >= weekAgo }

        let insight = InsightService.shared.generateWeeklyInsight(moments: recentMoments)
        if let insight = insight {
            try? database.insertInsight(insight)
            weeklyInsight = insight
        } else if recentMoments.isEmpty {
            weeklyInsight = Insight(
                title: "Start your emotional journey",
                body: "Capture a moment to begin discovering your emotional patterns. Pulse works best with regular reflection.",
                category: .general
            )
        }

        generateMoodRing(from: recentMoments)
    }

    private func generateMoodRing(from moments: [Moment]) {
        var emotionFrequency: [EmotionCategory: Double] = [:]

        for moment in moments {
            for tag in moment.emotionTags {
                emotionFrequency[tag.category, default: 0] += tag.confidence
            }
        }

        let sorted = emotionFrequency.sorted { $0.value > $1.value }
        weeklyMoodRing = sorted.prefix(5).map { category, confidence in
            EmotionTag(category: category, confidence: confidence / Double(max(moments.count, 1)))
        }
    }

    private func calculateStreak(from moments: [Moment]) -> Int {
        guard !moments.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        while true {
            let hasMoments = moments.contains { moment in
                calendar.isDate(moment.timestamp, inSameDayAs: currentDate)
            }

            if hasMoments {
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

        return streak
    }

    func refresh() {
        loadData()
    }
}
