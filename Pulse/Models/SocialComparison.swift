import Foundation

// MARK: - Anonymous Social Comparison

/// Represents an anonymized percentile comparison of the user's emotional data
struct PercentileComparison: Identifiable, Codable {
    let id = UUID()
    let metricName: String
    let metricDescription: String
    let userValue: Double
    let percentile: Int // 0-100
    let averageValue: Double
    let cohortAverage: Double
    let sampleSize: Int
    let comparedTo: String // e.g., "all users", "your age group", "your region"

    var percentileLabel: String {
        switch percentile {
        case 0..<20: return "Lower range"
        case 20..<40: return "Below average"
        case 40..<60: return "Average range"
        case 60..<80: return "Above average"
        case 80..<95: return "Top tier"
        case 95...100: return "Exceptional"
        default: return "Average"
        }
    }

    var comparisonDirection: ComparisonDirection {
        if percentile >= 70 { return .aboveAverage }
        if percentile <= 30 { return .belowAverage }
        return .average
    }

    enum ComparisonDirection {
        case aboveAverage, average, belowAverage

        var icon: String {
            switch self {
            case .aboveAverage: return "arrow.up.circle.fill"
            case .average: return "equal.circle.fill"
            case .belowAverage: return "arrow.down.circle.fill"
            }
        }
    }
}

/// Insight card showing social comparison data
struct PercentileInsight: Identifiable {
    let id = UUID()
    let comparison: PercentileComparison
    let insight: String
    let createdAt: Date

    init(comparison: PercentileComparison) {
        self.comparison = comparison
        self.insight = Self.generateInsight(from: comparison)
        self.createdAt = Date()
    }

    private static func generateInsight(from comparison: PercentileComparison) -> String {
        switch comparison.percentile {
        case 80...:
            return "\(comparison.metricName) is one of your strengths. You're in the top \(100 - comparison.percentile)% of users."
        case 60..<80:
            return "Your \(comparison.metricName) is above average. Keep doing what works."
        case 40..<60:
            return "Your \(comparison.metricName) is typical — you're right in the middle of the pack."
        case 20..<40:
            return "Your \(comparison.metricName) tends to be lower. This could be an area to explore."
        default:
            return "Your \(comparison.metricName) is at the lower end. Small steps forward add up."
        }
    }
}

/// Privacy-safe aggregated metrics for anonymous comparison
struct AggregatedMetrics: Codable {
    let periodStart: Date
    let periodEnd: Date
    let totalUsersAnalyzed: Int
    let averageEmotionScore: Double
    let emotionScoreDistribution: [Double: Double] // percentile -> score
    let averageMomentFrequency: Double
    let dominantEmotionPercentages: [String: Double]
    let streakStatistics: StreakStats

    struct StreakStats: Codable {
        let averageStreak: Double
        let medianStreak: Double
        let topPercentileStreak: Int
    }

    func percentileFor(score: Double) -> Int {
        // Find what percentile the user's score falls into
        let sortedScores = emotionScoreDistribution.sorted { $0.key < $1.key }
        var count = 0
        for (threshold, _) in sortedScores {
            if score >= threshold {
                count += 1
            }
        }
        return min(Int(Double(count) / Double(sortedScores.count) * 100), 99)
    }

    static var sample: AggregatedMetrics {
        AggregatedMetrics(
            periodStart: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
            periodEnd: Date(),
            totalUsersAnalyzed: 12847,
            averageEmotionScore: 0.32,
            emotionScoreDistribution: [-1.0: 0.05, -0.5: 0.15, 0.0: 0.35, 0.3: 0.25, 0.7: 0.15, 1.0: 0.05],
            averageMomentFrequency: 4.2,
            dominantEmotionPercentages: ["joy": 0.28, "neutral": 0.25, "anticipation": 0.18, "trust": 0.15, "sadness": 0.14],
            streakStatistics: StreakStats(
                averageStreak: 3.2,
                medianStreak: 2,
                topPercentileStreak: 21
            )
        )
    }
}
