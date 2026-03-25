import Foundation

enum DataSourceType: String, Codable, CaseIterable {
    case photosLibrary
    case voiceNotes
    case calendar
    case journal
    case health

    var displayName: String {
        switch self {
        case .photosLibrary: return "Photos Library"
        case .voiceNotes: return "Voice Notes"
        case .calendar: return "Calendar"
        case .journal: return "Journal Entries"
        case .health: return "Health Data"
        }
    }

    var icon: String {
        switch self {
        case .photosLibrary: return "photo.on.rectangle"
        case .voiceNotes: return "waveform.circle"
        case .calendar: return "calendar"
        case .journal: return "book.closed"
        case .health: return "heart.fill"
        }
    }

    var description: String {
        switch self {
        case .photosLibrary: return "Read photos to understand visual mood and life moments"
        case .voiceNotes: return "Analyze voice notes for emotional tone and content"
        case .calendar: return "Find patterns between schedule and emotional wellbeing"
        case .journal: return "Store and analyze your written reflections"
        case .health: return "Correlate physical activity with emotional patterns"
        }
    }
}

struct DataSource: Identifiable, Codable, Equatable {
    let id: UUID
    let type: DataSourceType
    var isConnected: Bool
    var lastSyncedAt: Date?
    var dataPointCount: Int

    init(
        id: UUID = UUID(),
        type: DataSourceType,
        isConnected: Bool = false,
        lastSyncedAt: Date? = nil,
        dataPointCount: Int = 0
    ) {
        self.id = id
        self.type = type
        self.isConnected = isConnected
        self.lastSyncedAt = lastSyncedAt
        self.dataPointCount = dataPointCount
    }

    var statusText: String {
        if isConnected {
            if let lastSynced = lastSyncedAt {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .abbreviated
                return "Synced \(formatter.localizedString(for: lastSynced, relativeTo: Date()))"
            }
            return "Connected"
        }
        return "Not connected"
    }

    var statusColor: String {
        isConnected ? "green" : "gray"
    }
}
