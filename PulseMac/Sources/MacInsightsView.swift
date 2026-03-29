import SwiftUI
import Charts

struct MacInsightsView: View {
    @Bindable var viewModel: PulseViewModel
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: MacTheme.Spacing.sectionSpacing) {
                headerSection

                if viewModel.isLoading {
                    loadingSection
                } else {
                    insightsContent
                }
            }
            .padding(MacTheme.Spacing.screenMargin)
        }
        .background(MacTheme.Colors.cream)
        .onAppear {
            withAnimation(MacTheme.Animations.cardAppear.delay(0.1)) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Pulse")
                        .font(MacTheme.Typography.displayFont)
                        .foregroundColor(MacTheme.Colors.charcoal)

                    Text(todayLabel)
                        .font(MacTheme.Typography.captionFont)
                        .foregroundColor(MacTheme.Colors.warmGray)
                }

                Spacer()

                if viewModel.currentStreak > 0 {
                    streakBadge
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    private var todayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    private var streakBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .foregroundColor(MacTheme.Colors.gentleGold)
            Text("\(viewModel.currentStreak) day streak")
                .font(MacTheme.Typography.calloutFont)
                .foregroundColor(MacTheme.Colors.charcoal)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(MacTheme.Colors.warmWhite)
        .cornerRadius(MacTheme.CornerRadius.large)
        .shadow(color: MacTheme.Colors.cardShadow, radius: 8, y: 2)
    }

    // MARK: - Loading

    private var loadingSection: some View {
        VStack(spacing: MacTheme.Spacing.md) {
            ForEach(0..<3) { _ in
                RoundedRectangle(cornerRadius: MacTheme.CornerRadius.card)
                    .fill(MacTheme.Colors.softBlush.opacity(0.5))
                    .frame(height: 120)
            }
        }
    }

    // MARK: - Insights Content

    @ViewBuilder
    private var insightsContent: some View {
        // Insight Card of the Week
        if let insight = viewModel.weeklyInsight {
            insightCard(insight)
        }

        // Top Emotions This Week
        if !viewModel.weeklyMoodRing.isEmpty {
            emotionCardsSection
        }

        // Trend Chart
        if !viewModel.recentMoments.isEmpty {
            trendChartSection
        }

        // What's Influencing You
        influencingSection

        // Recent Moments
        if !viewModel.recentMoments.isEmpty {
            recentMomentsSection
        }
    }

    // MARK: - Insight Card

    private func insightCard(_ insight: Insight) -> some View {
        VStack(alignment: .leading, spacing: MacTheme.Spacing.md) {
            HStack {
                Image(systemName: insight.category.icon)
                    .foregroundColor(MacTheme.Colors.mutedRose)
                    .font(.system(size: 18))

                Text("Weekly Insight")
                    .font(MacTheme.Typography.captionFont)
                    .foregroundColor(MacTheme.Colors.warmGray)
                    .textCase(.uppercase)
                    .tracking(1)

                Spacer()
            }

            Text(insight.title)
                .font(MacTheme.Typography.headlineFont)
                .foregroundColor(MacTheme.Colors.charcoal)

            Text(insight.body)
                .font(MacTheme.Typography.bodyFont)
                .foregroundColor(MacTheme.Colors.warmGray)
                .lineLimit(4)
        }
        .padding(MacTheme.Spacing.cardPadding)
        .background(
            LinearGradient(
                colors: [MacTheme.Colors.mutedRose.opacity(0.08), MacTheme.Colors.warmWhite],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(MacTheme.CornerRadius.card)
        .shadow(color: MacTheme.Colors.cardShadow, radius: 16, y: 4)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    // MARK: - Emotion Cards

    private var emotionCardsSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.Spacing.md) {
            Text("Top Emotions This Week")
                .font(MacTheme.Typography.headlineFont)
                .foregroundColor(MacTheme.Colors.charcoal)

            HStack(spacing: MacTheme.Spacing.md) {
                ForEach(Array(viewModel.weeklyMoodRing.prefix(3).enumerated()), id: \.element.id) { index, tag in
                    emotionCard(tag, index: index)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom)),
            removal: .opacity
        ))
    }

    private func emotionCard(_ tag: EmotionTag, index: Int) -> some View {
        VStack(spacing: MacTheme.Spacing.sm) {
            Circle()
                .fill(tag.color)
                .frame(width: 56, height: 56)
                .overlay {
                    Text(String(tag.label.prefix(1)))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .shadow(color: tag.color.opacity(0.4), radius: 8, y: 4)

            Text(tag.label)
                .font(MacTheme.Typography.calloutFont)
                .foregroundColor(MacTheme.Colors.charcoal)

            Text("\(Int(tag.confidence * 100))%")
                .font(MacTheme.Typography.captionFont)
                .foregroundColor(MacTheme.Colors.warmGray)
        }
        .frame(maxWidth: .infinity)
        .padding(MacTheme.Spacing.lg)
        .background(MacTheme.Colors.warmWhite)
        .cornerRadius(MacTheme.CornerRadius.card)
        .shadow(color: MacTheme.Colors.cardShadow, radius: 12, y: 4)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom)),
            removal: .opacity
        ))
    }

    // MARK: - Trend Chart

    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.Spacing.md) {
            Text("Emotional Pattern")
                .font(MacTheme.Typography.headlineFont)
                .foregroundColor(MacTheme.Colors.charcoal)

            Chart {
                ForEach(chartDataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(MacTheme.Colors.mutedRose)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [MacTheme.Colors.mutedRose.opacity(0.3), MacTheme.Colors.mutedRose.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                        .foregroundStyle(MacTheme.Colors.warmGray)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(MacTheme.Colors.softBlush)
                    AxisValueLabel {
                        if let score = value.as(Double.self) {
                            Text(scoreLabel(score))
                                .font(MacTheme.Typography.captionFont)
                                .foregroundStyle(MacTheme.Colors.warmGray)
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding(MacTheme.Spacing.cardPadding)
            .background(MacTheme.Colors.warmWhite)
            .cornerRadius(MacTheme.CornerRadius.card)
            .shadow(color: MacTheme.Colors.cardShadow, radius: 12, y: 4)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    private var chartDataPoints: [ChartDataPoint] {
        let calendar = Calendar.current
        var points: [ChartDataPoint] = []

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let dayStart = calendar.startOfDay(for: date)

            let dayMoments = viewModel.recentMoments.filter {
                calendar.isDate($0.timestamp, inSameDayAs: dayStart)
            }

            let avgScore = dayMoments.isEmpty
                ? 0.0
                : dayMoments.map(\.emotionScore).reduce(0, +) / Double(dayMoments.count)

            points.append(ChartDataPoint(date: dayStart, score: avgScore))
        }

        return points
    }

    private func scoreLabel(_ score: Double) -> String {
        if score > 0.5 { return "High" }
        if score > 0 { return "Med" }
        if score > -0.5 { return "Low" }
        return "Very Low"
    }

    struct ChartDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let score: Double
    }

    // MARK: - What's Influencing You

    private var influencingSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.Spacing.md) {
            Text("What's Influencing You")
                .font(MacTheme.Typography.headlineFont)
                .foregroundColor(MacTheme.Colors.charcoal)

            HStack(spacing: MacTheme.Spacing.md) {
                influencingCard(
                    icon: "calendar",
                    title: "Calendar Patterns",
                    detail: "Busier mornings tend to bring more energy"
                )

                influencingCard(
                    icon: "pencil.line",
                    title: "Journal Entries",
                    detail: "\(viewModel.recentMoments.filter { $0.type == .journal }.count) entries this week"
                )

                influencingCard(
                    icon: "clock.fill",
                    title: "Time of Day",
                    detail: "Evening captures show more reflection"
                )
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    private func influencingCard(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: MacTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(MacTheme.Colors.mutedRose)
                .frame(width: 40, height: 40)
                .background(MacTheme.Colors.softBlush)
                .cornerRadius(MacTheme.CornerRadius.medium)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(MacTheme.Typography.calloutFont)
                    .foregroundColor(MacTheme.Colors.charcoal)

                Text(detail)
                    .font(MacTheme.Typography.captionFont)
                    .foregroundColor(MacTheme.Colors.warmGray)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MacTheme.Spacing.md)
        .background(MacTheme.Colors.warmWhite)
        .cornerRadius(MacTheme.CornerRadius.card)
        .shadow(color: MacTheme.Colors.cardShadow, radius: 8, y: 2)
    }

    // MARK: - Recent Moments

    private var recentMomentsSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.Spacing.md) {
            Text("Recent Moments")
                .font(MacTheme.Typography.headlineFont)
                .foregroundColor(MacTheme.Colors.charcoal)

            ForEach(viewModel.recentMoments.prefix(3)) { moment in
                MacMomentRow(moment: moment)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }
}

// MARK: - Moment Row

struct MacMomentRow: View {
    let moment: Moment

    var body: some View {
        HStack(spacing: MacTheme.Spacing.md) {
            // Emotion indicator
            Circle()
                .fill(dominantColor)
                .frame(width: 12, height: 12)

            // Type icon
            Image(systemName: moment.type.icon)
                .font(.system(size: 16))
                .foregroundColor(MacTheme.Colors.warmGray)
                .frame(width: 24)

            // Content preview
            VStack(alignment: .leading, spacing: 2) {
                Text(moment.type.displayName)
                    .font(MacTheme.Typography.calloutFont)
                    .foregroundColor(MacTheme.Colors.charcoal)

                Text(contentPreview)
                    .font(MacTheme.Typography.captionFont)
                    .foregroundColor(MacTheme.Colors.warmGray)
                    .lineLimit(1)
            }

            Spacer()

            // Tags
            HStack(spacing: 4) {
                ForEach(moment.emotionTags.prefix(2)) { tag in
                    Text(tag.label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(tag.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(tag.color.opacity(0.15))
                        .cornerRadius(4)
                }
            }

            // Time
            Text(moment.formattedTime)
                .font(MacTheme.Typography.monoFont)
                .foregroundColor(MacTheme.Colors.warmGray)
        }
        .padding(MacTheme.Spacing.md)
        .background(MacTheme.Colors.warmWhite)
        .cornerRadius(MacTheme.CornerRadius.medium)
        .shadow(color: MacTheme.Colors.cardShadow, radius: 6, y: 2)
    }

    private var dominantColor: Color {
        moment.emotionTags.first?.color ?? MacTheme.Colors.neutral
    }

    private var contentPreview: String {
        switch moment.type {
        case .photo:
            return "Photo capture"
        case .voice:
            return moment.content.prefix(50).description + (moment.content.count > 50 ? "..." : "")
        case .journal:
            return moment.content.prefix(60).description + (moment.content.count > 60 ? "..." : "")
        }
    }
}

#Preview {
    MacInsightsView(viewModel: PulseViewModel())
}
