import SwiftUI

/// R4: Anonymous social comparison — percentile context
/// Shows how the user compares to other Pulse users across key metrics.
struct SocialComparisonView: View {
    @State private var comparisons: [PercentileComparison] = []
    @State private var compositeInsight: PercentileInsight?
    @State private var isLoading = true

    private let socialService = SocialComparisonService.shared
    private let databaseService = DatabaseService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.primaryBackground.ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if comparisons.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { loadComparisons() }
        }
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Overall wellness index
                if let insight = compositeInsight {
                    overallCard(insight: insight)
                }

                // Privacy notice
                privacyNotice

                // Individual metric comparisons
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("Your Metrics")
                        .font(Theme.Typography.headlineFont)
                        .foregroundColor(Theme.Colors.primaryText)
                        .padding(.horizontal, Theme.Spacing.screenMargin)

                    ForEach(comparisons) { comparison in
                        PercentileCard(comparison: comparison)
                            .padding(.horizontal, Theme.Spacing.screenMargin)
                    }
                }

                // Sample size notice
                if let sampleSize = comparisons.first?.sampleSize {
                    Text("Compared against \(sampleSize.formatted()) anonymized Pulse users")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.screenMargin)
                }

                Spacer(minLength: Theme.Spacing.xxl)
            }
            .padding(.top, Theme.Spacing.md)
        }
    }

    // MARK: - Overall Card

    private func overallCard(insight: PercentileInsight) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.md) {
                // Percentile circle
                ZStack {
                    Circle()
                        .stroke(Theme.Colors.softBlush, lineWidth: 8)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: CGFloat(insight.comparison.percentile) / 100.0)
                        .stroke(
                            Theme.Colors.emotionGradient,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    Text("\(insight.comparison.percentile)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.primaryText)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall Wellness Index")
                        .font(Theme.Typography.headlineFont)
                        .foregroundColor(Theme.Colors.primaryText)

                    Text("\(insight.comparison.percentileLabel)")
                        .font(Theme.Typography.calloutFont)
                        .foregroundColor(Theme.Colors.primaryAccent)

                    Text("Top \(100 - insight.comparison.percentile)% of users")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                Spacer()
            }

            Text(insight.insight)
                .font(Theme.Typography.insightBody)
                .foregroundColor(Theme.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    // MARK: - Privacy Notice

    private var privacyNotice: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "eye.slash.fill")
                .foregroundColor(Theme.Colors.calmSage)

            Text("All comparisons use anonymized, aggregated data. Your individual moments are never shared.")
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.calmSage.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.small)
        .padding(.horizontal, Theme.Spacing.screenMargin)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .tint(Theme.Colors.primaryAccent)
            Text("Computing comparisons...")
                .font(Theme.Typography.bodyFont)
                .foregroundColor(Theme.Colors.secondaryText)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            PulseEmptyIllustration(size: 180)

            VStack(spacing: Theme.Spacing.sm) {
                Text("Not Enough Data")
                    .font(Theme.Typography.headlineFont)
                    .foregroundColor(Theme.Colors.primaryText)

                Text("Capture at least 7 days of moments to see how you compare to other Pulse users.")
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
        }
    }

    // MARK: - Load Data

    private func loadComparisons() {
        isLoading = true

        Task {
            let moments = databaseService.fetchAllMoments()
            let aggregated = AggregatedMetrics.sample

            // Calculate user stats
            let avgScore = moments.isEmpty ? 0.0 : moments.map(\.emotionScore).reduce(0, +) / Double(moments.count)

            // Calculate streak
            var streak = 0
            var checkDate = Date()
            let calendar = Calendar.current
            for _ in 0..<30 {
                let hasMoment = moments.contains { calendar.isDate($0.timestamp, inSameDayAs: checkDate) }
                if hasMoment { streak += 1 }
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            }

            comparisons = await socialService.generateComparisons(
                userMoments: moments,
                userStreak: streak,
                userAverageScore: avgScore,
                aggregatedMetrics: aggregated
            )

            compositeInsight = await socialService.generateCompositeInsight(comparisons: comparisons)

            isLoading = false
        }
    }
}

// MARK: - Percentile Card

struct PercentileCard: View {
    let comparison: PercentileComparison

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(comparison.metricName)
                        .font(Theme.Typography.calloutFont)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.primaryText)

                    Text(comparison.metricDescription)
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                Spacer()

                // Direction icon
                Image(systemName: comparison.comparisonDirection.icon)
                    .font(.title2)
                    .foregroundColor(directionColor)
            }

            // Percentile bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(comparison.percentile)%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.primaryText)

                    Text(comparison.percentileLabel)
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(directionColor)

                    Spacer()

                    Text("vs \(Int(comparison.averageValue * 100)) avg")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.extraSmall)
                            .fill(Theme.Colors.softBlush)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: Theme.CornerRadius.extraSmall)
                            .fill(Theme.Colors.emotionGradient)
                            .frame(width: geometry.size.width * CGFloat(comparison.percentile) / 100.0, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
    }

    private var directionColor: Color {
        switch comparison.comparisonDirection {
        case .aboveAverage: return Theme.Colors.calmSage
        case .average: return Theme.Colors.gentleGold
        case .belowAverage: return Theme.Colors.mutedRose
        }
    }
}

#Preview {
    SocialComparisonView()
}
