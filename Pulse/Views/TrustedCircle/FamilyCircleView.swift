import SwiftUI

/// R9: Family Circle — aggregate emotional health of close group
struct FamilyCircleView: View {
    @State private var familyService = FamilyCircleService.shared
    @State private var showingAddSample = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.primaryBackground.ignoresSafeArea()

                if familyService.familyMoments.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .navigationTitle("Family Circle")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            familyService.addSampleFamilyData()
                        } label: {
                            Label("Add Sample Data", systemImage: "chart.bar.fill")
                        }

                        if !familyService.familyMoments.isEmpty {
                            Button(role: .destructive) {
                                familyService.clearFamilyData()
                            } label: {
                                Label("Clear Family Data", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(Theme.Colors.primaryAccent)
                    }
                }
            }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Weekly summary header
                if let summary = familyService.weeklySummary {
                    weeklySummaryCard(summary)
                }

                // Family energy bar
                if let summary = familyService.weeklySummary {
                    familyEnergySection(summary)
                }

                // Member summaries
                if let summary = familyService.weeklySummary, !summary.memberSummaries.isEmpty {
                    memberSummariesSection(summary)
                }

                // Recent family moments
                recentMomentsSection

                Spacer(minLength: Theme.Spacing.xxl)
            }
            .padding(.top, Theme.Spacing.md)
        }
    }

    // MARK: - Weekly Summary Card

    private func weeklySummaryCard(_ summary: FamilyCircleService.FamilyWeeklySummary) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Your Family's Week")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.warmGray)
                        .textCase(.uppercase)
                        .tracking(1)

                    Text(summary.formattedDateRange)
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.warmGray)
                }

                Spacer()

                // Trend indicator
                HStack(spacing: 4) {
                    Image(systemName: summary.trend.icon)
                    Text(summary.trend.label)
                }
                .font(Theme.Typography.captionFont)
                .foregroundColor(trendColor(summary.trend))
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(trendColor(summary.trend).opacity(0.1))
                .cornerRadius(Theme.CornerRadius.small)
            }

            // Family insight text
            Text(summary.familyInsight)
                .font(Theme.Typography.insightBody)
                .foregroundColor(Theme.Colors.charcoal)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Stats row
            HStack(spacing: Theme.Spacing.xl) {
                statItem(
                    value: "\(summary.activeMembers)",
                    label: "Members",
                    icon: "person.2.fill"
                )

                statItem(
                    value: "\(summary.totalCheckIns)",
                    label: "Check-ins",
                    icon: "heart.fill"
                )

                statItem(
                    value: "\(Int(summary.averageEmotionScore * 100))%",
                    label: "Avg Score",
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(
            LinearGradient(
                colors: [Theme.Colors.calmSage.opacity(0.15), Theme.Colors.cardBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                .stroke(Theme.Colors.softBlush, lineWidth: 1)
        )
        .shadow(color: Theme.Colors.charcoal.opacity(0.08), radius: 16, y: 4)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .foregroundColor(Theme.Colors.primaryAccent)
                .font(.system(size: 16))

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.charcoal)

            Text(label)
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.warmGray)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Family Energy Section

    private func familyEnergySection(_ summary: FamilyCircleService.FamilyWeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Family Energy")
                .font(Theme.Typography.headlineFont)
                .foregroundColor(Theme.Colors.charcoal)

            HStack(spacing: Theme.Spacing.lg) {
                // Energy ring
                ZStack {
                    Circle()
                        .stroke(Theme.Colors.softBlush, lineWidth: 10)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: CGFloat((summary.averageEmotionScore + 1) / 2))
                        .stroke(Theme.Colors.emotionColor(for: summary.averageEmotionScore), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(summary.averageEmotionScore * 100))%")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.charcoal)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Text("Top emotion:")
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(Theme.Colors.warmGray)

                        EmotionTagView(tag: EmotionTag(
                            category: EmotionCategory(rawValue: summary.dominantEmotion.lowercased()) ?? .neutral,
                            confidence: 1.0
                        ))
                    }

                    Text(energyDescription(for: summary.averageEmotionScore))
                        .font(Theme.Typography.insightBody)
                        .foregroundColor(Theme.Colors.charcoal)
                }

                Spacer()
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    private func energyDescription(for score: Double) -> String {
        switch score {
        case 0.6...1.0:
            return "Your family is radiating warmth and joy this week. Great energy!"
        case 0.2..<0.6:
            return "A positive week for the family with moments of connection."
        case -0.2..<0.2:
            return "A steady week. Some quiet moments, some vibrant ones."
        case -0.6..<(-0.2):
            return "A challenging week. Family support makes a difference."
        default:
            return "A difficult week. Your family's collective resilience is being tested."
        }
    }

    // MARK: - Member Summaries

    private func memberSummariesSection(_ summary: FamilyCircleService.FamilyWeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Member Summaries")
                .font(Theme.Typography.headlineFont)
                .foregroundColor(Theme.Colors.charcoal)
                .padding(.horizontal, Theme.Spacing.screenMargin)

            ForEach(summary.memberSummaries) { member in
                FamilyMemberRow(member: member)
                    .padding(.horizontal, Theme.Spacing.screenMargin)
            }
        }
    }

    // MARK: - Recent Moments

    private var recentMomentsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Recent Family Moments")
                .font(Theme.Typography.headlineFont)
                .foregroundColor(Theme.Colors.charcoal)
                .padding(.horizontal, Theme.Spacing.screenMargin)

            ForEach(familyService.familyMoments.sorted(by: { $0.timestamp > $1.timestamp }).prefix(5)) { moment in
                FamilyMomentRow(moment: moment)
                    .padding(.horizontal, Theme.Spacing.screenMargin)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.calmSage.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "figure.2.and.child.holdinghands")
                    .font(.system(size: 48))
                    .foregroundColor(Theme.Colors.calmSage)
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text("No Family Circle Yet")
                    .font(Theme.Typography.headlineFont)
                    .foregroundColor(Theme.Colors.charcoal)

                Text("When your trusted family members share their emotional summaries, they'll appear here as a collective family view.")
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(Theme.Colors.warmGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }

            Button {
                familyService.addSampleFamilyData()
            } label: {
                HStack {
                    Image(systemName: "chart.bar.fill")
                    Text("Preview with Sample Data")
                }
                .font(Theme.Typography.calloutFont)
                .foregroundColor(Theme.Colors.cardBackground)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
                .background(Theme.Colors.primaryAccent)
                .cornerRadius(Theme.CornerRadius.button)
            }
        }
    }

    // MARK: - Helpers

    private func trendColor(_ trend: FamilyCircleService.FamilyWeeklySummary.Trend) -> Color {
        switch trend {
        case .up: return Theme.Colors.calmSage
        case .down: return Theme.Colors.mutedRose
        case .stable: return Theme.Colors.gentleGold
        }
    }
}

