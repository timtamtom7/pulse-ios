import SwiftUI

struct PulseView: View {
    @State private var viewModel = PulseViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.sectionSpacing) {
                    // R3: Weekly AI Narrative Report
                    if let report = viewModel.weeklyReport {
                        WeeklyNarrativeCard(report: report)
                            .padding(.horizontal, Theme.Spacing.screenMargin)
                    }

                    // R3: Mood Predictor - Tomorrow's Mood
                    if let prediction = viewModel.moodPrediction {
                        MoodPredictionCard(prediction: prediction)
                            .padding(.horizontal, Theme.Spacing.screenMargin)
                    }

                    // Insight Card of the Week
                    if let insight = viewModel.weeklyInsight {
                        InsightCardView(insight: insight)
                            .padding(.horizontal, Theme.Spacing.screenMargin)
                    } else {
                        LoadingShimmer()
                            .frame(height: 180)
                            .padding(.horizontal, Theme.Spacing.screenMargin)
                    }

                    // R3: Correlation Insights
                    if !viewModel.correlations.isEmpty {
                        CorrelationInsightsSection(correlations: viewModel.correlations)
                            .padding(.horizontal, Theme.Spacing.screenMargin)
                    }

                    // R3: Trigger Insights
                    if !viewModel.triggerInsights.isEmpty {
                        TriggerInsightsSection(triggers: viewModel.triggerInsights)
                            .padding(.horizontal, Theme.Spacing.screenMargin)
                    }

                    // R4: Social Comparison
                    if !viewModel.percentileComparisons.isEmpty {
                        SocialComparisonSection(
                            comparisons: viewModel.percentileComparisons,
                            overallInsight: viewModel.overallPercentileInsight
                        )
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

// MARK: - R3: Weekly AI Narrative Card

struct WeeklyNarrativeCard: View {
    let report: WeeklyReport
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(Theme.Colors.gentleGold)
                    .font(.system(size: 20))

                Text("Your Week in Review")
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.warmGray)
                    .textCase(.uppercase)
                    .tracking(1)

                Spacer()

                Text(report.weekLabel)
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.warmGray)
            }

            Text(report.narrative)
                .font(Theme.Typography.insightBody)
                .foregroundColor(Theme.Colors.charcoal)
                .multilineTextAlignment(.leading)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

            // Highlights & Lowlights
            if !report.highlights.isEmpty || !report.lowlights.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    if !report.highlights.isEmpty {
                        ForEach(report.highlights, id: \.self) { highlight in
                            HStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: "sun.max.fill")
                                    .foregroundColor(Theme.Colors.calmSage)
                                    .font(.system(size: 12))
                                Text(highlight)
                                    .font(Theme.Typography.captionFont)
                                    .foregroundColor(Theme.Colors.charcoal)
                            }
                        }
                    }
                    if !report.lowlights.isEmpty {
                        ForEach(report.lowlights, id: \.self) { lowlight in
                            HStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: "cloud.fill")
                                    .foregroundColor(Theme.Colors.warmGray)
                                    .font(.system(size: 12))
                                Text(lowlight)
                                    .font(Theme.Typography.captionFont)
                                    .foregroundColor(Theme.Colors.warmGray)
                            }
                        }
                    }
                }
            }

            // Dominant emotions
            if !report.dominantEmotions.isEmpty {
                HStack(spacing: Theme.Spacing.sm) {
                    Text("Top feelings:")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.warmGray)

                    ForEach(report.dominantEmotions.prefix(3)) { tag in
                        EmotionTagView(tag: tag)
                    }
                }
            }

            // Health correlation if available
            if let healthCorr = report.healthCorrelation {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(Theme.Colors.mutedRose)
                        .font(.system(size: 12))
                    Text(healthCorr)
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.warmGray)
                        .lineLimit(2)
                }
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(
            LinearGradient(
                colors: [Theme.Colors.gentleGold.opacity(0.15), Theme.Colors.cardBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                .stroke(Theme.Colors.softBlush, lineWidth: 1)
        )
        .shadow(color: Theme.Colors.charcoal.opacity(0.08), radius: 16, y: 4)
        .onAppear {
            withAnimation(Theme.Animations.cardAppear.delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - R3: Mood Prediction Card

struct MoodPredictionCard: View {
    let prediction: MoodPrediction
    @State private var appeared = false

    private var predictionColor: Color {
        switch prediction.predictedEmotion {
        case .joy: return Theme.Colors.calmSage
        case .anticipation, .trust: return Theme.Colors.gentleGold
        case .neutral: return Theme.Colors.warmGray
        case .sadness, .fear, .anger, .disgust: return Theme.Colors.mutedRose
        case .surprise: return Theme.Colors.gentleGold
        }
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Circle()
                .fill(predictionColor)
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 24))
                }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Tomorrow's Mood")
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.warmGray)
                    .textCase(.uppercase)
                    .tracking(1)

                Text("Like a \(prediction.similarDay ?? "typical") day")
                    .font(Theme.Typography.headlineFont)
                    .foregroundColor(Theme.Colors.charcoal)

                HStack(spacing: Theme.Spacing.sm) {
                    Text(prediction.reason)
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.warmGray)

                    Text("•")
                        .foregroundColor(Theme.Colors.warmGray)

                    Text("\(Int(prediction.confidence * 100))% confidence")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.warmGray)
                }
            }

            Spacer()
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                .stroke(predictionColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Theme.Colors.charcoal.opacity(0.08), radius: 16, y: 4)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            withAnimation(Theme.Animations.cardAppear.delay(0.2)) {
                appeared = true
            }
        }
    }
}

