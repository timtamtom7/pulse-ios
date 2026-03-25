import SwiftUI

/// R9: Memorial Mode view — honoring a loved one's emotional journey
struct MemorialModeView: View {
    @State private var memorialService = MemorialService.shared
    @State private var showingAddMemorial = false
    @State private var newMemorialName = ""
    @State private var newMemorialRelationship = "Grandparent"

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.primaryBackground.ignoresSafeArea()

                if memorialService.memorialAccounts.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .navigationTitle("Memorial")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddMemorial = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Theme.Colors.primaryAccent)
                    }
                }
            }
            .sheet(isPresented: $showingAddMemorial) {
                addMemorialSheet
            }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Memorial description
                memorialHeader

                // Memorial accounts
                ForEach(memorialService.memorialAccounts) { account in
                    if let summary = memorialService.generateMemorialSummary(for: account.id) {
                        MemorialCard(summary: summary)
                    }
                }

                Spacer(minLength: Theme.Spacing.xxl)
            }
            .padding(.top, Theme.Spacing.md)
        }
    }

    // MARK: - Header

    private var memorialHeader: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "heart.fill")
                .font(.system(size: 32))
                .foregroundColor(Theme.Colors.mutedRose)

            Text("Their journey lives on")
                .font(Theme.Typography.headlineFont)
                .foregroundColor(Theme.Colors.charcoal)

            Text("Pulse holds space for the emotional lives of those we've lost. Each memorial is a quiet tribute — a way to remember, reflect, and carry love forward.")
                .font(Theme.Typography.insightBody)
                .foregroundColor(Theme.Colors.warmGray)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.softBlush.opacity(0.5))
                    .frame(width: 120, height: 120)

                Image(systemName: "heart.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Theme.Colors.mutedRose)
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text("Honor a Loved One")
                    .font(Theme.Typography.headlineFont)
                    .foregroundColor(Theme.Colors.charcoal)

                Text("Create a memorial for someone you've lost. Pulse will preserve their emotional journey — a record of their inner world as they saw it.")
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(Theme.Colors.warmGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }

            Button {
                showingAddMemorial = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Memorial")
                }
                .font(Theme.Typography.calloutFont)
                .foregroundColor(Theme.Colors.cardBackground)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
                .background(Theme.Colors.mutedRose)
                .cornerRadius(Theme.CornerRadius.button)
            }

            // Preview option
            Button {
                memorialService.createSampleMemorial()
            } label: {
                Text("Preview with sample memorial")
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.warmGray)
            }
        }
    }

    // MARK: - Add Memorial Sheet

    private var addMemorialSheet: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.primaryBackground.ignoresSafeArea()

                VStack(spacing: Theme.Spacing.lg) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.softBlush)
                            .frame(width: 80, height: 80)

                        Image(systemName: "heart.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Theme.Colors.mutedRose)
                    }
                    .padding(.top, Theme.Spacing.lg)

                    // Name field
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Name")
                            .font(Theme.Typography.calloutFont)
                            .foregroundColor(Theme.Colors.secondaryText)

                        TextField("e.g., Grandma Elena", text: $newMemorialName)
                            .font(Theme.Typography.bodyFont)
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.CornerRadius.small)
                    }

                    // Relationship
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Relationship")
                            .font(Theme.Typography.calloutFont)
                            .foregroundColor(Theme.Colors.secondaryText)

                        TextField("e.g., Grandmother", text: $newMemorialRelationship)
                            .font(Theme.Typography.bodyFont)
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.CornerRadius.small)
                    }

                    // Info text
                    VStack(spacing: Theme.Spacing.sm) {
                        Text("How it works")
                            .font(Theme.Typography.calloutFont)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.Colors.primaryText)

                        Text("When a loved one's family shares their emotional summaries with you, those moments will appear here as a memorial. This is a place of remembrance — read-only, always private.")
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(Theme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.softBlush.opacity(0.5))
                    .cornerRadius(Theme.CornerRadius.medium)

                    Spacer()

                    Button {
                        let _ = memorialService.createMemorial(name: newMemorialName, relationship: newMemorialRelationship)
                        newMemorialName = ""
                        newMemorialRelationship = "Grandparent"
                        showingAddMemorial = false
                    } label: {
                        Text("Create Memorial")
                            .font(Theme.Typography.calloutFont)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.Colors.cardBackground)
                            .frame(maxWidth: .infinity)
                            .padding(Theme.Spacing.md)
                            .background(newMemorialName.isEmpty ? Theme.Colors.secondaryText : Theme.Colors.mutedRose)
                            .cornerRadius(Theme.CornerRadius.button)
                    }
                    .disabled(newMemorialName.isEmpty)
                    .padding(.horizontal, Theme.Spacing.screenMargin)
                    .padding(.bottom, Theme.Spacing.lg)
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
            }
            .navigationTitle("Create Memorial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAddMemorial = false
                    }
                    .foregroundColor(Theme.Colors.secondaryText)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Memorial Card

struct MemorialCard: View {
    let summary: MemorialService.MemorialSummary
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Header
            HStack(spacing: Theme.Spacing.md) {
                // Memorial avatar
                ZStack {
                    Circle()
                        .fill(Theme.Colors.mutedRose.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Text(String(summary.name.prefix(1)))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Theme.Colors.mutedRose)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.name)
                        .font(Theme.Typography.headlineFont)
                        .foregroundColor(Theme.Colors.charcoal)

                    Text(summary.relationship)
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.warmGray)

                    Text("Memorialized \(summary.memorializedAt, style: .date)")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.warmGray)
                }

                Spacer()

                Image(systemName: "heart.fill")
                    .foregroundColor(Theme.Colors.mutedRose)
                    .font(.system(size: 24))
            }

            // Celebrating text
            Text(summary.celebratingText)
                .font(Theme.Typography.insightBody)
                .foregroundColor(Theme.Colors.charcoal)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)

            // Stats
            HStack(spacing: Theme.Spacing.xl) {
                memorialStat(value: "\(summary.totalMoments)", label: "Moments")
                memorialStat(value: "\(Int(summary.averageEmotionScore * 100))%", label: "Avg Score")
                memorialStat(value: summary.dominantEmotion, label: "Top Feeling")
            }

            // Expandable content
            if isExpanded {
                expandedContent
            }

            // Toggle
            Button {
                withAnimation(Theme.Animations.gentleEaseOut) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(isExpanded ? "Show less" : "View their journey")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.warmGray)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.warmGray)
                }
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                .stroke(Theme.Colors.mutedRose.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Theme.Colors.charcoal.opacity(0.08), radius: 16, y: 4)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    private func memorialStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.charcoal)

            Text(label)
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.warmGray)
        }
        .frame(maxWidth: .infinity)
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Divider()

            // Last check-in
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(Theme.Colors.warmGray)
                    .font(.system(size: 14))

                Text("Last check-in: \(summary.lastCheckInFormatted)")
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.warmGray)
            }

            // Total days
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Theme.Colors.warmGray)
                    .font(.system(size: 14))

                Text("Journey spanned \(summary.totalDays) day\(summary.totalDays == 1 ? "" : "s")")
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.warmGray)
            }

            // Top insights
            if !summary.topInsights.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Remembering...")
                        .font(Theme.Typography.calloutFont)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.charcoal)

                    ForEach(summary.topInsights, id: \.self) { insight in
                        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(Theme.Colors.mutedRose)
                                .font(.system(size: 10))
                                .padding(.top, 2)

                            Text(insight)
                                .font(Theme.Typography.captionFont)
                                .foregroundColor(Theme.Colors.charcoal)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    MemorialModeView()
}
