import Foundation
import NaturalLanguage
import Speech
import Photos
import UIKit
import EventKit

struct AnalysisContext: Sendable {
    var healthData: [Date: HealthData] = [:]
    var weatherData: [Date: WeatherData] = [:]
}

enum AnalysisError: LocalizedError {
    case speechRecognizerUnavailable
    case photoAnalysisFailed
    case audioRecordingFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .speechRecognizerUnavailable:
            return "Speech recognition is not available on this device. Please check your settings."
        case .photoAnalysisFailed:
            return "We couldn't analyze your photo. Please try again."
        case .audioRecordingFailed:
            return "Recording failed. Please check microphone permissions."
        case .unknown:
            return "Something went wrong during analysis. Please try again."
        }
    }
}

actor AnalysisService {
    static let shared = AnalysisService()

    private init() {}

    // MARK: - Text Analysis

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

        // Generate emotion tags based on keywords and sentiment
        let tags = generateEmotionTags(from: text, score: normalizedScore)

        return (normalizedScore, tags)
    }

    private func generateEmotionTags(from text: String, score: Double) -> [EmotionTag] {
        var tags: [EmotionTag] = []
        let lowercaseText = text.lowercased()

        // Keyword-based emotion detection
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

        // Add sentiment-based fallback
        if tags.isEmpty {
            if score > 0.3 {
                tags.append(EmotionTag(category: .joy, confidence: abs(score), label: "Positive"))
            } else if score < -0.3 {
                tags.append(EmotionTag(category: .sadness, confidence: abs(score), label: "Negative"))
            } else {
                tags.append(EmotionTag(category: .neutral, confidence: 0.8, label: "Neutral"))
            }
        }

        // Deduplicate and return top 3
        var seen: [EmotionCategory] = []
        return tags.filter { tag in
            if seen.contains(tag.category) { return false }
            seen.append(tag.category)
            return true
        }.prefix(3).map { $0 }
    }

    // MARK: - Voice Transcription

    func transcribeAudio(url: URL) async throws -> String {
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
            throw AnalysisError.speechRecognizerUnavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false

        // Simple wrapper: use a shared Task reference for timeout cancellation
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let wrapper = TranscriptionWrapper(continuation: continuation)
            wrapper.startRecognition(recognizer: recognizer, request: request)
        }
    }

    // MARK: - Voice Tone Analysis

    func analyzeVoiceTone(audioURL: URL) async -> VoiceToneResult {
        await VoiceToneAnalysisService.shared.analyzeTone(audioURL: audioURL)
    }

    // MARK: - Photo Analysis (Vision Framework)

    func analyzePhotoWithVision(_ image: UIImage) async -> (score: Double, tags: [EmotionTag], visionResult: PhotoVisionResult) {
        let visionResult = await VisionPhotoAnalysisService.shared.analyzePhoto(image)

        // Generate emotional score from vision analysis
        var score: Double = 0.5

        // Scene type emotional influence
        score += visionResult.sceneType.emotionalTone * 0.3

        // Brightness influence (very dark or very bright can indicate specific moods)
        let brightnessInfluence = abs(visionResult.brightness - 0.5)
        score += (brightnessInfluence - 0.25) * 0.2

        // People in photo tend to correlate with positive emotions
        if visionResult.hasPeople {
            score += 0.1
        }

        // Nature scenes tend to be positive
        if visionResult.hasNature {
            score += 0.15
        }

        // Normalize
        score = max(-1, min(1, score))

        // Generate tags from vision
        var tags = generateEmotionTags(from: visionResult.sceneType.label, score: score)

        // Add scene-specific tags
        if visionResult.hasPeople {
            tags.append(EmotionTag(category: .trust, confidence: 0.6, label: "Social"))
        }
        if visionResult.hasNature {
            tags.append(EmotionTag(category: .joy, confidence: 0.5, label: "Nature"))
        }
        if visionResult.hasCityscape {
            tags.append(EmotionTag(category: .anticipation, confidence: 0.4, label: "Urban"))
        }
        if visionResult.brightness > 0.7 {
            tags.append(EmotionTag(category: .joy, confidence: 0.4, label: "Bright"))
        } else if visionResult.brightness < 0.3 {
            tags.append(EmotionTag(category: .sadness, confidence: 0.3, label: "Low light"))
        }

        // Deduplicate
        var seen: [EmotionCategory] = []
        tags = tags.filter { tag in
            if seen.contains(tag.category) { return false }
            seen.append(tag.category)
            return true
        }.prefix(4).map { $0 }

        return (score, tags, visionResult)
    }

    // MARK: - Photo Analysis (Legacy)

    func analyzePhoto(_ image: UIImage) async -> (score: Double, tags: [EmotionTag]) {
        let (score, tags, _) = await analyzePhotoWithVision(image)
        return (score, tags)
    }

    // MARK: - Calendar Analysis

    func analyzeCalendarEvents(_ events: [EKEvent]) -> (score: Double, tags: [EmotionTag]) {
        // Analyze patterns in calendar - busy schedules, free time, event types
        var tags: [EmotionTag] = []

        let eventCount = events.count
        if eventCount == 0 {
            return (0.3, [EmotionTag(category: .neutral, confidence: 0.6, label: "Free day")])
        }

        if eventCount > 5 {
            tags.append(EmotionTag(category: .fear, confidence: 0.6, label: "Busy schedule"))
            return (-0.2, tags)
        }

        tags.append(EmotionTag(category: .anticipation, confidence: 0.5, label: "Scheduled activities"))
        return (0.2, tags)
    }

    // MARK: - Health Data Analysis

    func analyzeHealthData(_ health: HealthData) -> (score: Double, tags: [EmotionTag]) {
        var tags: [EmotionTag] = []
        var score = health.normalizedScore * 2 - 1 // Convert 0-1 to -1 to 1

        if let hrv = health.hrvAverage {
            if hrv > 60 {
                tags.append(EmotionTag(category: .joy, confidence: 0.7, label: "High HRV"))
            } else if hrv < 30 {
                tags.append(EmotionTag(category: .fear, confidence: 0.5, label: "Low HRV"))
            }
        }

        if let sleep = health.sleepDuration {
            if sleep >= 7 {
                tags.append(EmotionTag(category: .joy, confidence: 0.6, label: "Good sleep"))
            } else if sleep < 6 {
                tags.append(EmotionTag(category: .sadness, confidence: 0.5, label: "Poor sleep"))
            }
        }

        if health.stepCount >= 10000 {
            tags.append(EmotionTag(category: .joy, confidence: 0.5, label: "Active day"))
        }

        return (score, tags)
    }

    // MARK: - Weather Analysis

    func analyzeWeatherData(_ weather: WeatherData) -> (score: Double, tags: [EmotionTag]) {
        let score = weather.emotionalTone
        var tags: [EmotionTag] = []

        switch weather.condition {
        case .sunny:
            tags.append(EmotionTag(category: .joy, confidence: 0.6, label: "Sunny"))
        case .rainy, .stormy:
            tags.append(EmotionTag(category: .sadness, confidence: 0.5, label: "Rainy"))
        case .cloudy:
            tags.append(EmotionTag(category: .neutral, confidence: 0.4, label: "Cloudy"))
        case .clear:
            tags.append(EmotionTag(category: .joy, confidence: 0.4, label: "Clear"))
        default:
            break
        }

        return (score, tags)
    }

    // MARK: - Cross-Context Analysis

    func generateCrossContextInsight(
        moment: Moment,
        context: AnalysisContext
    ) async -> (score: Double, tags: [EmotionTag]) {
        var scores: [Double] = []
        var tags: [EmotionTag] = []

        // Base moment analysis
        scores.append(moment.emotionScore)

        // Health context
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: moment.timestamp)
        if let health = context.healthData[dayStart] {
            let (healthScore, healthTags) = analyzeHealthData(health)
            scores.append(healthScore * 0.3 + moment.emotionScore * 0.7)
            tags.append(contentsOf: healthTags)
        }

        // Weather context
        if let weather = context.weatherData[dayStart] {
            let (weatherScore, weatherTags) = analyzeWeatherData(weather)
            scores.append(weatherScore * 0.2 + moment.emotionScore * 0.8)
            tags.append(contentsOf: weatherTags)
        }

        let finalScore = scores.reduce(0, +) / Double(scores.count)

        // Deduplicate
        var seen: [EmotionCategory] = []
        tags = tags.filter { tag in
            if seen.contains(tag.category) { return false }
            seen.append(tag.category)
            return true
        }.prefix(4).map { $0 }

        return (finalScore, tags)
    }
}