// MARK: - R3: Correlation Insights Section

struct CorrelationInsightsSection: View {
    let correlations: [Correlation]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("What Affects Your Mood")
                .font(Theme.Typography.headlineFont)
                .foregroundColor(Theme.Colors.charcoal)

            ForEach(correlations.prefix(3)) { correlation in
                CorrelationRow(correlation: correlation)
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct CorrelationRow: View {
    let correlation: Correlation

    private var strengthColor: Color {
        if correlation.strength > 0.4 { return Theme.Colors.calmSage }
        if correlation.strength > 0.25 { return Theme.Colors.gentleGold }
        return Theme.Colors.warmGray
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: correlation.correlationType.icon)
                    .foregroundColor(Theme.Colors.mutedRose)
                    .font(.system(size: 16))

                Text(correlation.title)
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(Theme.Colors.charcoal)

                Spacer()

                // Strength indicator
                HStack(spacing: 2) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index < Int(correlation.strength * 3) ? strengthColor : Theme.Colors.softBlush)
                            .frame(width: 6, height: 6)
                    }
                }
            }

            Text(correlation.description)
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.warmGray)
                .lineLimit(2)
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.softBlush.opacity(0.5))
        .cornerRadius(Theme.CornerRadius.small)
    }
}

// MARK: - R3: Trigger Insights Section

struct TriggerInsightsSection: View {
    let triggers: [TriggerInsight]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Your Emotional Triggers")
                .font(Theme.Typography.headlineFont)
                .foregroundColor(Theme.Colors.charcoal)

            ForEach(triggers.prefix(2)) { trigger in
                TriggerRow(trigger: trigger)
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct TriggerRow: View {
    let trigger: TriggerInsight

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            VStack(spacing: Theme.Spacing.xs) {
                if let before = trigger.emotionBefore {
                    EmotionTagView(tag: before)
                }
                Image(systemName: "arrow.down")
                    .foregroundColor(Theme.Colors.warmGray)
                    .font(.system(size: 12))
                if let after = trigger.emotionAfter {
                    EmotionTagView(tag: after)
                }
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(trigger.trigger)
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(Theme.Colors.charcoal)

                Text(trigger.description)
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.warmGray)
                    .lineLimit(3)

                Text("\(trigger.frequency)x observed")
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.warmGray.opacity(0.8))
            }

            Spacer()
        }
    }
}

// MARK: - R4: Social Comparison Section

