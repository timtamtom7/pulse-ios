import SwiftUI
import UniformTypeIdentifiers

struct MacSettingsView: View {
    @State private var iCloudSync = false
    @State private var notifications = true
    @State private var healthKitIntegration = false
    @State private var calendarIntegration = false
    @State private var photoLibraryIntegration = false
    @State private var speechRecognition = false

    @State private var showingExportSheet = false
    @State private var showingDeleteAlert = false
    @State private var exportData: Data?

    var body: some View {
        ScrollView {
            VStack(spacing: MacTheme.Spacing.sectionSpacing) {
                headerSection

                privacySection

                dataSourcesSection

                notificationsSection

                dataManagementSection
            }
            .padding(MacTheme.Spacing.screenMargin)
        }
        .background(MacTheme.Colors.cream)
        .alert("Delete All Data", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Everything", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("This will permanently delete all your moments, insights, and emotional data. This action cannot be undone.")
        }
        .fileExporter(
            isPresented: $showingExportSheet,
            document: exportData.map { ExportDocument(data: $0) },
            contentType: .json,
            defaultFilename: "pulse_export_\(dateString)"
        ) { result in
            switch result {
            case .success:
                break
            case .failure:
                break
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.Spacing.sm) {
            Text("Settings")
                .font(MacTheme.Typography.displayFont)
                .foregroundColor(MacTheme.Colors.charcoal)

            Text("Manage your privacy and data preferences")
                .font(MacTheme.Typography.bodyFont)
                .foregroundColor(MacTheme.Colors.warmGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: MacTheme.Spacing.md) {
            sectionHeader("Privacy", icon: "lock.shield.fill")

            VStack(spacing: 0) {
                privacyRow(
                    icon: "icloud.fill",
                    title: "iCloud Sync",
                    description: "Sync your data across devices with end-to-end encryption",
                    toggle: $iCloudSync
                )

                Divider().padding(.leading, 56)

                privacyRow(
                    icon: "heart.fill",
                    title: "HealthKit Integration",
                    description: "Read health data to correlate with emotions",
                    toggle: $healthKitIntegration
                )
            }
            .background(MacTheme.Colors.warmWhite)
            .cornerRadius(MacTheme.CornerRadius.card)
            .shadow(color: MacTheme.Colors.cardShadow, radius: 8, y: 2)
        }
    }

    private func privacyRow(icon: String, title: String, description: String, toggle: Binding<Bool>) -> some View {
        HStack(spacing: MacTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(MacTheme.Colors.mutedRose)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MacTheme.Typography.calloutFont)
                    .foregroundColor(MacTheme.Colors.charcoal)

                Text(description)
                    .font(MacTheme.Typography.captionFont)
                    .foregroundColor(MacTheme.Colors.warmGray)
                    .lineLimit(2)
            }

            Spacer()

            Toggle("", isOn: toggle)
                .toggleStyle(.switch)
                .tint(MacTheme.Colors.mutedRose)
        }
        .padding(MacTheme.Spacing.md)
    }

    // MARK: - Data Sources Section

