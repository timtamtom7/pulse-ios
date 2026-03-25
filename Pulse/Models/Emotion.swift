import Foundation
import SwiftUI

enum EmotionCategory: String, Codable, CaseIterable {
    case joy
    case sadness
    case anger
    case fear
    case surprise
    case disgust
    case trust
    case anticipation
    case neutral

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .joy: return Theme.Colors.veryPositive
        case .trust: return Theme.Colors.positive
        case .anticipation: return Theme.Colors.positive
        case .surprise: return Theme.Colors.gentleGold
        case .neutral: return Theme.Colors.neutral
        case .sadness: return Theme.Colors.mutedRose
        case .fear: return Theme.Colors.deepEmber
        case .anger: return Theme.Colors.dustyRose
        case .disgust: return Theme.Colors.dustyRose
        }
    }
}

struct EmotionTag: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let category: EmotionCategory
    let confidence: Double // 0.0 to 1.0
    let label: String

    init(id: UUID = UUID(), category: EmotionCategory, confidence: Double, label: String? = nil) {
        self.id = id
        self.category = category
        self.confidence = confidence
        self.label = label ?? category.displayName
    }

    var color: Color {
        category.color
    }
}

struct DayEmotionSummary: Identifiable {
    let id: UUID
    let date: Date
    let dominantEmotion: EmotionTag?
    let averageScore: Double
    let momentCount: Int
    let dominantEmotionColor: Color

    init(date: Date, moments: [Moment]) {
        self.id = UUID()
        self.date = date
        self.momentCount = moments.count

        if moments.isEmpty {
            self.dominantEmotion = nil
            self.averageScore = 0.0
            self.dominantEmotionColor = Theme.Colors.neutral
        } else {
            self.averageScore = moments.map(\.emotionScore).reduce(0, +) / Double(moments.count)

            // Find dominant emotion by frequency and strength
            var emotionFrequency: [EmotionCategory: (count: Int, totalConfidence: Double)] = [:]
            for moment in moments {
                for tag in moment.emotionTags {
                    let existing = emotionFrequency[tag.category] ?? (0, 0)
                    emotionFrequency[tag.category] = (existing.count + 1, existing.totalConfidence + tag.confidence)
                }
            }

            if let dominant = emotionFrequency.max(by: {
                ($0.value.count, $0.value.totalConfidence) < ($1.value.count, $1.value.totalConfidence)
            }) {
                self.dominantEmotion = EmotionTag(
                    category: dominant.key,
                    confidence: dominant.value.totalConfidence / Double(dominant.value.count)
                )
                self.dominantEmotionColor = dominant.key.color
            } else {
                self.dominantEmotion = nil
                self.dominantEmotionColor = Theme.Colors.neutral
            }
        }
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var monthAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
}
