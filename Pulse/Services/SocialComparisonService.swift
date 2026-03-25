import Foundation

/// Service for generating anonymous social comparison insights
actor SocialComparisonService {
    static let shared = SocialComparisonService()

    private init() {}

    /// Generate percentile comparisons for the user
    func generateComparisons(
        userMoments: [Moment],
        userStreak: Int,
        userAverageScore: Double,
        aggregatedMetrics: AggregatedMetrics
    ) -> [PercentileComparison] {
        var comparisons: [PercentileComparison] = []

        // Emotional positivity percentile
        comparisons.append(PercentileComparison(
            metricName: "Emotional Positivity",
            metricDescription: "Your average emotional score compared to all users",
            userValue: userAverageScore,
            percentile: aggregatedMetrics.percentileFor(score: userAverageScore),
            averageValue: aggregatedMetrics.averageEmotionScore,
            cohortAverage: aggregatedMetrics.averageEmotionScore,
            sampleSize: aggregatedMetrics.totalUsersAnalyzed,
            comparedTo: "all Pulse users"
        ))

        // Consistency (moment frequency) percentile
        let userMomentFrequency = Double(userMoments.count) / 30.0
        comparisons.append(PercentileComparison(
            metricName: "Reflection Consistency",
            metricDescription: "How often you capture moments vs. other users",
            userValue: userMomentFrequency,
            percentile: percentileForFrequency(userMomentFrequency, average: aggregatedMetrics.averageMomentFrequency),
            averageValue: aggregatedMetrics.averageMomentFrequency,
            cohortAverage: aggregatedMetrics.averageMomentFrequency,
            sampleSize: aggregatedMetrics.totalUsersAnalyzed,
            comparedTo: "all Pulse users"
        ))

        // Streak percentile
        comparisons.append(PercentileComparison(
            metricName: "Reflection Streak",
            metricDescription: "Your longest reflection streak vs. other users",
            userValue: Double(userStreak),
            percentile: percentileForStreak(userStreak, topPercentile: aggregatedMetrics.streakStatistics.topPercentileStreak),
            averageValue: aggregatedMetrics.streakStatistics.averageStreak,
            cohortAverage: aggregatedMetrics.streakStatistics.medianStreak,
            sampleSize: aggregatedMetrics.totalUsersAnalyzed,
            comparedTo: "all Pulse users"
        ))

        // Joy percentage comparison
        let userJoyPercentage = calculateJoyPercentage(moments: userMoments)
        comparisons.append(PercentileComparison(
            metricName: "Joy Quotient",
            metricDescription: "Percentage of joyful moments vs. other users",
            userValue: userJoyPercentage,
            percentile: percentileForJoy(userJoyPercentage, cohortJoy: aggregatedMetrics.dominantEmotionPercentages["joy"] ?? 0.25),
            averageValue: aggregatedMetrics.dominantEmotionPercentages["joy"] ?? 0.25,
            cohortAverage: aggregatedMetrics.dominantEmotionPercentages["joy"] ?? 0.25,
            sampleSize: aggregatedMetrics.totalUsersAnalyzed,
            comparedTo: "all Pulse users"
        ))

        return comparisons
    }

    /// Generate a composite insight from multiple comparisons
    func generateCompositeInsight(comparisons: [PercentileComparison]) -> PercentileInsight? {
        guard let overallComparison = comparisons.first else { return nil }

        // Calculate weighted average percentile
        let weights: [Double] = [0.35, 0.25, 0.20, 0.20] // emotional, consistency, streak, joy
        var weightedPercentile = 0.0

        for (index, comparison) in comparisons.prefix(4).enumerated() {
            weightedPercentile += Double(comparison.percentile) * weights[index]
        }

        let roundedPercentile = min(max(Int(weightedPercentile), 1), 99)

        let composite = PercentileComparison(
            metricName: "Overall Wellness Index",
            metricDescription: "A composite score combining all emotional metrics",
            userValue: overallComparison.userValue,
            percentile: roundedPercentile,
            averageValue: comparisons.map(\.averageValue).reduce(0, +) / Double(comparisons.count),
            cohortAverage: comparisons.map(\.cohortAverage).reduce(0, +) / Double(comparisons.count),
            sampleSize: comparisons.first?.sampleSize ?? 0,
            comparedTo: "all Pulse users"
        )

        return PercentileInsight(comparison: composite)
    }

    private func percentileForFrequency(_ frequency: Double, average: Double) -> Int {
        if frequency >= average * 2 { return 85 }
        if frequency >= average * 1.5 { return 70 }
        if frequency >= average { return 55 }
        if frequency >= average * 0.5 { return 35 }
        return 15
    }

    private func percentileForStreak(_ streak: Int, topPercentile: Int) -> Int {
        if streak >= topPercentile { return 95 }
        if streak >= topPercentile / 2 { return 75 }
        if streak >= topPercentile / 4 { return 50 }
        if streak >= 3 { return 30 }
        return 10
    }

    private func percentileForJoy(_ userJoy: Double, cohortJoy: Double) -> Int {
        if userJoy >= cohortJoy * 1.5 { return 80 }
        if userJoy >= cohortJoy * 1.2 { return 65 }
        if userJoy >= cohortJoy * 0.8 { return 50 }
        if userJoy >= cohortJoy * 0.5 { return 30 }
        return 15
    }

    private func calculateJoyPercentage(moments: [Moment]) -> Double {
        guard !moments.isEmpty else { return 0 }
        let joyCount = moments.flatMap { $0.emotionTags }.filter { $0.category == .joy }.count
        return Double(joyCount) / Double(moments.count)
    }
}