struct SocialComparisonSection: View {
    let comparisons: [PercentileComparison]
    let overallInsight: PercentileInsight?
    @State private var isExpanded = false

    private var comparisonColor: Color {
        guard let overall = overallInsight else { return Theme.Colors.warmGray }
        switch overall.comparison.comparisonDirection {
        case .aboveAverage: return Theme.Colors.calmSage
        case .average: return Theme.Colors.gentleGold
        case .belowAverage: return Theme.Colors.mutedRose
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(Theme.Colors.warmGray)
                    .font(.system(size: 18))

                Text("How You Compare")
                    .font(Theme.Typography.headlineFont)
                    .foregroundColor(Theme.Colors.charcoal)

                Spacer()

                if let insight = overallInsight {
                    Text("Top \(100 - insight.comparison.percentile)%")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(comparisonColor)
                        .cornerRadius(8)
                }
            }

            // Overall percentile card
            if let insight = overallInsight {
                OverallPercentileCard(insight: insight)
            }

            // Individual comparisons (collapsed by default)
            if isExpanded {
                ForEach(comparisons) { comparison in
                    PercentileComparisonRow(comparison: comparison)
                }
            }

            // Toggle button
            Button {
                withAnimation(Theme.Animations.gentleEaseOut) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(isExpanded ? "Show less" : "View all comparisons")
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.Colors.warmGray)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.warmGray)
                }
            }
            .padding(.top, Theme.Spacing.xs)

            // Privacy note
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "lock.fill")
                    .foregroundColor(Theme.Colors.warmGray.opacity(0.6))
                    .font(.system(size: 11))

                Text("Anonymized & aggregated — your data stays private")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.warmGray.opacity(0.6))
            }
            .padding(.top, Theme.Spacing.xs)
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct OverallPercentileCard: View {
    let insight: PercentileInsight
    @State private var appeared = false

    private var color: Color {
        switch insight.comparison.comparisonDirection {
        case .aboveAverage: return Theme.Colors.calmSage
        case .average: return Theme.Colors.gentleGold
        case .belowAverage: return Theme.Colors.mutedRose
        }
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Percentile ring
            ZStack {
                Circle()
                    .stroke(Theme.Colors.softBlush, lineWidth: 6)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: CGFloat(insight.comparison.percentile) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))

                Text("\(insight.comparison.percentile)%")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.charcoal)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Your Wellness Index")
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(Theme.Colors.charcoal)

                Text(insight.comparison.percentileLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)

                Text(insight.comparison.metricDescription)
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.warmGray)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: insight.comparison.comparisonDirection.icon)
                .foregroundColor(color)
                .font(.system(size: 24))
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            withAnimation(Theme.Animations.cardAppear.delay(0.1)) {
                appeared = true
            }
        }
    }
}

struct PercentileComparisonRow: View {
    let comparison: PercentileComparison

    private var color: Color {
        switch comparison.comparisonDirection {
        case .aboveAverage: return Theme.Colors.calmSage
        case .average: return Theme.Colors.gentleGold
        case .belowAverage: return Theme.Colors.mutedRose
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text(comparison.metricName)
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(Theme.Colors.charcoal)

                Spacer()

                Text("\(comparison.percentile)%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }

            // Mini bar chart
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    // Average marker
                    let avgPosition = CGFloat((comparison.averageValue + 1) / 2) * geometry.size.width
                    let userPosition = CGFloat((comparison.userValue + 1) / 2) * geometry.size.width

                    // Background bar
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.Colors.softBlush)
                        .frame(height: 8)

                    // User position marker
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)
                        .offset(x: userPosition - geometry.size.width / 2)
                }
            }
            .frame(height: 10)

            HStack {
                Text("vs \(Int(comparison.averageValue * 100))% avg")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.warmGray)

                Spacer()

                Text("n=\(comparison.sampleSize.formatted()) users")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.warmGray.opacity(0.7))
            }
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.softBlush.opacity(0.5))
        .cornerRadius(Theme.CornerRadius.small)
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
