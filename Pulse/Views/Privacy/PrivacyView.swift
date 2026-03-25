import SwiftUI

struct PrivacyView: View {
    @State private var viewModel = PrivacyViewModel()
    @State private var subscriptionService = SubscriptionService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.sectionSpacing) {
                    // R10: Pulse+ Upgrade Card
                    if !subscriptionService.isPro {
                        PulseUpgradeCard()
                            .padding(.horizontal, Theme.Spacing.screenMargin)
                    }

                    // Privacy Score Card
                    PrivacyScoreCard(score: viewModel.privacyScore, badges: viewModel.privacyBadges)
                        .padding(.horizontal, Theme.Spacing.screenMargin)

                    // Data Summary
                    DataSummaryCard(viewModel: viewModel)
                        .padding(.horizontal, Theme.Spacing.screenMargin)

                    // R4: Trusted Circles
                    TrustedCirclesCard(viewModel: viewModel)
                        .padding(.horizontal, Theme.Spacing.screenMargin)

                    // R2: Privacy Controls
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Privacy Settings")
                            .font(Theme.Typography.headlineFont)
                            .foregroundColor(Theme.Colors.charcoal)
                            .padding(.horizontal, Theme.Spacing.screenMargin)

                        // On-Device ML Toggle
                        PrivacyToggleRow(
                            icon: "cpu",
                            title: "On-Device AI",
                            subtitle: viewModel.onDeviceMLDescription,
                            isOn: Binding(
                                get: { viewModel.isOnDeviceMLEnabled },
                                set: { viewModel.isOnDeviceMLEnabled = $0 }
                            )
                        )
                        .padding(.horizontal, Theme.Spacing.screenMargin)

                        // Data Donation Toggle
                        PrivacyToggleRow(
                            icon: "heart.circle",
                            title: "Data Donation",
                            subtitle: viewModel.dataDonationDescription,
                            isOn: Binding(
                                get: { viewModel.isDataDonationEnabled },
                                set: { viewModel.isDataDonationEnabled = $0 }
                            )
                        )
                        .padding(.horizontal, Theme.Spacing.screenMargin)

                        // Privacy Audit
                        Button {
                            viewModel.runPrivacyAudit()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.shield")
                                    .foregroundColor(Theme.Colors.mutedRose)
                                Text("Run Privacy Audit")
                                    .font(Theme.Typography.bodyFont)
                                    .foregroundColor(Theme.Colors.charcoal)
                                Spacer()
                                if let lastAudit = viewModel.lastPrivacyAudit {
                                    Text(lastAudit, style: .relative)
                                        .font(Theme.Typography.captionFont)
                                        .foregroundColor(Theme.Colors.warmGray)
                                }
                            }
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                        .padding(.horizontal, Theme.Spacing.screenMargin)
                    }

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

                        NavigationLink {
                            LegacyExportView()
                        } label: {
                            HStack {
                                Image(systemName: "book.closed.fill")
                                    .foregroundColor(Theme.Colors.gentleGold)
                                Text("Legacy Export")
                                    .font(Theme.Typography.bodyFont)
                                    .foregroundColor(Theme.Colors.charcoal)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Theme.Colors.warmGray)
                            }
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                        .padding(.horizontal, Theme.Spacing.screenMargin)

                        NavigationLink {
                            MemorialModeView()
                        } label: {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(Theme.Colors.mutedRose)
                                Text("Memorial Mode")
                                    .font(Theme.Typography.bodyFont)
                                    .foregroundColor(Theme.Colors.charcoal)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Theme.Colors.warmGray)
                            }
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
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

                    // R10: Subscriptions, Legal, App Store
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("About Pulse")
                            .font(Theme.Typography.headlineFont)
                            .foregroundColor(Theme.Colors.charcoal)
                            .padding(.horizontal, Theme.Spacing.screenMargin)

                        NavigationLink {
                            SubscriptionsView()
                        } label: {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(Theme.Colors.gentleGold)
                                Text("Pulse+ Subscription")
                                    .font(Theme.Typography.bodyFont)
                                    .foregroundColor(Theme.Colors.charcoal)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Theme.Colors.warmGray)
                            }
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                        .padding(.horizontal, Theme.Spacing.screenMargin)

                        NavigationLink {
                            AppStoreListingView()
                        } label: {
                            HStack {
                                Image(systemName: "app.badge.fill")
                                    .foregroundColor(Theme.Colors.primaryAccent)
                                Text("App Store Listing")
                                    .font(Theme.Typography.bodyFont)
                                    .foregroundColor(Theme.Colors.charcoal)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Theme.Colors.warmGray)
                            }
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                        .padding(.horizontal, Theme.Spacing.screenMargin)

                        NavigationLink {
                            LegalView()
                        } label: {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(Theme.Colors.warmGray)
                                Text("Privacy Policy & Terms")
                                    .font(Theme.Typography.bodyFont)
                                    .foregroundColor(Theme.Colors.charcoal)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Theme.Colors.warmGray)
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