    private var dataSourcesSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.Spacing.md) {
            sectionHeader("Connected Sources", icon: "link")

            VStack(spacing: 0) {
                dataSourceRow(
                    icon: "calendar",
                    title: "Calendar",
                    description: "Read events to understand your schedule patterns",
                    connected: calendarIntegration,
                    onToggle: { calendarIntegration = $0 }
                )

                Divider().padding(.leading, 56)

                dataSourceRow(
                    icon: "photo.fill",
                    title: "Photo Library",
                    description: "Analyze photos for emotional insights",
                    connected: photoLibraryIntegration,
                    onToggle: { photoLibraryIntegration = $0 }
                )

                Divider().padding(.leading, 56)

                dataSourceRow(
                    icon: "waveform",
                    title: "Speech Recognition",
                    description: "Transcribe voice notes for deeper analysis",
                    connected: speechRecognition,
                    onToggle: { speechRecognition = $0 }
                )
            }
            .background(MacTheme.Colors.warmWhite)
            .cornerRadius(MacTheme.CornerRadius.card)
            .shadow(color: MacTheme.Colors.cardShadow, radius: 8, y: 2)
        }
    }

    private func dataSourceRow(icon: String, title: String, description: String, connected: Bool, onToggle: @escaping (Bool) -> Void) -> some View {
        HStack(spacing: MacTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(connected ? MacTheme.Colors.calmSage : MacTheme.Colors.warmGray)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MacTheme.Typography.calloutFont)
                    .foregroundColor(MacTheme.Colors.charcoal)

                Text(description)
                    .font(MacTheme.Typography.captionFont)
                    .foregroundColor(MacTheme.Colors.warmGray)
                    .lineLimit(2)
            }

            Spacer()

            HStack(spacing: 8) {
                Circle()
                    .fill(connected ? MacTheme.Colors.calmSage : MacTheme.Colors.warmGray.opacity(0.3))
                    .frame(width: 8, height: 8)

                Text(connected ? "Connected" : "Not connected")
                    .font(MacTheme.Typography.captionFont)
                    .foregroundColor(connected ? MacTheme.Colors.calmSage : MacTheme.Colors.warmGray)

                Toggle("", isOn: Binding(
                    get: { connected },
                    set: { onToggle($0) }
                ))
                .toggleStyle(.switch)
                .tint(MacTheme.Colors.mutedRose)
            }
        }
        .padding(MacTheme.Spacing.md)
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.Spacing.md) {
            sectionHeader("Notifications", icon: "bell.fill")

            VStack(spacing: 0) {
                HStack(spacing: MacTheme.Spacing.md) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18))
                        .foregroundColor(MacTheme.Colors.mutedRose)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Check-in Reminder")
                            .font(MacTheme.Typography.calloutFont)
                            .foregroundColor(MacTheme.Colors.charcoal)

                        Text("Gentle reminder to capture your mood each evening")
                            .font(MacTheme.Typography.captionFont)
                            .foregroundColor(MacTheme.Colors.warmGray)
                            .lineLimit(2)
                    }

                    Spacer()

                    Toggle("", isOn: $notifications)
                        .toggleStyle(.switch)
                        .tint(MacTheme.Colors.mutedRose)
                }
                .padding(MacTheme.Spacing.md)
            }
            .background(MacTheme.Colors.warmWhite)
            .cornerRadius(MacTheme.CornerRadius.card)
            .shadow(color: MacTheme.Colors.cardShadow, radius: 8, y: 2)
        }
    }

    // MARK: - Data Management Section

    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.Spacing.md) {
            sectionHeader("Data Management", icon: "externaldrive.fill")

            VStack(spacing: 0) {
                // Export data
                Button {
                    exportDataTapped()
                } label: {
                    HStack(spacing: MacTheme.Spacing.md) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                            .foregroundColor(MacTheme.Colors.mutedRose)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export My Data")
                                .font(MacTheme.Typography.calloutFont)
                                .foregroundColor(MacTheme.Colors.charcoal)

                            Text("Download all your emotional insights as JSON")
                                .font(MacTheme.Typography.captionFont)
                                .foregroundColor(MacTheme.Colors.warmGray)
                                .lineLimit(2)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(MacTheme.Colors.warmGray)
                    }
                    .padding(MacTheme.Spacing.md)
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 56)

                // Delete all data
                Button {
                    showingDeleteAlert = true
                } label: {
                    HStack(spacing: MacTheme.Spacing.md) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18))
                            .foregroundColor(MacTheme.Colors.destructive)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Delete All Data")
                                .font(MacTheme.Typography.calloutFont)
                                .foregroundColor(MacTheme.Colors.destructiveText)

                            Text("Permanently remove all moments and insights")
                                .font(MacTheme.Typography.captionFont)
                                .foregroundColor(MacTheme.Colors.warmGray)
                                .lineLimit(2)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(MacTheme.Colors.warmGray)
                    }
                    .padding(MacTheme.Spacing.md)
                }
                .buttonStyle(.plain)
            }
            .background(MacTheme.Colors.warmWhite)
            .cornerRadius(MacTheme.CornerRadius.card)
            .shadow(color: MacTheme.Colors.cardShadow, radius: 8, y: 2)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(MacTheme.Colors.mutedRose)

            Text(title)
                .font(MacTheme.Typography.headlineFont)
                .foregroundColor(MacTheme.Colors.charcoal)
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func exportDataTapped() {
        // Gather data for export
        let database = DatabaseService.shared
        let moments = database.fetchAllMoments()

        let exportObject = ExportData(
            exportDate: Date(),
            momentsCount: moments.count,
            moments: moments
        )

        if let jsonData = try? JSONEncoder().encode(exportObject) {
            exportData = jsonData
            showingExportSheet = true
        }
    }

    private func deleteAllData() {
        let database = DatabaseService.shared
        let moments = database.fetchAllMoments()
        for moment in moments {
            try? database.deleteMoment(id: moment.id)
        }
    }
}

// MARK: - Export Data Model

struct ExportData: Codable {
    let exportDate: Date
    let momentsCount: Int
    let moments: [Moment]
}

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

#Preview {
    MacSettingsView()
}
