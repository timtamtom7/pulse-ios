import SwiftUI

/// R4: Trusted circles — family members see aggregate emotional data
struct TrustedCircleView: View {
    @State private var circleService = TrustedCircleService.shared
    @State private var showingAddMember = false
    @State private var showingShareSettings = false
    @State private var newMemberName = ""
    @State private var newMemberRelationship: TrustedMember.Relationship = .spouse

    private let databaseService = DatabaseService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.primaryBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Circle header
                        circleHeader

                        // Privacy notice
                        privacyNotice

                        // Members list
                        if circleService.circle.members.isEmpty {
                            emptyMembersView
                        } else {
                            membersList
                        }

                        // Recent shares
                        if !circleService.recentShares.isEmpty {
                            recentSharesSection
                        }

                        Spacer(minLength: Theme.Spacing.xxl)
                    }
                    .padding(.top, Theme.Spacing.md)
                }
            }
            .navigationTitle("Trusted Circle")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddMember = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(Theme.Colors.primaryAccent)
                    }
                }
            }
            .sheet(isPresented: $showingAddMember) {
                addMemberSheet
            }
            .sheet(isPresented: $showingShareSettings) {
                shareSettingsSheet
            }
        }
    }

    // MARK: - Circle Header

    private var circleHeader: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.md) {
                // Circle icon
                ZStack {
                    Circle()
                        .fill(Theme.Colors.calmSage.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Image(systemName: "figure.2.and.child.holdinghands")
                        .font(.title2)
                        .foregroundColor(Theme.Colors.calmSage)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(circleService.circle.name)
                        .font(Theme.Typography.headlineFont)
                        .foregroundColor(Theme.Colors.primaryText)

                    Text("\(circleService.circle.activeMembersCount) member\(circleService.circle.activeMembersCount == 1 ? "" : "s") connected")
                        .font(Theme.Typography.calloutFont)
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { circleService.circle.isSharingEnabled },
                    set: { newValue in
                        circleService.circle.isSharingEnabled = newValue
                    }
                ))
                .labelsHidden()
                .tint(Theme.Colors.calmSage)
            }

            if circleService.circle.isSharingEnabled {
                // Share settings button
                Button {
                    showingShareSettings = true
                } label: {
                    HStack {
                        Image(systemName: "gearshape.fill")
                        Text("Share Settings")
                            .font(Theme.Typography.calloutFont)
                    }
                    .foregroundColor(Theme.Colors.primaryAccent)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Theme.Colors.primaryAccent.opacity(0.1))
                    .cornerRadius(Theme.CornerRadius.button)
                }
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    // MARK: - Privacy Notice

    private var privacyNotice: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "lock.shield.fill")
                .foregroundColor(Theme.Colors.calmSage)

            Text("Only aggregate summaries are shared — individual moments are never exposed.")
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.calmSage.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.small)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    // MARK: - Empty Members

    private var emptyMembersView: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 40))
                .foregroundColor(Theme.Colors.mutedRose.opacity(0.5))

            Text("No family members added yet")
                .font(Theme.Typography.calloutFont)
                .foregroundColor(Theme.Colors.secondaryText)

            Button {
                showingAddMember = true
            } label: {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Add First Member")
                }
                .font(Theme.Typography.calloutFont)
                .foregroundColor(Theme.Colors.cardBackground)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Colors.primaryAccent)
                .cornerRadius(Theme.CornerRadius.button)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    // MARK: - Members List

    private var membersList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Members")
                .font(Theme.Typography.headlineFont)
                .foregroundColor(Theme.Colors.primaryText)
                .padding(.horizontal, Theme.Spacing.screenMargin)

            ForEach(circleService.circle.members) { member in
                MemberRow(
                    member: member,
                    onToggle: { circleService.toggleMember(id: member.id) },
                    onRemove: { circleService.removeMember(id: member.id) }
                )
                .padding(.horizontal, Theme.Spacing.screenMargin)
            }
        }
    }

    // MARK: - Recent Shares

    private var recentSharesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Recent Shares")
                .font(Theme.Typography.headlineFont)
                .foregroundColor(Theme.Colors.primaryText)
                .padding(.horizontal, Theme.Spacing.screenMargin)

            ForEach(circleService.recentShares) { share in
                if let member = circleService.circle.members.first(where: { $0.id == share.memberId }) {
                    SharePreviewCard(share: share, member: member)
                        .padding(.horizontal, Theme.Spacing.screenMargin)
                }
            }
        }
    }

    // MARK: - Add Member Sheet

    private var addMemberSheet: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.primaryBackground.ignoresSafeArea()

                VStack(spacing: Theme.Spacing.lg) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.calmSage.opacity(0.2))
                            .frame(width: 80, height: 80)

                        Image(systemName: newMemberRelationship.icon)
                            .font(.largeTitle)
                            .foregroundColor(Theme.Colors.calmSage)
                    }
                    .padding(.top, Theme.Spacing.lg)

                    // Name field
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Name")
                            .font(Theme.Typography.calloutFont)
                            .foregroundColor(Theme.Colors.secondaryText)

                        TextField("e.g., Maria", text: $newMemberName)
                            .font(Theme.Typography.bodyFont)
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.CornerRadius.small)
                    }

                    // Relationship picker
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Relationship")
                            .font(Theme.Typography.calloutFont)
                            .foregroundColor(Theme.Colors.secondaryText)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.sm) {
                            ForEach(TrustedMember.Relationship.allCases, id: \.self) { relationship in
                                Button {
                                    newMemberRelationship = relationship
                                } label: {
                                    HStack {
                                        Image(systemName: relationship.icon)
                                        Text(relationship.rawValue)
                                    }
                                    .font(Theme.Typography.calloutFont)
                                    .foregroundColor(newMemberRelationship == relationship ? Theme.Colors.cardBackground : Theme.Colors.primaryText)
                                    .frame(maxWidth: .infinity)
                                    .padding(Theme.Spacing.sm)
                                    .background(newMemberRelationship == relationship ? Theme.Colors.primaryAccent : Theme.Colors.cardBackground)
                                    .cornerRadius(Theme.CornerRadius.small)
                                }
                            }
                        }
                    }

                    Spacer()

                    // Add button
                    Button {
                        circleService.addMember(name: newMemberName, relationship: newMemberRelationship)
                        newMemberName = ""
                        showingAddMember = false
                    } label: {
                        Text("Add to Circle")
                            .font(Theme.Typography.calloutFont)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.Colors.cardBackground)
                            .frame(maxWidth: .infinity)
                            .padding(Theme.Spacing.md)
                            .background(newMemberName.isEmpty ? Theme.Colors.secondaryText : Theme.Colors.primaryAccent)
                            .cornerRadius(Theme.CornerRadius.button)
                    }
                    .disabled(newMemberName.isEmpty)
                    .padding(.horizontal, Theme.Spacing.screenMargin)
                    .padding(.bottom, Theme.Spacing.lg)
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
            }
            .navigationTitle("Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddMember = false }
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Share Settings Sheet

    private var shareSettingsSheet: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.primaryBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        let settings = circleService.circle.shareSettings

                        // Frequency
                        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                            Text("Share Frequency")
                                .font(Theme.Typography.calloutFont)
                                .fontWeight(.semibold)
                                .foregroundColor(Theme.Colors.primaryText)

                            ForEach(TrustedCircle.ShareSettings.ShareFrequency.allCases, id: \.self) { frequency in
                                Button {
                                    var newSettings = settings
                                    newSettings.shareFrequency = frequency
                                    circleService.updateShareSettings(newSettings)
                                } label: {
                                    HStack {
                                        Text(frequency.rawValue)
                                            .font(Theme.Typography.bodyFont)
                                            .foregroundColor(Theme.Colors.primaryText)
                                        Spacer()
                                        if settings.shareFrequency == frequency {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(Theme.Colors.calmSage)
                                        }
                                    }
                                    .padding(Theme.Spacing.md)
                                    .background(Theme.Colors.cardBackground)
                                    .cornerRadius(Theme.CornerRadius.small)
                                }
                            }
                        }

                        // Data to share
                        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                            Text("Data to Share")
                                .font(Theme.Typography.calloutFont)
                                .fontWeight(.semibold)
                                .foregroundColor(Theme.Colors.primaryText)

                            SettingToggle(title: "Average Score", isOn: Binding(
                                get: { settings.showAverageScore },
                                set: { newValue in
                                    var s = settings; s.showAverageScore = newValue; circleService.updateShareSettings(s)
                                }
                            ))

                            SettingToggle(title: "Reflection Streak", isOn: Binding(
                                get: { settings.showStreak },
                                set: { newValue in
                                    var s = settings; s.showStreak = newValue; circleService.updateShareSettings(s)
                                }
                            ))

                            SettingToggle(title: "Dominant Emotion", isOn: Binding(
                                get: { settings.showDominantEmotion },
                                set: { newValue in
                                    var s = settings; s.showDominantEmotion = newValue; circleService.updateShareSettings(s)
                                }
                            ))

                            SettingToggle(title: "Insights", isOn: Binding(
                                get: { settings.showInsights },
                                set: { newValue in
                                    var s = settings; s.showInsights = newValue; circleService.updateShareSettings(s)
                                }
                            ))

                            SettingToggle(title: "Mood Trend", isOn: Binding(
                                get: { settings.showTrend },
                                set: { newValue in
                                    var s = settings; s.showTrend = newValue; circleService.updateShareSettings(s)
                                }
                            ))

                            // Always hidden notice
                            HStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: "eye.slash.fill")
                                    .foregroundColor(Theme.Colors.calmSage)
                                    .font(.caption)
                                Text("Individual moments are always private")
                                    .font(Theme.Typography.captionFont)
                                    .foregroundColor(Theme.Colors.secondaryText)
                            }
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.calmSage.opacity(0.1))
                            .cornerRadius(Theme.CornerRadius.small)
                        }
                    }
                    .padding(Theme.Spacing.screenMargin)
                }
            }
            .navigationTitle("Share Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showingShareSettings = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Member Row

struct MemberRow: View {
    let member: TrustedMember
    let onToggle: () -> Void
    let onRemove: () -> Void

    @State private var showingRemoveAlert = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(member.isEnabled ? Theme.Colors.calmSage.opacity(0.2) : Theme.Colors.softBlush)
                    .frame(width: 44, height: 44)

                Image(systemName: member.relationship.icon)
                    .foregroundColor(member.isEnabled ? Theme.Colors.calmSage : Theme.Colors.secondaryText)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(Theme.Typography.calloutFont)
                    .fontWeight(.semibold)
                    .foregroundColor(member.isEnabled ? Theme.Colors.primaryText : Theme.Colors.secondaryText)

                Text(member.relationship.rawValue)
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.secondaryText)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { member.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .tint(Theme.Colors.calmSage)
            .onTapGesture {
                onToggle()
            }

            Button {
                showingRemoveAlert = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Theme.Colors.mutedRose.opacity(0.5))
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
        .alert("Remove \(member.name)?", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) { onRemove() }
        } message: {
            Text("They will no longer receive emotional summaries.")
        }
    }
}