struct PrivacyToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isOn ? Theme.Colors.mutedRose : Theme.Colors.warmGray)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Typography.bodyFont)
                        .foregroundColor(Theme.Colors.charcoal)

                    Text(subtitle)
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.warmGray)
                        .lineLimit(2...3)
                }

                Spacer()

                Toggle("", isOn: $isOn)
                    .tint(Theme.Colors.mutedRose)
                    .labelsHidden()
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }
}

struct PrivacyScoreCard: View {
    let score: Int
    let badges: [String]

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

            // Privacy badges
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(badges, id: \.self) { badge in
                    Text(badge)
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.mutedRose)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(Theme.Colors.softBlush)
                        .cornerRadius(Theme.CornerRadius.small)
                }
                Spacer()
            }
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

// MARK: - R4: Trusted Circles Card

struct TrustedCirclesCard: View {
    @Bindable var viewModel: PrivacyViewModel
    @State private var showingAddMember = false
    @State private var showingShareSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.Colors.calmSage)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Trusted Circles")
                        .font(Theme.Typography.headlineFont)
                        .foregroundColor(Theme.Colors.charcoal)

                    Text("Share aggregate wellness with family")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.warmGray)
                }

                Spacer()

                if viewModel.circle.activeMembersCount > 0 {
                    Text("\(viewModel.circle.activeMembersCount) members")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.mutedRose)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.Colors.softBlush)
                        .cornerRadius(8)
                }
            }

            // Toggle sharing
            HStack {
                Text("Share with circle")
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(Theme.Colors.charcoal)

                Spacer()

                Toggle("", isOn: $viewModel.circle.isSharingEnabled)
                    .tint(Theme.Colors.calmSage)
                    .labelsHidden()
            }
            .padding(Theme.Spacing.sm)
            .background(Theme.Colors.softBlush.opacity(0.5))
            .cornerRadius(Theme.CornerRadius.small)

            // Members list
            if !viewModel.circle.members.isEmpty {
                ForEach(viewModel.circle.members) { member in
                    TrustedMemberRow(member: member, viewModel: viewModel)
                }
            } else {
                Text("No family members added yet")
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(Theme.Colors.warmGray)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.lg)
            }

            // Add member button
            Button {
                showingAddMember = true
            } label: {
                HStack {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(Theme.Colors.mutedRose)
                    Text("Add Family Member")
                        .font(Theme.Typography.bodyFont)
                        .foregroundColor(Theme.Colors.mutedRose)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.softBlush.opacity(0.3))
                .cornerRadius(Theme.CornerRadius.medium)
            }

            // Share settings link
            if viewModel.circle.activeMembersCount > 0 {
                Button {
                    showingShareSettings = true
                } label: {
                    HStack {
                        Image(systemName: "gearshape")
                            .foregroundColor(Theme.Colors.warmGray)
                        Text("Share Settings")
                            .font(Theme.Typography.bodyFont)
                            .foregroundColor(Theme.Colors.warmGray)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.warmGray)
                    }
                    .padding(Theme.Spacing.sm)
                }
            }

            // Privacy note
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "eye.slash.fill")
                    .foregroundColor(Theme.Colors.warmGray.opacity(0.6))
                    .font(.system(size: 10))

                Text("Individual moments are never shared — only aggregates")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.Colors.warmGray.opacity(0.6))
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .sheet(isPresented: $showingAddMember) {
            AddTrustedMemberSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingShareSettings) {
            ShareSettingsSheet(viewModel: viewModel)
        }
    }
}

