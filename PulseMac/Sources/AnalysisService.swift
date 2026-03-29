import Foundation
import NaturalLanguage
import Speech
import AVFoundation

#if !canImport(UIKit)
// MARK: - AnalysisService (macOS version without UIKit dependency)

actor AnalysisService {
    static let shared = AnalysisService()

    private init() {}

    func analyzeText(_ text: String) async -> (score: Double, tags: [EmotionTag]) {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        var totalScore: Double = 0
        var count = 0

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .sentence, scheme: .sentimentScore, options: []) { tag, _ in
            if let tag = tag, let score = Double(tag.rawValue) {
                totalScore += score
                count += 1
            }
            return true
        }

        let normalizedScore = count > 0 ? totalScore / Double(count) : 0
        let tags = generateEmotionTags(from: text, score: normalizedScore)

        return (normalizedScore, tags)
    }

    private func generateEmotionTags(from text: String, score: Double) -> [EmotionTag] {
        var tags: [EmotionTag] = []
        let lowercaseText = text.lowercased()

        let joyKeywords = ["happy", "joy", "excited", "wonderful", "amazing", "great", "love", "fantastic", "beautiful", "grateful", "blessed", "delighted", "pleased", "thrilled"]
        let sadnessKeywords = ["sad", "down", "depressed", "unhappy", "disappointed", "heartbroken", "grief", "sorrow", "miserable", "hopeless", "lonely", "empty"]
        let angerKeywords = ["angry", "furious", "annoyed", "frustrated", "irritated", "mad", "rage", "hate", "bitter", "resentful"]
        let fearKeywords = ["scared", "afraid", "anxious", "worried", "nervous", "terrified", "panicked", "stressed", "uneasy", "apprehensive"]
        let surpriseKeywords = ["surprised", "amazed", "shocked", "astonished", "stunned", "unexpected"]
        let trustKeywords = ["trust", "believe", "confident", "sure", "certain", "rely", "faith"]
        let anticipationKeywords = ["excited", "looking forward", "anticipate", "hope", "expect", "eager", "waiting"]

        for keyword in joyKeywords where lowercaseText.contains(keyword) {
            tags.append(EmotionTag(category: .joy, confidence: 0.8, label: keyword.capitalized))
        }
        for keyword in sadnessKeywords where lowercaseText.contains(keyword) {
            tags.append(EmotionTag(category: .sadness, confidence: 0.8, label: keyword.capitalized))
        }
        for keyword in angerKeywords where lowercaseText.contains(keyword) {
            tags.append(EmotionTag(category: .anger, confidence: 0.8, label: keyword.capitalized))
        }
        for keyword in fearKeywords where lowercaseText.contains(keyword) {
            tags.append(EmotionTag(category: .fear, confidence: 0.8, label: keyword.capitalized))
        }
        for keyword in surpriseKeywords where lowercaseText.contains(keyword) {
            tags.append(EmotionTag(category: .surprise, confidence: 0.8, label: keyword.capitalized))
        }
        for keyword in trustKeywords where lowercaseText.contains(keyword) {
            tags.append(EmotionTag(category: .trust, confidence: 0.7, label: keyword.capitalized))
        }
        for keyword in anticipationKeywords where lowercaseText.contains(keyword) {
            tags.append(EmotionTag(category: .anticipation, confidence: 0.7, label: keyword.capitalized))
        }

        if tags.isEmpty {
            if score > 0.3 {
                tags.append(EmotionTag(category: .joy, confidence: abs(score), label: "Positive"))
            } else if score < -0.3 {
                tags.append(EmotionTag(category: .sadness, confidence: abs(score), label: "Negative"))
            } else {
                tags.append(EmotionTag(category: .neutral, confidence: 0.8, label: "Neutral"))
            }
        }

        var seen: [EmotionCategory] = []
        return tags.filter { tag in
            if seen.contains(tag.category) { return false }
            seen.append(tag.category)
            return true
        }.prefix(3).map { $0 }
    }

    func transcribeAudio(url: URL) async throws -> String {
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
            throw AnalysisError.speechRecognizerUnavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false

        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                if let result = result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }

    func analyzeVoiceTone(audioURL: URL) async -> VoiceToneResult {
        return VoiceToneResult(
            averagePitch: 0.5,
            pace: 150,
            stressLevel: 0.3,
            emotionalTags: [EmotionTag(category: .neutral, confidence: 0.6)]
        )
    }

    func analyzePhotoWithVision(_ image: Any) async -> (score: Double, tags: [EmotionTag], vision: PhotoVisionResult?) {
        let result = await analyzeText("Photo moment captured")
        return (result.score, result.tags, nil)
    }
}

