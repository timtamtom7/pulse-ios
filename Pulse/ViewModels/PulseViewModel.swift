import Foundation
import SwiftUI
import EventKit

@Observable
final class PulseViewModel: @unchecked Sendable {
    var weeklyInsight: Insight?
    var recentMoments: [Moment] = []
    var weeklyMoodRing: [EmotionTag] = []
    var currentStreak: Int = 0
    var isLoading = false
    var errorMessage: String?

    // R3: AI Correlation Engine
    var correlations: [Correlation] = []
    var triggerInsights: [TriggerInsight] = []

    // R3: Weekly AI Narrative
    var weeklyReport: WeeklyReport?

    // R3: Mood Predictor
    var moodPrediction: MoodPrediction?

    // R4: Social Comparison
    var percentileComparisons: [PercentileComparison] = []
    var overallPercentileInsight: PercentileInsight?

    // R11: AI Emotional Insights
    var aiInsight: AIInsight?

    private let database = DatabaseService.shared

    init() {
        loadData()
    }

    func loadData() {
        isLoading = true
        errorMessage = nil

        let allMoments = database.fetchAllMoments()
        recentMoments = Array(allMoments.prefix(3))
        currentStreak = calculateStreak(from: allMoments)
        generateWeeklyInsightFromMoments(allMoments)

        // R3: Run correlation analysis
        Task {
            await runCorrelationAnalysis(moments: allMoments)
        }

        // R4: Generate social comparison insights
        Task {
            await generateSocialComparisons(moments: allMoments)
        }

        isLoading = false
    }

    private func generateWeeklyInsightFromMoments(_ moments: [Moment]) {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentMoments = moments.filter { $0.timestamp >= weekAgo }

        let insight = InsightService.shared.generateWeeklyInsight(moments: recentMoments)
        if let insight = insight {
            try? database.insertInsight(insight)
            weeklyInsight = insight
        } else if recentMoments.isEmpty {
            weeklyInsight = Insight(
                title: "Start your emotional journey",
                body: "Capture a moment to begin discovering your emotional patterns. Pulse works best with regular reflection.",
                category: .general
            )
        }

        generateMoodRing(from: recentMoments)

        // R11: Generate AI emotional insights
        aiInsight = AIInsightService.shared.generateWeeklyAnalysis(entries: recentMoments)
    }

    private func generateMoodRing(from moments: [Moment]) {
        var emotionFrequency: [EmotionCategory: Double] = [:]

        for moment in moments {
            for tag in moment.emotionTags {
                emotionFrequency[tag.category, default: 0] += tag.confidence
            }
        }

        let sorted = emotionFrequency.sorted { $0.value > $1.value }
        weeklyMoodRing = sorted.prefix(5).map { category, confidence in
            EmotionTag(category: category, confidence: confidence / Double(max(moments.count, 1)))
        }
    }

    private func calculateStreak(from moments: [Moment]) -> Int {
        guard !moments.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        while true {
            let hasMoments = moments.contains { moment in
                calendar.isDate(moment.timestamp, inSameDayAs: currentDate)
            }

            if hasMoments {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = previousDay
            } else {
                if calendar.isDateInToday(currentDate) {
                    guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                    currentDate = previousDay
                    continue
                }
                break
            }
        }

        return streak
    }

    // R3: Correlation analysis - what predicts energy vs anxiety
    private func runCorrelationAnalysis(moments: [Moment]) async {
        guard moments.count >= 5 else { return }

        let healthService = HealthKitService.shared
        let weatherService = WeatherService.shared
        let eventKitService = EventKitService.shared

        // Gather health data for the past 30 days
        var healthData: [Date: HealthData] = [:]
        let calendar = Calendar.current
        for dayOffset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            if let data = await healthService.fetchHealthData(for: dayStart) {
                healthData[dayStart] = data
            }
        }

        // Gather weather data
        var weatherData: [Date: WeatherData] = [:]
        for dayOffset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            if let weather = await weatherService.fetchWeather(for: dayStart) {
                weatherData[dayStart] = weather
            }
        }

        // Gather calendar data
        let calendarEvents = eventKitService.fetchTodaysEvents()
        var calendarData: [Date: [EKEvent]] = [:]
        calendarData[calendar.startOfDay(for: Date())] = calendarEvents

        // Analyze correlations
        let correlations = await CorrelationService.shared.analyzeCorrelations(
            moments: moments,
            healthData: healthData,
            weatherData: weatherData,
            calendarData: calendarData
        )

        // Detect triggers
        let triggers = await CorrelationService.shared.detectTriggers(moments: moments)

        // Generate weekly report (AI-written narrative)
        let weeklyReport = await CorrelationService.shared.generateWeeklyReport(
            moments: moments,
            correlations: correlations,
            triggers: triggers
        )

        // Predict tomorrow's mood
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let moodPrediction = await CorrelationService.shared.predictMood(
            for: tomorrow,
            moments: moments,
            healthData: healthData,
            weatherData: weatherData
        )

        await MainActor.run {
            self.correlations = correlations
            self.triggerInsights = triggers
            self.weeklyReport = weeklyReport
            self.moodPrediction = moodPrediction
        }
    }

    func refresh() {
        loadData()
    }

    // R4: Anonymous Social Comparison
    private func generateSocialComparisons(moments: [Moment]) async {
        guard moments.count >= 5 else { return }

        let avgScore = moments.isEmpty ? 0.0 : moments.map(\.emotionScore).reduce(0, +) / Double(moments.count)

        // Use aggregated metrics (in production, this would come from a privacy-safe server)
        let aggregatedMetrics = AggregatedMetrics.sample

        let comparisons = await SocialComparisonService.shared.generateComparisons(
            userMoments: moments,
            userStreak: currentStreak,
            userAverageScore: avgScore,
            aggregatedMetrics: aggregatedMetrics
        )

        let compositeInsight = await SocialComparisonService.shared.generateCompositeInsight(comparisons: comparisons)

        await MainActor.run {
            self.percentileComparisons = comparisons
            self.overallPercentileInsight = compositeInsight
        }
    }
}
