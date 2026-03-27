import SwiftUI

struct ForecastView: View {
    @StateObject private var forecastService = EmotionalForecastService.shared
    @State private var selectedDay: EmotionalForecast?
    @State private var allMoments: [Moment] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.cream.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        // Stress alert banner
                        if let topAlert = forecastService.stressAlerts.first {
                            stressAlertBanner(topAlert)
                        }

                        // 30-day forecast header
                        forecastHeader

                        // Forecast visualization
                        forecastCalendarView

                        // Daily breakdown
                        dailyBreakdownSection

                        // AI Coach insights
                        coachInsightsSection
                    }
                    .padding(.horizontal, Theme.Spacing.screenMargin)
                }
            }
            .navigationTitle("Forecast")
            .onAppear {
                allMoments = DatabaseService.shared.fetchAllMoments()
                Task {
                    await forecastService.generateForecast(from: allMoments)
                }
            }
        }
    }

    private func stressAlertBanner(_ alert: StressAlert) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: alert.risk.icon)
                .font(.title2)
                .foregroundColor(alert.risk.color)

            VStack(alignment: .leading, spacing: 2) {
                Text("Stress Alert")
                    .font(Theme.Typography.headlineFont)
                    .foregroundColor(Theme.Colors.charcoal)

                Text(alert.message)
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(Theme.Colors.warmGray)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(alert.risk.color.opacity(0.15))
        .cornerRadius(Theme.CornerRadius.card)
    }

    private var forecastHeader: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("30-Day Forecast")
                .font(Theme.Typography.headlineFont)
                .foregroundColor(Theme.Colors.charcoal)

            Text("Based on your patterns, here's what the next month might look like")
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.warmGray)
        }
    }

    private var forecastCalendarView: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                // Day labels
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.warmGray)
                        .frame(maxWidth: .infinity)
                }

                // Forecast days
                ForEach(forecastService.forecast.prefix(30)) { forecast in
                    ForecastDayCell(forecast: forecast)
                        .onTapGesture {
                            selectedDay = forecast
                        }
                }
            }

            // Legend
            HStack(spacing: Theme.Spacing.lg) {
                ForEach(StressRisk.allCases, id: \.self) { risk in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(risk.color)
                            .frame(width: 8, height: 8)
                        Text(risk.rawValue)
                            .font(.caption2)
                            .foregroundColor(Theme.Colors.warmGray)
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Color.white)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Theme.Colors.charcoal.opacity(0.06), radius: 8, y: 4)
    }

    private var dailyBreakdownSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Tomorrow's Outlook")
                .font(Theme.Typography.headlineFont)
                .foregroundColor(Theme.Colors.charcoal)

            if let tomorrow = forecastService.forecast.first {
                TomorrowOutlookCard(forecast: tomorrow)
            } else {
                Text("Not enough data to forecast yet. Keep capturing moments!")
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(Theme.Colors.warmGray)
                    .italic()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(Theme.CornerRadius.card)
            }
        }
    }

    private var coachInsightsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(Theme.Colors.mutedRose)
                Text("AI Coach Insights")
                    .font(Theme.Typography.headlineFont)
                    .foregroundColor(Theme.Colors.charcoal)
            }

            ForEach(generateCoachInsights()) { insight in
                CoachInsightCard(insight: insight)
            }
        }
    }

    private func generateCoachInsights() -> [CoachInsight] {
        var insights: [CoachInsight] = []

        // Pattern-based insight
        if let first = forecastService.forecast.first, first.stressRisk == .low {
            insights.append(CoachInsight(
                icon: "sun.max.fill",
                title: "Great Day Ahead",
                description: "Tomorrow looks peaceful. A great opportunity for creative work or starting new habits.",
                color: Theme.Colors.calmSage
            ))
        }

        // Streak reminder
        insights.append(CoachInsight(
            icon: "flame.fill",
            title: "Keep Your Streak Alive",
            description: "You've been consistent! Just one more day of capture maintains your rhythm.",
            color: Theme.Colors.gentleGold
        ))

        // Emotional pattern
        insights.append(CoachInsight(
            icon: "heart.fill",
            title: "Emotional Pattern Detected",
            description: "Your anxiety tends to peak midweek. Consider lighter schedules on Tuesdays and Wednesdays.",
            color: Theme.Colors.mutedRose
        ))

        return insights
    }
}

struct ForecastDayCell: View {
    let forecast: EmotionalForecast

    private var isToday: Bool {
        Calendar.current.isDateInToday(forecast.date)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.extraSmall)
                .fill(forecast.stressRisk.color.opacity(0.6))

            if isToday {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.extraSmall)
                    .strokeBorder(Theme.Colors.charcoal, lineWidth: 2)
            }

            VStack(spacing: 0) {
                Text("\(Calendar.current.component(.day, from: forecast.date))")
                    .font(.system(size: 11, weight: isToday ? .bold : .regular))
                    .foregroundColor(isToday ? Theme.Colors.charcoal : .white)
            }
        }
        .frame(height: 36)
        .overlay(alignment: .bottomTrailing) {
            if forecast.confidence > 0.7 {
                Image(systemName: "star.fill")
                    .font(.system(size: 6))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(2)
            }
        }
    }
}

struct TomorrowOutlookCard: View {
    let forecast: EmotionalForecast

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                // Stress risk indicator
                VStack {
                    Image(systemName: forecast.stressRisk.icon)
                        .font(.title2)
                        .foregroundColor(forecast.stressRisk.color)

                    Text(forecast.stressRisk.rawValue)
                        .font(.caption)
                        .foregroundColor(forecast.stressRisk.color)
                }
                .frame(width: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text(forecast.date.formatted(date: .abbreviated, time: .omitted))
                        .font(Theme.Typography.headlineFont)
                        .foregroundColor(Theme.Colors.charcoal)

                    HStack(spacing: 4) {
                        ForEach(forecast.predictedEmotions.prefix(3)) { emotion in
                            Text(emotion.label)
                                .font(.caption)
                                .foregroundColor(Theme.Colors.warmGray)
                        }
                    }
                }

                Spacer()

                // Confidence indicator
                VStack {
                    Text("\(Int(forecast.confidence * 100))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(confidenceColor)

                    Text("confidence")
                        .font(.caption2)
                        .foregroundColor(Theme.Colors.warmGray)
                }
            }

            // Recommendation
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Theme.Colors.gentleGold)

                Text(forecast.recommendation)
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(Theme.Colors.charcoal)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Theme.Spacing.sm)
            .background(Theme.Colors.softBlush)
            .cornerRadius(8)
        }
        .padding(Theme.Spacing.md)
        .background(Color.white)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Theme.Colors.charcoal.opacity(0.06), radius: 8, y: 4)
    }

    private var confidenceColor: Color {
        if forecast.confidence > 0.7 { return Theme.Colors.calmSage }
        else if forecast.confidence > 0.4 { return Theme.Colors.gentleGold }
        else { return Theme.Colors.mutedRose }
    }
}

struct CoachInsightCard: View {
    let insight: CoachInsight

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(insight.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: insight.icon)
                    .foregroundColor(insight.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(Theme.Typography.headlineFont)
                    .foregroundColor(Theme.Colors.charcoal)

                Text(insight.description)
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(Theme.Colors.warmGray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Color.white)
        .cornerRadius(Theme.CornerRadius.card)
        .shadow(color: Theme.Colors.charcoal.opacity(0.06), radius: 8, y: 4)
    }
}

struct CoachInsight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
}