enum AnalysisError: LocalizedError {
    case speechRecognizerUnavailable
    case photoAnalysisFailed
    case audioRecordingFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .speechRecognizerUnavailable:
            return "Speech recognition is not available on this device."
        case .photoAnalysisFailed:
            return "We couldn't analyze your photo. Please try again."
        case .audioRecordingFailed:
            return "Recording failed. Please check microphone permissions."
        case .unknown:
            return "Something went wrong during analysis. Please try again."
        }
    }
}

struct VoiceToneResult {
    let averagePitch: Double
    let pace: Int
    let stressLevel: Double
    let emotionalTags: [EmotionTag]
}

struct PhotoVisionResult {
    let dominantColors: [String]
    let sceneClassification: String
    let textDetected: String?
}

struct HealthData {
    var heartRate: Double = 70
    var sleepHours: Double = 7
    var steps: Int = 5000
}

struct WeatherData {
    var temperature: Double = 20
    var condition: String = "Clear"
}

struct Correlation: Identifiable, Sendable {
    let id: UUID
    let title: String
    let description: String
    let correlationType: CorrelationType
    let strength: Double
    let direction: CorrelationDirection

    enum CorrelationType: String, Sendable {
        case weather
        case sleep
        case exercise
        case calendar
        case unknown

        var icon: String {
            switch self {
            case .weather: return "cloud.sun.fill"
            case .sleep: return "bed.double.fill"
            case .exercise: return "figure.walk"
            case .calendar: return "calendar"
            case .unknown: return "questionmark.circle"
            }
        }
    }

    enum CorrelationDirection: String, Sendable {
        case positive
        case negative
        case neutral
    }
}

struct TriggerInsight: Identifiable, Sendable {
    let id: UUID
    let trigger: String
    let description: String
    let frequency: Int
    let emotionBefore: EmotionTag?
    let emotionAfter: EmotionTag?
}

struct WeeklyReport: Identifiable, Sendable {
    let id: UUID
    let weekLabel: String
    let narrative: String
    let highlights: [String]
    let lowlights: [String]
    let dominantEmotions: [EmotionTag]
    let healthCorrelation: String?
}

struct MoodPrediction: Identifiable, Sendable {
    let id: UUID
    let predictedEmotion: EmotionCategory
    let confidence: Double
    let reason: String
    let similarDay: String?
}

final class CorrelationService: @unchecked Sendable {
    static let shared = CorrelationService()

    private init() {}

    func analyzeCorrelations(moments: [Moment], healthData: [Date: HealthData], weatherData: [Date: WeatherData], calendarData: [Date: [Any]]) async -> [Correlation] {
        return []
    }

    func detectTriggers(moments: [Moment]) async -> [TriggerInsight] {
        return []
    }

    func generateWeeklyReport(moments: [Moment], correlations: [Correlation], triggers: [TriggerInsight]) async -> WeeklyReport {
        WeeklyReport(
            id: UUID(),
            weekLabel: "This Week",
            narrative: "Your week showed a mix of emotions with several positive highlights.",
            highlights: [],
            lowlights: [],
            dominantEmotions: [],
            healthCorrelation: nil
        )
    }

    func predictMood(for date: Date, moments: [Moment], healthData: [Date: HealthData], weatherData: [Date: WeatherData]) async -> MoodPrediction {
        MoodPrediction(
            id: UUID(),
            predictedEmotion: .neutral,
            confidence: 0.5,
            reason: "Based on your recent patterns",
            similarDay: nil
        )
    }
}



final class SocialComparisonService: @unchecked Sendable {
    static let shared = SocialComparisonService()

    private init() {}

    func generateComparisons(userMoments: [Moment], userStreak: Int, userAverageScore: Double, aggregatedMetrics: AggregatedMetrics) async -> [PercentileComparison] {
        return []
    }

    func generateCompositeInsight(comparisons: [PercentileComparison]) async -> PercentileInsight? {
        return nil
    }
}

final class HealthKitService: @unchecked Sendable {
    static let shared = HealthKitService()

    private init() {}

    func fetchHealthData(for date: Date) async -> HealthData? {
        return HealthData()
    }
}

final class WeatherService: @unchecked Sendable {
    static let shared = WeatherService()

    private init() {}

    func fetchWeather(for date: Date) async -> WeatherData? {
        return WeatherData()
    }
}

import EventKit

final class EventKitService: @unchecked Sendable {
    static let shared = EventKitService()
    let eventStore: Any? = nil

    private init() {}

    func fetchTodaysEvents() -> [EKEvent] {
        return []
    }
}
#endif
