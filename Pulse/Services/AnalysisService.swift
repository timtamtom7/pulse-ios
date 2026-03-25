import Foundation
import NaturalLanguage
import Speech
import Photos
import UIKit
import EventKit

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
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false

        return try await withCheckedThrowingContinuation { continuation in
            recognizer?.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                if let result = result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                } else if result == nil {
                    continuation.resume(returning: "")
                }
            }
        }
    }

    // MARK: - Photo Analysis (Simulated)

    func analyzePhoto(_ image: UIImage) async -> (score: Double, tags: [EmotionTag]) {
        // In production, this would use Apple Intelligence vision analysis
        // For now, return neutral with random variance for demo
        let score = Double.random(in: -0.3...0.7)
        let tags = generateEmotionTags(from: "", score: score)
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
}
