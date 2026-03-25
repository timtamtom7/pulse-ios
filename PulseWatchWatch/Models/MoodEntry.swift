import Foundation

/// A quick mood check-in entry for watch
struct MoodEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let emotionScore: Double // -1.0 to 1.0
    let emotionLabel: String

    init(id: UUID = UUID(), timestamp: Date = Date(), emotionScore: Double, emotionLabel: String) {
        self.id = id
        self.timestamp = timestamp
        self.emotionScore = emotionScore
        self.emotionLabel = emotionLabel
    }
}
