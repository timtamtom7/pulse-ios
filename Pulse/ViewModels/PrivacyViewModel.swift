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

    private let database = DatabaseService.shared
    private let permissionService = PermissionService.shared

    init() {
        loadData()
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

    private func calculatePrivacyScore() {
        var score = 100

        // Deduct for connected data sources
        let connectedCount = dataSources.filter { $0.isConnected }.count
        score -= connectedCount * 5

        // Ensure minimum score of 70 for basic functionality
        privacyScore = max(70, min(100, score))
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
                // HealthKit would need separate permission
                granted = .denied
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
                errorMessage = "Permission denied for \(dataSource.type.displayName). Please enable it in Settings."
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

    var connectedSourcesCount: Int {
        dataSources.filter { $0.isConnected }.count
    }

    var dataSummaryText: String {
        "Pulse knows \(totalMoments) moments about you: \(photoCount) photos, \(voiceNoteCount) voice notes, \(journalCount) journal entries"
    }
}
