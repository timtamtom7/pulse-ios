import Foundation

/// R9: Memorial Mode — when a loved one passes, their account becomes a memorial
/// with read-only access to their emotional history
@Observable
final class MemorialService: @unchecked Sendable {
    static let shared = MemorialService()

    var memorialAccounts: [MemorialAccount] = []
    var isEnabled: Bool { !memorialAccounts.isEmpty }

    private let userDefaults = UserDefaults.standard
    private let memorialKey = "memorial_accounts"

    private init() {
        loadMemorialAccounts()
    }

    struct MemorialAccount: Identifiable, Codable {
        let id: UUID
        let name: String
        let relationship: String
        let createdAt: Date
        let memorializedAt: Date?

        var isMemorialized: Bool {
            memorializedAt != nil
        }

        var displayName: String {
            if let _ = memorializedAt {
                return "\(name) (Memorial)"
            }
            return name
        }
    }

    struct MemorialSummary: Codable {
        let accountId: UUID
        let name: String
        let relationship: String

        // Their journey summary
        let totalMoments: Int
        let averageEmotionScore: Double
        let dominantEmotion: String
        let totalDays: Int
        let lastCheckIn: Date?

        // What they were working through
        let topInsights: [String]

        // Memorial-specific
        let memorializedAt: Date
        let celebratingText: String

        var lastCheckInFormatted: String {
            guard let date = lastCheckIn else { return "Never" }
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return formatter.localizedString(for: date, relativeTo: Date())
        }
    }

    // MARK: - Create Memorial

    func createMemorial(name: String, relationship: String) -> MemorialAccount {
        let account = MemorialAccount(
            id: UUID(),
            name: name,
            relationship: relationship,
            createdAt: Date(),
            memorializedAt: nil
        )
        memorialAccounts.append(account)
        saveMemorialAccounts()
        return account
    }

    func memorializeAccount(id: UUID) {
        guard let index = memorialAccounts.firstIndex(where: { $0.id == id }) else { return }

        var account = memorialAccounts[index]
        account = MemorialAccount(
            id: account.id,
            name: account.name,
            relationship: account.relationship,
            createdAt: account.createdAt,
            memorializedAt: Date()
        )

        memorialAccounts[index] = account
        saveMemorialAccounts()
    }

    func removeMemorial(id: UUID) {
        memorialAccounts.removeAll { $0.id == id }
        saveMemorialAccounts()
    }

    // MARK: - Memorial Summary

    func generateMemorialSummary(for accountId: UUID) -> MemorialSummary? {
        guard let account = memorialAccounts.first(where: { $0.id == accountId }) else {
            return nil
        }

        let familyService = FamilyCircleService.shared
        let memberMoments = familyService.familyMoments.filter { $0.memberId == accountId }

        let moments = familyService.familyMoments
        let avgScore = memberMoments.isEmpty ? 0.0 : memberMoments.map(\.emotionScore).reduce(0, +) / Double(memberMoments.count)

        var emotionCounts: [String: Int] = [:]
        for moment in memberMoments {
            emotionCounts[moment.dominantEmotion, default: 0] += 1
        }
        let dominantEmotion = emotionCounts.max(by: { $0.value < $1.value })?.key ?? "Neutral"

        let firstMoment = memberMoments.min(by: { $0.timestamp < $1.timestamp })
        let lastMoment = memberMoments.max(by: { $0.timestamp < $1.timestamp })

        let totalDays: Int
        if let first = firstMoment, let last = lastMoment {
            totalDays = Calendar.current.dateComponents([.day], from: first.timestamp, to: last.timestamp).day ?? 0
        } else {
            totalDays = 0
        }

        // Generate celebrating text based on their journey
        let celebratingText = generateCelebratingText(
            name: account.name,
            totalMoments: memberMoments.count,
            dominantEmotion: dominantEmotion,
            avgScore: avgScore
        )

        // Get top insights from their emotional data
        let topInsights = generateTopInsights(from: memberMoments)

        return MemorialSummary(
            accountId: accountId,
            name: account.name,
            relationship: account.relationship,
            totalMoments: memberMoments.count,
            averageEmotionScore: avgScore,
            dominantEmotion: dominantEmotion,
            totalDays: totalDays,
            lastCheckIn: lastMoment?.timestamp,
            topInsights: topInsights,
            memorializedAt: account.memorializedAt ?? Date(),
            celebratingText: celebratingText
        )
    }

