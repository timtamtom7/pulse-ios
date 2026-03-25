import Foundation

struct Insight: Identifiable, Codable {
    let id: UUID
    let title: String
    let body: String
    let category: InsightCategory
    let createdAt: Date
    let supportingDataPointCount: Int
    let emotionScore: Double

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        category: InsightCategory,
        createdAt: Date = Date(),
        supportingDataPointCount: Int = 0,
        emotionScore: Double = 0.0
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.category = category
        self.createdAt = createdAt
        self.supportingDataPointCount = supportingDataPointCount
        self.emotionScore = emotionScore
    }
}

enum InsightCategory: String, Codable {
    case pattern
    case correlation
    case achievement
    case concern
    case general

    var icon: String {
        switch self {
        case .pattern: return "waveform.path.ecg"
        case .correlation: return "link"
        case .achievement: return "star.fill"
        case .concern: return "exclamationmark.triangle"
        case .general: return "lightbulb.fill"
        }
    }
}

struct WeeklyInsight: Identifiable {
    let id: UUID
    let insight: Insight
    let weekStartDate: Date
    let isViewed: Bool

    init(insight: Insight, weekStartDate: Date, isViewed: Bool = false) {
        self.id = insight.id
        self.insight = insight
        self.weekStartDate = weekStartDate
        self.isViewed = isViewed
    }
}
