import Foundation

// R11: AI Emotional Insights
struct AIInsight: Identifiable {
    let id: UUID
    let headline: String
    let summary: String
    let emotionalTheme: String
    let dominantEmotion: EmotionCategory
    let intensity: Double // 0.0 to 1.0
    let trend: Trend
    let supportingMomentCount: Int
    let generatedAt: Date

    enum Trend: String {
        case improving = "improving"
        case declining = "declining"
        case stable = "stable"
        case fluctuating = "fluctuating"

        var icon: String {
            switch self {
            case .improving: return "arrow.up.right"
            case .declining: return "arrow.down.right"
            case .stable: return "arrow.right"
            case .fluctuating: return "arrow.up.arrow.down"
            }
        }
    }

    init(
        id: UUID = UUID(),
        headline: String,
        summary: String,
        emotionalTheme: String,
        dominantEmotion: EmotionCategory,
        intensity: Double,
        trend: Trend,
        supportingMomentCount: Int,
        generatedAt: Date
    ) {
        self.id = id
        self.headline = headline
        self.summary = summary
        self.emotionalTheme = emotionalTheme
        self.dominantEmotion = dominantEmotion
        self.intensity = intensity
        self.trend = trend
        self.supportingMomentCount = supportingMomentCount
        self.generatedAt = generatedAt
    }
}

@MainActor
final class AIInsightService: ObservableObject {
    nonisolated(unsafe) static let shared = AIInsightService()

    private nonisolated init() {}

    nonisolated func generateWeeklyAnalysis(entries: [Moment]) -> AIInsight? {
        guard !entries.isEmpty else { return nil }

        let avgScore = entries.map(\.emotionScore).reduce(0, +) / Double(entries.count)

        // Determine dominant emotion from tags
        var emotionFrequency: [EmotionCategory: Double] = [:]
        for entry in entries {
            for tag in entry.emotionTags {
                emotionFrequency[tag.category, default: 0] += tag.confidence
            }
        }
        let dominantEmotion = emotionFrequency.max(by: { $0.value < $1.value })?.key ?? .neutral

        // Calculate trend
        let trend = calculateTrend(from: entries)

        // Calculate intensity
        let scoreVariance = calculateVariance(values: entries.map(\.emotionScore))
        let intensity = min(abs(avgScore) + scoreVariance * 0.5, 1.0)

        // Generate headline and summary based on emotional patterns
        let (headline, summary, theme) = generateNarrative(
            entries: entries,
            avgScore: avgScore,
            dominantEmotion: dominantEmotion,
            trend: trend
        )

        return AIInsight(
            headline: headline,
            summary: summary,
            emotionalTheme: theme,
            dominantEmotion: dominantEmotion,
            intensity: intensity,
            trend: trend,
            supportingMomentCount: entries.count,
            generatedAt: Date()
        )
    }

    private nonisolated func calculateTrend(from entries: [Moment]) -> AIInsight.Trend {
        guard entries.count >= 2 else { return .stable }

        let sorted = entries.sorted { $0.timestamp < $1.timestamp }
        let midpoint = sorted.count / 2

        let firstHalfAvg = sorted.prefix(midpoint).map(\.emotionScore).reduce(0, +) / Double(max(midpoint, 1))
        let secondHalfAvg = sorted.suffix(midpoint).map(\.emotionScore).reduce(0, +) / Double(max(midpoint, 1))

        let diff = secondHalfAvg - firstHalfAvg

        if abs(diff) < 0.1 {
            return .stable
        } else if diff > 0.2 {
            return .improving
        } else if diff < -0.2 {
            return .declining
        } else {
            return .fluctuating
        }
    }

    private nonisolated func calculateVariance(values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDiffs = values.map { pow($0 - mean, 2) }
        return sqrt(squaredDiffs.reduce(0, +) / Double(values.count - 1))
    }

    private nonisolated func generateNarrative(
        entries: [Moment],
        avgScore: Double,
        dominantEmotion: EmotionCategory,
        trend: AIInsight.Trend
    ) -> (headline: String, summary: String, theme: String) {
        let count = entries.count

        let themeMap: [EmotionCategory: String] = [
            .joy: "Joy & Gratitude",
            .sadness: "Processing & Reflection",
            .anger: "Stress & Frustration",
            .fear: "Anxiety & Uncertainty",
            .surprise: "Unexpected Moments",
            .disgust: "Discomfort & Aversion",
            .trust: "Connection & Support",
            .anticipation: "Expectation & Hope",
            .neutral: "Balance & Stability"
        ]

        let theme = themeMap[dominantEmotion] ?? "Emotional Awareness"

        let trendAdjectives: [AIInsight.Trend: (positive: String, negative: String, neutral: String)] = [
            .improving: ("notable uplift", "a dip followed by recovery", "gradual positivity emerging"),
            .declining: ("challenging period", "rough stretch", "emotional low point"),
            .stable: ("consistent emotional baseline", "steady state", "balanced emotional register"),
            .fluctuating: ("emotional ups and downs", "mixed emotional signals", "variable week")
        ]

        let adjectives = trendAdjectives[trend] ?? trendAdjectives[.stable]!

        let headline: String
        let summary: String

        if avgScore > 0.5 {
            headline = "A week of \(theme.lowercased())"
            summary = "You've captured \(count) moment\(count == 1 ? "" : "s") reflecting \(adjectives.positive). Your emotional score averaged \(String(format: "%.1f", avgScore * 100))% positive, with \(dominantEmotion.rawValue.lowercased()) as your dominant theme."
        } else if avgScore < -0.3 {
            headline = "Navigating \(theme.lowercased())"
            summary = "Over the past week, \(count) moment\(count == 1 ? "" : "s") show \(adjectives.negative). Your emotional score averaged \(String(format: "%.1f", abs(avgScore) * 100))% below neutral. This is valuable self-awareness."
        } else {
            headline = "A week of \(theme.lowercased())"
            summary = "Your \(count) captured moment\(count == 1 ? "" : "s") reveal \(adjectives.neutral). \(dominantEmotion.rawValue.capitalized) emerged as your primary emotional theme, with room to explore what sustains or challenges that balance."
        }

        return (headline, summary, theme)
    }
}