// MARK: - Family Member Row

struct FamilyMemberRow: View {
    let member: FamilyCircleService.FamilyWeeklySummary.MemberSummary

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Theme.Colors.calmSage.opacity(0.2))
                    .frame(width: 44, height: 44)

                Text(String(member.memberName.prefix(1)))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.Colors.calmSage)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(member.memberName)
                    .font(Theme.Typography.calloutFont)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.charcoal)

                Text("\(member.checkInCount) check-in\(member.checkInCount == 1 ? "" : "s")")
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.warmGray)
            }

            Spacer()

            // Score and trend
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text("\(Int(member.averageScore * 100))%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.emotionColor(for: member.averageScore))

                    Image(systemName: member.trend.icon)
                        .font(.system(size: 12))
                        .foregroundColor(trendColor(member.trend))
                }

                Text(member.dominantEmotion)
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.warmGray)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }

    private func trendColor(_ trend: FamilyCircleService.FamilyWeeklySummary.Trend) -> Color {
        switch trend {
        case .up: return Theme.Colors.calmSage
        case .down: return Theme.Colors.mutedRose
        case .stable: return Theme.Colors.gentleGold
        }
    }
}

// MARK: - Family Moment Row

struct FamilyMomentRow: View {
    let moment: FamilyCircleService.FamilyMoment

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Emotion indicator
            Circle()
                .fill(emotionColor)
                .frame(width: 32, height: 32)
                .overlay {
                    Text(String(moment.dominantEmotion.prefix(1)))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(moment.memberName) felt \(moment.dominantEmotion)")
                    .font(Theme.Typography.calloutFont)
                    .foregroundColor(Theme.Colors.charcoal)

                Text("\(moment.formattedDate) at \(moment.formattedTime)")
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.warmGray)
            }

            Spacer()

            Text("\(Int(moment.emotionScore * 100))%")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.emotionColor(for: moment.emotionScore))
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }

    private var emotionColor: Color {
        switch moment.emotionColor {
        case "calmSage": return Theme.Colors.calmSage
        case "gentleGold": return Theme.Colors.gentleGold
        case "mutedRose": return Theme.Colors.mutedRose
        case "warmGray": return Theme.Colors.warmGray
        default: return Theme.Colors.neutral
        }
    }
}

#Preview {
    FamilyCircleView()
}