    private func generateCelebratingText(name: String, totalMoments: Int, dominantEmotion: String, avgScore: Double) -> String {
        let scoreLabel = avgScore > 0.4 ? "radiated joy" : avgScore > 0 ? "found moments of peace" : avgScore > -0.4 ? "navigated complex feelings" : "faced real challenges"

        return "\(name) \(scoreLabel), capturing \(totalMoments) moment\(totalMoments == 1 ? "" : "s") and sharing a journey often marked by \(dominantEmotion.lowercased()). They showed up for themselves every day, and that matters."
    }

    private func generateTopInsights(from moments: [FamilyCircleService.FamilyMoment]) -> [String] {
        // Simple rule-based insights
        var insights: [String] = []

        let positiveMoments = moments.filter { $0.emotionScore > 0.3 }
        let negativeMoments = moments.filter { $0.emotionScore < -0.3 }

        if !positiveMoments.isEmpty {
            insights.append("Found joy in \(positiveMoments.count) moment\(positiveMoments.count == 1 ? "" : "s")")
        }

        if !negativeMoments.isEmpty {
            insights.append("Navigated \(negativeMoments.count) difficult moment\(negativeMoments.count == 1 ? "" : "s") with courage")
        }

        let joyCount = moments.filter { $0.dominantEmotion == "Joy" }.count
        if joyCount > 0 {
            insights.append("Joy was their most frequent emotion — \(joyCount) time\(joyCount == 1 ? "" : "s")")
        }

        let trustCount = moments.filter { $0.dominantEmotion == "Trust" }.count
        if trustCount > 0 {
            insights.append("Trust appeared \(trustCount) time\(trustCount == 1 ? "" : "s") — a mark of connection")
        }

        return Array(insights.prefix(4))
    }

    // MARK: - Persistence

    private func saveMemorialAccounts() {
        if let data = try? JSONEncoder().encode(memorialAccounts) {
            userDefaults.set(data, forKey: memorialKey)
        }
    }

    private func loadMemorialAccounts() {
        if let data = userDefaults.data(forKey: memorialKey),
           let accounts = try? JSONDecoder().decode([MemorialAccount].self, from: data) {
            memorialAccounts = accounts
        }
    }

    // MARK: - Sample Data

    func createSampleMemorial() {
        let account = createMemorial(name: "Grandma Elena", relationship: "Grandmother")

        // Add some sample family moments for this account
        let calendar = Calendar.current
        let now = Date()

        let sampleMoments: [FamilyCircleService.FamilyMoment] = [
            FamilyCircleService.FamilyMoment(
                id: UUID(),
                memberId: account.id,
                memberName: "Grandma Elena",
                timestamp: calendar.date(byAdding: .day, value: -2, to: now)!,
                emotionScore: 0.7,
                dominantEmotion: "Joy",
                emotionColor: "calmSage"
            ),
            FamilyCircleService.FamilyMoment(
                id: UUID(),
                memberId: account.id,
                memberName: "Grandma Elena",
                timestamp: calendar.date(byAdding: .day, value: -5, to: now)!,
                emotionScore: 0.5,
                dominantEmotion: "Trust",
                emotionColor: "gentleGold"
            ),
            FamilyCircleService.FamilyMoment(
                id: UUID(),
                memberId: account.id,
                memberName: "Grandma Elena",
                timestamp: calendar.date(byAdding: .day, value: -10, to: now)!,
                emotionScore: 0.6,
                dominantEmotion: "Joy",
                emotionColor: "calmSage"
            ),
        ]

        FamilyCircleService.shared.familyMoments.append(contentsOf: sampleMoments)
        memorializeAccount(id: account.id)
    }
}
