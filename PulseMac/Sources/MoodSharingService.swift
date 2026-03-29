import Foundation
import SwiftUI

// MARK: - Shared Models for Mac (since UIKit-based WatchSharedModels isn't available on macOS)

/// A quick mood check-in entry (Mac-compatible version)
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

/// Predefined mood options for quick selection
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

    var color: Color {
        switch self {
        case .great: return MacTheme.Colors.calmSage
        case .good: return MacTheme.Colors.gentleGold
        case .okay: return MacTheme.Colors.warmGray
        case .low: return MacTheme.Colors.mutedRose
        case .rough: return MacTheme.Colors.deepEmber
        }
    }
}

// MARK: - Mood Sharing Service

/// Service for anonymous mood sharing across the Pulse community
final class MoodSharingService: @unchecked Sendable {
    static let shared = MoodSharingService()

    private let userDefaults = UserDefaults.standard
    private let sharedMoodsKey = "shared_anonymous_moods"
    private let lastAggregateKey = "last_aggregate_fetch"

    private let circleKey = "trusted_circle_data"
    private let sharesKey = "recent_shares"

    private init() {}

    // MARK: - Anonymous Mood Sharing

    /// Share a mood entry anonymously to the aggregate feed
    /// Other users see: emotion + time + "X people feel this right now"
    func shareMood(_ mood: MoodEntry) async throws {
        // Simulate network delay for anonymous post
        try await Task.sleep(nanoseconds: 500_000_000)

        await MainActor.run {
            var sharedMoods = loadSharedMoods()

            let anonymousEntry = AnonymousMoodEntry(
                id: UUID(),
                emotionCategory: emotionCategoryFromLabel(mood.emotionLabel),
                emotionScore: mood.emotionScore,
                timestamp: mood.timestamp,
                sharerCount: 1 // Will be aggregated
            )

            sharedMoods.append(anonymousEntry)

            // Keep only last 1000 entries to avoid unbounded growth
            if sharedMoods.count > 1000 {
                sharedMoods = Array(sharedMoods.suffix(1000))
            }

            saveSharedMoods(sharedMoods)
        }
    }

    /// Get aggregate mood for right now across all anonymous sharers
    func getAggregateMood() async throws -> AggregateMood {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)

        return await MainActor.run {
            let sharedMoods = loadSharedMoods()

            // Filter to only recent entries (last 24 hours)
            let oneDayAgo = Date().addingTimeInterval(-86400)
            let recentMoods = sharedMoods.filter { $0.timestamp > oneDayAgo }

            if recentMoods.isEmpty {
                return AggregateMood(
                    dominantEmotion: .neutral,
                    totalSharers: 0,
                    breakdown: [:]
                )
            }

            // Calculate breakdown by emotion category
            var breakdown: [EmotionCategory: Int] = [:]
            for mood in recentMoods {
                breakdown[mood.emotionCategory, default: 0] += 1
            }

            // Find dominant emotion
            let dominant = breakdown.max { $0.value < $1.value }?.key ?? .neutral

            return AggregateMood(
                dominantEmotion: dominant,
                totalSharers: recentMoods.count,
                breakdown: breakdown
            )
        }
    }

    /// Get all recent mood chains (grouped by emotion over time)
    func getMoodChains() async throws -> [MoodChain] {
        try await Task.sleep(nanoseconds: 300_000_000)

        return await MainActor.run {
            let sharedMoods = loadSharedMoods()

            // Get last 7 days of moods
            let sevenDaysAgo = Date().addingTimeInterval(-7 * 86400)
            let recentMoods = sharedMoods.filter { $0.timestamp > sevenDaysAgo }

            var chains: [MoodChain] = []

            // Group by emotion category
            for category in EmotionCategory.allCases {
                let categoryMoods = recentMoods.filter { $0.emotionCategory == category }
                if categoryMoods.count >= 3 {
                    // Create a chain from consecutive moods
                    let chain = MoodChain(
                        id: UUID(),
                        emotionCategory: category,
                        entries: categoryMoods.sorted { $0.timestamp < $1.timestamp },
                        participantCount: categoryMoods.count,
                        startedAt: categoryMoods.map(\.timestamp).min() ?? Date(),
                        lastActivity: categoryMoods.map(\.timestamp).max() ?? Date()
                    )
                    chains.append(chain)
                }
            }

            return chains.sorted { $0.participantCount > $1.participantCount }
        }
    }

    /// Get mood entries for a specific emotion chain
    func getMoodChain(for category: EmotionCategory) async throws -> MoodChain? {
        let chains = try await getMoodChains()
        return chains.first { $0.emotionCategory == category }
    }

    /// Add current user to a mood chain
    func joinMoodChain(category: EmotionCategory, mood: MoodEntry) async throws {
        try await shareMood(mood)
    }

    // MARK: - Friends Feed

    /// Get friends who have opted into sharing their mood
    func getFriendsFeed() async throws -> [FriendMoodUpdate] {
        try await Task.sleep(nanoseconds: 400_000_000)

        return await MainActor.run {
            let circle = loadTrustedCircle()
            let recentShares = loadRecentShares()

            var updates: [FriendMoodUpdate] = []

            for member in circle.members where member.isEnabled {
                let memberShares = recentShares.filter { $0.memberId == member.id }
                if let latestShare = memberShares.sorted(by: { $0.periodEnd > $1.periodEnd }).first {
                    let update = FriendMoodUpdate(
                        friendId: member.id,
                        friendName: member.name,
                        relationship: member.relationship,
                        moodLabel: latestShare.dominantEmotion,
                        moodScore: latestShare.averageEmotionScore,
                        lastUpdated: latestShare.periodEnd,
                        trend: latestShare.moodTrend
                    )
                    updates.append(update)
                }
            }

            return updates.sorted { $0.lastUpdated > $1.lastUpdated }
        }
    }

    // MARK: - Trusted Circle Access (Inlined)

    private func loadTrustedCircle() -> TrustedCircle {
        guard let data = userDefaults.data(forKey: circleKey),
              let loaded = try? JSONDecoder().decode(TrustedCircle.self, from: data) else {
            return TrustedCircle()
        }
        return loaded
    }

    private func loadRecentShares() -> [CircleShare] {
        guard let data = userDefaults.data(forKey: sharesKey),
              let loaded = try? JSONDecoder().decode([CircleShare].self, from: data) else {
            return []
        }
        return loaded
    }

    // MARK: - Helpers

    private func loadSharedMoods() -> [AnonymousMoodEntry] {
        guard let data = userDefaults.data(forKey: sharedMoodsKey),
              let moods = try? JSONDecoder().decode([AnonymousMoodEntry].self, from: data) else {
            return []
        }
        return moods
    }

    private func saveSharedMoods(_ moods: [AnonymousMoodEntry]) {
        if let data = try? JSONEncoder().encode(moods) {
            userDefaults.set(data, forKey: sharedMoodsKey)
        }
    }

    private func emotionCategoryFromLabel(_ label: String) -> EmotionCategory {
        switch label.lowercased() {
        case "great", "happy", "joyful", "excited":
            return .joy
        case "good", "content", "satisfied":
            return .trust
        case "okay", "neutral", "calm":
            return .neutral
        case "low", "sad", "down":
            return .sadness
        case "rough", "angry", "frustrated":
            return .anger
        case "anxious", "worried", "nervous":
            return .fear
        case "surprised", "amazed":
            return .surprise
        case "disgusted", "uncomfortable":
            return .disgust
        case "hopeful", "looking forward":
            return .anticipation
        default:
            return .neutral
        }
    }
}

