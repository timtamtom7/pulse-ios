import Foundation
import SwiftUI

@Observable
final class PrivacyViewModel: @unchecked Sendable {
    var dataSources: [DataSource] = []
    var totalMoments = 0
    var photoCount = 0
    var voiceNoteCount = 0
    var journalCount = 0
    var privacyScore: Int = 100
    var isExporting = false
    var showDeleteConfirmation = false
    var deleteConfirmationText = ""
    var errorMessage: String?

    // R2: Privacy hardening
    var isOnDeviceMLEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isOnDeviceMLEnabled, forKey: "isOnDeviceMLEnabled")
        }
    }
    var isDataDonationEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isDataDonationEnabled, forKey: "isDataDonationEnabled")
        }
    }
    var encryptionStatus: String = "Encrypted at rest"
    var lastPrivacyAudit: Date?

    private let database = DatabaseService.shared
    private let permissionService = PermissionService.shared

    init() {
        loadData()
        loadPrivacyPreferences()
    }

    func loadData() {
        dataSources = database.fetchAllDataSources()

        let summary = database.dataSummary()
        totalMoments = summary.photos + summary.voiceNotes + summary.journalEntries
        photoCount = summary.photos
        voiceNoteCount = summary.voiceNotes
        journalCount = summary.journalEntries

        calculatePrivacyScore()
    }

    private func loadPrivacyPreferences() {
        isOnDeviceMLEnabled = UserDefaults.standard.object(forKey: "isOnDeviceMLEnabled") as? Bool ?? true
        isDataDonationEnabled = UserDefaults.standard.bool(forKey: "isDataDonationEnabled")
        lastPrivacyAudit = UserDefaults.standard.object(forKey: "lastPrivacyAudit") as? Date
    }

    private func calculatePrivacyScore() {
        var score = 100

        // Deduct for connected data sources
        let connectedCount = dataSources.filter { $0.isConnected }.count
        score -= connectedCount * 5

        // R2: Deduct for data donation
        if isDataDonationEnabled {
            score -= 10
        }

        // R2: Add points for on-device ML (bonus)
        if isOnDeviceMLEnabled {
            score = min(100, score + 5)
        }

        // Ensure minimum score
        privacyScore = max(50, min(100, score))
    }

    func toggleDataSource(_ dataSource: DataSource) async {
        if dataSource.isConnected {
            // Disconnect
            var updated = dataSource
            updated.isConnected = false
            updated.lastSyncedAt = nil
            try? database.updateDataSource(updated)
        } else {
            // Connect - request permission
            let granted: PermissionStatus

            switch dataSource.type {
            case .photosLibrary:
                granted = await permissionService.requestPhotosPermission()
            case .calendar:
                granted = await permissionService.requestCalendarPermission()
            case .voiceNotes:
                granted = await permissionService.requestMicrophonePermission()
            case .health:
                granted = await HealthKitService.shared.requestAuthorization() ? .authorized : .denied
            case .journal:
                // Journal doesn't need special permission
                granted = .authorized
            }

            var updated = dataSource
            if granted == .authorized {
                updated.isConnected = true
                updated.lastSyncedAt = Date()
                try? database.updateDataSource(updated)
            } else {
                await MainActor.run {
                    errorMessage = "Permission denied for \(dataSource.type.displayName). Please enable it in Settings."
                }
            }
        }

        await MainActor.run {
            loadData()
        }
    }

    func exportData() {
        isExporting = true

        guard let data = database.exportAllData(),
              let jsonString = String(data: data, encoding: .utf8) else {
            errorMessage = "Failed to export data"
            isExporting = false
            return
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("pulse_export.json")
        do {
            try jsonString.write(to: tempURL, atomically: true, encoding: .utf8)

            #if canImport(UIKit)
            Task { @MainActor in
                let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    rootVC.present(activityVC, animated: true)
                }
                self.isExporting = false
            }
            #endif
        } catch {
            errorMessage = "Failed to save export file: \(error.localizedDescription)"
            isExporting = false
        }
    }

    func deleteAllData() {
        guard deleteConfirmationText == "DELETE" else { return }

        try? database.deleteAllMoments()
        try? database.deleteAllInsights()

        // Reset data source counts
        var updatedSources = dataSources
        for i in updatedSources.indices {
            updatedSources[i].dataPointCount = 0
            try? database.updateDataSource(updatedSources[i])
        }

        deleteConfirmationText = ""
        showDeleteConfirmation = false
        loadData()
    }

    func deleteDataSource(_ dataSource: DataSource) {
        var updated = dataSource
        updated.isConnected = false
        updated.lastSyncedAt = nil
        updated.dataPointCount = 0
        try? database.updateDataSource(updated)
        loadData()
    }

    func runPrivacyAudit() {
        lastPrivacyAudit = Date()
        UserDefaults.standard.set(lastPrivacyAudit, forKey: "lastPrivacyAudit")
        loadData()
    }

    // R2: Privacy info
    var onDeviceMLDescription: String {
        if isOnDeviceMLEnabled {
            return "All AI analysis happens on your device. Your emotional data never leaves your phone."
        } else {
            return "AI analysis may use cloud services. Enable on-device ML for maximum privacy."
        }
    }

    var dataDonationDescription: String {
        if isDataDonationEnabled {
            return "Anonymous usage data helps improve Pulse. No personal information is shared."
        } else {
            return "Share anonymous data to help improve Pulse for everyone."
        }
    }

    var privacyBadges: [String] {
        var badges = ["Encrypted at rest"]
        if isOnDeviceMLEnabled {
            badges.append("On-device AI")
        }
        if !isDataDonationEnabled {
            badges.append("No data sharing")
        }
        return badges
    }

    var connectedSourcesCount: Int {
        dataSources.filter { $0.isConnected }.count
    }

    var dataSummaryText: String {
        "Pulse knows \(totalMoments) moments about you: \(photoCount) photos, \(voiceNoteCount) voice notes, \(journalCount) journal entries"
    }
}
