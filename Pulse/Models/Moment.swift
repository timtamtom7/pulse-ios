import Foundation

enum MomentType: String, Codable, CaseIterable {
    case photo
    case voice
    case journal

    var icon: String {
        switch self {
        case .photo: return "photo.fill"
        case .voice: return "waveform"
        case .journal: return "pencil.line"
        }
    }

    var displayName: String {
        switch self {
        case .photo: return "Photo"
        case .voice: return "Voice Note"
        case .journal: return "Journal"
        }
    }
}

struct Moment: Identifiable, Codable, Equatable {
    let id: UUID
    let type: MomentType
    let timestamp: Date
    let content: String // Base64 for photo data, text for journal, transcript for voice
    let emotionScore: Double // -1.0 to 1.0
    let emotionTags: [EmotionTag]
    let note: String?
    let sourceDataSourceId: UUID?

    init(
        id: UUID = UUID(),
        type: MomentType,
        timestamp: Date = Date(),
        content: String,
        emotionScore: Double = 0.0,
        emotionTags: [EmotionTag] = [],
        note: String? = nil,
        sourceDataSourceId: UUID? = nil
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.content = content
        self.emotionScore = emotionScore
        self.emotionTags = emotionTags
        self.note = note
        self.sourceDataSourceId = sourceDataSourceId
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: timestamp)
    }
}