// MARK: - Share Preview Card

struct SharePreviewCard: View {
    let share: CircleShare
    let member: TrustedMember

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text(member.name)
                    .font(Theme.Typography.calloutFont)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.primaryText)

                Spacer()

                Text(share.shareDate.formatted(date: .abbreviated, time: .omitted))
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.secondaryText)
            }

            HStack(spacing: Theme.Spacing.lg) {
                // Score
                VStack(spacing: 2) {
                    Text("\(Int(share.averageEmotionScore * 100))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.emotionColor(for: share.averageEmotionScore))
                    Text("Score")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                // Streak
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.gentleGold)
                        Text("\(share.streak)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.primaryText)
                    }
                    Text("Streak")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                // Trend
                VStack(spacing: 2) {
                    Image(systemName: share.moodTrend.icon)
                        .font(.title2)
                        .foregroundColor(trendColor)
                    Text(share.moodTrend.label)
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                // Dominant emotion
                VStack(spacing: 2) {
                    Text(share.dominantEmotion.prefix(1))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.primaryAccent)
                    Text("Top")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }

            if let insight = share.topInsight {
                Text(insight)
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .lineLimit(2)
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
    }

    private var trendColor: Color {
        switch share.moodTrend {
        case .up: return Theme.Colors.calmSage
        case .down: return Theme.Colors.mutedRose
        case .stable: return Theme.Colors.gentleGold
        }
    }
}

// MARK: - Setting Toggle

struct SettingToggle: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(Theme.Typography.bodyFont)
                .foregroundColor(Theme.Colors.primaryText)
        }
        .tint(Theme.Colors.calmSage)
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.small)
    }
}

#Preview {
    TrustedCircleView()
}
