import Foundation
import Combine

final class PulseR12R20Service: ObservableObject, @unchecked Sendable {
    static let shared = PulseR12R20Service()
    
    @Published var careTeams: [CareTeam] = []
    @Published var sharePermissions: [SharePermission] = []
    @Published var healthReports: [HealthReport] = []
    @Published var healthcareProviders: [HealthcareProvider] = []
    @Published var currentTier: PulseSubscriptionTier = .free
    @Published var crossPlatformDevices: [CrossPlatformDevice] = []
    @Published var awardSubmissions: [AwardSubmission] = []
    @Published var apiCredentials: PulseAPI?
    
    private let userDefaults = UserDefaults.standard
    
    private init() { loadFromDisk() }
    
    func createCareTeam(name: String, ownerID: String) -> CareTeam {
        let team = CareTeam(name: name, ownerID: ownerID)
        careTeams.append(team)
        saveToDisk()
        return team
    }
    
    func addTeamMember(teamID: UUID, memberID: String, role: CareTeam.MemberRole) {
        guard let index = careTeams.firstIndex(where: { $0.id == teamID }) else { return }
        if !careTeams[index].memberIDs.contains(memberID) {
            careTeams[index].memberIDs.append(memberID)
        }
        careTeams[index].memberRole[memberID] = role
        saveToDisk()
    }
    
    func grantPermission(recipientID: String, recipientName: String, dataTypes: [SharePermission.DataType], level: SharePermission.PermissionLevel) -> SharePermission {
        let permission = SharePermission(recipientID: recipientID, recipientName: recipientName, dataTypes: dataTypes, permissionLevel: level)
        sharePermissions.append(permission)
        saveToDisk()
        return permission
    }
    
    func revokePermission(_ permissionID: UUID) {
        if let index = sharePermissions.firstIndex(where: { $0.id == permissionID }) {
            sharePermissions[index].isRevoked = true
        }
        saveToDisk()
    }
    
    func generateReport(type: HealthReport.ReportType, startDate: Date, endDate: Date, summary: String) -> HealthReport {
        let report = HealthReport(reportType: type, dateRange: HealthReport.DateRange(startDate: startDate, endDate: endDate), summary: summary)
        healthReports.append(report)
        saveToDisk()
        return report
    }
    
    func connectHealthcareProvider(name: String, specialty: String) -> HealthcareProvider {
        let provider = HealthcareProvider(name: name, specialty: specialty, isConnected: true, linkedAt: Date())
        healthcareProviders.append(provider)
        saveToDisk()
        return provider
    }
    
    func subscribe(to tier: PulseSubscriptionTier) async -> Bool {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run { currentTier = tier; saveToDisk() }
        return true
    }
    
    private func saveToDisk() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(careTeams) { userDefaults.set(data, forKey: "pulse_care_teams") }
        if let data = try? encoder.encode(sharePermissions) { userDefaults.set(data, forKey: "pulse_permissions") }
        if let data = try? encoder.encode(healthReports) { userDefaults.set(data, forKey: "pulse_reports") }
        if let data = try? encoder.encode(healthcareProviders) { userDefaults.set(data, forKey: "pulse_providers") }
        if let data = try? encoder.encode(crossPlatformDevices) { userDefaults.set(data, forKey: "pulse_devices") }
        if let data = try? encoder.encode(awardSubmissions) { userDefaults.set(data, forKey: "pulse_awards") }
    }
    
    private func loadFromDisk() {
        let decoder = JSONDecoder()
        if let data = userDefaults.data(forKey: "pulse_care_teams"),
           let decoded = try? decoder.decode([CareTeam].self, from: data) { careTeams = decoded }
        if let data = userDefaults.data(forKey: "pulse_permissions"),
           let decoded = try? decoder.decode([SharePermission].self, from: data) { sharePermissions = decoded }
        if let data = userDefaults.data(forKey: "pulse_reports"),
           let decoded = try? decoder.decode([HealthReport].self, from: data) { healthReports = decoded }
        if let data = userDefaults.data(forKey: "pulse_providers"),
           let decoded = try? decoder.decode([HealthcareProvider].self, from: data) { healthcareProviders = decoded }
        if let data = userDefaults.data(forKey: "pulse_devices"),
           let decoded = try? decoder.decode([CrossPlatformDevice].self, from: data) { crossPlatformDevices = decoded }
        if let data = userDefaults.data(forKey: "pulse_awards"),
           let decoded = try? decoder.decode([AwardSubmission].self, from: data) { awardSubmissions = decoded }
    }
}