struct TrustedMemberRow: View {
    let member: TrustedMember
    @Bindable var viewModel: PrivacyViewModel

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Avatar
            Circle()
                .fill(member.isEnabled ? Theme.Colors.calmSage.opacity(0.2) : Theme.Colors.warmGray.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    Text(String(member.name.prefix(1)))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(member.isEnabled ? Theme.Colors.calmSage : Theme.Colors.warmGray)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(member.isEnabled ? Theme.Colors.charcoal : Theme.Colors.warmGray)

                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: member.relationship.icon)
                        .font(.system(size: 10))
                    Text(member.relationship.rawValue)
                        .font(.system(size: 11))
                }
                .foregroundColor(Theme.Colors.warmGray)
            }

            Spacer()

            // Last shared
            if let lastShare = member.lastSharedAt {
                Text(lastShare, style: .relative)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.Colors.warmGray)
            }

            // Toggle
            Toggle("", isOn: Binding(
                get: { member.isEnabled },
                set: { _ in viewModel.toggleMember(id: member.id) }
            ))
            .tint(Theme.Colors.calmSage)
            .labelsHidden()
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.softBlush.opacity(0.3))
        .cornerRadius(Theme.CornerRadius.small)
    }
}

struct AddTrustedMemberSheet: View {
    @Bindable var viewModel: PrivacyViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedRelationship: TrustedMember.Relationship = .family

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g., Maria, Dad", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section("Relationship") {
                    Picker("Relationship", selection: $selectedRelationship) {
                        ForEach(TrustedMember.Relationship.allCases, id: \.self) { rel in
                            Label(rel.rawValue, systemImage: rel.icon)
                                .tag(rel)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section {
                    Text("You'll share aggregate wellness data with this person — no individual moments will be visible to them.")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.warmGray)
                }
            }
            .navigationTitle("Add Family Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addCircleMember(name: name, relationship: selectedRelationship)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct ShareSettingsSheet: View {
    @Bindable var viewModel: PrivacyViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("What to Share") {
                    Toggle("Average Mood Score", isOn: $viewModel.circle.shareSettings.showAverageScore)
                    Toggle("Reflection Streak", isOn: $viewModel.circle.shareSettings.showStreak)
                    Toggle("Dominant Emotion", isOn: $viewModel.circle.shareSettings.showDominantEmotion)
                    Toggle("Weekly Insights", isOn: $viewModel.circle.shareSettings.showInsights)
                    Toggle("Mood Trend", isOn: $viewModel.circle.shareSettings.showTrend)
                }

                Section("Share Frequency") {
                    Picker("Frequency", selection: $viewModel.circle.shareSettings.shareFrequency) {
                        ForEach(TrustedCircle.ShareSettings.ShareFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                }

                Section {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(Theme.Colors.calmSage)
                            .font(.system(size: 12))

                        Text("Individual moments are never shared — only aggregate summaries")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.warmGray)
                    }
                }
            }
            .navigationTitle("Share Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    PrivacyView()
}

// MARK: - R10: Pulse Upgrade Card

struct PulseUpgradeCard: View {
    @State private var subscriptionService = SubscriptionService.shared

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.gentleGold.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.Colors.gentleGold)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Upgrade to Pulse+")
                        .font(Theme.Typography.headlineFont)
                        .foregroundColor(Theme.Colors.charcoal)

                    Text("Unlimited captures, family circle & legacy export")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.warmGray)
                }

                Spacer()
            }

            HStack(spacing: Theme.Spacing.md) {
                NavigationLink {
                    SubscriptionsView()
                } label: {
                    Text("See Plans")
                        .font(Theme.Typography.calloutFont)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.cardBackground)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Spacing.sm)
                        .background(Theme.Colors.gentleGold)
                        .cornerRadius(Theme.CornerRadius.button)
                }
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(
            LinearGradient(
                colors: [Theme.Colors.gentleGold.opacity(0.1), Theme.Colors.cardBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                .stroke(Theme.Colors.gentleGold.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(Theme.CornerRadius.card)
    }
}
