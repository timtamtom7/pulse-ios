import Foundation

/// R10: Subscription service for Pulse
/// Manages subscription tiers: Free (7 days), Basic (30 days), Pro (unlimited)
@Observable
final class SubscriptionService: @unchecked Sendable {
    static let shared = SubscriptionService()

    // MARK: - Subscription Tiers

    enum Tier: String, CaseIterable, Identifiable {
        case free = "Free"
        case basic = "Basic"
        case pro = "Pro"

        var id: String { rawValue }

        var description: String {
            switch self {
            case .free: return "7 days free"
            case .basic: return "30 days"
            case .pro: return "Unlimited"
            }
        }

        var price: String {
            switch self {
            case .free: return "Free"
            case .basic: return "$4.99"
            case .pro: return "$9.99/month"
            }
        }

        var period: String {
            switch self {
            case .free: return "7 days"
            case .basic: return "30 days"
            case .pro: return "Monthly"
            }
        }

        var features: [String] {
            switch self {
            case .free:
                return [
                    "7 days free trial",
                    "3 captures per day",
                    "Basic emotion analysis",
                    "1 trusted circle member",
                    "3 family circle members"
                ]
            case .basic:
                return [
                    "Unlimited captures",
                    "Advanced AI analysis",
                    "5 trusted circle members",
                    "10 family circle members",
                    "Social comparison insights",
                    "30-day data export"
                ]
            case .pro:
                return [
                    "Everything in Basic",
                    "Unlimited trusted circle",
                    "Unlimited family circle",
                    "Legacy export (PDF, JSON, MD)",
                    "Memorial mode",
                    "Priority support",
                    "Early access to new features"
                ]
            }
        }

        var color: String {
            switch self {
            case .free: return "warmGray"
            case .basic: return "gentleGold"
            case .pro: return "mutedRose"
            }
        }

        var icon: String {
            switch self {
            case .free: return "leaf.fill"
            case .basic: return "star.fill"
            case .pro: return "crown.fill"
            }
        }
    }

    enum Status: Equatable {
        case trial(daysRemaining: Int)
        case active(tier: Tier)
        case expired
        case lifetime // Lifetime access (R10 bonus for early adopters)
    }

    // MARK: - State

    private(set) var currentStatus: Status = .trial(daysRemaining: 7)
    private(set) var currentTier: Tier = .free

    var isPro: Bool {
        if case .active(let tier) = currentStatus {
            return tier == .pro
        }
        return false
    }

    var isActive: Bool {
        switch currentStatus {
        case .trial, .active, .lifetime: return true
        case .expired: return false
        }
    }

    var daysRemaining: Int {
        switch currentStatus {
        case .trial(let days): return days
        case .active: return Int.max
        case .expired: return 0
        case .lifetime: return Int.max
        }
    }

    var maxCapturesPerDay: Int {
        switch currentTier {
        case .free: return 3
        case .basic, .pro: return Int.max
        }
    }

    var maxTrustedCircleMembers: Int {
        switch currentTier {
        case .free: return 1
        case .basic: return 5
        case .pro: return Int.max
        }
    }

    var maxFamilyCircleMembers: Int {
        switch currentTier {
        case .free: return 3
        case .basic: return 10
        case .pro: return Int.max
        }
    }

    private let userDefaults = UserDefaults.standard
    private let statusKey = "subscription_status"
    private let tierKey = "subscription_tier"
    private let trialStartKey = "trial_start_date"

    private init() {
        loadStatus()
    }

    // MARK: - Trial Management

    func startTrial() {
        let trialStart = Date()
        userDefaults.set(trialStart, forKey: trialStartKey)
        currentStatus = .trial(daysRemaining: 7)
        currentTier = .free
        saveStatus()
    }

