import SwiftUI

/// R9: Legacy Export view — export your full emotional life as a document
struct LegacyExportView: View {
    @State private var isExporting = false
    @State private var exportedURL: URL?
    @State private var showingShareSheet = false
    @State private var selectedFormat: LegacyExportService.ExportFormat = .pdf
    @State private var errorMessage: String?
    @State private var showingError = false

    private let exportService = LegacyExportService.shared
    private let databaseService = DatabaseService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.primaryBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Header illustration
                        legacyHeader

                        // Export format picker
                        formatPickerSection

                        // What's included
                        includedSection

                        // Privacy note
                        privacyNote

                        // Export button
                        exportButton

                        Spacer(minLength: Theme.Spacing.xxl)
                    }
                    .padding(.top, Theme.Spacing.md)
                }
            }
            .navigationTitle("Legacy Export")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Export Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
        }
    }

    // MARK: - Header

    private var legacyHeader: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.gentleGold.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "book.closed.fill")
                    .font(.system(size: 44))
                    .foregroundColor(Theme.Colors.gentleGold)
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text("Your Complete Emotional History")
                    .font(Theme.Typography.headlineFont)
                    .foregroundColor(Theme.Colors.charcoal)

                Text("Export everything Pulse has learned about your emotional world — a complete record of your inner life.")
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(Theme.Colors.warmGray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
        }
        .padding(.vertical, Theme.Spacing.lg)
    }

    // MARK: - Format Picker

    private var formatPickerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Export Format")
                .font(Theme.Typography.headlineFont)
                .foregroundColor(Theme.Colors.charcoal)
                .padding(.horizontal, Theme.Spacing.screenMargin)

            VStack(spacing: Theme.Spacing.sm) {
                formatOption(
                    format: .pdf,
                    title: "PDF Document",
                    description: "Beautiful formatted document, perfect for printing or sharing",
                    icon: "doc.richtext.fill"
                )

                formatOption(
                    format: .markdown,
                    title: "Markdown",
                    description: "Plain text format for journaling apps or Obsidian",
                    icon: "text.alignleft"
                )

                formatOption(
                    format: .json,
                    title: "JSON Data",
                    description: "Raw data export for developers or backup purposes",
                    icon: "curlybraces"
                )
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
        }
    }

    private func formatOption(format: LegacyExportService.ExportFormat, title: String, description: String, icon: String) -> some View {
        Button {
            selectedFormat = format
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(selectedFormat == format ? Theme.Colors.cardBackground : Theme.Colors.primaryAccent)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Typography.calloutFont)
                        .fontWeight(.semibold)
                        .foregroundColor(selectedFormat == format ? Theme.Colors.cardBackground : Theme.Colors.charcoal)

                    Text(description)
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(selectedFormat == format ? Theme.Colors.cardBackground.opacity(0.8) : Theme.Colors.warmGray)
                }

                Spacer()

                if selectedFormat == format {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.Colors.cardBackground)
                }
            }
            .padding(Theme.Spacing.md)
            .background(selectedFormat == format ? Theme.Colors.primaryAccent : Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Included Section

    private var includedSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("What's Included")
                .font(Theme.Typography.headlineFont)
                .foregroundColor(Theme.Colors.charcoal)
                .padding(.horizontal, Theme.Spacing.screenMargin)

            let moments = databaseService.fetchAllMoments()
            let insights = databaseService.fetchRecentInsights(limit: 100)

            VStack(spacing: Theme.Spacing.sm) {
                includedItem(
                    icon: "heart.fill",
                    title: "\(moments.count) Moments",
                    description: "Every emotional capture with timestamps and emotion tags"
                )

                includedItem(
                    icon: "lightbulb.fill",
                    title: "\(insights.count) Insights",
                    description: "AI-generated insights about your emotional patterns"
                )

                includedItem(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Emotional Trends",
                    description: "Your journey visualized over time"
                )

                includedItem(
                    icon: "flame.fill",
                    title: "Streaks & Consistency",
                    description: "Your reflection streaks and consistency data"
                )
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
        }
    }

    private func includedItem(icon: String, title: String, description: String) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(Theme.Colors.primaryAccent)
                .font(.system(size: 20))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.calloutFont)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.charcoal)

                Text(description)
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.warmGray)
            }

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }

    // MARK: - Privacy Note

    private var privacyNote: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "lock.fill")
                .foregroundColor(Theme.Colors.calmSage)
                .font(.system(size: 14))

            Text("Your export is generated locally on your device. Nothing is sent to any server.")
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.warmGray)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.calmSage.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.small)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    // MARK: - Export Button

    private var exportButton: some View {
        Button {
            performExport()
        } label: {
            HStack {
                if isExporting {
                    ProgressView()
                        .tint(Theme.Colors.cardBackground)
                } else {
                    Image(systemName: "square.and.arrow.up")
                }
                Text(isExporting ? "Generating..." : "Export My Emotional Life")
            }
            .font(Theme.Typography.calloutFont)
            .fontWeight(.semibold)
            .foregroundColor(Theme.Colors.cardBackground)
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .background(isExporting ? Theme.Colors.warmGray : Theme.Colors.primaryAccent)
            .cornerRadius(Theme.CornerRadius.button)
        }
        .disabled(isExporting)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    // MARK: - Export Action

    private func performExport() {
        isExporting = true
        errorMessage = nil

        Task {
            do {
                let url = try await exportService.export(format: selectedFormat)
                await MainActor.run {
                    exportedURL = url
                    isExporting = false
                    showingShareSheet = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isExporting = false
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    LegacyExportView()
}