// MARK: - Supporting Types

/// An anonymous mood entry shared to the aggregate feed
struct AnonymousMoodEntry: Identifiable, Codable {
    let id: UUID
    let emotionCategory: EmotionCategory
    let emotionScore: Double
    let timestamp: Date
    let sharerCount: Int

    var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

/// Aggregate mood showing what the community is feeling
struct AggregateMood: Codable {
    let dominantEmotion: EmotionCategory
    let totalSharers: Int
    let breakdown: [EmotionCategory: Int]

    var shareText: String {
        if totalSharers == 0 {
            return "Be the first to share how you're feeling"
        } else if totalSharers == 1 {
            return "1 person is feeling \(dominantEmotion.displayName.lowercased()) right now"
        } else {
            return "\(totalSharers) people are feeling \(dominantEmotion.displayName.lowercased()) right now"
        }
    }
}

/// A mood chain represents a stream of similar moods over time
struct MoodChain: Identifiable, Codable {
    let id: UUID
    let emotionCategory: EmotionCategory
    let entries: [AnonymousMoodEntry]
    let participantCount: Int
    let startedAt: Date
    let lastActivity: Date

    var chainName: String {
        "\(emotionCategory.displayName) Chain"
    }

    var isActive: Bool {
        // Active if someone shared in the last hour
        Date().timeIntervalSince(lastActivity) < 3600
    }
}

/// A friend's mood update (if they've opted into sharing)
struct FriendMoodUpdate: Identifiable, Codable {
    let id: UUID
    let friendId: UUID
    let friendName: String
    let relationship: TrustedMember.Relationship
    let moodLabel: String
    let moodScore: Double
    let lastUpdated: Date
    let trend: CircleShare.MoodTrend

    init(id: UUID = UUID(), friendId: UUID, friendName: String, relationship: TrustedMember.Relationship, moodLabel: String, moodScore: Double, lastUpdated: Date, trend: CircleShare.MoodTrend) {
        self.id = id
        self.friendId = friendId
        self.friendName = friendName
        self.relationship = relationship
        self.moodLabel = moodLabel
        self.moodScore = moodScore
        self.lastUpdated = lastUpdated
        self.trend = trend
    }

    var formattedUpdate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let timeAgo = formatter.localizedString(for: lastUpdated, relativeTo: Date())
        return "\(friendName) is feeling \(moodLabel.lowercased()) (\(timeAgo))"
    }

    var trendIcon: String {
        switch trend {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    var trendColor: Color {
        switch trend {
        case .up: return MacTheme.Colors.calmSage
        case .down: return MacTheme.Colors.mutedRose
        case .stable: return MacTheme.Colors.warmGray
        }
    }
}
