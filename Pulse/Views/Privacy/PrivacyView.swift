import SwiftUI

struct PrivacyView: View {
    @State private var viewModel = PrivacyViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.sectionSpacing) {
                    // Privacy Score Card
                    PrivacyScoreCard(score: viewModel.privacyScore)
                        .padding(.horizontal, Theme.Spacing.screenMargin)

                    // Data Summary
                    DataSummaryCard(viewModel: viewModel)
                        .padding(.horizontal, Theme.Spacing.screenMargin)

                    // Connected Sources
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Data Sources")
                            .font(Theme.Typography.headlineFont)
                            .foregroundColor(Theme.Colors.charcoal)
                            .padding(.horizontal, Theme.Spacing.screenMargin)

                        ForEach(viewModel.dataSources) { source in
                            DataSourceRow(
                                dataSource: source,
                                onToggle: {
                                    Task {
                                        await viewModel.toggleDataSource(source)
                                    }
                                }
                            )
                            .padding(.horizontal, Theme.Spacing.screenMargin)
                        }

                        NavigationLink {
                            DataSourcesDetailView(viewModel: viewModel)
                        } label: {
                            HStack {
                                Text("Manage Data Sources")
                                    .font(Theme.Typography.bodyFont)
                                    .foregroundColor(Theme.Colors.mutedRose)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Theme.Colors.warmGray)
                            }
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                        .padding(.horizontal, Theme.Spacing.screenMargin)
                    }

                    // Data Controls
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Data Controls")
                            .font(Theme.Typography.headlineFont)
                            .foregroundColor(Theme.Colors.charcoal)
                            .padding(.horizontal, Theme.Spacing.screenMargin)

                        Button {
                            viewModel.exportData()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(Theme.Colors.mutedRose)
                                Text("Export My Data")
                                    .font(Theme.Typography.bodyFont)
                                    .foregroundColor(Theme.Colors.charcoal)
                                Spacer()
                                if viewModel.isExporting {
                                    ProgressView()
                                        .tint(Theme.Colors.warmGray)
                                }
                            }
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                        .disabled(viewModel.isExporting)
                        .padding(.horizontal, Theme.Spacing.screenMargin)

                        Button {
                            viewModel.showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(Theme.Colors.deepEmber)
                                Text("Delete All Data")
                                    .font(Theme.Typography.bodyFont)
                                    .foregroundColor(Theme.Colors.deepEmber)
                                Spacer()
                            }
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                        .padding(.horizontal, Theme.Spacing.screenMargin)
                    }

                    Spacer(minLength: Theme.Spacing.xxl)
                }
                .padding(.top, Theme.Spacing.lg)
            }
            .background(Theme.Colors.primaryBackground)
            .navigationTitle("Privacy")
            .alert("Delete All Data", isPresented: $viewModel.showDeleteConfirmation) {
                TextField("Type DELETE to confirm", text: $viewModel.deleteConfirmationText)
                    .textInputAutocapitalization(.characters)
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    viewModel.deleteAllData()
                }
            } message: {
                Text("This will permanently delete all your moments, insights, and analysis data. This action cannot be undone.")
            }
        }
    }
}

struct PrivacyScoreCard: View {
    let score: Int

    var scoreColor: Color {
        switch score {
        case 80...100: return Theme.Colors.calmSage
        case 60..<80: return Theme.Colors.gentleGold
        default: return Theme.Colors.mutedRose
        }
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.Colors.mutedRose)

                Text("Privacy Score")
                    .font(Theme.Typography.headlineFont)
                    .foregroundColor(Theme.Colors.charcoal)

                Spacer()
            }

            HStack(alignment: .bottom, spacing: Theme.Spacing.md) {
                Text("\(score)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(scoreColor)

                Text("/ 100")
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(Theme.Colors.warmGray)
                    .padding(.bottom, 8)

                Spacer()
            }

            // Score bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.Colors.softBlush)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(scoreColor)
                        .frame(width: geometry.size.width * CGFloat(score) / 100, height: 8)
                }
            }
            .frame(height: 8)

            Text("Your data is protected with on-device processing and encryption")
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.warmGray)
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct DataSummaryCard: View {
    let viewModel: PrivacyViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("What Pulse Knows")
                .font(Theme.Typography.headlineFont)
                .foregroundColor(Theme.Colors.charcoal)

            Text(viewModel.dataSummaryText)
                .font(Theme.Typography.bodyFont)
                .foregroundColor(Theme.Colors.warmGray)

            HStack(spacing: Theme.Spacing.lg) {
                StatItem(count: viewModel.photoCount, label: "Photos", icon: "photo.fill")
                StatItem(count: viewModel.voiceNoteCount, label: "Voice", icon: "waveform")
                StatItem(count: viewModel.journalCount, label: "Journal", icon: "pencil.line")
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct StatItem: View {
    let count: Int
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Theme.Colors.mutedRose)

            Text("\(count)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.charcoal)

            Text(label)
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.warmGray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DataSourceRow: View {
    let dataSource: DataSource
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: dataSource.type.icon)
                .font(.system(size: 20))
                .foregroundColor(dataSource.isConnected ? Theme.Colors.mutedRose : Theme.Colors.warmGray)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(dataSource.type.displayName)
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(Theme.Colors.charcoal)

                Text(dataSource.statusText)
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.warmGray)
            }

            Spacer()

            if dataSource.isConnected {
                Circle()
                    .fill(Theme.Colors.calmSage)
                    .frame(width: 8, height: 8)
            }

            Toggle("", isOn: Binding(
                get: { dataSource.isConnected },
                set: { _ in onToggle() }
            ))
            .tint(Theme.Colors.mutedRose)
            .labelsHidden()
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }
}

#Preview {
    PrivacyView()
}
