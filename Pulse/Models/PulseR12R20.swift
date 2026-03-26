import Foundation

// MARK: - Pulse R12-R20: Family & Care Team Sharing, Platform

struct CareTeam: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var ownerID: String
    var memberIDs: [String]
    var memberRole: [String: MemberRole]
    var isActive: Bool
    var createdAt: Date
    
    enum MemberRole: String, Codable {
        case admin, caregiver, healthcareProvider, familyMember, patient
    }
    
    init(id: UUID = UUID(), name: String, ownerID: String, memberIDs: [String] = [], memberRole: [String: MemberRole] = [:], isActive: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.ownerID = ownerID
        self.memberIDs = memberIDs
        self.memberRole = memberRole
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

struct SharePermission: Identifiable, Codable, Equatable {
    let id: UUID
    var recipientID: String
    var recipientName: String
    var dataTypes: [DataType]
    var permissionLevel: PermissionLevel
    var expiresAt: Date?
    var isRevoked: Bool
    
    enum DataType: String, Codable {
        case heartRate, sleep, steps, workouts, weight, nutrition, stress, bloodPressure, glucose, medication, notes
    }
    
    enum PermissionLevel: String, Codable {
        case viewOnly = "View Only"
        case viewAndComment = "View & Comment"
        case fullAccess = "Full Access"
    }
    
    init(id: UUID = UUID(), recipientID: String, recipientName: String, dataTypes: [DataType] = [], permissionLevel: PermissionLevel = .viewOnly, expiresAt: Date? = nil, isRevoked: Bool = false) {
        self.id = id
        self.recipientID = recipientID
        self.recipientName = recipientName
        self.dataTypes = dataTypes
        self.permissionLevel = permissionLevel
        self.expiresAt = expiresAt
        self.isRevoked = isRevoked
    }
}

struct HealthReport: Identifiable, Codable, Equatable {
    let id: UUID
    var reportType: ReportType
    var dateRange: DateRange
    var summary: String
    var keyMetrics: [KeyMetric]
    var trendCharts: [String] // chart identifiers
    var createdAt: Date
    var sharedWithIDs: [String]
    
    enum ReportType: String, Codable {
        case weekly = "Weekly Summary"
        case monthly = "Monthly Report"
        case quarterly = "Quarterly Review"
        case custom = "Custom Report"
    }
    
    struct DateRange: Codable, Equatable {
        var startDate: Date
        var endDate: Date
    }
    
    struct KeyMetric: Identifiable, Codable, Equatable {
        let id: UUID
        var name: String
        var value: String
        var change: Double
        var trend: Trend
        
        enum Trend: String, Codable {
            case up, down, stable
        }
    }
    
    init(id: UUID = UUID(), reportType: ReportType, dateRange: DateRange, summary: String = "", keyMetrics: [KeyMetric] = [], trendCharts: [String] = [], createdAt: Date = Date(), sharedWithIDs: [String] = []) {
        self.id = id
        self.reportType = reportType
        self.dateRange = dateRange
        self.summary = summary
        self.keyMetrics = keyMetrics
        self.trendCharts = trendCharts
        self.createdAt = createdAt
        self.sharedWithIDs = sharedWithIDs
    }
}

struct HealthcareProvider: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var specialty: String
    var clinicName: String
    var contactEmail: String
    var isConnected: Bool
    var linkedAt: Date?
    
    init(id: UUID = UUID(), name: String, specialty: String, clinicName: String = "", contactEmail: String = "", isConnected: Bool = false, linkedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.specialty = specialty
        self.clinicName = clinicName
        self.contactEmail = contactEmail
        self.isConnected = isConnected
        self.linkedAt = linkedAt
    }
}

struct PulseSubscriptionTier: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var displayName: String
    var monthlyPrice: Decimal
    var annualPrice: Decimal
    var lifetimePrice: Decimal
    var features: [String]
    var isMostPopular: Bool
    
    static let free = PulseSubscriptionTier(id: UUID(), name: "free", displayName: "Free", monthlyPrice: 0, annualPrice: 0, lifetimePrice: 0, features: ["Basic tracking", "3 data types", "Simple charts"], isMostPopular: false)
    static let plus = PulseSubscriptionTier(id: UUID(), name: "plus", displayName: "Plus", monthlyPrice: 5.99, annualPrice: 59.99, lifetimePrice: 99, features: ["Unlimited data types", "Care team sharing", "Health reports", "Healthcare provider links"], isMostPopular: true)
    static let family = PulseSubscriptionTier(id: UUID(), name: "family", displayName: "Family", monthlyPrice: 9.99, annualPrice: 95.88, lifetimePrice: 0, features: ["Up to 6 members", "Shared care team", "Priority support", "Family analytics"], isMostPopular: false)
}

struct SupportedLocale: Identifiable, Codable, Equatable {
    let id: UUID
    var code: String
    var displayName: String
    
    static let supported: [SupportedLocale] = [
        SupportedLocale(id: UUID(), code: "en", displayName: "English"),
        SupportedLocale(id: UUID(), code: "es", displayName: "Spanish"),
        SupportedLocale(id: UUID(), code: "fr", displayName: "French"),
    ]
}

struct CrossPlatformDevice: Identifiable, Codable, Equatable {
    let id: UUID
    var deviceName: String
    var platform: Platform
    
    enum Platform: String, Codable { case ios, android, web }
    
    init(id: UUID = UUID(), deviceName: String, platform: Platform) {
        self.id = id
        self.deviceName = deviceName
        self.platform = platform
    }
}

struct AwardSubmission: Identifiable, Codable, Equatable {
    let id: UUID
    var awardName: String
    var category: String
    var status: Status
    
    enum Status: String, Codable { case draft, submitted, inReview, won, rejected }
    
    init(id: UUID = UUID(), awardName: String, category: String, status: Status = .draft) {
        self.id = id
        self.awardName = awardName
        self.category = category
        self.status = status
    }
}

struct PulseAPI: Codable, Equatable {
    var clientID: String
    var tier: APITier
    
    enum APITier: String, Codable { case free, paid }
    
    init(clientID: String = UUID().uuidString, tier: APITier = .free) {
        self.clientID = clientID
        self.tier = tier
    }
}
