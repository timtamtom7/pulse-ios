import Foundation

// MARK: - Trusted Circles

/// A family member or trusted person who can see aggregate emotional data
struct TrustedMember: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let relationship: Relationship
    var isEnabled: Bool
    let joinedAt: Date
    var lastSharedAt: Date?

    enum Relationship: String, Codable, CaseIterable {
        case spouse = "Spouse"
        case partner = "Partner"
        case parent = "Parent"
        case child = "Child"
        case sibling = "Sibling"
        case family = "Family"
        case friend = "Friend"
        case other = "Other"

        var icon: String {
            switch self {
            case .spouse, .partner: return "heart.fill"
            case .parent: return "person.fill.and.arrow.left.and.arrow.right"
            case .child: return "person.fill.and.arrow.right.and.arrow.left"
            case .sibling: return "person.2.fill"
            case .family: return "figure.2.and.child.holdinghands"
            case .friend: return "hand.wave.fill"
            case .other: return "person.fill.questionmark"
            }
        }

        var displayName: String { rawValue }
    }

    init(id: UUID = UUID(), name: String, relationship: Relationship, isEnabled: Bool = true, joinedAt: Date = Date(), lastSharedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.relationship = relationship
        self.isEnabled = isEnabled
        self.joinedAt = joinedAt
        self.lastSharedAt = lastSharedAt
    }
}

/// Aggregate emotional summary shared with trusted circles
struct CircleShare: Identifiable, Codable {
    let id: UUID
    let memberId: UUID
    let shareDate: Date
    let periodStart: Date
    let periodEnd: Date

    // Aggregated data (no individual moments, just summaries)
    let averageEmotionScore: Double
    let dominantEmotion: String
    let momentCount: Int
    let streak: Int
    let topInsight: String?
    let moodTrend: MoodTrend // up, down, stable

    enum MoodTrend: String, Codable {
        case up
        case down
        case stable

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }

        var label: String {
            switch self {
            case .up: return "Trending up"
            case .down: return "Trending down"
            case .stable: return "Stable"
            }
        }

        var displayName: String {
            switch self {
            case .up: return "Up"
            case .down: return "Down"
            case .stable: return "Stable"
            }
        }
    }

    init(id: UUID = UUID(), memberId: UUID, shareDate: Date = Date(), periodStart: Date, periodEnd: Date, averageEmotionScore: Double, dominantEmotion: String, momentCount: Int, streak: Int, topInsight: String?, moodTrend: MoodTrend) {
        self.id = id
        self.memberId = memberId
        self.shareDate = shareDate
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.averageEmotionScore = averageEmotionScore
        self.dominantEmotion = dominantEmotion
        self.momentCount = momentCount
        self.streak = streak
        self.topInsight = topInsight
        self.moodTrend = moodTrend
    }
}

/// A trusted circle containing family members
struct TrustedCircle: Identifiable, Codable {
    let id: UUID
    var name: String
    var members: [TrustedMember]
    var isSharingEnabled: Bool
    let createdAt: Date

    // What data is shared with this circle
    var shareSettings: ShareSettings

    struct ShareSettings: Codable {
        var showAverageScore: Bool = true
        var showStreak: Bool = true
        var showDominantEmotion: Bool = true
        var showInsights: Bool = true
        var showTrend: Bool = true
        var hideIndividualMoments: Bool = true // Always true, privacy requirement
        var shareFrequency: ShareFrequency = .weekly

        enum ShareFrequency: String, Codable, CaseIterable {
            case daily = "Daily"
            case weekly = "Weekly"
            case biweekly = "Every 2 weeks"
            case monthly = "Monthly"

            var days: Int {
                switch self {
                case .daily: return 1
                case .weekly: return 7
                case .biweekly: return 14
                case .monthly: return 30
                }
            }
        }
    }

    init(id: UUID = UUID(), name: String = "My Circle", members: [TrustedMember] = [], isSharingEnabled: Bool = true, createdAt: Date = Date(), shareSettings: ShareSettings = ShareSettings()) {
        self.id = id
        self.name = name
        self.members = members
        self.isSharingEnabled = isSharingEnabled
        self.createdAt = createdAt
        self.shareSettings = shareSettings
    }

    var activeMembersCount: Int {
        members.filter { $0.isEnabled }.count
    }

    var lastShareDate: Date? {
        members.compactMap { $0.lastSharedAt }.max()
    }
}
