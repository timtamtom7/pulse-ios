import Foundation

/// Service for managing Family Circle — aggregate emotional health of close group
@Observable
final class FamilyCircleService: @unchecked Sendable {
    static let shared = FamilyCircleService()

    var familyMoments: [FamilyMoment] = []
    var weeklySummary: FamilyWeeklySummary?
    var isLoading = false

    private let userDefaults = UserDefaults.standard
    private let familyMomentsKey = "family_circle_moments"
    private let familySummaryKey = "family_weekly_summary"

    private init() {
        loadFamilyData()
    }

    // MARK: - Family Data

    struct FamilyMoment: Identifiable, Codable {
        let id: UUID
        let memberId: UUID
        let memberName: String
        let timestamp: Date
        let emotionScore: Double
        let dominantEmotion: String
        let emotionColor: String

        var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: timestamp)
        }

        var formattedTime: String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: timestamp)
        }
    }

    struct FamilyWeeklySummary: Codable {
        let periodStart: Date
        let periodEnd: Date
        let averageEmotionScore: Double
        let dominantEmotion: String
        let emotionColor: String
        let activeMembers: Int
        let totalCheckIns: Int
        let trend: Trend
        let memberSummaries: [MemberSummary]
        let familyInsight: String

        enum Trend: String, Codable {
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
                case .up: return "Improving"
                case .down: return "Declining"
                case .stable: return "Steady"
                }
            }

            var color: String {
                switch self {
                case .up: return "calmSage"
                case .down: return "mutedRose"
                case .stable: return "gentleGold"
                }
            }
        }

        struct MemberSummary: Codable, Identifiable {
            let id: UUID
            let memberName: String
            let averageScore: Double
            let checkInCount: Int
            let dominantEmotion: String
            let dominantEmotionColor: String
            let trend: Trend
        }

        var formattedDateRange: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: periodStart)) – \(formatter.string(from: periodEnd))"
        }
    }

    // MARK: - Generate Weekly Summary

    func generateWeeklySummary() {
        let calendar = Calendar.current
        let periodEnd = Date()
        let periodStart = calendar.date(byAdding: .day, value: -7, to: periodEnd) ?? periodEnd

        let periodMoments = familyMoments.filter {
            $0.timestamp >= periodStart && $0.timestamp <= periodEnd
        }

        guard !periodMoments.isEmpty else {
            weeklySummary = nil
            return
        }

        let avgScore = periodMoments.map(\.emotionScore).reduce(0, +) / Double(periodMoments.count)

        // Find dominant emotion
        var emotionCounts: [String: Int] = [:]
        for moment in periodMoments {
            emotionCounts[moment.dominantEmotion, default: 0] += 1
        }

        let dominantEmotion = emotionCounts.max(by: { $0.value < $1.value })?.key ?? "Neutral"
        let dominantColor = periodMoments.first(where: { $0.dominantEmotion == dominantEmotion })?.emotionColor ?? "warmGray"

        // Active members
        let activeMemberIds = Set(periodMoments.map(\.memberId))
        let activeCount = activeMemberIds.count

        // Calculate trend
        let previousPeriodStart = calendar.date(byAdding: .day, value: -7, to: periodStart) ?? periodStart
        let previousMoments = familyMoments.filter {
            $0.timestamp >= previousPeriodStart && $0.timestamp < periodStart
        }

        let previousAvg = previousMoments.isEmpty ? avgScore : previousMoments.map(\.emotionScore).reduce(0, +) / Double(previousMoments.count)

        let trend: FamilyWeeklySummary.Trend
        if avgScore - previousAvg > 0.1 {
            trend = .up
        } else if avgScore - previousAvg < -0.1 {
            trend = .down
        } else {
            trend = .stable
        }

        // Member summaries
        var memberSummaries: [FamilyWeeklySummary.MemberSummary] = []
        for memberId in activeMemberIds {
            let memberMoments = periodMoments.filter { $0.memberId == memberId }
            guard !memberMoments.isEmpty else { continue }

            let memberAvg = memberMoments.map(\.emotionScore).reduce(0, +) / Double(memberMoments.count)
            let memberDominant = emotionCounts.max(by: { $0.value < $1.value })?.key ?? "Neutral"
            let memberDominantColor = memberMoments.first(where: { $0.dominantEmotion == memberDominant })?.emotionColor ?? "warmGray"
            let memberName = memberMoments.first?.memberName ?? "Unknown"

            // Member trend
            let memberPrevious = previousMoments.filter { $0.memberId == memberId }
            let memberPrevAvg = memberPrevious.isEmpty ? memberAvg : memberPrevious.map(\.emotionScore).reduce(0, +) / Double(memberPrevious.count)
            let memberTrend: FamilyWeeklySummary.Trend
            if memberAvg - memberPrevAvg > 0.1 {
                memberTrend = .up
            } else if memberAvg - memberPrevAvg < -0.1 {
                memberTrend = .down
            } else {
                memberTrend = .stable
            }

            memberSummaries.append(FamilyWeeklySummary.MemberSummary(
                id: memberId,
                memberName: memberName,
                averageScore: memberAvg,
                checkInCount: memberMoments.count,
                dominantEmotion: memberDominant,
                dominantEmotionColor: memberDominantColor,
                trend: memberTrend
            ))
        }

        // Generate family insight
        let insight = generateFamilyInsight(
            avgScore: avgScore,
            trend: trend,
            activeCount: activeCount,
            totalCheckIns: periodMoments.count
        )

        weeklySummary = FamilyWeeklySummary(
            periodStart: periodStart,
            periodEnd: periodEnd,
            averageEmotionScore: avgScore,
            dominantEmotion: dominantEmotion,
            emotionColor: dominantColor,
            activeMembers: activeCount,
            totalCheckIns: periodMoments.count,
            trend: trend,
            memberSummaries: memberSummaries,
            familyInsight: insight
        )

        saveFamilyData()
    }

    private func generateFamilyInsight(avgScore: Double, trend: FamilyWeeklySummary.Trend, activeCount: Int, totalCheckIns: Int) -> String {
        let scoreLabel = avgScore > 0.4 ? "vibrant" : avgScore > 0 ? "balanced" : avgScore > -0.4 ? "low" : "challenging"

        switch trend {
        case .up:
            return "Your family's emotional energy is \(scoreLabel) and trending upward. \(activeCount) member\(activeCount == 1 ? "" : "s") contributed \(totalCheckIns) check-in\(totalCheckIns == 1 ? "" : "s") this week."
        case .down:
            return "Your family's emotional energy is \(scoreLabel) and trending downward. Consider reaching out — \(activeCount) member\(activeCount == 1 ? "" : "s") shared \(totalCheckIns) moment\(totalCheckIns == 1 ? "" : "s")."
        case .stable:
            return "Your family's emotional energy is steady at \(scoreLabel). \(activeCount) member\(activeCount == 1 ? "" : "s") logged \(totalCheckIns) check-in\(totalCheckIns == 1 ? "" : "s")."
        }
    }

    // MARK: - Persistence

    private func saveFamilyData() {
        if let data = try? JSONEncoder().encode(familyMoments) {
            userDefaults.set(data, forKey: familyMomentsKey)
        }
        if let summary = weeklySummary, let data = try? JSONEncoder().encode(summary) {
            userDefaults.set(data, forKey: familySummaryKey)
        }
    }

    private func loadFamilyData() {
        if let data = userDefaults.data(forKey: familyMomentsKey),
           let moments = try? JSONDecoder().decode([FamilyMoment].self, from: data) {
            familyMoments = moments
        }
        if let data = userDefaults.data(forKey: familySummaryKey),
           let summary = try? JSONDecoder().decode(FamilyWeeklySummary.self, from: data) {
            weeklySummary = summary
        }
    }

    // MARK: - Sample Data

    func addSampleFamilyData() {
        let calendar = Calendar.current
        let now = Date()

        let sampleMoments: [FamilyMoment] = [
            FamilyMoment(id: UUID(), memberId: UUID(), memberName: "Maria", timestamp: calendar.date(byAdding: .hour, value: -2, to: now)!, emotionScore: 0.7, dominantEmotion: "Joy", emotionColor: "calmSage"),
            FamilyMoment(id: UUID(), memberId: UUID(), memberName: "Sofia", timestamp: calendar.date(byAdding: .day, value: -1, to: now)!, emotionScore: 0.5, dominantEmotion: "Trust", emotionColor: "gentleGold"),
            FamilyMoment(id: UUID(), memberId: UUID(), memberName: "Papa", timestamp: calendar.date(byAdding: .day, value: -2, to: now)!, emotionScore: 0.3, dominantEmotion: "Anticipation", emotionColor: "gentleGold"),
            FamilyMoment(id: UUID(), memberId: UUID(), memberName: "Maria", timestamp: calendar.date(byAdding: .day, value: -3, to: now)!, emotionScore: 0.8, dominantEmotion: "Joy", emotionColor: "calmSage"),
            FamilyMoment(id: UUID(), memberId: UUID(), memberName: "Sofia", timestamp: calendar.date(byAdding: .day, value: -4, to: now)!, emotionScore: 0.2, dominantEmotion: "Neutral", emotionColor: "warmGray"),
        ]

        familyMoments = sampleMoments
        generateWeeklySummary()
    }

    func clearFamilyData() {
        familyMoments = []
        weeklySummary = nil
        userDefaults.removeObject(forKey: familyMomentsKey)
        userDefaults.removeObject(forKey: familySummaryKey)
    }
}
