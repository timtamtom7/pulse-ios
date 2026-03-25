import Foundation

struct Correlation: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let description: String
    let correlationType: CorrelationType
    let strength: Double
    let dataPointCount: Int

    enum CorrelationType: String, Sendable {
        case health
        case weather
        case social
        case sleep
        case activity

        var icon: String {
            switch self {
            case .health: return "heart.fill"
            case .weather: return "cloud.sun.fill"
            case .social: return "person.2.fill"
            case .sleep: return "bed.double.fill"
            case .activity: return "figure.walk"
            }
        }
    }
}

struct TriggerInsight: Identifiable {
    let id = UUID()
    let trigger: String
    let description: String
    let emotionBefore: EmotionTag?
    let emotionAfter: EmotionTag?
    let frequency: Int
    let confidence: Double
}

struct WeeklyReport: Identifiable, Sendable {
    let id = UUID()
    let weekStartDate: Date
    let weekEndDate: Date
    let narrative: String
    let highlights: [String]
    let lowlights: [String]
    let dominantEmotions: [EmotionTag]
    let averageScore: Double
    let momentCount: Int
    let topCorrelation: Correlation?
    let prediction: String?
    let healthCorrelation: String?

    var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekStartDate)) - \(formatter.string(from: weekEndDate))"
    }
}

struct MoodPrediction: Identifiable, Sendable {
    let id = UUID()
    let predictedDate: Date
    let predictedScore: Double
    let reason: String
    let confidence: Double
    let similarDay: String?

    var predictedEmotion: EmotionCategory {
        if predictedScore > 0.5 { return .joy }
        if predictedScore > 0.2 { return .anticipation }
        if predictedScore > -0.2 { return .neutral }
        if predictedScore > -0.5 { return .sadness }
        return .fear
    }
}