    func checkTrialStatus() {
        guard let trialStart = userDefaults.object(forKey: trialStartKey) as? Date else {
            startTrial()
            return
        }

        let daysSinceStart = Calendar.current.dateComponents([.day], from: trialStart, to: Date()).day ?? 0
        let daysRemaining = max(0, 7 - daysSinceStart)

        if daysRemaining > 0 {
            currentStatus = .trial(daysRemaining: daysRemaining)
        } else if case .trial = currentStatus {
            // Trial expired, check if user has active subscription
            currentStatus = .expired
        }
    }

    // MARK: - Subscription Activation

    func activateSubscription(tier: Tier) {
        currentTier = tier
        currentStatus = .active(tier: tier)
        saveStatus()
    }

    func activateLifetime() {
        currentTier = .pro
        currentStatus = .lifetime
        saveStatus()
    }

    func expireSubscription() {
        currentStatus = .expired
        saveStatus()
    }

    // MARK: - Feature Access

    func canUseFeature(_ feature: Feature) -> Bool {
        switch feature {
        case .unlimitedCaptures:
            return currentTier != .free || daysRemaining > 0

        case .trustedCircle:
            return currentTier == .pro || currentTier == .basic || daysRemaining > 0

        case .familyCircle:
            return currentTier == .pro || currentTier == .basic || daysRemaining > 0

        case .socialComparison:
            return currentTier == .pro || currentTier == .basic || daysRemaining > 0

        case .legacyExport:
            return currentTier == .pro || daysRemaining > 0

        case .memorialMode:
            return currentTier == .pro || daysRemaining > 0

        case .prioritySupport:
            return currentTier == .pro
        }
    }

    enum Feature {
        case unlimitedCaptures
        case trustedCircle
        case familyCircle
        case socialComparison
        case legacyExport
        case memorialMode
        case prioritySupport
    }

    // MARK: - Capture Limits

    func canCapture() -> Bool {
        return isActive
    }

    func remainingCapturesToday() -> Int? {
        if currentTier != .free { return nil } // Unlimited

        let today = Calendar.current.startOfDay(for: Date())
        let captures = getTodayCaptures()

        if captures >= 3 {
            return 0
        }
        return 3 - captures
    }

    func recordCapture() {
        let today = Calendar.current.startOfDay(for: Date())
        let key = "captures_\(today.timeIntervalSince1970)"
        let count = userDefaults.integer(forKey: key)
        userDefaults.set(count + 1, forKey: key)
    }

    private func getTodayCaptures() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        let key = "captures_\(today.timeIntervalSince1970)"
        return userDefaults.integer(forKey: key)
    }

    // MARK: - Persistence

    private func saveStatus() {
        userDefaults.set(currentTier.rawValue, forKey: tierKey)

        switch currentStatus {
        case .trial(let days):
            userDefaults.set("trial_\(days)", forKey: statusKey)
        case .active(let tier):
            userDefaults.set("active_\(tier.rawValue)", forKey: statusKey)
        case .expired:
            userDefaults.set("expired", forKey: statusKey)
        case .lifetime:
            userDefaults.set("lifetime", forKey: statusKey)
        }
    }

    private func loadStatus() {
        guard let statusString = userDefaults.string(forKey: statusKey) else {
            startTrial()
            return
        }

        if statusString.hasPrefix("trial_") {
            let days = Int(statusString.replacingOccurrences(of: "trial_", with: "")) ?? 0
            currentStatus = .trial(daysRemaining: days)
            currentTier = .free
        } else if statusString.hasPrefix("active_") {
            let tierString = statusString.replacingOccurrences(of: "active_", with: "")
            let tier = Tier(rawValue: tierString) ?? .free
            currentStatus = .active(tier: tier)
            currentTier = tier
        } else if statusString == "expired" {
            currentStatus = .expired
        } else if statusString == "lifetime" {
            currentStatus = .lifetime
            currentTier = .pro
        }

        checkTrialStatus()
    }

    // MARK: - Restore

    func restorePurchases() async -> Bool {
        // Simulate restore - in production this would call StoreKit
        return true
    }

    // MARK: - Demo / Preview

    func activateDemo() {
        // For demo purposes, activate Pro
        activateLifetime()
    }
}
