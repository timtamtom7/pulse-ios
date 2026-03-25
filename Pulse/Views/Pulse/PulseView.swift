import SwiftUI

struct PulseView: View {
    @State private var viewModel = PulseViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.sectionSpacing) {
                    // Insight Card of the Week
                    if let insight = viewModel.weeklyInsight {
                        InsightCardView(insight: insight)
                            .padding(.horizontal, Theme.Spacing.screenMargin)
                    } else {
                        LoadingShimmer()
                            .frame(height: 180)
                            .padding(.horizontal, Theme.Spacing.screenMargin)
                    }

                    // Weekly Mood Ring
                    if !viewModel.weeklyMoodRing.isEmpty {
                        MoodRingView(tags: viewModel.weeklyMoodRing)
                            .padding(.horizontal, Theme.Spacing.screenMargin)
                    }

                    // Streak Counter
                    if viewModel.currentStreak > 0 {
                        StreakView(streak: viewModel.currentStreak)
                            .padding(.horizontal, Theme.Spacing.screenMargin)
                    }

                    // Recent Captures
                    if !viewModel.recentMoments.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                            Text("Recent Moments")
                                .font(Theme.Typography.headlineFont)
                                .foregroundColor(Theme.Colors.charcoal)
                                .padding(.horizontal, Theme.Spacing.screenMargin)

                            ForEach(viewModel.recentMoments) { moment in
                                MomentCard(moment: moment)
                                    .padding(.horizontal, Theme.Spacing.screenMargin)
                            }
                        }
                    }

                    Spacer(minLength: Theme.Spacing.xxl)
                }
                .padding(.top, Theme.Spacing.lg)
            }
            .background(Theme.Colors.primaryBackground)
            .navigationTitle("Pulse")
            .refreshable {
                viewModel.refresh()
            }
        }
    }
}

struct MoodRingView: View {
    let tags: [EmotionTag]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("This Week's Mood")
                .font(Theme.Typography.headlineFont)
                .foregroundColor(Theme.Colors.charcoal)

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(tags.prefix(5)) { tag in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(tag.color)
                            .frame(width: 40, height: 40)
                            .overlay {
                                Text(String(tag.label.prefix(1)))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }

                        Text(tag.label)
                            .font(Theme.Typography.captionFont)
                            .foregroundColor(Theme.Colors.warmGray)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct StreakView: View {
    let streak: Int

    var body: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundColor(Theme.Colors.gentleGold)
                .font(.system(size: 24))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak)-day streak")
                    .font(Theme.Typography.headlineFont)
                    .foregroundColor(Theme.Colors.charcoal)

                Text("Keep capturing moments!")
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.warmGray)
            }

            Spacer()
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

#Preview {
    PulseView()
}