// MARK: - Transcription Wrapper

private final class TranscriptionWrapper: NSObject, @unchecked Sendable {
    private let continuation: CheckedContinuation<String, Error>
    private var task: SFSpeechRecognitionTask?
    private let stateLock = NSLock()
    private var isFinished = false

    init(continuation: CheckedContinuation<String, Error>) {
        self.continuation = continuation
        super.init()
    }

    func startRecognition(recognizer: SFSpeechRecognizer, request: SFSpeechURLRecognitionRequest) {
        let delegate = TranscriptionHandlerWrapper(wrapper: self)
        task = recognizer.recognitionTask(with: request, delegate: delegate)

        // Schedule timeout
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(30))
            self?.handleTimeout()
        }
    }

    fileprivate func handleResult(_ result: String) {
        resumeContinuation { $0.resume(returning: result) }
    }

    fileprivate func handleError(_ error: Error) {
        resumeContinuation { $0.resume(throwing: error) }
    }

    fileprivate func handleCancel() {
        resumeContinuation { $0.resume(returning: "") }
    }

    private func handleTimeout() {
        stateLock.lock()
        guard !isFinished else {
            stateLock.unlock()
            return
        }
        isFinished = true
        stateLock.unlock()

        task?.cancel()
        continuation.resume(returning: "")
    }

    private func resumeContinuation(_ block: (CheckedContinuation<String, Error>) -> Void) {
        stateLock.lock()
        guard !isFinished else {
            stateLock.unlock()
            return
        }
        isFinished = true
        stateLock.unlock()

        block(continuation)
    }
}

// Thread-safe delegate wrapper
private final class TranscriptionHandlerWrapper: NSObject, SFSpeechRecognitionTaskDelegate {
    private let wrapper: TranscriptionWrapper

    init(wrapper: TranscriptionWrapper) {
        self.wrapper = wrapper
        super.init()
    }

    nonisolated func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition result: SFSpeechRecognitionResult) {
        wrapper.handleResult(result.bestTranscription.formattedString)
    }

    nonisolated func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFailWith error: Error) {
        wrapper.handleError(error)
    }

    nonisolated func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
        wrapper.handleCancel()
    }
}
