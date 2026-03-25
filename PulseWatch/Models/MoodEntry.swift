import Foundation
import WatchKit

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

/// Predefined mood options for quick selection on watch
enum QuickMood: Int, CaseIterable, Identifiable {
    case great = 0
    case good = 1
    case okay = 2
    case low = 3
    case rough = 4

    var id: Int { rawValue }

    var emoji: String {
        switch self {
        case .great: return "😄"
        case .good: return "🙂"
        case .okay: return "😐"
        case .low: return "😔"
        case .rough: return "😢"
        }
    }

    var label: String {
        switch self {
        case .great: return "Great"
        case .good: return "Good"
        case .okay: return "Okay"
        case .low: return "Low"
        case .rough: return "Rough"
        }
    }

    var emotionScore: Double {
        switch self {
        case .great: return 0.8
        case .good: return 0.4
        case .okay: return 0.0
        case .low: return -0.4
        case .rough: return -0.8
        }
    }

    var color: UIColor {
        switch self {
        case .great: return UIColor(red: 0.61, green: 0.81, blue: 0.53, alpha: 1) // calmSage
        case .good: return UIColor(red: 0.83, green: 0.66, blue: 0.33, alpha: 1) // gentleGold
        case .okay: return UIColor(red: 0.55, green: 0.48, blue: 0.46, alpha: 1) // warmGray
        case .low: return UIColor(red: 0.77, green: 0.44, blue: 0.42, alpha: 1) // mutedRose
        case .rough: return UIColor(red: 0.48, green: 0.24, blue: 0.22, alpha: 1) // deepEmber
        }
    }
}