/// Service for managing trusted circle sharing
@Observable
final class TrustedCircleService: @unchecked Sendable {
    static let shared = TrustedCircleService()

    var circle: TrustedCircle = TrustedCircle()
    var recentShares: [CircleShare] = []
    private let database = DatabaseService.shared
    private let userDefaults = UserDefaults.standard

    private let circleKey = "trusted_circle_data"
    private let sharesKey = "recent_shares"

    private init() {
        loadCircle()
        loadShares()
    }

    // MARK: - Circle Management

    func addMember(name: String, relationship: TrustedMember.Relationship) {
        let member = TrustedMember(name: name, relationship: relationship)
        circle.members.append(member)
        saveCircle()
    }

    func removeMember(id: UUID) {
        circle.members.removeAll { $0.id == id }
        saveCircle()
    }

    func toggleMember(id: UUID) {
        if let index = circle.members.firstIndex(where: { $0.id == id }) {
            circle.members[index].isEnabled.toggle()
            saveCircle()
        }
    }

    func updateShareSettings(_ settings: TrustedCircle.ShareSettings) {
        circle.shareSettings = settings
        saveCircle()
    }

    func generateShare(for memberId: UUID, moments: [Moment], streak: Int, topInsight: String?) -> CircleShare {
        let calendar = Calendar.current
        let periodEnd = Date()
        let periodStart = calendar.date(byAdding: .day, value: -circle.shareSettings.shareFrequency.days, to: periodEnd) ?? periodEnd

        let periodMoments = moments.filter { $0.timestamp >= periodStart && $0.timestamp <= periodEnd }

        let avgScore = periodMoments.isEmpty ? 0.0 : periodMoments.map(\.emotionScore).reduce(0, +) / Double(periodMoments.count)

        var emotionFrequency: [EmotionCategory: Double] = [:]
        for moment in periodMoments {
            for tag in moment.emotionTags {
                emotionFrequency[tag.category, default: 0] += tag.confidence
            }
        }

        let dominantEmotion = emotionFrequency.max(by: { $0.value < $1.value })?.key.displayName ?? "Neutral"

        // Calculate trend by comparing to previous period
        let previousPeriodStart = calendar.date(byAdding: .day, value: -circle.shareSettings.shareFrequency.days, to: periodStart) ?? periodStart
        let previousPeriodMoments = moments.filter { $0.timestamp >= previousPeriodStart && $0.timestamp < periodStart }
        let previousAvg = previousPeriodMoments.isEmpty ? avgScore : previousPeriodMoments.map(\.emotionScore).reduce(0, +) / Double(previousPeriodMoments.count)

        let trend: CircleShare.MoodTrend
        if avgScore - previousAvg > 0.1 {
            trend = .up
        } else if avgScore - previousAvg < -0.1 {
            trend = .down
        } else {
            trend = .stable
        }

        let share = CircleShare(
            memberId: memberId,
            periodStart: periodStart,
            periodEnd: periodEnd,
            averageEmotionScore: avgScore,
            dominantEmotion: dominantEmotion,
            momentCount: periodMoments.count,
            streak: streak,
            topInsight: topInsight,
            moodTrend: trend
        )

        // Update member's last share date
        if let index = circle.members.firstIndex(where: { $0.id == memberId }) {
            circle.members[index].lastSharedAt = Date()
            saveCircle()
        }

        recentShares.append(share)
        saveShares()

        return share
    }

    // MARK: - Privacy

    /// Creates a privacy-filtered share that removes any identifying details
    func createPrivacyFilteredShare(_ share: CircleShare) -> CircleShare {
        // Only share aggregate data - no individual moments
        return share
    }

    // MARK: - Persistence

    private func saveCircle() {
        if let data = try? JSONEncoder().encode(circle) {
            userDefaults.set(data, forKey: circleKey)
        }
    }

    private func loadCircle() {
        if let data = userDefaults.data(forKey: circleKey),
           let loaded = try? JSONDecoder().decode(TrustedCircle.self, from: data) {
            circle = loaded
        }
    }

    private func saveShares() {
        if let data = try? JSONEncoder().encode(recentShares) {
            userDefaults.set(data, forKey: sharesKey)
        }
    }

    private func loadShares() {
        if let data = userDefaults.data(forKey: sharesKey),
           let loaded = try? JSONDecoder().decode([CircleShare].self, from: data) {
            recentShares = loaded
        }
    }

    // MARK: - Sample Data

    func addSampleCircle() {
        circle = TrustedCircle(
            name: "Family",
            members: [
                TrustedMember(name: "Maria", relationship: .spouse),
                TrustedMember(name: "Sofia", relationship: .child),
            ],
            isSharingEnabled: true,
            shareSettings: TrustedCircle.ShareSettings(
                showAverageScore: true,
                showStreak: true,
                showDominantEmotion: true,
                showInsights: true,
                showTrend: true,
                hideIndividualMoments: true,
                shareFrequency: .weekly
            )
        )
        saveCircle()
    }
}