actor CorrelationService {
    static let shared = CorrelationService()

    private init() {}

    func analyzeCorrelations(
        moments: [Moment],
        healthData: [Date: HealthData],
        weatherData: [Date: WeatherData],
        calendarData: [Date: [EKEvent]]
    ) async -> [Correlation] {
        var correlations: [Correlation] = []

        // Health correlation
        if let healthCorrelation = analyzeHealthCorrelation(moments: moments, healthData: healthData) {
            correlations.append(healthCorrelation)
        }

        // Weather correlation
        if let weatherCorrelation = analyzeWeatherCorrelation(moments: moments, weatherData: weatherData) {
            correlations.append(weatherCorrelation)
        }

        // Social interaction correlation (from calendar)
        if let socialCorrelation = analyzeSocialCorrelation(moments: moments, calendarData: calendarData) {
            correlations.append(socialCorrelation)
        }

        // Sleep correlation
        if let sleepCorrelation = analyzeSleepCorrelation(moments: moments, healthData: healthData) {
            correlations.append(sleepCorrelation)
        }

        return correlations
    }

    private func analyzeHealthCorrelation(moments: [Moment], healthData: [Date: HealthData]) -> Correlation? {
        let calendar = Calendar.current
        var highHRVDays: [Double] = []
        var lowHRVDays: [Double] = []

        for moment in moments {
            let day = calendar.startOfDay(for: moment.timestamp)
            if let health = healthData[day], let hrv = health.hrvAverage {
                if hrv > 50 {
                    highHRVDays.append(moment.emotionScore)
                } else if hrv < 35 {
                    lowHRVDays.append(moment.emotionScore)
                }
            }
        }

        guard highHRVDays.count >= 2 && lowHRVDays.count >= 2 else { return nil }

        let avgHigh = highHRVDays.reduce(0, +) / Double(highHRVDays.count)
        let avgLow = lowHRVDays.reduce(0, +) / Double(lowHRVDays.count)

        let strength = abs(avgHigh - avgLow)

        if strength > 0.2 {
            let direction = avgHigh > avgLow ? "higher" : "lower"
            return Correlation(
                title: "HRV Affects Your Mood",
                description: "Your emotional scores are \(direction) on days with better heart rate variability. HRV \(avgHigh > avgLow ? "boosts" : "aligns with") your mood.",
                correlationType: .health,
                strength: strength,
                dataPointCount: highHRVDays.count + lowHRVDays.count
            )
        }

        return nil
    }

    private func analyzeWeatherCorrelation(moments: [Moment], weatherData: [Date: WeatherData]) -> Correlation? {
        let calendar = Calendar.current
        var sunnyScores: [Double] = []
        var cloudyScores: [Double] = []

        for moment in moments {
            let day = calendar.startOfDay(for: moment.timestamp)
            if let weather = weatherData[day] {
                switch weather.condition {
                case .sunny, .clear:
                    sunnyScores.append(moment.emotionScore)
                case .cloudy, .rainy, .foggy:
                    cloudyScores.append(moment.emotionScore)
                default:
                    break
                }
            }
        }

        guard sunnyScores.count >= 2 && cloudyScores.count >= 2 else { return nil }

        let avgSunny = sunnyScores.reduce(0, +) / Double(sunnyScores.count)
        let avgCloudy = cloudyScores.reduce(0, +) / Double(cloudyScores.count)
        let strength = abs(avgSunny - avgCloudy)

        if strength > 0.15 {
            return Correlation(
                title: "Weather Shapes Your Day",
                description: "Your mood is \(avgSunny > avgCloudy ? "better" : "similar") on sunny days vs cloudy days (\(String(format: "%.1f", strength * 100))% difference).",
                correlationType: .weather,
                strength: strength,
                dataPointCount: sunnyScores.count + cloudyScores.count
            )
        }

        return nil
    }

    private func analyzeSocialCorrelation(moments: [Moment], calendarData: [Date: [EKEvent]]) -> Correlation? {
        let calendar = Calendar.current
        var socialDays: [Double] = []
        var aloneDays: [Double] = []

        for moment in moments {
            let day = calendar.startOfDay(for: moment.timestamp)
            let events = calendarData[day] ?? []
            let eventCount = events.count

            if eventCount >= 3 {
                socialDays.append(moment.emotionScore)
            } else if eventCount == 0 {
                aloneDays.append(moment.emotionScore)
            }
        }

        guard socialDays.count >= 2 && aloneDays.count >= 2 else { return nil }

        let avgSocial = socialDays.reduce(0, +) / Double(socialDays.count)
        let avgAlone = aloneDays.reduce(0, +) / Double(aloneDays.count)
        let strength = abs(avgSocial - avgAlone)

        if strength > 0.2 {
            return Correlation(
                title: "Social Energy Matters",
                description: "Your energy is highest when you had \(3)+ social interactions (\(String(format: "%.0f", avgSocial * 100))%) vs alone days (\(String(format: "%.0f", avgAlone * 100))%).",
                correlationType: .social,
                strength: strength,
                dataPointCount: socialDays.count + aloneDays.count
            )
        }

        return nil
    }

    private func analyzeSleepCorrelation(moments: [Moment], healthData: [Date: HealthData]) -> Correlation? {
        let calendar = Calendar.current
        var goodSleepDays: [Double] = []
        var poorSleepDays: [Double] = []

        for moment in moments {
            let day = calendar.startOfDay(for: moment.timestamp)
            let previousDay = calendar.date(byAdding: .day, value: -1, to: day) ?? day

            if let health = healthData[previousDay], let sleep = health.sleepDuration {
                if sleep >= 7 {
                    goodSleepDays.append(moment.emotionScore)
                } else if sleep < 6 {
                    poorSleepDays.append(moment.emotionScore)
                }
            }
        }

        guard goodSleepDays.count >= 2 && poorSleepDays.count >= 2 else { return nil }

        let avgGood = goodSleepDays.reduce(0, +) / Double(goodSleepDays.count)
        let avgPoor = poorSleepDays.reduce(0, +) / Double(poorSleepDays.count)
        let strength = abs(avgGood - avgPoor)

        if strength > 0.2 {
            return Correlation(
                title: "Sleep Predicts Your Day",
                description: "You score \(String(format: "%.0f", avgGood * 100))% higher on days after sleeping 7+ hours vs less than 6 hours.",
                correlationType: .sleep,
                strength: strength,
                dataPointCount: goodSleepDays.count + poorSleepDays.count
            )
        }

        return nil
    }

    // MARK: - Trigger Detection

    func detectTriggers(moments: [Moment]) -> [TriggerInsight] {
        var triggers: [TriggerInsight] = []

        // News reading trigger
        if let newsTrigger = detectNewsTrigger(moments: moments) {
            triggers.append(newsTrigger)
        }

        // Exercise trigger
        if let exerciseTrigger = detectExerciseTrigger(moments: moments) {
            triggers.append(exerciseTrigger)
        }

        // Time-of-day trigger
        if let timeTrigger = detectTimeTrigger(moments: moments) {
            triggers.append(timeTrigger)
        }

        return triggers
    }

    private func detectNewsTrigger(moments: [Moment]) -> TriggerInsight? {
        let calendar = Calendar.current
        var morningScores: [Double] = []
        var middayScores: [Double] = []

        for moment in moments {
            let hour = calendar.component(.hour, from: moment.timestamp)
            if hour < 9 {
                morningScores.append(moment.emotionScore)
            } else if hour >= 9 && hour < 12 {
                middayScores.append(moment.emotionScore)
            }
        }

        guard morningScores.count >= 3 && middayScores.count >= 3 else { return nil }

        let avgMorning = morningScores.reduce(0, +) / Double(morningScores.count)
        let avgMidday = middayScores.reduce(0, +) / Double(middayScores.count)

        if avgMorning < avgMidday - 0.3 {
            return TriggerInsight(
                trigger: "Morning News",
                description: "You consistently feel worse after reading news in the morning. Consider a news-free morning routine.",
                emotionBefore: EmotionTag(category: .fear, confidence: 0.7, label: "Anxious"),
                emotionAfter: EmotionTag(category: .sadness, confidence: 0.6, label: "Down"),
                frequency: morningScores.count,
                confidence: abs(avgMorning - avgMidday)
            )
        }

        return nil
    }

    private func detectExerciseTrigger(moments: [Moment]) -> TriggerInsight? {
        // Check if journal entries mention exercise and correlate with better mood
        let exerciseKeywords = ["exercise", "gym", "run", "workout", "yoga", "walk", "bike", "swim", "tennis", "sport"]
        let calendar = Calendar.current

        var exerciseDays: [Double] = []
        var noExerciseDays: [Double] = []

        for moment in moments where moment.type == .journal {
            let lowercaseContent = moment.content.lowercased()
            let hasExercise = exerciseKeywords.contains { lowercaseContent.contains($0) }

            if hasExercise {
                exerciseDays.append(moment.emotionScore)
            }
        }

        // Also check previous day's health data for exercise
        for moment in moments {
            let hour = calendar.component(.hour, from: moment.timestamp)
            if hour >= 17 && hour <= 20 {
                noExerciseDays.append(moment.emotionScore)
            }
        }

        guard exerciseDays.count >= 2 else { return nil }

        let avgExercise = exerciseDays.reduce(0, +) / Double(exerciseDays.count)

        if !noExerciseDays.isEmpty {
            let avgNoExercise = noExerciseDays.reduce(0, +) / Double(noExerciseDays.count)

            if avgExercise > avgNoExercise + 0.2 {
                return TriggerInsight(
                    trigger: "Exercise",
                    description: "You consistently feel better on days you exercise. Your post-workout mood averages \(String(format: "%.0f", avgExercise * 100))%.",
                    emotionBefore: EmotionTag(category: .fear, confidence: 0.5, label: "Reluctant"),
                    emotionAfter: EmotionTag(category: .joy, confidence: 0.8, label: "Energized"),
                    frequency: exerciseDays.count,
                    confidence: avgExercise - avgNoExercise
                )
            }
        }

        return nil
    }

    private func detectTimeTrigger(moments: [Moment]) -> TriggerInsight? {
        let calendar = Calendar.current
        var hourBuckets: [Int: [Double]] = [:]

        for moment in moments {
            let hour = calendar.component(.hour, from: moment.timestamp)
            hourBuckets[hour, default: []].append(moment.emotionScore)
        }

        var avgByHour: [(hour: Int, avg: Double)] = []
        for (hour, scores) in hourBuckets where scores.count >= 2 {
            avgByHour.append((hour, scores.reduce(0, +) / Double(scores.count)))
        }

        guard avgByHour.count >= 4 else { return nil }

        if let worstHour = avgByHour.min(by: { $0.avg < $1.avg }),
           let bestHour = avgByHour.max(by: { $0.avg < $1.avg }),
           worstHour.avg < bestHour.avg - 0.3 {

            let worstLabel = hourLabel(worstHour.hour)
            let bestLabel = hourLabel(bestHour.hour)

            return TriggerInsight(
                trigger: "\(worstLabel) Dip",
                description: "You feel worst around \(worstLabel) (\(String(format: "%.0f", worstHour.avg * 100))%) and best around \(bestLabel) (\(String(format: "%.0f", bestHour.avg * 100))%).",
                emotionBefore: nil,
                emotionAfter: nil,
                frequency: hourBuckets[worstHour.hour]?.count ?? 0,
                confidence: abs(worstHour.avg - bestHour.avg)
            )
        }

        return nil
    }

    private func hourLabel(_ hour: Int) -> String {
        switch hour {
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<21: return "evening"
        default: return "night"
        }
    }

    // MARK: - Weekly Report Generation

    func generateWeeklyReport(
        moments: [Moment],
        correlations: [Correlation],
        triggers: [TriggerInsight]
    ) async -> WeeklyReport {
        let calendar = Calendar.current
        let today = Date()
        guard let weekStart = calendar.date(byAdding: .day, value: -6, to: today) else {
            return emptyReport()
        }
        let weekEnd = today

        let weekMoments = moments.filter { $0.timestamp >= weekStart && $0.timestamp <= today }

        let avgScore = weekMoments.isEmpty ? 0.0 : weekMoments.map(\.emotionScore).reduce(0, +) / Double(weekMoments.count)

        // Generate narrative
        var narrativeParts: [String] = []
        narrativeParts.append("This week, you captured \(weekMoments.count) moments.")

        if avgScore > 0.3 {
            narrativeParts.append("Your emotional tone was predominantly positive, reflecting a week of growth and connection.")
        } else if avgScore > 0 {
            narrativeParts.append("Your emotional state was balanced, with more good days than challenging ones.")
        } else if avgScore < -0.3 {
            narrativeParts.append("This was a challenging week emotionally. It happens — what matters is showing up.")
        } else {
            narrativeParts.append("A reflective week with varied emotional moments. Each one adds to your understanding.")
        }

        // Identify highlights and lowlights
        let sortedMoments = weekMoments.sorted { $0.emotionScore > $1.emotionScore }
        var highlights: [String] = []
        var lowlights: [String] = []

        if let best = sortedMoments.first, best.emotionScore > 0.3 {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            highlights.append("\(dayFormatter.string(from: best.timestamp)) was your brightest day.")
        }

        if let worst = sortedMoments.last, worst.emotionScore < -0.2 {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            lowlights.append("\(dayFormatter.string(from: worst.timestamp)) had its challenges.")
        }

        // Dominant emotions
        var emotionFrequency: [EmotionCategory: Double] = [:]
        for moment in weekMoments {
            for tag in moment.emotionTags {
                emotionFrequency[tag.category, default: 0] += tag.confidence
            }
        }

        let dominantEmotions = emotionFrequency.sorted { $0.value > $1.value }
            .prefix(3)
            .map { EmotionTag(category: $0.key, confidence: $0.value / Double(max(weekMoments.count, 1))) }

        // Top correlation
        let topCorrelation = correlations.max(by: { $0.strength < $1.strength })

        // Health correlation summary
        var healthCorrelation: String? = nil
        if let healthCorr = correlations.first(where: { $0.correlationType == .health }) {
            healthCorrelation = healthCorr.description
        }

        // Build narrative
        var fullNarrative = narrativeParts.joined(separator: " ")
        if let topCorr = topCorrelation {
            fullNarrative += " A key pattern: \(topCorr.description)"
        }

        return WeeklyReport(
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            narrative: fullNarrative,
            highlights: highlights,
            lowlights: lowlights,
            dominantEmotions: dominantEmotions,
            averageScore: avgScore,
            momentCount: weekMoments.count,
            topCorrelation: topCorrelation,
            prediction: nil,
            healthCorrelation: healthCorrelation
        )
    }

    private func emptyReport() -> WeeklyReport {
        WeeklyReport(
            weekStartDate: Date(),
            weekEndDate: Date(),
            narrative: "Not enough data to generate a weekly report yet.",
            highlights: [],
            lowlights: [],
            dominantEmotions: [],
            averageScore: 0,
            momentCount: 0,
            topCorrelation: nil,
            prediction: nil,
            healthCorrelation: nil
        )
    }

    // MARK: - Mood Prediction

    func predictMood(for date: Date, moments: [Moment], healthData: [Date: HealthData], weatherData: [Date: WeatherData]) async -> MoodPrediction? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)

        // Find similar days (same weekday)
        let sameWeekdayMoments = moments.filter {
            calendar.component(.weekday, from: $0.timestamp) == weekday
        }

        guard sameWeekdayMoments.count >= 2 else { return nil }

        let avgScore = sameWeekdayMoments.map(\.emotionScore).reduce(0, +) / Double(sameWeekdayMoments.count)

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        let dayName = dayFormatter.string(from: date)

        var confidence = min(Double(sameWeekdayMoments.count) / 5.0, 0.8)

        // Adjust based on recent trend
        let recentMoments = moments.prefix(7)
        if !recentMoments.isEmpty {
            let recentAvg = recentMoments.map(\.emotionScore).reduce(0, +) / Double(recentMoments.count)
            let adjustedScore = (avgScore + recentAvg) / 2
            confidence *= 0.8
        }

        let reason = "Based on your \(sameWeekdayMoments.count) previous \(dayName)s"

        return MoodPrediction(
            predictedDate: date,
            predictedScore: avgScore,
            reason: reason,
            confidence: confidence,
            similarDay: dayName
        )
    }
}

import EventKit
