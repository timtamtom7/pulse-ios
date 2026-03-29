import Foundation

/// Service for anonymous mood sharing across the Pulse community
final class MoodSharingService: @unchecked Sendable {
    static let shared = MoodSharingService()

    private let userDefaults = UserDefaults.standard
    private let sharedMoodsKey = "shared_anonymous_moods_ios"
    private let lastAggregateKey = "last_aggregate_fetch_ios"

    private init() {}

    // MARK: - Anonymous Mood Sharing

    /// Share a mood entry anonymously to the aggregate feed.
    /// Other users see: emotion + time + "X people feel this right now"
    func shareMood(_ mood: MoodEntry) async throws {
        // Simulate a brief network delay for the anonymous post
        try await Task.sleep(nanoseconds: 500_000_000)

        await MainActor.run {
            var sharedMoods = loadSharedMoods()

            let anonymousEntry = AnonymousMoodEntry(
                id: UUID(),
                emotionCategory: emotionCategoryFromLabel(mood.emotionLabel),
                emotionScore: mood.emotionScore,
                timestamp: mood.timestamp,
                sharerCount: 1
            )

            sharedMoods.append(anonymousEntry)

            // Keep only last 1000 entries to avoid unbounded growth
            if sharedMoods.count > 1000 {
                sharedMoods = Array(sharedMoods.suffix(1000))
            }

            saveSharedMoods(sharedMoods)
        }
    }

    // MARK: - Aggregate Mood

    /// Get aggregate mood for right now across all anonymous sharers
    func getAggregateMood() async throws -> AggregateMood {
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

            var breakdown: [EmotionCategory: Int] = [:]
            for mood in recentMoods {
                breakdown[mood.emotionCategory, default: 0] += 1
            }

            let dominant = breakdown.max { $0.value < $1.value }?.key ?? .neutral

            return AggregateMood(
                dominantEmotion: dominant,
                totalSharers: recentMoods.count,
                breakdown: breakdown
            )
        }
    }

    // MARK: - Mood Chains

    /// Get all recent mood chains (grouped by emotion over time)
    func getMoodChains() async throws -> [MoodChain] {
        try await Task.sleep(nanoseconds: 300_000_000)

        return await MainActor.run {
            let sharedMoods = loadSharedMoods()

            // Get last 7 days of moods
            let sevenDaysAgo = Date().addingTimeInterval(-7 * 86400)
            let recentMoods = sharedMoods.filter { $0.timestamp > sevenDaysAgo }

            var chains: [MoodChain] = []

            for category in EmotionCategory.allCases {
                let categoryMoods = recentMoods.filter { $0.emotionCategory == category }
                if categoryMoods.count >= 3 {
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
        Date().timeIntervalSince(lastActivity) < 3600
    }
}
