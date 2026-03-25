import SwiftUI

struct DataSourcesDetailView: View {
    let viewModel: PrivacyViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.sectionSpacing) {
                ForEach(viewModel.dataSources) { source in
                    DataSourceDetailCard(
                        dataSource: source,
                        onToggle: {
                            Task {
                                await viewModel.toggleDataSource(source)
                            }
                        },
                        onDelete: {
                            viewModel.deleteDataSource(source)
                        }
                    )
                }
            }
            .padding(Theme.Spacing.screenMargin)
        }
        .background(Theme.Colors.primaryBackground)
        .navigationTitle("Data Sources")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataSourceDetailCard: View {
    let dataSource: DataSource
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: dataSource.type.icon)
                    .font(.system(size: 28))
                    .foregroundColor(dataSource.isConnected ? Theme.Colors.mutedRose : Theme.Colors.warmGray)

                VStack(alignment: .leading, spacing: 4) {
                    Text(dataSource.type.displayName)
                        .font(Theme.Typography.headlineFont)
                        .foregroundColor(Theme.Colors.charcoal)

                    Text(dataSource.type.description)
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.warmGray)
                        .lineLimit(2)
                }

                Spacer()
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Status")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.warmGray)

                    HStack(spacing: Theme.Spacing.xs) {
                        Circle()
                            .fill(dataSource.isConnected ? Theme.Colors.calmSage : Theme.Colors.warmGray)
                            .frame(width: 8, height: 8)

                        Text(dataSource.statusText)
                            .font(Theme.Typography.bodyFont)
                            .foregroundColor(Theme.Colors.charcoal)
                    }
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { dataSource.isConnected },
                    set: { _ in onToggle() }
                ))
                .tint(Theme.Colors.mutedRose)
                .labelsHidden()
            }

            if dataSource.isConnected && dataSource.dataPointCount > 0 {
                HStack {
                    Text("Data points: \(dataSource.dataPointCount)")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.warmGray)

                    Spacer()

                    Button {
                        showDeleteAlert = true
                    } label: {
                        Text("Remove")
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(Theme.Colors.deepEmber)
                    }
                }
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .alert("Remove \(dataSource.type.displayName)?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("This will disconnect \(dataSource.type.displayName) and remove all associated data from Pulse.")
        }
    }
}

#Preview {
    NavigationStack {
        DataSourcesDetailView(viewModel: PrivacyViewModel())
    }
}
